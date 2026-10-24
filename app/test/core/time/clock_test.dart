// FixedClock and SystemClock: "today" is the local date in the clock's zone, not the UTC
// date, and a day whose midnight DST skips still has a start.
import 'package:finance_tracker/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
