import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../core/startup_trace.dart';
import '../../domain/agenda.dart';
import '../formatting.dart';
import '../widgets/task_tile.dart';

/// Subscribes to the live agenda for the current day and upcoming setting.
class AgendaBuilderWidget extends StatefulWidget {
  const AgendaBuilderWidget({super.key, required this.builder, this.upcomingDaysOverride});
  final Widget Function(BuildContext context, Agenda? agenda) builder;
  final int? upcomingDaysOverride;

  @override
  State<AgendaBuilderWidget> createState() => _AgendaBuilderWidgetState();
}

class _AgendaBuilderWidgetState extends State<AgendaBuilderWidget> {
  StreamSubscription<Agenda>? _sub;
  Agenda? _agenda;
  LocalDate? _day;
  int? _upcoming;
  late AppServices _s;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = AppScope.of(context);
    _s.today.addListener(_resubscribe);
    _s.settings.addListener(_resubscribe);
    _resubscribe();
  }

  @override
  void didUpdateWidget(AgendaBuilderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.upcomingDaysOverride != widget.upcomingDaysOverride) _resubscribe();
  }

  void _resubscribe() {
    final day = _s.today.value;
    final upcoming = widget.upcomingDaysOverride ?? _s.settings.upcomingDays;
    if (day == _day && upcoming == _upcoming && _sub != null) return;
    _day = day;
    _upcoming = upcoming;
    _sub?.cancel();
    _sub = _s.agenda.watch(today: day, upcomingDays: upcoming).listen((a) {
      StartupTrace.mark('agenda-data');
      if (mounted) setState(() => _agenda = a);
    });
  }

  @override
  void dispose() {
    _s.today.removeListener(_resubscribe);
    _s.settings.removeListener(_resubscribe);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _agenda);
}

/// Flattened agenda rows (headers + entries) for a single lazy sliver list.
sealed class AgendaRow {}

class AgendaHeaderRow extends AgendaRow {
  AgendaHeaderRow(this.title, {this.count, this.big = false, this.color, this.collapsible = false});
  final String title;
  final int? count;
  final bool big;
  final Color? color;
  final bool collapsible;
}

class AgendaEntryRow extends AgendaRow {
  AgendaEntryRow(this.entry);
  final AgendaEntry entry;
}

List<AgendaRow> flattenAgenda(Agenda a, {required ColorScheme scheme, bool overdueCollapsed = false}) {
  final rows = <AgendaRow>[];
  final today = a.todaySections.toList();
  rows.add(AgendaHeaderRow('Today', count: a.todayCount, big: true));
  for (final s in today) {
    rows.add(
      AgendaHeaderRow(
        s.kind.label,
        count: s.openCount,
        color: s.kind == AgendaSectionKind.todayUrgent ? const Color(0xFFE03131) : null,
      ),
    );
    rows.addAll(s.entries.map(AgendaEntryRow.new));
  }
  final overdue = a.overdue;
  if (overdue != null) {
    rows.add(AgendaHeaderRow('Overdue', count: overdue.openCount, big: true, color: scheme.error, collapsible: true));
    if (!overdueCollapsed) rows.addAll(overdue.entries.map(AgendaEntryRow.new));
  }
  final upcoming = a.upcoming.toList();
  if (upcoming.isNotEmpty) {
    rows.add(AgendaHeaderRow('Upcoming', count: upcoming.fold<int>(0, (n, s) => n + s.openCount), big: true));
    for (final s in upcoming) {
      final d = s.date!;
      rows.add(
        AgendaHeaderRow(
          a.today.daysUntil(d) == 1 ? 'Tomorrow · ${Fmt.longDate(d)}' : Fmt.longDate(d),
          count: s.openCount,
        ),
      );
      rows.addAll(s.entries.map(AgendaEntryRow.new));
    }
  }
  return rows;
}

class AgendaEntryTile extends StatelessWidget {
  const AgendaEntryTile({super.key, required this.entry, required this.today, this.selected, this.onSelect});
  final AgendaEntry entry;
  final LocalDate today;
  final bool? selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) => ExpandableTaskTile(
    item: entry.item,
    occurrence: entry.occurrence,
    today: today,
    missedCount: entry.missedCount,
    // Done today: stays visible until tomorrow, unless removed now.
    onRemove: entry.isDone
        ? () {
            final tasks = AppScope.of(context).tasks;
            final occ = entry.occurrence;
            occ != null ? tasks.archiveOccurrence(entry.task.id, occ.date) : tasks.archiveTask(entry.task.id);
          }
        : null,
    selected: selected,
    onSelect: onSelect,
  );
}
