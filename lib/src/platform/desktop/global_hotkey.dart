import 'dart:async';

import 'package:flutter/services.dart';

/// System-wide Ctrl+Alt+N (Windows): native `RegisterHotKey` in the runner,
/// reported here through a method channel.
///
/// Only one process can own a hotkey. The main window and the overlay both
/// try; whichever succeeds handles it, the other retries periodically (so the
/// shortcut keeps working when either one closes).
class GlobalHotkey {
  GlobalHotkey(this.onPressed);

  final VoidCallback onPressed;
  static const _channel = MethodChannel('app.overdue/hotkey');
  Timer? _retry;
  bool _registered = false;
  bool _enabled = false;

  bool get isRegistered => _registered;

  Future<void> setEnabled(bool enabled) async {
    if (enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'pressed') onPressed();
        return null;
      });
      await _tryRegister();
      _retry ??= Timer.periodic(const Duration(seconds: 20), (_) {
        if (!_registered) unawaited(_tryRegister());
      });
    } else {
      _retry?.cancel();
      _retry = null;
      if (_registered) {
        try {
          await _channel.invokeMethod<bool>('unregister');
        } on MissingPluginException {
          // Runner without hotkey support.
        }
      }
      _registered = false;
    }
  }

  Future<void> _tryRegister() async {
    try {
      _registered = await _channel.invokeMethod<bool>('register') ?? false;
    } on MissingPluginException {
      _retry?.cancel(); // Not supported by this runner (Linux): stop trying.
    }
  }
}
