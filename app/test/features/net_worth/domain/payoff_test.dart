// Payoff projections (payoff.dart): worked examples, the half-even tie, a zero rate, the
// "never" boundary, the cap, invariants over many inputs, the terms picked from a
// liability, and agreement with the persona engine's amortization of the family's loans.
import 'package:finance_tracker/features/net_worth/domain/payoff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart' as engine;
import 'package:shared_models/shared_models.dart';

final LocalDate today = LocalDate(2026, 10, 24);

Money usd(int cents) => Money(cents, 'USD');

PayoffProjection project(int owed, int rate, int payment, [int extra = 0]) =>
    projectPayoff(
      owed: usd(owed),
      rateBasisPoints: rate,
      payment: usd(payment),
      extra: usd(extra),
      today: today,
    );

Liability liability(
  LiabilityKind kind, {
  int? rate,
  List<LiabilityApr> aprs = const [],
  Money? minimum,
  Money? monthly,
}) => Liability(
  accountId: 'a',
  kind: kind,
  source: DataSource.plaid,
  interestRateBasisPoints: rate,
  aprs: aprs,
  minimumPaymentAmount: minimum,
  nextMonthlyPayment: monthly,
  payload: const {},
);

void main() {
  test('a worked example, month by month', () {
    // $1,000.00 at 12 %: 1 % a month. Month 1: interest 1000, balance 101000 − 50000 =
    // 51000; month 2: interest 510, 51510 − 50000 = 1510; month 3: interest 15.1 → 15,
    // 1525 paid.
    expect(
      project(100000, 1200, 50000),
      PaidOff(
        months: 3,
        totalInterest: usd(1525),
        date: LocalDate(2027, 1, 24),
        lastPayment: usd(1525),
      ),
    );
  });

  test('interest rounds half to even, once a month', () {
    // At 1 % a month: 0.5 → 0, 1.5 → 2, 2.5 → 2.
    expect(monthlyInterestOn(usd(50), 1200), usd(0));
    expect(monthlyInterestOn(usd(150), 1200), usd(2));
    expect(monthlyInterestOn(usd(250), 1200), usd(2));
    expect(
      project(150, 1200, 100),
      PaidOff(
        months: 2,
        // 152 − 100 = 52 left, then 0.52 → 1 of interest.
        totalInterest: usd(2 + 1),
        date: LocalDate(2026, 12, 24),
        lastPayment: usd(53),
      ),
    );
  });

  test('a zero rate is the balance over the payment, rounded up', () {
    final PaidOff p = project(100001, 0, 10000) as PaidOff;
    expect(p.months, 11);
    expect(p.totalInterest, usd(0));
    expect(p.lastPayment, usd(1));
  });

  test(
    'never when the payment does not exceed the first month\'s interest',
    () {
      // $10,000.00 at 24 %: 200.00 interest a month.
      expect(project(1000000, 2400, 20000), isA<NeverPaidOff>());
      expect(
        (project(1000000, 2400, 15000) as NeverPaidOff).firstInterest,
        usd(20000),
      );
      expect(project(1000000, 2400, 20001), isA<PaidOff>());
      // The extra counts: 150.00 + 50.01 covers it.
      expect(project(1000000, 2400, 15000, 5001), isA<PaidOff>());
      expect(project(100, 0, 0), isA<NeverPaidOff>());
    },
  );

  test('over the cap is BeyondCap', () {
    // A cent over the interest: about 500 months at 2 % a month, far more at 0.5 %.
    expect(project(1000000, 2400, 20001), isA<PaidOff>());
    expect(project(100000000, 600, 500001), isA<BeyondCap>());
  });

  test('nothing owed', () {
    expect(project(0, 1200, 100), isA<NothingOwed>());
    expect(project(-500, 1200, 100), isA<NothingOwed>());
  });

  test('an extra payment pays off sooner with less interest', () {
    final PaidOff base = project(2000000, 1999, 50000) as PaidOff;
    final PaidOff more = project(2000000, 1999, 50000, 10000) as PaidOff;
    expect(more.months, lessThan(base.months));
    expect(more.totalInterest, lessThan(base.totalInterest));
  });

  test('invariants: what is paid is the debt plus the interest, exactly', () {
    int state = 7;
    int next(int bound) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return state % bound;
    }

    for (int i = 0; i < 300; i++) {
      final int owed = 1 + next(5000000);
      final int rate = next(3000);
      final int payment = 1 + next(200000);
      final PayoffProjection p = project(owed, rate, payment);
      if (p is! PaidOff) continue;
      // Replay: every payment but the last is the full payment.
      expect(p.lastPayment.minorUnits, inInclusiveRange(1, payment));
      expect(
        (p.months - 1) * payment + p.lastPayment.minorUnits,
        owed + p.totalInterest.minorUnits,
        reason: 'owed $owed rate $rate payment $payment',
      );
    }
  });

  test('a negative input or two currencies is refused', () {
    expect(() => project(100, -1, 10), throwsArgumentError);
    expect(() => project(100, 100, -10), throwsArgumentError);
    expect(() => project(100, 100, 10, -1), throwsArgumentError);
    expect(
      () => projectPayoff(
        owed: usd(100),
        rateBasisPoints: 0,
        payment: Money(10, 'EUR'),
        today: today,
      ),
      throwsA(isA<CurrencyMismatchException>()),
    );
  });

  group('payoffTermsOf', () {
    test('a mortgage: its rate and next monthly payment', () {
      final PayoffTerms t = payoffTermsOf(
        usd(-30000000),
        liability(
          LiabilityKind.mortgage,
          rate: 625,
          monthly: usd(215000),
          minimum: usd(1),
        ),
      );
      expect(t.owed, usd(30000000));
      expect(t.rateBasisPoints, 625);
      expect(t.rateSource, PayoffInputSource.reported);
      expect(t.payment, usd(215000));
      expect(t.paymentKind, PayoffPaymentKind.monthly);
    });

    test('a card: the purchase APR, else the first; the minimum', () {
      const LiabilityApr cash = LiabilityApr(
        type: 'cash_apr',
        percentageBasisPoints: 2999,
      );
      const LiabilityApr purchase = LiabilityApr(
        type: 'purchase_apr',
        percentageBasisPoints: 2199,
      );
      expect(
        payoffTermsOf(
          usd(-5000),
          liability(
            LiabilityKind.credit,
            aprs: [cash, purchase],
            minimum: usd(2500),
          ),
        ).rateBasisPoints,
        2199,
      );
      final PayoffTerms t = payoffTermsOf(
        usd(-5000),
        liability(LiabilityKind.credit, aprs: [cash], minimum: usd(2500)),
      );
      expect(t.rateBasisPoints, 2999);
      expect(t.payment, usd(2500));
      expect(t.paymentKind, PayoffPaymentKind.minimum);
    });

    test('what the bank does not report comes from the entries', () {
      final PayoffTerms none = payoffTermsOf(usd(-100), null);
      expect(none.rateBasisPoints, isNull);
      expect(none.payment, isNull);
      expect(none.rateSource, isNull);
      final PayoffTerms entered = payoffTermsOf(
        usd(-100),
        null,
        enteredRate: 489,
        enteredPayment: usd(40000),
      );
      expect(entered.rateBasisPoints, 489);
      expect(entered.rateSource, PayoffInputSource.entered);
      expect(entered.payment, usd(40000));
      expect(entered.paymentKind, PayoffPaymentKind.entered);
      // A reported value wins over an entry.
      final PayoffTerms reported = payoffTermsOf(
        usd(-100),
        liability(LiabilityKind.student, rate: 500, minimum: usd(9000)),
        enteredRate: 489,
        enteredPayment: usd(40000),
      );
      expect(reported.rateBasisPoints, 500);
      expect(reported.payment, usd(9000));
      // An entry in another currency is not used.
      expect(
        payoffTermsOf(usd(-100), null, enteredPayment: Money(1, 'EUR')).payment,
        isNull,
      );
    });

    test('an account in credit owes nothing', () {
      expect(payoffTermsOf(usd(300), null).owed, usd(0));
    });
  });

  test('agrees with the engine\'s amortization of the family\'s loans', () {
    final engine.DemoSeed seed = engine.generateDemoSeed(
      engine.PersonaId.family,
      1,
      today,
    );
    final List<engine.LoanLiability> loans = [
      for (final engine.Liability l in seed.household.liabilities)
        if (l is engine.LoanLiability && l.monthlyPayment != null) l,
    ];
    expect(loans, hasLength(3)); // the mortgage and two auto loans
    for (final engine.LoanLiability loan in loans) {
      final PaidOff p = projectPayoff(
        owed: loan.principalBalance,
        rateBasisPoints: loan.aprBasisPoints,
        payment: loan.monthlyPayment!,
        today: today,
      ) as PaidOff;
      // The engine amortizes each loan to its maturity with this payment, charging the
      // same rounded interest each due date, so the projection from today's principal
      // ends with the due date on or before the maturity.
      final LocalDate due = loan.nextPaymentDueDate!;
      int remaining = 0;
      while (!due.addMonths(remaining).isAfter(loan.maturityDate)) {
        remaining++;
      }
      expect(p.months, remaining, reason: loan.accountId);
    }
  });
}
