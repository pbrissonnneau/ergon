import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../core/local_date.dart';
import '../data/agenda_service.dart';
import '../data/database.dart';
import '../data/database_opener.dart';
import '../data/project_repository.dart';
import '../data/settings_repository.dart';
import '../data/task_repository.dart';
import '../platform/platform_integration.dart';
import '../services/reminder_host.dart';

/// Composition root: owns every long-lived service of a process.
class AppServices {
  AppServices._({required this.db, required this.settings, required this.platform, required this.clock})
    : tasks = TaskRepository(db, clock: clock),
      projects = ProjectRepository(db, clock: clock) {
    agenda = AgendaService(tasks);
    tasks.lookaheadDays = settings.upcomingDays > 14 ? settings.upcomingDays : 14;
    reminders = ReminderHost(
      db: db,
      tasks: tasks,
      settings: settings,
      platform: platform,
      clock: clock,
      onOpenTask: (id) => _openRequests.add(id),
    );
  }

  static Future<AppServices> create({
    required AppDatabase db,
    required PlatformIntegration platform,
    Clock clock = const SystemClock(),
  }) async {
    final settings = await AppSettings.load(db);
    return AppServices._(db: db, settings: settings, platform: platform, clock: clock);
  }

  static Future<AppServices> open(Directory dataDir, PlatformIntegration platform) =>
      create(db: openAppDatabase(dataDir), platform: platform);

  final AppDatabase db;
  final AppSettings settings;
  final PlatformIntegration platform;
  final Clock clock;
  final TaskRepository tasks;
  final ProjectRepository projects;
  late final AgendaService agenda;
  late final ReminderHost reminders;

  final _openRequests = StreamController<int>.broadcast();

  /// The current civil day; ticks at local midnight and on resume so every
  /// screen rolls over without polling.
  late final ValueNotifier<LocalDate> today = ValueNotifier(clock.today());
  Timer? _midnight;
  Timer? _externalPoll;
  int? _dataVersion;

  /// Requests to open a task coming from notifications, widget, overlay.
  Stream<int> get openTaskRequests => _openRequests.stream;

  /// Re-evaluates [today] (call on app resume too) and re-arms the midnight timer.
  void refreshDay() {
    final now = clock.now();
    final d = LocalDate.fromDateTime(now);
    if (d != today.value) {
      today.value = d;
      unawaited(tasks.materializeAll());
    }
    _midnight?.cancel();
    final next = d.addDays(1).atMinute(0).add(const Duration(seconds: 1));
    _midnight = Timer(next.difference(now), refreshDay);
  }

  /// Background start-up work, run after the first frame so it never delays
  /// the initial paint.
  Future<void> startBackground({bool watchExternalChanges = false}) async {
    refreshDay();
    platform.openTaskRequests.listen(_openRequests.add);
    await platform.start();
    final initial = await platform.initialTaskToOpen();
    if (initial != null) _openRequests.add(initial);
    unawaited(tasks.materializeAll());
    unawaited(reminders.start());
    if (watchExternalChanges) startExternalChangeWatcher();
  }

  /// Another process (overlay <-> main window) may write the same database.
  /// Poll SQLite's cheap `data_version` and refresh live queries on change.
  void startExternalChangeWatcher({Duration every = const Duration(milliseconds: 1500)}) {
    _externalPoll?.cancel();
    _externalPoll = Timer.periodic(every, (_) async {
      try {
        final v = await db.dataVersion();
        if (_dataVersion != null && v != _dataVersion) {
          db.markTablesUpdated(db.allTables);
          await settings.reload();
        }
        _dataVersion = v;
      } catch (_) {}
    });
  }

  Future<void> dispose() async {
    _externalPoll?.cancel();
    _midnight?.cancel();
    await reminders.dispose();
    await platform.dispose();
    await db.close();
  }
}

/// Makes [AppServices] available to the widget tree.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final AppServices services;

  static AppServices of(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
