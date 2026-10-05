import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../services/notifications/notification_gateway.dart';
import '../platform_integration.dart';
import 'autostart.dart';
import 'instance_ipc.dart';

/// Windows and Linux desktop integration (main window process).
class DesktopIntegration extends PlatformIntegration {
  DesktopIntegration({required this.dataDir, required this.osSchedulesNotifications});

  final Directory dataDir;

  /// Windows toasts can be scheduled with the OS; Linux needs in-process delivery.
  final bool osSchedulesNotifications;

  /// The main-role channel; acquired in `main.dart` before the UI starts.
  InstanceChannel? mainChannel;
  int? launchTaskId;
  bool launchQuickAdd = false;

  final _open = StreamController<int>.broadcast();
  final _add = StreamController<void>.broadcast();
  StreamSubscription<IpcCommand>? _sub;

  @override
  bool get isDesktop => true;
  @override
  bool get supportsOverlay => true;
  @override
  bool get supportsHomeWidget => false;

  @override
  NotificationGateway createNotificationGateway() => pluginGateway(osScheduled: osSchedulesNotifications);

  InstanceChannel? _notifier;

  @override
  Future<bool> tryAcquireReminderHost() async {
    if (_notifier != null) return true;
    final ch = InstanceChannel(dataDir, 'notifier');
    if (await ch.tryAcquire()) {
      _notifier = ch;
      return true;
    }
    return false;
  }

  @override
  Future<void> start() async {
    final ch = mainChannel;
    if (ch == null) return;
    _sub = ch.commands.listen((cmd) async {
      switch (cmd.name) {
        case IpcCommand.openTask:
          await bringToFront();
          final id = cmd.args['taskId'];
          if (id is int) _open.add(id);
        case IpcCommand.quickAdd:
          await bringToFront();
          _add.add(null);
        case IpcCommand.show:
          await bringToFront();
      }
    });
    await ch.listen();
    if (launchQuickAdd) _add.add(null);
  }

  @override
  Stream<int> get openTaskRequests => _open.stream;
  @override
  Stream<void> get quickAddRequests => _add.stream;

  @override
  Future<int?> initialTaskToOpen() async => launchTaskId;

  @override
  Future<void> setOverlayVisible(bool visible) async {
    final running = await InstanceChannel.isRunning(dataDir, 'overlay');
    if (visible && !running) {
      await Process.start(Platform.resolvedExecutable, const ['--overlay'], mode: ProcessStartMode.detached);
    } else if (!visible && running) {
      await InstanceChannel.send(dataDir, 'overlay', const IpcCommand(IpcCommand.close));
    }
  }

  @override
  Future<Directory> defaultBackupFolder(Directory dataDir) async {
    try {
      // Visible to the user and independent of the app's own data folder.
      return Directory(p.join((await getApplicationDocumentsDirectory()).path, 'Ergon backups'));
    } catch (_) {
      return super.defaultBackupFolder(dataDir);
    }
  }

  @override
  Future<void> restartApp() async {
    // The overlay keeps the database open; it must close for the swap.
    if (await InstanceChannel.isRunning(dataDir, 'overlay')) {
      await InstanceChannel.send(dataDir, 'overlay', const IpcCommand(IpcCommand.close));
    }
    await mainChannel?.dispose(); // Release the single-instance lock first.
    await Process.start(Platform.resolvedExecutable, const ['--restarted'], mode: ProcessStartMode.detached);
    exit(0);
  }

  @override
  Future<bool?> overlayAutostartEnabled() => DesktopAutostart.isOverlayAutostartEnabled();

  @override
  Future<void> setOverlayAutostart(bool enabled) => DesktopAutostart.setOverlayAutostart(enabled);

  @override
  Future<void> bringToFront() async {
    try {
      if (await windowManager.isMinimized()) await windowManager.restore();
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await mainChannel?.dispose();
    await _notifier?.dispose();
  }
}
