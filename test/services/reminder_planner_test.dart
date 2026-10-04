import 'package:ergon/src/core/local_date.dart';
import 'package:ergon/src/domain/enums.dart';
import 'package:ergon/src/domain/models.dart';
import 'package:ergon/src/domain/recurrence.dart';
import 'package:ergon/src/services/notifications/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

Task task({
  int id = 1,
  LocalDate? due,
  int? minute,
  TaskStatus status = TaskStatus.notStarted,
  TaskType type = TaskType.oneTime,
  RecurrenceRule? rule,
}) => Task(
  id: id,
  title: 'T$id',
  dueDate: due,
  dueMinute: minute,
  status: status,
  type: type,
  recurrence: rule,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Reminder rem(int id, Reminder r) => r.copyWith(id: id);

void main() {
  const planner = ReminderPlanner();
  final now = DateTime(2026, 10, 4, 10, 0);
  final today = LocalDate(2026, 10, 4);

  List<PlannedNotification> plan(Task t, List<Reminder> rs, {Map<int, Set<int>> closed = const {}}) =>
      planner.plan(now: now, tasks: [(t, rs)], closedOccurrenceDays: closed);

  test('one-time reminder: future only, regardless of distance', () {
    expect(plan(task(), [rem(1, Reminder.once(today, 11 * 60))]).single.fireAt, DateTime(2026, 10, 4, 11));
    expect(plan(task(), [rem(1, Reminder.once(today, 9 * 60))]), isEmpty);
    expect(plan(task(), [rem(1, Reminder.once(LocalDate(2027, 3, 1), 8 * 60))]), hasLength(1));
  });

  test('reminders work without a due date', () {
    final t = task(type: TaskType.ongoing);
    expect(plan(t, [rem(1, Reminder.once(today, 12 * 60))]), hasLength(1));
    expect(plan(t, [rem(2, Reminder.repeating(RecurrenceRule.daily(today, every: 2), 19 * 60))]), isNotEmpty);
    expect(plan(t, [rem(3, const Reminder.relative(60))]), isEmpty, reason: 'relative needs a due date');
  });

  test('relative: hours before an exact time', () {
    final p = plan(task(due: LocalDate(2026, 10, 6), minute: 10 * 60), [rem(1, const Reminder.relative(120))]);
    expect(p.single.fireAt, DateTime(2026, 10, 6, 8));
  });

  test('relative: days before a date-only due uses the default time', () {
    final p = plan(task(due: LocalDate(2026, 10, 20)), [rem(1, const Reminder.relative(7 * 24 * 60))]);
    expect(p.single.fireAt, DateTime(2026, 10, 13, 9));
  });

  test('multiple reminders on the same task', () {
    final p = plan(task(due: LocalDate(2026, 10, 20), minute: 18 * 60), [
      rem(1, const Reminder.relative(0)),
      rem(2, const Reminder.relative(24 * 60)),
      rem(3, Reminder.once(LocalDate(2026, 10, 5), 8 * 60)),
    ]);
    expect(p.map((e) => e.fireAt), [DateTime(2026, 10, 5, 8), DateTime(2026, 10, 19, 18), DateTime(2026, 10, 20, 18)]);
    expect(p.map((e) => e.instanceKey).toSet(), hasLength(3));
  });

  test('fixed repeating reminder (every day at 19:00) is windowed and capped', () {
    final p = plan(task(), [rem(1, Reminder.repeating(RecurrenceRule.daily(today), 19 * 60))]);
    expect(p.first.fireAt, DateTime(2026, 10, 4, 19));
    expect(p.length, planner.maxPerReminder);
    expect(p.every((e) => e.fireAt.hour == 19), isTrue);
  });

  test('relative reminders on recurring tasks follow each open occurrence', () {
    final t = task(type: TaskType.recurring, rule: RecurrenceRule.daily(today, every: 2), minute: 19 * 60);
    final p = plan(
      t,
      [rem(1, const Reminder.relative(30))],
      closed: {
        1: {LocalDate(2026, 10, 6).epochDay},
      },
    );
    expect(p.first.fireAt, DateTime(2026, 10, 4, 18, 30));
    expect(p.first.occurrenceDate, today);
    expect(p.any((e) => e.occurrenceDate == LocalDate(2026, 10, 6)), isFalse, reason: 'already completed');
    expect(p.last.fireAt.isBefore(now.add(planner.horizon)), isTrue);
  });

  test('closed or suspended tasks get nothing', () {
    for (final s in [TaskStatus.completed, TaskStatus.cancelled, TaskStatus.suspended]) {
      expect(plan(task(status: s), [rem(1, Reminder.once(today, 12 * 60))]), isEmpty);
    }
    expect(plan(task(), [rem(1, Reminder.once(today, 12 * 60)).copyWith(enabled: false)]), isEmpty);
  });

  test('snooze fires at its instant', () {
    final p = plan(task(), [
      Reminder(id: 9, kind: ReminderKind.snooze, atUtc: now.add(const Duration(minutes: 10)).toUtc()),
    ]);
    expect(p.single.fireAt, now.add(const Duration(minutes: 10)));
  });

  test('global cap keeps the earliest instances', () {
    const small = ReminderPlanner(maxTotal: 5);
    final tasks = [
      for (var i = 0; i < 10; i++) (task(id: i), [rem(i, Reminder.once(today, 11 * 60 + i))]),
    ];
    final p = small.plan(now: now, tasks: tasks);
    expect(p.length, 5);
    expect(p.last.fireAt, DateTime(2026, 10, 4, 11, 4));
  });

  group('daylight saving time (meaningful when run with e.g. TZ=Europe/Paris)', () {
    // Europe: DST ends 2026-10-25 03:00 -> 02:00; US: 2026-11-01.
    test('wall-clock reminders keep their local hour across a DST change', () {
      final start = DateTime(2026, 10, 20, 10);
      final p = planner.plan(
        now: start,
        tasks: [
          (task(), [rem(1, Reminder.repeating(RecurrenceRule.daily(LocalDate(2026, 10, 20)), 19 * 60))]),
        ],
      );
      expect(p.every((e) => e.fireAt.hour == 19 && e.fireAt.minute == 0), isTrue);
      final days = p.map((e) => LocalDate.fromDateTime(e.fireAt)).toList();
      for (var i = 1; i < days.length; i++) {
        expect(days[i].epochDay - days[i - 1].epochDay, 1);
      }
    });

    test('whole-day offsets are calendar-based, not 24h multiples', () {
      final p2 = planner.plan(
        now: DateTime(2026, 10, 20, 10),
        tasks: [
          (task(due: LocalDate(2026, 11, 2), minute: 9 * 60), [rem(1, const Reminder.relative(7 * 24 * 60))]),
        ],
      );
      expect(p2.single.fireAt.hour, 9);
      expect(LocalDate.fromDateTime(p2.single.fireAt), LocalDate(2026, 10, 26));
    });

    test('sub-day offsets are exact durations', () {
      final p = planner.plan(
        now: DateTime(2026, 10, 20, 10),
        tasks: [
          (task(due: LocalDate(2026, 10, 25), minute: 4 * 60), [rem(1, const Reminder.relative(180))]),
        ],
      );
      final due = LocalDate(2026, 10, 25).atMinute(4 * 60);
      expect(due.difference(p.single.fireAt), const Duration(hours: 3));
    });
  });
}
