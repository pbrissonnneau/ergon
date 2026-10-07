import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:overdue/src/core/local_date.dart';
import 'package:overdue/src/data/database_opener.dart';
import 'package:overdue/src/data/settings_repository.dart';
import 'package:overdue/src/data/task_repository.dart';
import 'package:overdue/src/domain/models.dart';
import 'package:overdue/src/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory root, dataDir, backupDir;
  late FixedClock clock;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('overdue_backup_');
    dataDir = Directory(p.join(root.path, 'data'))..createSync();
    backupDir = Directory(p.join(root.path, 'backups'));
    clock = FixedClock(DateTime(2026, 10, 5, 9));
  });
  tearDown(() => root.delete(recursive: true));

  Future<(BackupService, TaskRepository, AppSettings)> open() async {
    final db = openAppDatabase(dataDir);
    final settings = await AppSettings.load(db);
    final service = BackupService(db: db, settings: settings, dataDir: dataDir, defaultFolder: backupDir, clock: clock);
    return (service, TaskRepository(db, clock: clock), settings);
  }

  Future<List<String>> titlesIn(File dbFile) async {
    final dir = await Directory.systemTemp.createTemp('overdue_check_');
    await dbFile.copy(p.join(dir.path, 'overdue.sqlite'));
    final db = openAppDatabase(dir);
    final titles = (await db.select(db.tasks).get()).map((t) => t.title).toList();
    await db.close();
    await dir.delete(recursive: true);
    return titles;
  }

  test('daily backup is a complete, openable copy and runs once per day', () async {
    final (service, tasks, _) = await open();
    await tasks.createTask(TaskDraft(title: 'Pay rent'));
    await tasks.createTask(TaskDraft(title: 'Learn Spanish'));

    final f = await service.runIfDue();
    expect(p.basename(f!.path), 'overdue-2026-10-05.sqlite');
    expect(await titlesIn(f), ['Pay rent', 'Learn Spanish']);
    expect(await service.runIfDue(), isNull, reason: 'already done today');

    clock.current = DateTime(2026, 10, 6, 9);
    expect(p.basename((await service.runIfDue())!.path), 'overdue-2026-10-06.sqlite');
    await service.db.close();
  });

  test('disabled backups do nothing', () async {
    final (service, _, settings) = await open();
    settings.backupEnabled = false;
    expect(await service.runIfDue(), isNull);
    expect(await service.list(), isEmpty);
    await service.db.close();
  });

  test('keeps only the newest N daily backups; manual ones are never pruned', () async {
    final (service, _, settings) = await open();
    settings.backupKeep = 3;
    final manual = await service.backupNow();
    for (var d = 1; d <= 6; d++) {
      clock.current = LocalDate(2026, 10, d).atMinute(600);
      await service.runIfDue();
    }
    final names = (await service.list()).map((b) => b.name).toList();
    expect(
      names.where((n) => !n.contains('manual')),
      unorderedEquals(['overdue-2026-10-04.sqlite', 'overdue-2026-10-05.sqlite', 'overdue-2026-10-06.sqlite']),
    );
    expect(names, contains(p.basename(manual.path)));
    await service.db.close();
  });

  test('restore swaps the database at next start and keeps a safety copy', () async {
    var (service, tasks, _) = await open();
    await tasks.createTask(TaskDraft(title: 'Before backup'));
    final backup = await service.backupNow();
    await tasks.createTask(TaskDraft(title: 'Added after backup'));
    await service.scheduleRestore(backup);
    await service.db.close();

    final message = await BackupService.applyPendingRestore(dataDir);
    expect(message, startsWith('Backup restored'));
    expect(await BackupService.applyPendingRestore(dataDir), isNull, reason: 'marker consumed');

    (service, tasks, _) = await open();
    expect((await service.db.select(service.db.tasks).get()).map((t) => t.title), ['Before backup']);
    final safety = (await service.list()).firstWhere((b) => b.name.startsWith('overdue-before-restore-'));
    expect(await titlesIn(safety.file), containsAll(['Before backup', 'Added after backup']));
    await service.db.close();
  });
}
