import 'package:ergon/src/core/local_date.dart';
import 'package:ergon/src/domain/enums.dart';
import 'package:ergon/src/domain/models.dart';
import 'package:ergon/src/domain/recurrence.dart';
import 'package:ergon/src/domain/task_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late TestEnv env;
  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  group('task CRUD', () {
    test('create with minimal input uses sensible defaults', () async {
      final id = await env.tasks.createTask(TaskDraft(title: '  Submit tax documents '));
      final t = (await env.tasks.getTask(id))!;
      expect(t.title, 'Submit tax documents');
      expect(t.type, TaskType.oneTime);
      expect(t.status, TaskStatus.notStarted);
      expect(t.priority, TaskPriority.normal);
      expect(t.dueDate, isNull);
      expect(t.completedAt, isNull);
      expect(t.createdAt, t.updatedAt);
    });

    test('update fields and timestamps', () async {
      final id = await env.tasks.createTask(TaskDraft(title: 'A'));
      env.clock.advance(const Duration(minutes: 5));
      await env.tasks.updateTask(
          id,
          TaskDraft(
            title: 'B',
            description: '**bold**',
            priority: TaskPriority.high,
            dueDate: LocalDate(2026, 10, 10),
            dueMinute: 14 * 60,
          ));
      final t = (await env.tasks.getTask(id))!;
      expect(t.title, 'B');
      expect(t.description, '**bold**');
      expect(t.priority, TaskPriority.high);
      expect(t.dueDate, LocalDate(2026, 10, 10));
      expect(t.dueMinute, 14 * 60);
      expect(t.updatedAt.isAfter(t.createdAt), isTrue);
    });

    test('due time is dropped when there is no due date', () async {
      final id = await env.tasks.createTask(TaskDraft(title: 'A', dueMinute: 600));
      expect((await env.tasks.getTask(id))!.dueMinute, isNull);
    });

    test('delete cascades to subtasks, reminders and occurrences', () async {
      final id = await env.tasks.createTask(TaskDraft(
        title: 'Learn Spanish',
        type: TaskType.recurring,
        recurrence: RecurrenceRule.daily(env.today, every: 2),
        reminders: [const Reminder.relative(0)],
      ));
      await env.tasks.addSubtask(id, 'Buy Spanish book');
      await env.tasks.deleteTask(id);
      expect(await env.db.select(env.db.tasks).get(), isEmpty);
      expect(await env.db.select(env.db.reminders).get(), isEmpty);
      expect(await env.db.select(env.db.occurrences).get(), isEmpty);
    });
  });

  group('statuses and priorities', () {
    test('completion timestamp follows status', () async {
      final id = await env.tasks.createTask(TaskDraft(title: 'A'));
      await env.tasks.setStatus(id, TaskStatus.completed);
      final done = (await env.tasks.getTask(id))!;
      expect(done.status, TaskStatus.completed);
      expect(done.completedAt, isNotNull);

      env.clock.advance(const Duration(hours: 1));
      await env.tasks.setStatus(id, TaskStatus.completed); // idempotent
      expect((await env.tasks.getTask(id))!.completedAt, done.completedAt);

      await env.tasks.setStatus(id, TaskStatus.inProgress);
      expect((await env.tasks.getTask(id))!.completedAt, isNull);
    });

    test('every status and priority round-trips', () async {
      for (final s in TaskStatus.values) {
        for (final p in TaskPriority.values) {
          final id = await env.tasks.createTask(TaskDraft(title: '$s $p', status: s, priority: p));
          final t = (await env.tasks.getTask(id))!;
          expect(t.status, s);
          expect(t.priority, p);
        }
      }
    });

    test('closed tasks are kept for history', () async {
      final id = await env.tasks.createTask(TaskDraft(title: 'A'));
      await env.tasks.setStatus(id, TaskStatus.cancelled);
      final all = await env.tasks.watchQuery(const TaskQuery(completion: CompletionFilter.closed)).first;
      expect(all.single.task.id, id);
    });
  });

  group('projects', () {
    test('create, rename, move tasks, delete keeps tasks', () async {
      final home = await env.projects.create('Home');
      final work = await env.projects.create('Work');
      final id = await env.tasks.createTask(TaskDraft(title: 'Research insurance', projectId: home));
      final sub = await env.tasks.addSubtask(id, 'Compare offers');
      expect((await env.tasks.getTask(sub))!.projectId, home, reason: 'subtasks inherit project');

      await env.tasks.moveToProject(id, work);
      expect((await env.tasks.getTask(id))!.projectId, work);
      expect((await env.tasks.getTask(sub))!.projectId, work, reason: 'subtasks move along');

      await env.projects.update(work, name: 'Office');
      final counts = await env.projects.watchWithCounts().first;
      expect(counts.firstWhere((c) => c.project.id == work).project.name, 'Office');
      expect(counts.firstWhere((c) => c.project.id == work).openCount, 1);

      await env.projects.delete(work);
      final t = (await env.tasks.getTask(id))!;
      expect(t.projectId, isNull);
    });
  });

  group('subtasks', () {
    test('ordering and counts', () async {
      final id = await env.tasks.createTask(TaskDraft(title: 'Learn Spanish'));
      final a = await env.tasks.addSubtask(id, 'Buy Spanish book');
      final b = await env.tasks.addSubtask(id, 'Complete lesson 1');
      var subs = await env.tasks.watchSubtasks(id).first;
      expect(subs.map((s) => s.task.id), [a, b]);
      await env.tasks.reorderSubtasks([b, a]);
      subs = await env.tasks.watchSubtasks(id).first;
      expect(subs.map((s) => s.task.id), [b, a]);

      await env.tasks.setStatus(a, TaskStatus.completed);
      final parent = (await env.tasks.watchQuery(const TaskQuery(includeSubtasks: false)).first).single;
      expect(parent.subtaskCount, 2);
      expect(parent.subtaskDone, 1);
    });

    test('subtasks have their own status, priority, due date, reminders', () async {
      final id = await env.tasks.createTask(TaskDraft(title: 'Parent'));
      final sub = await env.tasks.createTask(TaskDraft(
        title: 'Child',
        parentId: id,
        priority: TaskPriority.urgent,
        dueDate: LocalDate(2026, 10, 5),
        reminders: [Reminder.once(LocalDate(2026, 10, 5), 8 * 60)],
      ));
      final t = (await env.tasks.getTask(sub))!;
      expect(t.parentId, id);
      expect(t.priority, TaskPriority.urgent);
      expect((await env.tasks.getReminders(sub)).single.kind, ReminderKind.once);
      final path = await env.tasks.ancestry(sub);
      expect(path.map((e) => e.title), ['Parent', 'Child']);
    });
  });

  group('reminders persistence', () {
    test('replace keeps ids of unchanged reminders and keeps snoozes', () async {
      final id = await env.tasks.createTask(TaskDraft(
        title: 'A',
        dueDate: LocalDate(2026, 10, 10),
        reminders: [const Reminder.relative(60), const Reminder.relative(24 * 60)],
      ));
      await env.tasks.snooze(id, DateTime(2026, 10, 4, 11));
      final rs = await env.tasks.getReminders(id);
      expect(rs.length, 3);
      final keep = rs.firstWhere((r) => r.offsetMinutes == 60);
      final draft = TaskDraft.fromTask((await env.tasks.getTask(id))!, rs);
      expect(draft.reminders.length, 2, reason: 'snoozes are not editable');
      draft.reminders = [keep, Reminder.repeating(RecurrenceRule.daily(env.today), 19 * 60)];
      await env.tasks.updateTask(id, draft);
      final after = await env.tasks.getReminders(id);
      expect(after.map((r) => r.kind).toSet(), {ReminderKind.relative, ReminderKind.repeating, ReminderKind.snooze});
      expect(after.firstWhere((r) => r.kind == ReminderKind.relative).id, keep.id);
    });
  });

  group('search & filters', () {
    late int tax, spanish, insurance;
    setUp(() async {
      final home = await env.projects.create('Household admin');
      tax = await env.tasks.createTask(TaskDraft(
          title: 'Submit tax documents',
          priority: TaskPriority.urgent,
          dueDate: LocalDate(2026, 10, 3),
          projectId: home));
      spanish = await env.tasks.createTask(
          TaskDraft(title: 'Learn Spanish', description: 'Duolingo and *grammar* book', type: TaskType.ongoing));
      insurance = await env.tasks.createTask(TaskDraft(
          title: 'Research insurance', type: TaskType.ongoing, dueDate: LocalDate(2026, 10, 20)));
      await env.tasks.setStatus(insurance, TaskStatus.waiting);
    });

    Future<List<int>> q(TaskQuery query) async =>
        (await env.tasks.watchQuery(query).first).map((e) => e.task.id).toList();

    test('full-text on title, description (prefix) and project name', () async {
      expect(await q(const TaskQuery(text: 'tax')), [tax]);
      expect(await q(const TaskQuery(text: 'gram')), [spanish]);
      expect(await q(const TaskQuery(text: 'household')), [tax]);
      expect(await q(const TaskQuery(text: 'learn span')), [spanish]);
      expect(await q(const TaskQuery(text: 'nothing-matches')), isEmpty);
      expect(await q(const TaskQuery(text: '"\'*')), hasLength(3), reason: 'punctuation-only = no text filter');
    });

    test('search index follows edits', () async {
      await env.tasks.rename(spanish, 'Learn Italian');
      expect(await q(const TaskQuery(text: 'spanish')), isEmpty);
      expect(await q(const TaskQuery(text: 'italian')), [spanish]);
    });

    test('combinable filters', () async {
      expect(await q(const TaskQuery(types: {TaskType.ongoing})), unorderedEquals([spanish, insurance]));
      expect(await q(const TaskQuery(types: {TaskType.ongoing}, statuses: {TaskStatus.waiting})), [insurance]);
      expect(await q(const TaskQuery(priorities: {TaskPriority.urgent})), [tax]);
      expect(await q(const TaskQuery(due: DueFilter.overdue)), [tax]);
      expect(await q(const TaskQuery(due: DueFilter.noDate)), [spanish]);
      expect(await q(const TaskQuery(due: DueFilter.next30Days)), [insurance]);
      expect(await q(const TaskQuery(withoutProject: true)), unorderedEquals([spanish, insurance]));
      final home = (await env.projects.getAll()).single.id;
      expect(await q(TaskQuery(projectIds: {home}, text: 'submit')), [tax]);
      await env.tasks.setStatus(tax, TaskStatus.completed);
      expect(await q(const TaskQuery(priorities: {TaskPriority.urgent})), isEmpty);
      expect(await q(const TaskQuery(priorities: {TaskPriority.urgent}, completion: CompletionFilter.all)), [tax]);
    });
  });
}
