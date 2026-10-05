import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/local_date.dart';
import '../data/database.dart';
import '../data/settings_repository.dart';

/// A backup file found in the backup folder.
class BackupFile {
  const BackupFile(this.file, this.modified, this.sizeBytes);
  final File file;
  final DateTime modified;
  final int sizeBytes;
  String get name => p.basename(file.path);
}

/// Local, automatic backups of the database (no network, no cloud).
///
/// * Once per day (at start-up and at day change) a consistent snapshot is
///   written with SQLite's `VACUUM INTO` (safe while the app is running).
/// * Only the newest [AppSettings.backupKeep] daily files are kept.
/// * Restoring is two-phase: the chosen file is recorded in a marker and the
///   swap happens at the next start, before the database is opened (a live
///   database file cannot be replaced safely, and on Windows not at all).
class BackupService {
  BackupService({
    required this.db,
    required this.settings,
    required this.dataDir,
    required this.defaultFolder,
    Clock clock = const SystemClock(),
  }) : _clock = clock;

  final AppDatabase db;
  final AppSettings settings;
  final Directory dataDir;

  /// Used when the user has not chosen a folder (set by the platform at start-up).
  Directory defaultFolder;
  final Clock _clock;

  static const _prefix = 'ergon-';
  static const _ext = '.sqlite';
  static final _dailyName = RegExp(r'^ergon-\d{4}-\d{2}-\d{2}\.sqlite$');

  Directory get folder {
    final custom = settings.backupFolder;
    return custom == null || custom.isEmpty ? defaultFolder : Directory(custom);
  }

  /// Runs the daily backup if enabled and not yet done today.
  /// Returns the written file, or null when nothing was needed.
  Future<File?> runIfDue() async {
    if (!settings.backupEnabled) return null;
    final today = _clock.today().toString();
    if (settings.lastBackupDay == today) return null;
    final f = await backupNow(daily: true);
    settings.lastBackupDay = today;
    await prune();
    return f;
  }

  /// Writes a snapshot now. Daily backups are named by date (one per day);
  /// manual ones also carry the time.
  Future<File> backupNow({bool daily = false}) async {
    final dir = folder;
    await dir.create(recursive: true);
    final now = _clock.now();
    final day = LocalDate.fromDateTime(now).toString();
    final time =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final file = File(p.join(dir.path, daily ? '$_prefix$day$_ext' : '$_prefix$day-$time-manual$_ext'));
    if (await file.exists()) await file.delete(); // VACUUM INTO refuses to overwrite.
    final tmp = File('${file.path}.tmp');
    if (await tmp.exists()) await tmp.delete();
    await db.customStatement('VACUUM INTO ?', [tmp.path]);
    await tmp.rename(file.path); // Never leave a half-written backup behind.
    return file;
  }

  /// Backups in the folder, newest first.
  Future<List<BackupFile>> list() async {
    final dir = folder;
    if (!await dir.exists()) return const [];
    final out = <BackupFile>[];
    await for (final e in dir.list()) {
      final name = p.basename(e.path);
      if (e is File && name.startsWith(_prefix) && name.endsWith(_ext)) {
        final st = await e.stat();
        out.add(BackupFile(e, st.modified, st.size));
      }
    }
    out.sort((a, b) => b.modified.compareTo(a.modified));
    return out;
  }

  /// Deletes the oldest *daily* backups beyond the configured count. Manual
  /// and pre-restore backups are never deleted automatically.
  Future<void> prune() async {
    final daily = (await list()).where((b) => _dailyName.hasMatch(b.name)).toList()
      ..sort((a, b) => b.name.compareTo(a.name)); // Names sort by date.
    for (final old in daily.skip(settings.backupKeep)) {
      try {
        await old.file.delete();
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // Restore
  // ---------------------------------------------------------------------------

  static File _marker(Directory dataDir) => File(p.join(dataDir.path, 'restore.pending'));

  /// Schedules [backup] to replace the database at the next start.
  Future<void> scheduleRestore(File backup) => _marker(dataDir).writeAsString(backup.path, flush: true);

  /// Called at start-up *before* opening the database. If a restore is
  /// pending, the current database is first saved next to the backups
  /// (`ergon-before-restore-….sqlite`), then replaced. Returns a message for
  /// the user, or null when nothing happened.
  static Future<String?> applyPendingRestore(Directory dataDir) async {
    final marker = _marker(dataDir);
    if (!await marker.exists()) return null;
    final source = File((await marker.readAsString()).trim());
    final live = File(p.join(dataDir.path, 'ergon.sqlite'));
    // The overlay may take a moment to close and release the file.
    for (var attempt = 0; ; attempt++) {
      final result = await _swap(marker, source, live);
      if (result.$1 || attempt >= 15) return result.$2;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Returns (finished, message).
  static Future<(bool, String?)> _swap(File marker, File source, File live) async {
    try {
      if (!await source.exists()) {
        await marker.delete();
        return (true, 'Restore cancelled: the backup file no longer exists.');
      }
      if (await live.exists()) {
        // Safety copy of the current data (with its WAL, which may hold the
        // latest committed changes), once per minute at most across retries.
        final stamp = DateTime.now().toIso8601String().replaceAll(':', '').substring(0, 13);
        final safety = File(p.join(source.parent.path, 'ergon-before-restore-$stamp.sqlite'));
        if (!await safety.exists()) {
          await live.copy(safety.path);
          final wal = File('${live.path}-wal');
          if (await wal.exists()) await wal.copy('${safety.path}-wal');
        }
      }
      for (final suffix in ['-wal', '-shm']) {
        final f = File('${live.path}$suffix');
        if (await f.exists()) await f.delete();
      }
      await source.copy(live.path);
      final sourceWal = File('${source.path}-wal');
      if (await sourceWal.exists()) await sourceWal.copy('${live.path}-wal');
      await marker.delete();
      return (true, 'Backup restored: ${p.basename(source.path)}');
    } on FileSystemException catch (e) {
      // Typically another Ergon process (the overlay) still has the file open.
      return (
        false,
        'Could not restore yet (${e.osError?.message ?? e.message}). '
            'Close all Ergon windows, including the overlay, and start Ergon again.',
      );
    }
  }
}
