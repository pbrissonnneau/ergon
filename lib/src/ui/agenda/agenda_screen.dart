import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/agenda.dart';
import '../../domain/models.dart';
import '../bulk_actions.dart';
import '../editor/quick_add.dart';
import '../formatting.dart';
import '../widgets/live_query.dart';
import '../widgets/task_tile.dart';
import 'agenda_drop.dart';
import 'agenda_view.dart';
import 'backlog.dart';
import 'week_strip.dart';

/// Main screen: "What do I need to deal with today?"
///
/// Today/overdue/upcoming are below the fold anchor; scrolling *up* reveals
/// past days with what was completed each day (weekly review).
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  bool _overdueCollapsed = false;
  bool _backlogCollapsed = false;

  /// Keys of selected entries (multi-select); empty = normal mode.
  final _selected = <String>{};
  bool _selecting = false;
  Agenda? _agenda;

  /// How many past days are loaded (grows while scrolling up).
  int _pastDays = 14;
  LocalDate? _earliest;
  bool _earliestLoaded = false;
  final _centerKey = UniqueKey();

  static const _upcomingChoices = [
    (0, 'Today only'),
    (1, 'Today + tomorrow'),
    (3, 'Next 3 days'),
    (7, 'Next 7 days'),
    (14, 'Next 14 days'),
    (30, 'Next 30 days'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_earliestLoaded) {
      _earliestLoaded = true;
      unawaited(
        AppScope.of(context).tasks.earliestCompletion().then((d) {
          if (mounted) setState(() => _earliest = d);
        }),
      );
    }
  }

  List<AgendaEntry> get _selectedEntries =>
      _agenda?.sections.expand((s) => s.entries).where((e) => _selected.contains(e.key)).toList() ?? const [];

  void _toggle(AgendaEntry e) => setState(() {
    _selecting = true;
    _selected.contains(e.key) ? _selected.remove(e.key) : _selected.add(e.key);
  });

  void _exitSelection() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 560;
    return AgendaBuilderWidget(
      builder: (context, agenda) {
        _agenda = agenda;
        // Drop selections that disappeared (completed elsewhere, etc.).
        if (agenda != null && _selected.isNotEmpty) {
          final keys = agenda.sections.expand((s) => s.entries).map((e) => e.key).toSet();
          _selected.retainWhere(keys.contains);
        }
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            toolbarHeight: wide ? 64 : 56,
            title: Row(
              children: [
                ValueListenableBuilder(
                  valueListenable: s.today,
                  builder: (context, today, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Agenda'),
                      Text(
                        Fmt.longDate(today),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ),
                ),
                if (wide) ...[
                  const SizedBox(width: 20),
                  const Flexible(
                    child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: WeekStrip()),
                  ),
                ],
              ],
            ),
            bottom: wide
                ? null
                : const PreferredSize(
                    preferredSize: Size.fromHeight(60),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: FittedBox(fit: BoxFit.scaleDown, child: WeekStrip(square: 30)),
                    ),
                  ),
            actions: [
              if ((agenda?.completedCount ?? 0) > 0 && !_selecting)
                TextButton.icon(
                  onPressed: s.tasks.archiveAllCompleted,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text('Clear completed (${agenda!.completedCount})'),
                ),
              IconButton(
                tooltip: _selecting ? 'Cancel selection' : 'Select tasks (or Ctrl+click)',
                icon: Icon(_selecting ? Icons.close : Icons.checklist_rtl),
                onPressed: () => _selecting ? _exitSelection() : setState(() => _selecting = true),
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
              ListenableBuilder(
                listenable: s.settings,
                builder: (context, _) => PopupMenuButton<int>(
                  tooltip: 'Show upcoming days',
                  icon: const Icon(Icons.date_range),
                  initialValue: s.settings.upcomingDays,
                  onSelected: (v) {
                    s.settings.upcomingDays = v;
                    if (v > s.tasks.lookaheadDays) s.tasks.lookaheadDays = v;
                  },
                  itemBuilder: (_) => [
                    for (final (v, label) in _upcomingChoices)
                      CheckedPopupMenuItem(value: v, checked: s.settings.upcomingDays == v, child: Text(label)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: agenda == null
              ? const SizedBox.shrink()
              : ListenableBuilder(
                  listenable: s.settings,
                  builder: (context, _) => LayoutBuilder(
                    builder: (context, c) {
                      final show = s.settings.raw(Backlog.settingKey) != '0';
                      // Wide: backlog as a side panel; narrow: a section below the agenda.
                      final side = show && c.maxWidth >= 900;
                      final list = _body(context, agenda, backlogInList: show && !side);
                      if (!side) return list;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: list),
                          const SizedBox(width: 320, child: Backlog()),
                        ],
                      );
                    },
                  ),
                ),
          bottomNavigationBar: _selecting ? _selectionBar(context) : null,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Multi-select action bar
  // ---------------------------------------------------------------------------

  Widget _selectionBar(BuildContext context) {
    final s = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final n = _selected.length;
    Future<void> apply(Object? choice) async {
      final entries = _selectedEntries;
      if (entries.isEmpty) return;
      await BulkActions.applyMenuChoice(context, s, choice, entries);
      if (mounted) _exitSelection();
    }

    Widget menu(String label, IconData icon, List<PopupMenuEntry<Object>> Function() items) => PopupMenuButton<Object>(
      enabled: n > 0,
      tooltip: label,
      onSelected: apply,
      itemBuilder: (_) => items(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 20), const SizedBox(width: 4), Text(label)],
        ),
      ),
    );

    return BottomAppBar(
      height: 64,
      child: Row(
        children: [
          Text(n == 0 ? 'Select tasks' : '$n selected', style: TextStyle(color: scheme.primary)),
          const Spacer(),
          Flexible(
            flex: 6,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  menu('Reschedule', Icons.event, () => BulkActions.rescheduleItems(includeNoDate: true)),
                  menu('Priority', Icons.flag_outlined, () => BulkActions.priorityItems(scheme)),
                  LiveQuery<List<Project>>(
                    id: 'projects',
                    stream: s.projects.watchAll,
                    builder: (context, projects) =>
                        menu('Project', Icons.folder_outlined, () => BulkActions.projectItems(projects ?? const [])),
                  ),
                  TextButton.icon(
                    onPressed: n == 0 ? null : () => apply('complete'),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Complete'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // List
  // ---------------------------------------------------------------------------

  Widget _body(BuildContext context, Agenda agenda, {required bool backlogInList}) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppScope.of(context);
    final rows = flattenAgenda(agenda, scheme: scheme, overdueCollapsed: _overdueCollapsed);
    final today = agenda.today;
    final pastFrom = today.addDays(-_pastDays);

    final future = <Widget>[
      if (agenda.isEmpty)
        SliverToBoxAdapter(child: _emptyToday(context, agenda))
      else
        SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) => switch (rows[i]) {
            AgendaHeaderRow h =>
              h.section == null
                  ? _header(context, h, agenda)
                  : AgendaDropSlot(section: h.section!, today: today, child: _header(context, h, agenda)),
            AgendaEntryRow e => _dropSlot(
              e,
              today,
              AgendaEntryTile(
                key: ValueKey(e.entry.key),
                entry: e.entry,
                today: today,
                selected: _selecting ? _selected.contains(e.entry.key) : null,
                onSelect: () => _toggle(e.entry),
              ),
            ),
          },
        ),
      if (backlogInList)
        SliverToBoxAdapter(
          child: Backlog(
            asSection: true,
            collapsed: _backlogCollapsed,
            onToggle: () => setState(() => _backlogCollapsed = !_backlogCollapsed),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 96)),
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: LiveQuery<List<CompletedItem>>(
          id: (pastFrom, today),
          stream: () => s.tasks.watchCompleted(pastFrom, today.addDays(-1)),
          builder: (context, history) {
            final byDay = <int, List<CompletedItem>>{};
            for (final h in history ?? const <CompletedItem>[]) {
              byDay.putIfAbsent(h.day.epochDay, () => []).add(h);
            }
            final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a)); // Most recent first.
            final reachedStart = _earliest == null || pastFrom <= _earliest!;
            return CustomScrollView(
              center: _centerKey,
              slivers: [
                // Grows upwards from "Today": index 0 is the most recent day.
                SliverList.builder(
                  itemCount: days.length + 1,
                  itemBuilder: (context, i) {
                    if (i == days.length) {
                      if (!reachedStart) {
                        // Reached the top of what is loaded: load older days.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _pastDays += 28);
                        });
                      }
                      return _pastFooter(context, reachedStart, days.isEmpty);
                    }
                    final day = LocalDate.fromEpochDay(days[i]);
                    return _pastDay(context, day, byDay[days[i]]!, today);
                  },
                ),
                SliverToBoxAdapter(key: _centerKey, child: const SizedBox.shrink()),
                ...future,
              ],
            );
          },
        ),
      ),
    );
  }

  /// Agenda row accepting dragged tasks (reorder / move to this day).
  Widget _dropSlot(AgendaEntryRow e, LocalDate today, Widget tile) {
    final entries = e.section.entries;
    final i = entries.indexWhere((x) => x.key == e.entry.key);
    return AgendaDropSlot(
      section: e.section,
      today: today,
      thisKey: e.entry.key,
      nextKey: i >= 0 && i + 1 < entries.length ? entries[i + 1].key : null,
      child: tile,
    );
  }

  Widget _pastDay(BuildContext context, LocalDate day, List<CompletedItem> items, LocalDate today) {
    final theme = Theme.of(context);
    final isMonday = day.weekday == DateTime.monday;
    final postponed = items.where((h) => h.postponement != null).length;
    final done = items.length - postponed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 2),
          child: Row(
            children: [
              Text(
                today.daysUntil(day) == -1 ? 'Yesterday · ${Fmt.longDate(day)}' : Fmt.longDate(day),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                [if (done > 0 || postponed == 0) '$done done', if (postponed > 0) '$postponed postponed'].join(' · '),
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
        for (final h in items)
          if (h.postponement != null)
            PostponedTile(
              key: ValueKey('hp${h.postponement!.id}'),
              postponement: h.postponement!,
              today: today,
              dense: true,
            )
          else
            TaskTile(
              key: ValueKey('h${h.item.task.id}_${h.occurrence?.date.epochDay}'),
              item: h.item,
              occurrence: h.occurrence,
              today: today,
              dense: true,
            ),
        if (isMonday) const Divider(height: 20, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _pastFooter(BuildContext context, bool reachedStart, bool empty) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        reachedStart ? (empty ? 'No completed tasks yet' : 'Beginning of your history') : 'Loading earlier days…',
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _emptyToday(BuildContext context, Agenda agenda) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.wb_sunny_outlined, size: 56, color: scheme.primary),
          const SizedBox(height: 12),
          Text('All clear for today', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Nothing due, overdue or ongoing. Scroll up to see past days.', style: TextStyle(color: scheme.outline)),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => QuickAdd.show(context, due: agenda.today),
            icon: const Icon(Icons.add),
            label: const Text('Add a task for today'),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AgendaHeaderRow h, Agenda agenda) {
    final theme = Theme.of(context);
    final color = h.color ?? (h.big ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant);
    final isOverdue = h.collapsible;
    final text = Text(
      h.big ? h.title.toUpperCase() : h.title,
      style: (h.big ? theme.textTheme.titleSmall : theme.textTheme.labelLarge)?.copyWith(
        color: color,
        letterSpacing: h.big ? 1.1 : null,
        fontWeight: FontWeight.w700,
      ),
    );
    final row = Padding(
      padding: EdgeInsets.fromLTRB(16, h.big ? 18 : 10, 8, 4),
      child: Row(
        children: [
          text,
          if (h.count != null) ...[
            const SizedBox(width: 8),
            Text('${h.count}', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline)),
          ],
          const Spacer(),
          if (isOverdue) _overdueMenu(context, agenda, color),
          if (isOverdue) Icon(_overdueCollapsed ? Icons.expand_more : Icons.expand_less, size: 20, color: color),
          if (h.big && h.title == 'Today' && h.count == 0)
            Text('Nothing for today', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
    if (!isOverdue) return row;
    return InkWell(onTap: () => setState(() => _overdueCollapsed = !_overdueCollapsed), child: row);
  }

  /// "Overdue" header menu: act on every overdue task at once, or select.
  Widget _overdueMenu(BuildContext context, Agenda agenda, Color color) {
    final s = AppScope.of(context);
    final overdue = agenda.overdue?.entries.where((e) => e.isOpen).toList() ?? const <AgendaEntry>[];
    return PopupMenuButton<Object>(
      tooltip: 'All overdue tasks…',
      icon: Icon(Icons.more_horiz, color: color),
      onSelected: (choice) async {
        if (choice == 'select') {
          setState(() {
            _selecting = true;
            _selected.addAll(overdue.map((e) => e.key));
          });
          return;
        }
        await BulkActions.applyMenuChoice(context, s, choice, overdue);
      },
      itemBuilder: (_) => [
        const PopupMenuItem<Object>(enabled: false, height: 28, child: Text('Move all overdue to…')),
        ...BulkActions.rescheduleItems(),
        const PopupMenuDivider(),
        const PopupMenuItem<Object>(
          value: 'select',
          child: Row(
            children: [Icon(Icons.checklist_rtl, size: 18), SizedBox(width: 10), Text('Select overdue tasks…')],
          ),
        ),
      ],
    );
  }
}
