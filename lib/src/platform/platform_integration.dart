import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/agenda.dart';
import '../services/notifications/local_notifications_gateway.dart';
import '../services/notifications/notification_gateway.dart';
import 'android/android_integration.dart';
import 'desktop/desktop_integration.dart';

/// Everything platform-specific, behind one interface. This is the only place
/// (together with `main.dart` argument handling) that branches on the OS.
abstract class PlatformIntegration {
  /// Selects the implementation for the running OS.
  static PlatformIntegration forCurrentPlatform({required Directory dataDir}) {
    if (Platform.isAndroid) return AndroidIntegration();
    if (Platform.isWindows) return DesktopIntegration(dataDir: dataDir, osSchedulesNotifications: true);
    if (Platform.isLinux || Platform.isMacOS) {
      return DesktopIntegration(dataDir: dataDir, osSchedulesNotifications: false);
    }
    return HeadlessIntegration();
  }

  bool get isDesktop;
  bool get supportsOverlay;
  bool get supportsHomeWidget;

  NotificationGateway createNotificationGateway();

  /// Only one process may own reminder delivery at a time (desktop runs a
  /// main window and an overlay process). Returns whether this one does.
  Future<bool> tryAcquireReminderHost() async => true;

  /// Starts platform channels / IPC. Called once after the first frame.
  Future<void> start();

  /// Task ids the user asked to open from outside (widget, overlay, CLI...).
  Stream<int> get openTaskRequests;

  /// "New task" requests from outside (e.g. overlay's + button).
  Stream<void> get quickAddRequests;

  /// Task to open on cold start, if the app was launched for one.
  Future<int?> initialTaskToOpen();

  /// Pushes a compact agenda summary to the home-screen widget.
  Future<void> publishAgenda(Agenda agenda) async {}

  /// Shows / hides the desktop overlay (no-op where unsupported).
  Future<void> setOverlayVisible(bool visible) async {}

  /// Default folder for automatic backups (user-visible where possible).
  Future<Directory> defaultBackupFolder(Directory dataDir) async => Directory(p.join(dataDir.path, 'backups'));

  /// Restarts the application (used to finish restoring a backup).
  Future<void> restartApp() async => exit(0);

  /// Whether a system-wide "new task" shortcut can be registered.
  bool get supportsGlobalHotkey => false;
  Future<void> setGlobalHotkeyEnabled(bool enabled) async {}

  /// Login autostart of the overlay; null when unsupported.
  Future<bool?> overlayAutostartEnabled() async => null;
  Future<void> setOverlayAutostart(bool enabled) async {}

  /// Brings the main window to the foreground.
  Future<void> bringToFront() async {}

  Future<void> dispose() async {}
}

/// Used in tests and on platforms without native integration.
class HeadlessIntegration extends PlatformIntegration {
  HeadlessIntegration({NotificationGateway? gateway}) : _gateway = gateway;
  final NotificationGateway? _gateway;
  final _open = StreamController<int>.broadcast();
  final _add = StreamController<void>.broadcast();

  @override
  bool get isDesktop => false;
  @override
  bool get supportsOverlay => false;
  @override
  bool get supportsHomeWidget => false;
  @override
  NotificationGateway createNotificationGateway() => _gateway ?? NoopNotificationGateway();
  @override
  Future<void> start() async {}
  @override
  Stream<int> get openTaskRequests => _open.stream;
  @override
  Stream<void> get quickAddRequests => _add.stream;
  @override
  Future<int?> initialTaskToOpen() async => null;
}

/// Shared helper: OS-level notification gateway for the current platform.
NotificationGateway pluginGateway({required bool osScheduled}) =>
    osScheduled ? OsScheduledNotificationGateway() : InProcessNotificationGateway();
