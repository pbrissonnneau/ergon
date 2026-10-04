import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/local_date.dart';
import '../data/database.dart';
import '../data/settings_repository.dart';
import '../data/task_repository.dart';
import '../platform/platform_integration.dart';
import 'notifications/notification_gateway.dart';
import 'notifications/notification_payload.dart';
import 'notifications/notification_reconciler.dart';

/// Owns reminder delivery for this process: initialises the platform gateway,
/// reconciles on start-up, after data changes, periodically and at day
/// change, and executes notification actions.
class ReminderHost {
  ReminderHost({
    required this.db,
    required this.tasks,
    required this.settings,
    required this.platform,
    required this.onOpenTask,
    this.clock = const SystemClock(),
  });

  final AppDatabase db;
  final TaskRepository tasks;
  final AppSettings settings;
  final PlatformIntegration platform;
  final void Function(int taskId) onOpenTask;
  final Clock clock;

  NotificationGateway? _gateway;
  NotificationReconciler? reconciler;
  StreamSubscription<void>? _changes;
  Timer? _debounce;
  Timer? _periodic;
  Timer? _retry;
  bool _active = false;

  bool get isActive => _active;

  /// Starts if this process can own reminders; otherwise retries in the
  /// background (e.g. the overlay currently owns them on desktop).
  Future<void> start() async {
    if (await platform.tryAcquireReminderHost()) {
      await _activate();
    } else {
      _retry = Timer.periodic(const Duration(seconds: 30), (_) async {
        if (await platform.tryAcquireReminderHost()) {
          _retry?.cancel();
          await _activate();
        }
      });
    }
  }

  Future<void> _activate() async {
    final gateway = platform.createNotificationGateway();
    _gateway = gateway;
    reconciler = NotificationReconciler(db: db, tasks: tasks, gateway: gateway, settings: settings, clock: clock);
    try {
      await gateway.initialize(handleResponse);
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
      return;
    }
    _active = true;
    final launch = await gateway.launchDetails();
    if (launch != null) handleResponse(launch.$1, launch.$2);
    _changes = tasks.changes.listen((_) => scheduleReconcile());
    settings.addListener(scheduleReconcile);
    // Catches day changes, timezone/DST shifts and keeps the window rolling.
    _periodic = Timer.periodic(const Duration(minutes: 15), (_) => scheduleReconcile());
    await reconcileNow();
  }

  /// Debounced reconciliation after bursts of edits.
  void scheduleReconcile() {
    if (!_active) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => unawaited(reconcileNow()));
  }

  Future<void> reconcileNow() async {
    final r = reconciler;
    if (r == null || !_active) return;
    try {
      await r.reconcile();
    } catch (e) {
      debugPrint('Reminder reconciliation failed: $e');
    }
  }

  Future<bool> requestPermission() async => await _gateway?.requestPermission() ?? false;

  void handleResponse(NotificationAction action, NotificationPayload p) {
    switch (action) {
      case NotificationAction.open:
        onOpenTask(p.taskId);
      case NotificationAction.complete:
        unawaited(reconciler?.completeFromNotification(p.taskId, p.occurrenceDate));
      case NotificationAction.snooze:
        unawaited(reconciler?.snooze(p.taskId, occurrenceDate: p.occurrenceDate));
    }
  }

  Future<void> snooze(int taskId, {LocalDate? occurrenceDate, Duration? duration}) async {
    final r = reconciler;
    if (r != null) {
      await r.snooze(taskId, occurrenceDate: occurrenceDate, duration: duration);
    } else {
      // Another process delivers reminders; it will pick the snooze up.
      await tasks.snooze(
        taskId,
        clock.now().add(duration ?? Duration(minutes: settings.snoozeMinutes)),
        occurrenceDate: occurrenceDate,
      );
    }
  }

  Future<void> dispose() async {
    _debounce?.cancel();
    _periodic?.cancel();
    _retry?.cancel();
    settings.removeListener(scheduleReconcile);
    await _changes?.cancel();
    await _gateway?.dispose();
  }
}
