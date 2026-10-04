import '../../core/local_date.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/recurrence_engine.dart';
import 'notification_payload.dart';

/// A concrete notification instance to be delivered at [fireAt].
class PlannedNotification {
  const PlannedNotification({
    required this.instanceKey,
    required this.reminderId,
    required this.taskId,
    required this.fireAt,
    required this.title,
    required this.body,
    this.occurrenceDate,
  });

  /// Stable identity, used to avoid duplicate scheduling.
  final String instanceKey;
  final int reminderId;
  final int taskId;
  final LocalDate? occurrenceDate;
  final DateTime fireAt;
  final String title;
  final String body;

  String get signature => '${fireAt.toUtc().millisecondsSinceEpoch}|$title|$body';

  NotificationPayload get payload =>
      NotificationPayload(taskId: taskId, occurrenceDate: occurrenceDate, reminderId: reminderId);
}

/// Pure expansion of reminder definitions into concrete instances.
///
/// Wall-clock reminder times are resolved with the device's *current*
/// timezone each time planning runs, so timezone/DST changes are absorbed by
/// re-planning (done at start-up, resume and on every data change).
class ReminderPlanner {
  const ReminderPlanner({
    this.horizon = const Duration(days: 14),
    this.maxPerReminder = 12,
    this.maxTotal = 300,
    this.defaultDueMinute = 9 * 60,
  });

  /// How far ahead repeating/recurring reminders are expanded.
  final Duration horizon;
  final int maxPerReminder;

  /// Hard cap (Android limits alarms per app to 500).
  final int maxTotal;

  /// Due time assumed for date-only due dates.
  final int defaultDueMinute;

  List<PlannedNotification> plan({
    required DateTime now,
    required List<(Task, List<Reminder>)> tasks,
    Map<int, Set<int>> closedOccurrenceDays = const {},
  }) {
    final out = <PlannedNotification>[];
    final end = now.add(horizon);
    final today = LocalDate.fromDateTime(now);
    final endDate = LocalDate.fromDateTime(end);

    for (final (task, reminders) in tasks) {
      if (task.status.isClosed || task.status == TaskStatus.suspended) continue;
      final closedDays = closedOccurrenceDays[task.id] ?? const <int>{};
      for (final r in reminders) {
        if (!r.enabled || r.id == null) continue;
        final instances = <(DateTime, LocalDate?)>[];
        switch (r.kind) {
          case ReminderKind.once:
            if (r.atDate != null) instances.add((r.atDate!.atMinute(r.atMinute ?? defaultDueMinute), null));
          case ReminderKind.snooze:
            if (r.atUtc != null && !(r.occurrenceDate != null && closedDays.contains(r.occurrenceDate!.epochDay))) {
              instances.add((r.atUtc!.toLocal(), r.occurrenceDate));
            }
          case ReminderKind.repeating:
            final rule = r.repeatRule;
            if (rule == null) break;
            for (final d in RecurrenceEngine.iterate(rule, from: today)) {
              if (d > endDate || instances.length >= maxPerReminder) break;
              instances.add((d.atMinute(r.atMinute ?? defaultDueMinute), null));
            }
          case ReminderKind.relative:
            final offset = r.offsetMinutes ?? 0;
            if (task.isRecurring) {
              // Offsets can reach back before today, so look a little further ahead.
              final lookBack = offset > 0 ? (offset ~/ (24 * 60)) + 1 : 0;
              for (final d in RecurrenceEngine.iterate(task.recurrence!, from: today)) {
                if (d.addDays(-lookBack) > endDate || instances.length >= maxPerReminder) break;
                if (closedDays.contains(d.epochDay)) continue;
                instances.add((_relative(d, task.dueMinute, offset), d));
              }
            } else if (task.dueDate != null) {
              instances.add((_relative(task.dueDate!, task.dueMinute, offset), null));
            }
        }
        for (final (fire, occDate) in instances) {
          if (!fire.isAfter(now)) continue;
          // Single instances are always kept; expanded series are windowed.
          final windowed = r.kind == ReminderKind.repeating || (r.kind == ReminderKind.relative && task.isRecurring);
          if (windowed && fire.isAfter(end)) continue;
          out.add(
            PlannedNotification(
              instanceKey:
                  '${r.id}@${fire.toUtc().millisecondsSinceEpoch}${occDate == null ? '' : '@${occDate.epochDay}'}',
              reminderId: r.id!,
              taskId: task.id,
              occurrenceDate: occDate,
              fireAt: fire,
              title: task.title,
              body: _body(task, occDate),
            ),
          );
        }
      }
    }
    out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return out.length > maxTotal ? out.sublist(0, maxTotal) : out;
  }

  /// Due time minus offset. Whole-day offsets are applied on the calendar so
  /// "7 days before 09:00" stays 09:00 across a DST change; others are exact
  /// durations.
  DateTime _relative(LocalDate date, int? dueMinute, int offsetMinutes) {
    final minute = dueMinute ?? defaultDueMinute;
    if (offsetMinutes % (24 * 60) == 0) {
      return date.addDays(-(offsetMinutes ~/ (24 * 60))).atMinute(minute);
    }
    return date.atMinute(minute).subtract(Duration(minutes: offsetMinutes));
  }

  String _body(Task task, LocalDate? occDate) {
    final date = occDate ?? (task.isRecurring ? null : task.dueDate);
    final prio = task.priority == TaskPriority.urgent
        ? 'Urgent · '
        : task.priority == TaskPriority.high
        ? 'High priority · '
        : '';
    if (date == null) return '${prio}Reminder';
    final time = task.dueMinute == null ? '' : ' at ${MinuteOfDay.format(task.dueMinute!)}';
    return '${prio}Due $date$time';
  }
}
