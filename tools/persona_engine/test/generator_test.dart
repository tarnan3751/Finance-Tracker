// The day walk over the fixture persona: shape, order, closure and reproducibility.
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support/fixture_persona.dart';

void main() {
  final asOf = LocalDate(2026, 10, 24);
  final h = generateHousehold(fixturePersona, seed: 1, asOf: asOf);

  test('the window is the requested days ending on the as-of date', () {
    expect(h.window.end, asOf.addDays(1));
    expect(h.window.length, maxWindowDays);
    expect(
      () => generateHousehold(fixturePersona, seed: 1, asOf: asOf, days: 0),
      throwsRangeError,
    );
    expect(
      () => generateHousehold(fixturePersona, seed: 1, asOf: asOf, days: 731),
      throwsRangeError,
    );
  });

  test('transactions are in date order with sequential ids', () {
    for (var i = 0; i < h.transactions.length; i++) {
      final t = h.transactions[i];
      expect(t.id, 'demo-renter-t${(i + 1).toString().padLeft(6, '0')}');
      if (i > 0) expect(t.date.isBefore(h.transactions[i - 1].date), isFalse);
      expect(t.authorizedDate!.isAfter(t.date), isFalse);
    }
  });

  test('every account closes: opening plus transactions is the balance', () {
    for (final a in h.accounts) {
      if (a.type == AccountType.investment) continue;
      final opening = h.openingBalances.firstWhere((o) => o.accountId == a.id);
      final sum = Money.sum([
        opening.amount,
        for (final t in h.transactions)
          if (t.accountId == a.id) t.amount,
      ]);
      expect(sum, a.currentBalance, reason: a.id);
    }
  });

  test('every kind of spec produced something', () {
    final names = {for (final t in h.transactions) t.name};
    expect(
      names,
      containsAll([
        'ACME PAYROLL',
        'GIG PAYOUT',
        'POWER CO',
        'NETFLIX.COM',
        'LOAN PAYMENT',
        'DISBURSEMENT',
        'TUITION',
        'AUTO LOAN PAYMENT',
        'CARD PAYMENT',
        'TO SAVINGS',
        'INTEREST PAYMENT',
        'INTEREST CHARGED',
      ]),
    );
    expect(h.holdings, hasLength(2));
    expect(h.investmentTransactions, isNotEmpty);
    expect(h.liabilities, hasLength(4));
    expect(h.anomalies, hasLength(inInclusiveRange(4, 6)));
    expect(h.interestTransactionIds, isNotEmpty);
  });

  test('the demo plays the institution', () {
    expect(h.items.map((i) => i.status), everyElement(ItemStatus.healthy));
    for (final a in h.accounts) {
      expect(h.items.map((i) => i.id), contains(a.itemId));
      expect(a.balancesAsOf, DateTime.utc(2026, 10, 24));
    }
    final card = h.accounts.firstWhere((a) => a.type == AccountType.credit);
    expect(card.availableBalance, card.creditLimit! + card.currentBalance!);
  });

  test('the same arguments give the same household; another seed differs', () {
    final again = generateHousehold(fixturePersona, seed: 1, asOf: asOf);
    expect(again.transactions, h.transactions);
    expect(again.accounts, h.accounts);
    final other = generateHousehold(fixturePersona, seed: 2, asOf: asOf);
    expect(other.transactions, isNot(h.transactions));
  });

  LoanLiability loan(GeneratedHousehold h, String key) => h.liabilities
      .whereType<LoanLiability>()
      .singleWhere((l) => l.accountId == accountIdFor(PersonaId.renter, key));

  test(
    'a loan opens at its amortized balance and runs on its computed payment',
    () {
      final l = loan(h, 'loan');
      expect(l.originationDate, asOf.addMonths(-40));
      expect(l.monthlyPayment, isNotNull);
      final opening = h.openingBalances.singleWhere(
        (o) => o.accountId == l.accountId,
      );
      expect(opening.amount.isNegative, isTrue);
      expect(-opening.amount < l.originationPrincipal, isTrue);
      final payments = h.transactions.where((t) => t.name == 'LOAN PAYMENT');
      expect(payments.map((t) => t.amount), everyElement(-l.monthlyPayment!));
    },
  );

  test(
    'a matured loan is paid off, reports zero and takes no more payments',
    () {
      final l = loan(h, 'auto');
      expect(l.maturityDate.isBefore(asOf), isTrue);
      expect(l.principalBalance.isZero, isTrue);
      expect(l.nextPaymentAmount, isNull);
      final payments = h.transactions.where(
        (t) => t.name == 'AUTO LOAN PAYMENT',
      );
      expect(payments, isNotEmpty);
      for (final t in payments) {
        expect(t.authorizedDate!.isAfter(l.maturityDate), isFalse);
      }
      final account = h.accounts.singleWhere((a) => a.id == l.accountId);
      expect(account.currentBalance!.isZero, isTrue);
    },
  );

  test(
    'a deferred loan only accrues, grows by disbursements and pays nothing',
    () {
      final l = loan(h, 'grad');
      expect(l.monthlyPayment, isNull);
      expect(l.ytdInterestPaid.isZero, isTrue);
      expect(l.principalBalance > l.originationPrincipal, isTrue);
      for (final d in h.transactions.where((t) => t.name == 'DISBURSEMENT')) {
        final tuition = h.transactions.where(
          (t) => t.name == 'TUITION' && t.authorizedDate == d.authorizedDate,
        );
        expect(tuition, hasLength(1));
      }
    },
  );

  test('ytd interest is what the payments paid since January 1', () {
    final l = loan(h, 'loan');
    final charged = h.transactions.where(
      (t) =>
          t.accountId == l.accountId &&
          h.interestTransactionIds.contains(t.id) &&
          t.authorizedDate!.year == asOf.year,
    );
    final interest = Money.sum([for (final t in charged) -t.amount]);
    expect(l.ytdInterestPaid, interest);
    expect(loan(h, 'auto').ytdInterestPaid.isZero, isTrue);
  });

  test('the state on the as-of date does not depend on the window', () {
    for (final days in [1, 31, 365]) {
      final short = generateHousehold(
        fixturePersona,
        seed: 1,
        asOf: asOf,
        days: days,
      );
      expect(short.holdings, hasLength(h.holdings.length));
      for (var i = 0; i < h.holdings.length; i++) {
        expect(short.holdings[i].quantityMilli, h.holdings[i].quantityMilli);
        expect(short.holdings[i].costBasis, h.holdings[i].costBasis);
        expect(short.holdings[i].price, h.holdings[i].price);
      }
      for (final key in ['loan', 'grad', 'auto']) {
        expect(
          loan(short, key).principalBalance,
          loan(h, key).principalBalance,
          reason: '$key, $days days',
        );
        expect(loan(short, key).ytdInterestPaid, loan(h, key).ytdInterestPaid);
      }
    }
  });

  test('a household that cannot be generated honestly is refused', () {
    Persona withPool(List<Merchant> pool) => Persona(
      id: fixturePersona.id,
      currency: fixturePersona.currency,
      identity: fixturePersona.identity,
      institutions: fixturePersona.institutions,
      accounts: fixturePersona.accounts,
      loans: fixturePersona.loans,
      disbursements: fixturePersona.disbursements,
      spending: fixturePersona.spending,
      brokerage: fixturePersona.brokerage,
      anomalyAccount: 'card',
      anomalyMerchants: pool,
    );
    const cafe = Merchant(
      ['CAFE'],
      'Other Cafe',
      'FOOD_AND_DRINK_COFFEE',
      1,
      2,
    );
    const netflix = Merchant(['X'], 'Grocer', 'FOOD_AND_DRINK_COFFEE', 1, 2);
    for (final pool in [
      [cafe],
      [netflix],
      [
        fixturePersona.anomalyMerchants.first,
        fixturePersona.anomalyMerchants.first,
      ],
    ]) {
      expect(
        () => generateHousehold(withPool(pool), seed: 1, asOf: asOf),
        throwsArgumentError,
      );
    }
    final young = Persona(
      id: fixturePersona.id,
      currency: fixturePersona.currency,
      identity: fixturePersona.identity,
      institutions: fixturePersona.institutions,
      accounts: fixturePersona.accounts,
      loans: [
        for (final l in fixturePersona.loans)
          LoanSpec(
            key: l.key,
            account: l.account,
            kind: l.kind,
            schedule: l.schedule,
            aprBasisPoints: l.aprBasisPoints,
            originationMonthsBefore: 3,
            originationPrincipal: l.originationPrincipal,
            termMonths: l.termMonths,
            loanName: l.loanName,
            deferred: l.deferred,
            payFrom: l.payFrom,
            paymentPayee: l.paymentPayee,
          ),
      ],
      brokerage: fixturePersona.brokerage,
      anomalyAccount: 'card',
      anomalyMerchants: fixturePersona.anomalyMerchants,
    );
    expect(
      () => generateHousehold(young, seed: 1, asOf: asOf),
      throwsArgumentError,
    );
    expect(
      generateHousehold(young, seed: 1, asOf: asOf, days: 60).transactions,
      isNotEmpty,
    );
  });
}
