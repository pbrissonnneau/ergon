/// Core enumerations. The integer [code] values are persisted in the database
/// and must never be renumbered.
library;

enum TaskStatus {
  notStarted(0, 'Not Started'),
  inProgress(1, 'In Progress'),
  completed(2, 'Completed'),
  suspended(3, 'Suspended'),
  waiting(4, 'Waiting'),
  blocked(5, 'Blocked'),
  cancelled(6, 'Cancelled');

  const TaskStatus(this.code, this.label);
  final int code;
  final String label;

  /// Completed and cancelled tasks are "closed": kept for history, hidden from
  /// the active agenda.
  bool get isClosed => this == completed || this == cancelled;
  bool get isOpen => !isClosed;

  /// Statuses that appear in the agenda. Suspended work is deliberately parked.
  bool get isAgendaVisible => isOpen && this != suspended;

  static TaskStatus fromCode(int code) =>
      values.firstWhere((s) => s.code == code, orElse: () => notStarted);

  static const List<int> closedCodes = [2, 6];
  static const List<int> agendaCodes = [0, 1, 4, 5];
}

enum TaskPriority {
  low(0, 'Low'),
  normal(1, 'Normal'),
  high(2, 'High'),
  urgent(3, 'Urgent');

  const TaskPriority(this.code, this.label);
  final int code;
  final String label;

  static TaskPriority fromCode(int code) =>
      values.firstWhere((p) => p.code == code, orElse: () => normal);
}

enum TaskType {
  oneTime(0, 'One-time'),
  ongoing(1, 'Ongoing'),
  recurring(2, 'Recurring');

  const TaskType(this.code, this.label);
  final int code;
  final String label;

  static TaskType fromCode(int code) =>
      values.firstWhere((t) => t.code == code, orElse: () => oneTime);
}

enum ReminderKind {
  /// Fires once at a fixed local date/time.
  once(0, 'Once'),

  /// Fires a fixed offset before the task's (or each occurrence's) due time.
  relative(1, 'Before due'),

  /// Fires repeatedly following its own recurrence rule at a fixed time,
  /// independent of any due date (e.g. every day at 19:00).
  repeating(2, 'Repeating'),

  /// One-shot reminder created by "Snooze"; removed once it has fired.
  snooze(3, 'Snoozed');

  const ReminderKind(this.code, this.label);
  final int code;
  final String label;

  static ReminderKind fromCode(int code) =>
      values.firstWhere((k) => k.code == code, orElse: () => once);
}
