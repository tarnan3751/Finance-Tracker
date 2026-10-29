// The forecast's providers over the in-memory repositories, as of 24 October 2026: the
// start balance as each account is shown (reported, else derived), the streams counted
// (active, unmuted, on a covered account, in the currency) with their members' band, the
// allowance leaving the members out, the selection and the currency, and the series
// following a new transaction.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/forecast/application/forecast_providers.dart';
import 'package:finance_tracker/features/forecast/domain/cash_flow_forecast.dart';
import 'package:finance_tracker/features/forecast/domain/forecast_plan.dart';
import 'package:finance_tracker/features/recurring/application/recurring_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/forecast_fixtures.dart';

final Clock clock = FixedClock(DateTime.utc(2026, 10, 24, 15), tz.UTC);

Account depository(
  String id, {
  String currency = 'USD',
  bool hidden = false,
  int order = 0,
}) => Account(
  id: id,
  type: AccountType.depository,
  name: id,
  currencyCode: currency,
  isHidden: hidden,
  displayOrder: order,
);

/// The store: a manual checking account (derived balance), a linked savings account
/// (reported 50,000.00), a hidden manual account, a card and a euro account.
InMemoryStore store() {
  final InMemoryStore s = InMemoryStore(clock)..seedSystemCategories();
  s
    ..upsertAccount(depository('checking'))
    ..upsertAccount(depository('stash', hidden: true, order: 1))
    ..upsertAccount(
      const Account(
        id: 'card',
        type: AccountType.credit,
        name: 'card',
        currencyCode: 'USD',
        isHidden: false,
        displayOrder: 2,
      ),
    )
    ..upsertAccount(depository('euro', currency: 'EUR', order: 3))
    ..applyPlaidAccounts([
      Account(
        id: 'savings',
        itemId: 'item',
        type: AccountType.depository,
        name: 'savings',
        currencyCode: 'USD',
        currentBalance: usd(5000000),
        isHidden: false,
        displayOrder: 4,
      ),
    ])
    ..upsertTransactions([
      txn('opening', 300000, LocalDate(2026, 6, 1)),
      txn('pay1', 200000, LocalDate(2026, 9, 18)),
      txn('pay2', 210000, LocalDate(2026, 10, 2)),
      txn('pay3', 190000, LocalDate(2026, 10, 16)),
      txn('coffee', -9000, LocalDate(2026, 10, 20)),
      txn('stashed', 100000, LocalDate(2026, 6, 1), accountId: 'stash'),
      txn(
        'euro-in',
        70000,
        LocalDate(2026, 6, 1),
        accountId: 'euro',
        currency: 'EUR',
      ),
    ]);
  return s;
}

final List<RecurringStream> streams = [
  stream(
    'pay',
    cadence: RecurringCadence.biweekly,
    cents: 200000,
    next: LocalDate(2026, 10, 30),
    last: LocalDate(2026, 10, 16),
    members: ['pay1', 'pay2', 'pay3', 'gone'],
  ),
  stream('rent', cents: -150000, next: LocalDate(2026, 11, 1)),
  stream('gym', cents: -5000, next: LocalDate(2026, 11, 3)),
  stream(
    'old',
    cents: -7000,
    next: LocalDate(2026, 11, 4),
    status: RecurringStatus.ended,
  ),
  stream(
    'card-stream',
    cents: -1000,
    next: LocalDate(2026, 11, 5),
  ).copyWith(accountId: 'card'),
];

Future<ProviderContainer> container({InMemoryStore? on}) async {
  final ProviderContainer c = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.demo()),
      clockProvider.overrideWithValue(clock),
      inMemoryStoreProvider.overrideWithValue(on ?? store()),
    ],
  );
  addTearDown(c.dispose);
  await c.read(recurringStreamRepositoryProvider).applyPlaid(streams);
  await c.read(streamActionsProvider).mute('gym', muted: true);
  return c;
}

Future<ForecastPlan?> planOf(ProviderContainer c) async {
  final ProviderSubscription<AsyncValue<ForecastPlan?>> sub = c.listen(
    forecastPlanProvider,
    (_, _) {},
  );
  addTearDown(sub.close);
  return c.read(forecastPlanProvider.future);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the plan of the covered USD accounts', () async {
    final ForecastPlan plan = (await planOf(await container()))!;
    expect(plan.today, LocalDate(2026, 10, 24));
    // checking derived (3,000 + 6,000 - 90) plus savings reported (50,000).
    expect(plan.start, usd(300000 + 600000 - 9000 + 5000000));
    expect(plan.streams.map((s) => s.stream.id), ['pay', 'rent']);
    final ForecastStream pay = plan.streams.first;
    expect(pay.name, 'pay');
    expect(pay.members.map((t) => t.id), ['pay1', 'pay2', 'pay3']);
    // The coffee alone, over 90 days, half-even.
    expect(plan.allowance, usd(100));
  });

  test('the series projects the plan for each horizon', () async {
    final ProviderContainer c = await container();
    await planOf(c);
    final ProviderSubscription<AsyncValue<ForecastSeries?>> sub = c.listen(
      forecastProvider(90),
      (_, _) {},
    );
    addTearDown(sub.close);
    final ForecastSeries long = (await c.read(forecastProvider(90).future))!;
    final ForecastSeries short = (await c.read(forecastProvider(30).future))!;
    expect(long.points, hasLength(91));
    expect(short.points, long.points.sublist(0, 31));
    final ForecastPoint payday = long.points.firstWhere(
      (p) => p.date == LocalDate(2026, 10, 30),
    );
    expect(payday.upper - payday.lower, usd(20000));
  });

  test('a new transaction moves the start and the allowance', () async {
    final ProviderContainer c = await container();
    await planOf(c);
    await c
        .read(transactionRepositoryProvider)
        .upsert(txn('lunch', -18000, LocalDate(2026, 10, 22)));
    final ForecastPlan plan = (await c.read(forecastPlanProvider.future))!;
    expect(plan.start, usd(5891000 - 18000));
    expect(plan.allowance, usd(300));
  });

  test('a toggle and a currency change the plan', () async {
    final ProviderContainer c = await container();
    await planOf(c);
    final ForecastSelectionController selection = c.read(
      forecastSelectionControllerProvider.notifier,
    );
    final Account savings =
        (await c.read(accountRepositoryProvider).watchAll().first).singleWhere(
          (a) => a.id == 'savings',
        );
    await selection.toggle(savings);
    expect((await c.read(forecastPlanProvider.future))!.start, usd(891000));

    await selection.showCurrency('EUR');
    final ForecastPlan euro = (await c.read(forecastPlanProvider.future))!;
    expect(euro.currencyCode, 'EUR');
    expect(euro.start, Money(70000, 'EUR'));
    expect(euro.streams, isEmpty);
  });

  test('no plan when no account is covered', () async {
    final InMemoryStore s = InMemoryStore(clock)
      ..seedSystemCategories()
      ..upsertAccount(depository('stash', hidden: true));
    expect(await planOf(await container(on: s)), isNull);
  });
}
