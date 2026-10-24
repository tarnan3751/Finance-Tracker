// todayProvider: the clock's local date, moved on by a timer at the next local midnight
// in the clock's zone (rescheduled after it fires) and re-read when the app resumes.
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A clock the test moves by hand, in [location].
final class _MovableClock implements Clock {
  _MovableClock(this.utc, this.location);

  DateTime utc;

  @override
  final tz.Location location;

  @override
  DateTime nowUtc() => utc;

  @override
  DateTime todayLocalMidnight() {
    final tz.TZDateTime local = tz.TZDateTime.from(utc, location);
    return tz.TZDateTime(location, local.year, local.month, local.day);
  }

  @override
  LocalDate today() => LocalDate.fromDateTime(todayLocalMidnight());
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('the delay to midnight is local, across a DST change', () {
    final tz.Location newYork = tz.getLocation('America/New_York');
    // 8 March 2026, 01:30 EST: midnight is 22.5 hours away, the day being 23 hours long.
    expect(
      untilNextLocalMidnight(
        _MovableClock(DateTime.utc(2026, 3, 8, 6, 30), newYork),
      ),
      const Duration(hours: 21, minutes: 30),
    );
    expect(
      untilNextLocalMidnight(
        _MovableClock(DateTime.utc(2026, 3, 8, 4, 30), newYork),
      ),
      const Duration(minutes: 30),
    );
  });

  testWidgets('moves on at local midnight, and again the next night', (
    tester,
  ) async {
    final _MovableClock clock = _MovableClock(
      // 7 March 2026, 23:59 in New York (UTC-5).
      DateTime.utc(2026, 3, 8, 4, 59),
      tz.getLocation('America/New_York'),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(clock)],
    );
    addTearDown(container.dispose);
    final List<LocalDate> seen = [];
    container.listen(
      todayProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );

    clock.utc = DateTime.utc(2026, 3, 8, 5);
    await tester.pump(const Duration(minutes: 1));
    clock.utc = DateTime.utc(2026, 3, 9, 4);
    // The next midnight is 23 hours on (the clocks go forward on the 8th).
    await tester.pump(const Duration(hours: 23));

    expect(seen, [
      LocalDate(2026, 3, 7),
      LocalDate(2026, 3, 8),
      LocalDate(2026, 3, 9),
    ]);
    // Disposing cancels the next night's timer, which the test must not leave pending.
    container.dispose();
  });

  testWidgets('re-reads the date when the app resumes', (tester) async {
    final _MovableClock clock = _MovableClock(
      DateTime.utc(2026, 10, 24, 15),
      tz.UTC,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(clock)],
    );
    addTearDown(container.dispose);
    expect(container.read(todayProvider), LocalDate(2026, 10, 24));

    // The device slept through midnight: no timer has fired yet.
    clock.utc = DateTime.utc(2026, 10, 25, 7);
    for (final AppLifecycleState state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }

    expect(container.read(todayProvider), LocalDate(2026, 10, 25));
    container.dispose();
  });
}
