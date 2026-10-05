import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../core/local_date.dart';
import '../domain/agenda.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import 'theme.dart';

/// Where to move tasks to.
enum RescheduleTarget {
  today('Today'),
  tomorrow('Tomorrow'),
  nextMonday('Next Monday'),
  pick('Pick a date…'),
  noDate('No date');

  const RescheduleTarget(this.label);
  final String label;

  IconData get icon => switch (this) {
    RescheduleTarget.today => Icons.today,
    RescheduleTarget.tomorrow => Icons.wb_twilight,
    RescheduleTarget.nextMonday => Icons.next_week_outlined,
    RescheduleTarget.pick => Icons.edit_calendar_outlined,
    RescheduleTarget.noDate => Icons.event_busy_outlined,
  };
}

/// Operations on one or many agenda entries at once (multi-select bar,
/// "Overdue" menu, overlay right-click menu).
abstract final class BulkActions {
  static LocalDate nextMonday(LocalDate today) => today.addDays(8 - today.weekday);

  /// Resolves [target] to a date (asks the user for [RescheduleTarget.pick]).
  /// Returns `(cancelled, date)`.
  static Future<(bool, LocalDate?)> resolve(BuildContext context, RescheduleTarget target, LocalDate today) async {
    switch (target) {
      case RescheduleTarget.today:
        return (false, today);
      case RescheduleTarget.tomorrow:
        return (false, today.addDays(1));
      case RescheduleTarget.nextMonday:
        return (false, nextMonday(today));
      case RescheduleTarget.noDate:
        return (false, null);
      case RescheduleTarget.pick:
        final d = await showDatePicker(
          context: context,
          initialDate: today.atMinute(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        return d == null ? (true, null) : (false, LocalDate.fromDateTime(d));
    }
  }

  /// Moves tasks to [date]. Recurring occurrences cannot move (the rule
  /// decides their dates), so the missed ones are skipped instead.
  /// Returns a short summary for a snackbar.
  static Future<String> reschedule(AppServices s, Iterable<AgendaEntry> entries, LocalDate? date) async {
    final taskIds = <int>{};
    var skipped = 0;
    for (final e in entries) {
      final occ = e.occurrence;
      if (occ != null) {
        skipped += await s.tasks.skipOccurrences(e.task.id, occ.date);
      } else if (!e.task.isRecurring) {
        taskIds.add(e.task.id);
      }
    }
    await s.tasks.rescheduleTasks(taskIds, date);
    final where = date == null ? 'without a date' : 'to ${_label(date, s.clock.today())}';
    return [
      if (taskIds.isNotEmpty) '${taskIds.length} task${taskIds.length == 1 ? '' : 's'} moved $where',
      if (skipped > 0) '$skipped recurring occurrence${skipped == 1 ? '' : 's'} skipped',
    ].join(' · ');
  }

  static Future<void> setPriority(AppServices s, Iterable<AgendaEntry> entries, TaskPriority p) =>
      s.tasks.setPriorityMany(entries.map((e) => e.task.id).toSet(), p);

  static Future<void> moveToProject(AppServices s, Iterable<AgendaEntry> entries, int? projectId) =>
      s.tasks.moveManyToProject(entries.map((e) => e.task.id).toSet(), projectId);

  static Future<void> complete(AppServices s, Iterable<AgendaEntry> entries) async {
    for (final e in entries) {
      final occ = e.occurrence;
      if (occ != null) {
        await s.tasks.setOccurrenceStatus(e.task.id, occ.date, TaskStatus.completed);
      } else {
        await s.tasks.setStatus(e.task.id, TaskStatus.completed);
      }
    }
  }

  static String _label(LocalDate d, LocalDate today) {
    final diff = today.daysUntil(d);
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    return d.toString();
  }

  /// Menu entries for rescheduling (values are [RescheduleTarget]s).
  static List<PopupMenuEntry<Object>> rescheduleItems({
    bool includeNoDate = false,
    bool includePick = true,
    double? height,
  }) => [
    for (final t in RescheduleTarget.values)
      if ((t != RescheduleTarget.noDate || includeNoDate) && (t != RescheduleTarget.pick || includePick))
        PopupMenuItem<Object>(
          value: t,
          height: height ?? kMinInteractiveDimension,
          child: Row(children: [Icon(t.icon, size: 18), const SizedBox(width: 10), Text(t.label)]),
        ),
  ];

  /// Menu entries for priorities (values are [TaskPriority]s).
  static List<PopupMenuEntry<Object>> priorityItems(ColorScheme scheme, {double? height}) => [
    for (final p in TaskPriority.values.reversed)
      PopupMenuItem<Object>(
        value: p,
        height: height ?? kMinInteractiveDimension,
        child: Row(
          children: [
            Icon(AppTheme.priorityIcon(p), size: 18, color: AppTheme.priorityColor(p, scheme)),
            const SizedBox(width: 10),
            Text('Priority: ${p.label}'),
          ],
        ),
      ),
  ];

  /// Menu entries for moving to a project (values are `('project', id)`;
  /// id -1 = no project).
  static List<PopupMenuEntry<Object>> projectItems(List<Project> projects) => [
    const PopupMenuItem<Object>(
      value: ('project', -1),
      child: Row(children: [Icon(Icons.folder_off_outlined, size: 18), SizedBox(width: 10), Text('No project')]),
    ),
    for (final p in projects)
      PopupMenuItem<Object>(
        value: ('project', p.id),
        child: Row(
          children: [
            CircleAvatar(radius: 6, backgroundColor: Color(p.color)),
            const SizedBox(width: 10),
            Text(p.name),
          ],
        ),
      ),
  ];

  /// Applies a value chosen from one of the menus above to [entries].
  static Future<void> applyMenuChoice(
    BuildContext context,
    AppServices s,
    Object? choice,
    List<AgendaEntry> entries,
  ) async {
    switch (choice) {
      case RescheduleTarget t:
        final (cancelled, date) = await resolve(context, t, s.clock.today());
        if (cancelled) return;
        await reschedule(s, entries, date);
      case TaskPriority p:
        await setPriority(s, entries, p);
      case ('project', int id):
        await moveToProject(s, entries, id < 0 ? null : id);
      case 'complete':
        await complete(s, entries);
      default:
        return;
    }
  }
}
