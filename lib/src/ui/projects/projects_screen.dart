import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../data/project_repository.dart';
import '../../domain/models.dart';
import '../tasks/tasks_screen.dart';
import '../widgets/live_query.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-project',
        onPressed: () => editProject(context),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New project'),
      ),
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            tooltip: 'New project',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => editProject(context),
          ),
        ],
      ),
      body: LiveQuery<List<ProjectWithCount>>(
        id: 'projects',
        stream: s.projects.watchWithCounts,
        builder: (context, list) {
          if (list == null) return const SizedBox.shrink();
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_open, size: 48),
                  const SizedBox(height: 8),
                  const Text('No projects yet'),
                  const SizedBox(height: 12),
                  FilledButton.tonal(onPressed: () => editProject(context), child: const Text('Create a project')),
                ],
              ),
            );
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  ListTile(
                    leading: const Icon(Icons.inbox_outlined),
                    title: const Text('Tasks without project'),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _NoProjectTasks())),
                  ),
                  const Divider(),
                  for (final pc in list)
                    ListTile(
                      leading: CircleAvatar(radius: 8, backgroundColor: Color(pc.project.color)),
                      title: Text(pc.project.name),
                      subtitle: Text(pc.openCount == 0 ? 'No open tasks' : '${pc.openCount} open'),
                      onTap: () =>
                          Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => TasksScreen(project: pc.project))),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') await editProject(context, project: pc.project);
                          if (v == 'delete' && context.mounted) await _delete(context, pc.project);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Rename / color')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<void> editProject(BuildContext context, {Project? project}) async {
    final s = AppScope.of(context);
    final ctrl = TextEditingController(text: project?.name ?? '');
    var color = project?.color ?? ProjectRepository.palette.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(project == null ? 'New project' : 'Edit project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                onSubmitted: (_) => Navigator.pop(c, true),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final col in ProjectRepository.palette)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => set(() => color = col),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(col),
                        child: col == color ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (result != true || name.isEmpty) return;
    if (project == null) {
      await s.projects.create(name, color: color);
    } else {
      await s.projects.update(project.id, name: name, color: color);
    }
  }

  static Future<void> _delete(BuildContext context, Project p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('“${p.name}” will be deleted. Its tasks are kept and moved to “No project”.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) await AppScope.of(context).projects.delete(p.id);
  }
}

class _NoProjectTasks extends StatelessWidget {
  const _NoProjectTasks();
  @override
  Widget build(BuildContext context) =>
      const TasksScreen(project: Project(id: -1, name: 'No project', color: 0xFF9E9E9E));
}
