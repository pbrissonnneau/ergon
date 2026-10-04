import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../formatting.dart';
import '../task_actions.dart';
import '../theme.dart';

/// Compact, cheap-to-build row used by every task list.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.item,
    required this.today,
    this.occurrence,
    this.missedCount = 0,
    this.showProject = true,
    this.showParent = true,
    this.showDue = true,
    this.expanded,
    this.onToggleExpanded,
    this.dense = false,
  });

  final TaskListItem item;
  final Occurrence? occurrence;
  final LocalDate today;
  final int missedCount;
  final bool showProject;
  final bool showParent;
  final bool showDue;
  final bool? expanded;
  final VoidCallback? onToggleExpanded;
  final bool dense;

  Task get task => item.task;
  TaskStatus get status => occurrence?.status ?? task.status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final closed = status.isClosed;
    final date = occurrence?.date ?? (task.isRecurring ? task.dueDate : task.dueDate);
    final minute = occurrence != null ? occurrence!.dueMinute : task.dueMinute;
    final overdue = date != null && date < today && !closed;

    final meta = <Widget>[
      if (showParent && item.parentTitle != null)
        _Meta(icon: Icons.subdirectory_arrow_right, text: item.parentTitle!, color: scheme.outline),
      if (showDue && date != null)
        _Meta(
          icon: task.isRecurring ? Icons.repeat : Icons.event,
          text: Fmt.due(date, minute, today),
          color: overdue ? scheme.error : (date == today ? scheme.primary : scheme.outline),
          bold: overdue || date == today,
        )
      else if (task.isRecurring)
        _Meta(icon: Icons.repeat, text: task.recurrence!.describe(), color: scheme.outline),
      if (task.type == TaskType.ongoing && date == null)
        _Meta(icon: Icons.all_inclusive, text: 'Ongoing', color: scheme.outline),
      if (missedCount > 0) _Meta(icon: Icons.history, text: '+$missedCount missed', color: scheme.error),
      if (status != TaskStatus.notStarted && !closed)
        _Meta(icon: AppTheme.statusIcon(status), text: status.label, color: AppTheme.statusColor(status, scheme)),
      if (showProject && item.projectName != null)
        _Meta(
          icon: Icons.circle,
          iconSize: 9,
          text: item.projectName!,
          color: scheme.onSurfaceVariant,
          iconColor: Color(item.projectColor ?? scheme.primary.toARGB32()),
        ),
      if (item.subtaskCount > 0)
        _Meta(icon: Icons.checklist, text: '${item.subtaskDone}/${item.subtaskCount}', color: scheme.outline),
      if (task.description.isNotEmpty) Icon(Icons.notes, size: 14, color: scheme.outline),
    ];

    return InkWell(
      onTap: () => TaskActions.open(context, task.id),
      onLongPress: () => TaskActions.showQuickActions(context, item, occurrence: occurrence),
      onSecondaryTapUp: (TapUpDetails _) => TaskActions.showQuickActions(context, item, occurrence: occurrence),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: dense ? 0 : 2),
        child: Row(
          children: [
            _CompleteBox(
              status: status,
              priority: task.priority,
              onTap: () => TaskActions.toggleComplete(context, task, occurrence: occurrence),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: dense ? 6 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: closed ? TextDecoration.lineThrough : null,
                        color: closed ? scheme.outline : null,
                        height: 1.2,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Wrap(spacing: 10, runSpacing: 2, children: meta),
                      ),
                  ],
                ),
              ),
            ),
            if (task.priority.code >= TaskPriority.high.code)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(AppTheme.priorityIcon(task.priority),
                    size: 18, color: AppTheme.priorityColor(task.priority, scheme)),
              ),
            if (onToggleExpanded != null && item.subtaskCount > 0)
              IconButton(
                tooltip: expanded == true ? 'Hide subtasks' : 'Show subtasks',
                visualDensity: VisualDensity.compact,
                icon: Icon(expanded == true ? Icons.expand_less : Icons.expand_more),
                onPressed: onToggleExpanded,
              ),
            IconButton(
              tooltip: 'Actions',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () => TaskActions.showQuickActions(context, item, occurrence: occurrence),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteBox extends StatelessWidget {
  const _CompleteBox({required this.status, required this.priority, required this.onTap});
  final TaskStatus status;
  final TaskPriority priority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = status == TaskStatus.completed;
    final color = done ? AppTheme.statusColor(status, scheme) : AppTheme.priorityColor(priority, scheme);
    return Semantics(
      button: true,
      checked: done,
      label: done ? 'Mark as not completed' : 'Mark as completed',
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            done
                ? Icons.check_circle
                : status == TaskStatus.cancelled
                    ? Icons.cancel_outlined
                    : Icons.radio_button_unchecked,
            size: 22,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.text,
    required this.color,
    this.iconColor,
    this.iconSize = 13,
    this.bold = false,
  });
  final IconData icon;
  final String text;
  final Color color;
  final Color? iconColor;
  final double iconSize;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: iconSize, color: iconColor ?? color),
      const SizedBox(width: 3),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: bold ? FontWeight.w600 : null,
              ),
        ),
      ),
    ]);
  }
}

/// Task tile that can expand to show its subtasks inline.
class ExpandableTaskTile extends StatefulWidget {
  const ExpandableTaskTile({
    super.key,
    required this.item,
    required this.today,
    this.occurrence,
    this.missedCount = 0,
    this.showProject = true,
  });
  final TaskListItem item;
  final Occurrence? occurrence;
  final LocalDate today;
  final int missedCount;
  final bool showProject;

  @override
  State<ExpandableTaskTile> createState() => _ExpandableTaskTileState();
}

class _ExpandableTaskTileState extends State<ExpandableTaskTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tile = TaskTile(
      item: widget.item,
      occurrence: widget.occurrence,
      today: widget.today,
      missedCount: widget.missedCount,
      showProject: widget.showProject,
      expanded: _expanded,
      onToggleExpanded: () => setState(() => _expanded = !_expanded),
    );
    if (!_expanded) return tile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: StreamBuilder<List<TaskListItem>>(
            stream: AppScope.of(context).tasks.watchSubtasks(widget.item.task.id),
            builder: (context, snap) => Column(
              children: [
                for (final sub in snap.data ?? const <TaskListItem>[])
                  TaskTile(
                    key: ValueKey(sub.task.id),
                    item: sub,
                    today: widget.today,
                    showProject: false,
                    showParent: false,
                    dense: true,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

