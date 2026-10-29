// A household for the reports' screen tests, on testClock's today, Saturday 24 October
// 2026: Everyday Checking (USD) with fourteen months of history from August 2025. Each
// month: a salary on the 1st, the rent on the 2nd, groceries at Safeway on the 5th,
// 12th and 19th, a restaurant meal and a coffee; a transfer to savings on the 15th. In
// October a restaurant meal at Olive Garden is far above its usual, and Guitar Center
// is a merchant new to the household: the two anomalies.
//
//   await pumpApp(tester, overrides: reportOverrides(), initialLocation: '/reports');
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_models/shared_models.dart';

import 'pump_app.dart';
import 'seed.dart';
import 'test_seed.dart';

/// The household's checking account.
const String reportCheckingId = 'report-checking';

/// The October meal far above Olive Garden's usual.
const String reportUnusualId = 'report-olive-garden-oct';

/// The first purchase at Guitar Center.
const String reportNewMerchantId = 'report-guitar-center';

Transaction _entry(
  String id,
  int cents,
  LocalDate date,
  String merchant,
  String code,
) => Transaction(
  id: id,
  accountId: reportCheckingId,
  amount: Money(cents, 'USD'),
  date: date,
  pending: false,
  name: merchant,
  merchantName: merchant,
  plaidDetailedCategory: code,
  source: DataSource.manual,
  createdAt: testClock.nowUtc(),
  updatedAt: testClock.nowUtc(),
  syncVersion: 0,
);

/// The household's store, with the system categories.
InMemoryStore reportStore() {
  final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
  store
    ..upsertAccount(
      const Account(
        id: reportCheckingId,
        type: AccountType.depository,
        name: 'Everyday Checking',
        currencyCode: 'USD',
        isHidden: false,
        displayOrder: 0,
      ),
    )
    ..upsertTransactions([
      for (int m = 0; m < 15; m++)
        ...() {
          final LocalDate month = LocalDate(2025, 8, 1).addMonths(m);
          LocalDate on(int day) => LocalDate(month.year, month.month, day);
          final String key = '${month.year}-${month.month}';
          final bool october = month == LocalDate(2026, 10, 1);
          return [
            _entry(
              'salary-$key',
              420000 + (m % 3) * 5000,
              on(1),
              'Acme Payroll',
              'INCOME_SALARY',
            ),
            _entry(
              'rent-$key',
              -165000,
              on(2),
              'Parkside Lofts',
              'RENT_AND_UTILITIES_RENT',
            ),
            for (final (int day, int cents) in [
              (5, -8200),
              (12, -9100),
              (19, -7600),
            ])
              _entry(
                'safeway-$key-$day',
                cents - (m % 4) * 300,
                on(day),
                'Safeway',
                'FOOD_AND_DRINK_GROCERIES',
              ),
            if (!october)
              _entry(
                'olive-garden-$key',
                -4200 - (m % 5) * 150,
                on(9),
                'Olive Garden',
                'FOOD_AND_DRINK_RESTAURANT',
              ),
            _entry(
              'coffee-$key',
              -550 - (m % 2) * 50,
              on(10),
              'Blue Bottle Coffee',
              'FOOD_AND_DRINK_COFFEE',
            ),
            _entry(
              'savings-$key',
              -50000,
              on(15),
              'Savings',
              'TRANSFER_OUT_SAVINGS',
            ),
          ];
        }(),
      _entry(
        reportUnusualId,
        -21500,
        LocalDate(2026, 10, 9),
        'Olive Garden',
        'FOOD_AND_DRINK_RESTAURANT',
      ),
      _entry(
        reportNewMerchantId,
        -38900,
        LocalDate(2026, 10, 17),
        'Guitar Center',
        'ENTERTAINMENT_MUSIC_AND_AUDIO',
      ),
    ]);
  return store;
}

/// The household's store ([reportStore] by default).
List<Override> reportOverrides({InMemoryStore? store}) => [
  storeOverride(store ?? reportStore()),
];
