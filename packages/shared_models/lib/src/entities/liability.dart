/// The liability detail of a card or loan account, as Plaid's Liabilities product reports
/// it (`PLAN.md` §12, "Liabilities in Phase 5").
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'liability.freezed.dart';

/// One account's liability of one [kind]: the fields bills and payoff projections need,
/// typed, and the whole object as the server sent it in [payload]. Which fields are
/// present depends on the kind: [aprs] and [isOverdue] for cards, the loan terms for
/// mortgages and student loans. Amounts are positive (owed, paid), in the account's
/// currency; rates are integers of basis points (1 % is 100). Server-authoritative and
/// never synced, so the entity has no JSON form of its own.
@freezed
abstract class Liability with _$Liability {
  /// A liability; every detail field is null when the institution does not report it.
  const factory Liability({
    required String accountId,
    required LiabilityKind kind,
    required DataSource source,
    LocalDate? nextPaymentDueDate,
    Money? minimumPaymentAmount,
    Money? lastStatementBalance,
    LocalDate? lastStatementIssueDate,
    Money? lastPaymentAmount,
    LocalDate? lastPaymentDate,
    bool? isOverdue,
    @Default(<LiabilityApr>[]) List<LiabilityApr> aprs,
    int? interestRateBasisPoints,
    LocalDate? originationDate,
    Money? originationPrincipal,
    String? loanTerm,
    Money? nextMonthlyPayment,
    Money? ytdInterestPaid,
    Money? ytdPrincipalPaid,
    required Map<String, Object?> payload,
  }) = _Liability;
}

/// One APR of a card: Plaid's type (`purchase_apr`, `cash_apr`, ...), the rate in basis
/// points, and the balance it applies to.
@freezed
abstract class LiabilityApr with _$LiabilityApr {
  /// An APR.
  const factory LiabilityApr({
    required String type,
    required int percentageBasisPoints,
    Money? balanceSubjectToApr,
  }) = _LiabilityApr;
}
