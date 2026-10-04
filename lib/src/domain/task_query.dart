import '../core/local_date.dart';
import 'enums.dart';

enum DueFilter {
  any('Any date'),
  overdue('Overdue'),
  today('Today'),
  next7Days('Next 7 days'),
  next30Days('Next 30 days'),
  hasDate('Has a date'),
  noDate('No date');

  const DueFilter(this.label);
  final String label;
}

enum CompletionFilter {
  open('Open'),
  closed('Completed / cancelled'),
  all('All');

  const CompletionFilter(this.label);
  final String label;
}

enum TaskSort {
  smart('Smart'),
  due('Due date'),
  priority('Priority'),
  updated('Recently updated'),
  created('Recently created'),
  title('Title');

  const TaskSort(this.label);
  final String label;
}

/// Combinable search + filter criteria for the task list.
class TaskQuery {
  const TaskQuery({
    this.text = '',
    this.projectIds = const {},
    this.withoutProject = false,
    this.statuses = const {},
    this.priorities = const {},
    this.types = const {},
    this.due = DueFilter.any,
    this.completion = CompletionFilter.open,
    this.includeSubtasks = true,
    this.sort = TaskSort.smart,
    this.limit = 200,
  });

  final String text;

  /// Empty = any project.
  final Set<int> projectIds;

  /// Restrict to tasks without a project (combined with [projectIds] as OR).
  final bool withoutProject;

  /// Empty = any status (subject to [completion]).
  final Set<TaskStatus> statuses;
  final Set<TaskPriority> priorities;
  final Set<TaskType> types;
  final DueFilter due;
  final CompletionFilter completion;
  final bool includeSubtasks;
  final TaskSort sort;
  final int limit;

  bool get hasFilters =>
      projectIds.isNotEmpty ||
      withoutProject ||
      statuses.isNotEmpty ||
      priorities.isNotEmpty ||
      types.isNotEmpty ||
      due != DueFilter.any ||
      completion != CompletionFilter.open;

  TaskQuery copyWith({
    String? text,
    Set<int>? projectIds,
    bool? withoutProject,
    Set<TaskStatus>? statuses,
    Set<TaskPriority>? priorities,
    Set<TaskType>? types,
    DueFilter? due,
    CompletionFilter? completion,
    bool? includeSubtasks,
    TaskSort? sort,
    int? limit,
  }) => TaskQuery(
    text: text ?? this.text,
    projectIds: projectIds ?? this.projectIds,
    withoutProject: withoutProject ?? this.withoutProject,
    statuses: statuses ?? this.statuses,
    priorities: priorities ?? this.priorities,
    types: types ?? this.types,
    due: due ?? this.due,
    completion: completion ?? this.completion,
    includeSubtasks: includeSubtasks ?? this.includeSubtasks,
    sort: sort ?? this.sort,
    limit: limit ?? this.limit,
  );

  /// Builds an FTS5 MATCH expression: every token must prefix-match.
  static String? ftsExpression(String text) {
    final tokens = text
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;
    return tokens.map((t) => '"$t"*').join(' ');
  }

  /// Inclusive epoch-day bounds for [due] relative to [today].
  (int?, int?) dueBounds(LocalDate today) => switch (due) {
    DueFilter.overdue => (null, today.epochDay - 1),
    DueFilter.today => (today.epochDay, today.epochDay),
    DueFilter.next7Days => (today.epochDay, today.epochDay + 7),
    DueFilter.next30Days => (today.epochDay, today.epochDay + 30),
    _ => (null, null),
  };
}
