import 'package:drift/drift.dart';

import '../core/local_date.dart';
import '../domain/models.dart';
import 'database.dart';
import 'mappers.dart';

class ProjectRepository {
  ProjectRepository(this.db, {Clock clock = const SystemClock()}) : _clock = clock;

  final AppDatabase db;
  final Clock _clock;
  int get _now => _clock.now().toUtc().millisecondsSinceEpoch;

  static const palette = [
    0xFF5C6BC0, 0xFF26A69A, 0xFFEF5350, 0xFFFFA726, 0xFFAB47BC, //
    0xFF42A5F5, 0xFF66BB6A, 0xFF8D6E63, 0xFFEC407A, 0xFF78909C,
  ];

  Stream<List<Project>> watchAll() =>
      (db.select(db.projects)
            ..orderBy([(p) => OrderingTerm.asc(p.sortOrder), (p) => OrderingTerm.asc(p.name.collate(Collate.noCase))]))
          .watch()
          .map((rows) => rows.map((r) => r.toDomain()).toList());

  Future<List<Project>> getAll() => watchAll().first;

  /// Projects with their number of open top-level tasks.
  Stream<List<ProjectWithCount>> watchWithCounts() => db
      .customSelect(
        'SELECT p.*, (SELECT COUNT(*) FROM tasks t WHERE t.project_id = p.id AND t.parent_id IS NULL '
        'AND t.status NOT IN (2,6)) AS open_count FROM projects p ORDER BY p.sort_order, p.name COLLATE NOCASE',
        readsFrom: {db.projects, db.tasks},
      )
      .watch()
      .map(
        (rows) =>
            rows.map((r) => ProjectWithCount(db.projects.map(r.data).toDomain(), r.read<int>('open_count'))).toList(),
      );

  Future<int> create(String name, {int? color}) async {
    final now = _now;
    final count = await db.projects.count().getSingle();
    return db
        .into(db.projects)
        .insert(
          ProjectsCompanion.insert(
            name: name.trim(),
            color: Value(color ?? palette[count % palette.length]),
            sortOrder: Value(count),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> update(int id, {String? name, int? color}) =>
      (db.update(db.projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(
          name: name == null ? const Value.absent() : Value(name.trim()),
          color: color == null ? const Value.absent() : Value(color),
          updatedAt: Value(_now),
        ),
      );

  /// Deletes a project. Its tasks are kept and become project-less.
  Future<void> delete(int id) => (db.delete(db.projects)..where((p) => p.id.equals(id))).go();
}
