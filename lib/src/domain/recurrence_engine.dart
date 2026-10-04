import '../core/local_date.dart';
import 'recurrence.dart';

/// Pure, allocation-light generator of occurrence dates for a [RecurrenceRule].
///
/// Everything happens on civil dates, so results never drift across DST or
/// timezone changes. Unbounded rules are only ever evaluated over explicit,
/// finite windows: nothing here generates "all" occurrences.
abstract final class RecurrenceEngine {
  /// Safety bound for pathological rules.
  static const _maxPeriods = 200000;

  /// Lazily yields the rule's dates on or after [from], in ascending order.
  static Iterable<LocalDate> iterate(RecurrenceRule rule, {LocalDate? from}) sync* {
    final lower = from == null || from < rule.start ? rule.start : from;
    // With a count limit we must count from the very beginning.
    var k = rule.count != null ? 0 : _firstPeriodNear(rule, lower);
    var produced = 0;
    for (var guard = 0; guard < _maxPeriods; guard++, k++) {
      final candidates = _candidates(rule, k);
      if (candidates == null) return; // Past representable range.
      for (final d in candidates) {
        if (d < rule.start) continue;
        if (rule.until != null && d > rule.until!) return;
        produced++;
        if (rule.count != null && produced > rule.count!) return;
        if (d >= lower) yield d;
      }
      // Once the period's first possible day is beyond `until`, stop.
      if (rule.until != null && _periodStart(rule, k) > rule.until!) return;
    }
  }

  /// Dates within [from, to] inclusive.
  static List<LocalDate> between(RecurrenceRule rule, LocalDate from, LocalDate to, {int limit = 5000}) {
    final out = <LocalDate>[];
    if (to < from) return out;
    for (final d in iterate(rule, from: from)) {
      if (d > to || out.length >= limit) break;
      out.add(d);
    }
    return out;
  }

  /// First date on or after [date], or null if the rule has ended.
  static LocalDate? nextOnOrAfter(RecurrenceRule rule, LocalDate date) {
    for (final d in iterate(rule, from: date)) {
      return d;
    }
    return null;
  }

  /// Whether [date] is one of the rule's dates.
  static bool matches(RecurrenceRule rule, LocalDate date) => nextOnOrAfter(rule, date) == date;

  // ---------------------------------------------------------------------------

  static int _firstPeriodNear(RecurrenceRule r, LocalDate from) {
    final int units;
    switch (r.frequency) {
      case RecurrenceFrequency.daily:
        units = r.start.daysUntil(from);
      case RecurrenceFrequency.weekly:
        units = r.start.startOfWeek.daysUntil(from.startOfWeek) ~/ 7;
      case RecurrenceFrequency.monthly:
        units = (from.year * 12 + from.month) - (r.start.year * 12 + r.start.month);
      case RecurrenceFrequency.yearly:
        units = from.year - r.start.year;
    }
    // Step back one period to be safe with clamped/early candidates.
    final k = units ~/ r.interval - 1;
    return k < 0 ? 0 : k;
  }

  static LocalDate _periodStart(RecurrenceRule r, int k) {
    final n = k * r.interval;
    return switch (r.frequency) {
      RecurrenceFrequency.daily => r.start.addDays(n),
      RecurrenceFrequency.weekly => r.start.startOfWeek.addDays(7 * n),
      RecurrenceFrequency.monthly => r.start.startOfMonth.addMonths(n),
      RecurrenceFrequency.yearly => LocalDate(r.start.year + n, 1, 1),
    };
  }

  /// Candidate dates for period [k], ascending. Returns null when out of range.
  static List<LocalDate>? _candidates(RecurrenceRule r, int k) {
    final n = k * r.interval;
    if (n > 12 * 10000) return null;
    switch (r.frequency) {
      case RecurrenceFrequency.daily:
        return [r.start.addDays(n)];
      case RecurrenceFrequency.weekly:
        final monday = r.start.startOfWeek.addDays(7 * n);
        final days = r.weekdays.isEmpty ? [r.start.weekday] : (r.weekdays.toList()..sort());
        return [for (final wd in days) monday.addDays(wd - 1)];
      case RecurrenceFrequency.monthly:
        final first = r.start.startOfMonth.addMonths(n);
        final d = r.monthlyMode == MonthlyMode.nthWeekday
            ? _nthWeekday(
                first,
                r.weekdays.isEmpty ? r.start.weekday : r.weekdays.first,
                r.weekOrdinal ?? ((r.start.day - 1) ~/ 7 + 1),
              )
            : _dayInMonth(first, r.monthDay ?? r.start.day);
        return d == null ? const [] : [d];
      case RecurrenceFrequency.yearly:
        final y = r.start.year + n;
        final dim = LocalDate.daysInMonth(y, r.start.month);
        return [LocalDate(y, r.start.month, r.start.day > dim ? dim : r.start.day)];
    }
  }

  static LocalDate _dayInMonth(LocalDate first, int day) {
    final dim = LocalDate.daysInMonth(first.year, first.month);
    if (day == -1 || day > dim) return LocalDate(first.year, first.month, dim);
    return LocalDate(first.year, first.month, day);
  }

  static LocalDate? _nthWeekday(LocalDate first, int weekday, int ordinal) {
    final dim = LocalDate.daysInMonth(first.year, first.month);
    if (ordinal == -1) {
      final last = LocalDate(first.year, first.month, dim);
      return last.addDays(-((last.weekday - weekday + 7) % 7));
    }
    final day = 1 + (weekday - first.weekday + 7) % 7 + (ordinal - 1) * 7;
    return day > dim ? null : LocalDate(first.year, first.month, day);
  }
}
