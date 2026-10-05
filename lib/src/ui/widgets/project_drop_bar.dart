import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../domain/models.dart';
import 'live_query.dart';
import 'task_drag.dart';

/// Appears at the bottom of the window while a task is dragged: drop it on a
/// project to move it there (with its subtasks).
class ProjectDropBar extends StatelessWidget {
  const ProjectDropBar({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: TaskDrag.active,
      builder: (context, active, _) => IgnorePointer(
        ignoring: !active,
        child: AnimatedSlide(
          offset: active ? Offset.zero : const Offset(0, 1.2),
          duration: const Duration(milliseconds: 140),
          child: Material(
            elevation: 8,
            color: scheme.surfaceContainerHigh,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: LiveQuery<List<Project>>(
                  id: 'projects',
                  stream: s.projects.watchAll,
                  builder: (context, projects) => Row(
                    children: [
                      Icon(Icons.drive_file_move_outline, color: scheme.primary),
                      const SizedBox(width: 10),
                      const Text('Drop on a project'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _target(context, null, 'No project', scheme.outline),
                              for (final p in projects ?? const <Project>[])
                                _target(context, p.id, p.name, Color(p.color)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _target(BuildContext context, int? projectId, String name, Color color) {
    final s = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DragTarget<TaskDragData>(
        onAcceptWithDetails: (d) async {
          final task = d.data.task;
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (task.isSubtask) {
            messenger?.showSnackBar(const SnackBar(content: Text('Subtasks follow their parent task’s project.')));
            return;
          }
          await s.tasks.moveToProject(task.id, projectId);
        },
        builder: (context, candidates, _) {
          final hover = candidates.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: hover ? color.withValues(alpha: 0.25) : scheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: hover ? color : scheme.outlineVariant, width: hover ? 2 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 6, backgroundColor: color),
                const SizedBox(width: 8),
                Text(name),
              ],
            ),
          );
        },
      ),
    );
  }
}
