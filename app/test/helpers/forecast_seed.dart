// A household for the forecast's screen tests, on testClock's today, Saturday 24 October
// 2026: Everyday Checking (USD, derived from its transactions), a hidden Rainy Day savings
// account, a euro account, and a card, which the forecast never offers. The checking
// account has a biweekly payroll whose four members vary (so the band shows), a monthly
// rent on the 1st, a Netflix subscription and some everyday spending for
// the allowance. The forecast screen has no route, so forecastRouter puts ForecastScreen
// at a router's root; forecastSheetRouter shows the account sheet alone.
//
//   await pumpApp(tester, overrides: forecastOverrides(), router: forecastRouter);
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_accounts_sheet.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_screen.dart';
import 'package:finance_tracker/features/recurring/data/in_memory_recurring_stream_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import 'pump_app.dart';
import 'seed.dart';
import 'test_seed.dart';

/// The household's checking account.
const String forecastCheckingId = 'forecast-checking';

Account _account(
  String id,
  String name, {
  AccountType type = AccountType.depository,
  String currency = 'USD',
  bool hidden = false,
  required int order,
}) => Account(
  id: id,
  type: type,
  name: name,
  currencyCode: currency,
  isHidden: hidden,
  displayOrder: order,
);

Transaction _entry(
  String id,
  int cents,
  LocalDate date, {
  String account = forecastCheckingId,
  String currency = 'USD',
}) => Transaction(
  id: id,
  accountId: account,
  amount: Money(cents, currency),
  date: date,
  pending: false,
  name: id,
  source: DataSource.manual,
  createdAt: testClock.nowUtc(),
  updatedAt: testClock.nowUtc(),
  syncVersion: 0,
);

/// The household's store, with the system categories.
InMemoryStore forecastStore() {
  final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
  store
    ..upsertAccount(_account(forecastCheckingId, 'Everyday Checking', order: 0))
    ..upsertAccount(
      _account('forecast-rainy-day', 'Rainy Day', hidden: true, order: 1),
    )
    ..upsertAccount(
      _account('forecast-euro', 'Euro Account', currency: 'EUR', order: 2),
    )
    ..upsertAccount(
      _account('forecast-card', 'Card', type: AccountType.credit, order: 3),
    )
    ..upsertTransactions([
      _entry('opening', 120000, LocalDate(2026, 9, 1)),
      _entry('pay-1', 225000, LocalDate(2026, 9, 11)),
      _entry('pay-2', 185000, LocalDate(2026, 9, 25)),
      _entry('pay-3', 205000, LocalDate(2026, 10, 9)),
      _entry('pay-4', 170000, LocalDate(2026, 10, 23)),
      _entry('rent-oct', -165000, LocalDate(2026, 10, 1)),
      _entry('netflix-oct', -1549, LocalDate(2026, 10, 3)),
      for (int i = 0; i < 18; i++)
        _entry(
          'spend-$i',
          -(2500 + 700 * (i % 5)),
          LocalDate(2026, 8, 1).addDays(i * 4 + 1),
        ),
      _entry(
        'rainy',
        500000,
        LocalDate(2026, 9, 1),
        account: 'forecast-rainy-day',
      ),
      _entry(
        'euro',
        80000,
        LocalDate(2026, 9, 1),
        account: 'forecast-euro',
        currency: 'EUR',
      ),
    ]);
  return store;
}

RecurringStream _stream(
  String id,
  String name,
  RecurringCadence cadence,
  int cents, {
  required LocalDate last,
  required LocalDate next,
  List<String> members = const [],
}) => RecurringStream(
  id: id,
  accountId: forecastCheckingId,
  merchantName: name,
  cadence: cadence,
  averageAmount: Money(cents, 'USD'),
  lastExpected: last,
  nextExpected: next,
  status: RecurringStatus.active,
  isSubscription: false,
  source: RecurringSource.demo,
  transactionIds: members,
);

/// The household's streams: the payroll, the rent and Netflix.
InMemoryRecurringStreamRepository forecastStreams() =>
    InMemoryRecurringStreamRepository(
      testClock,
      recorder: const NoChangeRecorder(),
      initial: [
        _stream(
          'forecast-payroll',
          'Acme Payroll',
          RecurringCadence.biweekly,
          200000,
          last: LocalDate(2026, 10, 23),
          next: LocalDate(2026, 11, 6),
          members: const ['pay-1', 'pay-2', 'pay-3', 'pay-4'],
        ),
        _stream(
          'forecast-rent',
          'Oakwood Apartments',
          RecurringCadence.monthly,
          -165000,
          last: LocalDate(2026, 10, 1),
          next: LocalDate(2026, 11, 1),
          members: const ['rent-oct'],
        ),
        _stream(
          'forecast-netflix',
          'Netflix',
          RecurringCadence.monthly,
          -1549,
          last: LocalDate(2026, 10, 3),
          next: LocalDate(2026, 11, 3),
          members: const ['netflix-oct'],
        ),
      ],
    );

/// The household's store ([forecastStore] by default) and streams.
List<Override> forecastOverrides({InMemoryStore? store}) => [
  storeOverride(store ?? forecastStore()),
  recurringStreamRepositoryProvider.overrideWithValue(forecastStreams()),
];

/// A router with the forecast's account sheet as its root page's body, disposed with
/// [ref]: for the sheet's goldens, where the modal sheet would open on the golden
/// harness's own root navigator, outside the app.
GoRouter forecastSheetRouter(Ref ref) {
  final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: SafeArea(child: ForecastAccountsSheet())),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

/// A router with ForecastScreen at its root, disposed with [ref].
GoRouter forecastRouter(Ref ref) {
  final GoRouter router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const ForecastScreen())],
  );
  ref.onDispose(router.dispose);
  return router;
}
