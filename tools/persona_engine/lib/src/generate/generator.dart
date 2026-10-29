/// The day walk: one persona, one seed, one window, one household.
///
/// Determinism: every random draw comes from one PCG32 seeded from `(persona, seed)`,
/// forked into one child per component in the persona's declaration order; iteration is
/// over lists in that order; sorting is stable with a total order; no clock is read and no
/// `double` is used. The same arguments give the same household on every run.
library;

import 'package:collection/collection.dart';
import 'package:persona_engine/src/generate/anomalies.dart';
import 'package:persona_engine/src/generate/brokerage.dart';
import 'package:persona_engine/src/generate/cards.dart';
import 'package:persona_engine/src/generate/ledger.dart';
import 'package:persona_engine/src/generate/loans.dart';
import 'package:persona_engine/src/model/anomaly.dart';
import 'package:persona_engine/src/model/household.dart';
import 'package:persona_engine/src/model/investments.dart';
import 'package:persona_engine/src/model/liabilities.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:persona_engine/src/model/recurring_expectation.dart';
import 'package:persona_engine/src/model/schedule.dart';
import 'package:persona_engine/src/random/pcg32.dart';
import 'package:shared_models/shared_models.dart'
    hide Holding, InvestmentTransaction, Liability, Security;

/// The longest window: Plaid accepts injected dates up to 730 days back (`PLAN.md` §4).
const int maxWindowDays = 730;

const Payee _interestEarned = Payee(
  'INTEREST PAYMENT',
  null,
  'INCOME_INTEREST_EARNED',
);

/// Generates [persona]'s household for the [days] ending on [asOf] (1 to 730).
GeneratedHousehold generateHousehold(
  Persona persona, {
  required int seed,
  required LocalDate asOf,
  int days = maxWindowDays,
}) {
  if (days < 1 || days > maxWindowDays) {
    throw RangeError.range(days, 1, maxWindowDays, 'days');
  }
  return _Walk(persona, seed, asOf, days).run();
}

final class _Walk {
  _Walk(this.persona, this.seed, this.asOf, int days)
    : first = asOf.addDays(-(days - 1)) {
    checkAnomalyPool(persona);
    final root = Pcg32.forPersona(persona.id.slug, seed);
    for (final s in persona.incomes) {
      _incomeRng.add(root.fork('income:${s.key}'));
    }
    for (final s in persona.bills) {
      _billRng.add(root.fork('bill:${s.key}'));
    }
    for (final s in persona.subscriptions) {
      _subscriptionRng.add(root.fork('subscription:${s.key}'));
    }
    for (final s in persona.spending) {
      _spendingRng.add(root.fork('spending:${s.key}'));
    }
    final brokerage = persona.brokerage;
    if (brokerage != null) {
      _brokerage = BrokerageBook(
        brokerage,
        accountIdFor(persona.id, brokerage.account),
        root.fork('brokerage'),
        asOf,
        first,
      );
    }
    _anomalies = planAnomalies(persona, root.fork('anomalies'), first, asOf);
    _loans = [
      for (final l in persona.loans)
        LoanCycle(
          l,
          [
            for (final s in persona.disbursements)
              if (s.loan == l.account) s,
          ],
          asOf,
          first,
        ),
    ];
    for (final a in persona.accounts) {
      if (a.type == AccountType.investment) {
        if (persona.brokerage?.account != a.key || a.opening != null) {
          throw ArgumentError(
            '${a.key} needs the brokerage spec and no opening',
          );
        }
        continue;
      }
      if (a.type == AccountType.loan) {
        final loan = _loans.where((l) => l.spec.account == a.key);
        if (loan.length != 1 || a.opening != null) {
          throw ArgumentError('${a.key} needs one loan spec and no opening');
        }
        _openings[a.key] = -loan.single.principal;
      } else {
        _openings[a.key] =
            a.opening ?? (throw ArgumentError('${a.key} needs an opening'));
      }
    }
    ledger = Ledger(persona, asOf, _openings);
    _cards = [for (final c in persona.cards) CardCycle(c, ledger, first)];
  }

  final Persona persona;
  final int seed;
  final LocalDate asOf;
  final LocalDate first;
  late final Ledger ledger;
  final Map<String, Money> _openings = {};

  final List<Pcg32> _incomeRng = [];
  final List<Pcg32> _billRng = [];
  final List<Pcg32> _subscriptionRng = [];
  final List<Pcg32> _spendingRng = [];
  BrokerageBook? _brokerage;
  late final Map<LocalDate, List<PlannedAnomaly>> _anomalies;
  late final List<CardCycle> _cards;
  late final List<LoanCycle> _loans;

  final Map<Schedule, Set<LocalDate>> _occurrences = Map.identity();

  bool _on(Schedule schedule, LocalDate date) => (_occurrences[schedule] ??= {
    ...schedule.occurrences(first, asOf),
  }).contains(date);

  GeneratedHousehold run() {
    for (var d = first; !d.isAfter(asOf); d = d.addDays(1)) {
      _day(d);
    }
    return _finish();
  }

  void _day(LocalDate d) {
    final brokerage = _brokerage;
    brokerage?.walk();
    for (var i = 0; i < persona.incomes.length; i++) {
      final s = persona.incomes[i];
      if (!_on(s.schedule, d)) continue;
      final rng = _incomeRng[i];
      if (s.skipPermille > 0 && rng.chance(s.skipPermille)) continue;
      ledger.postPayee(
        s.account,
        _vary(s.amount, s.varianceBasisPoints, rng),
        d,
        s.payer,
      );
    }
    for (final loan in _loans) {
      loan.day(ledger, d);
    }
    _bills(persona.bills, _billRng, d);
    _bills(persona.subscriptions, _subscriptionRng, d);
    for (final card in _cards) {
      card.run(ledger, d);
    }
    for (final s in persona.transfers) {
      if (!_on(s.schedule, d)) continue;
      if (ledger.balance(s.from) - s.amount >= s.keepAbove) {
        _transfer(s, s.amount, d);
      }
      final sweepAbove = s.sweepAbove;
      if (sweepAbove != null) {
        final excess = (ledger.balance(s.from) - sweepAbove) ~/ 10000 * 10000;
        if (excess.isPositive) _transfer(s, excess, d);
      }
    }
    brokerage?.contributeIfDue(d);
    for (var i = 0; i < persona.spending.length; i++) {
      _spend(persona.spending[i], _spendingRng[i], d);
    }
    for (final a in _anomalies[d] ?? const <PlannedAnomaly>[]) {
      ledger.post(
        account: a.account,
        amount: -Money(a.amountMinor, persona.currency),
        date: d,
        raw: a.raw,
        merchant: a.merchant.name,
        detailed: a.merchant.detailed,
        anomaly: a.kind,
      );
    }
    if (d == d.lastOfMonth) {
      for (final a in persona.accounts) {
        final apy = a.apyBasisPoints;
        if (apy == null) continue;
        final interest = ledger.balance(a.key).multipliedBy(apy, 120000);
        if (interest.isPositive) {
          ledger.postPayee(a.key, interest, d, _interestEarned);
        }
      }
    }
    for (final a in persona.accounts) {
      final from = a.coverFrom;
      if (from == null || !ledger.balance(a.key).isNegative) continue;
      final need = -ledger.balance(a.key);
      final rounded = Money(
        (need.minorUnits + 4999) ~/ 5000 * 5000,
        need.currencyCode,
      );
      final cover = Money.min(rounded, ledger.balance(from));
      if (cover.isPositive) {
        ledger.transfer(
          from: from,
          to: a.key,
          amount: cover,
          date: d,
          outPayee: Payee(
            'ONLINE TRANSFER TO ${a.name.toUpperCase()}',
            null,
            'TRANSFER_OUT_ACCOUNT_TRANSFER',
          ),
          inPayee: Payee(
            'ONLINE TRANSFER FROM ${persona.account(from).name.toUpperCase()}',
            null,
            'TRANSFER_IN_ACCOUNT_TRANSFER',
          ),
        );
      }
    }
  }

  void _bills(List<BillSpec> specs, List<Pcg32> rngs, LocalDate d) {
    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      if (!_on(s.schedule, d)) continue;
      final seasonal = s.seasonal;
      final base = seasonal == null
          ? s.amount
          : s.amount.multipliedBy(seasonal[d.month - 1], 1000);
      ledger.postPayee(
        s.account,
        -_vary(base, s.varianceBasisPoints, rngs[i]),
        d,
        s.payee,
      );
    }
  }

  void _spend(SpendingSpec s, Pcg32 rng, LocalDate d) {
    final rate =
        s.rateMilli *
        s.weekly[d.weekday - 1] *
        s.seasonal[d.month - 1] ~/
        1000000;
    final count = rate ~/ 1000 + (rng.nextInt(1000) < rate % 1000 ? 1 : 0);
    final weights = [for (final m in s.merchants) m.weight];
    for (var n = 0; n < count; n++) {
      final m = s.merchants[rng.pickWeighted(weights)];
      final raw = rng.pick(m.raw);
      final amount = rng.nextIntInRange(m.minMinor, m.maxMinor);
      final lag = s.postLagDays > 0 ? rng.nextInt(s.postLagDays + 1) : 0;
      ledger.post(
        account: s.account,
        amount: Money(-amount, persona.currency),
        date: d,
        posted: d.addDays(lag),
        raw: raw,
        merchant: m.name,
        detailed: m.detailed,
      );
    }
  }

  void _transfer(TransferSpec s, Money amount, LocalDate d) => ledger.transfer(
    from: s.from,
    to: s.to,
    amount: amount,
    date: d,
    outPayee: s.outPayee,
    inPayee: s.inPayee,
  );

  Money _vary(Money base, int basisPoints, Pcg32 rng) => basisPoints == 0
      ? base
      : base.multipliedBy(
          10000 + rng.nextIntInRange(-basisPoints, basisPoints),
          10000,
        );

  GeneratedHousehold _finish() {
    final id = persona.id;
    final entries = ledger.entries.toList();
    mergeSort(
      entries,
      compare: (a, b) {
        final byDate = a.posted.compareTo(b.posted);
        return byDate != 0 ? byDate : a.seq.compareTo(b.seq);
      },
    );
    final midnight = DateTime.utc(asOf.year, asOf.month, asOf.day);
    final transactions = <Transaction>[];
    final idOfSeq = <int, String>{};
    final interest = <String>{};
    final anomalies = <Anomaly>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final txId = 'demo-${id.slug}-t${(i + 1).toString().padLeft(6, '0')}';
      idOfSeq[e.seq] = txId;
      if (e.isInterest) interest.add(txId);
      final kind = e.anomaly;
      if (kind != null) anomalies.add(Anomaly(kind, txId));
      final created = DateTime.utc(e.posted.year, e.posted.month, e.posted.day);
      transactions.add(
        Transaction(
          id: txId,
          accountId: accountIdFor(id, e.account),
          amount: e.amount,
          date: e.posted,
          authorizedDate: e.transacted,
          pending: false,
          name: e.raw,
          merchantName: e.merchant,
          plaidPrimaryCategory: primaryCategoryOf(e.detailed),
          plaidDetailedCategory: e.detailed,
          source: DataSource.demo,
          createdAt: created,
          updatedAt: created,
          syncVersion: 0,
        ),
      );
    }

    final legs = <int, List<LedgerEntry>>{};
    for (final e in ledger.entries) {
      final pair = e.pairId;
      if (pair != null) (legs[pair] ??= []).add(e);
    }
    final transfers = [
      for (final pair in legs.values)
        TransferPair(
          idOfSeq[pair.firstWhere((e) => e.leg == TransferLeg.out).seq]!,
          idOfSeq[pair.firstWhere((e) => e.leg == TransferLeg.into).seq]!,
        ),
    ];

    final brokerage = _brokerage;
    final holdings = brokerage?.holdings(asOf) ?? const <Holding>[];
    final investmentTransactions = <InvestmentTransaction>[
      if (brokerage != null)
        for (var i = 0; i < brokerage.pending.length; i++)
          brokerage.pending[i](
            'demo-${id.slug}-i${(i + 1).toString().padLeft(6, '0')}',
          ),
    ];

    final accounts = <Account>[];
    final openings = <OpeningBalance>[];
    for (var i = 0; i < persona.accounts.length; i++) {
      final a = persona.accounts[i];
      final accountId = accountIdFor(id, a.key);
      final Money balance;
      if (a.type == AccountType.investment) {
        balance = Money.sum([
          for (final h in holdings) h.value,
          brokerage!.cash,
        ], currencyCode: persona.currency);
        openings.add(
          OpeningBalance(accountId, first.addDays(-1), brokerage.openingCash),
        );
      } else {
        final opening = _openings[a.key]!;
        final derived = Money.sum([
          opening,
          for (final e in ledger.entries)
            if (e.account == a.key) e.amount,
        ]);
        if (derived != ledger.balance(a.key)) {
          throw StateError('${a.key} does not close: $derived');
        }
        balance = derived;
        openings.add(OpeningBalance(accountId, first.addDays(-1), opening));
      }
      final limit = a.creditLimit;
      accounts.add(
        Account(
          id: accountId,
          itemId: itemIdFor(id, a.institution),
          type: a.type,
          subtype: a.subtype,
          name: a.name,
          officialName: a.officialName,
          mask: a.mask,
          currencyCode: persona.currency,
          currentBalance: balance,
          availableBalance: switch (a.type) {
            AccountType.depository => balance,
            AccountType.credit when limit != null => limit + balance,
            _ => null,
          },
          creditLimit: limit,
          balancesAsOf: midnight,
          isHidden: false,
          displayOrder: i,
        ),
      );
    }

    return GeneratedHousehold(
      persona: persona,
      seed: seed,
      asOf: asOf,
      window: LocalDateRange(first, asOf.addDays(1)),
      institutions: [
        for (final i in persona.institutions)
          Institution(id: i.plaidId, name: i.name),
      ],
      items: [
        for (final i in persona.institutions)
          Item(
            id: itemIdFor(id, i.key),
            institutionId: i.plaidId,
            status: ItemStatus.healthy,
            lastSuccessfulSyncAt: midnight,
          ),
      ],
      accounts: accounts,
      openingBalances: openings,
      transactions: transactions,
      transfers: transfers,
      interestTransactionIds: interest,
      recurring: _recurring(),
      holdings: holdings,
      openingHoldings: brokerage?.openingHoldings ?? const <Holding>[],
      investmentTransactions: investmentTransactions,
      liabilities: <Liability>[
        for (final c in _cards) c.liability(accountIdFor(id, c.spec.account)),
        for (final l in _loans) _loanLiability(l),
      ],
      anomalies: anomalies,
    );
  }

  LoanLiability _loanLiability(LoanCycle loan) {
    if (loan.principal != -ledger.balance(loan.spec.account)) {
      throw StateError('${loan.spec.key} principal and balance disagree');
    }
    return loan.liability(accountIdFor(persona.id, loan.spec.account));
  }

  List<RecurringExpectation> _recurring() {
    final id = persona.id;
    Money low(Money m, int bp) => m.multipliedBy(10000 - bp, 10000);
    Money high(Money m, int bp) => m.multipliedBy(10000 + bp, 10000);
    RecurringExpectation bill(BillSpec s, {required bool subscription}) {
      final seasonal = s.seasonal ?? const [1000];
      final lowest = seasonal.reduce((a, b) => a < b ? a : b);
      final highest = seasonal.reduce((a, b) => a > b ? a : b);
      return RecurringExpectation(
        key: s.key,
        accountId: accountIdFor(id, s.account),
        name: s.payee.raw,
        merchantName: s.payee.merchant,
        schedule: s.schedule,
        minAmount: low(
          s.amount.multipliedBy(lowest, 1000),
          s.varianceBasisPoints,
        ),
        maxAmount: high(
          s.amount.multipliedBy(highest, 1000),
          s.varianceBasisPoints,
        ),
        isSubscription: subscription,
        isInflow: false,
      );
    }

    return [
      for (final s in persona.incomes)
        if (s.skipPermille == 0)
          RecurringExpectation(
            key: s.key,
            accountId: accountIdFor(id, s.account),
            name: s.payer.raw,
            merchantName: s.payer.merchant,
            schedule: s.schedule,
            minAmount: low(s.amount, s.varianceBasisPoints),
            maxAmount: high(s.amount, s.varianceBasisPoints),
            isSubscription: false,
            isInflow: true,
          ),
      for (final s in persona.bills) bill(s, subscription: false),
      for (final s in persona.subscriptions) bill(s, subscription: true),
      for (final l in _loans)
        if (l.payment != null &&
            l.repaymentStart.isBefore(first) &&
            l.maturity.isAfter(asOf.addMonths(1)))
          RecurringExpectation(
            key: l.spec.key,
            accountId: accountIdFor(id, l.spec.payFrom!),
            name: l.spec.paymentPayee!.raw,
            merchantName: l.spec.paymentPayee!.merchant,
            schedule: l.spec.schedule,
            minAmount: l.payment!,
            maxAmount: l.payment!,
            isSubscription: false,
            isInflow: false,
          ),
    ];
  }
}
