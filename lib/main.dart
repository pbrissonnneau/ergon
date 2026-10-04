import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app/app_services.dart';
import 'src/app/ergon_app.dart';
import 'src/data/database_opener.dart';
import 'src/data/task_repository.dart';
import 'src/platform/desktop/desktop_integration.dart';
import 'src/platform/desktop/instance_ipc.dart';
import 'src/platform/platform_integration.dart';
import 'src/services/notifications/local_notifications_gateway.dart';
import 'src/services/notifications/notification_payload.dart';
import 'src/services/notifications/notification_reconciler.dart';
import 'src/ui/overlay/overlay_app.dart';

/// Command line (desktop):
///   ergon                    open the main window (or focus the running one)
///   ergon --open-task=ID     open a task
///   ergon --new-task         open the quick-add dialog
///   ergon --overlay          run the compact desktop overlay
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final dataDir = await getApplicationSupportDirectory();
  await dataDir.create(recursive: true);

  final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  if (isDesktop && args.contains('--overlay')) {
    await runOverlay(dataDir);
    return;
  }

  final openTask = _intArg(args, '--open-task=');
  PlatformIntegration platform = PlatformIntegration.forCurrentPlatform(dataDir: dataDir);

  if (platform is DesktopIntegration) {
    // Single instance: forward the request to the running window and quit.
    final channel = InstanceChannel(dataDir, 'main');
    if (!await channel.tryAcquire()) {
      await InstanceChannel.send(
        dataDir,
        'main',
        openTask != null
            ? IpcCommand(IpcCommand.openTask, {'taskId': openTask})
            : args.contains('--new-task')
                ? const IpcCommand(IpcCommand.quickAdd)
                : const IpcCommand(IpcCommand.show),
      );
      exit(0);
    }
    platform
      ..mainChannel = channel
      ..launchTaskId = openTask
      ..launchQuickAdd = args.contains('--new-task');
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(title: 'Ergon', minimumSize: Size(380, 480)),
    );
  }

  // Android: notification actions tapped while the app is not running.
  notificationBackgroundEntryPoint = notificationBackgroundHandler;

  final services = await AppServices.open(dataDir, platform);
  runApp(ErgonApp(services: services, dataPath: dataDir.path));

  // Everything else happens after the first frame so start-up stays instant.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await services.startBackground(watchExternalChanges: platform.isDesktop);
    if (platform.supportsOverlay && services.settings.overlayEnabled) {
      unawaited(platform.setOverlayVisible(true));
    }
    if (platform.supportsHomeWidget) startWidgetPublisher(services);
  });
}

int? _intArg(List<String> args, String prefix) {
  for (final a in args) {
    if (a.startsWith(prefix)) return int.tryParse(a.substring(prefix.length));
  }
  return null;
}

/// Keeps the Android home-screen widget in sync with the agenda.
void startWidgetPublisher(AppServices s) {
  StreamSubscription<void>? sub;
  void resubscribe() {
    sub?.cancel();
    sub = s.agenda
        .watch(today: s.today.value, upcomingDays: 7)
        .listen((a) => unawaited(s.platform.publishAgenda(a)));
  }

  s.today.addListener(resubscribe);
  resubscribe();
}

/// Entry point for notification actions (Complete / Snooze) handled in a
/// background isolate on Android, without opening the UI.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  final parsed = NotificationPayload.parse(response.payload, actionId: response.actionId);
  if (parsed == null || parsed.$1 == NotificationAction.open) return;
  final dir = await getApplicationSupportDirectory();
  final db = openAppDatabase(dir);
  try {
    final tasks = TaskRepository(db);
    final gateway = OsScheduledNotificationGateway(FlutterLocalNotificationsPlugin());
    await gateway.initialize((_, _) {});
    final reconciler = NotificationReconciler(db: db, tasks: tasks, gateway: gateway);
    final (action, p) = parsed;
    if (action == NotificationAction.complete) {
      await reconciler.completeFromNotification(p.taskId, p.occurrenceDate);
    } else {
      final minutes = int.tryParse((await (db.select(db.settings)
                    ..where((s) => s.key.equals('reminders.snoozeMinutes')))
                  .getSingleOrNull())
              ?.value ??
          '');
      await reconciler.snooze(p.taskId, occurrenceDate: p.occurrenceDate, duration: Duration(minutes: minutes ?? 10));
    }
  } finally {
    await db.close();
  }
}
