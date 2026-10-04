import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/agenda.dart';
import '../../domain/enums.dart';
import '../../platform/desktop/desktop_integration.dart';
import '../../platform/desktop/instance_ipc.dart';
import '../../platform/desktop/native_window.dart';
import '../agenda/agenda_view.dart';
import '../formatting.dart';
import '../theme.dart';

/// Entry point of the compact desktop overlay process (`ergon --overlay`).
///
/// It is the same executable as the main app, running a different UI: a
/// small frameless, movable, resizable, optionally always-on-top window that
/// summarises the agenda. Clicking an item opens it in the main application.
Future<void> runOverlay(Directory dataDir) async {
  final channel = InstanceChannel(dataDir, 'overlay');
  if (!await channel.tryAcquire()) exit(0); // Already showing.

  final platform = OverlayIntegration(dataDir: dataDir, overlayChannel: channel);
  final services = await AppServices.open(dataDir, platform);
  final bounds = await OverlayBounds.load(dataDir);

  await windowManager.ensureInitialized();
  final options = WindowOptions(
    title: 'Ergon overlay',
    size: bounds?.size ?? const Size(320, 420),
    minimumSize: const Size(220, 140),
    skipTaskbar: true,
    alwaysOnTop: services.settings.overlayAlwaysOnTop,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setAsFrameless();
    if (bounds != null) await windowManager.setPosition(bounds.topLeft);
    await windowManager.setOpacity(services.settings.overlayOpacityPercent / 100);
    await windowManager.show();
  });

  runApp(OverlayApp(services: services, dataDir: dataDir));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(services.startBackground(watchExternalChanges: true));
  });
}

/// Persisted overlay geometry (per-user file next to the database).
class OverlayBounds {
  static File _file(Directory dir) => File(p.join(dir.path, 'overlay_window.json'));

  static Future<Rect?> load(Directory dir) async {
    try {
      final j = jsonDecode(await _file(dir).readAsString()) as Map<String, Object?>;
      return Rect.fromLTWH(
        (j['x']! as num).toDouble(),
        (j['y']! as num).toDouble(),
        (j['w']! as num).toDouble(),
        (j['h']! as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(Directory dir, Rect r) =>
      _file(dir).writeAsString(jsonEncode({'x': r.left, 'y': r.top, 'w': r.width, 'h': r.height}));
}

/// Desktop integration for the overlay process: "open" requests are
/// forwarded to the main window (launching it if needed).
class OverlayIntegration extends DesktopIntegration {
  OverlayIntegration({required super.dataDir, required this.overlayChannel})
    : super(osSchedulesNotifications: Platform.isWindows);

  final InstanceChannel overlayChannel;
  StreamSubscription<IpcCommand>? _cmds;

  @override
  bool get supportsOverlay => false;

  @override
  Future<void> start() async {
    _cmds = overlayChannel.commands.listen((cmd) async {
      if (cmd.name == IpcCommand.close) await windowManager.close();
    });
    await overlayChannel.listen();
  }

  Future<void> _toMain(IpcCommand cmd, List<String> args) async {
    NativeWindowHelpers.allowForegroundForOtherProcesses();
    if (await InstanceChannel.isRunning(dataDir, 'main')) {
      await InstanceChannel.send(dataDir, 'main', cmd);
    } else {
      await Process.start(Platform.resolvedExecutable, args, mode: ProcessStartMode.detached);
    }
  }

  Future<void> openInMain(int taskId) =>
      _toMain(IpcCommand(IpcCommand.openTask, {'taskId': taskId}), ['--open-task=$taskId']);
  Future<void> showMain() => _toMain(const IpcCommand(IpcCommand.show), const []);
  Future<void> quickAddInMain() => _toMain(const IpcCommand(IpcCommand.quickAdd), const ['--new-task']);

  @override
  Future<void> dispose() async {
    await _cmds?.cancel();
    await overlayChannel.dispose();
    await super.dispose();
  }
}

class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key, required this.services, required this.dataDir});
  final AppServices services;
  final Directory dataDir;

  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> with WindowListener {
  Timer? _saveBounds;
  late bool _onTop = s.settings.overlayAlwaysOnTop;
  late int _opacity = s.settings.overlayOpacityPercent;
  StreamSubscription<int>? _open;

  AppServices get s => widget.services;
  OverlayIntegration get platform => s.platform as OverlayIntegration;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    s.settings.addListener(_applySettings);
    // Notification "Open" clicks handled by this process go to the main app.
    _open = s.openTaskRequests.listen(platform.openInMain);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    s.settings.removeListener(_applySettings);
    _open?.cancel();
    super.dispose();
  }

  /// Settings are shared through the database (changed in the main window).
  Future<void> _applySettings() async {
    final st = s.settings;
    if (!st.overlayEnabled && _closeOnDisable) {
      await windowManager.close();
      return;
    }
    if (st.overlayAlwaysOnTop != _onTop) {
      _onTop = st.overlayAlwaysOnTop;
      await windowManager.setAlwaysOnTop(_onTop);
    }
    if (st.overlayOpacityPercent != _opacity) {
      _opacity = st.overlayOpacityPercent;
      await windowManager.setOpacity(_opacity / 100);
    }
    if (mounted) setState(() {});
  }

  /// Only close on "disabled" if it was enabled when we started (an overlay
  /// launched at login stays even if the in-app toggle is off).
  late final bool _closeOnDisable = s.settings.overlayEnabled;

  void _persistBounds() {
    _saveBounds?.cancel();
    _saveBounds = Timer(const Duration(milliseconds: 400), () async {
      await OverlayBounds.save(widget.dataDir, await windowManager.getBounds());
    });
  }

  @override
  void onWindowMoved() => _persistBounds();
  @override
  void onWindowResized() => _persistBounds();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: s,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ergon overlay',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: switch (s.settings.themeMode) {
          1 => ThemeMode.light,
          2 => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        home: DragToResizeArea(
          resizeEdgeSize: 6,
          child: Scaffold(
            body: Column(
              children: [
                _OverlayHeader(
                  onTop: _onTop,
                  onToggleTop: () => s.settings.overlayAlwaysOnTop = !_onTop,
                  onOpenMain: platform.showMain,
                  onAdd: platform.quickAddInMain,
                  onClose: () async {
                    if (_closeOnDisable) s.settings.overlayEnabled = false;
                    await Future<void>.delayed(const Duration(milliseconds: 50));
                    await windowManager.close();
                  },
                ),
                const Divider(height: 1),
                Expanded(
                  child: AgendaBuilderWidget(
                    upcomingDaysOverride: s.settings.overlayShowUpcoming ? s.settings.upcomingDays.clamp(1, 7) : 0,
                    builder: (context, agenda) => agenda == null
                        ? const SizedBox.shrink()
                        : _OverlayList(agenda: agenda, onOpen: platform.openInMain),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayHeader extends StatelessWidget {
  const _OverlayHeader({
    required this.onTop,
    required this.onToggleTop,
    required this.onOpenMain,
    required this.onAdd,
    required this.onClose,
  });
  final bool onTop;
  final VoidCallback onToggleTop;
  final VoidCallback onOpenMain;
  final VoidCallback onAdd;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final theme = Theme.of(context);
    Widget btn(IconData i, String tip, VoidCallback f, {bool active = false}) => IconButton(
      icon: Icon(i, size: 16, color: active ? theme.colorScheme.primary : null),
      tooltip: tip,
      onPressed: f,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
    );
    return Container(
      color: theme.colorScheme.surfaceContainer,
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  children: [
                    Icon(Icons.today, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    ValueListenableBuilder(
                      valueListenable: s.today,
                      builder: (context, LocalDate today, _) => Text(
                        'Today · ${Fmt.weekdayShort(today)}, ${Fmt.date(today, today)}',
                        style: theme.textTheme.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          btn(Icons.add, 'New task', onAdd),
          btn(
            onTop ? Icons.push_pin : Icons.push_pin_outlined,
            onTop ? 'Unpin from top' : 'Keep on top',
            onToggleTop,
            active: onTop,
          ),
          btn(Icons.open_in_new, 'Open Ergon', onOpenMain),
          btn(Icons.close, 'Close overlay', onClose),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _OverlayList extends StatelessWidget {
  const _OverlayList({required this.agenda, required this.onOpen});
  final Agenda agenda;
  final void Function(int taskId) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rows = <Widget>[];
    void header(String t, int n, [Color? c]) => rows.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
        child: Text(
          '$t · $n',
          style: theme.textTheme.labelSmall?.copyWith(color: c ?? scheme.primary, fontWeight: FontWeight.w700),
        ),
      ),
    );
    void entries(Iterable<AgendaEntry> es, {bool overdue = false}) {
      for (final e in es) {
        rows.add(
          InkWell(
            onTap: () => onOpen(e.task.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.priorityColor(e.task.priority, scheme),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (e.isOccurrence) ...[
                    Icon(Icons.repeat, size: 13, color: scheme.outline),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      e.task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: overdue ? scheme.error : null),
                    ),
                  ),
                  if (e.minute != null)
                    Text(
                      MinuteOfDay.format(e.minute!),
                      style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline),
                    ),
                  if (e.status != TaskStatus.notStarted)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        AppTheme.statusIcon(e.status),
                        size: 13,
                        color: AppTheme.statusColor(e.status, scheme),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    final overdue = agenda.overdue;
    if (overdue != null) {
      header('OVERDUE', overdue.entries.length, scheme.error);
      entries(overdue.entries, overdue: true);
    }
    header('TODAY', agenda.todayCount);
    for (final s in agenda.todaySections) {
      entries(s.entries);
    }
    for (final s in agenda.upcoming) {
      header(
        s.date == agenda.today.addDays(1) ? 'TOMORROW' : Fmt.longDate(s.date!).toUpperCase(),
        s.entries.length,
        scheme.outline,
      );
      entries(s.entries);
    }
    if (agenda.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('All clear for today', style: TextStyle(color: scheme.outline)),
        ),
      );
    }
    return ListView(padding: const EdgeInsets.only(bottom: 8), children: rows);
  }
}
