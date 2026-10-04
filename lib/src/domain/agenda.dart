import '../core/local_date.dart';
import 'enums.dart';
import 'models.dart';

enum AgendaSectionKind {
  todayUrgent('Urgent'),
  today('Due today'),
  ongoing('Ongoing'),
  recurring('Recurring'),
  overdue('Overdue'),
  upcoming('Upcoming');

  const AgendaSectionKind(this.label);
  final String label;
}

/// One line in the agenda: a task, or one occurrence of a recurring task.
class AgendaEntry {
  const AgendaEntry({required this.item, this.occurrence, this.missedCount = 0});

  final TaskListItem item;
  final Occurrence? occurrence;

  /// For overdue recurring entries: how many earlier occurrences were missed.
  final int missedCount;

  Task get task => item.task;
  bool get isOccurrence => occurrence != null;
  LocalDate? get date => occurrence?.date ?? task.dueDate;
  int? get minute => occurrence != null ? occurrence!.dueMinute : task.dueMinute;
  TaskStatus get status => occurrence?.status ?? task.status;

  /// Stable key for list diffing.
  String get key => occurrence != null ? 'o${task.id}_${occurrence!.date.epochDay}' : 't${task.id}';
}

class AgendaSection {
  const AgendaSection(this.kind, this.entries, {this.date});
  final AgendaSectionKind kind;
  final List<AgendaEntry> entries;

  /// Day of an upcoming section.
  final LocalDate? date;

  bool get isTodayGroup =>
      kind == AgendaSectionKind.todayUrgent ||
      kind == AgendaSectionKind.today ||
      kind == AgendaSectionKind.ongoing ||
      kind == AgendaSectionKind.recurring;
}

class Agenda {
  const Agenda({required this.today, required this.sections});
  final LocalDate today;
  final List<AgendaSection> sections;

  static Agenda empty(LocalDate today) => Agenda(today: today, sections: const []);

  Iterable<AgendaSection> get todaySections => sections.where((s) => s.isTodayGroup);
  AgendaSection? get overdue => sections.where((s) => s.kind == AgendaSectionKind.overdue).firstOrNull;
  Iterable<AgendaSection> get upcoming => sections.where((s) => s.kind == AgendaSectionKind.upcoming);

  int get todayCount => todaySections.fold(0, (n, s) => n + s.entries.length);
  int get overdueCount => overdue?.entries.length ?? 0;
  bool get isEmpty => sections.every((s) => s.entries.isEmpty);
}

/// Pure agenda computation: "What do I need to deal with today?"
abstract final class AgendaBuilder {
  static Agenda build({
    required LocalDate today,
    required int upcomingDays,
    required List<TaskListItem> tasks,
    required List<(TaskListItem, Occurrence)> occurrences,
  }) {
    final end = today.addDays(upcomingDays);
    final urgent = <AgendaEntry>[];
    final dueToday = <AgendaEntry>[];
    final ongoing = <AgendaEntry>[];
    final recurring = <AgendaEntry>[];
    final overdue = <AgendaEntry>[];
    final upcoming = <int, List<AgendaEntry>>{};

    for (final item in tasks) {
      final t = item.task;
      if (!t.status.isAgendaVisible || t.type == TaskType.recurring) continue;
      final entry = AgendaEntry(item: item);
      final due = t.dueDate;
      if (due == null) {
        if (t.type == TaskType.ongoing) ongoing.add(entry);
      } else if (due < today) {
        overdue.add(entry);
      } else if (due == today) {
        (t.priority == TaskPriority.urgent ? urgent : dueToday).add(entry);
      } else if (t.type == TaskType.ongoing) {
        ongoing.add(entry);
      } else if (due <= end) {
        upcoming.putIfAbsent(due.epochDay, () => []).add(entry);
      }
    }

    // Recurring: collapse missed occurrences per task to the most recent one.
    final missedByTask = <int, List<(TaskListItem, Occurrence)>>{};
    for (final pair in occurrences) {
      final (item, occ) = pair;
      if (!occ.status.isAgendaVisible || !item.task.status.isAgendaVisible) continue;
      if (occ.date < today) {
        missedByTask.putIfAbsent(item.task.id, () => []).add(pair);
      } else if (occ.date == today) {
        final e = AgendaEntry(item: item, occurrence: occ);
        (item.task.priority == TaskPriority.urgent ? urgent : recurring).add(e);
      } else if (occ.date <= end) {
        upcoming.putIfAbsent(occ.date.epochDay, () => []).add(AgendaEntry(item: item, occurrence: occ));
      }
    }
    for (final list in missedByTask.values) {
      list.sort((a, b) => a.$2.date.compareTo(b.$2.date));
      final (item, last) = list.last;
      overdue.add(AgendaEntry(item: item, occurrence: last, missedCount: list.length - 1));
    }

    urgent.sort(_byTime);
    dueToday.sort(_byPriorityThenTime);
    ongoing.sort(_byPriorityThenTime);
    recurring.sort(_byPriorityThenTime);
    overdue.sort(_byDateThenPriority);

    final sections = <AgendaSection>[
      if (urgent.isNotEmpty) AgendaSection(AgendaSectionKind.todayUrgent, urgent),
      if (dueToday.isNotEmpty) AgendaSection(AgendaSectionKind.today, dueToday),
      if (ongoing.isNotEmpty) AgendaSection(AgendaSectionKind.ongoing, ongoing),
      if (recurring.isNotEmpty) AgendaSection(AgendaSectionKind.recurring, recurring),
      if (overdue.isNotEmpty) AgendaSection(AgendaSectionKind.overdue, overdue),
      for (final day in upcoming.keys.toList()..sort())
        AgendaSection(AgendaSectionKind.upcoming, upcoming[day]!..sort(_byPriorityThenTime),
            date: LocalDate.fromEpochDay(day)),
    ];
    return Agenda(today: today, sections: sections);
  }

  static int _cmpMinute(AgendaEntry a, AgendaEntry b) {
    final am = a.minute, bm = b.minute;
    if (am == bm) return 0;
    if (am == null) return 1;
    if (bm == null) return -1;
    return am.compareTo(bm);
  }

  static int _byTitle(AgendaEntry a, AgendaEntry b) =>
      a.task.title.toLowerCase().compareTo(b.task.title.toLowerCase());

  static int _byTime(AgendaEntry a, AgendaEntry b) {
    final c = _cmpMinute(a, b);
    return c != 0 ? c : _byTitle(a, b);
  }

  static int _byPriorityThenTime(AgendaEntry a, AgendaEntry b) {
    final p = b.task.priority.code.compareTo(a.task.priority.code);
    return p != 0 ? p : _byTime(a, b);
  }

  static int _byDateThenPriority(AgendaEntry a, AgendaEntry b) {
    final d = a.date!.compareTo(b.date!);
    return d != 0 ? d : _byPriorityThenTime(a, b);
  }
}
