import 'package:overdue/src/core/local_date.dart';
import 'package:overdue/src/domain/recurrence.dart';
import 'package:overdue/src/domain/recurrence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);
List<String> s(List<LocalDate> l) => l.map((e) => e.toString()).toList();

void main() {
  group('daily', () {
    test('every day', () {
      final r = RecurrenceRule.daily(d(2026, 10, 1));
      expect(s(RecurrenceEngine.between(r, d(2026, 10, 1), d(2026, 10, 3))), [
        '2026-10-01',
        '2026-10-02',
        '2026-10-03',
      ]);
    });

    test('every N days keeps phase from start, even when querying far later', () {
      final r = RecurrenceRule.daily(d(2026, 10, 1), every: 2);
      expect(s(RecurrenceEngine.between(r, d(2026, 10, 1), d(2026, 10, 6))), [
        '2026-10-01',
        '2026-10-03',
        '2026-10-05',
      ]);
      // 1000 days later: phase still aligned (1000 is even).
      expect(RecurrenceEngine.nextOnOrAfter(r, d(2026, 10, 1).addDays(1000)), d(2026, 10, 1).addDays(1000));
      expect(RecurrenceEngine.nextOnOrAfter(r, d(2026, 10, 1).addDays(1001)), d(2026, 10, 1).addDays(1002));
    });

    test('never yields before start', () {
      final r = RecurrenceRule.daily(d(2026, 10, 10));
      expect(RecurrenceEngine.between(r, d(2026, 10, 1), d(2026, 10, 9)), isEmpty);
    });

    test('crosses month/year boundaries and leap day', () {
      final r = RecurrenceRule.daily(d(2027, 12, 30));
      expect(s(RecurrenceEngine.between(r, d(2027, 12, 30), d(2028, 1, 2))), [
        '2027-12-30',
        '2027-12-31',
        '2028-01-01',
        '2028-01-02',
      ]);
      final leap = RecurrenceRule.daily(d(2028, 2, 28));
      expect(s(RecurrenceEngine.between(leap, d(2028, 2, 28), d(2028, 3, 1))), [
        '2028-02-28',
        '2028-02-29',
        '2028-03-01',
      ]);
    });
  });

  group('weekly', () {
    test('defaults to start weekday', () {
      final r = RecurrenceRule.weekly(d(2026, 10, 5)); // Monday
      expect(s(RecurrenceEngine.between(r, d(2026, 10, 1), d(2026, 10, 20))), [
        '2026-10-05',
        '2026-10-12',
        '2026-10-19',
      ]);
    });

    test('selected weekdays', () {
      final r = RecurrenceRule.weekly(d(2026, 10, 5), weekdays: {1, 3, 5});
      expect(s(RecurrenceEngine.between(r, d(2026, 10, 5), d(2026, 10, 11))), [
        '2026-10-05',
        '2026-10-07',
        '2026-10-09',
      ]);
    });

    test('every 2 weeks on Tue/Thu, starting mid-week', () {
      final r = RecurrenceRule.weekly(d(2026, 10, 8), every: 2, weekdays: {2, 4}); // Thu
      expect(s(RecurrenceEngine.between(r, d(2026, 10, 1), d(2026, 11, 1))), [
        '2026-10-08',
        '2026-10-20',
        '2026-10-22',
      ]);
    });

    test('week spanning a year boundary', () {
      final r = RecurrenceRule.weekly(d(2026, 12, 28), weekdays: {1, 5});
      expect(s(RecurrenceEngine.between(r, d(2026, 12, 28), d(2027, 1, 8))), [
        '2026-12-28',
        '2027-01-01',
        '2027-01-04',
        '2027-01-08',
      ]);
    });
  });

  group('monthly', () {
    test('specific day of month (rent on the 25th)', () {
      final r = RecurrenceRule.monthlyOnDay(d(2026, 10, 1), 25);
      expect(s(RecurrenceEngine.between(r, d(2026, 10, 1), d(2027, 1, 31))), [
        '2026-10-25',
        '2026-11-25',
        '2026-12-25',
        '2027-01-25',
      ]);
    });

    test('31st clamps to the last day of shorter months', () {
      final r = RecurrenceRule.monthlyOnDay(d(2026, 1, 31), 31);
      expect(s(RecurrenceEngine.between(r, d(2026, 1, 1), d(2026, 4, 30))), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
        '2026-04-30',
      ]);
      final leap = RecurrenceRule.monthlyOnDay(d(2028, 1, 31), 30);
      expect(RecurrenceEngine.nextOnOrAfter(leap, d(2028, 2, 1)), d(2028, 2, 29));
    });

    test('last day of month (-1)', () {
      final r = RecurrenceRule.monthlyOnDay(d(2026, 1, 1), -1);
      expect(s(RecurrenceEngine.between(r, d(2026, 1, 1), d(2026, 3, 31))), ['2026-01-31', '2026-02-28', '2026-03-31']);
    });

    test('every 3 months', () {
      final r = RecurrenceRule.monthlyOnDay(d(2026, 1, 15), 15, every: 3);
      expect(s(RecurrenceEngine.between(r, d(2026, 1, 1), d(2026, 12, 31))), [
        '2026-01-15',
        '2026-04-15',
        '2026-07-15',
        '2026-10-15',
      ]);
    });

    test('day before start in first month is skipped', () {
      final r = RecurrenceRule.monthlyOnDay(d(2026, 10, 26), 25);
      expect(RecurrenceEngine.nextOnOrAfter(r, d(2026, 10, 1)), d(2026, 11, 25));
    });

    test('n-th weekday and last weekday', () {
      final second = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        start: d(2026, 10, 1),
        monthlyMode: MonthlyMode.nthWeekday,
        weekdays: {2},
        weekOrdinal: 2,
      );
      expect(s(RecurrenceEngine.between(second, d(2026, 10, 1), d(2026, 12, 31))), [
        '2026-10-13',
        '2026-11-10',
        '2026-12-08',
      ]);
      final lastFri = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        start: d(2026, 10, 1),
        monthlyMode: MonthlyMode.nthWeekday,
        weekdays: {5},
        weekOrdinal: -1,
      );
      expect(s(RecurrenceEngine.between(lastFri, d(2026, 10, 1), d(2026, 12, 31))), [
        '2026-10-30',
        '2026-11-27',
        '2026-12-25',
      ]);
    });

    test('fifth weekday skips months without one', () {
      final r = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        start: d(2026, 1, 1),
        monthlyMode: MonthlyMode.nthWeekday,
        weekdays: {4},
        weekOrdinal: 5,
      );
      final dates = RecurrenceEngine.between(r, d(2026, 1, 1), d(2026, 12, 31));
      expect(dates.every((x) => x.weekday == 4 && x.day > 28), isTrue);
      expect(s(dates).first, '2026-01-29');
      expect(dates.length, 5); // Jan, Apr, Jul, Oct, Dec 2026.
    });
  });

  group('yearly', () {
    test('same date every year; Feb 29 clamps in common years', () {
      final r = RecurrenceRule(frequency: RecurrenceFrequency.yearly, start: d(2024, 2, 29));
      expect(s(RecurrenceEngine.between(r, d(2024, 1, 1), d(2028, 12, 31))), [
        '2024-02-29',
        '2025-02-28',
        '2026-02-28',
        '2027-02-28',
        '2028-02-29',
      ]);
    });
  });

  group('limits', () {
    test('until is inclusive', () {
      final r = RecurrenceRule(frequency: RecurrenceFrequency.daily, start: d(2026, 10, 1), until: d(2026, 10, 3));
      expect(RecurrenceEngine.between(r, d(2026, 9, 1), d(2026, 12, 1)).length, 3);
      expect(RecurrenceEngine.nextOnOrAfter(r, d(2026, 10, 4)), isNull);
    });

    test('count counts from the start even when querying later', () {
      final r = RecurrenceRule(frequency: RecurrenceFrequency.daily, start: d(2026, 10, 1), count: 5);
      expect(s(RecurrenceEngine.between(r, d(2026, 10, 4), d(2026, 12, 1))), ['2026-10-04', '2026-10-05']);
    });

    test('between respects limit and empty ranges', () {
      final r = RecurrenceRule.daily(d(2026, 1, 1));
      expect(RecurrenceEngine.between(r, d(2026, 1, 1), d(2030, 1, 1), limit: 10).length, 10);
      expect(RecurrenceEngine.between(r, d(2026, 2, 1), d(2026, 1, 1)), isEmpty);
    });

    test('matches()', () {
      final r = RecurrenceRule.daily(d(2026, 10, 1), every: 2);
      expect(RecurrenceEngine.matches(r, d(2026, 10, 3)), isTrue);
      expect(RecurrenceEngine.matches(r, d(2026, 10, 4)), isFalse);
    });

    test('rejects invalid rules', () {
      expect(() => RecurrenceRule.daily(d(2026, 1, 1), every: 0), throwsArgumentError);
      expect(() => RecurrenceRule.weekly(d(2026, 1, 1), weekdays: {8}), throwsArgumentError);
      expect(() => RecurrenceRule.monthlyOnDay(d(2026, 1, 1), 32), throwsArgumentError);
    });
  });

  group('serialisation & description', () {
    test('JSON round trip', () {
      final rules = [
        RecurrenceRule.daily(d(2026, 10, 1), every: 2),
        RecurrenceRule.weekly(d(2026, 10, 1), every: 3, weekdays: {1, 7}),
        RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          start: d(2026, 1, 1),
          monthlyMode: MonthlyMode.nthWeekday,
          weekdays: {5},
          weekOrdinal: -1,
          until: d(2027, 1, 1),
        ),
        RecurrenceRule(frequency: RecurrenceFrequency.yearly, start: d(2026, 5, 3), count: 4),
      ];
      for (final r in rules) {
        expect(RecurrenceRule.decode(r.encode()), r);
      }
    });

    test('describe', () {
      expect(RecurrenceRule.daily(d(2026, 10, 1), every: 2).describe(), 'Every 2 days');
      expect(RecurrenceRule.monthlyOnDay(d(2026, 10, 1), 25).describe(), 'Monthly on the 25th');
      expect(RecurrenceRule.weekly(d(2026, 10, 5), weekdays: {1, 4}).describe(), 'Weekly on Mon, Thu');
    });
  });

  test('performance: far-future query is fast thanks to period skipping', () {
    final r = RecurrenceRule.daily(d(1990, 1, 1));
    final sw = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      RecurrenceEngine.nextOnOrAfter(r, d(2026, 10, 4));
    }
    expect(sw.elapsedMilliseconds, lessThan(500));
  });
}
