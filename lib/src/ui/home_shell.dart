import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_services.dart';
import 'agenda/agenda_screen.dart';
import 'editor/quick_add.dart';
import 'projects/projects_screen.dart';
import 'settings/settings_screen.dart';
import 'tasks/tasks_screen.dart';

/// Adaptive navigation: bottom bar on phones, rail on wide windows.
/// Tabs are kept alive (IndexedStack) so switching is instant.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.dataPath});
  final String dataPath;

  static final GlobalKey<HomeShellState> globalKey = GlobalKey<HomeShellState>();

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _searchFocus = FocusNode();
  late final _navigators = List.generate(4, (_) => GlobalKey<NavigatorState>());

  static const _destinations = [
    (Icons.today_outlined, Icons.today, 'Agenda'),
    (Icons.checklist_outlined, Icons.checklist, 'Tasks'),
    (Icons.folder_outlined, Icons.folder, 'Projects'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void select(int i) {
    if (i == _index) {
      _navigators[i].currentState?.popUntil((r) => r.isFirst);
    }
    setState(() => _index = i);
    // Offstage tabs cannot take focus; wait until the tab is visible.
    if (i == 1) WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  void quickAdd() {
    final ctx = _navigators[_index].currentContext ?? context;
    QuickAdd.show(ctx, due: _index == 0 ? AppScope.of(context).today.value : null);
  }

  Widget _tab(int i) {
    final child = switch (i) {
      0 => const AgendaScreen(),
      1 => TasksScreen(searchFocus: _searchFocus),
      2 => const ProjectsScreen(),
      _ => SettingsScreen(dataPath: widget.dataPath),
    };
    return Navigator(
      key: _navigators[i],
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final body = IndexedStack(index: _index, children: [for (var i = 0; i < 4; i++) _tab(i)]);
    final fab = _index < 3
        ? FloatingActionButton(tooltip: 'New task (Ctrl+N)', onPressed: quickAdd, child: const Icon(Icons.add))
        : null;

    final scaffold = wide
        ? Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: select,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FloatingActionButton.small(
                      heroTag: 'rail-add',
                      tooltip: 'New task (Ctrl+N)',
                      elevation: 0,
                      onPressed: quickAdd,
                      child: const Icon(Icons.add),
                    ),
                  ),
                  destinations: [
                    for (final (icon, selected, label) in _destinations)
                      NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          )
        : Scaffold(
            body: body,
            floatingActionButton: fab,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: select,
              height: 64,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: [
                for (final (icon, selected, label) in _destinations)
                  NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
              ],
            ),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = _navigators[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        } else {
          await SystemNavigator.pop();
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): quickAdd,
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => select(1),
          const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => select(0),
          const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => select(1),
          const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => select(2),
          const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => select(3),
        },
        child: Focus(autofocus: true, child: scaffold),
      ),
    );
  }

  /// Opens a task in the current tab's navigator.
  void openTask(Widget page) {
    _navigators[_index].currentState?.push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
