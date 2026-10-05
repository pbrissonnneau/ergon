import 'package:ergon/src/core/local_date.dart';
import 'package:ergon/src/domain/enums.dart';
import 'package:ergon/src/domain/models.dart';
import 'package:ergon/src/domain/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late TestEnv env;
  setUp(() => env = TestEnv(now: DateTime(2026, 10, 5, 10)));
  tearDown(() => env.dispose());
  final today = LocalDate(2026, 10, 5);

  group('bulk operations', () {
    test('reschedule keeps the time of day; "no date" clears it', () async {
      final a = await env.tasks.createTask(TaskDraft(title: 'A', dueDate: today.addDays(-3), dueMinute: 600));
      final b = await env.tasks.createTask(TaskDraft(title: 'B', dueDate: today.addDays(-1)));
      await env.tasks.rescheduleTasks([a, b], today.addDays(1));
      expect((await env.tasks.getTask(a))!.dueDate, today.addDays(1));
      expect((await env.tasks.getTask(a))!.dueMinute, 600);
      expect((await env.tasks.getTask(b))!.dueDate, today.addDays(1));
      await env.tasks.rescheduleTasks([a], null);
      expect((await env.tasks.getTask(a))!.dueDate, isNull);
      expect((await env.tasks.getTask(a))!.dueMinute, isNull);
    });

    test('recurring tasks are not moved by reschedule; missed occurrences can be skipped', () async {
      env.clock.current = DateTime(2026, 10, 1, 9);
      final r = await env.tasks.createTask(
        TaskDraft(title: 'Daily', type: TaskType.recurring, recurrence: RecurrenceRule.daily(LocalDate(2026, 10, 1))),
      );
      env.clock.current = DateTime(2026, 10, 5, 10);
      await env.tasks.materializeAll();
      await env.tasks.rescheduleTasks([r], today.addDays(3));
      expect((await env.tasks.getTask(r))!.recurrence, isNotNull);
      final skipped = await env.tasks.skipOccurrences(r, today.addDays(-1));
      expect(skipped, 4); // Oct 1..4
      final occ = await env.tasks.watchOccurrences(r).first;
      expect(occ.where((o) => o.date < today).every((o) => o.status == TaskStatus.cancelled), isTrue);
      expect((await env.tasks.getTask(r))!.dueDate, today, reason: 'next open occurrence');
    });

    test('priority and project for many tasks at once', () async {
      final p = await env.projects.create('Home');
      final a = await env.tasks.createTask(TaskDraft(title: 'A'));
      final b = await env.tasks.createTask(TaskDraft(title: 'B'));
      final sub = await env.tasks.addSubtask(a, 'A.1');
      await env.tasks.setPriorityMany([a, b], TaskPriority.urgent);
      await env.tasks.moveManyToProject([a, b, sub], p);
      for (final id in [a, b]) {
        expect((await env.tasks.getTask(id))!.priority, TaskPriority.urgent);
        expect((await env.tasks.getTask(id))!.projectId, p);
      }
      expect((await env.tasks.getTask(sub))!.projectId, p, reason: 'subtask follows its parent');
    });
  });

  group('history and mini calendar', () {
    test('completed work is grouped by the day it was completed', () async {
      final a = await env.tasks.createTask(TaskDraft(title: 'Done Friday', dueDate: today.addDays(-5)));
      final b = await env.tasks.createTask(TaskDraft(title: 'Done today'));
      env.clock.current = DateTime(2026, 10, 2, 18);
      await env.tasks.setStatus(a, TaskStatus.completed);
      env.clock.current = DateTime(2026, 10, 5, 11);
      await env.tasks.setStatus(b, TaskStatus.completed);
      final items = await env.tasks.watchCompleted(today.addDays(-7), today).first;
      expect({for (final i in items) i.item.task.title: i.day}, {
        'Done Friday': LocalDate(2026, 10, 2),
        'Done today': today,
      });
      expect(await env.tasks.earliestCompletion(), LocalDate(2026, 10, 2));
    });

    test('day activity: due tasks, completions and occurrences with project colours', () async {
      final p = await env.projects.create('Work', color: 0xFF42A5F5);
      await env.tasks.createTask(TaskDraft(title: 'Due tomorrow', dueDate: today.addDays(1), projectId: p));
      await env.tasks.createTask(TaskDraft(title: 'Cancelled', dueDate: today, status: TaskStatus.cancelled));
      final done = await env.tasks.createTask(TaskDraft(title: 'Due today', dueDate: today));
      await env.tasks.setStatus(done, TaskStatus.completed);
      await env.tasks.createTask(
        TaskDraft(title: 'Every day', type: TaskType.recurring, recurrence: RecurrenceRule.daily(today)),
      );
      final week = await env.tasks.watchDayActivity(today, today.addDays(6)).first;
      final todayCells = week[today.epochDay]!;
      expect(todayCells.map((c) => (c.title, c.done)), unorderedEquals([('Due today', true), ('Every day', false)]));
      final tomorrow = week[today.addDays(1).epochDay]!;
      expect(tomorrow.firstWhere((c) => c.title == 'Due tomorrow').projectColor, 0xFF42A5F5);
      expect(week.values.expand((c) => c).where((c) => c.title == 'Cancelled'), isEmpty);
    });
  });
}
