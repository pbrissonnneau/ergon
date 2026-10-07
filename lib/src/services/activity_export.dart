import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/local_date.dart';
import '../data/settings_repository.dart';
import '../data/task_repository.dart';
import '../domain/models.dart';

/// Export period: a calendar month or an ISO week (Monday to Sunday).
enum ExportPeriod {
  month('month', 'Monthly'),
  week('week', 'Weekly');

  const ExportPeriod(this.code, this.label);
  final String code;
  final String label;

  static ExportPeriod fromCode(String? c) => c == week.code ? week : month;
}

/// One period to export: its bounds and the label used in the file name.
class ExportRange {
  const ExportRange(this.from, this.to, this.label);
  final LocalDate from;
  final LocalDate to;
  final String label;

  @override
  bool operator ==(Object other) => other is ExportRange && other.label == label;
  @override
  int get hashCode => label.hashCode;
  @override
  String toString() => label;

  /// The period of [kind] containing [day].
  static ExportRange containing(LocalDate day, ExportPeriod kind) {
    if (kind == ExportPeriod.month) {
      final from = LocalDate(day.year, day.month, 1);
      final to = LocalDate(day.year, day.month + 1, 1).addDays(-1);
      return ExportRange(from, to, '${day.year}-${_two(day.month)}');
    }
    final from = day.addDays(-(day.weekday - DateTime.monday));
    // ISO week: the week belongs to the year of its Thursday.
    final thursday = from.addDays(3);
    final week = (LocalDate(thursday.year, 1, 1).daysUntil(thursday) ~/ 7) + 1;
    return ExportRange(from, from.addDays(6), '${thursday.year}-W${_two(week)}');
  }

  ExportRange previous(ExportPeriod kind) => containing(from.addDays(-1), kind);
  ExportRange next(ExportPeriod kind) => containing(to.addDays(1), kind);

  static String _two(int n) => n.toString().padLeft(2, '0');
}

/// Writes a small YAML summary of what was done (completed, postponed and
/// created tasks) per period into a folder chosen by the user — local files
/// only, nothing leaves the device.
///
/// When enabled, every finished period is exported once (checked at start-up
/// and at day change); "Export now" writes the current period so far, and is
/// overwritten by the complete file once the period ends.
class ActivityExportService {
  ActivityExportService({
    required this.tasks,
    required this.settings,
    required this.defaultFolder,
    Clock clock = const SystemClock(),
  }) : _clock = clock;

  final TaskRepository tasks;
  final AppSettings settings;

  /// Used when the user has not chosen a folder (set by the platform at start-up).
  Directory defaultFolder;
  final Clock _clock;

  static const enabledKey = 'export.enabled';
  static const folderKey = 'export.folder';
  static const periodKey = 'export.period';
  static const lastKey = 'export.last';

  /// Catch-up limit after a long absence.
  static const maxCatchUp = 12;

  bool get enabled => settings.raw(enabledKey) == '1';
  ExportPeriod get period => ExportPeriod.fromCode(settings.raw(periodKey));

  Directory get folder {
    final custom = settings.raw(folderKey);
    return custom == null || custom.isEmpty ? defaultFolder : Directory(custom);
  }

  /// Exports the finished periods not exported yet. Returns the files written.
  Future<List<File>> runIfDue() async {
    if (!enabled) return const [];
    final kind = period;
    final lastFinished = ExportRange.containing(_clock.today(), kind).previous(kind);
    final done = settings.raw(lastKey);
    final due = <ExportRange>[];
    if (done == null || done.isEmpty || _isWeekLabel(done) != (kind == ExportPeriod.week)) {
      // First run (or the period kind changed): only the period that just ended.
      due.add(lastFinished);
    } else {
      // Labels sort chronologically (2026-09 < 2026-10, 2026-W09 < 2026-W10).
      for (var r = lastFinished; r.label.compareTo(done) > 0 && due.length < maxCatchUp; r = r.previous(kind)) {
        due.insert(0, r);
      }
    }
    final written = <File>[];
    for (final r in due) {
      written.add(await export(r));
      await settings.setRaw(lastKey, r.label);
    }
    return written;
  }

  static bool _isWeekLabel(String label) => label.contains('-W');

  /// Exports the current period up to today.
  Future<File> exportNow() => export(ExportRange.containing(_clock.today(), period), partial: true);

  /// Writes the YAML file of [range] (replacing an older one).
  Future<File> export(ExportRange range, {bool partial = false}) async {
    final history = await tasks.watchCompleted(range.from, range.to).first;
    final created = await tasks.tasksCreatedBetween(range.from, range.to);
    final yaml = buildYaml(range, history, created, generatedAt: _clock.now(), partial: partial);
    final dir = folder;
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'overdue-activity-${range.label}.yaml'));
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(yaml, flush: true);
    return tmp.rename(file.path); // Never leave a half-written file behind.
  }

  /// The YAML document (pure, for tests).
  static String buildYaml(
    ExportRange range,
    List<CompletedItem> history,
    List<TaskListItem> created, {
    required DateTime generatedAt,
    bool partial = false,
  }) {
    final completed = history.where((h) => h.postponement == null).toList();
    final postponed = history.where((h) => h.postponement != null).toList();
    final days = <int, _Day>{};
    _Day day(LocalDate d) => days.putIfAbsent(d.epochDay, () => _Day(d));
    for (final h in completed) {
      day(h.day).completed.add(h);
    }
    for (final h in postponed) {
      day(h.day).postponed.add(h);
    }
    for (final c in created) {
      day(LocalDate.fromDateTime(c.task.createdAt.toLocal())).created.add(c);
    }

    final b = StringBuffer()
      ..writeln('# Overdue activity export')
      ..writeln('period: ${_q(range.label)}')
      ..writeln('from: ${range.from}')
      ..writeln('to: ${range.to}')
      ..writeln('complete: ${!partial}')
      ..writeln('generated_at: ${_q(_stamp(generatedAt))}')
      ..writeln('summary:')
      ..writeln('  completed: ${completed.length}')
      ..writeln('  postponed: ${postponed.length}')
      ..writeln('  created: ${created.length}');
    if (days.isEmpty) {
      b.writeln('days: []');
      return b.toString();
    }
    b.writeln('days:');
    for (final key in days.keys.toList()..sort()) {
      final d = days[key]!;
      b.writeln('  - date: ${d.date}');
      if (d.completed.isNotEmpty) {
        b.writeln('    completed:');
        for (final h in d.completed..sort((a, b) => _doneAt(a).compareTo(_doneAt(b)))) {
          b.writeln('      - title: ${_q(h.item.task.title)}');
          _project(b, h.item);
          final at = h.occurrence?.completedAt ?? h.item.task.completedAt;
          if (at != null) b.writeln('        time: ${_q(_hm(at))}');
          if (h.occurrence != null) b.writeln('        recurring: true');
        }
      }
      if (d.postponed.isNotEmpty) {
        b.writeln('    postponed:');
        for (final h in d.postponed) {
          final pp = h.postponement!;
          b.writeln('      - title: ${_q(pp.item.task.title)}');
          _project(b, pp.item);
          b.writeln('        from: ${pp.from}');
          b.writeln('        to: ${pp.to == null ? _q('backlog') : pp.to.toString()}');
        }
      }
      if (d.created.isNotEmpty) {
        b.writeln('    created:');
        for (final c in d.created) {
          b.writeln('      - title: ${_q(c.task.title)}');
          _project(b, c);
        }
      }
    }
    return b.toString();
  }

  static void _project(StringBuffer b, TaskListItem item) {
    if (item.projectName != null) b.writeln('        project: ${_q(item.projectName!)}');
  }

  static DateTime _doneAt(CompletedItem h) =>
      h.occurrence?.completedAt ?? h.item.task.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _hm(DateTime t) {
    final l = t.toLocal();
    return '${_two(l.hour)}:${_two(l.minute)}';
  }

  static String _stamp(DateTime t) {
    final l = t.toLocal();
    return '${LocalDate.fromDateTime(l)}T${_hm(l)}:${_two(l.second)}';
  }

  /// YAML double-quoted scalar.
  static String _q(String s) {
    final e = StringBuffer('"');
    for (final r in s.runes) {
      switch (r) {
        case 0x22:
          e.write(r'\"');
        case 0x5C:
          e.write(r'\\');
        case 0x0A:
          e.write(r'\n');
        case 0x0D:
          e.write(r'\r');
        case 0x09:
          e.write(r'\t');
        default:
          if (r < 0x20) {
            e.write('\\x${r.toRadixString(16).padLeft(2, '0')}');
          } else {
            e.writeCharCode(r);
          }
      }
    }
    e.write('"');
    return e.toString();
  }
}

class _Day {
  _Day(this.date);
  final LocalDate date;
  final completed = <CompletedItem>[];
  final postponed = <CompletedItem>[];
  final created = <TaskListItem>[];
}
