import '../core/local_date.dart';
import 'enums.dart';
import 'recurrence.dart';

DateTime? _ms(int? v) => v == null ? null : DateTime.fromMillisecondsSinceEpoch(v, isUtc: true).toLocal();

class Project {
  const Project({required this.id, required this.name, required this.color, this.sortOrder = 0});
  final int id;
  final String name;
  final int color;
  final int sortOrder;
}

class ProjectWithCount {
  const ProjectWithCount(this.project, this.openCount);
  final Project project;
  final int openCount;
}

/// A task or subtask.
class Task {
  const Task({
    required this.id,
    required this.title,
    this.parentId,
    this.projectId,
    this.description = '',
    this.type = TaskType.oneTime,
    this.status = TaskStatus.notStarted,
    this.priority = TaskPriority.normal,
    this.dueDate,
    this.dueMinute,
    this.recurrence,
    this.position = 0,
    this.dayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final int id;
  final int? parentId;
  final int? projectId;
  final String title;
  final String description;
  final TaskType type;
  final TaskStatus status;
  final TaskPriority priority;

  /// For recurring tasks: the next open occurrence date (maintained).
  final LocalDate? dueDate;

  /// Minute-of-day; null means "date only".
  final int? dueMinute;
  final RecurrenceRule? recurrence;
  final int position;

  /// Manual order within an agenda day (0 = none).
  final int dayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  bool get isRecurring => type == TaskType.recurring && recurrence != null;
  bool get hasDueTime => dueDate != null && dueMinute != null;
  bool get isSubtask => parentId != null;

  /// Local due instant; date-only tasks are due at the end of their day.
  DateTime? get dueDateTime => dueDate?.atMinute(dueMinute ?? 24 * 60 - 1);
}

/// A materialised (or virtual, when [id] is null) occurrence of a recurring task.
class Occurrence {
  const Occurrence({
    this.id,
    required this.taskId,
    required this.date,
    this.dueMinute,
    this.status = TaskStatus.notStarted,
    this.completedAt,
  });
  final int? id;
  final int taskId;
  final LocalDate date;
  final int? dueMinute;
  final TaskStatus status;
  final DateTime? completedAt;
}

/// A reminder definition attached to a task.
class Reminder {
  const Reminder({
    this.id,
    required this.kind,
    this.atDate,
    this.atMinute,
    this.offsetMinutes,
    this.repeatRule,
    this.atUtc,
    this.occurrenceDate,
    this.enabled = true,
  });

  const Reminder.once(LocalDate date, int minute) : this(kind: ReminderKind.once, atDate: date, atMinute: minute);
  const Reminder.relative(int minutesBefore) : this(kind: ReminderKind.relative, offsetMinutes: minutesBefore);
  const Reminder.repeating(RecurrenceRule rule, int minute)
    : this(kind: ReminderKind.repeating, repeatRule: rule, atMinute: minute);

  final int? id;
  final ReminderKind kind;
  final LocalDate? atDate;
  final int? atMinute;
  final int? offsetMinutes;
  final RecurrenceRule? repeatRule;
  final DateTime? atUtc;
  final LocalDate? occurrenceDate;
  final bool enabled;

  Reminder copyWith({int? id, bool? enabled}) => Reminder(
    id: id ?? this.id,
    kind: kind,
    atDate: atDate,
    atMinute: atMinute,
    offsetMinutes: offsetMinutes,
    repeatRule: repeatRule,
    atUtc: atUtc,
    occurrenceDate: occurrenceDate,
    enabled: enabled ?? this.enabled,
  );

  String describe() => switch (kind) {
    ReminderKind.once => 'On $atDate at ${MinuteOfDay.format(atMinute ?? 0)}',
    ReminderKind.relative => describeOffset(offsetMinutes ?? 0),
    ReminderKind.repeating => '${repeatRule?.describe() ?? 'Repeating'} at ${MinuteOfDay.format(atMinute ?? 0)}',
    ReminderKind.snooze => 'Snoozed until ${atUtc == null ? '?' : _fmtInstant(atUtc!)}',
  };

  static String describeOffset(int minutes) {
    if (minutes == 0) return 'At due time';
    final abs = minutes.abs();
    final suffix = minutes > 0 ? 'before' : 'after';
    String unit(int n, String s) => '$n $s${n == 1 ? '' : 's'}';
    if (abs % (60 * 24 * 7) == 0) return '${unit(abs ~/ (60 * 24 * 7), 'week')} $suffix';
    if (abs % (60 * 24) == 0) return '${unit(abs ~/ (60 * 24), 'day')} $suffix';
    if (abs % 60 == 0) return '${unit(abs ~/ 60, 'hour')} $suffix';
    return '${unit(abs, 'minute')} $suffix';
  }

  static String _fmtInstant(DateTime t) {
    final l = t.toLocal();
    return '${LocalDate.fromDateTime(l)} ${MinuteOfDay.format(MinuteOfDay.fromDateTime(l))}';
  }
}

/// Mutable editing model used by the task editor and quick-add.
class TaskDraft {
  TaskDraft({
    this.title = '',
    this.description = '',
    this.parentId,
    this.projectId,
    this.type = TaskType.oneTime,
    this.status = TaskStatus.notStarted,
    this.priority = TaskPriority.normal,
    this.dueDate,
    this.dueMinute,
    this.recurrence,
    List<Reminder>? reminders,
  }) : reminders = reminders ?? [];

  factory TaskDraft.fromTask(Task t, List<Reminder> reminders) => TaskDraft(
    title: t.title,
    description: t.description,
    parentId: t.parentId,
    projectId: t.projectId,
    type: t.type,
    status: t.status,
    priority: t.priority,
    dueDate: t.isRecurring ? null : t.dueDate,
    dueMinute: t.dueMinute,
    recurrence: t.recurrence,
    reminders: reminders.where((r) => r.kind != ReminderKind.snooze).toList(),
  );

  String title;
  String description;
  int? parentId;
  int? projectId;
  TaskType type;
  TaskStatus status;
  TaskPriority priority;
  LocalDate? dueDate;
  int? dueMinute;
  RecurrenceRule? recurrence;
  List<Reminder> reminders;
}

/// Row shown in task lists and search results.
class TaskListItem {
  const TaskListItem({
    required this.task,
    this.projectName,
    this.projectColor,
    this.subtaskCount = 0,
    this.subtaskDone = 0,
    this.parentTitle,
  });
  final Task task;
  final String? projectName;
  final int? projectColor;
  final int subtaskCount;
  final int subtaskDone;
  final String? parentTitle;
}

DateTime? millisToLocal(int? v) => _ms(v);

/// One little square of the mini calendar: a task (or occurrence) on a day.
class DayCell {
  const DayCell({required this.taskId, required this.title, this.projectColor, this.done = false});
  final int taskId;
  final String title;
  final int? projectColor;
  final bool done;
}

/// Something completed on a past day (agenda history / weekly review).
class CompletedItem {
  const CompletedItem({required this.item, required this.day, this.occurrence, this.postponement});
  final TaskListItem item;
  final LocalDate day;
  final Occurrence? occurrence;

  /// Set when this history line is a postponement, not a completion.
  final PostponedItem? postponement;
}

/// A task moved away from [from] (to [to], or to the backlog when null).
/// Its original day shows it struck through in red until the end of the day
/// it was postponed.
class PostponedItem {
  const PostponedItem({required this.id, required this.item, required this.from, this.to, required this.at});
  final int id;
  final TaskListItem item;
  final LocalDate from;
  final LocalDate? to;
  final DateTime at;
}
