import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../core/local_date.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import 'editor/task_editor_page.dart';
import 'theme.dart';
import 'widgets/live_query.dart';

/// Shared task operations used by the agenda, lists and the editor.
abstract final class TaskActions {
  static Future<void> open(BuildContext context, int taskId) =>
      Navigator.of(context).push(TaskEditorPage.route(taskId));

  /// Toggles completion of a task or of one occurrence, with Undo.
  static Future<void> toggleComplete(BuildContext context, Task task, {Occurrence? occurrence}) async {
    final s = AppScope.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final current = occurrence?.status ?? task.status;
    final next = current == TaskStatus.completed ? TaskStatus.notStarted : TaskStatus.completed;
    await setStatus(s, task, next, occurrence: occurrence);
    if (next == TaskStatus.completed && messenger != null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Completed “${task.title}”', maxLines: 1, overflow: TextOverflow.ellipsis),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => setStatus(s, task, current, occurrence: occurrence),
            ),
          ),
        );
    }
  }

  static Future<void> setStatus(AppServices s, Task task, TaskStatus status, {Occurrence? occurrence}) {
    if (occurrence != null) return s.tasks.setOccurrenceStatus(task.id, occurrence.date, status);
    return s.tasks.setStatus(task.id, status);
  }

  static Future<void> snooze(BuildContext context, Task task, Duration d, {LocalDate? occurrenceDate}) async {
    final s = AppScope.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    await s.reminders.snooze(task.id, occurrenceDate: occurrenceDate, duration: d);
    final at = s.clock.now().add(d);
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Reminder snoozed until ${MinuteOfDay.format(MinuteOfDay.fromDateTime(at))}'
          '${LocalDate.fromDateTime(at) != s.clock.today() ? ' (${LocalDate.fromDateTime(at)})' : ''}',
        ),
      ),
    );
  }

  static Future<bool> confirmDelete(BuildContext context, Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          '“${task.title}” and its subtasks, reminders and history will be permanently deleted. '
          'To keep it for history, mark it Completed or Cancelled instead.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await AppScope.of(context).tasks.deleteTask(task.id);
      return true;
    }
    return false;
  }

  /// Quick actions sheet: status, priority, snooze, project, open, delete.
  static Future<void> showQuickActions(BuildContext context, TaskListItem item, {Occurrence? occurrence}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => _QuickActionsSheet(item: item, occurrence: occurrence, hostContext: context),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet({required this.item, required this.occurrence, required this.hostContext});
  final TaskListItem item;
  final Occurrence? occurrence;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final task = item.task;
    final scheme = Theme.of(context).colorScheme;
    final status = occurrence?.status ?? task.status;
    void close() => Navigator.of(context).pop();

    Widget label(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(t, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.outline)),
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                occurrence == null ? task.title : '${task.title} · ${occurrence!.date}',
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            label(occurrence == null ? 'Status' : 'Occurrence status'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final st in TaskStatus.values)
                    ChoiceChip(
                      avatar: Icon(AppTheme.statusIcon(st), size: 18, color: AppTheme.statusColor(st, scheme)),
                      label: Text(st.label),
                      selected: st == status,
                      onSelected: (_) {
                        TaskActions.setStatus(s, task, st, occurrence: occurrence);
                        close();
                      },
                    ),
                ],
              ),
            ),
            if (occurrence == null) ...[
              label('Priority'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final p in TaskPriority.values)
                      ChoiceChip(
                        avatar: Icon(AppTheme.priorityIcon(p), size: 18, color: AppTheme.priorityColor(p, scheme)),
                        label: Text(p.label),
                        selected: p == task.priority,
                        onSelected: (_) {
                          s.tasks.setPriority(task.id, p);
                          close();
                        },
                      ),
                  ],
                ),
              ),
            ],
            label('Snooze reminder'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 6,
                children: [
                  for (final (text, d) in [
                    ('${s.settings.snoozeMinutes} min', Duration(minutes: s.settings.snoozeMinutes)),
                    ('1 hour', const Duration(hours: 1)),
                    ('3 hours', const Duration(hours: 3)),
                    ('Tomorrow', _untilTomorrowMorning(s)),
                  ])
                    ActionChip(
                      avatar: const Icon(Icons.snooze, size: 18),
                      label: Text(text),
                      onPressed: () {
                        close();
                        TaskActions.snooze(hostContext, task, d, occurrenceDate: occurrence?.date);
                      },
                    ),
                ],
              ),
            ),
            if (!task.isSubtask) ...[
              label('Project'),
              LiveQuery<List<Project>>(
                id: 'projects',
                stream: s.projects.watchAll,
                builder: (context, data) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        label: const Text('No project'),
                        selected: task.projectId == null,
                        onSelected: (_) {
                          s.tasks.moveToProject(task.id, null);
                          close();
                        },
                      ),
                      for (final p in data ?? const <Project>[])
                        ChoiceChip(
                          avatar: CircleAvatar(backgroundColor: Color(p.color), radius: 6),
                          label: Text(p.name),
                          selected: task.projectId == p.id,
                          onSelected: (_) {
                            s.tasks.moveToProject(task.id, p.id);
                            close();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open task'),
              onTap: () {
                close();
                TaskActions.open(hostContext, task.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text('Delete', style: TextStyle(color: scheme.error)),
              onTap: () {
                close();
                TaskActions.confirmDelete(hostContext, task);
              },
            ),
          ],
        ),
      ),
    );
  }

  Duration _untilTomorrowMorning(AppServices s) {
    final now = s.clock.now();
    final t = s.clock.today().addDays(1).atMinute(s.settings.defaultReminderMinute);
    return t.difference(now);
  }
}
