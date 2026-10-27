// The occurrences of a bill for every cadence, across month ends, February and leap
// years, and the first-due-date floor.
import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

void main() {
  group('between', () {
    test('a one-off is its date once', () {
      final BillSchedule s = BillSchedule(d(2026, 11, 3), null);
      expect(s.between(d(2026, 1, 1), d(2027, 1, 1)), [d(2026, 11, 3)]);
      expect(s.between(d(2026, 11, 4), d(2027, 1, 1)), isEmpty);
      expect(
        BillSchedule(
          d(2026, 11, 3),
          RecurringCadence.unknown,
        ).between(d(2026, 1, 1), d(2027, 1, 1)),
        [d(2026, 11, 3)],
      );
    });

    test('weekly and biweekly step 7 and 14 days across the year end', () {
      expect(
        BillSchedule(
          d(2026, 12, 18),
          RecurringCadence.weekly,
        ).between(d(2026, 12, 20), d(2027, 1, 10)),
        [d(2026, 12, 25), d(2027, 1, 1), d(2027, 1, 8)],
      );
      expect(
        BillSchedule(
          d(2026, 12, 18),
          RecurringCadence.biweekly,
        ).between(d(2026, 12, 18), d(2027, 1, 30)),
        [d(2026, 12, 18), d(2027, 1, 1), d(2027, 1, 15), d(2027, 1, 29)],
      );
    });

    test('monthly keeps the anchor day, clamped to short months', () {
      expect(
        BillSchedule(
          d(2027, 1, 31),
          RecurringCadence.monthly,
        ).between(d(2027, 1, 1), d(2027, 6, 1)),
        [
          d(2027, 1, 31),
          d(2027, 2, 28),
          d(2027, 3, 31),
          d(2027, 4, 30),
          d(2027, 5, 31),
        ],
      );
      expect(
        BillSchedule(
          d(2028, 1, 30),
          RecurringCadence.monthly,
        ).between(d(2028, 2, 1), d(2028, 3, 31)),
        [d(2028, 2, 29), d(2028, 3, 30)],
      );
    });

    test('quarterly keeps the day every three months', () {
      expect(
        BillSchedule(
          d(2026, 11, 30),
          RecurringCadence.quarterly,
        ).between(d(2026, 1, 1), d(2027, 12, 1)),
        [
          d(2026, 11, 30),
          d(2027, 2, 28),
          d(2027, 5, 30),
          d(2027, 8, 30),
          d(2027, 11, 30),
        ],
      );
    });

    test('annually keeps the day, February 29 clamped in common years', () {
      expect(
        BillSchedule(
          d(2028, 2, 29),
          RecurringCadence.annually,
        ).between(d(2028, 1, 1), d(2033, 1, 1)),
        [
          d(2028, 2, 29),
          d(2029, 2, 28),
          d(2030, 2, 28),
          d(2031, 2, 28),
          d(2032, 2, 29),
        ],
      );
    });

    test('semimonthly runs on the anchor day and 15 days away', () {
      expect(
        BillSchedule(
          d(2027, 1, 1),
          RecurringCadence.semiMonthly,
        ).between(d(2027, 1, 1), d(2027, 3, 1)),
        [d(2027, 1, 1), d(2027, 1, 16), d(2027, 2, 1), d(2027, 2, 16)],
      );
      expect(
        BillSchedule(
          d(2027, 1, 15),
          RecurringCadence.semiMonthly,
        ).between(d(2027, 1, 1), d(2027, 3, 1)),
        [d(2027, 1, 15), d(2027, 1, 30), d(2027, 2, 15), d(2027, 2, 28)],
      );
      // An anchor after the 15th: its first half-month day is in the next month.
      expect(
        BillSchedule(
          d(2027, 1, 31),
          RecurringCadence.semiMonthly,
        ).between(d(2027, 1, 1), d(2027, 3, 1)),
        [d(2027, 1, 31), d(2027, 2, 16), d(2027, 2, 28)],
      );
    });

    test('nothing falls before the first due date', () {
      final BillSchedule s = BillSchedule(
        d(2027, 3, 28),
        RecurringCadence.monthly,
        first: d(2027, 2, 1),
      );
      expect(s.between(d(2026, 1, 1), d(2027, 5, 1)), [
        d(2027, 2, 28),
        d(2027, 3, 28),
        d(2027, 4, 28),
      ]);
    });

    test('an empty or reversed range has no occurrences', () {
      final BillSchedule s = BillSchedule(
        d(2027, 1, 1),
        RecurringCadence.weekly,
      );
      expect(s.between(d(2027, 2, 1), d(2027, 2, 1)), isEmpty);
      expect(s.between(d(2027, 2, 2), d(2027, 2, 1)), isEmpty);
    });
  });

  group('next and previous', () {
    test('find the neighbours of a day, the day itself counting as next', () {
      final BillSchedule s = BillSchedule(
        d(2027, 1, 15),
        RecurringCadence.monthly,
      );
      expect(s.nextOnOrAfter(d(2027, 3, 15)), d(2027, 3, 15));
      expect(s.previousBefore(d(2027, 3, 15)), d(2027, 2, 15));
      expect(s.nextOnOrAfter(d(2027, 3, 16)), d(2027, 4, 15));
      expect(s.previousBefore(d(2027, 1, 15)), isNull);
    });

    test('an annual bill finds its neighbours a year away', () {
      final BillSchedule s = BillSchedule(
        d(2027, 1, 2),
        RecurringCadence.annually,
      );
      expect(s.nextOnOrAfter(d(2027, 1, 3)), d(2028, 1, 2));
      expect(s.previousBefore(d(2028, 1, 1)), d(2027, 1, 2));
    });

    test('a past one-off has no next', () {
      expect(
        BillSchedule(d(2027, 1, 2), null).nextOnOrAfter(d(2027, 1, 3)),
        isNull,
      );
    });

    test('a one-off years past is the previous occurrence, not a lost one', () {
      final BillSchedule s = BillSchedule(d(2024, 3, 1), null);
      expect(s.previousBefore(d(2027, 3, 10)), d(2024, 3, 1));
      expect(s.nextOnOrAfter(d(2027, 3, 10)), isNull);
      expect(s.nextOnOrAfter(d(2020, 1, 1)), d(2024, 3, 1));
    });

    test('an annual bill first due 15 months ahead has that next date', () {
      final BillSchedule s = BillSchedule(
        d(2028, 6, 15),
        RecurringCadence.annually,
      );
      expect(s.nextOnOrAfter(d(2027, 3, 10)), d(2028, 6, 15));
      expect(s.previousBefore(d(2027, 3, 10)), isNull);
      expect(s.previousBefore(d(2031, 1, 1)), d(2030, 6, 15));
    });

    test('a followed liability\'s date is an occurrence, even before the bill\'s own', () {
      final BillReminder once = BillReminder(id: 'b', dueDate: d(2026, 12, 1));
      final BillSchedule s = BillSchedule.of(
        once,
        liabilityDue: d(2026, 11, 25),
      );
      expect(s.between(d(2026, 1, 1), d(2028, 1, 1)), [d(2026, 11, 25)]);
      expect(s.nextOnOrAfter(d(2026, 11, 1)), d(2026, 11, 25));
      final BillSchedule monthly = BillSchedule.of(
        once.copyWith(cadence: RecurringCadence.monthly),
        liabilityDue: d(2026, 11, 25),
      );
      expect(monthly.previousBefore(d(2026, 11, 1)), d(2026, 10, 25));
      expect(monthly.previousBefore(d(2026, 8, 1)), d(2026, 7, 25));
    });

    test('a liability due date re-anchors the series', () {
      final BillReminder bill = BillReminder(
        id: 'b',
        dueDate: d(2026, 9, 28),
        cadence: RecurringCadence.monthly,
      );
      final BillSchedule s = BillSchedule.of(
        bill,
        liabilityDue: d(2026, 11, 25),
      );
      expect(s.nextOnOrAfter(d(2026, 11, 1)), d(2026, 11, 25));
      expect(s.previousBefore(d(2026, 11, 1)), d(2026, 10, 25));
    });
  });
}
