import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_gateway.dart';
import 'notification_payload.dart';
import 'reminder_planner.dart';

const _channelId = 'ergon_reminders';

/// Top-level `@pragma('vm:entry-point')` handler for notification actions
/// tapped while the app is not running (Android). Set from `main.dart`.
DidReceiveBackgroundNotificationResponseCallback? notificationBackgroundEntryPoint;
const _channelName = 'Task reminders';

/// Common setup for `flutter_local_notifications` on every platform.
abstract class _PluginGatewayBase extends NotificationGateway {
  _PluginGatewayBase(this.plugin);
  final FlutterLocalNotificationsPlugin plugin;
  NotificationResponseHandler? _handler;

  static const _windowsGuid = '6f1f2a4e-6c1b-4f0a-9a63-6b1d0d6c9a21';

  InitializationSettings get _settings => const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: WindowsInitializationSettings(
          appName: 'Ergon',
          appUserModelId: 'Ergon.TaskManager',
          guid: _windowsGuid,
        ),
      );

  @override
  Future<void> initialize(NotificationResponseHandler onResponse) async {
    _handler = onResponse;
    await plugin.initialize(
      settings: _settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundEntryPoint,
    );
  }

  void _onResponse(NotificationResponse r) {
    final parsed = NotificationPayload.parse(r.payload, actionId: r.actionId);
    if (parsed != null) _handler?.call(parsed.$1, parsed.$2);
  }

  @override
  Future<(NotificationAction, NotificationPayload)?> launchDetails() async {
    try {
      final d = await plugin.getNotificationAppLaunchDetails();
      final r = d?.notificationResponse;
      if (d == null || !d.didNotificationLaunchApp || r == null) return null;
      return NotificationPayload.parse(r.payload, actionId: r.actionId);
    } catch (_) {
      return null;
    }
  }

  NotificationDetails details(PlannedNotification n) {
    final payload = n.payload;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Reminders for your tasks',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        actions: const [
          AndroidNotificationAction('complete', 'Complete', cancelNotification: true),
          AndroidNotificationAction('snooze', 'Snooze', cancelNotification: true),
          AndroidNotificationAction('open', 'Open', showsUserInterface: true, cancelNotification: true),
        ],
      ),
      linux: const LinuxNotificationDetails(
        actions: [
          LinuxNotificationAction(key: 'open', label: 'Open'),
          LinuxNotificationAction(key: 'complete', label: 'Complete'),
          LinuxNotificationAction(key: 'snooze', label: 'Snooze'),
        ],
        category: LinuxNotificationCategory.imReceived,
        urgency: LinuxNotificationUrgency.normal,
      ),
      windows: WindowsNotificationDetails(
        actions: [
          WindowsAction(content: 'Complete', arguments: payload.encodeWithAction(NotificationAction.complete)),
          WindowsAction(content: 'Snooze', arguments: payload.encodeWithAction(NotificationAction.snooze)),
          WindowsAction(content: 'Open', arguments: payload.encodeWithAction(NotificationAction.open)),
        ],
      ),
    );
  }
}

/// Android and Windows: the OS holds and fires scheduled notifications even
/// while the app is closed.
class OsScheduledNotificationGateway extends _PluginGatewayBase {
  OsScheduledNotificationGateway([FlutterLocalNotificationsPlugin? plugin])
      : super(plugin ?? FlutterLocalNotificationsPlugin());

  @override
  bool get isInProcess => false;

  @override
  Future<bool> requestPermission() async {
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission() ?? false;
    // Exact alarms make reminders fire on time; fall back to inexact otherwise.
    try {
      await android.requestExactAlarmsPermission();
    } catch (_) {}
    return granted;
  }

  Future<AndroidScheduleMode> _mode() async {
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    try {
      final exact = await android.canScheduleExactNotifications() ?? false;
      return exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  @override
  Future<void> schedule(int id, PlannedNotification n) async {
    // Instants are absolute, so UTC avoids needing the timezone database.
    final when = tz.TZDateTime.from(n.fireAt.toUtc(), tz.UTC);
    try {
      await plugin.zonedSchedule(
        id: id,
        title: n.title,
        body: n.body,
        scheduledDate: when,
        notificationDetails: details(n),
        androidScheduleMode: await _mode(),
        payload: n.payload.encode(),
      );
    } catch (e) {
      debugPrint('Failed to schedule notification $id: $e');
    }
  }

  @override
  Future<void> cancel(int id) => plugin.cancel(id: id);

  @override
  Future<Set<int>?> pendingIds() async {
    try {
      return (await plugin.pendingNotificationRequests()).map((p) => p.id).toSet();
    } catch (_) {
      return null;
    }
  }
}

/// Linux: desktop notification daemons cannot schedule, so instances are held
/// in memory and delivered by a lightweight periodic check (robust against
/// suspend/resume and clock changes, unlike long-running timers).
class InProcessNotificationGateway extends _PluginGatewayBase {
  InProcessNotificationGateway({FlutterLocalNotificationsPlugin? plugin, this.tick = const Duration(seconds: 15)})
      : super(plugin ?? FlutterLocalNotificationsPlugin());

  final Duration tick;
  final Map<int, PlannedNotification> _pending = {};
  Timer? _timer;
  bool _available = true;

  @override
  bool get isInProcess => true;

  @override
  Future<void> initialize(NotificationResponseHandler onResponse) async {
    // Desktop notifications go through the D-Bus session bus. Without one
    // (minimal sessions, some containers) the app keeps working silently.
    _available = Platform.isLinux ? await _sessionBusAvailable() : true;
    if (_available) await super.initialize(onResponse);
    _timer = Timer.periodic(tick, (_) => _deliverDue());
  }

  static Future<bool> _sessionBusAvailable() async {
    final address = Platform.environment['DBUS_SESSION_BUS_ADDRESS'];
    if (address != null && address.isNotEmpty) {
      final path = RegExp(r'unix:path=([^,;]+)').firstMatch(address)?.group(1);
      return path == null || File(path).existsSync();
    }
    final runtime = Platform.environment['XDG_RUNTIME_DIR'];
    return runtime != null && File('$runtime/bus').existsSync();
  }

  @override
  Future<void> schedule(int id, PlannedNotification n) async {
    _pending[id] = n;
    if (!n.fireAt.isAfter(DateTime.now())) unawaited(_deliverDue());
  }

  @override
  Future<void> cancel(int id) async {
    _pending.remove(id);
  }

  @override
  Future<Set<int>?> pendingIds() async => _pending.keys.toSet();

  Future<void> _deliverDue() async {
    final now = DateTime.now();
    final due = _pending.entries.where((e) => !e.value.fireAt.isAfter(now)).toList();
    for (final e in due) {
      _pending.remove(e.key);
      if (!_available) {
        onDelivered?.call(e.key);
        continue;
      }
      try {
        await plugin.show(
          id: e.key,
          title: e.value.title,
          body: e.value.body,
          notificationDetails: details(e.value),
          payload: e.value.payload.encode(),
        );
      } catch (err) {
        debugPrint('Failed to show notification ${e.key}: $err');
      }
      onDelivered?.call(e.key);
    }
  }

  @override
  Future<void> dispose() async => _timer?.cancel();
}
