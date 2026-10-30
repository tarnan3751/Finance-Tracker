// Investments for the Investments segment's tests, on testClock's today, Saturday 24
// October 2026, beside the test seed's checking account and card: a linked "Retirement
// 401k" reporting $15,234.56, with five holdings (Vanguard Total Stock Market ETF with a
// gain, Vanguard Total Bond Market ETF with no cost basis, Acme Corp with a loss, US
// dollars as a cash equivalent with no gain, and Mystery Fund with no type and no price
// date), fourteen investment transactions (contributions, buys and a fee) and four days
// of snapshots with a gap on Oct 22; and a manual "Brokerage" with nothing in it yet.
// investmentsRouter puts InvestmentsScreen at a router's root.
//
//   await pumpApp(tester, overrides: investmentOverrides(), router: investmentsRouter);
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/investments/data/in_memory_holding_repository.dart';
import 'package:finance_tracker/features/investments/data/in_memory_investment_transaction_repository.dart';
import 'package:finance_tracker/features/investments/presentation/investments_screen.dart';
import 'package:finance_tracker/features/net_worth/data/in_memory_balance_snapshot_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import 'seed.dart';

/// The linked retirement account.
const String retirementId = 'invest-401k';

/// The manual brokerage account, with no holdings.
const String brokerageId = 'invest-brokerage';

Money _usd(int cents) => Money(cents, 'USD');

Security _security(
  String id, {
  String? name,
  String? ticker,
  String? type,
  bool? cash,
}) => Security(
  id: id,
  name: name,
  tickerSymbol: ticker,
  type: type,
  isCashEquivalent: cash,
  currencyCode: 'USD',
  source: DataSource.plaid,
);

Holding _holding(
  String securityId,
  String quantity,
  String price,
  int valueCents, {
  int? costCents,
  LocalDate? asOf,
}) => Holding(
  accountId: retirementId,
  securityId: securityId,
  quantity: Decimal.parse(quantity),
  institutionPrice: Decimal.parse(price),
  institutionPriceAsOf: asOf,
  institutionValue: _usd(valueCents),
  costBasis: costCents == null ? null : _usd(costCents),
  source: DataSource.plaid,
);

/// The securities held.
final List<Security> investmentSecurities = [
  _security(
    'sec-vti',
    name: 'Vanguard Total Stock Market ETF',
    ticker: 'VTI',
    type: 'etf',
  ),
  _security(
    'sec-bnd',
    name: 'Vanguard Total Bond Market ETF',
    ticker: 'BND',
    type: 'etf',
  ),
  _security('sec-acme', name: 'Acme Corp', ticker: 'ACME', type: 'equity'),
  _security(
    'sec-usd',
    name: 'US Dollar',
    ticker: 'CUR:USD',
    type: 'cash',
    cash: true,
  ),
  _security('sec-mystery', name: 'Mystery Fund'),
];

/// The retirement account's holdings: ETF $4,511.75, Equity $1,500.00, Cash $1,222.81 and
/// Other $31.27, $7,265.83 in all.
final List<Holding> investmentHoldings = [
  _holding(
    'sec-vti',
    '12.500',
    '245.10',
    306375,
    costCents: 290000,
    asOf: LocalDate(2026, 10, 23),
  ),
  _holding('sec-bnd', '20', '72.40', 144800, asOf: LocalDate(2026, 10, 23)),
  _holding(
    'sec-acme',
    '10',
    '150.00',
    150000,
    costCents: 165000,
    asOf: LocalDate(2026, 10, 23),
  ),
  _holding(
    'sec-usd',
    '1222.81',
    '1.00',
    122281,
    costCents: 122281,
    asOf: LocalDate(2026, 10, 23),
  ),
  _holding('sec-mystery', '3', '10.4234', 3127),
];

/// The retirement account's investment transactions: seven fortnights of a $450.00
/// contribution and a purchase of VTI the same day, the newest on Oct 22, with a $1.50
/// fee on the newest purchase.
final List<InvestmentTransaction> investmentTransactions = [
  for (int i = 0; i < 7; i++) ...[
    InvestmentTransaction(
      id: 'itx-contribution-$i',
      accountId: retirementId,
      date: LocalDate(2026, 10, 22).addDays(-14 * i),
      name: 'Payroll contribution',
      type: 'cash',
      subtype: 'contribution',
      quantity: Decimal.parse('0'),
      price: Decimal.parse('0'),
      amount: _usd(45000),
      syncVersion: i + 1,
      source: DataSource.plaid,
    ),
    InvestmentTransaction(
      id: 'itx-buy-$i',
      accountId: retirementId,
      securityId: 'sec-vti',
      date: LocalDate(2026, 10, 22).addDays(-14 * i),
      name: 'BUY VTI',
      type: 'buy',
      subtype: 'buy',
      quantity: Decimal.parse('1.836'),
      price: Decimal.parse('245.10'),
      amount: _usd(-45000),
      fees: i == 0 ? _usd(150) : null,
      syncVersion: i + 1,
      source: DataSource.plaid,
    ),
  ],
];

/// The retirement account's snapshots: Oct 20, 21, 23 and 24 (none on Oct 22), the last
/// at its reported balance.
final List<BalanceSnapshot> investmentSnapshots = [
  for (final (int day, int cents) in [
    (20, 1500000),
    (21, 1510000),
    (23, 1518025),
    (24, 1523456),
  ])
    BalanceSnapshot(
      accountId: retirementId,
      date: LocalDate(2026, 10, day),
      current: _usd(cents),
      source: DataSource.plaid,
    ),
];

/// The overrides that put the test seed, the two investment accounts and their
/// investments ([holdings] instead of [investmentHoldings] when given) on the in-memory
/// repositories.
List<Override> investmentOverrides({List<Holding>? holdings}) => [
  storeOverride(
    seededStore()
      ..upsertAccount(
        Account(
          id: retirementId,
          itemId: 'item-invest',
          type: AccountType.investment,
          subtype: '401k',
          name: 'Retirement 401k',
          currencyCode: 'USD',
          currentBalance: _usd(1523456),
          isHidden: false,
          displayOrder: 2,
        ),
      )
      ..upsertAccount(
        const Account(
          id: brokerageId,
          type: AccountType.investment,
          name: 'Brokerage',
          currencyCode: 'USD',
          isHidden: false,
          displayOrder: 3,
        ),
      ),
  ),
  holdingRepositoryProvider.overrideWith((ref) {
    final InMemoryHoldingRepository repository = InMemoryHoldingRepository(
      holdings: holdings ?? investmentHoldings,
      securities: investmentSecurities,
    );
    ref.onDispose(repository.close);
    return repository;
  }),
  investmentTransactionRepositoryProvider.overrideWith((ref) {
    final InMemoryInvestmentTransactionRepository repository =
        InMemoryInvestmentTransactionRepository(
          initial: investmentTransactions,
        );
    ref.onDispose(repository.close);
    return repository;
  }),
  balanceSnapshotRepositoryProvider.overrideWith((ref) {
    final InMemoryBalanceSnapshotRepository repository =
        InMemoryBalanceSnapshotRepository();
    for (final BalanceSnapshot s in investmentSnapshots) {
      repository.writeDay(s.date, [s]);
    }
    ref.onDispose(repository.close);
    return repository;
  }),
];

/// A router with InvestmentsScreen at its root, disposed with [ref].
GoRouter investmentsRouter(Ref ref) {
  final GoRouter router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const InvestmentsScreen())],
  );
  ref.onDispose(router.dispose);
  return router;
}
