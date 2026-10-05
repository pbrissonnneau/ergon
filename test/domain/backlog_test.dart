import 'package:ergon/src/app/app_services.dart';
import 'package:ergon/src/core/local_date.dart';
import 'package:ergon/src/data/database_opener.dart';
import 'package:ergon/src/domain/enums.dart';
import 'package:ergon/src/domain/models.dart';
import 'package:ergon/src/platform/platform_integration.dart';
import 'package:ergon/src/ui/agenda/backlog.dart';
import 'package:ergon/src/ui/widgets/task_drag.dart';
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

  Future<List<String>> backlog() async =>
      (await app.tasks.watchQuery(Backlog.query).first).map((i) => i.task.title).toList();

  test('backlog lists open one-time tasks without a date, highest priority first', () async {
    final idea = await app.tasks.createTask(TaskDraft(title: 'Idea'));
    await app.tasks.createTask(TaskDraft(title: 'Important idea', priority: TaskPriority.high));
    await app.tasks.createTask(TaskDraft(title: 'Dated', dueDate: today));
    await app.tasks.createTask(TaskDraft(title: 'Background', type: TaskType.ongoing));
    await app.tasks.createTask(TaskDraft(title: 'Sub', parentId: idea));
    final done = await app.tasks.createTask(TaskDraft(title: 'Done'));
    await app.tasks.setStatus(done, TaskStatus.completed);

    expect(await backlog(), ['Important idea', 'Idea']);
  });

  test('giving a date plans the task; removing it sends it back', () async {
    final id = await app.tasks.createTask(TaskDraft(title: 'Idea'));
    await app.tasks.rescheduleTasks([id], today.addDays(2));
    expect(await backlog(), isEmpty);

    final dragged = TaskDragData((await app.tasks.getTask(id))!);
    expect(Backlog.accepts(dragged), isTrue);
    await app.tasks.rescheduleTasks([id], null);
    expect(await backlog(), ['Idea']);
    expect(Backlog.accepts(TaskDragData((await app.tasks.getTask(id))!)), isFalse, reason: 'already in the backlog');
  });
}
