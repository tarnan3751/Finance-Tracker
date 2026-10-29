/// The demo flavor's data: a household from the persona engine, generated at startup with
/// no server and no database (`PLAN.md` §7.1: synthesized data lives in the demo flavor,
/// labelled `demo`; `docs/reference/persona.md`).
///
/// The persona engine's accounts belong to demo Items and report the balance their
/// history gives; the app's accounts screens show balances derived from transactions, so
/// each non-zero opening balance (the balance the day before the window, which the
/// engine keeps apart from the transactions) is loaded as an "Opening balance"
/// transaction, `source: demo`, dated that day, as a manual account's opening balance is.
/// An investment account reports its total value, holdings and cash, as Plaid's
/// `balances.current` does, and is shown with it; its transactions (only the opening
/// cash: the engine's contributions and buys are investment transactions) derive to that
/// cash alone. The engine's Items are loaded with their institutions, as the demo's fake
/// server lists them. Its recurring expectations become `demo` recurring streams
/// ([demoRecurringStreams]), its card, mortgage and student-loan liabilities the
/// contract's liability objects ([demoLiabilities]), and its brokerage (the family's)
/// the contract's holdings, securities ([demoHoldings]) and investment transactions
/// ([demoInvestmentTransactions]), all `demo`, which the demo repositories and the
/// in-app fake both start from; its opening holdings (quantity history is later scope)
/// and anomalies are not loaded.
library;

import 'package:finance_tracker/core/api/api_models.dart' as wire;
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart'
    hide Holding, InvestmentTransaction, Liability, Security;

/// The persona the demo flavor starts with: the `FT_DEMO_PERSONA` dart-define's slug
/// ([PersonaId.slug]), or the renter when it is unset or names no persona.
PersonaId initialDemoPersona([
  String slug = const String.fromEnvironment('FT_DEMO_PERSONA'),
]) {
  for (final PersonaId persona in PersonaId.values) {
    if (persona.slug == slug) return persona;
  }
  return PersonaId.renter;
}

/// The demo seed of [persona] as of [today]: seed 1, the engine's full window.
DemoSeed demoSeedFor(PersonaId persona, LocalDate today) =>
    generateDemoSeed(persona, 1, today);

/// Loads [seed] into [store], through the store's rules: the Items with their
/// institutions, the accounts, an opening balance transaction for each non-zero opening
/// balance, then the transactions.
void loadDemoSeed(InMemoryStore store, DemoSeed seed) {
  final GeneratedHousehold household = seed.household;
  store.applyPlaidItems([
    for (final Item item in household.items)
      (
        item: item,
        institution: household.institutions.firstWhere(
          (i) => i.id == item.institutionId,
        ),
      ),
  ], store.clock.nowUtc());
  household.accounts.forEach(store.upsertAccount);
  for (final OpeningBalance opening in household.openingBalances) {
    if (opening.amount.isZero) continue;
    final LocalDate date = opening.date;
    final DateTime at = DateTime.utc(date.year, date.month, date.day);
    store.upsertTransaction(
      Transaction(
        id: '${opening.accountId}-opening',
        accountId: opening.accountId,
        amount: opening.amount,
        date: date,
        pending: false,
        name: 'Opening balance',
        source: DataSource.demo,
        createdAt: at,
        updatedAt: at,
        syncVersion: 0,
      ),
    );
  }
  household.transactions.forEach(store.upsertTransaction);
}

/// The demo's recurring streams: one per expectation of [seed], `demo`, with the id
/// `demo-stream-<key>`, the schedule's cadence, the middle of the expectation's band in
/// the app's sign as the average, the schedule's last occurrence in the window and its
/// next after it as the expected dates, and as members the seed's transactions on the
/// expectation's account with its raw name (the engine's recurrence tests hold that
/// nothing else on the account carries the name), in the seed's order.
List<RecurringStream> demoRecurringStreams(DemoSeed seed) {
  final GeneratedHousehold household = seed.household;
  final LocalDate asOf = household.asOf;
  return [
    for (final RecurringExpectation r in household.recurring)
      () {
        final Money middle = (r.minAmount + r.maxAmount).multipliedBy(1, 2);
        final List<LocalDate> past = r.schedule.occurrences(
          household.window.start,
          asOf,
        );
        final List<LocalDate> next = r.schedule.occurrences(
          asOf.addDays(1),
          asOf.addDays(400),
        );
        return RecurringStream(
          id: 'demo-stream-${r.key}',
          accountId: r.accountId,
          merchantName: r.merchantName ?? r.name,
          cadence: r.cadence,
          averageAmount: r.isInflow ? middle : -middle,
          lastExpected: past.isEmpty ? null : past.last,
          nextExpected: next.isEmpty ? null : next.first,
          status: RecurringStatus.active,
          isSubscription: r.isSubscription,
          source: RecurringSource.demo,
          transactionIds: [
            for (final Transaction t in household.transactions)
              if (t.accountId == r.accountId && t.name == r.name) t.id,
          ],
        );
      }(),
  ];
}

/// The demo's liabilities as the contract's objects, `demo`: each card's statement,
/// minimum and purchase APR, each mortgage's and student loan's terms. Auto loans are
/// left out, as Plaid's Liabilities product has no auto-loan detail; fields the engine
/// does not model are null.
wire.Liabilities demoLiabilities(DemoSeed seed) {
  final List<Liability> engine = seed.household.liabilities;
  String rate(int basisPoints) =>
      '${basisPoints ~/ 100}.${(basisPoints % 100).toString().padLeft(2, '0')}';
  String term(int months) =>
      months % 12 == 0 ? '${months ~/ 12} year' : '$months month';
  return wire.Liabilities(
    credit: [
      for (final Liability l in engine)
        if (l is CreditLiability)
          wire.CreditLiability(
            accountId: l.accountId,
            source: DataSource.demo,
            aprs: [
              wire.Apr(
                aprPercentage: rate(l.aprBasisPoints),
                aprType: 'purchase_apr',
              ),
            ],
            lastPaymentAmount: l.lastPaymentAmount,
            lastPaymentDate: l.lastPaymentDate,
            lastStatementIssueDate: l.lastStatementDate,
            lastStatementBalance: l.lastStatementBalance,
            minimumPaymentAmount: l.minimumPayment,
            nextPaymentDueDate: l.nextPaymentDueDate,
          ),
    ],
    mortgage: [
      for (final Liability l in engine)
        if (l is LoanLiability && l.kind == LoanKind.mortgage)
          wire.MortgageLiability(
            accountId: l.accountId,
            source: DataSource.demo,
            loanTerm: term(l.termMonths),
            interestRatePercentage: rate(l.aprBasisPoints),
            interestRateType: 'fixed',
            lastPaymentAmount: l.lastPaymentAmount,
            lastPaymentDate: l.lastPaymentDate,
            maturityDate: l.maturityDate,
            nextMonthlyPayment: l.nextPaymentAmount ?? l.monthlyPayment,
            nextPaymentDueDate: l.nextPaymentDueDate,
            originationDate: l.originationDate,
            originationPrincipalAmount: l.originationPrincipal,
            ytdInterestPaid: l.ytdInterestPaid,
          ),
    ],
    student: [
      for (final Liability l in engine)
        if (l is LoanLiability && l.kind == LoanKind.student)
          wire.StudentLoanLiability(
            accountId: l.accountId,
            source: DataSource.demo,
            loanName: l.loanName,
            interestRatePercentage: rate(l.aprBasisPoints),
            expectedPayoffDate: l.maturityDate,
            lastPaymentAmount: l.lastPaymentAmount,
            lastPaymentDate: l.lastPaymentDate,
            minimumPaymentAmount: l.monthlyPayment,
            nextPaymentDueDate: l.nextPaymentDueDate,
            originationDate: l.originationDate,
            originationPrincipalAmount: l.originationPrincipal,
            loanStatusType: l.monthlyPayment == null
                ? 'deferment'
                : 'repayment',
            ytdInterestPaid: l.ytdInterestPaid,
          ),
    ],
  );
}

/// The id of the demo security with [ticker].
String demoSecurityId(String ticker) => 'demo-security-$ticker';

/// The demo's holdings and securities as the contract's objects, `demo`: each of the
/// engine's positions on the as-of date (its quantity in thousandths of a share, its
/// price, value and cost), and each security they hold, once however many positions hold
/// it, an `etf` (the engine's are all exchange-traded funds and carry no type) closing at
/// its first position's price on that date.
wire.Holdings demoHoldings(DemoSeed seed) {
  final List<Holding> engine = seed.household.holdings;
  // Each security's first position, by id.
  final Map<String, Holding> first = {};
  for (final Holding h in engine) {
    first.putIfAbsent(demoSecurityId(h.security.ticker), () => h);
  }
  return wire.Holdings(
    holdings: [
      for (final Holding h in engine)
        wire.Holding(
          accountId: h.accountId,
          securityId: demoSecurityId(h.security.ticker),
          quantity: Decimal(BigInt.from(h.quantityMilli), 3).toString(),
          institutionPrice: h.price.toDecimalString(),
          institutionPriceAsOf: h.priceAsOf,
          institutionValue: h.value,
          costBasis: h.costBasis,
          currencyCode: h.price.currencyCode,
          source: DataSource.demo,
        ),
    ],
    securities: [
      for (final MapEntry(key: String id, value: Holding h) in first.entries)
        wire.Security(
          id: id,
          name: h.security.name,
          tickerSymbol: h.security.ticker,
          type: 'etf',
          isCashEquivalent: false,
          closePrice: h.price.toDecimalString(),
          closePriceAsOf: h.priceAsOf,
          currencyCode: h.security.currencyCode,
          source: DataSource.demo,
        ),
    ],
  );
}

/// The demo's investment transactions as the contract's objects, `demo`, in the app's
/// sign: a `cash` contribution is money in (subtype `contribution`, no security, no
/// quantity or price), a `buy` money out of the account's cash (its security, quantity
/// and price). The engine charges no fees.
List<wire.InvestmentTransaction> demoInvestmentTransactions(DemoSeed seed) => [
  for (final InvestmentTransaction t in seed.household.investmentTransactions)
    switch (t.type) {
      InvestmentTransactionType.cash => wire.InvestmentTransaction(
        id: t.id,
        accountId: t.accountId,
        date: t.date,
        name: t.name,
        type: 'cash',
        subtype: 'contribution',
        quantity: '0',
        price: '0',
        amount: t.amount,
        syncVersion: 0,
        source: DataSource.demo,
      ),
      InvestmentTransactionType.buy => wire.InvestmentTransaction(
        id: t.id,
        accountId: t.accountId,
        securityId: demoSecurityId(t.security!.ticker),
        date: t.date,
        name: t.name,
        type: 'buy',
        subtype: 'buy',
        quantity: Decimal(BigInt.from(t.quantityMilli), 3).toString(),
        price: t.price!.toDecimalString(),
        amount: -t.amount,
        syncVersion: 0,
        source: DataSource.demo,
      ),
    },
];
