import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/models.dart';
import '../agenda/backlog.dart';
import '../agenda/week_strip.dart';
import '../formatting.dart';
import '../widgets/day_mosaic.dart';
import '../widgets/live_query.dart';
import '../widgets/task_drag.dart';

/// Month calendar: one square per day holding a mosaic of the day's tasks in
/// project colours. Click a day for its list, double-click to add a task,
/// drop a task (e.g. from the backlog) on a day to move it there.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// Months from the current one (0 = this month).
  int _offset = 0;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ValueListenableBuilder<LocalDate>(
      valueListenable: s.today,
      builder: (context, today, _) {
        final month = LocalDate(today.year, today.month + _offset, 1);
        // Six full weeks starting on the Monday on or before the 1st.
        final first = month.addDays(-(month.weekday - DateTime.monday));
        final last = first.addDays(41);
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: Text('${Fmt.month(month.month)} ${month.year}'),
            actions: [
              if (_offset != 0) TextButton(onPressed: () => setState(() => _offset = 0), child: const Text('Today')),
              IconButton(
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _offset--),
              ),
              IconButton(
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _offset++),
              ),
              ListenableBuilder(
                listenable: s.settings,
                builder: (context, _) {
                  final shown = s.settings.raw(Backlog.settingKey) != '0';
                  return IconButton(
                    tooltip: shown ? 'Hide backlog' : 'Show backlog (tasks without a date)',
                    isSelected: shown,
                    icon: const Icon(Icons.inbox_outlined),
                    selectedIcon: Icon(Icons.inbox_outlined, color: Theme.of(context).colorScheme.primary),
                    onPressed: () => s.settings.setRaw(Backlog.settingKey, shown ? '0' : '1'),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListenableBuilder(
            listenable: s.settings,
            builder: (context, _) => LayoutBuilder(
              builder: (context, c) {
                final grid = LiveQuery<Map<int, List<DayCell>>>(
                  id: (first, last),
                  stream: () => s.tasks.watchDayActivity(first, last),
                  builder: (context, data) => _grid(context, month, first, today, data ?? const {}),
                );
                final side = s.settings.raw(Backlog.settingKey) != '0' && c.maxWidth >= 900;
                if (!side) return grid;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: grid),
                    const SizedBox(width: 320, child: Backlog()),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _grid(BuildContext context, LocalDate month, LocalDate first, LocalDate today, Map<int, List<DayCell>> data) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      _weekdays[i],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: i >= 5 ? scheme.onSurfaceVariant : scheme.outline,
                        fontWeight: i >= 5 ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                for (var w = 0; w < 6; w++)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var d = 0; d < 7; d++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _DayCell(
                                day: first.addDays(w * 7 + d),
                                today: today,
                                inMonth: first.addDays(w * 7 + d).month == month.month,
                                cells: data[first.addDays(w * 7 + d).epochDay] ?? const [],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.today, required this.inMonth, required this.cells});
  final LocalDate day;
  final LocalDate today;
  final bool inMonth;
  final List<DayCell> cells;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isToday = day == today;
    final weekend = day.weekday >= DateTime.saturday;
    final radius = BorderRadius.circular(8);
    return DragTarget<TaskDragData>(
      onWillAcceptWithDetails: (d) => !d.data.task.isRecurring,
      onAcceptWithDetails: (d) => AppScope.of(context).tasks.rescheduleTasks([d.data.task.id], day),
      builder: (context, candidates, _) => Opacity(
        opacity: inMonth ? 1 : 0.45,
        child: Material(
          color: candidates.isNotEmpty
              ? scheme.primaryContainer
              : scheme.onSurface.withValues(alpha: weekend ? 0.16 : 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: isToday ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
          ),
          child: Builder(
            builder: (cellContext) => InkWell(
              borderRadius: radius,
              onTap: () => DayPopup.show(cellContext, day: day, cells: cells),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: LayoutBuilder(
                  builder: (context, c) {
                    const label = 18.0;
                    final mosaic = math.max(0.0, math.min(c.maxWidth, c.maxHeight - label));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: label,
                          child: Text(
                            '${day.day}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (mosaic >= 8)
                          Expanded(
                            child: Center(
                              child: DayMosaic(cells: cells, size: mosaic, minCell: 7, gap: 2),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
