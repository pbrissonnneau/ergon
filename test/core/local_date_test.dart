import 'package:ergon/src/core/local_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDate', () {
    test('epoch day round-trips across centuries', () {
      for (var ed = -800000; ed <= 800000; ed += 997) {
        final d = LocalDate.fromEpochDay(ed);
        expect(LocalDate(d.year, d.month, d.day).epochDay, ed);
      }
      expect(LocalDate(1970, 1, 1).epochDay, 0);
      expect(LocalDate(2000, 3, 1).epochDay, 11017);
    });

    test('weekday is ISO (Mon=1..Sun=7)', () {
      expect(LocalDate(1970, 1, 1).weekday, DateTime.thursday);
      expect(LocalDate(2026, 10, 4).weekday, DateTime.sunday);
      expect(LocalDate(2024, 2, 29).weekday, DateTime(2024, 2, 29).weekday);
      for (var i = 0; i < 400; i++) {
        final d = LocalDate(2026, 1, 1).addDays(i);
        expect(d.weekday, DateTime(d.year, d.month, d.day).weekday);
      }
    });

    test('normalises overflowing months and days', () {
      expect(LocalDate(2026, 13, 1), LocalDate(2027, 1, 1));
      expect(LocalDate(2026, 0, 1), LocalDate(2025, 12, 1));
      expect(LocalDate(2026, 1, 32), LocalDate(2026, 2, 1));
      expect(LocalDate(2026, 3, 0), LocalDate(2026, 2, 28));
    });

    test('addMonths clamps to month end', () {
      expect(LocalDate(2026, 1, 31).addMonths(1), LocalDate(2026, 2, 28));
      expect(LocalDate(2024, 1, 31).addMonths(1), LocalDate(2024, 2, 29));
      expect(LocalDate(2026, 3, 31).addMonths(-1), LocalDate(2026, 2, 28));
      expect(LocalDate(2026, 12, 15).addMonths(1), LocalDate(2027, 1, 15));
      expect(LocalDate(2024, 2, 29).addYears(1), LocalDate(2025, 2, 28));
    });

    test('leap years', () {
      expect(LocalDate.isLeapYear(2000), isTrue);
      expect(LocalDate.isLeapYear(1900), isFalse);
      expect(LocalDate.isLeapYear(2024), isTrue);
      expect(LocalDate.daysInMonth(2026, 2), 28);
    });

    test('parse/toString', () {
      expect(LocalDate.parse('2026-10-04').toString(), '2026-10-04');
    });

    test('atMinute builds local wall-clock time', () {
      final dt = LocalDate(2026, 10, 4).atMinute(19 * 60 + 5);
      expect(dt.hour, 19);
      expect(dt.minute, 5);
      expect(MinuteOfDay.format(19 * 60 + 5), '19:05');
    });
  });
}
