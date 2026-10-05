import 'dart:async';

import 'package:flutter/foundation.dart';

import 'database.dart';

/// Typed, persisted application preferences backed by the `settings` table.
///
/// Values are loaded once at startup and cached; writes are asynchronous.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._db, this._values);

  static Future<AppSettings> load(AppDatabase db) async {
    final rows = await db.select(db.settings).get();
    return AppSettings._(db, {for (final r in rows) r.key: r.value});
  }

  final AppDatabase _db;
  final Map<String, String> _values;

  /// Re-reads values (e.g. written by another process such as the overlay).
  Future<void> reload() async {
    final rows = await _db.select(_db.settings).get();
    _values
      ..clear()
      ..addAll({for (final r in rows) r.key: r.value});
    notifyListeners();
  }

  int _int(String k, int def) => int.tryParse(_values[k] ?? '') ?? def;
  bool _bool(String k, bool def) => _values[k] == null ? def : _values[k] == '1';

  Future<void> _set(String k, String v) async {
    if (_values[k] == v) return;
    _values[k] = v;
    notifyListeners();
    await _db.into(_db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: k, value: v));
  }

  /// Number of days after today shown in the agenda's "Upcoming" section
  /// (0 = today only, 1 = tomorrow, ...).
  int get upcomingDays => _int('agenda.upcomingDays', 1);
  set upcomingDays(int v) => unawaited(_set('agenda.upcomingDays', '$v'));

  /// Default time used for date-only due dates in relative reminders.
  int get defaultReminderMinute => _int('reminders.defaultMinute', 9 * 60);
  set defaultReminderMinute(int v) => unawaited(_set('reminders.defaultMinute', '$v'));

  int get snoozeMinutes => _int('reminders.snoozeMinutes', 10);
  set snoozeMinutes(int v) => unawaited(_set('reminders.snoozeMinutes', '$v'));

  bool get notificationsEnabled => _bool('reminders.enabled', true);
  set notificationsEnabled(bool v) => unawaited(_set('reminders.enabled', v ? '1' : '0'));

  /// 0 = system, 1 = light, 2 = dark.
  int get themeMode => _int('ui.themeMode', 0);
  set themeMode(int v) => unawaited(_set('ui.themeMode', '$v'));

  /// Desktop overlay: launched together with the main application.
  bool get overlayEnabled => _bool('overlay.enabled', false);
  set overlayEnabled(bool v) => unawaited(_set('overlay.enabled', v ? '1' : '0'));

  bool get overlayAlwaysOnTop => _bool('overlay.alwaysOnTop', true);
  set overlayAlwaysOnTop(bool v) => unawaited(_set('overlay.alwaysOnTop', v ? '1' : '0'));

  /// Overlay content: include upcoming days or only overdue + today.
  bool get overlayShowUpcoming => _bool('overlay.showUpcoming', false);
  set overlayShowUpcoming(bool v) => unawaited(_set('overlay.showUpcoming', v ? '1' : '0'));

  int get overlayOpacityPercent => _int('overlay.opacity', 96);
  set overlayOpacityPercent(int v) => unawaited(_set('overlay.opacity', '$v'));

  /// Daily automatic backup of the database (on by default).
  bool get backupEnabled => _bool('backup.enabled', true);
  set backupEnabled(bool v) => unawaited(_set('backup.enabled', v ? '1' : '0'));

  /// Backup folder chosen by the user (null = platform default).
  String? get backupFolder => _values['backup.folder'];
  set backupFolder(String? v) => unawaited(_set('backup.folder', v ?? ''));

  /// Number of daily backups kept.
  int get backupKeep => _int('backup.keep', 30);
  set backupKeep(int v) => unawaited(_set('backup.keep', '$v'));

  /// Civil date (YYYY-MM-DD) of the last automatic backup.
  String? get lastBackupDay => _values['backup.lastDay'];
  set lastBackupDay(String? v) => unawaited(_set('backup.lastDay', v ?? ''));

  /// Desktop: system-wide Ctrl+Alt+N opens the new-task dialog.
  bool get globalHotkeyEnabled => _bool('hotkey.enabled', true);
  set globalHotkeyEnabled(bool v) => unawaited(_set('hotkey.enabled', v ? '1' : '0'));

  String? raw(String key) => _values[key];
  Future<void> setRaw(String key, String value) => _set(key, value);
}
