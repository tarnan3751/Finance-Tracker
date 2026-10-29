// Invariants every household must hold, shared by the per-persona tests and the property
// tests over many seeds. Each returns a list of violations, empty when the household holds.
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart'
    hide Holding, InvestmentTransaction, Security;

/// Opening plus transactions is each non-investment account's balance; an investment
/// account's balance is its holdings plus its cash.
List<String> closureViolations(GeneratedHousehold h) {
  final problems = <String>[];
  for (final a in h.accounts) {
    if (a.type == AccountType.investment) {
      final cash = Money.sum([
        h.openingBalances.singleWhere((o) => o.accountId == a.id).amount,
        for (final t in h.investmentTransactions)
          if (t.accountId == a.id)
            t.type == InvestmentTransactionType.cash ? t.amount : -t.amount,
      ], currencyCode: a.currencyCode);
      final value = Money.sum([
        for (final x in h.holdings)
          if (x.accountId == a.id) x.value,
        cash,
      ]);
      if (value != a.currentBalance) {
        problems.add('${a.id}: $value != ${a.currentBalance}');
      }
      continue;
    }
    final opening = h.openingBalances.singleWhere((o) => o.accountId == a.id);
    final sum = Money.sum([
      opening.amount,
      for (final t in h.transactions)
        if (t.accountId == a.id) t.amount,
    ]);
    if (sum != a.currentBalance) {
      problems.add('${a.id}: $sum != ${a.currentBalance}');
    }
  }
  return problems;
}

/// Every transfer's legs are equal and opposite, on one date, on two accounts.
List<String> transferViolations(GeneratedHousehold h) {
  final byId = {for (final t in h.transactions) t.id: t};
  return [
    for (final p in h.transfers)
      if (byId[p.outTransactionId]!.amount !=
              -byId[p.inTransactionId]!.amount ||
          byId[p.outTransactionId]!.authorizedDate !=
              byId[p.inTransactionId]!.authorizedDate ||
          byId[p.outTransactionId]!.accountId ==
              byId[p.inTransactionId]!.accountId ||
          !byId[p.outTransactionId]!.amount.isNegative)
        '${p.outTransactionId}/${p.inTransactionId}',
  ];
}

/// No date after the as-of date or before the window; posted on or after transacted.
List<String> dateViolations(GeneratedHousehold h) => [
  for (final t in h.transactions)
    if (t.date.isAfter(h.asOf) ||
        t.authorizedDate!.isBefore(h.window.start) ||
        t.authorizedDate!.isAfter(t.date))
      '${t.id} ${t.authorizedDate} ${t.date}',
  for (final t in h.investmentTransactions)
    if (!h.window.contains(t.date)) '${t.id} ${t.date}',
];

/// Every depository account ends every day, by posting date, at or above zero.
List<String> depositoryFloorViolations(GeneratedHousehold h) {
  final problems = <String>[];
  for (final a in h.accounts.where((a) => a.type == AccountType.depository)) {
    var balance = h.openingBalances
        .singleWhere((o) => o.accountId == a.id)
        .amount;
    final byDay = <LocalDate, List<Money>>{};
    for (final t in h.transactions.where((t) => t.accountId == a.id)) {
      (byDay[t.date] ??= []).add(t.amount);
    }
    for (var d = h.window.start; d.isBefore(h.window.end); d = d.addDays(1)) {
      balance = Money.sum([balance, ...?byDay[d]]);
      if (balance.isNegative) {
        problems.add('${a.id} $d $balance');
        break;
      }
    }
  }
  return problems;
}

/// Plaid's custom-user limits hold: ten accounts and the request budget; each custom
/// user carries its institution's newest whole days, and the carried and left-out rows
/// partition the household's transactions.
List<String> sandboxViolations(GeneratedHousehold h) {
  final problems = <String>[];
  final users = sandboxUsers(h);
  final carried = <String>{};
  for (final u in users) {
    final key = u.split.institution.key;
    final accounts = u.config['override_accounts']! as List<Object?>;
    if (accounts.length > 10) problems.add('$key: ${accounts.length} accounts');
    final size = sandboxRequestBytes(u.config);
    if (size > sandboxConfigByteBudget) problems.add('$key: $size bytes');
    for (final t in [...u.split.customUser, ...u.split.leftOut]) {
      if (!carried.add(t.id)) problems.add('$key: ${t.id} twice');
    }
    final kept = u.split.customUser;
    final left = u.split.leftOut;
    if (kept.isNotEmpty &&
        left.isNotEmpty &&
        !left.first.date.isBefore(kept.first.date)) {
      problems.add(
        '$key: ${left.first.date} left out, ${kept.first.date} kept',
      );
    }
  }
  if (h.window.start.daysUntil(h.asOf) > 729) problems.add('window too long');
  final expected = {for (final t in h.transactions) t.id};
  if (carried.length != expected.length) {
    problems.add('split carries ${carried.length} of ${expected.length}');
  }
  return problems;
}

/// Every record the household holds is `demo`.
List<String> provenanceViolations(GeneratedHousehold h) => [
  for (final t in h.transactions)
    if (t.source != DataSource.demo) t.id,
  for (final t in h.investmentTransactions)
    if (t.source != DataSource.demo) t.id,
];

/// Every loan replays from its opening balance through the window: interest each due
/// date, the computed payment from repayment start to maturity, disbursements on a
/// deferred loan; it ends at its reported principal, and a matured loan is at zero.
List<String> loanViolations(GeneratedHousehold h) {
  final problems = <String>[];
  for (final l in h.liabilities.whereType<LoanLiability>()) {
    final spec = h.persona.loans.singleWhere(
      (s) => accountIdFor(h.persona.id, s.account) == l.accountId,
    );
    var principal = -h.openingBalances
        .singleWhere((o) => o.accountId == l.accountId)
        .amount;
    final onLoan = h.transactions.where((t) => t.accountId == l.accountId);
    final byDay = <LocalDate, List<Transaction>>{};
    for (final t in onLoan) {
      (byDay[t.authorizedDate!] ??= []).add(t);
    }
    final after = l.originationDate.addDays(1);
    final start = h.window.start.isAfter(after) ? h.window.start : after;
    final disbursed = {
      for (final s in h.persona.disbursements)
        if (s.loan == spec.account)
          for (final d in s.schedule.occurrences(start, h.asOf)) d: s.amount,
    };
    final due = spec.schedule.occurrences(start, h.asOf).toSet();
    final repaymentStart = l.originationDate.addMonths(l.nonRepaymentMonths);
    var expected = 0;
    for (var d = start; !d.isAfter(h.asOf); d = d.addDays(1)) {
      final today = byDay[d] ?? const <Transaction>[];
      final disbursement = disbursed[d];
      if (disbursement != null) {
        principal += disbursement;
        expected++;
      }
      if (!due.contains(d) || !principal.isPositive) continue;
      final interest = monthlyInterest(principal, l.aprBasisPoints);
      if (interest.isPositive) {
        final charges = today.where(
          (t) => h.interestTransactionIds.contains(t.id),
        );
        if (charges.length != 1 || charges.single.amount != -interest) {
          problems.add('${spec.key} $d interest');
        }
        expected++;
      }
      principal += interest;
      final payment = l.monthlyPayment;
      if (payment == null ||
          d.isBefore(repaymentStart) ||
          d.isAfter(l.maturityDate)) {
        continue;
      }
      final pay = Money.min(payment, principal);
      final paid = today.where(
        (t) => t.amount.isPositive && !h.interestTransactionIds.contains(t.id),
      );
      if (paid.length != 1 || paid.single.amount != pay) {
        problems.add('${spec.key} $d payment');
      }
      principal -= pay;
      expected++;
    }
    if (onLoan.length != expected) {
      problems.add(
        '${spec.key}: ${onLoan.length} transactions, $expected expected',
      );
    }
    final account = h.accounts.singleWhere((a) => a.id == l.accountId);
    if (-account.currentBalance! != principal ||
        l.principalBalance != principal) {
      problems.add(
        '${spec.key}: ends at ${l.principalBalance}, replay $principal',
      );
    }
    if (l.monthlyPayment != null &&
        !l.maturityDate.isAfter(h.asOf) &&
        !principal.isZero) {
      problems.add('${spec.key}: matured with $principal owed');
    }
  }
  return problems;
}

/// Each position is its opening position plus the window's buys, at the buys' cost.
List<String> positionViolations(GeneratedHousehold h) {
  final problems = <String>[];
  for (final holding in h.holdings) {
    final ticker = holding.security.ticker;
    final opening = h.openingHoldings.where((x) => x.security.ticker == ticker);
    final buys = h.investmentTransactions.where(
      (t) =>
          t.type == InvestmentTransactionType.buy &&
          t.security!.ticker == ticker,
    );
    final quantity = buys.fold<int>(
      opening.fold<int>(0, (n, x) => n + x.quantityMilli),
      (n, t) => n + t.quantityMilli,
    );
    final cost = Money.sum([
      for (final x in opening) x.costBasis,
      for (final t in buys) t.amount,
    ], currencyCode: holding.costBasis.currencyCode);
    if (quantity != holding.quantityMilli || cost != holding.costBasis) {
      problems.add('$ticker: $quantity $cost');
    }
    for (final t in buys) {
      if (t.amount != t.price!.multipliedBy(t.quantityMilli, 1000)) {
        problems.add('${t.id} cost');
      }
    }
  }
  return problems;
}

/// Every new-merchant anomaly's merchant appears exactly once in the household.
List<String> anomalyViolations(GeneratedHousehold h) {
  final byId = {for (final t in h.transactions) t.id: t};
  final problems = <String>[];
  for (final a in h.anomalies.where((a) => a.kind == AnomalyKind.newMerchant)) {
    final merchant = byId[a.transactionId]!.merchantName;
    final count = h.transactions
        .where((t) => t.merchantName == merchant)
        .length;
    if (merchant == null || count != 1) {
      problems.add('$merchant appears $count times');
    }
  }
  return problems;
}

/// Every invariant at once.
List<String> allViolations(GeneratedHousehold h) => [
  ...closureViolations(h),
  ...transferViolations(h),
  ...dateViolations(h),
  ...depositoryFloorViolations(h),
  ...provenanceViolations(h),
  ...loanViolations(h),
  ...positionViolations(h),
  ...anomalyViolations(h),
  ...sandboxViolations(h),
];
