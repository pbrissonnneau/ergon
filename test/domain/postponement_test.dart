import 'package:ergon/src/app/app_services.dart';
import 'package:ergon/src/core/local_date.dart';
import 'package:ergon/src/data/database_opener.dart';
import 'package:ergon/src/domain/agenda.dart';
import 'package:ergon/src/domain/models.dart';
import 'package:ergon/src/platform/platform_integration.dart';
import 'package:ergon/src/ui/agenda/agenda_drop.dart';
import 'package:ergon/src/ui/widgets/task_drag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppServices app;
  final today = LocalDate(2026, 10, 5);
  final tomorrow = today.addDays(1);

  setUp(() async {
    app = await AppServices.create(
      db: openMemoryDatabase(),
      platform: HeadlessIntegration(),
      clock: FixedClock(DateTime(2026, 10, 5, 9)),
    );
  });
  tearDown(() => app.db.close());

  Future<Agenda> agenda({LocalDate? day}) async {
    final d = day ?? today;
    final end = d.addDays(7);
    return AgendaBuilder.build(
      today: d,
      upcomingDays: 7,
      tasks: await app.tasks.watchAgendaTasks(end, today: d).first,
      occurrences: await app.tasks.watchAgendaOccurrences(end, today: d).first,
      postponed: await app.tasks.watchPostponed(end, today: d).first,
    );
  }

  AgendaSection? section(Agenda a, AgendaSectionKind k, [LocalDate? date]) =>
      a.sections.where((s) => s.kind == k && (date == null || s.date == date)).firstOrNull;

  test('postponing leaves a red trace on the original day, not counted as to do', () async {
    final id = await app.tasks.createTask(TaskDraft(title: 'Report', dueDate: today));
    await app.tasks.rescheduleTasks([id], tomorrow);

    final a = await agenda();
    final todaySection = section(a, AgendaSectionKind.today)!;
    expect(todaySection.entries.single.isPostponed, isTrue);
    expect(todaySection.entries.single.postponement!.to, tomorrow);
    expect(todaySection.openCount, 0);
    expect(a.completedCount, 1, reason: '"Clear completed" also removes traces');
    expect(section(a, AgendaSectionKind.upcoming, tomorrow)!.entries.single.isPostponed, isFalse);
  });

  test('the trace is gone the next day but stays in history', () async {
    final id = await app.tasks.createTask(TaskDraft(title: 'Report', dueDate: today));
    await app.tasks.rescheduleTasks([id], tomorrow);

    final next = await agenda(day: tomorrow);
    expect(next.sections.expand((s) => s.entries).where((e) => e.isPostponed), isEmpty);

    final history = await app.tasks.watchCompleted(today, today).first;
    expect(history.single.postponement?.to, tomorrow);
    expect(history.single.day, today);
  });

  test('overdue and backlog moves; moving back removes the trace; bringing forward leaves none', () async {
    final late = await app.tasks.createTask(TaskDraft(title: 'Late', dueDate: today.addDays(-2)));
    final idea = await app.tasks.createTask(TaskDraft(title: 'Idea', dueDate: today));
    final soon = await app.tasks.createTask(TaskDraft(title: 'Soon', dueDate: today.addDays(3)));

    await app.tasks.rescheduleTasks([late], today);
    await app.tasks.rescheduleTasks([idea], null); // To the backlog.
    await app.tasks.rescheduleTasks([soon], tomorrow); // Brought forward: no trace.

    var a = await agenda();
    final overdueTrace = section(a, AgendaSectionKind.overdue)!.entries.single;
    expect(overdueTrace.isPostponed && overdueTrace.task.id == late, isTrue);
    final todayTraces = section(a, AgendaSectionKind.today)!.entries.where((e) => e.isPostponed).toList();
    expect(todayTraces.single.postponement!.to, isNull);
    expect(a.sections.expand((s) => s.entries).where((e) => e.isPostponed).length, 2);

    // Changed my mind: back to today, the trace disappears.
    await app.tasks.rescheduleTasks([idea], today);
    a = await agenda();
    expect(section(a, AgendaSectionKind.today)!.entries.where((e) => e.isPostponed), isEmpty);
  });

  test('traces can be removed and take no part in manual ordering', () async {
    final a1 = await app.tasks.createTask(TaskDraft(title: 'A', dueDate: today));
    final b1 = await app.tasks.createTask(TaskDraft(title: 'B', dueDate: today));
    final moved = await app.tasks.createTask(TaskDraft(title: 'Moved', dueDate: today));
    await app.tasks.rescheduleTasks([moved], tomorrow);

    var s = section(await agenda(), AgendaSectionKind.today)!;
    await AgendaDrop.drop(app, s, TaskDragData((await app.tasks.getTask(b1))!), beforeKey: 't$a1');
    expect((await app.tasks.getTask(moved))!.dayOrder, 0, reason: 'the trace did not reorder the moved task');
    s = section(await agenda(), AgendaSectionKind.today)!;
    expect(s.entries.map((e) => e.isPostponed ? 'trace' : e.task.title), ['B', 'A', 'trace']);

    await app.tasks.archivePostponement(s.entries.last.postponement!.id);
    expect(section(await agenda(), AgendaSectionKind.today)!.entries.where((e) => e.isPostponed), isEmpty);
  });
}
