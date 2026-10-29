// The forecast's stream dates (stream_schedule.dart): every cadence, the month-end
// clamping on 28, 30 and 31-day months and 29 February, the last-day rule for detected
// and bank streams, the semimonthly day pair, and the edge cases (unknown, ended, no
// next date, no dates at all).
import 'package:finance_tracker/features/forecast/domain/stream_schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'forecast_fixtures.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

List<LocalDate> datesOf(RecurringStream s, [LocalDate? from, LocalDate? to]) =>
    streamDates(s, from ?? d(2000, 1, 1), to ?? d(2027, 3, 31));

void main() {
  test('weekly and biweekly step 7 and 14 days from the next date', () {
    expect(
      datesOf(
        stream('w', cadence: RecurringCadence.weekly, next: d(2026, 10, 26)),
        d(2026, 10, 1),
        d(2026, 11, 16),
      ),
      [d(2026, 10, 26), d(2026, 11, 2), d(2026, 11, 9), d(2026, 11, 16)],
    );
    expect(
      datesOf(
        stream('b', cadence: RecurringCadence.biweekly, next: d(2026, 10, 30)),
        d(2026, 11, 1),
        d(2026, 12, 31),
      ),
      [d(2026, 11, 13), d(2026, 11, 27), d(2026, 12, 11), d(2026, 12, 25)],
    );
  });

  test('a far-past next date steps forward to the window', () {
    expect(
      datesOf(
        stream('w', cadence: RecurringCadence.weekly, next: d(2020, 1, 6)),
        d(2026, 10, 24),
        d(2026, 11, 3),
      ),
      [d(2026, 10, 26), d(2026, 11, 2)],
    );
    expect(
      datesOf(
        stream('m', next: d(2019, 5, 17)),
        d(2026, 10, 1),
        d(2026, 12, 31),
      ),
      [d(2026, 10, 17), d(2026, 11, 17), d(2026, 12, 17)],
    );
  });

  test('monthly on the 31st clamps from the anchor each time', () {
    expect(
      datesOf(
        stream('m', next: d(2026, 12, 31), last: d(2026, 11, 30)),
        d(2026, 12, 1),
        d(2027, 5, 31),
      ),
      [
        d(2026, 12, 31),
        d(2027, 1, 31),
        d(2027, 2, 28),
        d(2027, 3, 31),
        d(2027, 4, 30),
        d(2027, 5, 31),
      ],
    );
  });

  test('a detected stream on a month end follows every last day', () {
    final RecurringStream s = stream(
      'detected-x',
      source: RecurringSource.detected,
      next: d(2027, 2, 28),
      last: d(2027, 1, 31),
    );
    expect(datesOf(s, d(2027, 1, 1), d(2027, 6, 30)), [
      d(2027, 2, 28),
      d(2027, 3, 31),
      d(2027, 4, 30),
      d(2027, 5, 31),
      d(2027, 6, 30),
    ]);
  });

  test('a bank stream on the 28th stays on the 28th', () {
    final RecurringStream s = stream(
      'p',
      next: d(2027, 2, 28),
      last: d(2027, 1, 28),
    );
    expect(datesOf(s, d(2027, 1, 1), d(2027, 4, 30)), [
      d(2027, 2, 28),
      d(2027, 3, 28),
      d(2027, 4, 28),
    ]);
  });

  test('a bank stream on the 30th of a 30-day month stays on the 30th', () {
    expect(
      datesOf(
        stream('p', next: d(2026, 11, 30), last: d(2026, 10, 30)),
        d(2026, 11, 1),
        d(2027, 3, 31),
      ),
      [
        d(2026, 11, 30),
        d(2026, 12, 30),
        d(2027, 1, 30),
        d(2027, 2, 28),
        d(2027, 3, 30),
      ],
    );
  });

  test('a bank stream whose two dates are last days follows the last day', () {
    expect(
      datesOf(
        stream('p', next: d(2026, 11, 30), last: d(2026, 10, 31)),
        d(2026, 11, 1),
        d(2027, 2, 28),
      ),
      [d(2026, 11, 30), d(2026, 12, 31), d(2027, 1, 31), d(2027, 2, 28)],
    );
  });

  test('29 February: monthly and annual', () {
    expect(
      datesOf(
        stream(
          'detected-l',
          source: RecurringSource.detected,
          next: d(2028, 2, 29),
          last: d(2028, 1, 31),
        ),
        d(2028, 1, 1),
        d(2028, 4, 30),
      ),
      [d(2028, 2, 29), d(2028, 3, 31), d(2028, 4, 30)],
    );
    expect(
      datesOf(
        stream('p', next: d(2028, 2, 29), last: d(2028, 1, 29)),
        d(2028, 1, 1),
        d(2028, 4, 30),
      ),
      [d(2028, 2, 29), d(2028, 3, 29), d(2028, 4, 29)],
    );
    expect(
      datesOf(
        stream('a', cadence: RecurringCadence.annually, next: d(2028, 2, 29)),
        d(2028, 1, 1),
        d(2032, 12, 31),
      ),
      [
        d(2028, 2, 29),
        d(2029, 2, 28),
        d(2030, 2, 28),
        d(2031, 2, 28),
        d(2032, 2, 29),
      ],
    );
  });

  test('quarterly keeps the day every three months', () {
    expect(
      datesOf(
        stream('q', cadence: RecurringCadence.quarterly, next: d(2026, 11, 30)),
        d(2026, 10, 1),
        d(2027, 9, 30),
      ),
      [d(2026, 11, 30), d(2027, 2, 28), d(2027, 5, 30), d(2027, 8, 30)],
    );
  });

  test('semimonthly on the two days seen when 10 or more apart', () {
    final RecurringStream s = stream(
      's',
      cadence: RecurringCadence.semiMonthly,
      last: d(2026, 10, 9),
      next: d(2026, 10, 19),
    );
    expect(datesOf(s, d(2026, 10, 1), d(2026, 11, 30)), [
      d(2026, 10, 19),
      d(2026, 11, 9),
      d(2026, 11, 19),
    ]);
  });

  test('semimonthly 9 days apart pairs the next day with the day 15 away', () {
    final RecurringStream s = stream(
      's',
      cadence: RecurringCadence.semiMonthly,
      last: d(2026, 10, 10),
      next: d(2026, 10, 19),
    );
    expect(datesOf(s, d(2026, 10, 1), d(2026, 11, 30)), [
      d(2026, 10, 19),
      d(2026, 11, 4),
      d(2026, 11, 19),
    ]);
  });

  test('semimonthly on the 15th and the 30th is on the month end', () {
    final RecurringStream s = stream(
      's',
      cadence: RecurringCadence.semiMonthly,
      next: d(2027, 1, 30),
    );
    expect(datesOf(s, d(2027, 1, 1), d(2027, 3, 31)), [
      d(2027, 1, 31),
      d(2027, 2, 15),
      d(2027, 2, 28),
      d(2027, 3, 15),
      d(2027, 3, 31),
    ]);
  });

  test('a semimonthly stream on the 15th and the month end follows the month '
      'end whichever date is next', () {
    final List<LocalDate> fromOctober = [
      d(2026, 10, 15),
      d(2026, 10, 31),
      d(2026, 11, 15),
      d(2026, 11, 30),
      d(2026, 12, 15),
      d(2026, 12, 31),
    ];
    for (final RecurringSource source in [
      RecurringSource.detected,
      RecurringSource.plaid,
    ]) {
      expect(
        datesOf(
          stream(
            's',
            cadence: RecurringCadence.semiMonthly,
            source: source,
            last: d(2026, 9, 30),
            next: d(2026, 10, 15),
          ),
          d(2026, 10, 1),
          d(2026, 12, 31),
        ),
        fromOctober,
        reason: '$source',
      );
    }
    expect(
      datesOf(
        stream(
          's',
          cadence: RecurringCadence.semiMonthly,
          source: RecurringSource.detected,
          last: d(2027, 2, 28),
          next: d(2027, 3, 15),
        ),
        d(2027, 3, 1),
        d(2027, 5, 31),
      ),
      [
        d(2027, 3, 15),
        d(2027, 3, 31),
        d(2027, 4, 15),
        d(2027, 4, 30),
        d(2027, 5, 15),
        d(2027, 5, 31),
      ],
    );
    expect(
      datesOf(
        stream(
          's',
          cadence: RecurringCadence.semiMonthly,
          last: d(2026, 10, 15),
          next: d(2026, 10, 30),
        ),
        d(2026, 10, 1),
        d(2026, 11, 30),
      ),
      [d(2026, 10, 31), d(2026, 11, 15), d(2026, 11, 30)],
    );
  });

  test('a semimonthly stream on the 1st and the 15th is unchanged', () {
    expect(
      datesOf(
        stream(
          's',
          cadence: RecurringCadence.semiMonthly,
          last: d(2026, 10, 1),
          next: d(2026, 10, 15),
        ),
        d(2026, 10, 1),
        d(2027, 2, 28),
      ),
      [
        d(2026, 10, 15),
        d(2026, 11, 1),
        d(2026, 11, 15),
        d(2026, 12, 1),
        d(2026, 12, 15),
        d(2027, 1, 1),
        d(2027, 1, 15),
        d(2027, 2, 1),
        d(2027, 2, 15),
      ],
    );
  });

  test('an unknown cadence is its next date once', () {
    final RecurringStream s = stream(
      'u',
      cadence: RecurringCadence.unknown,
      next: d(2026, 11, 2),
      last: d(2026, 9, 1),
    );
    expect(datesOf(s), [d(2026, 11, 2)]);
    expect(datesOf(s, d(2026, 11, 3)), isEmpty);
    expect(
      datesOf(
        stream('u', cadence: RecurringCadence.unknown, last: d(2026, 9, 1)),
      ),
      isEmpty,
    );
  });

  test('an ended stream has no dates', () {
    expect(
      datesOf(stream('e', next: d(2026, 11, 1), status: RecurringStatus.ended)),
      isEmpty,
    );
  });

  test('with no next date the series steps from the last one', () {
    expect(
      datesOf(
        stream('n', last: d(2026, 10, 1)),
        d(2026, 10, 1),
        d(2026, 12, 31),
      ),
      [d(2026, 11, 1), d(2026, 12, 1)],
    );
    expect(
      datesOf(
        stream('n', cadence: RecurringCadence.weekly, last: d(2026, 10, 20)),
        d(2026, 10, 20),
        d(2026, 11, 3),
      ),
      [d(2026, 10, 27), d(2026, 11, 3)],
    );
  });

  test('with neither date there is nothing', () {
    expect(datesOf(stream('x')), isEmpty);
  });

  test(
    'the window is inclusive at both ends and nothing precedes the next date',
    () {
      final RecurringStream s = stream('m', next: d(2026, 11, 1));
      expect(datesOf(s, d(2026, 11, 1), d(2026, 12, 1)), [
        d(2026, 11, 1),
        d(2026, 12, 1),
      ]);
      expect(datesOf(s, d(2026, 9, 1), d(2026, 10, 31)), isEmpty);
      expect(datesOf(s, d(2026, 12, 2), d(2026, 12, 1)), isEmpty);
    },
  );
}
