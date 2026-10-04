/// Civil (wall-clock) date and time types.
///
/// Due dates, occurrence dates and reminder times are stored as *civil* values
/// (epoch-day + minute-of-day) rather than instants. This keeps them stable
/// across timezone and daylight-saving changes: "Pay rent on the 25th at
/// 09:00" stays at 09:00 local time, wherever and whenever the device is.
library;

/// A calendar date without time or timezone, backed by a day count since
/// 1970-01-01 (proleptic Gregorian calendar).
class LocalDate implements Comparable<LocalDate> {
  const LocalDate._(this.epochDay, this.year, this.month, this.day);

  factory LocalDate(int year, int month, int day) {
    // Out-of-range months and days are normalised (month 13 = next January).
    final total = year * 12 + (month - 1);
    final y = (total / 12).floor();
    final m = total - y * 12 + 1;
    return LocalDate.fromEpochDay(_daysFromCivil(y, m, 1) + day - 1);
  }

  factory LocalDate.fromEpochDay(int epochDay) {
    final c = _civilFromDays(epochDay);
    return LocalDate._(epochDay, c.$1, c.$2, c.$3);
  }

  factory LocalDate.fromDateTime(DateTime dt) => LocalDate(dt.year, dt.month, dt.day);

  /// Today in the device's current local timezone.
  factory LocalDate.today([DateTime? now]) => LocalDate.fromDateTime(now ?? DateTime.now());

  /// Parses `YYYY-MM-DD`.
  factory LocalDate.parse(String s) {
    final parts = s.split('-');
    if (parts.length != 3) throw FormatException('Invalid date: $s');
    return LocalDate(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  final int epochDay;
  final int year;
  final int month;
  final int day;

  /// ISO weekday: Monday = 1 ... Sunday = 7.
  int get weekday => (epochDay % 7 + 3) % 7 + 1; // 1970-01-01 was a Thursday.

  LocalDate addDays(int days) => LocalDate.fromEpochDay(epochDay + days);

  /// Adds months, clamping the day to the target month's length
  /// (Jan 31 + 1 month = Feb 28/29).
  LocalDate addMonths(int months) {
    final total = year * 12 + (month - 1) + months;
    final y = (total / 12).floor();
    final m = total - y * 12 + 1;
    final d = day <= 28 ? day : (day > daysInMonth(y, m) ? daysInMonth(y, m) : day);
    return LocalDate(y, m, d);
  }

  LocalDate addYears(int years) => addMonths(years * 12);

  /// First day of this date's month.
  LocalDate get startOfMonth => LocalDate(year, month, 1);

  /// Monday of this date's ISO week.
  LocalDate get startOfWeek => addDays(1 - weekday);

  int daysUntil(LocalDate other) => other.epochDay - epochDay;

  bool isBefore(LocalDate other) => epochDay < other.epochDay;
  bool isAfter(LocalDate other) => epochDay > other.epochDay;
  bool operator <(LocalDate other) => epochDay < other.epochDay;
  bool operator <=(LocalDate other) => epochDay <= other.epochDay;
  bool operator >(LocalDate other) => epochDay > other.epochDay;
  bool operator >=(LocalDate other) => epochDay >= other.epochDay;

  /// Local wall-clock DateTime at [minuteOfDay] (default midnight).
  ///
  /// Uses the platform's local timezone. A wall time that does not exist
  /// (skipped by a DST transition) is normalised forward by the platform.
  DateTime atMinute([int minuteOfDay = 0]) =>
      DateTime(year, month, day, minuteOfDay ~/ 60, minuteOfDay % 60);

  static bool isLeapYear(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  static int daysInMonth(int y, int m) {
    const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return m == 2 && isLeapYear(y) ? 29 : lengths[m - 1];
  }

  @override
  int compareTo(LocalDate other) => epochDay.compareTo(other.epochDay);

  @override
  bool operator ==(Object other) => other is LocalDate && other.epochDay == epochDay;

  @override
  int get hashCode => epochDay.hashCode;

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  // Howard Hinnant's civil-from-days algorithms.
  static int _daysFromCivil(int y, int m, int d) {
    y -= m <= 2 ? 1 : 0;
    final era = (y >= 0 ? y : y - 399) ~/ 400;
    final yoe = y - era * 400;
    final doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) ~/ 5 + d - 1;
    final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
    return era * 146097 + doe - 719468;
  }

  static (int, int, int) _civilFromDays(int z) {
    z += 719468;
    final era = (z >= 0 ? z : z - 146096) ~/ 146097;
    final doe = z - era * 146097;
    final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
    final y = yoe + era * 400;
    final doy = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
    final mp = (5 * doy + 2) ~/ 153;
    final d = doy - (153 * mp + 2) ~/ 5 + 1;
    final m = mp + (mp < 10 ? 3 : -9);
    return (m <= 2 ? y + 1 : y, m, d);
  }
}

/// Helpers for minute-of-day values (0..1439).
abstract final class MinuteOfDay {
  static int of(int hour, int minute) => hour * 60 + minute;
  static int fromDateTime(DateTime dt) => dt.hour * 60 + dt.minute;
  static String format(int minuteOfDay) =>
      '${(minuteOfDay ~/ 60).toString().padLeft(2, '0')}:${(minuteOfDay % 60).toString().padLeft(2, '0')}';
}

/// Injectable time source so that logic is deterministic in tests.
abstract class Clock {
  const Clock();
  DateTime now();
  LocalDate today() => LocalDate.fromDateTime(now());
}

class SystemClock extends Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

class FixedClock extends Clock {
  FixedClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
  void advance(Duration d) => current = current.add(d);
}
