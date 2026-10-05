import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../data/project_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/task_query.dart';
import '../editor/quick_add.dart';
import '../formatting.dart';
import '../task_actions.dart';
import '../tasks/tasks_screen.dart';
import '../theme.dart';
import '../widgets/live_query.dart';
import '../widgets/task_drag.dart';

/// Projects as a Kanban board: one vertical column per project, side by
/// side. Drag a card to another column to move the task; collapse a column
/// to squash it into a thin strip.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-project',
        onPressed: () => editProject(context),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New project'),
      ),
      appBar: AppBar(title: const Text('Projects')),
      body: const _SwimlaneBoard(),
    );
  }

  static Future<void> editProject(BuildContext context, {Project? project}) async {
    final s = AppScope.of(context);
    final ctrl = TextEditingController(text: project?.name ?? '');
    var color = project?.color ?? ProjectRepository.palette.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(project == null ? 'New project' : 'Edit project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                onSubmitted: (_) => Navigator.pop(c, true),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final col in ProjectRepository.palette)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => set(() => color = col),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(col),
                        child: col == color ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (result != true || name.isEmpty) return;
    if (project == null) {
      await s.projects.create(name, color: color);
    } else {
      await s.projects.update(project.id, name: name, color: color);
    }
  }

  static Future<void> _delete(BuildContext context, Project p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('“${p.name}” will be deleted. Its tasks are kept and moved to “No project”.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) await AppScope.of(context).projects.delete(p.id);
  }
}

/// Lane identity: a project id, or -1 for tasks without a project.
const _noProject = -1;

class _SwimlaneBoard extends StatefulWidget {
  const _SwimlaneBoard();
  @override
  State<_SwimlaneBoard> createState() => _SwimlaneBoardState();
}

class _SwimlaneBoardState extends State<_SwimlaneBoard> {
  static const _collapsedKey = 'projects.collapsed';
  Set<int>? _collapsed;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _collapsed ??= (AppScope.of(context).settings.raw(_collapsedKey) ?? '')
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  void _toggle(int lane) {
    setState(() => _collapsed!.contains(lane) ? _collapsed!.remove(lane) : _collapsed!.add(lane));
    unawaited(AppScope.of(context).settings.setRaw(_collapsedKey, _collapsed!.join(',')));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return LiveQuery<List<ProjectWithCount>>(
      id: 'projects',
      stream: s.projects.watchWithCounts,
      builder: (context, projects) => LiveQuery<List<TaskListItem>>(
        id: 'lane-tasks',
        stream: () => s.tasks.watchQuery(const TaskQuery(includeSubtasks: false, limit: 5000)),
        builder: (context, tasks) {
          if (projects == null || tasks == null) return const SizedBox.shrink();
          final byLane = <int, List<TaskListItem>>{};
          for (final t in tasks) {
            byLane.putIfAbsent(t.task.projectId ?? _noProject, () => []).add(t);
          }
          final lanes = [
            for (final p in projects) (p.project.id, p.project.name, Color(p.project.color), p.project),
            (_noProject, 'No project', AppTheme.projectColor(null, Theme.of(context).colorScheme), null),
          ];
          return ValueListenableBuilder<LocalDate>(
            valueListenable: s.today,
            builder: (context, today, _) => Scrollbar(
              controller: _scroll,
              thumbVisibility: s.platform.isDesktop,
              child: ListView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                children: [
                  if (projects.isEmpty)
                    SizedBox(
                      width: 220,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Create projects to group your tasks; drag cards between columns to move them.',
                          style: TextStyle(color: Theme.of(context).colorScheme.outline),
                        ),
                      ),
                    ),
                  for (final (id, name, color, project) in lanes)
                    _Lane(
                      key: ValueKey('lane$id'),
                      laneId: id,
                      name: name,
                      color: color,
                      project: project,
                      tasks: byLane[id] ?? const [],
                      today: today,
                      collapsed: _collapsed!.contains(id),
                      onToggle: () => _toggle(id),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Lane extends StatelessWidget {
  const _Lane({
    super.key,
    required this.laneId,
    required this.name,
    required this.color,
    required this.project,
    required this.tasks,
    required this.today,
    required this.collapsed,
    required this.onToggle,
  });
  final int laneId;
  final String name;
  final Color color;
  final Project? project;
  final List<TaskListItem> tasks;
  final LocalDate today;
  final bool collapsed;
  final VoidCallback onToggle;

  static const expandedWidth = 300.0;
  static const collapsedWidth = 44.0;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DragTarget<TaskDragData>(
      onWillAcceptWithDetails: (d) => !d.data.task.isSubtask && (d.data.task.projectId ?? _noProject) != laneId,
      onAcceptWithDetails: (d) => s.tasks.moveToProject(d.data.task.id, laneId == _noProject ? null : laneId),
      builder: (context, candidates, _) {
        final hover = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: collapsed ? collapsedWidth : expandedWidth,
          margin: const EdgeInsets.only(right: 10),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: hover ? color.withValues(alpha: 0.14) : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border(top: BorderSide(color: color, width: 5)),
          ),
          child: collapsed ? _collapsedBody(context) : _expandedBody(context, hover),
        );
      },
    );
  }

  /// Squashed lane: a thin column with the name written vertically.
  Widget _collapsedBody(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onToggle,
      child: Tooltip(
        message: '$name · ${tasks.length} task${tasks.length == 1 ? '' : 's'} (click to expand)',
        child: Column(
          children: [
            const SizedBox(height: 6),
            Icon(Icons.chevron_right, size: 20, color: scheme.outline),
            Text('${tasks.length}', style: theme.textTheme.labelMedium?.copyWith(color: scheme.outline)),
            const SizedBox(height: 8),
            Flexible(
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // A tiny summary of what is inside.
            for (final t in tasks.take(12))
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.priorityColor(t.task.priority, scheme),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _expandedBody(BuildContext context, bool hover) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
            child: Row(
              children: [
                Tooltip(
                  message: 'Collapse',
                  child: Icon(Icons.chevron_left, size: 20, color: scheme.outline),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${tasks.length}', style: theme.textTheme.labelMedium?.copyWith(color: scheme.outline)),
                const Spacer(),
                IconButton(
                  tooltip: 'New task in $name',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => QuickAdd.show(context, projectId: project?.id),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Column actions',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) async {
                    switch (v) {
                      case 'list':
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TasksScreen(
                              project: project ?? const Project(id: -1, name: 'No project', color: 0xFF9E9E9E),
                            ),
                          ),
                        );
                      case 'edit':
                        await ProjectsScreen.editProject(context, project: project);
                      case 'delete':
                        await ProjectsScreen._delete(context, project!);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'list', child: Text('Open as list (search, filters)')),
                    if (project != null) ...[
                      const PopupMenuItem(value: 'edit', child: Text('Rename / colour')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete project')),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    hover ? 'Drop here' : 'No open tasks — drag one here',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _TaskCard(key: ValueKey(tasks[i].task.id), item: tasks[i], today: today),
                ),
        ),
      ],
    );
  }
}

/// Compact Kanban card. Desktop: drag with the mouse. Touch: long-press
/// then drag. Click opens the task; the circle completes it.
class _TaskCard extends StatelessWidget {
  const _TaskCard({super.key, required this.item, required this.today});
  final TaskListItem item;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = item.task;
    final due = t.dueDate;
    final overdue = due != null && due < today;
    final card = Material(
      color: scheme.surface,
      elevation: 0.5,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => TaskActions.open(context, t.id),
        onSecondaryTapUp: (_) => TaskActions.showQuickActions(context, item),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkResponse(
                  radius: 16,
                  onTap: () => TaskActions.toggleComplete(context, t),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      t.status == TaskStatus.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                      color: t.status == TaskStatus.completed
                          ? AppTheme.statusColor(TaskStatus.completed, scheme)
                          : AppTheme.priorityColor(t.priority, scheme),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (due != null)
                            Text(
                              Fmt.due(due, t.dueMinute, today),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: overdue ? scheme.error : scheme.outline,
                                fontWeight: overdue ? FontWeight.w700 : null,
                              ),
                            ),
                          if (t.type == TaskType.ongoing)
                            Text('Ongoing', style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline)),
                          if (t.status != TaskStatus.notStarted && t.status.isOpen)
                            Text(
                              t.status.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.statusColor(t.status, scheme),
                              ),
                            ),
                          if (item.subtaskCount > 0)
                            Text(
                              '${item.subtaskDone}/${item.subtaskCount}',
                              style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (t.priority.code >= TaskPriority.high.code)
                  Icon(AppTheme.priorityIcon(t.priority), size: 16, color: AppTheme.priorityColor(t.priority, scheme)),
              ],
            ),
          ),
        ),
      ),
    );
    return DraggableTask(data: TaskDragData(t), enabled: true, touchLongPress: !s.platform.isDesktop, child: card);
  }
}
