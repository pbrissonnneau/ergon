import 'package:overdue/src/core/local_date.dart';
import 'package:overdue/src/domain/enums.dart';
import 'package:overdue/src/domain/models.dart';
import 'package:overdue/src/domain/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late TestEnv env;
  setUp(() => env = TestEnv(now: DateTime(2026, 10, 1, 9)));
  tearDown(() => env.dispose());

  Future<List<String>> occ(int id) async =>
      (await env.tasks.watchOccurrences(id).first).reversed.map((o) => '${o.date}:${o.status.name}').toList();

  Future<int> spanish() => env.tasks.createTask(
    TaskDraft(
      title: 'Learn Spanish',
      type: TaskType.recurring,
      recurrence: RecurrenceRule.daily(LocalDate(2026, 10, 1), every: 2),
      dueMinute: 19 * 60,
    ),
  );

  test('recurring task stays one task and materialises a bounded window', () async {
    env.tasks.lookaheadDays = 6;
    final id = await spanish();
    expect(await env.db.select(env.db.tasks).get(), hasLength(1));
    expect(await occ(id), [
      '2026-10-01:notStarted',
      '2026-10-03:notStarted',
      '2026-10-05:notStarted',
      '2026-10-07:notStarted',
    ]);
    final t = (await env.tasks.getTask(id))!;
    expect(t.dueDate, LocalDate(2026, 10, 1), reason: 'next open occurrence');
    expect((await env.tasks.watchOccurrences(id).first).first.dueMinute, 19 * 60);
  });

  test('occurrences complete independently; history is preserved', () async {
    env.tasks.lookaheadDays = 4;
    final id = await spanish();
    await env.tasks.setOccurrenceStatus(id, LocalDate(2026, 10, 1), TaskStatus.completed);
    env.clock.current = DateTime(2026, 10, 3, 20);
    await env.tasks.materializeAll();
    await env.tasks.setOccurrenceStatus(id, LocalDate(2026, 10, 3), TaskStatus.completed);
    final list = await occ(id);
    expect(list.take(3), ['2026-10-01:completed', '2026-10-03:completed', '2026-10-05:notStarted']);
    expect((await env.tasks.getTask(id))!.dueDate, LocalDate(2026, 10, 5));
    expect((await env.tasks.getTask(id))!.status, TaskStatus.notStarted, reason: 'parent unaffected');
  });

  test('re-running materialisation never duplicates', () async {
    final id = await spanish();
    final before = await occ(id);
    await env.tasks.materializeAll();
    await env.tasks.materializeAll();
    expect(await occ(id), before);
  });

  test('missed days are caught up (bounded) after an absence', () async {
    env.tasks.lookaheadDays = 2;
    final id = await spanish();
    env.clock.current = DateTime(2026, 10, 9, 8);
    await env.tasks.materializeAll();
    final list = await occ(id);
    expect(list, containsAll(['2026-10-05:notStarted', '2026-10-07:notStarted', '2026-10-09:notStarted']));

    env.clock.current = DateTime(2027, 6, 1, 8);
    await env.tasks.materializeAll();
    final all = await env.tasks.watchOccurrences(id, limit: 10000).first;
    final oldest = all.map((o) => o.date).reduce((a, b) => a < b ? a : b);
    expect(oldest >= LocalDate(2026, 10, 1), isTrue);
    expect(
      all.where((o) => o.date > LocalDate(2026, 10, 11) && o.date < LocalDate(2027, 3, 1)),
      isEmpty,
      reason: 'catch-up is limited to ~2 months',
    );
  });

  test('changing the rule keeps completed history and replaces future dates', () async {
    env.tasks.lookaheadDays = 6;
    final id = await spanish();
    await env.tasks.setOccurrenceStatus(id, LocalDate(2026, 10, 1), TaskStatus.completed);
    env.clock.current = DateTime(2026, 10, 2, 9);
    final draft = TaskDraft.fromTask((await env.tasks.getTask(id))!, const []);
    draft.recurrence = RecurrenceRule.weekly(LocalDate(2026, 10, 1), weekdays: {DateTime.monday, DateTime.friday});
    await env.tasks.updateTask(id, draft);
    expect(await occ(id), [
      '2026-10-01:completed',
      '2026-10-02:notStarted', // Friday
      '2026-10-05:notStarted', // Monday (window ends 2026-10-08)
    ]);
  });

  test('a touched future occurrence survives a rule change', () async {
    env.tasks.lookaheadDays = 6;
    final id = await spanish();
    await env.tasks.setOccurrenceStatus(id, LocalDate(2026, 10, 5), TaskStatus.completed); // done early
    final draft = TaskDraft.fromTask((await env.tasks.getTask(id))!, const []);
    draft.recurrence = RecurrenceRule.daily(LocalDate(2026, 10, 1), every: 3);
    await env.tasks.updateTask(id, draft);
    expect(await occ(id), contains('2026-10-05:completed'));
    expect(await occ(id), contains('2026-10-04:notStarted'));
    expect(await occ(id), isNot(contains('2026-10-03:notStarted')));
  });

  test('changing due time updates only open future occurrences', () async {
    final id = await spanish();
    await env.tasks.setOccurrenceStatus(id, LocalDate(2026, 10, 1), TaskStatus.completed);
    env.clock.current = DateTime(2026, 10, 2, 9);
    final draft = TaskDraft.fromTask((await env.tasks.getTask(id))!, const []);
    draft.dueMinute = 8 * 60;
    await env.tasks.updateTask(id, draft);
    final all = await env.tasks.watchOccurrences(id).first;
    expect(all.firstWhere((o) => o.date == LocalDate(2026, 10, 1)).dueMinute, 19 * 60);
    expect(all.firstWhere((o) => o.date == LocalDate(2026, 10, 3)).dueMinute, 8 * 60);
  });

  test('completing an occurrence that is not materialised yet creates it', () async {
    env.tasks.lookaheadDays = 1;
    final id = await spanish();
    await env.tasks.setOccurrenceStatus(id, LocalDate(2026, 10, 21), TaskStatus.completed);
    expect(await occ(id), contains('2026-10-21:completed'));
  });

  test('converting to a one-time task keeps history', () async {
    final id = await spanish();
    await env.tasks.setOccurrenceStatus(id, LocalDate(2026, 10, 1), TaskStatus.completed);
    env.clock.current = DateTime(2026, 10, 2, 9);
    final draft = TaskDraft.fromTask((await env.tasks.getTask(id))!, const []);
    draft.type = TaskType.oneTime;
    draft.dueDate = LocalDate(2026, 10, 30);
    await env.tasks.updateTask(id, draft);
    expect(await occ(id), ['2026-10-01:completed']);
    final t = (await env.tasks.getTask(id))!;
    expect(t.recurrence, isNull);
    expect(t.dueDate, LocalDate(2026, 10, 30));
  });

  test('monthly rent on the 25th always has its next occurrence', () async {
    env.tasks.lookaheadDays = 3;
    final id = await env.tasks.createTask(
      TaskDraft(
        title: 'Pay rent',
        type: TaskType.recurring,
        recurrence: RecurrenceRule.monthlyOnDay(LocalDate(2026, 10, 1), 25),
      ),
    );
    expect(await occ(id), ['2026-10-25:notStarted']);
    expect((await env.tasks.getTask(id))!.dueDate, LocalDate(2026, 10, 25));
  });
}
