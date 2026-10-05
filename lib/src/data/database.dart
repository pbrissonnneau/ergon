import 'package:drift/drift.dart';

import 'migrations.dart';

part 'database.g.dart';

/// Simple named groups of tasks (no nesting in v1).
@DataClassName('ProjectRow')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get color => integer().withDefault(const Constant(0xFF5C6BC0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Tasks and subtasks (a subtask is a task with a [parentId]).
///
/// Due values are civil: [dueDate] is an epoch-day and [dueMinute] a
/// minute-of-day (null for date-only). Audit timestamps are UTC epoch millis.
@DataClassName('TaskRow')
@TableIndex(name: 'idx_tasks_status_due', columns: {#status, #dueDate})
@TableIndex(name: 'idx_tasks_parent', columns: {#parentId})
@TableIndex(name: 'idx_tasks_project', columns: {#projectId, #status})
@TableIndex(name: 'idx_tasks_type_status', columns: {#type, #status})
@TableIndex(name: 'idx_tasks_updated', columns: {#updatedAt})
@TableIndex(name: 'idx_tasks_completed', columns: {#completedAt})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentId => integer().nullable().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get projectId => integer().nullable().references(Projects, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get type => integer().withDefault(const Constant(0))();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  IntColumn get dueDate => integer().nullable()();
  IntColumn get dueMinute => integer().nullable()();

  /// JSON-encoded RecurrenceRule for recurring tasks.
  TextColumn get recurrence => text().nullable()();

  /// Last epoch-day for which occurrences have been materialised.
  IntColumn get recurrenceGeneratedUntil => integer().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get completedAt => integer().nullable()();

  /// When a closed task was removed from the agenda (by the user, or
  /// implicitly the day after completion). Added in schema v2.
  IntColumn get archivedAt => integer().nullable()();

  /// Manual order within an agenda day (drag and drop); 0 = not ordered,
  /// which sorts after ordered tasks by priority/time. Added in schema v3.
  IntColumn get dayOrder => integer().withDefault(const Constant(0))();
}

/// Materialised occurrences of a recurring task. Only a bounded window is
/// stored; completed/past rows are history and are never regenerated.
@DataClassName('OccurrenceRow')
@TableIndex(name: 'idx_occ_status_date', columns: {#status, #date})
@TableIndex(name: 'idx_occ_task_date', columns: {#taskId, #date}, unique: true)
class Occurrences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get date => integer()();
  IntColumn get dueMinute => integer().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get completedAt => integer().nullable()();

  /// See [Tasks.archivedAt]. Added in schema v2.
  IntColumn get archivedAt => integer().nullable()();
}

/// Persisted reminder definitions (see ReminderKind).
@DataClassName('ReminderRow')
@TableIndex(name: 'idx_reminders_task', columns: {#taskId})
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get kind => integer()();

  /// [ReminderKind.once]: civil date + minute.
  IntColumn get atDate => integer().nullable()();
  IntColumn get atMinute => integer().nullable()();

  /// [ReminderKind.relative]: minutes before the due time.
  IntColumn get offsetMinutes => integer().nullable()();

  /// [ReminderKind.repeating]: JSON RecurrenceRule (fires at [atMinute]).
  TextColumn get repeatRule => text().nullable()();

  /// [ReminderKind.snooze]: absolute instant (UTC millis) and target occurrence.
  IntColumn get atUtc => integer().nullable()();
  IntColumn get occurrenceDate => integer().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
}

/// Bookkeeping of notifications handed to the OS (or the in-process
/// scheduler), used to reconcile without duplicates.
@DataClassName('ScheduledNotificationRow')
@TableIndex(name: 'idx_sched_fire', columns: {#fireAt})
@TableIndex(name: 'idx_sched_key', columns: {#instanceKey}, unique: true)
class ScheduledNotifications extends Table {
  /// Also the OS notification id.
  IntColumn get id => integer().autoIncrement()();

  /// Stable identity of a reminder instance: "reminderId@fireAtUtc[@date]".
  TextColumn get instanceKey => text()();
  IntColumn get reminderId => integer()();
  IntColumn get taskId => integer()();
  IntColumn get occurrenceDate => integer().nullable()();
  IntColumn get fireAt => integer()();

  /// Displayed content (kept so instances can be re-handed to the OS).
  TextColumn get title => text()();
  TextColumn get body => text()();

  /// Hash of the displayed content; a change triggers re-scheduling.
  TextColumn get signature => text()();
  IntColumn get deliveredAt => integer().nullable()();
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Projects, Tasks, Occurrences, Reminders, ScheduledNotifications, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => Migrations.currentVersion;

  @override
  MigrationStrategy get migration => Migrations.strategy(this);
}
