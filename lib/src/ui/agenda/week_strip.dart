import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/enums.dart';
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
    this.weekOffset,
  });

  final double square;

  /// Weeks shifted from the current ones; owned by the host so it can show
  /// its own "Today" button (the strip itself never changes width).
  final ValueNotifier<int>? weekOffset;

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
  final _ownOffset = ValueNotifier<int>(0);
  ValueNotifier<int> get _offset => widget.weekOffset ?? _ownOffset;

  @override
  void dispose() {
    _ownOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([s.today, _offset]),
      builder: (context, _) {
        final today = s.today.value;
        final first = today.addDays(-widget.daysBefore + 7 * _offset.value);
        final last = first.addDays(widget.days - 1);
        return LiveQuery<Map<int, List<DayCell>>>(
          id: (first, last, today),
          stream: () => s.tasks.watchDayActivity(first, last),
          builder: (context, data) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.compact) _arrow(Icons.chevron_left, 'Previous week', () => _offset.value--),
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
              if (!widget.compact) ...[_arrow(Icons.chevron_right, 'Next week', () => _offset.value++)],
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

  /// Day panel (main window): slides in from the right, full height.
  static Future<Object?> _sheet(BuildContext context, LocalDate day, List<DayCell> cells) {
    return showGeneralDialog<Object>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialog, _, _) => _DayPanel(day: day, cells: cells, today: AppScope.of(context).today.value),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
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

class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day, required this.cells, required this.today});
  final LocalDate day;
  final List<DayCell> cells;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final open = cells.where((c) => !c.done).toList()
      ..sort((a, b) => (a.minute ?? 1 << 20).compareTo(b.minute ?? 1 << 20));
    final done = cells.where((c) => c.done).toList();
    final rel = today.daysUntil(day);
    final when = rel == 0 ? 'Today' : (rel == 1 ? 'Tomorrow' : (rel == -1 ? 'Yesterday' : null));

    Widget row(DayCell c) => InkWell(
      onTap: () => Navigator.pop(context, c.taskId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.projectColor(c.projectColor, scheme),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              c.done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: c.done ? AppTheme.statusColor(TaskStatus.completed, scheme) : scheme.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: c.done ? scheme.outline : null,
                      decoration: c.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (c.projectName != null)
                    Text(c.projectName!, style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline)),
                ],
              ),
            ),
            if (c.minute != null)
              Text(MinuteOfDay.format(c.minute!), style: theme.textTheme.labelMedium?.copyWith(color: scheme.outline)),
          ],
        ),
      ),
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 8,
        color: scheme.surfaceContainerLow,
        child: SizedBox(
          width: width < 480 ? width : 420,
          height: double.infinity,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (when != null)
                              Text(when, style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                            Text(Fmt.longDate(day), style: theme.textTheme.titleLarge),
                            Text(
                              '${open.length} to do · ${done.length} done',
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, 'close'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.pop(context, 'new'),
                    icon: const Icon(Icons.add),
                    label: const Text('New task on this day'),
                  ),
                ),
                const Divider(height: 16),
                Expanded(
                  child: cells.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Nothing scheduled or completed this day.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.outline),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 16),
                          children: [
                            if (open.isNotEmpty) ...[label('TO DO'), for (final c in open) row(c)],
                            if (done.isNotEmpty) ...[label('DONE'), for (final c in done) row(c)],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
