// The anomaly providers over the in-memory repositories: the flags in a window, a
// recurring stream's members left out, and a dismissal kept in app_meta that hides the
// flag until it is restored.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/reports/application/anomaly_providers.dart';
import 'package:finance_tracker/features/reports/domain/anomalies.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

final Clock clock = FixedClock(DateTime.utc(2026, 4, 24, 15), tz.UTC);
final LocalDateRange april = LocalDateRange(
  LocalDate(2026, 4, 1),
  LocalDate(2026, 5, 1),
);

Transaction txn(String id, int minor, LocalDate date, {String? merchant}) =>
    Transaction(
      id: id,
      accountId: 'checking',
      amount: Money(minor, 'USD'),
      date: date,
      pending: false,
      name: merchant ?? 'Corner Deli',
      merchantName: merchant ?? 'Corner Deli',
      plaidDetailedCategory: 'FOOD_AND_DRINK_RESTAURANT',
      source: DataSource.manual,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      syncVersion: 0,
    );

InMemoryStore store() => InMemoryStore(clock)
  ..seedSystemCategories()
  ..upsertAccount(
    const Account(
      id: 'checking',
      type: AccountType.depository,
      name: 'Checking',
      currencyCode: 'USD',
      isHidden: false,
      displayOrder: 0,
    ),
  )
  ..upsertTransactions([
    txn('gas', -100, LocalDate(2025, 1, 2), merchant: 'Gas Stop'),
    for (int i = 0; i < 6; i++)
      txn('deli$i', -1000 - i * 100, LocalDate(2026, 3, 5 + i)),
    txn('big', -6000, LocalDate(2026, 4, 2)),
    txn('guitar', -45000, LocalDate(2026, 4, 20), merchant: 'Guitar Center'),
  ]);

Future<List<String>> flagged(ProviderContainer c) async {
  final ProviderSubscription<AsyncValue<List<AnomalyFlag>>> sub = c.listen(
    anomaliesProvider(april),
    (_, _) {},
  );
  addTearDown(sub.close);
  return [
    for (final AnomalyFlag f in await c.read(anomaliesProvider(april).future))
      f.transactionId,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppMetaStore meta;
  late ProviderContainer c;
  setUp(() {
    meta = InMemoryAppMetaStore();
    c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.demo()),
        clockProvider.overrideWithValue(clock),
        inMemoryStoreProvider.overrideWithValue(store()),
        appMetaStoreProvider.overrideWithValue(meta),
      ],
    );
    addTearDown(c.dispose);
  });

  test('the flags in the window', () async {
    expect(await flagged(c), ['big', 'guitar']);
  });

  test('a recurring stream\'s members are not flagged', () async {
    await c.read(recurringStreamRepositoryProvider).applyPlaid([
      RecurringStream(
        id: 'guitar-lessons',
        accountId: 'checking',
        merchantName: 'Guitar Center',
        cadence: RecurringCadence.monthly,
        averageAmount: Money(-45000, 'USD'),
        status: RecurringStatus.active,
        isSubscription: false,
        source: RecurringSource.demo,
        transactionIds: const ['guitar'],
      ),
    ]);
    expect(await flagged(c), ['big']);
  });

  test('a dismissal is kept on this device until restored', () async {
    expect(await flagged(c), ['big', 'guitar']);
    await c.read(dismissedAnomaliesProvider.notifier).dismiss('big');
    expect(await flagged(c), ['guitar']);
    expect(await meta.read(AppMetaKeys.dismissedAnomalies), '["big"]');

    await c.read(dismissedAnomaliesProvider.notifier).restore('big');
    expect(await flagged(c), ['big', 'guitar']);
    expect(await meta.read(AppMetaKeys.dismissedAnomalies), '[]');
  });
}
