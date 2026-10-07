import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../domain/agenda.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../platform/desktop/desktop_integration.dart';
import '../../platform/desktop/instance_ipc.dart';
import '../../platform/desktop/native_window.dart';
import '../agenda/agenda_view.dart';
import '../agenda/week_strip.dart';
import '../bulk_actions.dart';
import '../formatting.dart';
import '../theme.dart';
import '../widgets/task_drag.dart';

/// Entry point of the compact desktop overlay process (`overdue --overlay`).
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
    title: 'Overdue overlay',
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
    unawaited(services.startBackground(watchExternalChanges: true, runBackups: false));
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
      switch (cmd.name) {
        case IpcCommand.close:
          await windowManager.close();
        case IpcCommand.show:
          await windowManager.show();
          // Raise above everything even when "always on top" is off.
          if (!await windowManager.isAlwaysOnTop()) {
            await windowManager.setAlwaysOnTop(true);
            await windowManager.setAlwaysOnTop(false);
          }
          await windowManager.focus();
      }
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

  /// Ctrl+Alt+N while the overlay owns the shortcut: quick add in the main app.
  @override
  void onGlobalHotkey() => unawaited(quickAddInMain());

  Future<void> openInMain(int taskId) =>
      _toMain(IpcCommand(IpcCommand.openTask, {'taskId': taskId}), ['--open-task=$taskId']);
  Future<void> showMain() => _toMain(const IpcCommand(IpcCommand.show), const []);
  Future<void> quickAddInMain({LocalDate? due}) => _toMain(
    IpcCommand(IpcCommand.quickAdd, {if (due != null) 'due': due.epochDay}),
    ['--new-task', if (due != null) '--due=${due.epochDay}'],
  );

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
        title: 'Overdue overlay',
        // Overlay: no ink ripples (instant, quiet UI).
        theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
        darkTheme: AppTheme.dark().copyWith(splashFactory: NoSplash.splashFactory),
        themeMode: switch (s.settings.themeMode) {
          1 => ThemeMode.light,
          2 => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        // No hover tooltips in the overlay.
        builder: (context, child) => TooltipVisibility(visible: false, child: child!),
        home: DragToResizeArea(
          resizeEdgeSize: 6,
          child: Scaffold(
            body: Column(
              children: [
                _OverlayHeader(
                  onTop: _onTop,
                  onToggleTop: () => s.settings.overlayAlwaysOnTop = !_onTop,
                  onOpenMain: platform.showMain,
                  onAdd: () => platform.quickAddInMain(),
                  // Hides the overlay until Overdue starts again (turn it off for
                  // good in Settings).
                  onClose: windowManager.close,
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: WeekStrip(
                      compact: true,
                      square: 24,
                      onOpenTask: platform.openInMain,
                      onNewTask: (day) => platform.quickAddInMain(due: day),
                    ),
                  ),
                ),
                Expanded(
                  child: AgendaBuilderWidget(
                    upcomingDaysOverride: s.settings.overlayShowUpcoming ? s.settings.upcomingDays.clamp(1, 7) : 0,
                    builder: (context, agenda) => agenda == null
                        ? const SizedBox.shrink()
                        : _OverlayList(agenda: agenda, onOpen: platform.openInMain),
                  ),
                ),
                const Divider(height: 1),
                const _OverlayQuickAdd(),
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
          btn(Icons.open_in_new, 'Open Overdue', onOpenMain),
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
    void header(String t, int n, [Color? c, void Function(Offset at)? menu]) {
      final label = Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
        child: Row(
          children: [
            Text(
              '$t · $n',
              style: theme.textTheme.labelSmall?.copyWith(color: c ?? scheme.primary, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (menu != null)
              Builder(
                builder: (b) => InkWell(
                  onTap: () {
                    final box = b.findRenderObject()! as RenderBox;
                    menu(box.localToGlobal(box.size.bottomLeft(Offset.zero)));
                  },
                  child: Icon(Icons.more_horiz, size: 16, color: c),
                ),
              ),
          ],
        ),
      );
      rows.add(menu == null ? label : GestureDetector(onSecondaryTapUp: (d) => menu(d.globalPosition), child: label));
    }

    void entries(Iterable<AgendaEntry> es, {bool overdue = false}) {
      for (final e in es) {
        if (e.isPostponed) {
          rows.add(_postponedRow(context, e));
          continue;
        }
        rows.add(
          // Drag a line onto a day square to move it there.
          DraggableTask(
            data: TaskDragData(e.task, occurrenceDate: e.occurrence?.date),
            enabled: !e.isDone,
            child: InkWell(
              onTap: () => onOpen(e.task.id),
              onSecondaryTapUp: (d) => _taskMenu(context, e, d.globalPosition),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.projectColor(e.item.projectColor, scheme),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Done button: the circle turns into a green check (click again to undo).
                    InkResponse(
                      radius: 14,
                      onTap: () => _toggleDone(context, e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Icon(
                          e.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 18,
                          color: e.isDone
                              ? AppTheme.statusColor(TaskStatus.completed, scheme)
                              : AppTheme.priorityColor(e.task.priority, scheme),
                        ),
                      ),
                    ),
                    if (e.task.priority.code >= TaskPriority.high.code && !e.isDone)
                      Icon(
                        AppTheme.priorityIcon(e.task.priority),
                        size: 13,
                        color: AppTheme.priorityColor(e.task.priority, scheme),
                      ),
                    if (e.isOccurrence) ...[
                      Icon(Icons.repeat, size: 13, color: scheme.outline),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        e.task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: e.isDone ? scheme.outline : (overdue ? scheme.error : null),
                          decoration: e.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (e.minute != null)
                      Text(
                        MinuteOfDay.format(e.minute!),
                        style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline),
                      ),
                    if (e.status != TaskStatus.notStarted && !e.isDone)
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
          ),
        );
      }
    }

    final overdue = agenda.overdue;
    if (overdue != null) {
      header(
        'OVERDUE',
        overdue.openCount,
        scheme.error,
        (at) => _overdueMenu(context, overdue.entries.where((e) => e.isOpen).toList(), at),
      );
      entries(overdue.entries, overdue: true);
    }
    header('TODAY', agenda.todayCount);
    for (final s in agenda.todaySections) {
      entries(s.entries);
    }
    for (final s in agenda.upcoming) {
      header(
        s.date == agenda.today.addDays(1) ? 'TOMORROW' : Fmt.longDate(s.date!).toUpperCase(),
        s.openCount,
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

  /// Postponed task: struck through in red on the day it left.
  Widget _postponedRow(BuildContext context, AgendaEntry e) {
    final theme = Theme.of(context);
    final red = theme.colorScheme.error;
    final p = e.postponement!;
    final to = p.to;
    return InkWell(
      onTap: () => onOpen(e.task.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Icon(Icons.redo, size: 18, color: red),
            ),
            Expanded(
              child: Text(
                e.task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: red.withValues(alpha: 0.8),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: red,
                  decorationThickness: 2,
                ),
              ),
            ),
            Text(
              to == null ? 'backlog' : '→ ${Fmt.relativeDate(to, agenda.today)}',
              style: theme.textTheme.labelSmall?.copyWith(color: red),
            ),
          ],
        ),
      ),
    );
  }

  RelativeRect _at(BuildContext context, Offset p) {
    final size = MediaQuery.sizeOf(context);
    return RelativeRect.fromLTRB(p.dx, p.dy, size.width - p.dx, size.height - p.dy);
  }

  Future<void> _toggleDone(BuildContext context, AgendaEntry e) async {
    final s = AppScope.of(context);
    final next = e.isDone ? TaskStatus.notStarted : TaskStatus.completed;
    final occ = e.occurrence;
    occ != null
        ? await s.tasks.setOccurrenceStatus(e.task.id, occ.date, next)
        : await s.tasks.setStatus(e.task.id, next);
  }

  /// Right-click on a task: complete, reschedule, priority, open.
  Future<void> _taskMenu(BuildContext context, AgendaEntry e, Offset at) async {
    final s = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final choice = await showMenu<Object>(
      context: context,
      position: _at(context, at),
      items: [
        PopupMenuItem<Object>(
          value: 'toggle',
          child: Row(
            children: [
              Icon(e.isDone ? Icons.radio_button_unchecked : Icons.check_circle_outline, size: 18),
              const SizedBox(width: 10),
              Text(e.isDone ? 'Mark as not done' : 'Complete'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (e.isOccurrence)
          const PopupMenuItem<Object>(
            value: 'skip',
            child: Row(children: [Icon(Icons.skip_next, size: 18), SizedBox(width: 10), Text('Skip this occurrence')]),
          )
        else
          ...BulkActions.rescheduleItems(includePick: false, height: 34),
        const PopupMenuDivider(),
        ...BulkActions.priorityItems(scheme, height: 34),
        const PopupMenuDivider(),
        if (!e.isDone)
          const PopupMenuItem<Object>(
            value: 'followup',
            height: 34,
            child: Row(children: [Icon(Icons.redo, size: 18), SizedBox(width: 10), Text('Close + follow-up tomorrow')]),
          ),
      ],
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'followup':
        await s.tasks.followUp(e.task, occurrenceDate: e.occurrence?.date);
      case 'skip':
        await s.tasks.skipOccurrences(e.task.id, e.occurrence!.date);
      case 'toggle':
        final next = e.isDone ? TaskStatus.notStarted : TaskStatus.completed;
        final occ = e.occurrence;
        occ != null
            ? await s.tasks.setOccurrenceStatus(e.task.id, occ.date, next)
            : await s.tasks.setStatus(e.task.id, next);
      default:
        await BulkActions.applyMenuChoice(context, s, choice, [e]);
    }
  }

  /// Right-click (or ⋯) on OVERDUE: move every overdue task at once.
  Future<void> _overdueMenu(BuildContext context, List<AgendaEntry> overdue, Offset at) async {
    final s = AppScope.of(context);
    final choice = await showMenu<Object>(
      context: context,
      position: _at(context, at),
      items: [
        const PopupMenuItem<Object>(enabled: false, height: 28, child: Text('Move all overdue to…')),
        ...BulkActions.rescheduleItems(includePick: false, height: 34),
      ],
    );
    if (choice != null && context.mounted) await BulkActions.applyMenuChoice(context, s, choice, overdue);
  }
}

/// Discreet one-line task entry at the bottom of the overlay: type a title,
/// press Enter, the task is created for today. Esc clears the field.
class _OverlayQuickAdd extends StatefulWidget {
  const _OverlayQuickAdd();
  @override
  State<_OverlayQuickAdd> createState() => _OverlayQuickAddState();
}

class _OverlayQuickAddState extends State<_OverlayQuickAdd> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _ctrl.text.trim();
    if (title.isEmpty || _busy) return;
    _busy = true;
    final s = AppScope.of(context);
    try {
      await s.tasks.createTask(TaskDraft(title: title, dueDate: s.clock.today()));
      _ctrl.clear();
    } finally {
      _busy = false;
    }
    if (mounted) _focus.requestFocus(); // Ready for the next one.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.bodySmall;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _ctrl.clear();
          _focus.unfocus();
        },
      },
      child: SizedBox(
        height: 30,
        child: TextField(
          controller: _ctrl,
          focusNode: _focus,
          style: style,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: 'Add a task for today…',
            hintStyle: style?.copyWith(color: scheme.outline),
            prefixIcon: Icon(Icons.add, size: 14, color: scheme.outline),
            prefixIconConstraints: const BoxConstraints.tightFor(width: 30, height: 30),
            contentPadding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
          ),
        ),
      ),
    );
  }
}
