/// A liability's payoff projection (`docs/reference/net-worth.md`, **Payoff**; `PLAN.md`
/// §12 "Payoff projections", "6b plan rulings"). Pure Dart, integer `Money` only.
///
/// Monthly amortization from the amount owed: each month the interest is
/// balance × rate ÷ 12 ÷ 10000 (the rate in basis points), rounded half to even once, as
/// the persona engine charges it; the balance grows by it and falls by the payment, the
/// last payment being what is left. The projection stops when nothing is owed, says
/// "never" when the payment does not exceed the first month's interest (the balance
/// would never fall), and gives up past [payoffMonthCap] months.
///
/// [payoffTermsOf] picks the inputs from what the bank reports: the rate is the
/// liability's interest rate, else its purchase APR, else its first APR; the payment its
/// minimum (cards, student loans) or next monthly payment (mortgages). What the bank does
/// not report the user may enter.
library;

import 'package:shared_models/shared_models.dart';

/// The longest projection, in months: fifty years.
const int payoffMonthCap = 600;

/// What [projectPayoff] found.
sealed class PayoffProjection {
  const PayoffProjection();
}

/// Nothing is owed.
final class NothingOwed extends PayoffProjection {
  const NothingOwed();
}

/// Paid off after [months] payments, the last on [date] and of [lastPayment], having
/// paid [totalInterest] in interest.
final class PaidOff extends PayoffProjection {
  const PaidOff({
    required this.months,
    required this.totalInterest,
    required this.date,
    required this.lastPayment,
  });

  final int months;
  final Money totalInterest;
  final LocalDate date;
  final Money lastPayment;

  @override
  bool operator ==(Object other) =>
      other is PaidOff &&
      other.months == months &&
      other.totalInterest == totalInterest &&
      other.date == date &&
      other.lastPayment == lastPayment;

  @override
  int get hashCode => Object.hash(months, totalInterest, date, lastPayment);

  @override
  String toString() =>
      'PaidOff($months months, interest $totalInterest, $date, last $lastPayment)';
}

/// Never paid off: the payment does not exceed [firstInterest], the first month's
/// interest.
final class NeverPaidOff extends PayoffProjection {
  const NeverPaidOff(this.firstInterest);

  final Money firstInterest;
}

/// Still owed after [payoffMonthCap] months.
final class BeyondCap extends PayoffProjection {
  const BeyondCap();
}

/// One month's interest on [balance] at [rateBasisPoints] a year, rounded half to even.
Money monthlyInterestOn(Money balance, int rateBasisPoints) =>
    balance.multipliedBy(rateBasisPoints, 120000);

/// The payoff of [owed] (positive when owed) at [rateBasisPoints] a year with [payment]
/// plus [extra] each month, the first a month after [today]. Every amount in one
/// currency; a negative rate, payment or extra is an [ArgumentError].
PayoffProjection projectPayoff({
  required Money owed,
  required int rateBasisPoints,
  required Money payment,
  Money? extra,
  required LocalDate today,
}) {
  final Money monthly = payment + (extra ?? Money.zero(payment.currencyCode));
  if (rateBasisPoints < 0 || payment.isNegative || monthly < payment) {
    throw ArgumentError('negative rate, payment or extra');
  }
  if (owed.currencyCode != payment.currencyCode) {
    throw CurrencyMismatchException(owed.currencyCode, payment.currencyCode);
  }
  if (!owed.isPositive) return const NothingOwed();
  final Money first = monthlyInterestOn(owed, rateBasisPoints);
  if (monthly <= first) return NeverPaidOff(first);
  Money balance = owed;
  Money interest = Money.zero(owed.currencyCode);
  for (int month = 1; month <= payoffMonthCap; month++) {
    final Money charged = monthlyInterestOn(balance, rateBasisPoints);
    interest += charged;
    balance += charged;
    final Money paid = Money.min(monthly, balance);
    balance -= paid;
    if (balance.isZero) {
      return PaidOff(
        months: month,
        totalInterest: interest,
        date: today.addMonths(month),
        lastPayment: paid,
      );
    }
  }
  return const BeyondCap();
}

/// Where a payoff rate came from.
enum PayoffInputSource { reported, entered }

/// Which payment a projection uses: the bank's minimum, its monthly payment (a
/// mortgage's), or the user's.
enum PayoffPaymentKind { minimum, monthly, entered }

/// The inputs of a liability's projection: what is [owed] (positive when owed), the rate
/// and the payment with where each came from (null when neither the bank nor the user
/// gave one).
typedef PayoffTerms = ({
  Money owed,
  int? rateBasisPoints,
  PayoffInputSource? rateSource,
  Money? payment,
  PayoffPaymentKind? paymentKind,
});

/// The terms for an account shown with [balance] (the app's sign, negative when owed)
/// and its [liability] detail when the bank reports one, the user's [enteredRate] and
/// [enteredPayment] filling what the bank does not report.
PayoffTerms payoffTermsOf(
  Money balance,
  Liability? liability, {
  int? enteredRate,
  Money? enteredPayment,
}) {
  final int? reportedRate =
      liability?.interestRateBasisPoints ??
      liability?.aprs
          .where((a) => a.type == 'purchase_apr')
          .firstOrNull
          ?.percentageBasisPoints ??
      liability?.aprs.firstOrNull?.percentageBasisPoints;
  final Money? reportedPayment = switch (liability?.kind) {
    LiabilityKind.mortgage => liability?.nextMonthlyPayment,
    LiabilityKind.credit ||
    LiabilityKind.student => liability?.minimumPaymentAmount,
    null => null,
  };
  final Money? payment = reportedPayment?.currencyCode == balance.currencyCode
      ? reportedPayment
      : null;
  final Money? entered = enteredPayment?.currencyCode == balance.currencyCode
      ? enteredPayment
      : null;
  return (
    owed: balance.isNegative ? -balance : Money.zero(balance.currencyCode),
    rateBasisPoints: reportedRate ?? enteredRate,
    rateSource: reportedRate != null
        ? PayoffInputSource.reported
        : enteredRate != null
        ? PayoffInputSource.entered
        : null,
    payment: payment ?? entered,
    paymentKind: payment != null
        ? (liability?.kind == LiabilityKind.mortgage
              ? PayoffPaymentKind.monthly
              : PayoffPaymentKind.minimum)
        : entered != null
        ? PayoffPaymentKind.entered
        : null,
  );
}
