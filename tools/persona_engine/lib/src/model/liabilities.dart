/// Liability detail for cards and loans, which `shared_models` does not model yet. The
/// fields follow what Plaid's Liabilities product reports, computed from the generated
/// history as of the as-of date.
library;

import 'package:meta/meta.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:shared_models/shared_models.dart';

/// A card or loan's liability record.
@immutable
sealed class Liability {
  const Liability(this.accountId);

  /// The account.
  final String accountId;

  /// The JSON form.
  Map<String, Object?> toJson();
}

/// A credit card's statement and payment state.
final class CreditLiability extends Liability {
  /// A card's liability.
  const CreditLiability({
    required String accountId,
    required this.aprBasisPoints,
    required this.lastStatementBalance,
    required this.lastStatementDate,
    required this.minimumPayment,
    required this.nextPaymentDueDate,
    this.lastPaymentAmount,
    this.lastPaymentDate,
  }) : super(accountId);

  /// The purchase APR.
  final int aprBasisPoints;

  /// The balance owed at the last close, positive.
  final Money lastStatementBalance;

  /// The last close.
  final LocalDate lastStatementDate;

  /// The minimum payment on that statement.
  final Money minimumPayment;

  /// When it is due.
  final LocalDate nextPaymentDueDate;

  /// The last payment.
  final Money? lastPaymentAmount;

  /// Its date.
  final LocalDate? lastPaymentDate;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'credit',
    'account_id': accountId,
    'apr_basis_points': aprBasisPoints,
    'last_statement_balance': lastStatementBalance.toJson(),
    'last_statement_date': lastStatementDate.toIso(),
    'minimum_payment': minimumPayment.toJson(),
    'next_payment_due_date': nextPaymentDueDate.toIso(),
    'last_payment_amount': lastPaymentAmount?.toJson(),
    'last_payment_date': lastPaymentDate?.toIso(),
  };
}

/// An amortizing loan's state: a mortgage, an auto loan or a student loan.
final class LoanLiability extends Liability {
  /// A loan's liability.
  const LoanLiability({
    required String accountId,
    required this.kind,
    required this.loanName,
    required this.aprBasisPoints,
    required this.principalBalance,
    required this.originationDate,
    required this.originationPrincipal,
    required this.termMonths,
    required this.nonRepaymentMonths,
    required this.monthlyPayment,
    required this.ytdInterestPaid,
    this.nextPaymentAmount,
    this.nextPaymentDueDate,
    this.lastPaymentAmount,
    this.lastPaymentDate,
  }) : super(accountId);

  /// The kind.
  final LoanKind kind;

  /// The servicer's name for it.
  final String loanName;

  /// The annual rate.
  final int aprBasisPoints;

  /// The principal owed on the as-of date, positive, or zero once paid off.
  final Money principalBalance;

  /// When it was made.
  final LocalDate originationDate;

  /// How much was lent.
  final Money originationPrincipal;

  /// The term.
  final int termMonths;

  /// A student loan's months before repayment.
  final int nonRepaymentMonths;

  /// The fixed monthly payment; null for a loan in deferment.
  final Money? monthlyPayment;

  /// Interest paid by payments in the as-of date's calendar year; none in deferment.
  final Money ytdInterestPaid;

  /// The next payment, null in deferment or once paid off.
  final Money? nextPaymentAmount;

  /// Its due date.
  final LocalDate? nextPaymentDueDate;

  /// The last payment.
  final Money? lastPaymentAmount;

  /// Its date.
  final LocalDate? lastPaymentDate;

  /// The scheduled payoff date.
  LocalDate get maturityDate => originationDate.addMonths(termMonths);

  @override
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'account_id': accountId,
    'loan_name': loanName,
    'apr_basis_points': aprBasisPoints,
    'principal_balance': principalBalance.toJson(),
    'origination_date': originationDate.toIso(),
    'origination_principal': originationPrincipal.toJson(),
    'term_months': termMonths,
    'maturity_date': maturityDate.toIso(),
    'non_repayment_months': nonRepaymentMonths,
    'monthly_payment': monthlyPayment?.toJson(),
    'ytd_interest_paid': ytdInterestPaid.toJson(),
    'next_payment_amount': nextPaymentAmount?.toJson(),
    'next_payment_due_date': nextPaymentDueDate?.toIso(),
    'last_payment_amount': lastPaymentAmount?.toJson(),
    'last_payment_date': lastPaymentDate?.toIso(),
  };
}
