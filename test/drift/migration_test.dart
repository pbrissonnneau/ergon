import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:ergon/src/core/local_date.dart';
import 'package:ergon/src/data/database.dart';
import 'package:ergon/src/data/database_opener.dart';
import 'package:ergon/src/data/migrations.dart';
import 'package:ergon/src/data/task_repository.dart';
import 'package:ergon/src/domain/models.dart';
import 'package:ergon/src/domain/recurrence.dart';
import 'package:ergon/src/domain/task_query.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

/// Schema migration tests.
///
/// For every schema change: bump `Migrations.currentVersion`, run
/// `dart run drift_dev make-migrations` (stores `drift_schemas/` snapshots and
/// regenerates `test/drift/generated/`), then add a `from vN to vN+1` test here
/// that also checks the user data survives.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('every stored schema version upgrades to the current schema', () async {
    for (final from in GeneratedHelper.versions) {
      final connection = await verifier.startAt(from);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, Migrations.currentVersion);
      await db.close();
    }
  });

  test('a fresh database matches the declared schema', () async {
    final db = openMemoryDatabase();
    await db.validateDatabaseSchema();
    final objects = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type IN ('table','trigger','index')")
        .map((r) => r.read<String>('name'))
        .get();
    expect(objects, containsAll(['task_search', 'tasks_ai', 'tasks_ad', 'tasks_au', 'idx_tasks_status_due']));
    await db.close();
  });

  test('data survives closing and reopening the database file (restart / update)', () async {
    final dir = await Directory.systemTemp.createTemp('ergon_db_');
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
      expect(
        await db.customSelect('PRAGMA journal_mode').map((r) => r.read<String>('journal_mode')).getSingle(),
        'wal',
      );
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('search index can be rebuilt from task content (run after upgrades)', () async {
    final db = openMemoryDatabase();
    await TaskRepository(db).createTask(TaskDraft(title: 'Learn Spanish'));
    await db.customStatement("INSERT INTO task_search(task_search) VALUES('delete-all')");
    expect(
      await TaskRepository(db).watchQuery(const TaskQuery(text: 'spanish', sort: TaskSort.title)).first,
      hasLength(1),
      reason: 'title LIKE fallback still finds it',
    );
    expect(await db.customSelect("SELECT rowid FROM task_search WHERE task_search MATCH 'spanish'").get(), isEmpty);
    await Migrations.rebuildSearchIndex(db);
    expect(
      await db.customSelect("SELECT rowid FROM task_search WHERE task_search MATCH 'spanish'").get(),
      hasLength(1),
    );
    await db.close();
  });
}
