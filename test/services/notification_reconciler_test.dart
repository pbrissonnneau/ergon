import 'package:overdue/src/core/local_date.dart';
import 'package:overdue/src/domain/enums.dart';
import 'package:overdue/src/domain/models.dart';
import 'package:overdue/src/domain/recurrence.dart';
import 'package:overdue/src/services/notifications/notification_gateway.dart';
import 'package:overdue/src/services/notifications/notification_payload.dart';
import 'package:overdue/src/services/notifications/notification_reconciler.dart';
import 'package:overdue/src/services/notifications/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

class FakeGateway extends NotificationGateway {
  FakeGateway({this.inProcess = false, this.canListPending = true});
  final bool inProcess;
  final bool canListPending;
  final scheduled = <int, PlannedNotification>{};
  var scheduleCalls = 0;
  var cancelCalls = 0;

  @override
  bool get isInProcess => inProcess;
  @override
  Future<void> initialize(NotificationResponseHandler onResponse) async {}
  @override
  Future<void> schedule(int id, PlannedNotification n) async {
    scheduleCalls++;
    scheduled[id] = n;
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls++;
    scheduled.remove(id);
  }

  @override
  Future<Set<int>?> pendingIds() async => canListPending ? scheduled.keys.toSet() : null;
}

void main() {
  late TestEnv env;
  late FakeGateway gw;
  late NotificationReconciler rec;

  NotificationReconciler make(FakeGateway g) =>
      NotificationReconciler(db: env.db, tasks: env.tasks, gateway: g, clock: env.clock);

  setUp(() {
    env = TestEnv(now: DateTime(2026, 10, 4, 10));
    gw = FakeGateway();
    rec = make(gw);
  });
  tearDown(() => env.dispose());

  Future<int> taskWith(List<Reminder> rs, {LocalDate? due, int? minute, String title = 'Pay rent'}) =>
      env.tasks.createTask(TaskDraft(title: title, dueDate: due, dueMinute: minute, reminders: rs));

  test('schedules planned reminders and is idempotent (no duplicates)', () async {
    await taskWith(
      [Reminder.once(LocalDate(2026, 10, 4), 12 * 60), const Reminder.relative(60)],
      due: LocalDate(2026, 10, 5),
      minute: 9 * 60,
    );
    final r1 = await rec.reconcile();
    expect(r1.scheduled, 2);
    expect(gw.scheduled.values.map((n) => n.fireAt).toSet(), {DateTime(2026, 10, 4, 12), DateTime(2026, 10, 5, 8)});

    final calls = gw.scheduleCalls;
    final r2 = await rec.reconcile();
    expect(r2.scheduled, 0);
    expect(r2.cancelled, 0);
    expect(gw.scheduleCalls, calls);
    expect(gw.scheduled, hasLength(2));
  });

  test('concurrent reconcile requests are coalesced', () async {
    await taskWith([Reminder.once(LocalDate(2026, 10, 4), 12 * 60)]);
    await Future.wait([rec.reconcile(), rec.reconcile(), rec.reconcile()]);
    expect(gw.scheduled, hasLength(1));
    expect(await env.db.select(env.db.scheduledNotifications).get(), hasLength(1));
  });

  test('content change reschedules; completion cancels', () async {
    final id = await taskWith([Reminder.once(LocalDate(2026, 10, 4), 12 * 60)]);
    await rec.reconcile();
    await env.tasks.rename(id, 'Pay the rent');
    await rec.reconcile();
    expect(gw.scheduled.values.single.title, 'Pay the rent');
    await env.tasks.setStatus(id, TaskStatus.completed);
    await rec.reconcile();
    expect(gw.scheduled, isEmpty);
  });

  test('due date change moves relative reminders', () async {
    final id = await taskWith([const Reminder.relative(0)], due: LocalDate(2026, 10, 6), minute: 600);
    await rec.reconcile();
    await env.tasks.setDue(id, LocalDate(2026, 10, 7), 600);
    await rec.reconcile();
    expect(gw.scheduled.values.single.fireAt, DateTime(2026, 10, 7, 10));
  });

  test('restores notifications the OS lost and cancels orphans', () async {
    await taskWith([Reminder.once(LocalDate(2026, 10, 4), 12 * 60)]);
    await rec.reconcile();
    gw.scheduled.clear(); // e.g. OS dropped alarms
    gw.scheduled[99999] =
        gw.scheduled[0] ??
        PlannedNotification(
          instanceKey: 'x',
          reminderId: 0,
          taskId: 0,
          fireAt: DateTime(2030),
          title: 'stale',
          body: '',
        );
    final r = await rec.reconcile();
    expect(r.rescheduled, 1);
    expect(gw.scheduled.keys, isNot(contains(99999)));
    expect(gw.scheduled, hasLength(1));
  });

  test('passed instances are marked delivered and the window rolls forward', () async {
    await taskWith([Reminder.repeating(RecurrenceRule.daily(LocalDate(2026, 10, 4)), 19 * 60)]);
    await rec.reconcile();
    final firstIds = gw.scheduled.keys.toSet();
    env.clock.current = DateTime(2026, 10, 6, 8);
    await rec.reconcile();
    final rows = await env.db.select(env.db.scheduledNotifications).get();
    expect(rows.where((r) => r.deliveredAt != null).length, 2); // Oct 4 & 5 at 19:00
    expect(gw.scheduled.keys.toSet().difference(firstIds), isNotEmpty);
    expect(gw.scheduled.values.first.fireAt, DateTime(2026, 10, 6, 19));
  });

  test('in-process delivery catches up recently missed instances once', () async {
    final inproc = FakeGateway(inProcess: true);
    final r = make(inproc);
    await taskWith([Reminder.once(LocalDate(2026, 10, 4), 12 * 60)]);
    await r.reconcile();
    // App closed before 12:00, reopened at 13:00: the in-memory schedule is gone.
    inproc.scheduled.clear();
    env.clock.current = DateTime(2026, 10, 4, 13);
    final r2 = make(inproc);
    final res = await r2.reconcile();
    expect(res.rescheduled, 1);
    final id = inproc.scheduled.keys.single;
    await r2.markDelivered(id);
    inproc.scheduled.clear();
    expect((await r2.reconcile()).rescheduled, 0, reason: 'delivered once only');
  });

  test('disabled notifications cancel everything', () async {
    await taskWith([Reminder.once(LocalDate(2026, 10, 4), 12 * 60)]);
    await rec.reconcile();
    await env.db.into(env.db.settings).insert(SettingsCompanionHelper.disabled());
    final settingsAware = NotificationReconciler(
      db: env.db,
      tasks: env.tasks,
      gateway: gw,
      clock: env.clock,
      settings: await loadSettings(env),
    );
    await settingsAware.reconcile();
    expect(gw.scheduled, isEmpty);
  });

  test('snooze schedules a one-shot reminder and cleans up after firing', () async {
    final id = await taskWith(const []);
    await rec.snooze(id, duration: const Duration(minutes: 10));
    expect(gw.scheduled.values.single.fireAt, DateTime(2026, 10, 4, 10, 10));
    env.clock.current = DateTime(2026, 10, 4, 12);
    await rec.reconcile();
    expect(await env.tasks.getReminders(id), isEmpty, reason: 'expired snooze purged');
  });

  test('complete from notification handles tasks and occurrences', () async {
    final plain = await taskWith([Reminder.once(LocalDate(2026, 10, 4), 12 * 60)]);
    await rec.completeFromNotification(plain, null);
    expect((await env.tasks.getTask(plain))!.status, TaskStatus.completed);

    final rec2 = await env.tasks.createTask(
      TaskDraft(
        title: 'Learn Spanish',
        type: TaskType.recurring,
        recurrence: RecurrenceRule.daily(LocalDate(2026, 10, 4), every: 2),
        dueMinute: 19 * 60,
        reminders: [const Reminder.relative(0)],
      ),
    );
    await rec.reconcile();
    expect(gw.scheduled.values.where((n) => n.occurrenceDate == LocalDate(2026, 10, 4)), hasLength(1));
    await rec.completeFromNotification(rec2, LocalDate(2026, 10, 4));
    final occ = await env.tasks.watchOccurrences(rec2).first;
    expect(occ.firstWhere((o) => o.date == LocalDate(2026, 10, 4)).status, TaskStatus.completed);
    expect((await env.tasks.getTask(rec2))!.status, TaskStatus.notStarted);
    expect(gw.scheduled.values.where((n) => n.occurrenceDate == LocalDate(2026, 10, 4)), isEmpty);
    expect(gw.scheduled.values.where((n) => n.occurrenceDate == LocalDate(2026, 10, 6)), hasLength(1));
  });

  test('payload encoding round-trips, including Windows action prefixes', () {
    final p = NotificationPayload(taskId: 12, occurrenceDate: LocalDate(2026, 10, 4), reminderId: 3);
    final (a, back) = NotificationPayload.parse(p.encode())!;
    expect(a, NotificationAction.open);
    expect(back.taskId, 12);
    expect(back.occurrenceDate, LocalDate(2026, 10, 4));
    expect(back.reminderId, 3);
    expect(NotificationPayload.parse(p.encodeWithAction(NotificationAction.snooze))!.$1, NotificationAction.snooze);
    expect(NotificationPayload.parse(p.encode(), actionId: 'complete')!.$1, NotificationAction.complete);
    expect(NotificationPayload.parse('garbage'), isNull);
    expect(NotificationPayload.parse(null), isNull);
  });
}
