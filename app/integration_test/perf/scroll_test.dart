// The demo flavor on a device with ten thousand more transactions, measured
// (docs/reference/performance.md, **Scroll and data on screen**). Runs only under
// `flutter drive --profile` from tools/perf/scroll.sh, which passes
// --dart-define=FT_PERF=true and test_driver/perf_driver.dart; anywhere else it is skipped.
//
// The demo's store is the persona's seed plus one more account, "Perf ledger", holding
// 10,000 `demo` transactions from a fixed seed (three years back from today, a few a day).
// First trace ("start"): from `startApp`, after the one-time process setup bootstrap does,
// to the Accounts list's first row on screen ("data on screen", reported as
// `data_on_screen_ms`). Second trace ("scroll"): the app started again the same way, the
// Transactions tab opened, its list flung down five times, each fling left to settle. The
// driver summarises both timelines.
@Tags(['perf'])
library;

import 'dart:math';

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

const bool _driven = bool.fromEnvironment('FT_PERF');

/// The ledger's size.
const int _rows = 10000;

const Account _ledgerAccount = Account(
  id: 'perf-ledger',
  type: AccountType.depository,
  name: 'Perf ledger',
  currencyCode: 'USD',
  isHidden: false,
  displayOrder: 99,
);

const List<String> _merchants = [
  'Northwind Grocers',
  'Contoso Coffee',
  'Adventure Works Fuel',
  'Fabrikam Pharmacy',
  'Tailspin Airlines',
  'Wingtip Toys',
  'Litware Books',
  'Proseware Cinema',
  'Fourth Coffee',
  'Alpine Ski House',
];

/// [_rows] `demo` transactions on [_ledgerAccount] ending [today], the same for the same
/// day: about nine a day, amounts up to 250.00 out and an income every fortnight.
List<Transaction> _ledger(LocalDate today) {
  final Random random = Random(20261101);
  return [
    for (int i = 0; i < _rows; i++)
      () {
        final LocalDate date = today.addDays(-(i ~/ 9));
        final DateTime at = DateTime.utc(date.year, date.month, date.day, 12);
        final bool income = i % 126 == 0;
        return Transaction(
          id: 'perf-$i',
          accountId: _ledgerAccount.id,
          amount: Money(income ? 250000 : -(random.nextInt(25000) + 1), 'USD'),
          date: date,
          pending: false,
          name: income
              ? 'Payroll'
              : _merchants[random.nextInt(_merchants.length)],
          source: DataSource.demo,
          createdAt: at,
          updatedAt: at,
          syncVersion: 0,
        );
      }(),
  ];
}

/// The demo flavor's wiring with its store holding [ledger] too.
List<Override> _seeded(List<Transaction> ledger) => [
  for (final Override o in overridesFor(AppConfig.demo()))
    // ignore: invalid_use_of_visible_for_testing_member
    if (!identical(o.origin, inMemoryStoreProvider)) o,
  inMemoryStoreProvider.overrideWith((ref) {
    final InMemoryStore store = InMemoryStore(ref.watch(clockProvider))
      ..seedSystemCategories();
    loadDemoSeed(store, ref.watch(demoSeedProvider));
    store
      ..upsertAccount(_ledgerAccount)
      ..upsertTransactions(ledger);
    ref.onDispose(store.close);
    return store;
  }),
];

/// What bootstrap does once per process before it starts the app.
Future<void> _processSetUp() async {
  await setUpTimeZones();
  Intl.defaultLocale = deviceLocale();
  await initializeDateFormatting();
}

/// Pumps frames until [finder] finds something, at most two minutes of [watch].
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder,
  Stopwatch watch,
) async {
  while (finder.evaluate().isEmpty) {
    if (watch.elapsed > const Duration(minutes: 2)) {
      fail('nothing found by $finder within two minutes');
    }
    await tester.pump(const Duration(milliseconds: 8));
  }
}

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 30),
);

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  late List<Transaction> ledger;
  setUpAll(() async {
    await _processSetUp();
    ledger = _ledger(const SystemClock().today());
  });

  testWidgets(
    'data on screen: from start to the first account row',
    skip: !_driven,
    (tester) async {
      await binding.traceAction(() async {
        final Stopwatch watch = Stopwatch()..start();
        await startApp(AppConfig.demo(), overrides: _seeded(ledger));
        await _pumpUntil(tester, find.text('Everyday Checking'), watch);
        watch.stop();
        (binding.reportData ??= {})['data_on_screen_ms'] =
            watch.elapsedMilliseconds;
      }, reportKey: 'start');
      await _settle(tester);
    },
  );

  testWidgets(
    'scroll: five flings down the Transactions list',
    skip: !_driven,
    (tester) async {
      await stopApp();
      await startApp(AppConfig.demo(), overrides: _seeded(ledger));
      await _settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Transactions'),
        ),
      );
      await _settle(tester);
      final Finder list = find
          .ancestor(
            of: find.byType(TransactionTile).first,
            matching: find.byType(Scrollable),
          )
          .first;
      final Finder loading = find.descendant(
        of: list,
        matching: find.byType(CircularProgressIndicator),
      );
      await binding.traceAction(() async {
        for (int i = 0; i < 5; i++) {
          await tester.fling(list, const Offset(0, -1500), 5000);
          await _settle(tester);
          // A fling that reached the loaded end waits for the next page, as a person
          // would, so the next one has rows to scroll through.
          final Stopwatch watch = Stopwatch()..start();
          while (loading.evaluate().isNotEmpty &&
              watch.elapsed < const Duration(seconds: 10)) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          await _settle(tester);
        }
      }, reportKey: 'scroll');
      (binding.reportData ??= {})
        ..['ledger_rows'] = _rows
        ..['scroll_offset_px'] = tester
            .state<ScrollableState>(list)
            .position
            .pixels
            .round();
      await stopApp();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
