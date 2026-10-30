// The weekly summary's in-app notice: raised on the first day of a week the watcher
// runs, about the week before, recorded in app_meta, not raised again that week, and
// raised again the next week; never for a week before the install day's week, so a
// fresh install waits for the next Monday; with no install date (the demo), the day the
// watcher first runs is the install day.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/reports/application/weekly_summary_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

// A clock a test moves forward.
final class _MovableClock implements Clock {
  _MovableClock(DateTime utc) : _clock = FixedClock(utc, tz.UTC);

  Clock _clock;

  set now(DateTime utc) => _clock = FixedClock(utc, tz.UTC);

  @override
  DateTime nowUtc() => _clock.nowUtc();

  @override
  DateTime todayLocalMidnight() => _clock.todayLocalMidnight();

  @override
  LocalDate today() => _clock.today();

  @override
  tz.Location get location => _clock.location;
}

ProviderContainer container(AppMetaStore meta, DateTime now, {Clock? clock}) {
  final ProviderContainer c = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.demo()),
      clockProvider.overrideWithValue(clock ?? FixedClock(now, tz.UTC)),
      appMetaStoreProvider.overrideWithValue(meta),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> settle() async {
  // The notice is raised after a few store reads and a write.
  for (int i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<WeeklySummaryNotification> notices(ProviderContainer c) => [
  for (final InAppNotification n in c.read(inAppNotificationsProvider))
    if (n.notification case final WeeklySummaryNotification w) w,
];

Future<List<WeeklySummaryNotification>> run(ProviderContainer c) async {
  final ProviderSubscription<void> sub = c.listen(
    weeklySummaryNoticeProvider,
    (_, _) {},
  );
  addTearDown(sub.close);
  await settle();
  return notices(c);
}

Future<AppMetaStore> installedOn(String day) async {
  final AppMetaStore meta = InMemoryAppMetaStore();
  await meta.write(AppMetaKeys.installDate, day);
  return meta;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('raised once a week, about the week before', () async {
    final AppMetaStore meta = await installedOn('2026-09-01');
    // Wednesday 21 October 2026.
    final List<WeeklySummaryNotification> first = await run(
      container(meta, DateTime.utc(2026, 10, 21, 9)),
    );
    expect(first.single.weekStart, LocalDate(2026, 10, 12));
    expect(first.single.key, 'weekly/2026-10-12');
    expect(await meta.read(AppMetaKeys.weeklySummaryRaised), '2026-10-19');

    // Later the same week: nothing new.
    expect(await run(container(meta, DateTime.utc(2026, 10, 25, 20))), isEmpty);

    // The next Monday: the week of the 19th.
    final List<WeeklySummaryNotification> next = await run(
      container(meta, DateTime.utc(2026, 10, 26, 8)),
    );
    expect(next.single.weekStart, LocalDate(2026, 10, 19));
    expect(await meta.read(AppMetaKeys.weeklySummaryRaised), '2026-10-26');
  });

  test('a fresh install waits for the next Monday', () async {
    // Installed on Wednesday 21 October.
    final AppMetaStore meta = await installedOn('2026-10-21');
    expect(await run(container(meta, DateTime.utc(2026, 10, 21, 9))), isEmpty);
    expect(await meta.read(AppMetaKeys.weeklySummaryRaised), isNull);

    // Monday 26 October: the install week is summarised.
    final List<WeeklySummaryNotification> next = await run(
      container(meta, DateTime.utc(2026, 10, 26, 8)),
    );
    expect(next.single.weekStart, LocalDate(2026, 10, 19));
  });

  test(
    'installed on a Monday, that week is summarised the Monday after',
    () async {
      final AppMetaStore meta = await installedOn('2026-10-19');
      expect(
        await run(container(meta, DateTime.utc(2026, 10, 19, 9))),
        isEmpty,
      );
      expect(
        (await run(container(meta, DateTime.utc(2026, 10, 26, 9))))
            .single
            .weekStart,
        LocalDate(2026, 10, 19),
      );
    },
  );

  test(
    'with no install date, the first day it runs is the install day',
    () async {
      final AppMetaStore meta = InMemoryAppMetaStore();
      final _MovableClock clock = _MovableClock(DateTime.utc(2026, 10, 21, 9));
      final ProviderContainer c = container(
        meta,
        DateTime.utc(2026, 10, 21, 9),
        clock: clock,
      );
      expect(await run(c), isEmpty);

      // The same running app reaches the next Monday.
      clock.now = DateTime.utc(2026, 10, 26, 9);
      c.invalidate(todayProvider);
      c.read(todayProvider);
      await settle();
      expect(notices(c).single.weekStart, LocalDate(2026, 10, 19));
    },
  );
}
