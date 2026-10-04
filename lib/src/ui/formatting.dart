import '../core/local_date.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

abstract final class Fmt {
  static String weekday(LocalDate d) => _weekdays[d.weekday - 1];
  static String weekdayShort(LocalDate d) => _weekdays[d.weekday - 1].substring(0, 3);
  static String month(int m) => _months[m - 1];

  /// "Oct 12" or "Oct 12, 2027" when not in [today]'s year.
  static String date(LocalDate d, LocalDate today) =>
      d.year == today.year ? '${month(d.month)} ${d.day}' : '${month(d.month)} ${d.day}, ${d.year}';

  /// "Sunday, Oct 4"
  static String longDate(LocalDate d) => '${weekday(d)}, ${month(d.month)} ${d.day}';

  /// Relative, compact label: Today, Tomorrow, Yesterday, Wed, Oct 12.
  static String relativeDate(LocalDate d, LocalDate today) {
    final diff = today.daysUntil(d);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff < 7) return weekdayShort(d);
    return date(d, today);
  }

  static String due(LocalDate d, int? minute, LocalDate today) =>
      minute == null ? relativeDate(d, today) : '${relativeDate(d, today)} ${MinuteOfDay.format(minute)}';

  static String timestamp(DateTime t, LocalDate today) {
    final l = t.toLocal();
    return '${relativeDate(LocalDate.fromDateTime(l), today)} ${MinuteOfDay.format(MinuteOfDay.fromDateTime(l))}';
  }

  static String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
}
