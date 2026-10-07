import 'package:drift/drift.dart';
import 'package:overdue/src/core/local_date.dart';
import 'package:overdue/src/data/database.dart';
import 'package:overdue/src/data/database_opener.dart';
import 'package:overdue/src/data/project_repository.dart';
import 'package:overdue/src/data/settings_repository.dart';
import 'package:overdue/src/data/task_repository.dart';

/// In-memory database + repositories driven by a controllable clock.
class TestEnv {
  TestEnv({DateTime? now}) : clock = FixedClock(now ?? DateTime(2026, 10, 4, 10, 0)) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = openMemoryDatabase();
    tasks = TaskRepository(db, clock: clock);
    projects = ProjectRepository(db, clock: clock);
  }

  final FixedClock clock;
  late final AppDatabase db;
  late final TaskRepository tasks;
  late final ProjectRepository projects;

  LocalDate get today => clock.today();

  Future<void> dispose() => db.close();
}

/// Helpers for settings rows in tests.
abstract final class SettingsCompanionHelper {
  static SettingsCompanion disabled() => SettingsCompanion.insert(key: 'reminders.enabled', value: '0');
}

Future<AppSettings> loadSettings(TestEnv env) => AppSettings.load(env.db);
