/// Credit card statements: close, interest on a carried balance, and the paired payment
/// from checking.
library;

import 'package:persona_engine/src/generate/ledger.dart';
import 'package:persona_engine/src/model/liabilities.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:shared_models/shared_models.dart';

const Payee _interest = Payee(
  'INTEREST CHARGE ON PURCHASES',
  null,
  'BANK_FEES_INTEREST_CHARGE',
);

/// One card's statement cycle.
final class CardCycle {
  /// A cycle whose last statement closed before [first], carrying the opening balance
  /// owed; its payment is pending if that statement's due date is in the window.
  CardCycle(this.spec, Ledger ledger, LocalDate first) {
    var close = LocalDate(first.year, first.month, spec.closeDay);
    if (!close.isBefore(first)) close = close.addMonths(-1);
    _statementDate = close;
    _statement = _owed(ledger);
    _minimum = _minimumOf(_statement);
    _paidSinceClose = Money(0, _statement.currencyCode);
    final due = close.addDays(spec.dueAfterDays);
    _due = due.isBefore(first) ? null : due;
  }

  /// The card.
  final CardSpec spec;

  late LocalDate _statementDate;
  late Money _statement;
  late Money _minimum;
  LocalDate? _due;
  late Money _paidSinceClose;
  Money? _lastPayment;
  LocalDate? _lastPaymentDate;

  /// Runs [date]: the payment when it is due, then the close when it is the closing day.
  void run(Ledger ledger, LocalDate date) {
    if (date == _due) _pay(ledger, date);
    if (date.day == spec.closeDay) _close(ledger, date);
  }

  void _pay(Ledger ledger, LocalDate date) {
    final remaining = _statement - _paidSinceClose;
    if (!remaining.isPositive) return;
    final target = _statement.multipliedBy(spec.payBasisPoints, 10000);
    final available = ledger.balance(spec.payFrom) - spec.keepAbove;
    var pay = Money.min(target, available);
    pay = Money.max(pay, Money.min(_minimum, remaining));
    pay = Money.min(pay, remaining);
    if (!pay.isPositive) return;
    ledger.transfer(
      from: spec.payFrom,
      to: spec.account,
      amount: pay,
      date: date,
      outPayee: spec.paymentPayee,
      inPayee: Payee('PAYMENT - THANK YOU', null, spec.paymentPayee.detailed),
    );
    _paidSinceClose += pay;
    _lastPayment = pay;
    _lastPaymentDate = date;
  }

  void _close(Ledger ledger, LocalDate date) {
    final carried = _statement - _paidSinceClose;
    if (carried.isPositive) {
      final interest = carried.multipliedBy(spec.aprBasisPoints, 120000);
      if (interest.isPositive) {
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
    }
    _statementDate = date;
    _statement = _owed(ledger);
    _minimum = _minimumOf(_statement);
    _paidSinceClose = Money(0, _statement.currencyCode);
    _due = date.addDays(spec.dueAfterDays);
  }

  Money _owed(Ledger ledger) {
    final owed = -ledger.balance(spec.account);
    return owed.isNegative ? Money(0, owed.currencyCode) : owed;
  }

  Money _minimumOf(Money statement) => Money.min(
    statement,
    Money.max(statement.percent(spec.minimumBasisPoints), spec.minimumFloor),
  );

  /// The card's liability record on the as-of date.
  CreditLiability liability(String accountId) => CreditLiability(
    accountId: accountId,
    aprBasisPoints: spec.aprBasisPoints,
    lastStatementBalance: _statement,
    lastStatementDate: _statementDate,
    minimumPayment: _minimum,
    nextPaymentDueDate: _statementDate.addDays(spec.dueAfterDays),
    lastPaymentAmount: _lastPayment,
    lastPaymentDate: _lastPaymentDate,
  );
}
