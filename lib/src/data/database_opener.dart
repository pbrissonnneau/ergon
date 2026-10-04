import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'database.dart';

/// Opens the on-disk database on a background isolate.
///
/// WAL mode + a busy timeout let the desktop overlay process (and Android's
/// notification-action isolate) read/write the same file safely.
AppDatabase openAppDatabase(Directory dataDir) {
  final file = File(p.join(dataDir.path, 'ergon.sqlite'));
  return AppDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode = WAL');
        db.execute('PRAGMA busy_timeout = 5000');
        db.execute('PRAGMA synchronous = NORMAL');
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

/// In-memory database for tests.
AppDatabase openMemoryDatabase() =>
    AppDatabase(NativeDatabase.memory(setup: (db) => db.execute('PRAGMA foreign_keys = ON')));

extension DataVersion on AppDatabase {
  /// SQLite's `data_version`: changes whenever *another* connection commits.
  /// Cheap way for the overlay process to notice edits made by the main app.
  Future<int> dataVersion() async => (await customSelect('PRAGMA data_version').getSingle()).read<int>('data_version');
}
