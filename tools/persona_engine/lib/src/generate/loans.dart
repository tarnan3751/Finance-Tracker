/// Amortizing loans, replayed from their origination: each due date charges the month's
/// interest and, in repayment, takes the payment; disbursements grow a deferred loan.
/// Before the window the replay only moves the principal, so the loan's opening balance
/// is its amortized balance on the window's eve; inside the window it posts to the ledger.
/// No `pow`, no `double`.
library;

import 'package:persona_engine/src/generate/ledger.dart';
import 'package:persona_engine/src/model/liabilities.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:shared_models/shared_models.dart';

const Payee _interest = Payee(
  'INTEREST CHARGED',
  null,
  'BANK_FEES_INTEREST_CHARGE',
);

/// One month's interest on [principal] at [aprBasisPoints]: `principal x APR / 12`,
/// rounded half-even to the minor unit.
Money monthlyInterest(Money principal, int aprBasisPoints) =>
    principal.multipliedBy(aprBasisPoints, 120000);

/// One loan's life from origination to the as-of date.
final class LoanCycle {
  /// A loan with its [disbursements], for a household as of [asOf] whose window starts
  /// on [first]. Throws an [ArgumentError] when the loan originates inside the window.
  LoanCycle(this.spec, this.disbursements, this.asOf, this.first)
    : origination = asOf.addMonths(-spec.originationMonthsBefore),
      _principal = spec.originationPrincipal,
      _interestPaid = Money(0, spec.originationPrincipal.currencyCode) {
    if (!origination.isBefore(first)) {
      throw ArgumentError(
        '${spec.key} originates on $origination, inside the window from $first',
      );
    }
    if (!spec.deferred && disbursements.isNotEmpty) {
      throw ArgumentError(
        '${spec.key}: only a deferred loan takes disbursements',
      );
    }
    payment = spec.deferred ? null : _amortizingPayment();
    final eve = first.addDays(-1);
    final due = spec.schedule.occurrences(origination.addDays(1), eve).toSet();
    final disbursed = {
      for (final s in disbursements)
        for (final d in s.schedule.occurrences(origination.addDays(1), eve))
          d: s,
    };
    for (var d = origination.addDays(1); !d.isAfter(eve); d = d.addDays(1)) {
      final s = disbursed[d];
      if (s != null) _principal += s.amount;
      if (due.contains(d)) _due(d, null);
    }
    _dueInWindow = spec.schedule.occurrences(first, asOf).toSet();
    _disbursedInWindow = {
      for (final s in disbursements)
        for (final d in s.schedule.occurrences(first, asOf)) d: s,
    };
  }

  /// The loan.
  final LoanSpec spec;

  /// Its disbursements.
  final List<DisbursementSpec> disbursements;

  /// The as-of date.
  final LocalDate asOf;

  /// The window's first day.
  final LocalDate first;

  /// When it was made.
  final LocalDate origination;

  /// The fixed payment; null for a deferred loan.
  late final Money? payment;

  Money _principal;
  Money _interestPaid;
  Money? _lastPayment;
  LocalDate? _lastPaymentDate;
  late final Set<LocalDate> _dueInWindow;
  late final Map<LocalDate, DisbursementSpec> _disbursedInWindow;

  /// The scheduled payoff date.
  LocalDate get maturity => origination.addMonths(spec.termMonths);

  /// The first date a payment is due.
  LocalDate get repaymentStart =>
      origination.addMonths(spec.nonRepaymentMonths);

  /// The principal owed now, positive.
  Money get principal => _principal;

  /// Runs [date] inside the window: a disbursement, then a due date.
  void day(Ledger ledger, LocalDate date) {
    final s = _disbursedInWindow[date];
    if (s != null) {
      _principal += s.amount;
      ledger.transfer(
        from: spec.account,
        to: s.to,
        amount: s.amount,
        date: date,
        outPayee: s.payee,
        inPayee: s.payee,
      );
      final paysOut = s.paysOut;
      if (paysOut != null) {
        ledger.postPayee(s.to, -s.paysOutAmount!, date, paysOut);
      }
    }
    if (_dueInWindow.contains(date)) _due(date, ledger);
  }

  void _due(LocalDate date, Ledger? ledger) {
    if (!_principal.isPositive) return;
    final interest = monthlyInterest(_principal, spec.aprBasisPoints);
    _principal += interest;
    if (interest.isPositive && ledger != null) {
      ledger.post(
        account: spec.account,
        amount: -interest,
        date: date,
        raw: _interest.raw,
        merchant: _interest.merchant,
        detailed: _interest.detailed,
        isInterest: true,
      );
    }
    final scheduled = payment;
    if (scheduled == null ||
        date.isBefore(repaymentStart) ||
        date.isAfter(maturity)) {
      return;
    }
    final pay = Money.min(scheduled, _principal);
    _principal -= pay;
    if (date.year == asOf.year) _interestPaid += Money.min(pay, interest);
    _lastPayment = pay;
    _lastPaymentDate = date;
    if (ledger != null) {
      final payee = spec.paymentPayee!;
      ledger.transfer(
        from: spec.payFrom!,
        to: spec.account,
        amount: pay,
        date: date,
        outPayee: payee,
        inPayee: Payee('PAYMENT RECEIVED - THANK YOU', null, payee.detailed),
      );
    }
  }

  /// The smallest whole-cent payment that leaves nothing owed after the last due date
  /// on or before maturity, by bisection over a replay of the due dates.
  Money _amortizingPayment() {
    final dates = spec.schedule.occurrences(origination.addDays(1), maturity);
    final start = repaymentStart;
    int remaining(int payment) {
      var balance = spec.originationPrincipal;
      for (final d in dates) {
        balance += monthlyInterest(balance, spec.aprBasisPoints);
        if (!d.isBefore(start)) {
          balance -= Money.min(Money(payment, balance.currencyCode), balance);
        }
      }
      return balance.minorUnits;
    }

    var low = 1;
    var high = spec.originationPrincipal.minorUnits * 2;
    if (remaining(high) > 0) {
      throw ArgumentError('${spec.key} cannot be repaid within its term');
    }
    while (low < high) {
      final mid = low + (high - low) ~/ 2;
      if (remaining(mid) > 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return Money(low, spec.originationPrincipal.currencyCode);
  }

  /// The loan's liability record on the as-of date.
  LoanLiability liability(String accountId) {
    final active = _principal.isPositive && payment != null;
    final next = spec.schedule.occurrences(asOf.addDays(1), asOf.addDays(70));
    return LoanLiability(
      accountId: accountId,
      kind: spec.kind,
      loanName: spec.loanName,
      aprBasisPoints: spec.aprBasisPoints,
      principalBalance: _principal,
      originationDate: origination,
      originationPrincipal: spec.originationPrincipal,
      termMonths: spec.termMonths,
      nonRepaymentMonths: spec.nonRepaymentMonths,
      monthlyPayment: payment,
      ytdInterestPaid: _interestPaid,
      nextPaymentAmount: active ? Money.min(payment!, _principal) : null,
      nextPaymentDueDate: active ? next.first : null,
      lastPaymentAmount: _lastPayment,
      lastPaymentDate: _lastPaymentDate,
    );
  }
}
