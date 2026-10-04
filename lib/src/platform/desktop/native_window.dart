import 'dart:ffi';
import 'dart:io';

/// Thin native helpers that the cross-platform window plugin does not cover.
abstract final class NativeWindowHelpers {
  /// Windows only: lets the process we are about to signal (the main window)
  /// take the foreground, which Windows otherwise refuses to a background
  /// process ("focus stealing prevention"). No-op elsewhere.
  static void allowForegroundForOtherProcesses() {
    if (!Platform.isWindows) return;
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final allow = user32.lookupFunction<Int32 Function(Uint32), int Function(int)>('AllowSetForegroundWindow');
      allow(0xFFFFFFFF); // ASFW_ANY
    } catch (_) {}
  }
}
