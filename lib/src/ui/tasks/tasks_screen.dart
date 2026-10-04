import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/task_query.dart';
import '../theme.dart';
import '../widgets/task_tile.dart';

/// Global search with combinable filters.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.project, this.searchFocus});

  /// When set, the list is scoped to this project.
  final Project? project;
  final FocusNode? searchFocus;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _search = TextEditingController();
  late final FocusNode _focus = widget.searchFocus ?? FocusNode();
  late final TaskQuery _base = widget.project == null
      ? const TaskQuery()
      : widget.project!.id < 0
          ? const TaskQuery(withoutProject: true)
          : TaskQuery(projectIds: {widget.project!.id});
  late TaskQuery _query = _base;
  Timer? _debounce;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _search.dispose();
    if (widget.searchFocus == null) _focus.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.position.extentAfter < 800 && _lastCount >= _query.limit) {
      setState(() => _query = _query.copyWith(limit: _query.limit + 200));
    }
  }

  int _lastCount = 0;

  void _onSearch(String text) {
    _debounce?.cancel();
    // Very short debounce: queries are indexed and run off the UI thread.
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _query = _query.copyWith(text: text, limit: 200));
    });
  }

  void _set(TaskQuery q) => setState(() => _query = q.copyWith(limit: 200));

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: widget.project != null
            ? Row(children: [
                CircleAvatar(radius: 7, backgroundColor: Color(widget.project!.color)),
                const SizedBox(width: 10),
                Flexible(child: Text(widget.project!.name, overflow: TextOverflow.ellipsis)),
              ])
            : const Text('Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: SearchBar(
                controller: _search,
                focusNode: _focus,
                hintText: widget.project == null ? 'Search tasks, descriptions, projects' : 'Search in project',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                constraints: const BoxConstraints(minHeight: 44, maxHeight: 44),
                trailing: [
                  if (_search.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        _onSearch('');
                        setState(() {});
                      },
                    ),
                ],
                onChanged: (t) {
                  _onSearch(t);
                  setState(() {});
                },
              ),
            ),
            SizedBox(height: 48, child: _FilterBar(query: _query, base: _base, onChanged: _set, scopedToProject: widget.project != null)),
          ]),
        ),
      ),
      body: StreamBuilder<List<TaskListItem>>(
        stream: s.tasks.watchQuery(_query),
        builder: (context, snap) {
          final items = snap.data;
          if (items == null) return const SizedBox.shrink();
          _lastCount = items.length;
          if (items.isEmpty) {
            return Center(
              child: Text(_query.text.isEmpty && !_query.hasFilters ? 'No open tasks' : 'No matching tasks',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            );
          }
          return ValueListenableBuilder(
            valueListenable: s.today,
            builder: (context, today, _) => Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  itemBuilder: (context, i) => TaskTile(
                    key: ValueKey(items[i].task.id),
                    item: items[i],
                    today: today,
                    showProject: widget.project == null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.query, required this.base, required this.onChanged, required this.scopedToProject});
  final TaskQuery query;
  final TaskQuery base;
  final ValueChanged<TaskQuery> onChanged;
  final bool scopedToProject;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      children: [
        if (_filtered)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              avatar: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Reset'),
              onPressed: () => onChanged(base.copyWith(text: query.text, sort: query.sort)),
            ),
          ),
        _menu<CompletionFilter>(
          context,
          label: query.completion.label,
          active: query.completion != CompletionFilter.open,
          icon: Icons.done_all,
          values: CompletionFilter.values,
          text: (v) => v.label,
          isSelected: (v) => v == query.completion,
          onSelect: (v) => onChanged(query.copyWith(completion: v)),
        ),
        if (!scopedToProject)
          StreamBuilder<List<Project>>(
            stream: s.projects.watchAll(),
            builder: (context, snap) {
              final projects = snap.data ?? const <Project>[];
              final n = query.projectIds.length + (query.withoutProject ? 1 : 0);
              return _multiMenu<int>(
                context,
                label: n == 0
                    ? 'Project'
                    : n == 1 && query.projectIds.length == 1
                        ? projects.where((p) => p.id == query.projectIds.first).firstOrNull?.name ?? 'Project'
                        : n == 1
                            ? 'No project'
                            : '$n projects',
                icon: Icons.folder_outlined,
                active: n > 0,
                values: [-1, ...projects.map((p) => p.id)],
                text: (v) => v == -1 ? 'No project' : projects.firstWhere((p) => p.id == v).name,
                isSelected: (v) => v == -1 ? query.withoutProject : query.projectIds.contains(v),
                onToggle: (v) {
                  if (v == -1) {
                    onChanged(query.copyWith(withoutProject: !query.withoutProject));
                  } else {
                    final set = {...query.projectIds};
                    set.contains(v) ? set.remove(v) : set.add(v);
                    onChanged(query.copyWith(projectIds: set));
                  }
                },
              );
            },
          ),
        _multiMenu<TaskStatus>(
          context,
          label: query.statuses.isEmpty
              ? 'Status'
              : query.statuses.length == 1
                  ? query.statuses.first.label
                  : '${query.statuses.length} statuses',
          icon: Icons.radio_button_checked,
          active: query.statuses.isNotEmpty,
          values: TaskStatus.values,
          text: (v) => v.label,
          leading: (v) => Icon(AppTheme.statusIcon(v), size: 18, color: AppTheme.statusColor(v, scheme)),
          isSelected: query.statuses.contains,
          onToggle: (v) => onChanged(query.copyWith(
              statuses: query.statuses.contains(v) ? ({...query.statuses}..remove(v)) : {...query.statuses, v},
              completion: CompletionFilter.all)),
        ),
        _multiMenu<TaskPriority>(
          context,
          label: query.priorities.isEmpty
              ? 'Priority'
              : query.priorities.length == 1
                  ? query.priorities.first.label
                  : '${query.priorities.length} priorities',
          icon: Icons.flag_outlined,
          active: query.priorities.isNotEmpty,
          values: TaskPriority.values.reversed.toList(),
          text: (v) => v.label,
          leading: (v) => Icon(AppTheme.priorityIcon(v), size: 18, color: AppTheme.priorityColor(v, scheme)),
          isSelected: query.priorities.contains,
          onToggle: (v) => onChanged(query.copyWith(
              priorities:
                  query.priorities.contains(v) ? ({...query.priorities}..remove(v)) : {...query.priorities, v})),
        ),
        _multiMenu<TaskType>(
          context,
          label: query.types.isEmpty ? 'Type' : query.types.map((t) => t.label).join(', '),
          icon: Icons.category_outlined,
          active: query.types.isNotEmpty,
          values: TaskType.values,
          text: (v) => v.label,
          leading: (v) => Icon(AppTheme.typeIcon(v), size: 18),
          isSelected: query.types.contains,
          onToggle: (v) => onChanged(
              query.copyWith(types: query.types.contains(v) ? ({...query.types}..remove(v)) : {...query.types, v})),
        ),
        _menu<DueFilter>(
          context,
          label: query.due == DueFilter.any ? 'Due date' : query.due.label,
          icon: Icons.event_outlined,
          active: query.due != DueFilter.any,
          values: DueFilter.values,
          text: (v) => v.label,
          isSelected: (v) => v == query.due,
          onSelect: (v) => onChanged(query.copyWith(due: v)),
        ),
        _menu<TaskSort>(
          context,
          label: 'Sort: ${query.sort.label}',
          icon: Icons.sort,
          active: false,
          values: TaskSort.values,
          text: (v) => v.label,
          isSelected: (v) => v == query.sort,
          onSelect: (v) => onChanged(query.copyWith(sort: v)),
        ),
        FilterChip(
          label: const Text('Subtasks'),
          selected: query.includeSubtasks,
          onSelected: (v) => onChanged(query.copyWith(includeSubtasks: v)),
        ),
      ],
    );
  }

  bool get _filtered =>
      query.statuses.isNotEmpty ||
      query.priorities.isNotEmpty ||
      query.types.isNotEmpty ||
      query.due != DueFilter.any ||
      query.completion != CompletionFilter.open ||
      (!scopedToProject && (query.projectIds.isNotEmpty || query.withoutProject));

  Widget _chip(BuildContext context, String label, IconData icon, bool active) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 18, color: active ? scheme.onSecondaryContainer : null),
      label: Text(label),
      backgroundColor: active ? scheme.secondaryContainer : null,
      deleteIcon: const Icon(Icons.arrow_drop_down, size: 18),
      onDeleted: null,
    );
  }

  Widget _menu<T>(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool active,
    required List<T> values,
    required String Function(T) text,
    required bool Function(T) isSelected,
    required ValueChanged<T> onSelect,
  }) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: PopupMenuButton<T>(
          tooltip: label,
          onSelected: onSelect,
          itemBuilder: (_) => [
            for (final v in values) CheckedPopupMenuItem(value: v, checked: isSelected(v), child: Text(text(v))),
          ],
          child: _chip(context, label, icon, active),
        ),
      );

  Widget _multiMenu<T>(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool active,
    required List<T> values,
    required String Function(T) text,
    required bool Function(T) isSelected,
    required ValueChanged<T> onToggle,
    Widget Function(T)? leading,
  }) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: MenuAnchor(
          menuChildren: [
            for (final v in values)
              CheckboxMenuButton(
                value: isSelected(v),
                closeOnActivate: false,
                onChanged: (_) => onToggle(v),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (leading != null) ...[leading(v), const SizedBox(width: 8)],
                  Text(text(v)),
                ]),
              ),
          ],
          builder: (context, controller, _) => GestureDetector(
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            child: _chip(context, label, icon, active),
          ),
        ),
      );
}
