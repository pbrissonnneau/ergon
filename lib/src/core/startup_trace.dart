import 'dart:io';

/// Opt-in start-up timing (`ERGON_TRACE_STARTUP=1`): prints the wall-clock
/// epoch millis of each milestone to stderr so launch time can be measured
/// from outside the process. Does nothing otherwise.
abstract final class StartupTrace {
  static final bool enabled = Platform.environment['ERGON_TRACE_STARTUP'] == '1';
  static final _seen = <String>{};

  static void mark(String milestone) {
    if (!enabled || !_seen.add(milestone)) return;
    stderr.writeln('ergon-startup $milestone ${DateTime.now().millisecondsSinceEpoch}');
  }
}
