import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../domain/agenda.dart';
import '../editor/quick_add.dart';
import '../formatting.dart';
import 'agenda_view.dart';

/// Main screen: "What do I need to deal with today?"
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  bool _overdueCollapsed = false;

  static const _upcomingChoices = [
    (0, 'Today only'),
    (1, 'Today + tomorrow'),
    (3, 'Next 3 days'),
    (7, 'Next 7 days'),
    (14, 'Next 14 days'),
    (30, 'Next 30 days'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AgendaBuilderWidget(
      builder: (context, agenda) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: ValueListenableBuilder(
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
            actions: [
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
          body: agenda == null ? const SizedBox.shrink() : _body(context, agenda),
        );
      },
    );
  }

  Widget _body(BuildContext context, Agenda agenda) {
    final scheme = Theme.of(context).colorScheme;
    if (agenda.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny_outlined, size: 56, color: scheme.primary),
            const SizedBox(height: 12),
            Text('All clear for today', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Nothing due, overdue or ongoing.', style: TextStyle(color: scheme.outline)),
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
    final rows = flattenAgenda(agenda, scheme: scheme, overdueCollapsed: _overdueCollapsed);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 96),
              sliver: SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => switch (rows[i]) {
                  AgendaHeaderRow h => _header(context, h, agenda),
                  AgendaEntryRow e => AgendaEntryTile(key: ValueKey(e.entry.key), entry: e.entry, today: agenda.today),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AgendaHeaderRow h, Agenda agenda) {
    final theme = Theme.of(context);
    final color = h.color ?? (h.big ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant);
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
          if (h.collapsible) Icon(_overdueCollapsed ? Icons.expand_more : Icons.expand_less, size: 20, color: color),
          if (h.big && h.title == 'Today' && h.count == 0)
            Text('Nothing for today', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
    if (!h.collapsible) return row;
    return InkWell(onTap: () => setState(() => _overdueCollapsed = !_overdueCollapsed), child: row);
  }
}
