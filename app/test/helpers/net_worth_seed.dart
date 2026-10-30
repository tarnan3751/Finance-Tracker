// A household for the net worth screen's tests, on testClock's today, Saturday 24 October
// 2026: Everyday Checking (manual, derived from its transactions since 1 August), a
// linked Rewards Card (reported owing 1,250.00, a 21.99 % purchase APR and a 35.00
// minimum), a linked Home Mortgage (reported owing 285,000.00 at 6.25 % with a 2,150.00
// monthly payment), a manual Car Loan with no liability detail, and a linked 401(k)
// (reported 42,000.00). Its balance snapshots run from 14 October to today with no row on
// 19 October, so the screen has a derived prefix from 1 August, a gap and an observed
// span. NetWorthScreen has no route of its own in the tests, so netWorthRouter puts it at
// a router's root.
//
//   await pumpApp(tester, overrides: netWorthOverrides(), router: netWorthRouter);
import 'dart:async';

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/liabilities/data/in_memory_liability_repository.dart';
import 'package:finance_tracker/features/net_worth/data/in_memory_balance_snapshot_repository.dart';
import 'package:finance_tracker/features/net_worth/presentation/net_worth_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import 'pump_app.dart';
import 'seed.dart';
import 'test_seed.dart';

const String nwCheckingId = 'nw-checking';
const String nwCardId = 'nw-card';
const String nwMortgageId = 'nw-mortgage';
const String nwCarId = 'nw-car';
const String nw401kId = 'nw-401k';

/// The first day a snapshot is stored for.
final LocalDate nwFirstSnapshot = LocalDate(2026, 10, 14);

/// The day with no snapshot.
final LocalDate nwGap = LocalDate(2026, 10, 19);

Money _usd(int cents) => Money(cents, 'USD');

Account _account(
  String id,
  String name,
  AccountType type, {
  int? reported,
  required int order,
}) => Account(
  id: id,
  itemId: reported == null ? null : 'nw-item',
  type: type,
  name: name,
  currencyCode: 'USD',
  currentBalance: reported == null ? null : _usd(reported),
  isHidden: false,
  displayOrder: order,
);

Transaction _entry(String id, String account, int cents, LocalDate date) =>
    Transaction(
      id: id,
      accountId: account,
      amount: _usd(cents),
      date: date,
      pending: false,
      name: id,
      source: DataSource.manual,
      createdAt: testClock.nowUtc(),
      updatedAt: testClock.nowUtc(),
      syncVersion: 0,
    );

/// The household's transactions: on checking an opening balance, pay on the 1st and the
/// 15th, rent on the 1st and spending every fourth day; on the card a purchase every
/// fifth day; the car loan's opening balance.
List<Transaction> netWorthTransactions() => [
  _entry('nw-opening', nwCheckingId, 420000, LocalDate(2026, 8, 1)),
  for (final int month in [8, 9, 10]) ...[
    _entry('nw-pay-$month-1', nwCheckingId, 260000, LocalDate(2026, month, 1)),
    _entry(
      'nw-pay-$month-15',
      nwCheckingId,
      260000,
      LocalDate(2026, month, 15),
    ),
    _entry('nw-rent-$month', nwCheckingId, -215000, LocalDate(2026, month, 1)),
  ],
  for (int i = 0; i < 21; i++)
    _entry(
      'nw-spend-$i',
      nwCheckingId,
      -(6000 + 1500 * (i % 4)),
      LocalDate(2026, 8, 2).addDays(i * 4),
    ),
  for (int i = 0; i < 17; i++)
    _entry(
      'nw-card-$i',
      nwCardId,
      -(2500 + 900 * (i % 3)),
      LocalDate(2026, 8, 3).addDays(i * 5),
    ),
  _entry('nw-car-opening', nwCarId, -1840000, LocalDate(2026, 8, 1)),
];

/// The household's store.
InMemoryStore netWorthStore() {
  final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
  store
    ..upsertAccount(
      _account(
        nwCheckingId,
        'Everyday Checking',
        AccountType.depository,
        order: 0,
      ),
    )
    ..upsertAccount(_account(nwCarId, 'Car Loan', AccountType.loan, order: 3))
    ..applyPlaidAccounts([
      _account(
        nwCardId,
        'Rewards Card',
        AccountType.credit,
        reported: -125000,
        order: 1,
      ),
      _account(
        nwMortgageId,
        'Home Mortgage',
        AccountType.loan,
        reported: -28500000,
        order: 2,
      ),
      _account(
        nw401kId,
        '401(k)',
        AccountType.investment,
        reported: 4200000,
        order: 4,
      ),
    ])
    ..upsertTransactions(netWorthTransactions());
  return store;
}

/// The household's liabilities: the card's and the mortgage's.
List<Liability> netWorthLiabilities() => [
  Liability(
    accountId: nwCardId,
    kind: LiabilityKind.credit,
    source: DataSource.plaid,
    minimumPaymentAmount: _usd(3500),
    aprs: const [
      LiabilityApr(type: 'purchase_apr', percentageBasisPoints: 2199),
    ],
    payload: const {},
  ),
  Liability(
    accountId: nwMortgageId,
    kind: LiabilityKind.mortgage,
    source: DataSource.plaid,
    interestRateBasisPoints: 625,
    nextMonthlyPayment: _usd(215000),
    payload: const {},
  ),
];

/// The household's balance snapshots, from [nwFirstSnapshot] to today but [nwGap]: the
/// checking and car balances as their transactions give them that day, the card and
/// the mortgage as reported, the 401(k) growing by 120.00 a day to its reported total.
List<BalanceSnapshot> netWorthSnapshots() {
  final List<Transaction> ledger = netWorthTransactions();
  Money upTo(String account, LocalDate day) => Money.sum([
    for (final Transaction t in ledger)
      if (t.accountId == account && !t.date.isAfter(day)) t.amount,
  ], currencyCode: 'USD');
  final LocalDate today = testClock.today();
  BalanceSnapshot row(String account, LocalDate day, Money current) =>
      BalanceSnapshot(
        accountId: account,
        date: day,
        current: current,
        source: account == nwCheckingId || account == nwCarId
            ? DataSource.manual
            : DataSource.plaid,
      );
  return [
    for (
      LocalDate day = nwFirstSnapshot;
      !day.isAfter(today);
      day = day.addDays(1)
    )
      if (day != nwGap) ...[
        row(nwCheckingId, day, upTo(nwCheckingId, day)),
        row(nwCardId, day, _usd(-125000)),
        row(nwMortgageId, day, _usd(-28500000)),
        row(nwCarId, day, upTo(nwCarId, day)),
        row(nw401kId, day, _usd(4200000 - 12000 * day.daysUntil(today))),
      ],
  ];
}

/// The repository holding [snapshots] ([netWorthSnapshots] by default).
InMemoryBalanceSnapshotRepository netWorthSnapshotRepository([
  List<BalanceSnapshot>? snapshots,
]) {
  final InMemoryBalanceSnapshotRepository repository =
      InMemoryBalanceSnapshotRepository();
  final Map<LocalDate, List<BalanceSnapshot>> byDay = {};
  for (final BalanceSnapshot s in snapshots ?? netWorthSnapshots()) {
    (byDay[s.date] ??= []).add(s);
  }
  // The in-memory writes complete before their first await.
  for (final MapEntry<LocalDate, List<BalanceSnapshot>> e in byDay.entries) {
    unawaited(repository.writeDay(e.key, e.value));
  }
  return repository;
}

/// The household's store, liabilities and snapshots.
List<Override> netWorthOverrides({
  InMemoryStore? store,
  List<BalanceSnapshot>? snapshots,
}) => [
  storeOverride(store ?? netWorthStore()),
  liabilityRepositoryProvider.overrideWithValue(
    InMemoryLiabilityRepository(initial: netWorthLiabilities()),
  ),
  balanceSnapshotRepositoryProvider.overrideWithValue(
    netWorthSnapshotRepository(snapshots),
  ),
];

/// A router with NetWorthScreen at its root, disposed with [ref].
GoRouter netWorthRouter(Ref ref) {
  final GoRouter router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const NetWorthScreen())],
  );
  ref.onDispose(router.dispose);
  return router;
}
