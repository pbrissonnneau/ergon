import 'package:flutter/material.dart';

import '../../core/local_date.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart';
import '../formatting.dart';
import 'recurrence_editor.dart';

/// Creates a new reminder definition.
Future<Reminder?> showReminderDialog(
  BuildContext context, {
  required LocalDate today,
  required bool hasDue,
  required int defaultMinute,
}) {
  return showDialog<Reminder>(
    context: context,
    builder: (_) => _ReminderDialog(today: today, hasDue: hasDue, defaultMinute: defaultMinute),
  );
}

class _ReminderDialog extends StatefulWidget {
  const _ReminderDialog({required this.today, required this.hasDue, required this.defaultMinute});
  final LocalDate today;
  final bool hasDue;
  final int defaultMinute;

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late ReminderKind kind = widget.hasDue ? ReminderKind.relative : ReminderKind.once;
  late LocalDate date = widget.today;
  late int minute = _nextRoundMinute();
  int offset = 60;
  late RecurrenceRule rule = RecurrenceRule.daily(widget.today);
  int customValue = 3;
  int customUnit = 60 * 24; // minutes per unit

  static const presets = [
    (0, 'At due time'),
    (5, '5 minutes before'),
    (15, '15 minutes before'),
    (30, '30 minutes before'),
    (60, '1 hour before'),
    (120, '2 hours before'),
    (60 * 24, '1 day before'),
    (60 * 24 * 2, '2 days before'),
    (60 * 24 * 7, '1 week before'),
    (-1, 'Custom…'),
  ];

  int _nextRoundMinute() {
    final now = DateTime.now();
    final m = MinuteOfDay.fromDateTime(now) + 60;
    return m >= 24 * 60 ? widget.defaultMinute : (m ~/ 30) * 30;
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (t != null) setState(() => minute = t.hour * 60 + t.minute);
  }

  Reminder? get result => switch (kind) {
    ReminderKind.once => Reminder.once(date, minute),
    ReminderKind.relative => Reminder.relative(offset == -1 ? customValue * customUnit : offset),
    ReminderKind.repeating => Reminder.repeating(rule, minute),
    ReminderKind.snooze => null,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Add reminder'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<ReminderKind>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ReminderKind.once, label: Text('Date & time'), icon: Icon(Icons.alarm)),
                ButtonSegment(
                  value: ReminderKind.relative,
                  label: Text('Before due'),
                  icon: Icon(Icons.timer_outlined),
                ),
                ButtonSegment(value: ReminderKind.repeating, label: Text('Repeating'), icon: Icon(Icons.repeat)),
              ],
              selected: {kind},
              onSelectionChanged: (s) => setState(() => kind = s.first),
            ),
            const SizedBox(height: 16),
            switch (kind) {
              ReminderKind.once => Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: Text(Fmt.relativeDate(date, widget.today)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: date.atMinute(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => date = LocalDate.fromDateTime(d));
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(MinuteOfDay.format(minute)),
                    onPressed: _pickTime,
                  ),
                ],
              ),
              ReminderKind.relative => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.hasDue)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'This task has no due date yet; the reminder applies once one is set.',
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: offset,
                    items: [for (final (v, l) in presets) DropdownMenuItem(value: v, child: Text(l))],
                    onChanged: (v) => setState(() => offset = v!),
                  ),
                  if (offset == -1)
                    Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            initialValue: '$customValue',
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() => customValue = (int.tryParse(v) ?? 1).clamp(0, 9999)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<int>(
                          value: customUnit,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('minutes')),
                            DropdownMenuItem(value: 60, child: Text('hours')),
                            DropdownMenuItem(value: 60 * 24, child: Text('days')),
                            DropdownMenuItem(value: 60 * 24 * 7, child: Text('weeks')),
                          ],
                          onChanged: (v) => setState(() => customUnit = v!),
                        ),
                        const SizedBox(width: 12),
                        const Text('before'),
                      ],
                    ),
                  Text(
                    'Date-only due dates use ${MinuteOfDay.format(widget.defaultMinute)} (see Settings).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
                  ),
                ],
              ),
              ReminderKind.repeating => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.repeat),
                    title: Text(rule.describe()),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      final r = await showRecurrenceDialog(
                        context,
                        initial: rule,
                        today: widget.today,
                        title: 'Repeat reminder',
                      );
                      if (r != null) setState(() => rule = r);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text('At ${MinuteOfDay.format(minute)}'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: _pickTime,
                  ),
                ],
              ),
              ReminderKind.snooze => const SizedBox.shrink(),
            },
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, result), child: const Text('Add')),
      ],
    );
  }
}
