import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A command sent from one Overdue process to another.
class IpcCommand {
  const IpcCommand(this.name, [this.args = const {}]);
  final String name;
  final Map<String, Object?> args;

  static const show = 'show';
  static const openTask = 'open-task';
  static const quickAdd = 'quick-add';
  static const close = 'close';
  static const reload = 'reload';

  Map<String, Object?> toJson() => {'cmd': name, ...args};
  factory IpcCommand.fromJson(Map<String, Object?> j) =>
      IpcCommand(j['cmd'] as String? ?? '', Map.of(j)..remove('cmd'));
}

/// File-system based, network-free inter-process messaging between the main
/// window and the desktop overlay (both are the same executable).
///
/// * Liveness: each role holds an exclusive OS file lock for its lifetime;
///   the OS releases it automatically when the process exits or crashes.
/// * Messages: JSON files dropped into a per-role inbox directory, picked up
///   via directory watching with a polling fallback.
class InstanceChannel {
  InstanceChannel(this.baseDir, this.role);

  final Directory baseDir;
  final String role;
  RandomAccessFile? _lock;
  StreamSubscription<FileSystemEvent>? _watch;
  Timer? _poll;
  final _commands = StreamController<IpcCommand>.broadcast();
  bool _draining = false;

  Directory get _ipcDir => Directory(p.join(baseDir.path, 'ipc'));
  static Directory inboxOf(Directory baseDir, String role) => Directory(p.join(baseDir.path, 'ipc', '$role.inbox'));
  static File lockOf(Directory baseDir, String role) => File(p.join(baseDir.path, 'ipc', '$role.lock'));

  Stream<IpcCommand> get commands => _commands.stream;

  /// Held lock files. They must stay strongly reachable for the whole process
  /// lifetime: if a RandomAccessFile is garbage-collected its finalizer closes
  /// the descriptor, which silently drops the POSIX lock. (In AOT builds a
  /// field that is only written can be optimised away, so a static registry
  /// is used rather than relying on an instance field.)
  static final List<RandomAccessFile> _held = [];

  /// Tries to become the single live instance of [role].
  Future<bool> tryAcquire() async {
    await _ipcDir.create(recursive: true);
    final raf = await lockOf(baseDir, role).open(mode: FileMode.append);
    try {
      await raf.lock(FileLock.exclusive);
      _lock = raf;
      _held.add(raf);
      return true;
    } on FileSystemException {
      await raf.close();
      return false;
    }
  }

  /// Whether a process currently holds [role]'s lock.
  static Future<bool> isRunning(Directory baseDir, String role) async {
    final f = lockOf(baseDir, role);
    if (!await f.exists()) return false;
    final raf = await f.open(mode: FileMode.append);
    try {
      await raf.lock(FileLock.exclusive);
      await raf.unlock();
      return false;
    } on FileSystemException {
      return true;
    } finally {
      await raf.close();
    }
  }

  /// Delivers [cmd] to the inbox of [targetRole].
  static Future<void> send(Directory baseDir, String targetRole, IpcCommand cmd) async {
    final inbox = inboxOf(baseDir, targetRole);
    await inbox.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tmp = File(p.join(inbox.path, '$stamp-$pid.tmp'));
    await tmp.writeAsString(jsonEncode(cmd.toJson()), flush: true);
    await tmp.rename(p.join(inbox.path, '$stamp-$pid.json')); // Atomic publish.
  }

  /// Starts listening to this role's inbox (after [tryAcquire] succeeded).
  Future<void> listen() async {
    final inbox = inboxOf(baseDir, role);
    await inbox.create(recursive: true);
    try {
      _watch = inbox.watch(events: FileSystemEvent.create | FileSystemEvent.move).listen((_) => _drain());
    } catch (_) {
      // Watching unsupported: polling below still works.
    }
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _drain());
    await _drain();
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final inbox = inboxOf(baseDir, role);
      if (!await inbox.exists()) return;
      final files = await inbox.list().where((e) => e is File && e.path.endsWith('.json')).cast<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final f in files) {
        try {
          final json = jsonDecode(await f.readAsString()) as Map<String, Object?>;
          await f.delete();
          _commands.add(IpcCommand.fromJson(json));
        } catch (_) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> dispose() async {
    await _watch?.cancel();
    _poll?.cancel();
    await _commands.close();
    final lock = _lock;
    if (lock == null) return;
    _held.remove(lock);
    try {
      await lock.unlock();
      await lock.close();
    } catch (_) {}
  }
}
