import 'package:drift/drift.dart';

import 'database.dart';

/// Schema migrations.
///
/// Rules for future versions: bump [currentVersion], add a `from < N` step in
/// [strategy] that only *adds* or *transforms* data (never drops user data),
/// and add a migration test in `test/data/migration_test.dart`.
abstract final class Migrations {
  static const currentVersion = 3;

  static MigrationStrategy strategy(AppDatabase db) => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await createSearchIndex(db);
    },
    onUpgrade: (m, from, to) async {
      if (from < 2 && to >= 2) {
        // v2: completed work stays on the agenda until archived.
        await m.addColumn(db.tasks, db.tasks.archivedAt);
        await m.addColumn(db.occurrences, db.occurrences.archivedAt);
        await m.createIndex(db.idxTasksCompleted);
      }
      if (from < 3 && to >= 3) {
        // v3: manual order of tasks within an agenda day.
        await m.addColumn(db.tasks, db.tasks.dayOrder);
      }
    },
    beforeOpen: (details) async {
      await db.customStatement('PRAGMA foreign_keys = ON');
      // Ensure and rebuild the derived search index after any upgrade.
      if (details.hadUpgrade) {
        await createSearchIndex(db);
        await rebuildSearchIndex(db);
      }
    },
  );

  /// Recomputes the full-text index from the `tasks` table.
  static Future<void> rebuildSearchIndex(AppDatabase db) =>
      db.customStatement("INSERT INTO task_search(task_search) VALUES('rebuild')");

  /// FTS5 full-text index over task title/description, kept in sync by
  /// triggers (external-content table, so no data duplication).
  static Future<void> createSearchIndex(AppDatabase db) async {
    await db.customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS task_search USING fts5(
        title, description, content='tasks', content_rowid='id',
        tokenize='unicode61 remove_diacritics 2', prefix='2 3'
      )''');
    await db.customStatement('''
      CREATE TRIGGER IF NOT EXISTS tasks_ai AFTER INSERT ON tasks BEGIN
        INSERT INTO task_search(rowid, title, description) VALUES (new.id, new.title, new.description);
      END''');
    await db.customStatement('''
      CREATE TRIGGER IF NOT EXISTS tasks_ad AFTER DELETE ON tasks BEGIN
        INSERT INTO task_search(task_search, rowid, title, description) VALUES ('delete', old.id, old.title, old.description);
      END''');
    await db.customStatement('''
      CREATE TRIGGER IF NOT EXISTS tasks_au AFTER UPDATE OF title, description ON tasks BEGIN
        INSERT INTO task_search(task_search, rowid, title, description) VALUES ('delete', old.id, old.title, old.description);
        INSERT INTO task_search(rowid, title, description) VALUES (new.id, new.title, new.description);
      END''');
  }
}
