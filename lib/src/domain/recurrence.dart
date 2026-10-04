import 'dart:convert';

import '../core/local_date.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

/// How a monthly rule picks its day.
enum MonthlyMode {
  /// A fixed day number (1..31, or -1 for the last day). Days past the end of a
  /// short month are clamped to its last day (31st -> Feb 28/29).
  dayOfMonth,

  /// The n-th weekday of the month, e.g. "second Tuesday" or "last Friday".
  nthWeekday,
}

const weekdayShortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];

/// An immutable, serialisable recurrence rule working on civil dates.
class RecurrenceRule {
  RecurrenceRule({
    required this.frequency,
    required this.start,
    this.interval = 1,
    Set<int>? weekdays,
    this.monthlyMode = MonthlyMode.dayOfMonth,
    this.monthDay,
    this.weekOrdinal,
    this.until,
    this.count,
  }) : weekdays = Set.unmodifiable(weekdays ?? const <int>{}) {
    if (interval < 1) throw ArgumentError.value(interval, 'interval', 'must be >= 1');
    if (this.weekdays.any((d) => d < 1 || d > 7)) {
      throw ArgumentError.value(weekdays, 'weekdays', 'must be in 1..7');
    }
    if (monthDay != null && (monthDay! == 0 || monthDay! < -1 || monthDay! > 31)) {
      throw ArgumentError.value(monthDay, 'monthDay', 'must be 1..31 or -1');
    }
    if (weekOrdinal != null && (weekOrdinal! == 0 || weekOrdinal! < -1 || weekOrdinal! > 5)) {
      throw ArgumentError.value(weekOrdinal, 'weekOrdinal', 'must be 1..5 or -1');
    }
    if (count != null && count! < 1) throw ArgumentError.value(count, 'count', 'must be >= 1');
  }

  factory RecurrenceRule.daily(LocalDate start, {int every = 1}) =>
      RecurrenceRule(frequency: RecurrenceFrequency.daily, start: start, interval: every);

  factory RecurrenceRule.weekly(LocalDate start, {int every = 1, Set<int>? weekdays}) =>
      RecurrenceRule(
          frequency: RecurrenceFrequency.weekly, start: start, interval: every, weekdays: weekdays);

  factory RecurrenceRule.monthlyOnDay(LocalDate start, int day, {int every = 1}) => RecurrenceRule(
      frequency: RecurrenceFrequency.monthly, start: start, interval: every, monthDay: day);

  final RecurrenceFrequency frequency;
  final int interval;

  /// First date the rule may produce. Also the anchor for intervals.
  final LocalDate start;

  /// ISO weekdays for weekly rules (empty = the start date's weekday); for
  /// monthly [MonthlyMode.nthWeekday] rules exactly one weekday is used.
  final Set<int> weekdays;
  final MonthlyMode monthlyMode;

  /// Day of month for monthly/yearly rules (null = start's day, -1 = last day).
  final int? monthDay;

  /// 1..5 or -1 (last) for [MonthlyMode.nthWeekday].
  final int? weekOrdinal;

  /// Inclusive end date.
  final LocalDate? until;

  /// Maximum number of occurrences.
  final int? count;

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    LocalDate? start,
    int? interval,
    Set<int>? weekdays,
    MonthlyMode? monthlyMode,
    int? Function()? monthDay,
    int? Function()? weekOrdinal,
    LocalDate? Function()? until,
    int? Function()? count,
  }) =>
      RecurrenceRule(
        frequency: frequency ?? this.frequency,
        start: start ?? this.start,
        interval: interval ?? this.interval,
        weekdays: weekdays ?? this.weekdays,
        monthlyMode: monthlyMode ?? this.monthlyMode,
        monthDay: monthDay != null ? monthDay() : this.monthDay,
        weekOrdinal: weekOrdinal != null ? weekOrdinal() : this.weekOrdinal,
        until: until != null ? until() : this.until,
        count: count != null ? count() : this.count,
      );

  Map<String, Object?> toJson() => {
        'f': frequency.name,
        'i': interval,
        's': start.toString(),
        if (weekdays.isNotEmpty) 'wd': (weekdays.toList()..sort()),
        if (monthlyMode != MonthlyMode.dayOfMonth) 'mm': monthlyMode.name,
        if (monthDay != null) 'md': monthDay,
        if (weekOrdinal != null) 'wo': weekOrdinal,
        if (until != null) 'u': until.toString(),
        if (count != null) 'c': count,
      };

  String encode() => jsonEncode(toJson());

  factory RecurrenceRule.fromJson(Map<String, Object?> j) => RecurrenceRule(
        frequency: RecurrenceFrequency.values.byName(j['f']! as String),
        interval: (j['i'] as int?) ?? 1,
        start: LocalDate.parse(j['s']! as String),
        weekdays: ((j['wd'] as List?) ?? const []).cast<int>().toSet(),
        monthlyMode: j['mm'] == null ? MonthlyMode.dayOfMonth : MonthlyMode.values.byName(j['mm']! as String),
        monthDay: j['md'] as int?,
        weekOrdinal: j['wo'] as int?,
        until: j['u'] == null ? null : LocalDate.parse(j['u']! as String),
        count: j['c'] as int?,
      );

  static RecurrenceRule? decode(String? s) =>
      s == null || s.isEmpty ? null : RecurrenceRule.fromJson(jsonDecode(s) as Map<String, Object?>);

  /// Whether two rules generate the same dates (ignoring the start date).
  bool samePatternAs(RecurrenceRule o) =>
      frequency == o.frequency &&
      interval == o.interval &&
      _setEq(weekdays, o.weekdays) &&
      monthlyMode == o.monthlyMode &&
      monthDay == o.monthDay &&
      weekOrdinal == o.weekOrdinal &&
      until == o.until &&
      count == o.count;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule && samePatternAs(other) && start == other.start;

  @override
  int get hashCode => Object.hash(frequency, interval, start, monthDay, weekOrdinal, until, count);

  /// Human readable summary, e.g. "Every 2 weeks on Mon, Thu".
  String describe() {
    String every(String unit, String plural) => interval == 1 ? 'Every $unit' : 'Every $interval $plural';
    final buf = StringBuffer();
    switch (frequency) {
      case RecurrenceFrequency.daily:
        buf.write(interval == 1 ? 'Daily' : every('day', 'days'));
      case RecurrenceFrequency.weekly:
        buf.write(interval == 1 ? 'Weekly' : every('week', 'weeks'));
        final days = weekdays.isEmpty ? {start.weekday} : weekdays;
        buf.write(' on ${(days.toList()..sort()).map((d) => weekdayShortNames[d - 1]).join(', ')}');
      case RecurrenceFrequency.monthly:
        buf.write(interval == 1 ? 'Monthly' : every('month', 'months'));
        if (monthlyMode == MonthlyMode.nthWeekday) {
          final wd = weekdays.isEmpty ? start.weekday : weekdays.first;
          buf.write(' on the ${_ordinalWord(weekOrdinal ?? _defaultOrdinal(start))} ${weekdayShortNames[wd - 1]}');
        } else {
          final d = monthDay ?? start.day;
          buf.write(d == -1 ? ' on the last day' : ' on the ${_ordinal(d)}');
        }
      case RecurrenceFrequency.yearly:
        buf.write(interval == 1 ? 'Yearly' : every('year', 'years'));
        buf.write(' on ${monthNames[start.month - 1]} ${start.day}');
    }
    if (until != null) buf.write(', until $until');
    if (count != null) buf.write(', $count times');
    return buf.toString();
  }

  static int _defaultOrdinal(LocalDate d) => (d.day - 1) ~/ 7 + 1;

  static String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    return switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' };
  }

  static String _ordinalWord(int n) =>
      switch (n) { 1 => 'first', 2 => 'second', 3 => 'third', 4 => 'fourth', 5 => 'fifth', _ => 'last' };

  static bool _setEq(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);
}
