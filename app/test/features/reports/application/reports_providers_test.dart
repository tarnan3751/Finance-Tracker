// The report providers over the in-memory repositories, as of 24 October 2026: the
// start day the budgets share (else 1), the currency (the device's default when an
// account holds it, else the first account's), and the report of a period, hidden rows
// left out and a credit card payment a transfer while its card's inflow is in the ledger.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/reports/application/reports_providers.dart';
import 'package:finance_tracker/features/reports/application/weekly_summary_providers.dart';
import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/report_seed.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/test_seed.dart';

Budget budget(String id, int startDay) => Budget(
  id: id,
  categoryId: 'plaid:FOOD_AND_DRINK',
  period: BudgetPeriodKind.monthly,
  periodStartDay: startDay,
  amount: Money(50000, 'USD'),
  rollover: false,
  startDate: LocalDate(2026, 1, 1),
);

ProviderContainer container(InMemoryStore store) {
  final ProviderContainer c = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.demo()),
      clockProvider.overrideWithValue(testClock),
      inMemoryStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

// Reads [future] while [provider] is listened to, so it is not disposed meanwhile.
Future<T> read<T>(
  ProviderContainer c,
  ProviderListenable<AsyncValue<T>> provider,
  ProviderListenable<Future<T>> future,
) {
  final ProviderSubscription<AsyncValue<T>> sub = c.listen(provider, (_, _) {});
  addTearDown(sub.close);
  return c.read(future);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the start day is the one every budget shares, else 1', () async {
    final ProviderContainer c = container(reportStore());
    expect(
      await read(c, reportStartDayProvider, reportStartDayProvider.future),
      1,
    );

    await c.read(budgetRepositoryProvider).upsert(budget('b1', 15));
    expect(
      await read(c, reportStartDayProvider, reportStartDayProvider.future),
      15,
    );
    final Report r = await read(c, reportProvider(0), reportProvider(0).future);
    expect(
      r.current.range,
      LocalDateRange(LocalDate(2026, 10, 15), LocalDate(2026, 11, 15)),
    );

    await c.read(budgetRepositoryProvider).upsert(budget('b2', 20));
    expect(
      await read(c, reportStartDayProvider, reportStartDayProvider.future),
      1,
    );
  });

  test(
    'the currency is the default one an account holds, else the first',
    () async {
      expect(
        await read(
          container(reportStore()),
          reportCurrencyProvider,
          reportCurrencyProvider.future,
        ),
        'USD',
      );

      final InMemoryStore euros = InMemoryStore(testClock)
        ..seedSystemCategories()
        ..upsertAccount(
          const Account(
            id: 'euro',
            type: AccountType.depository,
            name: 'Euro',
            currencyCode: 'EUR',
            isHidden: false,
            displayOrder: 0,
          ),
        );
      expect(
        await read(
          container(euros),
          reportCurrencyProvider,
          reportCurrencyProvider.future,
        ),
        'EUR',
      );
    },
  );

  test('the report leaves the hidden rows out', () async {
    final ProviderContainer c = container(reportStore());
    final Report before = await read(
      c,
      reportProvider(0),
      reportProvider(0).future,
    );
    expect(before.current.spend, Money(252650, 'USD'));

    // The same household with the rent hidden, in a store of its own, so the report
    // read is never one computed before the write.
    final Transaction rent = (await c.read(recurringLedgerProvider.future))
        .firstWhere((t) => t.id == 'rent-2026-10');
    final InMemoryStore hidden = reportStore()
      ..upsertTransaction(rent.copyWith(hidden: true));
    final Report after = await read(
      container(hidden),
      reportProvider(0),
      reportProvider(0).future,
    );
    expect(after.current.spend, Money(252650 - 165000, 'USD'));
  });

  test(
    'a card payment is a transfer while the card\'s inflow is in the ledger',
    () async {
      // The test seed's household: a $187.69 payment from checking on Monday 12
      // October and the card's $187.69 inflow the same day; and the same household
      // without the inflow.
      final DemoSeed seed = buildDemoSeed(testClock.today());
      Future<(Report, WeeklyReport)> reports(DemoSeed seed) async {
        final ProviderContainer c = container(seededStore(seed: seed));
        return (
          await read(c, reportProvider(0), reportProvider(0).future),
          await read(c, weeklyReportProvider, weeklyReportProvider.future),
        );
      }

      final (Report paired, WeeklyReport pairedWeeks) = await reports(seed);
      final (Report unpaired, WeeklyReport unpairedWeeks) = await reports(
        DemoSeed(
          accounts: seed.accounts,
          transactions: [
            for (final Transaction t in seed.transactions)
              if (t.name != 'Payment received') t,
          ],
        ),
      );

      expect(paired.current.spend, Money(150377, 'USD'));
      expect(unpaired.current.spend, Money(150377 + 18769, 'USD'));
      expect(paired.current.counts[TransactionKind.transfer], 2);
      expect(
        unpairedWeeks.lastWeek.period.spend - pairedWeeks.lastWeek.period.spend,
        Money(18769, 'USD'),
      );
    },
  );
}
