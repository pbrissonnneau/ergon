import 'dart:io';

import 'package:path/path.dart' as p;

/// User-level "start at login" registration for the overlay. Never requires
/// administrator/root rights.
abstract final class DesktopAutostart {
  static const _name = 'ErgonOverlay';

  static Future<bool> isOverlayAutostartEnabled() async {
    if (Platform.isLinux) return File(_linuxDesktopFile).exists();
    if (Platform.isWindows) {
      final r = await Process.run('reg', ['query', _winRunKey, '/v', _name]);
      return r.exitCode == 0;
    }
    return false;
  }

  static Future<void> setOverlayAutostart(bool enabled) async {
    final exe = Platform.resolvedExecutable;
    if (Platform.isLinux) {
      final f = File(_linuxDesktopFile);
      if (enabled) {
        await f.parent.create(recursive: true);
        await f.writeAsString('[Desktop Entry]\n'
            'Type=Application\n'
            'Name=Ergon overlay\n'
            'Comment=Compact agenda overlay for Ergon\n'
            'Exec="$exe" --overlay\n'
            'X-GNOME-Autostart-enabled=true\n'
            'NoDisplay=true\n');
      } else if (await f.exists()) {
        await f.delete();
      }
    } else if (Platform.isWindows) {
      if (enabled) {
        await Process.run('reg', ['add', _winRunKey, '/v', _name, '/t', 'REG_SZ', '/d', '"$exe" --overlay', '/f']);
      } else {
        await Process.run('reg', ['delete', _winRunKey, '/v', _name, '/f']);
      }
    }
  }

  static String get _linuxDesktopFile {
    final config = Platform.environment['XDG_CONFIG_HOME'] ??
        p.join(Platform.environment['HOME'] ?? '.', '.config');
    return p.join(config, 'autostart', 'ergon-overlay.desktop');
  }

  // HKCU: per-user, no elevation needed.
  static const _winRunKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
}
