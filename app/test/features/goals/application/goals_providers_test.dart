// The goal views over the in-memory repositories, as of 24 October 2026: a balance goal's
// progress from its linked accounts as each is shown (reported, else derived), an account
// in another currency left out and listed, a deleted account left out; a contribution
// goal's from its live contributions; the suggestion and status following a new
// contribution and a delete.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/goals/application/goals_providers.dart';
import 'package:finance_tracker/features/goals/domain/goal_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../forecast/domain/forecast_fixtures.dart' show txn, usd;

final Clock clock = FixedClock(DateTime.utc(2026, 10, 24, 15), tz.UTC);

Account depository(String id, {String currency = 'USD', String? itemId}) =>
    Account(
      id: id,
      itemId: itemId,
      type: AccountType.depository,
      name: id,
      currencyCode: currency,
      currentBalance: itemId == null ? null : Money(250000, currency),
      isHidden: false,
      displayOrder: 0,
    );

Future<ProviderContainer> container() async {
  final InMemoryStore store = InMemoryStore(clock)
    ..upsertAccount(depository('checking'))
    ..upsertAccount(depository('euro', currency: 'EUR'))
    ..upsertAccount(depository('gone'))
    ..applyPlaidAccounts([depository('savings', itemId: 'item')])
    ..upsertTransactions([
      txn('pay', 120000, LocalDate(2026, 10, 1)),
      txn('coffee', -2000, LocalDate(2026, 10, 2)),
      txn('gone-in', 99900, LocalDate(2026, 10, 1), accountId: 'gone'),
    ]);
  final ProviderContainer c = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.demo()),
      clockProvider.overrideWithValue(clock),
      inMemoryStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(c.dispose);
  await c.read(accountRepositoryProvider).delete('gone');
  final ProviderSubscription<AsyncValue<List<GoalView>>> sub = c.listen(
    goalViewsProvider,
    (_, _) {},
  );
  addTearDown(sub.close);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a balance goal counts its linked accounts as they are shown', () async {
    final ProviderContainer c = await container();
    await c
        .read(goalActionsProvider)
        .create(
          Goal(
            id: 'fund',
            name: 'Emergency fund',
            target: usd(1000000),
            kind: GoalKind.balance,
            linkedAccountIds: const ['savings', 'checking', 'euro', 'gone'],
            targetDate: LocalDate(2027, 10, 24),
            createdOn: LocalDate(2026, 4, 24),
          ),
        );
    final GoalView view = (await c.read(goalViewsProvider.future)).single;
    // Reported 2,500.00 on savings, derived 1,180.00 on checking.
    expect(view.progress, usd(368000));
    expect(view.accounts.map((a) => (a.account.id, a.balance.reported)), [
      ('savings', true),
      ('checking', false),
    ]);
    expect(view.otherCurrencyAccounts.map((a) => a.id), ['euro']);
    expect(view.remaining, usd(632000));
    expect(view.monthsLeft, 12);
    expect(view.suggestion, usd(52667));
    // 183 of 548 days: 3,339.41 expected.
    expect(view.status, const GoalOnTrack());
  });

  test('a contribution goal counts its live contributions, and follows each '
      'change', () async {
    final ProviderContainer c = await container();
    final GoalActions actions = c.read(goalActionsProvider);
    await actions.create(
      Goal(
        id: 'trip',
        name: 'Holiday',
        target: usd(180000),
        kind: GoalKind.contribution,
        linkedAccountIds: const ['savings'],
        targetDate: LocalDate(2027, 4, 24),
        createdOn: LocalDate(2026, 4, 24),
      ),
    );
    for (int m = 0; m < 6; m++) {
      await actions.addContribution(
        GoalContribution(
          id: 'c$m',
          goalId: 'trip',
          date: LocalDate(2026, 5 + m, 1),
          amount: usd(12500),
        ),
      );
    }
    GoalView view = (await c.read(goalViewsProvider.future)).single;
    expect(view.progress, usd(75000));
    expect(view.accounts, isEmpty);
    expect(view.otherCurrencyContributions, isEmpty);
    // 183 of 365 days of 1,800.00: 902.46 expected.
    expect(view.status, GoalBehind(usd(90246 - 75000)));
    expect(view.monthsLeft, 6);
    expect(view.suggestion, usd(17500));

    await actions.addContribution(
      GoalContribution(
        id: 'bonus',
        goalId: 'trip',
        date: LocalDate(2026, 10, 24),
        amount: usd(20000),
      ),
    );
    view = (await c.read(goalViewsProvider.future)).single;
    expect(view.progress, usd(95000));
    expect(view.status, const GoalOnTrack());

    await actions.deleteContribution('bonus');
    expect(
      (await c.read(goalViewsProvider.future)).single.progress,
      usd(75000),
    );
    await actions.setArchived('trip', archived: true);
    expect(
      (await c.read(goalViewByIdProvider('trip').future))!.archived,
      isTrue,
    );
    await actions.delete('trip');
    expect(await c.read(goalViewsProvider.future), isEmpty);
  });

  test('a contribution in another currency than the target is left out and '
      'listed', () async {
    final ProviderContainer c = await container();
    final GoalActions actions = c.read(goalActionsProvider);
    final Goal trip = Goal(
      id: 'trip',
      name: 'Holiday',
      target: usd(180000),
      kind: GoalKind.contribution,
      createdOn: LocalDate(2026, 4, 24),
    );
    await actions.create(trip);
    await actions.addContribution(
      GoalContribution(
        id: 'usd',
        goalId: 'trip',
        date: LocalDate(2026, 5, 1),
        amount: usd(12500),
      ),
    );
    // Another device moved the target to euros (the editor would not let it here).
    await actions.update(trip.copyWith(target: Money(150000, 'EUR')));
    final GoalView view = (await c.read(goalViewsProvider.future)).single;
    expect(view.progress, Money(0, 'EUR'));
    expect(view.otherCurrencyContributions.map((c) => c.id), ['usd']);
  });
}
