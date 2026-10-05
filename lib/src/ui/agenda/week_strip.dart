import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/models.dart';
import '../formatting.dart';
import '../task_actions.dart';
import '../theme.dart';
import '../widgets/live_query.dart';
import '../widgets/task_drag.dart';

/// Minimal week calendar: 7 grey squares (today ± 3 days), each split into tiny
/// cells coloured by the project of the tasks of that day (done = solid,
/// to do = lighter). Click a day for its list; drop a dragged task on a day
/// to move it there.
class WeekStrip extends StatefulWidget {
  const WeekStrip({super.key, this.square = 34, this.compact = false, this.onOpenTask});

  final double square;

  /// Overlay mode: no navigation arrows or day numbers below.
  final bool compact;

  /// Opens a task (defaults to the in-app editor).
  final void Function(int taskId)? onOpenTask;

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ValueListenableBuilder<LocalDate>(
      valueListenable: s.today,
      builder: (context, today, _) {
        // Centred on today (3 days back, 3 ahead); arrows move by a week.
        final first = today.addDays(-3 + 7 * _weekOffset);
        final sunday = first.addDays(6);
        return LiveQuery<Map<int, List<DayCell>>>(
          id: (first, today),
          stream: () => s.tasks.watchDayActivity(first, sunday),
          builder: (context, data) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.compact) _arrow(Icons.chevron_left, 'Previous week', () => setState(() => _weekOffset--)),
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) SizedBox(width: widget.compact ? 3 : 5),
                _DaySquare(
                  day: first.addDays(i),
                  today: today,
                  cells: data?[first.addDays(i).epochDay] ?? const [],
                  size: widget.square,
                  showLabel: !widget.compact,
                  onOpenTask: widget.onOpenTask,
                ),
              ],
              if (!widget.compact) ...[
                _arrow(Icons.chevron_right, 'Next week', () => setState(() => _weekOffset++)),
                if (_weekOffset != 0)
                  TextButton(onPressed: () => setState(() => _weekOffset = 0), child: const Text('Today')),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _arrow(IconData icon, String tip, VoidCallback onTap) =>
      IconButton(icon: Icon(icon, size: 20), tooltip: tip, visualDensity: VisualDensity.compact, onPressed: onTap);
}

class _DaySquare extends StatelessWidget {
  const _DaySquare({
    required this.day,
    required this.today,
    required this.cells,
    required this.size,
    required this.showLabel,
    this.onOpenTask,
  });
  final LocalDate day;
  final LocalDate today;
  final List<DayCell> cells;
  final double size;
  final bool showLabel;
  final void Function(int taskId)? onOpenTask;

  static const _cell = 5.0;
  static const _gap = 1.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;
    final perRow = ((size - 6 + _gap) / (_cell + _gap)).floor();
    final capacity = perRow * perRow;
    // Done first so the square "fills up" as work gets done.
    final sorted = [...cells]..sort((a, b) => (b.done ? 1 : 0) - (a.done ? 1 : 0));
    final shown = sorted.length > capacity ? sorted.sublist(0, capacity) : sorted;
    final tooltip = cells.isEmpty
        ? '${Fmt.longDate(day)}\nNothing scheduled'
        : '${Fmt.longDate(day)}\n${cells.map((c) => '${c.done ? '✓' : '•'} ${c.title}').take(12).join('\n')}'
              '${cells.length > 12 ? '\n… +${cells.length - 12} more' : ''}';

    Widget square(bool highlight) => Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: highlight ? scheme.primaryContainer : scheme.onSurface.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isToday ? scheme.primary : Colors.transparent, width: 1.5),
      ),
      child: Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [
          for (final c in shown)
            Container(
              width: _cell,
              height: _cell,
              decoration: BoxDecoration(
                color: AppTheme.projectColor(c.projectColor, scheme).withValues(alpha: c.done ? 1 : 0.45),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );

    final target = DragTarget<TaskDragData>(
      onWillAcceptWithDetails: (d) => !d.data.task.isRecurring,
      onAcceptWithDetails: (d) async {
        final s = AppScope.of(context);
        final messenger = ScaffoldMessenger.maybeOf(context);
        await s.tasks.rescheduleTasks([d.data.task.id], day);
        messenger?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('“${d.data.task.title}” moved to ${Fmt.longDate(day)}'),
          ),
        );
      },
      builder: (context, candidate, _) => square(candidate.isNotEmpty),
    );

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _showDay(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            target,
            if (showLabel) ...[
              const SizedBox(height: 2),
              Text(
                '${Fmt.weekdayShort(day).substring(0, 2)} ${day.day}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isToday ? scheme.primary : scheme.outline,
                  fontWeight: isToday ? FontWeight.w700 : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDay(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(Fmt.longDate(day), style: Theme.of(context).textTheme.titleMedium),
            ),
            if (cells.isEmpty) const ListTile(title: Text('Nothing scheduled or completed this day')),
            for (final c in cells)
              ListTile(
                dense: true,
                leading: Icon(
                  c.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: AppTheme.projectColor(c.projectColor, scheme),
                ),
                title: Text(c.title, style: TextStyle(decoration: c.done ? TextDecoration.lineThrough : null)),
                onTap: () {
                  Navigator.pop(sheet);
                  final open = onOpenTask;
                  open != null ? open(c.taskId) : TaskActions.open(context, c.taskId);
                },
              ),
          ],
        ),
      ),
    );
  }
}
