import 'dart:async';

import 'package:flutter/material.dart';

import '../ui/editor/task_editor_page.dart';
import '../ui/home_shell.dart';
import '../ui/theme.dart';
import 'app_services.dart';

/// Root widget of the main window / phone app.
class ErgonApp extends StatefulWidget {
  const ErgonApp({super.key, required this.services, required this.dataPath});
  final AppServices services;
  final String dataPath;

  @override
  State<ErgonApp> createState() => _ErgonAppState();
}

class _ErgonAppState extends State<ErgonApp> with WidgetsBindingObserver {
  StreamSubscription<int>? _openSub;
  StreamSubscription<void>? _addSub;

  AppServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openSub = s.openTaskRequests.listen(_openTask);
    _addSub = s.platform.quickAddRequests.listen((_) => HomeShell.globalKey.currentState?.quickAdd());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _openSub?.cancel();
    _addSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Timezone, date or alarms may have changed while in background.
      s.refreshDay();
      s.reminders.scheduleReconcile();
    }
  }

  void _openTask(int id) {
    final shell = HomeShell.globalKey.currentState;
    if (shell == null) {
      // The shell is not built yet (cold start): retry after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openTask(id));
      return;
    }
    shell.openTask(TaskEditorPage(taskId: id));
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: s,
      child: ListenableBuilder(
        listenable: s.settings,
        builder: (context, _) => MaterialApp(
          title: 'Ergon',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: switch (s.settings.themeMode) {
            1 => ThemeMode.light,
            2 => ThemeMode.dark,
            _ => ThemeMode.system,
          },
          home: HomeShell(key: HomeShell.globalKey, dataPath: widget.dataPath),
        ),
      ),
    );
  }
}
