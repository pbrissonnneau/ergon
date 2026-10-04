import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/local_date.dart';
import '../../data/database.dart';
import '../../data/settings_repository.dart';
import '../../data/task_repository.dart';
import '../../domain/enums.dart';
import 'notification_gateway.dart';
import 'reminder_planner.dart';

class ReconcileResult {
  const ReconcileResult({this.scheduled = 0, this.cancelled = 0, this.rescheduled = 0, this.pending = 0});
  final int scheduled;
  final int cancelled;
  final int rescheduled;
  final int pending;
  @override
  String toString() => 'scheduled=$scheduled cancelled=$cancelled rescheduled=$rescheduled pending=$pending';
}

/// Keeps the OS's scheduled notifications equal to what the persisted
/// reminder definitions require — idempotently, without duplicates.
///
/// Our own `scheduled_notifications` table is the source of truth for what
/// has been handed to the OS; the plan is diffed against it by instance key
/// and content signature. Runs serially (calls are queued).
class NotificationReconciler {
  NotificationReconciler({
    required this.db,
    required this.tasks,
    required this.gateway,
    this.settings,
    Clock clock = const SystemClock(),
    this.missedGrace = const Duration(hours: 12),
  }) : _clock = clock {
    gateway.onDelivered = (id) => unawaited(markDelivered(id));
  }

  final AppDatabase db;
  final TaskRepository tasks;
  final NotificationGateway gateway;
  final AppSettings? settings;
  final Clock _clock;

  /// In-process delivery: instances missed by at most this much (app was not
  /// running) are still shown once on the next start.
  final Duration missedGrace;

  Future<ReconcileResult>? _running;
  bool _again = false;

  ReminderPlanner get planner =>
      ReminderPlanner(defaultDueMinute: settings?.defaultReminderMinute ?? 9 * 60);

  /// Requests a reconciliation; concurrent requests are coalesced.
  Future<ReconcileResult> reconcile() async {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    final completer = Completer<ReconcileResult>();
    _running = completer.future;
    ReconcileResult result = const ReconcileResult();
    try {
      do {
        _again = false;
        result = await _reconcileOnce();
      } while (_again);
      completer.complete(result);
    } catch (e, s) {
      completer.completeError(e, s);
    } finally {
      _running = null;
    }
    return completer.future;
  }

  Future<void> markDelivered(int id) => (db.update(db.scheduledNotifications)..where((n) => n.id.equals(id)))
      .write(ScheduledNotificationsCompanion(deliveredAt: Value(_clock.now().toUtc().millisecondsSinceEpoch)));

  Future<ReconcileResult> _reconcileOnce() async {
    final now = _clock.now();
    final nowMs = now.toUtc().millisecondsSinceEpoch;
    await tasks.purgeExpiredSnoozes();

    final enabled = settings?.notificationsEnabled ?? true;
    final planned = <String, PlannedNotification>{};
    final openTaskIds = <int>{};
    if (enabled) {
      final input = await tasks.tasksWithReminders();
      openTaskIds.addAll(input.map((e) => e.$1.id));
      final recurringIds = [for (final (t, _) in input) if (t.isRecurring) t.id];
      final closed = await tasks.closedOccurrenceDays(recurringIds, LocalDate.fromDateTime(now).addDays(-1));
      for (final p in planner.plan(now: now, tasks: input, closedOccurrenceDays: closed)) {
        planned[p.instanceKey] = p;
      }
    }

    var scheduled = 0, cancelled = 0, rescheduled = 0;
    final rows = await (db.select(db.scheduledNotifications)..where((n) => n.deliveredAt.isNull())).get();
    final kept = <int, ScheduledNotificationRow>{};
    final keptKeys = <String>{};

    for (final row in rows) {
      final due = row.fireAt <= nowMs;
      if (due) {
        if (gateway.isInProcess &&
            row.fireAt > nowMs - missedGrace.inMilliseconds &&
            openTaskIds.contains(row.taskId)) {
          kept[row.id] = row; // Will be (re)delivered by the in-process gateway.
          keptKeys.add(row.instanceKey);
        } else {
          await markDelivered(row.id);
        }
        continue;
      }
      final p = planned[row.instanceKey];
      if (p == null || p.signature != row.signature) {
        await gateway.cancel(row.id);
        await (db.delete(db.scheduledNotifications)..where((n) => n.id.equals(row.id))).go();
        cancelled++;
      } else {
        kept[row.id] = row;
        keptKeys.add(row.instanceKey);
      }
    }

    // Purge old delivered bookkeeping (frees unique keys too).
    await (db.delete(db.scheduledNotifications)
          ..where((n) => n.deliveredAt.isSmallerThanValue(nowMs - const Duration(days: 7).inMilliseconds)))
        .go();

    for (final p in planned.values) {
      if (keptKeys.contains(p.instanceKey)) continue;
      final id = await db.into(db.scheduledNotifications).insert(
            ScheduledNotificationsCompanion.insert(
              instanceKey: p.instanceKey,
              reminderId: p.reminderId,
              taskId: p.taskId,
              occurrenceDate: Value(p.occurrenceDate?.epochDay),
              fireAt: p.fireAt.toUtc().millisecondsSinceEpoch,
              title: p.title,
              body: p.body,
              signature: p.signature,
            ),
            mode: InsertMode.insertOrReplace,
          );
      await gateway.schedule(id, p);
      scheduled++;
    }

    // Cross-check with what the OS actually holds (survives app data loss,
    // OS reboots that dropped alarms, or a crashed previous run).
    final pending = await gateway.pendingIds();
    if (pending != null) {
      final ourIds = (await (db.select(db.scheduledNotifications)..where((n) => n.deliveredAt.isNull())).get())
          .map((r) => r.id)
          .toSet();
      for (final orphan in pending.difference(ourIds)) {
        await gateway.cancel(orphan);
        cancelled++;
      }
      for (final row in kept.values) {
        if (!pending.contains(row.id)) {
          await gateway.schedule(row.id, _fromRow(row));
          rescheduled++;
        }
      }
    }
    return ReconcileResult(
        scheduled: scheduled, cancelled: cancelled, rescheduled: rescheduled, pending: kept.length + scheduled);
  }

  PlannedNotification _fromRow(ScheduledNotificationRow r) => PlannedNotification(
        instanceKey: r.instanceKey,
        reminderId: r.reminderId,
        taskId: r.taskId,
        occurrenceDate: r.occurrenceDate == null ? null : LocalDate.fromEpochDay(r.occurrenceDate!),
        fireAt: DateTime.fromMillisecondsSinceEpoch(r.fireAt, isUtc: true).toLocal(),
        title: r.title,
        body: r.body,
      );

  /// Handles "Complete" from a notification.
  Future<void> completeFromNotification(int taskId, LocalDate? occurrenceDate) async {
    final task = await tasks.getTask(taskId);
    if (task == null) return;
    if (occurrenceDate != null && task.isRecurring) {
      await tasks.setOccurrenceStatus(taskId, occurrenceDate, TaskStatus.completed);
    } else {
      await tasks.setStatus(taskId, TaskStatus.completed);
    }
    await reconcile();
  }

  /// Handles "Snooze" from a notification or the agenda.
  Future<void> snooze(int taskId, {LocalDate? occurrenceDate, Duration? duration}) async {
    final d = duration ?? Duration(minutes: settings?.snoozeMinutes ?? 10);
    await tasks.snooze(taskId, _clock.now().add(d), occurrenceDate: occurrenceDate);
    await reconcile();
  }
}
