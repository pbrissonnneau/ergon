import 'package:overdue/src/core/local_date.dart';
import 'package:overdue/src/domain/agenda.dart';
import 'package:overdue/src/domain/enums.dart';
import 'package:overdue/src/domain/models.dart';
import 'package:overdue/src/domain/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late TestEnv env;
  setUp(() => env = TestEnv(now: DateTime(2026, 10, 4, 10)));
  tearDown(() => env.dispose());

  final today = LocalDate(2026, 10, 4);

  Future<Agenda> agendaFor(LocalDate today, {int upcoming = 1}) async {
    await env.tasks.materializeAll();
    final end = today.addDays(upcoming);
    return AgendaBuilder.build(
      today: today,
      upcomingDays: upcoming,
      tasks: await env.tasks.watchAgendaTasks(end, today: today).first,
      occurrences: await env.tasks.watchAgendaOccurrences(end, today: today).first,
    );
  }

  Future<Agenda> agenda({int upcoming = 1}) => agendaFor(today, upcoming: upcoming);

  List<String> titles(Agenda a, AgendaSectionKind k) =>
      a.sections.where((s) => s.kind == k).expand((s) => s.entries).map((e) => e.task.title).toList();

  Future<int> add(
    String title, {
    LocalDate? due,
    int? minute,
    TaskPriority p = TaskPriority.normal,
    TaskType type = TaskType.oneTime,
    TaskStatus status = TaskStatus.notStarted,
    RecurrenceRule? rule,
    int? parent,
  }) => env.tasks.createTask(
    TaskDraft(
      title: title,
      dueDate: due,
      dueMinute: minute,
      priority: p,
      type: type,
      status: status,
      recurrence: rule,
      parentId: parent,
    ),
  );

  test('groups today / overdue / upcoming as specified', () async {
    await add('Urgent today', due: today, p: TaskPriority.urgent);
    await add('Normal today late', due: today, minute: 18 * 60);
    await add('High today', due: today, p: TaskPriority.high);
    await add('Normal today early', due: today, minute: 8 * 60);
    await add('Research insurance', type: TaskType.ongoing);
    await add('Learn Spanish', type: TaskType.recurring, rule: RecurrenceRule.daily(today, every: 2));
    await add('Submit tax documents', due: today.addDays(-2));
    await add('Tomorrow thing', due: today.addDays(1));
    await add('Next week', due: today.addDays(7));
    await add('No date one-time');
    final a = await agenda();

    expect(titles(a, AgendaSectionKind.todayUrgent), ['Urgent today']);
    expect(titles(a, AgendaSectionKind.today), ['High today', 'Normal today early', 'Normal today late']);
    expect(titles(a, AgendaSectionKind.ongoing), ['Research insurance']);
    expect(titles(a, AgendaSectionKind.recurring), ['Learn Spanish']);
    expect(titles(a, AgendaSectionKind.overdue), ['Submit tax documents']);
    expect(titles(a, AgendaSectionKind.upcoming), ['Tomorrow thing']);
    expect(a.sections.first.kind, AgendaSectionKind.todayUrgent);
    expect(a.todayCount, 6);
    expect(a.overdueCount, 1);
  });

  test('upcoming days are configurable and grouped per day', () async {
    await add('D+1', due: today.addDays(1));
    await add('D+3', due: today.addDays(3));
    await add('D+9', due: today.addDays(9));
    expect(titles(await agenda(upcoming: 0), AgendaSectionKind.upcoming), isEmpty);
    final a = await agenda(upcoming: 7);
    final ups = a.upcoming.toList();
    expect(ups.map((s) => s.date), [today.addDays(1), today.addDays(3)]);
  });

  test('cancelled and suspended work is hidden; completed stays visible as done today', () async {
    await add('Done', due: today, status: TaskStatus.completed);
    await add('Cancelled', due: today, status: TaskStatus.cancelled);
    await add('Suspended', due: today, status: TaskStatus.suspended);
    await add('Waiting', due: today, status: TaskStatus.waiting);
    await add('Blocked', due: today, status: TaskStatus.blocked);
    final a = await agenda();
    expect(titles(a, AgendaSectionKind.today), ['Blocked', 'Done', 'Waiting']);
    expect(a.todayCount, 2, reason: 'done work is shown but not counted');
    expect(a.completedCount, 1);
  });

  test('a task completed today stays in place until tomorrow (spec #2)', () async {
    final id = await add('Call the plumber', due: today, p: TaskPriority.high);
    await add('Review pull requests', due: today);
    await env.tasks.setStatus(id, TaskStatus.completed);
    var a = await agenda();
    expect(titles(a, AgendaSectionKind.today), ['Call the plumber', 'Review pull requests'], reason: 'same position');
    expect(a.sections.expand((s) => s.entries).first.isDone, isTrue);

    // Next day: completed yesterday => gone; the open task is now overdue.
    env.clock.current = DateTime(2026, 10, 5, 8);
    a = await agendaFor(LocalDate(2026, 10, 5));
    expect(titles(a, AgendaSectionKind.overdue), ['Review pull requests']);
    expect(a.sections.expand((s) => s.entries).map((e) => e.task.title), isNot(contains('Call the plumber')));
  });

  test('an unfinished task is never dropped: it moves to Overdue day after day (spec #3)', () async {
    await add('Submit tax documents', due: today);
    for (var d = 1; d <= 40; d += 13) {
      final day = today.addDays(d);
      env.clock.current = day.atMinute(9 * 60);
      expect(titles(await agendaFor(day), AgendaSectionKind.overdue), ['Submit tax documents']);
    }
  });

  test('the user can remove completed work before tomorrow', () async {
    final a1 = await add('A', due: today);
    final a2 = await add('B', due: today);
    final rec = await add('Learn Spanish', type: TaskType.recurring, rule: RecurrenceRule.daily(today));
    await env.tasks.setStatus(a1, TaskStatus.completed);
    await env.tasks.setStatus(a2, TaskStatus.completed);
    await env.tasks.setOccurrenceStatus(rec, today, TaskStatus.completed);
    expect((await agenda()).completedCount, 3);

    await env.tasks.archiveTask(a1);
    expect(titles(await agenda(), AgendaSectionKind.today), ['B']);

    await env.tasks.archiveAllCompleted();
    final a = await agenda();
    expect(a.completedCount, 0);
    expect(titles(a, AgendaSectionKind.recurring), isEmpty);

    // Re-opening brings it back (archive flag is cleared).
    await env.tasks.setStatus(a1, TaskStatus.notStarted);
    expect(titles(await agenda(), AgendaSectionKind.today), ['A']);
  });

  test('completing an occurrence keeps it visible as done today; the series continues', () async {
    final id = await add('Learn Spanish', type: TaskType.recurring, rule: RecurrenceRule.daily(today));
    expect(titles(await agenda(), AgendaSectionKind.recurring), ['Learn Spanish']);
    await env.tasks.setOccurrenceStatus(id, today, TaskStatus.completed);
    var a = await agenda();
    expect(a.sections.firstWhere((s) => s.kind == AgendaSectionKind.recurring).entries.single.isDone, isTrue);
    expect(titles(a, AgendaSectionKind.upcoming), ['Learn Spanish']);
    env.clock.current = DateTime(2026, 10, 5, 8);
    a = await agendaFor(LocalDate(2026, 10, 5));
    expect(a.sections.expand((s) => s.entries).where((e) => e.isDone), isEmpty);
    expect(titles(a, AgendaSectionKind.recurring), ['Learn Spanish']);
  });

  test('missed recurring occurrences collapse into one overdue entry', () async {
    env.clock.current = DateTime(2026, 9, 30, 9);
    await add('Daily review', type: TaskType.recurring, rule: RecurrenceRule.daily(LocalDate(2026, 9, 30)));
    env.clock.current = DateTime(2026, 10, 4, 10);
    final a = await agenda();
    final overdue = a.overdue!.entries.single;
    expect(overdue.task.title, 'Daily review');
    expect(overdue.date, LocalDate(2026, 10, 3));
    expect(overdue.missedCount, 3);
    expect(titles(a, AgendaSectionKind.recurring), ['Daily review']);
  });

  test('ongoing task due today/overdue is treated by date, else ongoing', () async {
    await add('Ongoing overdue', type: TaskType.ongoing, due: today.addDays(-1));
    await add('Ongoing later', type: TaskType.ongoing, due: today.addDays(30));
    final a = await agenda();
    expect(titles(a, AgendaSectionKind.overdue), ['Ongoing overdue']);
    expect(titles(a, AgendaSectionKind.ongoing), ['Ongoing later']);
  });

  test('subtasks with due dates appear with their parent title; hidden when parent cancelled', () async {
    final parent = await add('Learn Spanish', type: TaskType.ongoing);
    await add('Complete lesson 1', due: today, parent: parent);
    var a = await agenda();
    final e = a.sections.expand((s) => s.entries).firstWhere((e) => e.task.title == 'Complete lesson 1');
    expect(e.item.parentTitle, 'Learn Spanish');
    await env.tasks.setStatus(parent, TaskStatus.cancelled);
    a = await agenda();
    expect(a.isEmpty, isTrue);
  });

  test('scales: 10,000 tasks build an agenda quickly', () async {
    await env.db.batch((b) {
      for (var i = 0; i < 10000; i++) {
        b.customStatement(
          'INSERT INTO tasks (title, type, status, priority, due_date, created_at, updated_at) VALUES (?,?,?,?,?,?,?)',
          ['Task $i', i % 3 == 1 ? 1 : 0, i % 7 == 0 ? 2 : 0, i % 4, today.epochDay - 400 + i % 800, 0, 0],
        );
      }
    });
    final sw = Stopwatch()..start();
    final a = await agenda(upcoming: 7);
    sw.stop();
    expect(a.sections, isNotEmpty);
    // Generous bound for CI machines; typically well under 150 ms.
    expect(sw.elapsedMilliseconds, lessThan(1500));
  });
}
