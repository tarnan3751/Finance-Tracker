// FixedClock and SystemClock: "today" is the local date in the clock's zone, not the UTC
// date, and a day whose midnight DST skips still has a start.
import 'package:finance_tracker/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('today is the local date when the UTC date is already tomorrow', () {
    final tz.Location newYork = tz.getLocation('America/New_York');
    // 02:30 UTC on 2 March is 21:30 on 1 March in New York (EST, UTC-5).
    final FixedClock clock = FixedClock(
      DateTime.utc(2026, 3, 2, 2, 30),
      newYork,
    );

    final DateTime today = clock.todayLocalMidnight();

    expect(today, isA<tz.TZDateTime>());
    expect((today as tz.TZDateTime).location, newYork);
    expect([today.year, today.month, today.day], [2026, 3, 1]);
    expect([today.hour, today.minute], [0, 0]);
    expect(today.toUtc(), DateTime.utc(2026, 3, 1, 5));
    expect(clock.nowUtc(), DateTime.utc(2026, 3, 2, 2, 30));
  });

  test('today is the local date when the UTC date is still yesterday', () {
    final tz.Location tokyo = tz.getLocation('Asia/Tokyo');
    // 20:00 UTC on 31 December is 05:00 on 1 January in Tokyo.
    final FixedClock clock = FixedClock(DateTime.utc(2026, 12, 31, 20), tokyo);

    final DateTime today = clock.todayLocalMidnight();

    expect([today.year, today.month, today.day], [2027, 1, 1]);
    expect(today.toUtc(), DateTime.utc(2026, 12, 31, 15));
  });

  test('a local instant is converted to UTC', () {
    final FixedClock clock = FixedClock(
      DateTime.utc(2026, 6, 1, 12).toLocal(),
      tz.UTC,
    );
    expect(clock.nowUtc().isUtc, isTrue);
    expect(clock.nowUtc(), DateTime.utc(2026, 6, 1, 12));
  });

  test('nowUtc is UTC truncated to milliseconds', () {
    final FixedClock fixed = FixedClock(
      DateTime.utc(2026, 6, 1, 12, 0, 0, 123, 456),
      tz.UTC,
    );
    expect(fixed.nowUtc().isUtc, isTrue);
    expect(fixed.nowUtc().microsecond, 0);
    expect(fixed.nowUtc(), DateTime.utc(2026, 6, 1, 12, 0, 0, 123));

    for (int i = 0; i < 100; i++) {
      final DateTime now = const SystemClock().nowUtc();
      expect(now.isUtc, isTrue);
      expect(now.microsecond, 0);
    }
  });

  test('on a DST start day the day still starts at local midnight', () {
    final tz.Location newYork = tz.getLocation('America/New_York');
    // DST starts at 02:00 on 8 March 2026 in New York; 18:00 UTC is 14:00 EDT.
    final FixedClock clock = FixedClock(DateTime.utc(2026, 3, 8, 18), newYork);

    final DateTime today = clock.todayLocalMidnight();

    expect([today.day, today.hour], [8, 0]);
    expect(today.toUtc(), DateTime.utc(2026, 3, 8, 5));
    expect(clock.nowUtc().difference(today), const Duration(hours: 13));
  });

  test(
    'on a day whose midnight DST skips, the day starts at the first instant',
    () {
      // Asia/Beirut moved its clocks from 00:00 to 01:00 on 29 March 2026.
      final tz.Location beirut = tz.getLocation('Asia/Beirut');
      final FixedClock clock = FixedClock(
        DateTime.utc(2026, 3, 29, 10),
        beirut,
      );

      final tz.TZDateTime today = clock.todayLocalMidnight() as tz.TZDateTime;

      expect(today.day, 29);
      expect(today.toUtc(), DateTime.utc(2026, 3, 28, 22));
    },
  );

  test('SystemClock reads tz.local and today is at or before now', () {
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));
    addTearDown(() => tz.setLocalLocation(tz.UTC));
    const SystemClock clock = SystemClock();

    expect(clock.location.name, 'Europe/Paris');
    final DateTime now = clock.nowUtc();
    expect(now.isUtc, isTrue);
    final DateTime today = clock.todayLocalMidnight();
    expect(today.isAfter(now), isFalse);
    expect(now.difference(today), lessThan(const Duration(hours: 25)));
  });

  group('today', () {
    tz.Location newYork() => tz.getLocation('America/New_York');

    test('is the local date either side of the spring DST change', () {
      // DST starts at 02:00 EST on 8 March 2026: 04:59 UTC is 23:59 on 7 March (EST),
      // 05:01 UTC is 00:01 on 8 March, and 07:30 UTC is 03:30 EDT on 8 March.
      expect(
        FixedClock(DateTime.utc(2026, 3, 8, 4, 59), newYork()).today(),
        LocalDate(2026, 3, 7),
      );
      expect(
        FixedClock(DateTime.utc(2026, 3, 8, 5, 1), newYork()).today(),
        LocalDate(2026, 3, 8),
      );
      expect(
        FixedClock(DateTime.utc(2026, 3, 8, 7, 30), newYork()).today(),
        LocalDate(2026, 3, 8),
      );
    });

    test('is the local date either side of the autumn DST change', () {
      // DST ends at 02:00 EDT on 1 November 2026: 03:59 UTC is 23:59 on 31 October
      // (EDT), and 05:30 UTC is 01:30 EDT, 06:30 UTC is 01:30 EST, both on 1 November.
      expect(
        FixedClock(DateTime.utc(2026, 11, 1, 3, 59), newYork()).today(),
        LocalDate(2026, 10, 31),
      );
      expect(
        FixedClock(DateTime.utc(2026, 11, 1, 5, 30), newYork()).today(),
        LocalDate(2026, 11, 1),
      );
      expect(
        FixedClock(DateTime.utc(2026, 11, 1, 6, 30), newYork()).today(),
        LocalDate(2026, 11, 1),
      );
    });

    test('follows a zone change at the same instant', () {
      // 06:00 UTC on 24 October is 15:00 that day in Tokyo (UTC+9) and still 23:00 on
      // 23 October in Los Angeles (PDT, UTC-7).
      final DateTime instant = DateTime.utc(2026, 10, 24, 6);
      expect(
        FixedClock(instant, tz.getLocation('Asia/Tokyo')).today(),
        LocalDate(2026, 10, 24),
      );
      expect(
        FixedClock(instant, tz.getLocation('America/Los_Angeles')).today(),
        LocalDate(2026, 10, 23),
      );
    });

    test('SystemClock follows tz.local when the zone changes', () {
      addTearDown(() => tz.setLocalLocation(tz.UTC));
      const SystemClock clock = SystemClock();
      tz.setLocalLocation(tz.getLocation('Pacific/Kiritimati')); // UTC+14
      final LocalDate east = clock.today();
      tz.setLocalLocation(tz.getLocation('Pacific/Pago_Pago')); // UTC-11
      final LocalDate west = clock.today();

      // 25 hours apart: the dates differ by one day, or by two around midnight UTC
      // (the reads are a moment apart).
      expect(west.daysUntil(east), inInclusiveRange(1, 2));
      expect(
        clock.todayLocalMidnight(),
        tz.TZDateTime(tz.local, west.year, west.month, west.day),
      );
    });
  });
}
