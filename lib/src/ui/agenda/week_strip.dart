import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/models.dart';
import '../editor/quick_add.dart';
import '../formatting.dart';
import '../task_actions.dart';
import '../theme.dart';
import '../widgets/day_mosaic.dart';
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

  static const _pad = 3.0;

  bool get _weekend => day.weekday >= DateTime.saturday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;

    Widget square(bool highlight) => Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        // Weekends are a darker grey.
        color: highlight ? scheme.primaryContainer : scheme.onSurface.withValues(alpha: _weekend ? 0.20 : 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      // Drawn on top so it does not shrink the mosaic.
      foregroundDecoration: isToday
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: scheme.primary, width: 1.5),
            )
          : null,
      child: DayMosaic(cells: cells, size: size - 2 * _pad),
    );

    final target = DragTarget<TaskDragData>(
      onWillAcceptWithDetails: (d) => !d.data.task.isRecurring,
      onAcceptWithDetails: (d) => AppScope.of(context).tasks.rescheduleTasks([d.data.task.id], day),
      builder: (context, candidate, _) => square(candidate.isNotEmpty),
    );

    final label = compact
        ? null
        : Text(
            '${Fmt.weekdayShort(day).substring(0, 2)} ${day.day}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isToday ? scheme.primary : (_weekend ? scheme.onSurfaceVariant : scheme.outline),
              fontWeight: isToday || _weekend ? FontWeight.w700 : null,
            ),
          );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        target,
        if (label != null) ...[const SizedBox(height: 2), label],
      ],
    );

    final tappable = Builder(
      builder: (squareContext) {
        void open() => DayPopup.show(
          squareContext,
          day: day,
          cells: cells,
          compact: compact,
          onOpenTask: onOpenTask,
          onNewTask: onNewTask,
        );
        // Overlay: no ink, no delay (the click opens the list immediately).
        if (compact) {
          return GestureDetector(behavior: HitTestBehavior.opaque, onTap: open, child: content);
        }
        return InkWell(borderRadius: BorderRadius.circular(6), onTap: open, child: content);
      },
    );
    if (compact) return tappable;
    return Tooltip(
      message: cells.isEmpty
          ? '${Fmt.longDate(day)}\nNothing scheduled · double-click to add'
          : '${Fmt.longDate(day)}\n${cells.map((c) => '${c.done ? '✓' : '•'} ${c.title}').take(12).join('\n')}'
                '${cells.length > 12 ? '\n… +${cells.length - 12} more' : ''}',
      waitDuration: const Duration(milliseconds: 350),
      child: tappable,
    );
  }
}

/// The list of a day's tasks, opened by clicking a day (mini calendar,
/// calendar tab). The list opens on the first click without waiting; a
/// second click right after (which closes it) counts as a double-click and
/// creates a task for that day.
abstract final class DayPopup {
  static const _doubleClick = Duration(milliseconds: 400);

  static Future<void> show(
    BuildContext anchor, {
    required LocalDate day,
    required List<DayCell> cells,
    bool compact = false,
    void Function(int taskId)? onOpenTask,
    void Function(LocalDate day)? onNewTask,
  }) async {
    final opened = DateTime.now();
    final Object? choice = compact ? await _compact(anchor, day, cells) : await _sheet(anchor, day, cells);
    if (!anchor.mounted) return;
    final quickClose = choice == null && DateTime.now().difference(opened) < _doubleClick;
    if (choice is int) {
      onOpenTask != null ? onOpenTask(choice) : await TaskActions.open(anchor, choice);
    } else if (choice == 'new' || quickClose) {
      onNewTask != null ? onNewTask(day) : await QuickAdd.show(anchor, due: day);
    }
  }

  /// Full day list (main window).
  static Future<Object?> _sheet(BuildContext context, LocalDate day, List<DayCell> cells) {
    final scheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<Object>(
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
                    onPressed: () => Navigator.pop(sheet, 'new'),
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
                onTap: () => Navigator.pop(sheet, c.taskId),
              ),
          ],
        ),
      ),
    );
  }

  /// Small popup anchored under the square, without animation (overlay).
  static Future<Object?> _compact(BuildContext squareContext, LocalDate day, List<DayCell> cells) {
    final theme = Theme.of(squareContext);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall;
    final box = squareContext.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(squareContext).context.findRenderObject()! as RenderBox;
    final at = box.localToGlobal(box.size.bottomLeft(Offset.zero), ancestor: overlay);
    return showMenu<Object>(
      context: squareContext,
      position: RelativeRect.fromLTRB(at.dx, at.dy, overlay.size.width - at.dx, 0),
      constraints: const BoxConstraints(maxWidth: 240),
      popUpAnimationStyle: AnimationStyle.noAnimation,
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
                  c.done ? Icons.check_circle : Icons.radio_button_unchecked,
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
  }
}
