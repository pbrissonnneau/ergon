import 'package:flutter/material.dart';

import '../../core/local_date.dart';
import '../../domain/recurrence.dart';
import '../../domain/recurrence_engine.dart';
import '../formatting.dart';

/// Dialog to create/edit a [RecurrenceRule]. Returns null when cancelled.
Future<RecurrenceRule?> showRecurrenceDialog(
  BuildContext context, {
  RecurrenceRule? initial,
  required LocalDate today,
  String title = 'Repeat',
}) {
  return showDialog<RecurrenceRule>(
    context: context,
    builder: (_) => _RecurrenceDialog(initial: initial ?? RecurrenceRule.daily(today), today: today, title: title),
  );
}

enum _End { never, until, count }

class _RecurrenceDialog extends StatefulWidget {
  const _RecurrenceDialog({required this.initial, required this.today, required this.title});
  final RecurrenceRule initial;
  final LocalDate today;
  final String title;

  @override
  State<_RecurrenceDialog> createState() => _RecurrenceDialogState();
}

class _RecurrenceDialogState extends State<_RecurrenceDialog> {
  late RecurrenceFrequency freq = widget.initial.frequency;
  late int interval = widget.initial.interval;
  late Set<int> weekdays = {...widget.initial.weekdays};
  late MonthlyMode monthlyMode = widget.initial.monthlyMode;
  late int monthDay = widget.initial.monthDay ?? widget.initial.start.day;
  late int ordinal = widget.initial.weekOrdinal ?? ((widget.initial.start.day - 1) ~/ 7 + 1);
  late int ordinalWeekday = widget.initial.weekdays.isNotEmpty
      ? widget.initial.weekdays.first
      : widget.initial.start.weekday;
  late LocalDate start = widget.initial.start;
  late _End end = widget.initial.until != null
      ? _End.until
      : widget.initial.count != null
      ? _End.count
      : _End.never;
  late LocalDate until = widget.initial.until ?? widget.today.addMonths(3);
  late int count = widget.initial.count ?? 10;
  late final _intervalCtrl = TextEditingController(text: '$interval');
  late final _countCtrl = TextEditingController(text: '$count');

  @override
  void dispose() {
    _intervalCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  RecurrenceRule? get rule {
    try {
      return RecurrenceRule(
        frequency: freq,
        start: start,
        interval: interval,
        weekdays: switch (freq) {
          RecurrenceFrequency.weekly => weekdays,
          RecurrenceFrequency.monthly when monthlyMode == MonthlyMode.nthWeekday => {ordinalWeekday},
          _ => const {},
        },
        monthlyMode: freq == RecurrenceFrequency.monthly ? monthlyMode : MonthlyMode.dayOfMonth,
        monthDay: freq == RecurrenceFrequency.monthly && monthlyMode == MonthlyMode.dayOfMonth ? monthDay : null,
        weekOrdinal: freq == RecurrenceFrequency.monthly && monthlyMode == MonthlyMode.nthWeekday ? ordinal : null,
        until: end == _End.until ? until : null,
        count: end == _End.count ? count : null,
      );
    } catch (_) {
      return null;
    }
  }

  String get unit => switch (freq) {
    RecurrenceFrequency.daily => interval == 1 ? 'day' : 'days',
    RecurrenceFrequency.weekly => interval == 1 ? 'week' : 'weeks',
    RecurrenceFrequency.monthly => interval == 1 ? 'month' : 'months',
    RecurrenceFrequency.yearly => interval == 1 ? 'year' : 'years',
  };

  Future<LocalDate?> _pick(LocalDate initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial.atMinute(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    return d == null ? null : LocalDate.fromDateTime(d);
  }

  @override
  Widget build(BuildContext context) {
    final r = rule;
    final scheme = Theme.of(context).colorScheme;
    final preview = r == null ? const <LocalDate>[] : RecurrenceEngine.iterate(r, from: widget.today).take(5).toList();
    const ordinals = [(1, 'First'), (2, 'Second'), (3, 'Third'), (4, 'Fourth'), (5, 'Fifth'), (-1, 'Last')];
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<RecurrenceFrequency>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: RecurrenceFrequency.daily, label: Text('Daily')),
                  ButtonSegment(value: RecurrenceFrequency.weekly, label: Text('Weekly')),
                  ButtonSegment(value: RecurrenceFrequency.monthly, label: Text('Monthly')),
                  ButtonSegment(value: RecurrenceFrequency.yearly, label: Text('Yearly')),
                ],
                selected: {freq},
                onSelectionChanged: (s) => setState(() => freq = s.first),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Every'),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _intervalCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (v) => setState(() => interval = (int.tryParse(v) ?? 1).clamp(1, 999)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(unit),
                ],
              ),
              if (freq == RecurrenceFrequency.weekly) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      FilterChip(
                        label: Text(weekdayShortNames[d - 1]),
                        selected: weekdays.contains(d) || (weekdays.isEmpty && d == start.weekday),
                        showCheckmark: false,
                        onSelected: (on) => setState(() {
                          if (weekdays.isEmpty) weekdays = {start.weekday};
                          on ? weekdays.add(d) : weekdays.remove(d);
                        }),
                      ),
                  ],
                ),
              ],
              if (freq == RecurrenceFrequency.monthly) ...[
                const SizedBox(height: 12),
                RadioGroup<MonthlyMode>(
                  groupValue: monthlyMode,
                  onChanged: (v) => setState(() => monthlyMode = v!),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Radio(value: MonthlyMode.dayOfMonth),
                          const Text('On day'),
                          const SizedBox(width: 12),
                          DropdownButton<int>(
                            value: monthDay,
                            items: [
                              for (var i = 1; i <= 31; i++) DropdownMenuItem(value: i, child: Text('$i')),
                              const DropdownMenuItem(value: -1, child: Text('Last day')),
                            ],
                            onChanged: (v) => setState(() {
                              monthDay = v!;
                              monthlyMode = MonthlyMode.dayOfMonth;
                            }),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Radio(value: MonthlyMode.nthWeekday),
                          const Text('On the'),
                          const SizedBox(width: 12),
                          DropdownButton<int>(
                            value: ordinal,
                            items: [for (final (v, l) in ordinals) DropdownMenuItem(value: v, child: Text(l))],
                            onChanged: (v) => setState(() {
                              ordinal = v!;
                              monthlyMode = MonthlyMode.nthWeekday;
                            }),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: ordinalWeekday,
                            items: [
                              for (var d = 1; d <= 7; d++)
                                DropdownMenuItem(value: d, child: Text(weekdayShortNames[d - 1])),
                            ],
                            onChanged: (v) => setState(() {
                              ordinalWeekday = v!;
                              monthlyMode = MonthlyMode.nthWeekday;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (monthlyMode == MonthlyMode.dayOfMonth && monthDay > 28)
                  Text(
                    'In shorter months the last day is used.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
                  ),
              ],
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_arrow_outlined),
                title: const Text('Starts'),
                trailing: TextButton(
                  onPressed: () async {
                    final d = await _pick(start);
                    if (d != null) setState(() => start = d);
                  },
                  child: Text(Fmt.date(start, widget.today)),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.stop_outlined),
                  const SizedBox(width: 16),
                  const Text('Ends'),
                  const Spacer(),
                  DropdownButton<_End>(
                    value: end,
                    items: const [
                      DropdownMenuItem(value: _End.never, child: Text('Never')),
                      DropdownMenuItem(value: _End.until, child: Text('On date')),
                      DropdownMenuItem(value: _End.count, child: Text('After N times')),
                    ],
                    onChanged: (v) => setState(() => end = v!),
                  ),
                ],
              ),
              if (end == _End.until)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final d = await _pick(until);
                      if (d != null) setState(() => until = d);
                    },
                    child: Text('Until ${Fmt.date(until, widget.today)}'),
                  ),
                ),
              if (end == _End.count)
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _countCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(suffixText: 'times'),
                      onChanged: (v) => setState(() => count = (int.tryParse(v) ?? 1).clamp(1, 9999)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(r?.describe() ?? 'Invalid rule', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                preview.isEmpty
                    ? 'No upcoming dates'
                    : 'Next: ${preview.map((d) => Fmt.relativeDate(d, widget.today)).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: r == null ? null : () => Navigator.pop(context, r), child: const Text('Done')),
      ],
    );
  }
}
