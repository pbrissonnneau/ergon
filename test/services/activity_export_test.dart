import 'dart:io';

import 'package:ergon/src/app/app_services.dart';
import 'package:ergon/src/core/local_date.dart';
import 'package:ergon/src/data/database_opener.dart';
import 'package:ergon/src/data/task_repository.dart';
import 'package:ergon/src/domain/enums.dart';
import 'package:ergon/src/domain/models.dart';
import 'package:ergon/src/platform/platform_integration.dart';
import 'package:ergon/src/services/activity_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('periods', () {
    test('months and ISO weeks', () {
      final m = ExportRange.containing(LocalDate(2026, 10, 6), ExportPeriod.month);
      expect((m.label, m.from, m.to), ('2026-10', LocalDate(2026, 10, 1), LocalDate(2026, 10, 31)));
      expect(m.previous(ExportPeriod.month).label, '2026-09');

      final w = ExportRange.containing(LocalDate(2026, 10, 6), ExportPeriod.week); // A Tuesday.
      expect((w.from, w.to), (LocalDate(2026, 10, 5), LocalDate(2026, 10, 11)));
      expect(w.label, '2026-W41');
      // 1 Jan 2027 is a Friday: it belongs to the last ISO week of 2026.
      expect(ExportRange.containing(LocalDate(2027, 1, 1), ExportPeriod.week).label, '2026-W53');
    });
  });

  group('service', () {
    late AppServices app;
    late Directory dir;
    late FixedClock clock;

    setUp(() async {
      clock = FixedClock(DateTime(2026, 10, 6, 9));
      app = await AppServices.create(db: openMemoryDatabase(), platform: HeadlessIntegration(), clock: clock);
      dir = await Directory.systemTemp.createTemp('ergon_export');
      app.exports.defaultFolder = dir;
    });
    tearDown(() async {
      await app.db.close();
      await dir.delete(recursive: true);
    });

    test('disabled by default; once enabled, exports the month that just ended, once', () async {
      expect(await app.exports.runIfDue(), isEmpty);
      await app.settings.setRaw(ActivityExportService.enabledKey, '1');
      final files = await app.exports.runIfDue();
      expect(files.map((f) => f.uri.pathSegments.last), ['ergon-activity-2026-09.yaml']);
      expect(await app.exports.runIfDue(), isEmpty, reason: 'already exported');
    });

    test('YAML lists completed, postponed and created tasks of the period', () async {
      final project = await app.projects.create('Work: "Q4"');
      final done = await app.tasks.createTask(
        TaskDraft(title: 'Ship it', projectId: project, dueDate: LocalDate(2026, 10, 6)),
      );
      await app.tasks.setStatus(done, TaskStatus.completed);
      final later = await app.tasks.createTask(TaskDraft(title: 'Later', dueDate: LocalDate(2026, 10, 6)));
      await app.tasks.rescheduleTasks([later], LocalDate(2026, 10, 9));

      final file = await app.exports.exportNow();
      final yaml = await file.readAsString();
      expect(file.uri.pathSegments.last, 'ergon-activity-2026-10.yaml');
      expect(yaml, contains('period: "2026-10"'));
      expect(yaml, contains('complete: false'));
      expect(yaml, contains('  completed: 1\n  postponed: 1\n  created: 2'));
      expect(yaml, contains('- date: 2026-10-06'));
      expect(yaml, contains('- title: "Ship it"\n        project: "Work: \\"Q4\\""\n        time: "09:00"'));
      expect(yaml, contains('- title: "Later"\n        from: 2026-10-06\n        to: 2026-10-09'));
    });
  });

  group('follow-up', () {
    test('closes the task and creates "[FU] title" for tomorrow', () async {
      final app = await AppServices.create(
        db: openMemoryDatabase(),
        platform: HeadlessIntegration(),
        clock: FixedClock(DateTime(2026, 10, 6, 9)),
      );
      addTearDown(app.db.close);
      final id = await app.tasks.createTask(
        TaskDraft(title: 'Call Bob', priority: TaskPriority.high, dueDate: LocalDate(2026, 10, 6)),
      );
      final fu = await app.tasks.followUp((await app.tasks.getTask(id))!);
      expect((await app.tasks.getTask(id))!.status, TaskStatus.completed);
      final t = (await app.tasks.getTask(fu))!;
      expect((t.title, t.dueDate, t.priority), ('[FU] Call Bob', LocalDate(2026, 10, 7), TaskPriority.high));

      final fu2 = await app.tasks.followUp(t);
      expect((await app.tasks.getTask(fu2))!.title, '[FU] Call Bob', reason: 'no double prefix');
      expect(TaskRepository.followUpTitle('x'), '[FU] x');
    });
  });
}
