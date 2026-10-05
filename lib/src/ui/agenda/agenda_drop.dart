import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/agenda.dart';
import '../widgets/task_drag.dart';

/// Drag and drop inside the agenda (desktop):
/// * within the same day/section: reorder (remembered as a manual order);
/// * onto another day (today or an upcoming day): change the due date and
///   insert at the drop position.
///
/// Recurring occurrences keep their date (the rule decides), so they can
/// only be reordered within their own section. Ongoing / Recurring / Overdue
/// sections accept only their own entries.
abstract final class AgendaDrop {
  static String keyOf(TaskDragData d) =>
      d.occurrenceDate != null ? 'o${d.task.id}_${d.occurrenceDate!.epochDay}' : 't${d.task.id}';

  /// Due date given to a task dropped into [s], or null if [s] has no date
  /// semantics (ongoing, recurring, overdue).
  static LocalDate? dateOf(AgendaSection s, LocalDate today) => switch (s.kind) {
    AgendaSectionKind.todayUrgent || AgendaSectionKind.today => today,
    AgendaSectionKind.upcoming => s.date,
    _ => null,
  };

  static bool canDrop(AgendaSection s, TaskDragData d, LocalDate today) {
    final key = keyOf(d);
    if (s.entries.any((e) => e.key == key)) return true; // Reorder in place.
    if (d.occurrenceDate != null || d.task.isRecurring) return false;
    return dateOf(s, today) != null;
  }

  /// Drops [d] into [s] before the entry with [beforeKey] (end when null).
  static Future<void> drop(AppServices app, AgendaSection s, TaskDragData d, {String? beforeKey}) async {
    final key = keyOf(d);
    if (beforeKey == key) return;
    final inSection = s.entries.any((e) => e.key == key);
    if (!inSection) {
      await app.tasks.rescheduleTasks([d.task.id], dateOf(s, app.clock.today()));
    }
    final rest = s.entries.where((e) => e.key != key).toList();
    var index = beforeKey == null ? rest.length : rest.indexWhere((e) => e.key == beforeKey);
    if (index < 0) index = rest.length;
    final order = <int>[for (final e in rest) e.task.id]..insert(index, d.task.id);
    await app.tasks.setDayOrder(order.toSet().toList());
  }
}

/// Wraps an agenda row: shows an insertion line while a task is dragged over
/// it (above or below depending on the hovered half) and drops it there.
class AgendaDropSlot extends StatefulWidget {
  const AgendaDropSlot({
    super.key,
    required this.section,
    required this.today,
    required this.child,
    this.thisKey,
    this.nextKey,
  });
  final AgendaSection section;
  final LocalDate today;

  /// Key of the entry in this row (null for a header: drops at the top).
  final String? thisKey;

  /// Key of the following entry in the section (null = last).
  final String? nextKey;
  final Widget child;

  @override
  State<AgendaDropSlot> createState() => _AgendaDropSlotState();
}

class _AgendaDropSlotState extends State<AgendaDropSlot> {
  bool _after = false;

  String? get _beforeKey {
    if (widget.thisKey == null) {
      // Header: insert at the top of the section.
      return widget.section.entries.isEmpty ? null : widget.section.entries.first.key;
    }
    return _after ? widget.nextKey : widget.thisKey;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final line = Container(
      height: 3,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2)),
    );
    return DragTarget<TaskDragData>(
      onWillAcceptWithDetails: (d) => AgendaDrop.canDrop(widget.section, d.data, widget.today),
      onMove: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || widget.thisKey == null) return;
        final after = box.globalToLocal(d.offset).dy > box.size.height / 2;
        if (after != _after) setState(() => _after = after);
      },
      onAcceptWithDetails: (d) => AgendaDrop.drop(app, widget.section, d.data, beforeKey: _beforeKey),
      builder: (context, candidates, _) => Stack(
        children: [
          widget.child,
          if (candidates.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              top: _after && widget.thisKey != null ? null : 0,
              bottom: _after && widget.thisKey != null ? 0 : null,
              child: line,
            ),
        ],
      ),
    );
  }
}
