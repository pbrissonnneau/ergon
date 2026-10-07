// ignore_for_file: unused_local_variable
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:overdue/src/core/local_date.dart';
import 'package:overdue/src/data/database.dart';
import 'package:overdue/src/data/database_opener.dart';
import 'package:overdue/src/data/migrations.dart';
import 'package:overdue/src/data/task_repository.dart';
import 'package:overdue/src/domain/models.dart';
import 'package:overdue/src/domain/recurrence.dart';
import 'package:overdue/src/domain/task_query.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

/// Schema migration tests: user data must survive every upgrade.
///
/// For every schema change: bump `Migrations.currentVersion`, add the step in
/// `onUpgrade`, run `dart run drift_dev make-migrations` (stores a snapshot in
/// `drift_schemas/` and regenerates `generated/`), then add a data-integrity
/// test like the v1 -> v2 one below.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  group('schema upgrades', () {
    const versions = GeneratedHelper.versions;
    for (final (i, from) in versions.indexed) {
      for (final to in versions.skip(i + 1)) {
        test('from v$from to v$to', () async {
          final schema = await verifier.schemaAt(from);
          final db = AppDatabase(schema.newConnection());
          await verifier.migrateAndValidate(db, to);
          await db.close();
        });
      }
    }
    test('latest stored schema is the current one', () {
      expect(GeneratedHelper.versions.last, Migrations.currentVersion);
    });
  });

  test('v1 -> v2 keeps every row and every value', () async {
    const t0 = 1759600000000;
    final projects = [
      const v1.ProjectsData(
        id: 1,
        name: 'Household admin',
        color: 0xFF26A69A,
        sortOrder: 0,
        createdAt: t0,
        updatedAt: t0,
      ),
    ];
    final tasks = [
      const v1.TasksData(
        id: 1,
        projectId: 1,
        title: 'Submit tax documents',
        description: 'Bring **all** receipts',
        type: 0,
        status: 0,
        priority: 3,
        dueDate: 20730,
        dueMinute: 17 * 60,
        position: 0,
        createdAt: t0,
        updatedAt: t0,
      ),
      const v1.TasksData(
        id: 2,
        parentId: 1,
        projectId: 1,
        title: 'Find bank statements',
        description: '',
        type: 0,
        status: 2,
        priority: 1,
        position: 0,
        createdAt: t0,
        updatedAt: t0 + 5,
        completedAt: t0 + 5,
      ),
      const v1.TasksData(
        id: 3,
        title: 'Learn Spanish',
        description: '',
        type: 2,
        status: 0,
        priority: 1,
        dueMinute: 19 * 60,
        recurrence: '{"f":"daily","i":2,"s":"2026-10-01"}',
        recurrenceGeneratedUntil: 20750,
        dueDate: 20731,
        position: 0,
        createdAt: t0,
        updatedAt: t0,
      ),
    ];
    final occurrences = [
      const v1.OccurrencesData(
        id: 1,
        taskId: 3,
        date: 20727,
        dueMinute: 1140,
        status: 2,
        createdAt: t0,
        updatedAt: t0,
        completedAt: t0,
      ),
      const v1.OccurrencesData(id: 2, taskId: 3, date: 20729, dueMinute: 1140, status: 0, createdAt: t0, updatedAt: t0),
    ];
    final reminders = [
      const v1.RemindersData(id: 1, taskId: 1, kind: 1, offsetMinutes: 60, enabled: 1, createdAt: t0),
      const v1.RemindersData(
        id: 2,
        taskId: 3,
        kind: 2,
        atMinute: 1140,
        repeatRule: '{"f":"daily","i":1,"s":"2026-10-01"}',
        enabled: 1,
        createdAt: t0,
      ),
    ];
    final settings = [const v1.SettingsData(key: 'agenda.upcomingDays', value: '7')];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.projects, projects);
        batch.insertAll(oldDb.tasks, tasks);
        batch.insertAll(oldDb.occurrences, occurrences);
        batch.insertAll(oldDb.reminders, reminders);
        batch.insertAll(oldDb.settings, settings);
      },
      validateItems: (newDb) async {
        expect((await newDb.select(newDb.projects).get()).map((p) => p.name), ['Household admin']);
        final newTasks = await newDb.select(newDb.tasks).get();
        expect(newTasks.map((t) => (t.id, t.title, t.status, t.dueDate, t.recurrence, t.completedAt, t.archivedAt)), [
          for (final t in tasks) (t.id, t.title, t.status, t.dueDate, t.recurrence, t.completedAt, null),
        ]);
        expect(newTasks.first.description, 'Bring **all** receipts');
        final newOcc = await newDb.select(newDb.occurrences).get();
        expect(newOcc.map((o) => (o.date, o.status, o.archivedAt)), [(20727, 2, null), (20729, 0, null)]);
        expect((await newDb.select(newDb.reminders).get()).map((r) => r.repeatRule), [null, reminders[1].repeatRule]);
        expect((await newDb.select(newDb.settings).get()).single.value, '7');
      },
    );
  });

  test('a fresh database matches the declared schema and has the search index', () async {
    final db = openMemoryDatabase();
    await db.validateDatabaseSchema();
    final objects = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type IN ('table','trigger','index')")
        .map((r) => r.read<String>('name'))
        .get();
    expect(objects, containsAll(['task_search', 'tasks_ai', 'tasks_ad', 'tasks_au', 'idx_tasks_completed']));
    await db.close();
  });

  test('data survives closing and reopening the database file (restart / update)', () async {
    final dir = await Directory.systemTemp.createTemp('overdue_db_');
    try {
      var db = openAppDatabase(dir);
      var repo = TaskRepository(db, clock: FixedClock(DateTime(2026, 10, 4, 9)));
      final id = await repo.createTask(
        TaskDraft(
          title: 'Pay rent',
          recurrence: RecurrenceRule.monthlyOnDay(LocalDate(2026, 10, 1), 25),
          reminders: [const Reminder.relative(24 * 60)],
        ),
      );
      await db.close();

      db = openAppDatabase(dir);
      repo = TaskRepository(db, clock: FixedClock(DateTime(2026, 10, 4, 9)));
      expect((await repo.getTask(id))!.title, 'Pay rent');
      expect(await repo.getReminders(id), hasLength(1));
      expect((await repo.watchQuery(const TaskQuery(text: 'rent')).first).single.task.id, id);
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('search index can be rebuilt from task content (run after upgrades)', () async {
    final db = openMemoryDatabase();
    await TaskRepository(db).createTask(TaskDraft(title: 'Learn Spanish'));
    await db.customStatement("INSERT INTO task_search(task_search) VALUES('delete-all')");
    expect(await db.customSelect("SELECT rowid FROM task_search WHERE task_search MATCH 'spanish'").get(), isEmpty);
    await Migrations.rebuildSearchIndex(db);
    expect(
      await db.customSelect("SELECT rowid FROM task_search WHERE task_search MATCH 'spanish'").get(),
      hasLength(1),
    );
    await db.close();
  });
}
