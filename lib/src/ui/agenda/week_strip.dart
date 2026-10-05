import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/models.dart';
import '../editor/quick_add.dart';
import '../formatting.dart';
import '../task_actions.dart';
import '../theme.dart';
import '../widgets/live_query.dart';
import '../widgets/task_drag.dart';

/// Minimal calendar strip: grey squares (one per day; weekends darker), each
/// split into tiny cells coloured by the project of the tasks of that day
/// (done = solid, to do = lighter).
///
/// * click a day: its task list;
/// * double-click a day: new task due that day;
/// * drop a dragged task on a day: move it there.
class WeekStrip extends StatefulWidget {
  const WeekStrip({
    super.key,
    this.square = 34,
    this.days = 14,
    this.daysBefore = 3,
    this.compact = false,
    this.onOpenTask,
    this.onNewTask,
  });

  final double square;

  /// Number of days shown, starting [daysBefore] days before today.
  final int days;
  final int daysBefore;

  /// Overlay mode: no navigation arrows or labels; compact day list.
  final bool compact;

  /// Opens a task (defaults to the in-app editor).
  final void Function(int taskId)? onOpenTask;

  /// Creates a task due on a day (defaults to the in-app quick-add dialog).
  final void Function(LocalDate day)? onNewTask;

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
        final first = today.addDays(-widget.daysBefore + 7 * _weekOffset);
        final last = first.addDays(widget.days - 1);
        return LiveQuery<Map<int, List<DayCell>>>(
          id: (first, last, today),
          stream: () => s.tasks.watchDayActivity(first, last),
          builder: (context, data) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.compact) _arrow(Icons.chevron_left, 'Previous week', () => setState(() => _weekOffset--)),
              for (var i = 0; i < widget.days; i++) ...[
                if (i > 0) SizedBox(width: widget.compact ? 3 : 4),
                _DaySquare(
                  day: first.addDays(i),
                  today: today,
                  cells: data?[first.addDays(i).epochDay] ?? const [],
                  size: widget.square,
                  compact: widget.compact,
                  onOpenTask: widget.onOpenTask,
                  onNewTask: widget.onNewTask,
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
    required this.compact,
    this.onOpenTask,
    this.onNewTask,
  });
  final LocalDate day;
  final LocalDate today;
  final List<DayCell> cells;
  final double size;
  final bool compact;
  final void Function(int taskId)? onOpenTask;
  final void Function(LocalDate day)? onNewTask;

  static const _cell = 5.0;
  static const _gap = 1.5;

  bool get _weekend => day.weekday >= DateTime.saturday;

  void _newTask(BuildContext context) {
    final create = onNewTask;
    create != null ? create(day) : QuickAdd.show(context, due: day);
  }

  void _open(BuildContext context, int taskId) {
    final open = onOpenTask;
    open != null ? open(taskId) : TaskActions.open(context, taskId);
  }

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
        ? '${Fmt.longDate(day)}\nNothing scheduled · double-click to add'
        : '${Fmt.longDate(day)}\n${cells.map((c) => '${c.done ? '✓' : '•'} ${c.title}').take(12).join('\n')}'
              '${cells.length > 12 ? '\n… +${cells.length - 12} more' : ''}';

    Widget square(bool highlight) => Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        // Weekends are a darker grey.
        color: highlight ? scheme.primaryContainer : scheme.onSurface.withValues(alpha: _weekend ? 0.20 : 0.08),
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
                color: AppTheme.projectColor(c.projectColor, scheme).withValues(alpha: c.done ? 1 : 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );

    final target = DragTarget<TaskDragData>(
      onWillAcceptWithDetails: (d) => !d.data.task.isRecurring,
      onAcceptWithDetails: (d) => AppScope.of(context).tasks.rescheduleTasks([d.data.task.id], day),
      builder: (context, candidate, _) => square(candidate.isNotEmpty),
    );

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: Builder(
        builder: (squareContext) => InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => compact ? _showDayCompact(squareContext) : _showDay(context),
          onDoubleTap: () => _newTask(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              target,
              if (!compact) ...[
                const SizedBox(height: 2),
                Text(
                  '${Fmt.weekdayShort(day).substring(0, 2)} ${day.day}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday ? scheme.primary : (_weekend ? scheme.onSurfaceVariant : scheme.outline),
                    fontWeight: isToday || _weekend ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Full day list (main window).
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
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text(Fmt.longDate(day), style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheet);
                      _newTask(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New task'),
                  ),
                ],
              ),
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
                  _open(context, c.taskId);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Small popup anchored on the square (overlay window).
  Future<void> _showDayCompact(BuildContext squareContext) async {
    final theme = Theme.of(squareContext);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall;
    final box = squareContext.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(squareContext).context.findRenderObject()! as RenderBox;
    final at = box.localToGlobal(box.size.bottomLeft(Offset.zero), ancestor: overlay);
    final choice = await showMenu<Object>(
      context: squareContext,
      position: RelativeRect.fromLTRB(at.dx, at.dy, overlay.size.width - at.dx, 0),
      constraints: const BoxConstraints(maxWidth: 240),
      items: [
        PopupMenuItem<Object>(
          enabled: false,
          height: 24,
          child: Text(Fmt.longDate(day), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (cells.isEmpty)
          PopupMenuItem<Object>(enabled: false, height: 24, child: Text('Nothing scheduled', style: small)),
        for (final c in cells)
          PopupMenuItem<Object>(
            value: c.taskId,
            height: 26,
            child: Row(
              children: [
                Icon(
                  c.done ? Icons.check_circle : Icons.circle_outlined,
                  size: 12,
                  color: AppTheme.projectColor(c.projectColor, scheme),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small?.copyWith(decoration: c.done ? TextDecoration.lineThrough : null),
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<Object>(
          value: 'new',
          height: 26,
          child: Row(
            children: [
              const Icon(Icons.add, size: 12),
              const SizedBox(width: 6),
              Text('New task', style: small),
            ],
          ),
        ),
      ],
    );
    if (!squareContext.mounted) return;
    if (choice is int) _open(squareContext, choice);
    if (choice == 'new') _newTask(squareContext);
  }
}
