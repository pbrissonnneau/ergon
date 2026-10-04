import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../formatting.dart';
import '../task_actions.dart';
import '../theme.dart';
import '../widgets/live_query.dart';

/// Minimal-interaction task creation: type a title, press Enter.
abstract final class QuickAdd {
  static Future<void> show(BuildContext context, {int? projectId, LocalDate? due, int? parentId}) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final sheet = _QuickAddForm(projectId: projectId, due: due, parentId: parentId, hostContext: context);
    if (wide) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          alignment: const Alignment(0, -0.5),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: sheet),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: sheet,
      ),
    );
  }
}

class _QuickAddForm extends StatefulWidget {
  const _QuickAddForm({this.projectId, this.due, this.parentId, required this.hostContext});
  final int? projectId;
  final LocalDate? due;
  final int? parentId;
  final BuildContext hostContext;

  @override
  State<_QuickAddForm> createState() => _QuickAddFormState();
}

class _QuickAddFormState extends State<_QuickAddForm> {
  final _title = TextEditingController();
  late LocalDate? _due = widget.due;
  late int? _projectId = widget.projectId;
  TaskPriority _priority = TaskPriority.normal;
  TaskType _type = TaskType.oneTime;
  bool _busy = false;
  int _added = 0;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<int?> _create() async {
    final title = _title.text.trim();
    if (title.isEmpty || _busy) return null;
    _busy = true;
    try {
      return await AppScope.of(context).tasks.createTask(
        TaskDraft(
          title: title,
          dueDate: _due,
          projectId: _projectId,
          priority: _priority,
          type: _type,
          parentId: widget.parentId,
        ),
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> _submit({bool keepOpen = false}) async {
    final id = await _create();
    if (id == null || !mounted) return;
    if (keepOpen) {
      setState(() {
        _added++;
        _title.clear();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _moreOptions() async {
    final id = await _create();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (id != null && widget.hostContext.mounted) await TaskActions.open(widget.hostContext, id);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final today = s.clock.today();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.parentId == null ? 'New task' : 'New subtask', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          CallbackShortcuts(
            bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): () => _submit(keepOpen: true)},
            child: TextField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: 'What needs to be done?', border: OutlineInputBorder()),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('No date'),
                selected: _due == null,
                onSelected: (_) => setState(() => _due = null),
              ),
              ChoiceChip(
                label: const Text('Today'),
                selected: _due == today,
                onSelected: (_) => setState(() => _due = today),
              ),
              ChoiceChip(
                label: const Text('Tomorrow'),
                selected: _due == today.addDays(1),
                onSelected: (_) => setState(() => _due = today.addDays(1)),
              ),
              ActionChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(
                  _due != null && _due != today && _due != today.addDays(1) ? Fmt.date(_due!, today) : 'Pick…',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: (_due ?? today).atMinute(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _due = LocalDate.fromDateTime(picked));
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PopupMenuButton<TaskPriority>(
                tooltip: 'Priority',
                initialValue: _priority,
                onSelected: (p) => setState(() => _priority = p),
                itemBuilder: (_) => [
                  for (final p in TaskPriority.values)
                    PopupMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Icon(AppTheme.priorityIcon(p), color: AppTheme.priorityColor(p, scheme)),
                          const SizedBox(width: 8),
                          Text(p.label),
                        ],
                      ),
                    ),
                ],
                child: Chip(
                  avatar: Icon(
                    AppTheme.priorityIcon(_priority),
                    size: 18,
                    color: AppTheme.priorityColor(_priority, scheme),
                  ),
                  label: Text(_priority.label),
                ),
              ),
              if (widget.parentId == null)
                PopupMenuButton<TaskType>(
                  tooltip: 'Type',
                  initialValue: _type,
                  onSelected: (t) => setState(() => _type = t),
                  itemBuilder: (_) => [
                    for (final t in [TaskType.oneTime, TaskType.ongoing]) PopupMenuItem(value: t, child: Text(t.label)),
                  ],
                  child: Chip(avatar: Icon(AppTheme.typeIcon(_type), size: 18), label: Text(_type.label)),
                ),
              if (widget.parentId == null)
                LiveQuery<List<Project>>(
                  id: 'projects',
                  stream: s.projects.watchAll,
                  builder: (context, data) {
                    final projects = data ?? const <Project>[];
                    final current = projects.where((p) => p.id == _projectId).firstOrNull;
                    return PopupMenuButton<int>(
                      tooltip: 'Project',
                      onSelected: (id) => setState(() => _projectId = id == -1 ? null : id),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: -1, child: Text('No project')),
                        for (final p in projects)
                          PopupMenuItem(
                            value: p.id,
                            child: Row(
                              children: [
                                CircleAvatar(radius: 6, backgroundColor: Color(p.color)),
                                const SizedBox(width: 8),
                                Text(p.name),
                              ],
                            ),
                          ),
                      ],
                      child: Chip(
                        avatar: current == null
                            ? const Icon(Icons.folder_outlined, size: 18)
                            : CircleAvatar(radius: 6, backgroundColor: Color(current.color)),
                        label: Text(current?.name ?? 'No project'),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_added > 0) Text('$_added added', style: TextStyle(color: scheme.outline)),
              const Spacer(),
              TextButton(onPressed: _moreOptions, child: const Text('More options')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _submit, child: const Text('Add')),
            ],
          ),
        ],
      ),
    );
  }
}
