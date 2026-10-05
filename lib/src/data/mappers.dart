import 'package:drift/drift.dart';

import '../core/local_date.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/recurrence.dart';
import 'database.dart';

LocalDate? epochDayToDate(int? v) => v == null ? null : LocalDate.fromEpochDay(v);
DateTime _utc(int v) => DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);

extension TaskRowMapping on TaskRow {
  Task toDomain() => Task(
    id: id,
    parentId: parentId,
    projectId: projectId,
    title: title,
    description: description,
    type: TaskType.fromCode(type),
    status: TaskStatus.fromCode(status),
    priority: TaskPriority.fromCode(priority),
    dueDate: epochDayToDate(dueDate),
    dueMinute: dueMinute,
    recurrence: _safeRule(recurrence),
    position: position,
    dayOrder: dayOrder,
    createdAt: _utc(createdAt),
    updatedAt: _utc(updatedAt),
    completedAt: completedAt == null ? null : _utc(completedAt!),
  );
}

RecurrenceRule? _safeRule(String? json) {
  try {
    return RecurrenceRule.decode(json);
  } catch (_) {
    return null; // Corrupt rule: treat as non-recurring rather than crash.
  }
}

extension ProjectRowMapping on ProjectRow {
  Project toDomain() => Project(id: id, name: name, color: color, sortOrder: sortOrder);
}

extension OccurrenceRowMapping on OccurrenceRow {
  Occurrence toDomain() => Occurrence(
    id: id,
    taskId: taskId,
    date: LocalDate.fromEpochDay(date),
    dueMinute: dueMinute,
    status: TaskStatus.fromCode(status),
    completedAt: completedAt == null ? null : _utc(completedAt!),
  );
}

extension ReminderRowMapping on ReminderRow {
  Reminder toDomain() => Reminder(
    id: id,
    kind: ReminderKind.fromCode(kind),
    atDate: epochDayToDate(atDate),
    atMinute: atMinute,
    offsetMinutes: offsetMinutes,
    repeatRule: _safeRule(repeatRule),
    atUtc: atUtc == null ? null : _utc(atUtc!),
    occurrenceDate: epochDayToDate(occurrenceDate),
    enabled: enabled,
  );
}

RemindersCompanion reminderCompanion(int taskId, Reminder r, int nowMs) => RemindersCompanion.insert(
  taskId: taskId,
  kind: r.kind.code,
  atDate: Value(r.atDate?.epochDay),
  atMinute: Value(r.atMinute),
  offsetMinutes: Value(r.offsetMinutes),
  repeatRule: Value(r.repeatRule?.encode()),
  atUtc: Value(r.atUtc?.toUtc().millisecondsSinceEpoch),
  occurrenceDate: Value(r.occurrenceDate?.epochDay),
  enabled: Value(r.enabled),
  createdAt: nowMs,
);

/// Reads a `tasks` row from a custom query that selected `t.*` (extra,
/// differently named columns are ignored).
TaskRow readTaskRow(AppDatabase db, QueryRow row) => db.tasks.map(row.data);
