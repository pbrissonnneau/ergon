import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../data/task_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart';
import '../formatting.dart';
import '../task_actions.dart';
import '../theme.dart';
import '../widgets/markdown_editor.dart';
import '../widgets/task_tile.dart';
import 'quick_add.dart';
import 'recurrence_editor.dart';
import 'reminder_dialog.dart';
import '../widgets/live_query.dart';

/// Full task editor. Every change is saved immediately (text fields are
/// debounced), so there is no Save button and nothing can be lost.
class TaskEditorPage extends StatefulWidget {
  const TaskEditorPage({super.key, required this.taskId, this.isNew = false});
  final int taskId;

  /// Created untitled from "More options": focus the title, and discard the
  /// task if the user leaves without entering anything.
  final bool isNew;

  static Route<void> route(int taskId, {bool isNew = false}) => MaterialPageRoute<void>(
    builder: (_) => TaskEditorPage(taskId: taskId, isNew: isNew),
    settings: RouteSettings(name: '/task/$taskId'),
  );

  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> {
  Task? _task;
  TaskDraft? _draft;
  List<Task> _ancestry = const [];
  bool _missing = false;
  final _title = TextEditingController();
  final _description = TextEditingController();
  Timer? _textDebounce;
  StreamSubscription<Task?>? _sub;
  bool _saving = false;
  late AppServices _s;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = AppScope.of(context);
    _sub ??= _s.tasks.watchTask(widget.taskId).listen(_onTask);
  }

  Future<void> _onTask(Task? t) async {
    if (!mounted) return;
    if (t == null) {
      setState(() => _missing = true);
      return;
    }
    final first = _task == null;
    _task = t;
    if (first) {
      _draft = TaskDraft.fromTask(t, const []);
      _title.text = t.title;
      _description.text = t.description;
      _ancestry = await _s.tasks.ancestry(t.id);
    } else if (!_saving) {
      // Reflect changes made elsewhere (agenda, notification, other window)
      // for fields that are not being typed into.
      final d = _draft!;
      d
        ..status = t.status
        ..priority = t.priority
        ..projectId = t.projectId
        ..type = t.type
        ..recurrence = t.recurrence
        ..dueMinute = t.dueMinute
        ..dueDate = t.isRecurring ? null : t.dueDate;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textDebounce?.cancel();
    final saved = _pendingText ? _save() : Future<void>.value();
    if (widget.isNew && _title.text.trim().isEmpty) {
      final tasks = _s.tasks, id = widget.taskId, description = _description.text;
      unawaited(saved.then((_) => _discardIfEmpty(tasks, id, description)));
    } else {
      unawaited(saved);
    }
    _sub?.cancel();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  bool _pendingText = false;

  /// An untitled new task is deleted when nothing was entered; otherwise it
  /// is kept with a placeholder title so no work is lost.
  static Future<void> _discardIfEmpty(TaskRepository tasks, int id, String description) async {
    final subtasks = await tasks.watchSubtasks(id).first;
    final reminders = await tasks.getReminders(id);
    if (description.trim().isEmpty && subtasks.isEmpty && reminders.isEmpty) {
      await tasks.deleteTask(id);
    } else {
      await tasks.rename(id, 'Untitled task');
    }
  }

  /// Saves pending edits and closes the editor (Ctrl+Enter).
  Future<void> _saveAndClose() async {
    _textDebounce?.cancel();
    if (_pendingText) await _save();
    if (mounted) await Navigator.of(context).maybePop();
  }

  void _onTextChanged() {
    _pendingText = true;
    _textDebounce?.cancel();
    _textDebounce = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    final d = _draft;
    if (d == null) return;
    _pendingText = false;
    final title = _title.text.trim();
    d.title = title.isEmpty ? (_task?.title ?? 'Untitled') : title;
    d.description = _description.text;
    _saving = true;
    try {
      await _s.tasks.updateTask(widget.taskId, d, replaceReminders: false);
    } finally {
      _saving = false;
    }
  }

  void _update(void Function(TaskDraft d) change) {
    setState(() => change(_draft!));
    _textDebounce?.cancel();
    unawaited(_save());
  }

  @override
  Widget build(BuildContext context) {
    if (_missing) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This task no longer exists.')),
      );
    }
    final task = _task;
    final d = _draft;
    if (task == null || d == null) return Scaffold(appBar: AppBar());
    final today = _s.clock.today();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
        // Ctrl+Enter saves and closes, also from the multi-line description.
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _saveAndClose,
        const SingleActivator(LogicalKeyboardKey.numpadEnter, control: true): _saveAndClose,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _saveAndClose,
      },
      child: Scaffold(
        appBar: AppBar(
          title: _Breadcrumb(ancestry: _ancestry),
          actions: [
            IconButton(
              tooltip: d.status == TaskStatus.completed ? 'Mark as not completed' : 'Mark as completed',
              icon: Icon(d.status == TaskStatus.completed ? Icons.check_circle : Icons.check_circle_outline),
              onPressed: () => _update(
                (d) => d.status = d.status == TaskStatus.completed ? TaskStatus.notStarted : TaskStatus.completed,
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await TaskActions.confirmDelete(context, task) && context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
              children: [
                TextField(
                  controller: _title,
                  autofocus: widget.isNew,
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Task title'),
                  onChanged: (_) => _onTextChanged(),
                ),
                const SizedBox(height: 4),
                _properties(context, d, task),
                const SizedBox(height: 8),
                _schedule(context, d, today),
                const SizedBox(height: 8),
                _RemindersSection(task: task, hasDue: d.dueDate != null || d.recurrence != null),
                const SizedBox(height: 16),
                _sectionTitle(context, 'Description'),
                MarkdownEditor(controller: _description, startInPreview: true, onChanged: (_) => _onTextChanged()),
                const SizedBox(height: 16),
                _SubtasksSection(parent: task),
                if (task.isRecurring) ...[const SizedBox(height: 16), _OccurrencesSection(task: task)],
                const SizedBox(height: 24),
                _footer(context, task, today),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _properties(BuildContext context, TaskDraft d, Task task) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MenuChip<TaskStatus>(
          tooltip: 'Status',
          icon: Icon(AppTheme.statusIcon(d.status), size: 18, color: AppTheme.statusColor(d.status, scheme)),
          label: d.status.label,
          values: TaskStatus.values,
          current: d.status,
          itemLabel: (v) => v.label,
          itemIcon: (v) => Icon(AppTheme.statusIcon(v), color: AppTheme.statusColor(v, scheme)),
          onSelected: (v) => _update((d) => d.status = v),
        ),
        _MenuChip<TaskPriority>(
          tooltip: 'Priority',
          icon: Icon(AppTheme.priorityIcon(d.priority), size: 18, color: AppTheme.priorityColor(d.priority, scheme)),
          label: d.priority.label,
          values: TaskPriority.values.reversed.toList(),
          current: d.priority,
          itemLabel: (v) => v.label,
          itemIcon: (v) => Icon(AppTheme.priorityIcon(v), color: AppTheme.priorityColor(v, scheme)),
          onSelected: (v) => _update((d) => d.priority = v),
        ),
        _MenuChip<TaskType>(
          tooltip: 'Type',
          icon: Icon(AppTheme.typeIcon(d.type), size: 18),
          label: d.type.label,
          values: TaskType.values,
          current: d.type,
          itemLabel: (v) => v.label,
          itemIcon: (v) => Icon(AppTheme.typeIcon(v)),
          onSelected: (v) async {
            if (v == TaskType.recurring && d.recurrence == null) {
              final r = await showRecurrenceDialog(
                context,
                initial: RecurrenceRule.daily(d.dueDate ?? _s.clock.today()),
                today: _s.clock.today(),
              );
              if (r == null) return;
              _update((d) {
                d.type = v;
                d.recurrence = r;
              });
            } else {
              _update((d) {
                d.type = v;
                if (v != TaskType.recurring) d.recurrence = null;
              });
            }
          },
        ),
        if (task.parentId == null)
          LiveQuery<List<Project>>(
            id: 'projects',
            stream: _s.projects.watchAll,
            builder: (context, data) {
              final projects = data ?? const <Project>[];
              final current = projects.where((p) => p.id == d.projectId).firstOrNull;
              return _MenuChip<int>(
                tooltip: 'Project',
                icon: current == null
                    ? const Icon(Icons.folder_outlined, size: 18)
                    : CircleAvatar(radius: 6, backgroundColor: Color(current.color)),
                label: current?.name ?? 'No project',
                values: [-1, ...projects.map((p) => p.id)],
                current: d.projectId ?? -1,
                itemLabel: (v) => v == -1 ? 'No project' : projects.firstWhere((p) => p.id == v).name,
                itemIcon: (v) => v == -1
                    ? const Icon(Icons.folder_off_outlined)
                    : CircleAvatar(radius: 6, backgroundColor: Color(projects.firstWhere((p) => p.id == v).color)),
                onSelected: (v) => _update((d) => d.projectId = v == -1 ? null : v),
              );
            },
          ),
      ],
    );
  }

  Widget _schedule(BuildContext context, TaskDraft d, LocalDate today) {
    final scheme = Theme.of(context).colorScheme;
    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: (d.dueDate ?? today).atMinute(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) _update((d) => d.dueDate = LocalDate.fromDateTime(picked));
    }

    Future<void> pickTime() async {
      final m = d.dueMinute ?? _s.settings.defaultReminderMinute;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
      );
      if (t != null) {
        _update((d) {
          d.dueMinute = t.hour * 60 + t.minute;
          if (d.type != TaskType.recurring) d.dueDate ??= today;
        });
      }
    }

    if (d.type == TaskType.recurring && d.recurrence != null) {
      return Card.outlined(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(d.recurrence!.describe()),
              subtitle: const Text('Each occurrence can be completed independently'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final r = await showRecurrenceDialog(context, initial: d.recurrence, today: today);
                if (r != null) _update((d) => d.recurrence = r);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(d.dueMinute == null ? 'Any time of day' : 'At ${MinuteOfDay.format(d.dueMinute!)}'),
              onTap: pickTime,
              trailing: d.dueMinute == null
                  ? const Icon(Icons.add)
                  : IconButton(
                      tooltip: 'Remove time',
                      icon: const Icon(Icons.close),
                      onPressed: () => _update((d) => d.dueMinute = null),
                    ),
            ),
          ],
        ),
      );
    }

    final due = d.dueDate;
    final overdue = due != null && due < today && d.status.isOpen;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.event, color: overdue ? scheme.error : null),
        title: Text(
          due == null ? 'No due date' : Fmt.due(due, d.dueMinute, today),
          style: TextStyle(color: overdue ? scheme.error : null),
        ),
        subtitle: due == null ? null : Text(Fmt.longDate(due)),
        onTap: pickDate,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (due == null) ...[
              TextButton(onPressed: () => _update((d) => d.dueDate = today), child: const Text('Today')),
              TextButton(onPressed: () => _update((d) => d.dueDate = today.addDays(1)), child: const Text('Tomorrow')),
            ],
            IconButton(tooltip: 'Set time', icon: const Icon(Icons.schedule), onPressed: pickTime),
            if (due != null)
              IconButton(
                tooltip: 'Clear due date',
                icon: const Icon(Icons.close),
                onPressed: () => _update((d) {
                  d.dueDate = null;
                  d.dueMinute = null;
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, Task t, LocalDate today) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline);
    return Text(
      [
        'Created ${Fmt.timestamp(t.createdAt, today)}',
        'Updated ${Fmt.timestamp(t.updatedAt, today)}',
        if (t.completedAt != null) 'Completed ${Fmt.timestamp(t.completedAt!, today)}',
      ].join('  ·  '),
      style: style,
    );
  }
}

Widget _sectionTitle(BuildContext context, String text, {Widget? trailing}) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    children: [
      Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      const Spacer(),
      ?trailing,
    ],
  ),
);

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.ancestry});
  final List<Task> ancestry;

  @override
  Widget build(BuildContext context) {
    if (ancestry.length <= 1) return const Text('Task');
    final parents = ancestry.sublist(0, ancestry.length - 1);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in parents) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacement(TaskEditorPage.route(p.id)),
              child: Text(p.title, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
          const Text('Subtask'),
        ],
      ),
    );
  }
}

class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.values,
    required this.current,
    required this.itemLabel,
    required this.onSelected,
    this.itemIcon,
  });
  final String tooltip;
  final Widget icon;
  final String label;
  final List<T> values;
  final T current;
  final String Function(T) itemLabel;
  final Widget Function(T)? itemIcon;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    tooltip: tooltip,
    initialValue: current,
    onSelected: onSelected,
    itemBuilder: (_) => [
      for (final v in values)
        PopupMenuItem(
          value: v,
          child: Row(
            children: [
              if (itemIcon != null) ...[itemIcon!(v), const SizedBox(width: 10)],
              Text(itemLabel(v)),
            ],
          ),
        ),
    ],
    child: Chip(avatar: icon, label: Text(label)),
  );
}

class _RemindersSection extends StatelessWidget {
  const _RemindersSection({required this.task, required this.hasDue});
  final Task task;
  final bool hasDue;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return LiveQuery<List<Reminder>>(
      id: task.id,
      stream: () => s.tasks.watchReminders(task.id),
      builder: (context, data) {
        final reminders = data ?? const <Reminder>[];
        return Card.outlined(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(reminders.isEmpty ? 'No reminders' : 'Reminders'),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: () async {
                    final r = await showReminderDialog(
                      context,
                      today: s.clock.today(),
                      hasDue: hasDue,
                      defaultMinute: s.settings.defaultReminderMinute,
                    );
                    if (r != null) await s.tasks.addReminder(task.id, r);
                  },
                ),
              ),
              for (final r in reminders)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 56, right: 12),
                  leading: Icon(switch (r.kind) {
                    ReminderKind.once => Icons.alarm,
                    ReminderKind.relative => Icons.timer_outlined,
                    ReminderKind.repeating => Icons.repeat,
                    ReminderKind.snooze => Icons.snooze,
                  }, size: 20),
                  title: Text(r.describe()),
                  trailing: IconButton(
                    tooltip: 'Remove reminder',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => s.tasks.deleteReminder(r.id!),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SubtasksSection extends StatefulWidget {
  const _SubtasksSection({required this.parent});
  final Task parent;

  @override
  State<_SubtasksSection> createState() => _SubtasksSectionState();
}

class _SubtasksSectionState extends State<_SubtasksSection> {
  final _add = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _add.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return LiveQuery<List<TaskListItem>>(
      id: widget.parent.id,
      stream: () => s.tasks.watchSubtasks(widget.parent.id),
      builder: (context, data) {
        final subs = data ?? const <TaskListItem>[];
        final done = subs.where((e) => e.task.status.isClosed).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(
              context,
              subs.isEmpty ? 'Subtasks' : 'Subtasks  $done/${subs.length}',
              trailing: IconButton(
                tooltip: 'Subtask with details',
                icon: const Icon(Icons.playlist_add),
                onPressed: () => QuickAdd.show(context, parentId: widget.parent.id),
              ),
            ),
            if (subs.isNotEmpty)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: subs.length,
                onReorderItem: (from, to) {
                  final ids = subs.map((e) => e.task.id).toList();
                  ids.insert(to, ids.removeAt(from));
                  s.tasks.reorderSubtasks(ids);
                },
                itemBuilder: (context, i) => Row(
                  key: ValueKey(subs[i].task.id),
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.drag_indicator, size: 18),
                      ),
                    ),
                    Expanded(
                      child: TaskTile(
                        item: subs[i],
                        today: s.clock.today(),
                        showProject: false,
                        showParent: false,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _add,
              focusNode: _focus,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.add),
                hintText: 'Add subtask',
                border: InputBorder.none,
              ),
              onSubmitted: (v) async {
                if (v.trim().isEmpty) return;
                _add.clear();
                await s.tasks.addSubtask(widget.parent.id, v);
                _focus.requestFocus();
              },
            ),
          ],
        );
      },
    );
  }
}

class _OccurrencesSection extends StatefulWidget {
  const _OccurrencesSection({required this.task});
  final Task task;

  @override
  State<_OccurrencesSection> createState() => _OccurrencesSectionState();
}

class _OccurrencesSectionState extends State<_OccurrencesSection> {
  int _limit = 15;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final today = s.clock.today();
    return LiveQuery<List<Occurrence>>(
      id: (widget.task.id, _limit),
      stream: () => s.tasks.watchOccurrences(widget.task.id, limit: _limit + 1),
      builder: (context, data) {
        final all = data ?? const <Occurrence>[];
        final list = all.take(_limit).toList();
        final done = list.where((o) => o.status == TaskStatus.completed).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(
              context,
              'Occurrences',
              trailing: Text(
                '$done of ${list.length} completed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
            ),
            for (final o in list)
              ListTile(
                dense: true,
                leading: IconButton(
                  icon: Icon(AppTheme.statusIcon(o.status), color: AppTheme.statusColor(o.status, scheme)),
                  tooltip: o.status == TaskStatus.completed ? 'Mark not completed' : 'Complete',
                  onPressed: () => s.tasks.setOccurrenceStatus(
                    widget.task.id,
                    o.date,
                    o.status == TaskStatus.completed ? TaskStatus.notStarted : TaskStatus.completed,
                  ),
                ),
                title: Text(
                  '${Fmt.weekdayShort(o.date)}, ${Fmt.date(o.date, today)}'
                  '${o.dueMinute == null ? '' : ' · ${MinuteOfDay.format(o.dueMinute!)}'}',
                  style: TextStyle(
                    color: o.date < today && o.status.isOpen ? scheme.error : null,
                    fontWeight: o.date == today ? FontWeight.w600 : null,
                  ),
                ),
                subtitle: Text(o.status.label),
                trailing: PopupMenuButton<TaskStatus>(
                  tooltip: 'Set status',
                  onSelected: (st) => s.tasks.setOccurrenceStatus(widget.task.id, o.date, st),
                  itemBuilder: (_) => [
                    for (final st in TaskStatus.values) PopupMenuItem(value: st, child: Text(st.label)),
                  ],
                ),
              ),
            if (all.length > _limit)
              TextButton(onPressed: () => setState(() => _limit += 30), child: const Text('Show older')),
          ],
        );
      },
    );
  }
}
