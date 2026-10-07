import 'package:overdue/src/app/app_services.dart';
import 'package:overdue/src/core/local_date.dart';
import 'package:overdue/src/data/database_opener.dart';
import 'package:overdue/src/domain/agenda.dart';
import 'package:overdue/src/domain/enums.dart';
import 'package:overdue/src/domain/models.dart';
import 'package:overdue/src/domain/recurrence.dart';
import 'package:overdue/src/platform/platform_integration.dart';
import 'package:overdue/src/ui/agenda/agenda_drop.dart';
import 'package:overdue/src/ui/widgets/task_drag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppServices app;
  final today = LocalDate(2026, 10, 5);

  setUp(() async {
    app = await AppServices.create(
      db: openMemoryDatabase(),
      platform: HeadlessIntegration(),
      clock: FixedClock(DateTime(2026, 10, 5, 9)),
    );
  });
  tearDown(() => app.db.close());

  Future<Agenda> agenda() async {
    final end = today.addDays(7);
    return AgendaBuilder.build(
      today: today,
      upcomingDays: 7,
      tasks: await app.tasks.watchAgendaTasks(end, today: today).first,
      occurrences: await app.tasks.watchAgendaOccurrences(end, today: today).first,
    );
  }

  AgendaSection section(Agenda a, AgendaSectionKind k, [LocalDate? date]) =>
      a.sections.firstWhere((s) => s.kind == k && (date == null || s.date == date));
  List<String> titles(AgendaSection s) => s.entries.map((e) => e.task.title).toList();
  Future<TaskDragData> drag(int id) async => TaskDragData((await app.tasks.getTask(id))!);

  test('reorder within a day is remembered; unordered tasks come after', () async {
    final a = await app.tasks.createTask(TaskDraft(title: 'A', dueDate: today, priority: TaskPriority.high));
    final b = await app.tasks.createTask(TaskDraft(title: 'B', dueDate: today));
    final c = await app.tasks.createTask(TaskDraft(title: 'C', dueDate: today));
    var s = section(await agenda(), AgendaSectionKind.today);
    expect(titles(s), ['A', 'B', 'C'], reason: 'default: priority then title');

    // Drag C before A.
    await AgendaDrop.drop(app, s, await drag(c), beforeKey: 't$a');
    s = section(await agenda(), AgendaSectionKind.today);
    expect(titles(s), ['C', 'A', 'B']);

    // A new task lands after the manually ordered ones.
    await app.tasks.createTask(TaskDraft(title: 'D', dueDate: today, priority: TaskPriority.high));
    expect(titles(section(await agenda(), AgendaSectionKind.today)), ['C', 'A', 'B', 'D']);
    expect(b, isPositive);
  });

  test('dropping onto another day changes the due date and inserts at the position', () async {
    final a = await app.tasks.createTask(TaskDraft(title: 'A', dueDate: today));
    final tomorrow = today.addDays(1);
    final x = await app.tasks.createTask(TaskDraft(title: 'X', dueDate: tomorrow));
    await app.tasks.createTask(TaskDraft(title: 'Y', dueDate: tomorrow));
    final up = section(await agenda(), AgendaSectionKind.upcoming, tomorrow);
    expect(AgendaDrop.canDrop(up, await drag(a), today), isTrue);
    await AgendaDrop.drop(app, up, await drag(a), beforeKey: 't$x');
    expect((await app.tasks.getTask(a))!.dueDate, tomorrow);
    expect(titles(section(await agenda(), AgendaSectionKind.upcoming, tomorrow)), ['A', 'X', 'Y']);
  });

  test('recurring occurrences only reorder in place; dated sections accept tasks', () async {
    final r = await app.tasks.createTask(
      TaskDraft(title: 'Daily', type: TaskType.recurring, recurrence: RecurrenceRule.daily(today)),
    );
    final ongoing = await app.tasks.createTask(TaskDraft(title: 'Ongoing', type: TaskType.ongoing));
    final a = await agenda();
    final occ = TaskDragData((await app.tasks.getTask(r))!, occurrenceDate: today);
    final upcoming = section(a, AgendaSectionKind.upcoming, today.addDays(1));
    expect(AgendaDrop.canDrop(upcoming, occ, today), isFalse);
    expect(AgendaDrop.canDrop(section(a, AgendaSectionKind.recurring), occ, today), isTrue);
    expect(AgendaDrop.canDrop(section(a, AgendaSectionKind.ongoing), await drag(r), today), isFalse);
    expect(AgendaDrop.canDrop(section(a, AgendaSectionKind.ongoing), await drag(ongoing), today), isTrue);
  });
}
