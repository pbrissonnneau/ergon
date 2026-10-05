import 'package:flutter/material.dart';

import '../../core/local_date.dart';
import '../../domain/models.dart';

/// Payload of a task being dragged (desktop) onto a project or a day.
class TaskDragData {
  const TaskDragData(this.task, {this.occurrenceDate});
  final Task task;
  final LocalDate? occurrenceDate;
}

/// Global drag state: drop targets (project bar) appear while it is true.
abstract final class TaskDrag {
  static final active = ValueNotifier<bool>(false);
}

/// Makes [child] draggable with the mouse on desktop. Touch keeps long-press
/// for the quick-actions menu, which offers the same moves.
class DraggableTask extends StatelessWidget {
  const DraggableTask({super.key, required this.data, required this.enabled, required this.child});
  final TaskDragData data;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final scheme = Theme.of(context).colorScheme;
    return Draggable<TaskDragData>(
      data: data,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      // Above the drop bar and every nested navigator.
      rootOverlay: true,
      onDragStarted: () => TaskDrag.active.value = true,
      onDragEnd: (_) => TaskDrag.active.value = false,
      onDraggableCanceled: (_, _) => TaskDrag.active.value = false,
      feedback: Material(
        elevation: 6,
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              data.task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: child),
      child: child,
    );
  }
}
