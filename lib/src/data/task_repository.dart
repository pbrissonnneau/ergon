import 'package:drift/drift.dart';

import '../core/local_date.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/recurrence.dart';
import '../domain/recurrence_engine.dart';
import '../domain/task_query.dart';
import 'database.dart';
import 'mappers.dart';

/// All task, subtask, occurrence and reminder persistence.
///
/// Every method is asynchronous; with `drift_flutter` the SQLite work runs on
/// a background isolate so the UI thread never blocks on I/O.
class TaskRepository {
  TaskRepository(this.db, {Clock clock = const SystemClock(), this.lookaheadDays = 14}) : _clock = clock;

  final AppDatabase db;
  final Clock _clock;

  /// How far ahead recurring occurrences are materialised.
  int lookaheadDays;

  int get _now => _clock.now().toUtc().millisecondsSinceEpoch;
  LocalDate get _today => _clock.today();

  static const _agendaStatuses = '(0,1,4,5)';
  static const _closedStatuses = '(2,6)';

  /// Completed today (bound as ?1) and not removed from the agenda.
  static const _doneTodayTask = '(t.status = 2 AND t.archived_at IS NULL AND t.completed_at >= ?1)';

  /// UTC millis of local midnight starting [day].
  static int _startOfDayMs(LocalDate day) => day.atMinute(0).toUtc().millisecondsSinceEpoch;

  /// Columns appended to `t.*` for list rows.
  static const _listColumns = '''
    t.*, p.name AS p_name, p.color AS p_color, par.title AS parent_title,
    (SELECT COUNT(*) FROM tasks c WHERE c.parent_id = t.id) AS sub_total,
    (SELECT COUNT(*) FROM tasks c WHERE c.parent_id = t.id AND c.status IN $_closedStatuses) AS sub_done''';
  static const _listJoins = '''
    FROM tasks t
    LEFT JOIN projects p ON p.id = t.project_id
    LEFT JOIN tasks par ON par.id = t.parent_id''';

  TaskListItem _listItem(QueryRow row) => TaskListItem(
    task: readTaskRow(db, row).toDomain(),
    projectName: row.readNullable<String>('p_name'),
    projectColor: row.readNullable<int>('p_color'),
    parentTitle: row.readNullable<String>('parent_title'),
    subtaskCount: row.read<int>('sub_total'),
    subtaskDone: row.read<int>('sub_done'),
  );

  /// Emits whenever task-related data changes (used to trigger reconciliation
  /// of notifications and widget refreshes).
  Stream<void> get changes =>
      db.tableUpdates(TableUpdateQuery.onAllTables([db.tasks, db.occurrences, db.reminders, db.projects])).map((_) {});

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<Task?> getTask(int id) async =>
      (await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull())?.toDomain();

  Stream<Task?> watchTask(int id) =>
      (db.select(db.tasks)..where((t) => t.id.equals(id))).watchSingleOrNull().map((r) => r?.toDomain());

  Stream<List<TaskListItem>> watchSubtasks(int parentId) => db
      .customSelect(
        'SELECT $_listColumns $_listJoins WHERE t.parent_id = ? ORDER BY t.position, t.id',
        variables: [Variable.withInt(parentId)],
        readsFrom: {db.tasks, db.projects},
      )
      .watch()
      .map((rows) => rows.map(_listItem).toList());

  Future<List<Reminder>> getReminders(int taskId) async =>
      (await (db.select(db.reminders)..where((r) => r.taskId.equals(taskId))).get()).map((r) => r.toDomain()).toList();

  Stream<List<Reminder>> watchReminders(int taskId) =>
      (db.select(db.reminders)
            ..where((r) => r.taskId.equals(taskId))
            ..orderBy([(r) => OrderingTerm.asc(r.id)]))
          .watch()
          .map((rows) => rows.map((r) => r.toDomain()).toList());

  /// Occurrence history (most recent first) plus upcoming materialised ones.
  Stream<List<Occurrence>> watchOccurrences(int taskId, {int limit = 120}) =>
      (db.select(db.occurrences)
            ..where((o) => o.taskId.equals(taskId))
            ..orderBy([(o) => OrderingTerm.desc(o.date)])
            ..limit(limit))
          .watch()
          .map((rows) => rows.map((r) => r.toDomain()).toList());

  /// Breadcrumb path from the root task down to [id] (inclusive).
  Future<List<Task>> ancestry(int id) async {
    final rows = await db
        .customSelect(
          '''
      WITH RECURSIVE chain(id, parent_id, depth) AS (
        SELECT id, parent_id, 0 FROM tasks WHERE id = ?
        UNION ALL SELECT t.id, t.parent_id, c.depth + 1 FROM tasks t JOIN chain c ON t.id = c.parent_id
      )
      SELECT t.* FROM chain JOIN tasks t ON t.id = chain.id ORDER BY chain.depth DESC''',
          variables: [Variable.withInt(id)],
          readsFrom: {db.tasks},
        )
        .get();
    return rows.map((r) => readTaskRow(db, r).toDomain()).toList();
  }

  /// Search + combinable filters.
  Stream<List<TaskListItem>> watchQuery(TaskQuery q) {
    final where = <String>[];
    final vars = <Variable>[];
    final today = _today;

    if (!q.includeSubtasks) where.add('t.parent_id IS NULL');
    switch (q.completion) {
      case CompletionFilter.open:
        where.add('t.status NOT IN $_closedStatuses');
      case CompletionFilter.closed:
        where.add('t.status IN $_closedStatuses');
      case CompletionFilter.all:
        break;
    }
    if (q.statuses.isNotEmpty) where.add('t.status IN (${q.statuses.map((s) => s.code).join(',')})');
    if (q.priorities.isNotEmpty) where.add('t.priority IN (${q.priorities.map((p) => p.code).join(',')})');
    if (q.types.isNotEmpty) where.add('t.type IN (${q.types.map((p) => p.code).join(',')})');
    if (q.projectIds.isNotEmpty || q.withoutProject) {
      final parts = <String>[
        if (q.projectIds.isNotEmpty) 't.project_id IN (${q.projectIds.join(',')})',
        if (q.withoutProject) 't.project_id IS NULL',
      ];
      where.add('(${parts.join(' OR ')})');
    }
    switch (q.due) {
      case DueFilter.any:
        break;
      case DueFilter.noDate:
        where.add('t.due_date IS NULL');
      case DueFilter.hasDate:
        where.add('t.due_date IS NOT NULL');
      default:
        final (lo, hi) = q.dueBounds(today);
        if (lo != null) {
          where.add('t.due_date >= ?');
          vars.add(Variable.withInt(lo));
        }
        if (hi != null) {
          where.add('t.due_date <= ?');
          vars.add(Variable.withInt(hi));
        }
    }
    final fts = TaskQuery.ftsExpression(q.text);
    if (fts != null) {
      final like = '%${q.text.trim().replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
      where.add('''(t.id IN (SELECT rowid FROM task_search WHERE task_search MATCH ?)
          OR t.title LIKE ? ESCAPE '\\'
          OR t.project_id IN (SELECT id FROM projects WHERE name LIKE ? ESCAPE '\\'))''');
      vars
        ..add(Variable.withString(fts))
        ..add(Variable.withString(like))
        ..add(Variable.withString(like));
    }

    final order = switch (q.sort) {
      TaskSort.smart =>
        't.status IN $_closedStatuses, t.due_date IS NULL, t.due_date, t.priority DESC, '
            't.due_minute IS NULL, t.due_minute, t.updated_at DESC',
      TaskSort.due => 't.due_date IS NULL, t.due_date, t.due_minute IS NULL, t.due_minute, t.priority DESC',
      TaskSort.priority => 't.priority DESC, t.due_date IS NULL, t.due_date',
      TaskSort.updated => 't.updated_at DESC',
      TaskSort.created => 't.created_at DESC',
      TaskSort.title => 't.title COLLATE NOCASE',
    };
    final sql =
        'SELECT $_listColumns $_listJoins'
        '${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}'
        ' ORDER BY $order, t.id LIMIT ${q.limit}';
    return db
        .customSelect(sql, variables: vars, readsFrom: {db.tasks, db.projects})
        .watch()
        .map((rows) => rows.map(_listItem).toList());
  }

  /// Candidates for the agenda: open non-recurring tasks due up to [end] and
  /// all open ongoing tasks.
  ///
  /// Tasks completed since the start of [today] that were not archived stay
  /// listed (shown as done) until the next day or until the user removes them.
  Stream<List<TaskListItem>> watchAgendaTasks(LocalDate end, {required LocalDate today}) => db
      .customSelect(
        'SELECT $_listColumns $_listJoins '
        'WHERE (t.status IN $_agendaStatuses OR $_doneTodayTask) AND t.type != 2 '
        'AND ((t.due_date IS NOT NULL AND t.due_date <= ?2) OR t.type = 1) '
        'AND (t.parent_id IS NULL OR par.status IN $_agendaStatuses '
        'OR (par.status = 2 AND par.archived_at IS NULL AND par.completed_at >= ?1))',
        variables: [Variable.withInt(_startOfDayMs(today)), Variable.withInt(end.epochDay)],
        readsFrom: {db.tasks, db.projects},
      )
      .watch()
      .map((rows) => rows.map(_listItem).toList());

  /// Open (or completed today and not archived) occurrences up to [end] of
  /// open recurring tasks.
  Stream<List<(TaskListItem, Occurrence)>> watchAgendaOccurrences(LocalDate end, {required LocalDate today}) => db
      .customSelect(
        'SELECT $_listColumns, o.id AS o_id, o.date AS o_date, o.due_minute AS o_due_minute, '
        'o.status AS o_status '
        'FROM occurrences o JOIN tasks t ON t.id = o.task_id '
        'LEFT JOIN projects p ON p.id = t.project_id LEFT JOIN tasks par ON par.id = t.parent_id '
        'WHERE (o.status IN $_agendaStatuses '
        'OR (o.status = 2 AND o.archived_at IS NULL AND o.completed_at >= ?1)) '
        'AND o.date <= ?2 AND t.status IN $_agendaStatuses',
        variables: [Variable.withInt(_startOfDayMs(today)), Variable.withInt(end.epochDay)],
        readsFrom: {db.tasks, db.projects, db.occurrences},
      )
      .watch()
      .map(
        (rows) => rows.map((r) {
          final item = _listItem(r);
          return (
            item,
            Occurrence(
              id: r.read<int>('o_id'),
              taskId: item.task.id,
              date: LocalDate.fromEpochDay(r.read<int>('o_date')),
              dueMinute: r.readNullable<int>('o_due_minute'),
              status: TaskStatus.fromCode(r.read<int>('o_status')),
            ),
          );
        }).toList(),
      );

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Creates a task (with its reminders) and returns its id.
  Future<int> createTask(TaskDraft d) => db.transaction(() async {
    final now = _now;
    var projectId = d.projectId;
    var position = 0;
    if (d.parentId != null) {
      final parent = await (db.select(db.tasks)..where((t) => t.id.equals(d.parentId!))).getSingle();
      projectId = parent.projectId; // Subtasks follow their parent's project.
      final maxPos = await db
          .customSelect(
            'SELECT COALESCE(MAX(position), -1) AS m FROM tasks WHERE parent_id = ?',
            variables: [Variable.withInt(d.parentId!)],
          )
          .getSingle();
      position = maxPos.read<int>('m') + 1;
    }
    final recurring = d.type == TaskType.recurring && d.recurrence != null;
    final id = await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            title: d.title.trim(),
            description: Value(d.description),
            parentId: Value(d.parentId),
            projectId: Value(projectId),
            type: Value(d.type.code),
            status: Value(d.status.code),
            priority: Value(d.priority.code),
            dueDate: Value(recurring ? null : d.dueDate?.epochDay),
            dueMinute: Value(d.dueDate == null && !recurring ? null : d.dueMinute),
            recurrence: Value(recurring ? d.recurrence!.encode() : null),
            position: Value(position),
            createdAt: now,
            updatedAt: now,
            completedAt: Value(d.status == TaskStatus.completed ? now : null),
          ),
        );
    for (final r in d.reminders) {
      await db.into(db.reminders).insert(reminderCompanion(id, r, now));
    }
    if (recurring) await _materializeTask(id);
    return id;
  });

  /// Replaces a task's editable fields and (unless [replaceReminders] is
  /// false, e.g. when reminders are edited individually) its reminder set.
  Future<void> updateTask(int id, TaskDraft d, {bool replaceReminders = true}) => db.transaction(() async {
    final old = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    final now = _now;
    final today = _today;
    final recurring = d.type == TaskType.recurring && d.recurrence != null;
    final oldRule = RecurrenceRule.decode(old.recurrence);
    final ruleChanged =
        recurring != (old.type == TaskType.recurring.code && oldRule != null) || (recurring && oldRule != d.recurrence);
    final status = d.status;
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        title: Value(d.title.trim()),
        description: Value(d.description),
        type: Value(d.type.code),
        status: Value(status.code),
        priority: Value(d.priority.code),
        dueDate: Value(recurring ? old.dueDate : d.dueDate?.epochDay),
        dueMinute: Value(d.dueDate == null && !recurring ? null : d.dueMinute),
        recurrence: Value(recurring ? d.recurrence!.encode() : null),
        updatedAt: Value(now),
        completedAt: Value(_completedAt(old, status, now)),
      ),
    );
    if (d.projectId != old.projectId && old.parentId == null) {
      await _setProjectRecursive(id, d.projectId);
    }
    if (ruleChanged) {
      // Keep history (past or touched occurrences); drop untouched future ones.
      await db.customUpdate(
        'DELETE FROM occurrences WHERE task_id = ? AND date >= ? AND status = 0 AND completed_at IS NULL',
        variables: [Variable.withInt(id), Variable.withInt(today.epochDay)],
        updates: {db.occurrences},
        updateKind: UpdateKind.delete,
      );
      await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(recurrenceGeneratedUntil: Value(recurring ? today.epochDay - 1 : null)),
      );
    } else if (recurring && d.dueMinute != old.dueMinute) {
      await db.customUpdate(
        'UPDATE occurrences SET due_minute = ? WHERE task_id = ? AND date >= ? AND status = 0',
        variables: [Variable(d.dueMinute), Variable.withInt(id), Variable.withInt(today.epochDay)],
        updates: {db.occurrences},
      );
    }
    if (replaceReminders) await _replaceReminders(id, d.reminders, now);
    if (recurring) await _materializeTask(id);
  });

  Future<void> _replaceReminders(int taskId, List<Reminder> reminders, int now) async {
    final existing = await (db.select(db.reminders)..where((r) => r.taskId.equals(taskId))).get();
    final keepIds = reminders.map((r) => r.id).whereType<int>().toSet();
    for (final e in existing) {
      if (e.kind != ReminderKind.snooze.code && !keepIds.contains(e.id)) {
        await (db.delete(db.reminders)..where((r) => r.id.equals(e.id))).go();
      }
    }
    for (final r in reminders) {
      if (r.id == null) {
        await db.into(db.reminders).insert(reminderCompanion(taskId, r, now));
      } else {
        await (db.update(db.reminders)..where((x) => x.id.equals(r.id!))).write(
          reminderCompanion(taskId, r, now).copyWith(createdAt: const Value.absent()),
        );
      }
    }
  }

  int? _completedAt(TaskRow old, TaskStatus status, int now) {
    if (status == TaskStatus.completed) return old.status == TaskStatus.completed.code ? old.completedAt : now;
    return null;
  }

  Future<void> setStatus(int id, TaskStatus status) => db.transaction(() async {
    final old = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (old == null) return;
    final now = _now;
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        status: Value(status.code),
        updatedAt: Value(now),
        completedAt: Value(_completedAt(old, status, now)),
        // Re-opened or re-completed work shows up on the agenda again.
        archivedAt: const Value(null),
      ),
    );
    if (status.isClosed) {
      // Pending snoozes of a closed task are pointless.
      await (db.delete(db.reminders)..where((r) => r.taskId.equals(id) & r.kind.equals(ReminderKind.snooze.code))).go();
    }
  });

  /// Removes a completed task from the agenda now instead of tomorrow.
  Future<void> archiveTask(int id) =>
      (db.update(db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(archivedAt: Value(_now)));

  /// Removes a completed occurrence from the agenda now instead of tomorrow.
  Future<void> archiveOccurrence(int taskId, LocalDate date) =>
      (db.update(db.occurrences)..where((o) => o.taskId.equals(taskId) & o.date.equals(date.epochDay))).write(
        OccurrencesCompanion(archivedAt: Value(_now)),
      );

  /// Removes everything completed (tasks and occurrences) from the agenda.
  Future<void> archiveAllCompleted() => db.transaction(() async {
    final now = _now;
    await (db.update(db.tasks)..where((t) => t.status.equals(TaskStatus.completed.code) & t.archivedAt.isNull())).write(
      TasksCompanion(archivedAt: Value(now)),
    );
    await (db.update(db.occurrences)..where((o) => o.status.equals(TaskStatus.completed.code) & o.archivedAt.isNull()))
        .write(OccurrencesCompanion(archivedAt: Value(now)));
  });

  Future<void> setPriority(int id, TaskPriority priority) => (db.update(
    db.tasks,
  )..where((t) => t.id.equals(id))).write(TasksCompanion(priority: Value(priority.code), updatedAt: Value(_now)));

  Future<void> setDue(int id, LocalDate? date, int? minute) =>
      (db.update(db.tasks)..where((t) => t.id.equals(id) & t.type.isNotValue(TaskType.recurring.code))).write(
        TasksCompanion(
          dueDate: Value(date?.epochDay),
          dueMinute: Value(date == null ? null : minute),
          updatedAt: Value(_now),
        ),
      );

  Future<void> rename(int id, String title) => (db.update(
    db.tasks,
  )..where((t) => t.id.equals(id))).write(TasksCompanion(title: Value(title.trim()), updatedAt: Value(_now)));

  /// Moves a top-level task (and its subtasks) to [projectId] (null = none).
  Future<void> moveToProject(int id, int? projectId) => db.transaction(() async {
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(updatedAt: Value(_now)));
    await _setProjectRecursive(id, projectId);
  });

  Future<void> _setProjectRecursive(int id, int? projectId) => db.customUpdate(
    '''WITH RECURSIVE tree(id) AS (
             SELECT ? UNION ALL SELECT t.id FROM tasks t JOIN tree ON t.parent_id = tree.id)
           UPDATE tasks SET project_id = ? WHERE id IN (SELECT id FROM tree)''',
    variables: [Variable.withInt(id), Variable(projectId)],
    updates: {db.tasks},
  );

  Future<void> deleteTask(int id) => (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();

  Future<int> addSubtask(int parentId, String title) => createTask(TaskDraft(title: title, parentId: parentId));

  /// Persists a new subtask order.
  Future<void> reorderSubtasks(List<int> orderedIds) => db.batch((b) {
    for (var i = 0; i < orderedIds.length; i++) {
      b.update(db.tasks, TasksCompanion(position: Value(i)), where: (t) => t.id.equals(orderedIds[i]));
    }
  });

  // ---------------------------------------------------------------------------
  // Reminders
  // ---------------------------------------------------------------------------

  Future<int> addReminder(int taskId, Reminder r) => db.into(db.reminders).insert(reminderCompanion(taskId, r, _now));

  Future<void> deleteReminder(int reminderId) => (db.delete(db.reminders)..where((r) => r.id.equals(reminderId))).go();

  /// Creates a one-shot snooze reminder firing at [until].
  Future<int> snooze(int taskId, DateTime until, {LocalDate? occurrenceDate}) =>
      addReminder(taskId, Reminder(kind: ReminderKind.snooze, atUtc: until.toUtc(), occurrenceDate: occurrenceDate));

  /// Removes snooze reminders whose time has passed.
  Future<void> purgeExpiredSnoozes({Duration grace = const Duration(hours: 1)}) =>
      (db.delete(db.reminders)..where(
            (r) => r.kind.equals(ReminderKind.snooze.code) & r.atUtc.isSmallerThanValue(_now - grace.inMilliseconds),
          ))
          .go();

  // ---------------------------------------------------------------------------
  // Recurring occurrences
  // ---------------------------------------------------------------------------

  /// Sets the status of a recurring task's occurrence on [date], creating it
  /// if it was not materialised yet (e.g. completed from a notification).
  Future<void> setOccurrenceStatus(int taskId, LocalDate date, TaskStatus status) => db.transaction(() async {
    final now = _now;
    final existing = await (db.select(
      db.occurrences,
    )..where((o) => o.taskId.equals(taskId) & o.date.equals(date.epochDay))).getSingleOrNull();
    if (existing == null) {
      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
      if (task == null) return;
      await db
          .into(db.occurrences)
          .insert(
            OccurrencesCompanion.insert(
              taskId: taskId,
              date: date.epochDay,
              dueMinute: Value(task.dueMinute),
              status: Value(status.code),
              createdAt: now,
              updatedAt: now,
              completedAt: Value(status == TaskStatus.completed ? now : null),
            ),
          );
    } else {
      await (db.update(db.occurrences)..where((o) => o.id.equals(existing.id))).write(
        OccurrencesCompanion(
          status: Value(status.code),
          updatedAt: Value(now),
          completedAt: Value(
            status == TaskStatus.completed
                ? (existing.status == TaskStatus.completed.code ? (existing.completedAt ?? now) : now)
                : (status == TaskStatus.cancelled ? now : null),
          ),
          archivedAt: const Value(null),
        ),
      );
    }
    if (status.isClosed) {
      await (db.delete(db.reminders)..where(
            (r) =>
                r.taskId.equals(taskId) &
                r.kind.equals(ReminderKind.snooze.code) &
                r.occurrenceDate.equals(date.epochDay),
          ))
          .go();
    }
    await _refreshNextDue(taskId);
  });

  /// Ensures every open recurring task has its occurrences materialised up to
  /// `today + lookaheadDays`. Cheap when nothing is due: a single indexed query.
  Future<void> materializeAll() async {
    final horizon = _today.epochDay + lookaheadDays;
    final rows = await db
        .customSelect(
          'SELECT id FROM tasks WHERE type = 2 AND recurrence IS NOT NULL AND status NOT IN $_closedStatuses '
          'AND (recurrence_generated_until IS NULL OR recurrence_generated_until < ?)',
          variables: [Variable.withInt(horizon)],
        )
        .get();
    if (rows.isEmpty) return;
    await db.transaction(() async {
      for (final r in rows) {
        await _materializeTask(r.read<int>('id'));
      }
    });
  }

  /// Maximum catch-up after a long absence (older misses are not backfilled).
  static const maxCatchUpDays = 62;

  Future<void> _materializeTask(int id) async {
    final task = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (task == null) return;
    final rule = RecurrenceRule.decode(task.recurrence);
    if (rule == null || task.type != TaskType.recurring.code) return;
    final today = _today;
    final horizon = today.addDays(lookaheadDays);
    var from = task.recurrenceGeneratedUntil == null
        ? today
        : LocalDate.fromEpochDay(task.recurrenceGeneratedUntil! + 1);
    final earliest = today.addDays(-maxCatchUpDays);
    if (from < earliest) from = earliest;

    final dates = RecurrenceEngine.between(rule, from, horizon);
    var generatedUntil = horizon;
    // Always keep the next occurrence visible, even beyond the window.
    if (!dates.any((d) => d >= today)) {
      final next = RecurrenceEngine.nextOnOrAfter(rule, horizon.addDays(1));
      if (next != null) {
        dates.add(next);
        generatedUntil = next;
      }
    }
    final now = _now;
    await db.batch((b) {
      b.insertAll(db.occurrences, [
        for (final d in dates)
          OccurrencesCompanion.insert(
            taskId: id,
            date: d.epochDay,
            dueMinute: Value(task.dueMinute),
            createdAt: now,
            updatedAt: now,
          ),
      ], mode: InsertMode.insertOrIgnore);
      b.update(
        db.tasks,
        TasksCompanion(recurrenceGeneratedUntil: Value(generatedUntil.epochDay)),
        where: (t) => t.id.equals(id),
      );
    });
    await _refreshNextDue(id);
  }

  /// Keeps `tasks.due_date` of a recurring task equal to its earliest open
  /// occurrence so lists, filters and sorting work uniformly.
  Future<void> _refreshNextDue(int id) => db.customUpdate(
    'UPDATE tasks SET due_date = (SELECT MIN(date) FROM occurrences '
    'WHERE task_id = ?1 AND status NOT IN $_closedStatuses) WHERE id = ?1 AND type = 2',
    variables: [Variable.withInt(id)],
    updates: {db.tasks},
  );

  // ---------------------------------------------------------------------------
  // Notification planning inputs
  // ---------------------------------------------------------------------------

  /// Open tasks that have at least one enabled reminder, with their reminders.
  Future<List<(Task, List<Reminder>)>> tasksWithReminders() async {
    final rows = await db
        .customSelect(
          'SELECT t.* FROM tasks t WHERE t.status NOT IN $_closedStatuses AND t.status != 3 '
          'AND EXISTS (SELECT 1 FROM reminders r WHERE r.task_id = t.id AND r.enabled = 1)',
          readsFrom: {db.tasks, db.reminders},
        )
        .get();
    if (rows.isEmpty) return const [];
    final tasks = {for (final r in rows) r.read<int>('id'): readTaskRow(db, r).toDomain()};
    final reminders = await (db.select(
      db.reminders,
    )..where((r) => r.taskId.isIn(tasks.keys) & r.enabled.equals(true))).get();
    final byTask = <int, List<Reminder>>{};
    for (final r in reminders) {
      byTask.putIfAbsent(r.taskId, () => []).add(r.toDomain());
    }
    return [for (final e in tasks.entries) (e.value, byTask[e.key] ?? const <Reminder>[])];
  }

  /// Closed occurrence dates per task (to skip reminders for done occurrences).
  Future<Map<int, Set<int>>> closedOccurrenceDays(Iterable<int> taskIds, LocalDate from) async {
    if (taskIds.isEmpty) return const {};
    final rows =
        await (db.select(db.occurrences)..where(
              (o) =>
                  o.taskId.isIn(taskIds) &
                  o.date.isBiggerOrEqualValue(from.epochDay) &
                  o.status.isIn(TaskStatus.closedCodes),
            ))
            .get();
    final out = <int, Set<int>>{};
    for (final o in rows) {
      out.putIfAbsent(o.taskId, () => {}).add(o.date);
    }
    return out;
  }
}
