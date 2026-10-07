import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'autostart.dart';

/// One-time pick-up of the data left by the app under its former name, Ergon.
///
/// The data folder follows the application id (Linux, `app.ergon.ergon`) or
/// the company/product names (Windows, `%APPDATA%\Ergon\Ergon`), so the rename
/// moved it. At the first start without a database, the old folder is copied
/// (never moved: it stays as a fallback), the default backup / activity
/// folders are renamed and the overlay's start-at-login entry is re-created.
abstract final class LegacyDataMigration {
  static const _legacyDb = 'ergon.sqlite';
  static const _db = 'overdue.sqlite';

  static Directory? legacyDataDir(Directory dataDir) {
    if (Platform.isLinux) return Directory(p.join(p.dirname(dataDir.path), 'app.ergon.ergon'));
    if (Platform.isWindows) return Directory(p.join(p.dirname(p.dirname(dataDir.path)), 'Ergon', 'Ergon'));
    return null;
  }

  /// Returns true when the old data was copied. Never throws: start-up goes on
  /// with an empty database if anything fails.
  static Future<bool> run(Directory dataDir) async {
    try {
      final old = legacyDataDir(dataDir);
      if (old == null) return false;
      final oldDb = File(p.join(old.path, _legacyDb));
      final db = File(p.join(dataDir.path, _db));
      if (await db.exists() || !await oldDb.exists()) return false;

      await for (final e in old.list()) {
        final name = p.basename(e.path);
        // The database itself goes last; IPC files and the SQLite shared
        // memory index belong to running processes.
        if (e is! File || name == _legacyDb || name == 'ipc' || name.endsWith('-shm')) continue;
        final target = name.startsWith(_legacyDb) ? '$_db${name.substring(_legacyDb.length)}' : name;
        await e.copy(p.join(dataDir.path, target));
      }
      // Written under a temporary name so an interrupted copy is retried.
      final tmp = await oldDb.copy('${db.path}.tmp');
      await tmp.rename(db.path);

      await _renameDocumentsFolder('Ergon backups', 'Overdue backups');
      await _renameDocumentsFolder('Ergon activity', 'Overdue activity');
      await DesktopAutostart.migrateLegacyEntry();
      return true;
    } catch (e) {
      stderr.writeln('Could not import Ergon data: $e');
      return false;
    }
  }

  static Future<void> _renameDocumentsFolder(String from, String to) async {
    try {
      final docs = (await getApplicationDocumentsDirectory()).path;
      final source = Directory(p.join(docs, from));
      final target = Directory(p.join(docs, to));
      if (await source.exists() && !await target.exists()) await source.rename(target.path);
    } catch (_) {}
  }
}
