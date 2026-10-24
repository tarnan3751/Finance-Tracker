/// The values the API returns that have no `shared_models` entity yet: the liability,
/// holding, security and investment-transaction schemas, which exist only in the contract
/// until Phase 3 adds their entities (`docs/reference/api.md`), and the small results of
/// the auth, Plaid and health operations.
///
/// Amounts are `Money`, dates `LocalDate`, instants UTC; per-unit prices, quantities and
/// rates are the contract's `Decimal` strings, kept as text. `fromJson` and `toJson` read
/// and write the contract's JSON exactly, so the client and the fake share one shape.
library;

import 'package:shared_models/shared_models.dart';

Money? _money(Object? json) =>
    json == null ? null : Money.fromJson(json as Map<String, dynamic>);

LocalDate? _date(Object? json) =>
    json == null ? null : LocalDate.parse(json as String);

DateTime? _instant(Object? json) =>
    json == null ? null : const UtcInstantConverter().fromJson(json as String);

/// A new token pair and the device it signs in (`AuthTokens`). Its `toString` never
/// prints a token.
final class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresIn,
    required this.device,
  });

  final String accessToken;
  final String refreshToken;
  final Duration accessExpiresIn;
  final Device device;

  @override
  String toString() => 'AuthResult(device: ${device.id})';
}

/// A Plaid Link token and when it expires (`LinkToken`). Its `toString` never prints the
/// token.
final class LinkToken {
  const LinkToken({required this.linkToken, required this.expiration});

  final String linkToken;
  final DateTime expiration;

  @override
  String toString() => 'LinkToken(expires: ${expiration.toIso8601String()})';
}

/// An Item with its institution, as the API embeds it (`Item`).
typedef LinkedItem = ({Item item, Institution institution});

/// What unlinking an Item does with its data (`deleteItem`'s `history`): [delete] drops
/// its accounts and tombstones its transactions; [keep] keeps everything and lists the
/// Item as `removed`.
enum UnlinkHistory { keep, delete }

/// The outcome of `POST /plaid/items/{id}/sync` (`SyncRunStatus`).
enum SyncRunStatus { started, notReady, completed }

/// The outcome of a sync request (`SyncRun`).
typedef SyncRun = ({
  SyncRunStatus status,
  int added,
  int modified,
  int removed,
  bool nextCursorSaved,
});

/// One page of a version-paged list (`TransactionPage`, `InvestmentTransactionPage`).
typedef VersionPage<T> = ({List<T> items, int nextSince, bool hasMore});

/// `GET /health`: the contract version the server implements.
typedef Health = ({String status, String version});

/// One APR of a credit account (`Apr`).
final class Apr {
  const Apr({
    required this.aprPercentage,
    required this.aprType,
    this.balanceSubjectToApr,
    this.interestChargeAmount,
  });

  factory Apr.fromJson(Map<String, dynamic> json) => Apr(
    aprPercentage: json['apr_percentage'] as String,
    aprType: json['apr_type'] as String,
    balanceSubjectToApr: _money(json['balance_subject_to_apr']),
    interestChargeAmount: _money(json['interest_charge_amount']),
  );

  /// A `Decimal`.
  final String aprPercentage;
  final String aprType;
  final Money? balanceSubjectToApr;
  final Money? interestChargeAmount;

  Map<String, dynamic> toJson() => {
    'apr_percentage': aprPercentage,
    'apr_type': aprType,
    'balance_subject_to_apr': balanceSubjectToApr?.toJson(),
    'interest_charge_amount': interestChargeAmount?.toJson(),
  };
}

/// A credit card's liability details (`CreditLiability`).
final class CreditLiability {
  const CreditLiability({
    required this.accountId,
    this.aprs = const [],
    this.isOverdue,
    this.lastPaymentAmount,
    this.lastPaymentDate,
    this.lastStatementIssueDate,
    this.lastStatementBalance,
    this.minimumPaymentAmount,
    this.nextPaymentDueDate,
  });

  factory CreditLiability.fromJson(Map<String, dynamic> json) =>
      CreditLiability(
        accountId: json['account_id'] as String,
        aprs: [
          for (final Object? a in json['aprs'] as List<dynamic>)
            Apr.fromJson(a as Map<String, dynamic>),
        ],
        isOverdue: json['is_overdue'] as bool?,
        lastPaymentAmount: _money(json['last_payment_amount']),
        lastPaymentDate: _date(json['last_payment_date']),
        lastStatementIssueDate: _date(json['last_statement_issue_date']),
        lastStatementBalance: _money(json['last_statement_balance']),
        minimumPaymentAmount: _money(json['minimum_payment_amount']),
        nextPaymentDueDate: _date(json['next_payment_due_date']),
      );

  final String accountId;
  final List<Apr> aprs;
  final bool? isOverdue;
  final Money? lastPaymentAmount;
  final LocalDate? lastPaymentDate;
  final LocalDate? lastStatementIssueDate;
  final Money? lastStatementBalance;
  final Money? minimumPaymentAmount;
  final LocalDate? nextPaymentDueDate;

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'aprs': [for (final Apr a in aprs) a.toJson()],
    'is_overdue': isOverdue,
    'last_payment_amount': lastPaymentAmount?.toJson(),
    'last_payment_date': lastPaymentDate?.toJson(),
    'last_statement_issue_date': lastStatementIssueDate?.toJson(),
    'last_statement_balance': lastStatementBalance?.toJson(),
    'minimum_payment_amount': minimumPaymentAmount?.toJson(),
    'next_payment_due_date': nextPaymentDueDate?.toJson(),
  };
}

/// A mortgage's liability details (`MortgageLiability`).
final class MortgageLiability {
  const MortgageLiability({
    required this.accountId,
    this.loanTypeDescription,
    this.loanTerm,
    this.interestRatePercentage,
    this.interestRateType,
    this.currentLateFee,
    this.escrowBalance,
    this.hasPmi,
    this.hasPrepaymentPenalty,
    this.lastPaymentAmount,
    this.lastPaymentDate,
    this.maturityDate,
    this.nextMonthlyPayment,
    this.nextPaymentDueDate,
    this.originationDate,
    this.originationPrincipalAmount,
    this.pastDueAmount,
    this.ytdInterestPaid,
    this.ytdPrincipalPaid,
  });

  factory MortgageLiability.fromJson(Map<String, dynamic> json) =>
      MortgageLiability(
        accountId: json['account_id'] as String,
        loanTypeDescription: json['loan_type_description'] as String?,
        loanTerm: json['loan_term'] as String?,
        interestRatePercentage: json['interest_rate_percentage'] as String?,
        interestRateType: json['interest_rate_type'] as String?,
        currentLateFee: _money(json['current_late_fee']),
        escrowBalance: _money(json['escrow_balance']),
        hasPmi: json['has_pmi'] as bool?,
        hasPrepaymentPenalty: json['has_prepayment_penalty'] as bool?,
        lastPaymentAmount: _money(json['last_payment_amount']),
        lastPaymentDate: _date(json['last_payment_date']),
        maturityDate: _date(json['maturity_date']),
        nextMonthlyPayment: _money(json['next_monthly_payment']),
        nextPaymentDueDate: _date(json['next_payment_due_date']),
        originationDate: _date(json['origination_date']),
        originationPrincipalAmount: _money(
          json['origination_principal_amount'],
        ),
        pastDueAmount: _money(json['past_due_amount']),
        ytdInterestPaid: _money(json['ytd_interest_paid']),
        ytdPrincipalPaid: _money(json['ytd_principal_paid']),
      );

  final String accountId;
  final String? loanTypeDescription;
  final String? loanTerm;

  /// A `Decimal`.
  final String? interestRatePercentage;
  final String? interestRateType;
  final Money? currentLateFee;
  final Money? escrowBalance;
  final bool? hasPmi;
  final bool? hasPrepaymentPenalty;
  final Money? lastPaymentAmount;
  final LocalDate? lastPaymentDate;
  final LocalDate? maturityDate;
  final Money? nextMonthlyPayment;
  final LocalDate? nextPaymentDueDate;
  final LocalDate? originationDate;
  final Money? originationPrincipalAmount;
  final Money? pastDueAmount;
  final Money? ytdInterestPaid;
  final Money? ytdPrincipalPaid;

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'loan_type_description': loanTypeDescription,
    'loan_term': loanTerm,
    'interest_rate_percentage': interestRatePercentage,
    'interest_rate_type': interestRateType,
    'current_late_fee': currentLateFee?.toJson(),
    'escrow_balance': escrowBalance?.toJson(),
    'has_pmi': hasPmi,
    'has_prepayment_penalty': hasPrepaymentPenalty,
    'last_payment_amount': lastPaymentAmount?.toJson(),
    'last_payment_date': lastPaymentDate?.toJson(),
    'maturity_date': maturityDate?.toJson(),
    'next_monthly_payment': nextMonthlyPayment?.toJson(),
    'next_payment_due_date': nextPaymentDueDate?.toJson(),
    'origination_date': originationDate?.toJson(),
    'origination_principal_amount': originationPrincipalAmount?.toJson(),
    'past_due_amount': pastDueAmount?.toJson(),
    'ytd_interest_paid': ytdInterestPaid?.toJson(),
    'ytd_principal_paid': ytdPrincipalPaid?.toJson(),
  };
}

/// A student loan's liability details (`StudentLoanLiability`).
final class StudentLoanLiability {
  const StudentLoanLiability({
    required this.accountId,
    this.loanName,
    this.guarantor,
    required this.interestRatePercentage,
    this.isOverdue,
    this.expectedPayoffDate,
    this.lastPaymentAmount,
    this.lastPaymentDate,
    this.lastStatementBalance,
    this.lastStatementIssueDate,
    this.minimumPaymentAmount,
    this.nextPaymentDueDate,
    this.originationDate,
    this.originationPrincipalAmount,
    this.outstandingInterestAmount,
    this.loanStatusType,
    this.repaymentPlanType,
    this.ytdInterestPaid,
    this.ytdPrincipalPaid,
  });

  factory StudentLoanLiability.fromJson(Map<String, dynamic> json) =>
      StudentLoanLiability(
        accountId: json['account_id'] as String,
        loanName: json['loan_name'] as String?,
        guarantor: json['guarantor'] as String?,
        interestRatePercentage: json['interest_rate_percentage'] as String,
        isOverdue: json['is_overdue'] as bool?,
        expectedPayoffDate: _date(json['expected_payoff_date']),
        lastPaymentAmount: _money(json['last_payment_amount']),
        lastPaymentDate: _date(json['last_payment_date']),
        lastStatementBalance: _money(json['last_statement_balance']),
        lastStatementIssueDate: _date(json['last_statement_issue_date']),
        minimumPaymentAmount: _money(json['minimum_payment_amount']),
        nextPaymentDueDate: _date(json['next_payment_due_date']),
        originationDate: _date(json['origination_date']),
        originationPrincipalAmount: _money(
          json['origination_principal_amount'],
        ),
        outstandingInterestAmount: _money(json['outstanding_interest_amount']),
        loanStatusType: json['loan_status_type'] as String?,
        repaymentPlanType: json['repayment_plan_type'] as String?,
        ytdInterestPaid: _money(json['ytd_interest_paid']),
        ytdPrincipalPaid: _money(json['ytd_principal_paid']),
      );

  final String accountId;
  final String? loanName;
  final String? guarantor;

  /// A `Decimal`.
  final String interestRatePercentage;
  final bool? isOverdue;
  final LocalDate? expectedPayoffDate;
  final Money? lastPaymentAmount;
  final LocalDate? lastPaymentDate;
  final Money? lastStatementBalance;
  final LocalDate? lastStatementIssueDate;
  final Money? minimumPaymentAmount;
  final LocalDate? nextPaymentDueDate;
  final LocalDate? originationDate;
  final Money? originationPrincipalAmount;
  final Money? outstandingInterestAmount;
  final String? loanStatusType;
  final String? repaymentPlanType;
  final Money? ytdInterestPaid;
  final Money? ytdPrincipalPaid;

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'loan_name': loanName,
    'guarantor': guarantor,
    'interest_rate_percentage': interestRatePercentage,
    'is_overdue': isOverdue,
    'expected_payoff_date': expectedPayoffDate?.toJson(),
    'last_payment_amount': lastPaymentAmount?.toJson(),
    'last_payment_date': lastPaymentDate?.toJson(),
    'last_statement_balance': lastStatementBalance?.toJson(),
    'last_statement_issue_date': lastStatementIssueDate?.toJson(),
    'minimum_payment_amount': minimumPaymentAmount?.toJson(),
    'next_payment_due_date': nextPaymentDueDate?.toJson(),
    'origination_date': originationDate?.toJson(),
    'origination_principal_amount': originationPrincipalAmount?.toJson(),
    'outstanding_interest_amount': outstandingInterestAmount?.toJson(),
    'loan_status_type': loanStatusType,
    'repayment_plan_type': repaymentPlanType,
    'ytd_interest_paid': ytdInterestPaid?.toJson(),
    'ytd_principal_paid': ytdPrincipalPaid?.toJson(),
  };
}

/// Every liability of the user's accounts (`Liabilities`).
final class Liabilities {
  const Liabilities({
    this.credit = const [],
    this.mortgage = const [],
    this.student = const [],
  });

  factory Liabilities.fromJson(Map<String, dynamic> json) => Liabilities(
    credit: [
      for (final Object? c in json['credit'] as List<dynamic>)
        CreditLiability.fromJson(c as Map<String, dynamic>),
    ],
    mortgage: [
      for (final Object? m in json['mortgage'] as List<dynamic>)
        MortgageLiability.fromJson(m as Map<String, dynamic>),
    ],
    student: [
      for (final Object? s in json['student'] as List<dynamic>)
        StudentLoanLiability.fromJson(s as Map<String, dynamic>),
    ],
  );

  final List<CreditLiability> credit;
  final List<MortgageLiability> mortgage;
  final List<StudentLoanLiability> student;

  Map<String, dynamic> toJson() => {
    'credit': [for (final CreditLiability c in credit) c.toJson()],
    'mortgage': [for (final MortgageLiability m in mortgage) m.toJson()],
    'student': [for (final StudentLoanLiability s in student) s.toJson()],
  };
}

/// A position in one security (`Holding`).
final class Holding {
  const Holding({
    required this.accountId,
    required this.securityId,
    required this.quantity,
    required this.institutionPrice,
    this.institutionPriceAsOf,
    required this.institutionValue,
    this.costBasis,
    required this.currencyCode,
  });

  factory Holding.fromJson(Map<String, dynamic> json) => Holding(
    accountId: json['account_id'] as String,
    securityId: json['security_id'] as String,
    quantity: json['quantity'] as String,
    institutionPrice: json['institution_price'] as String,
    institutionPriceAsOf: _date(json['institution_price_as_of']),
    institutionValue: _money(json['institution_value'])!,
    costBasis: _money(json['cost_basis']),
    currencyCode: json['currency_code'] as String,
  );

  final String accountId;
  final String securityId;

  /// A `Decimal`.
  final String quantity;

  /// A `Decimal`, per unit, in [currencyCode].
  final String institutionPrice;
  final LocalDate? institutionPriceAsOf;
  final Money institutionValue;
  final Money? costBasis;
  final String currencyCode;

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'security_id': securityId,
    'quantity': quantity,
    'institution_price': institutionPrice,
    'institution_price_as_of': institutionPriceAsOf?.toJson(),
    'institution_value': institutionValue.toJson(),
    'cost_basis': costBasis?.toJson(),
    'currency_code': currencyCode,
  };
}

/// A security a holding or an investment transaction references (`Security`).
final class Security {
  const Security({
    required this.id,
    this.name,
    this.tickerSymbol,
    this.type,
    this.isCashEquivalent,
    this.closePrice,
    this.closePriceAsOf,
    required this.currencyCode,
  });

  factory Security.fromJson(Map<String, dynamic> json) => Security(
    id: json['id'] as String,
    name: json['name'] as String?,
    tickerSymbol: json['ticker_symbol'] as String?,
    type: json['type'] as String?,
    isCashEquivalent: json['is_cash_equivalent'] as bool?,
    closePrice: json['close_price'] as String?,
    closePriceAsOf: _date(json['close_price_as_of']),
    currencyCode: json['currency_code'] as String,
  );

  final String id;
  final String? name;
  final String? tickerSymbol;
  final String? type;
  final bool? isCashEquivalent;

  /// A `Decimal`, per unit, in [currencyCode].
  final String? closePrice;
  final LocalDate? closePriceAsOf;
  final String currencyCode;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ticker_symbol': tickerSymbol,
    'type': type,
    'is_cash_equivalent': isCashEquivalent,
    'close_price': closePrice,
    'close_price_as_of': closePriceAsOf?.toJson(),
    'currency_code': currencyCode,
  };
}

/// The holdings and the securities they reference (`HoldingsResponse`).
final class Holdings {
  const Holdings({this.holdings = const [], this.securities = const []});

  factory Holdings.fromJson(Map<String, dynamic> json) => Holdings(
    holdings: [
      for (final Object? h in json['holdings'] as List<dynamic>)
        Holding.fromJson(h as Map<String, dynamic>),
    ],
    securities: [
      for (final Object? s in json['securities'] as List<dynamic>)
        Security.fromJson(s as Map<String, dynamic>),
    ],
  );

  final List<Holding> holdings;
  final List<Security> securities;

  Map<String, dynamic> toJson() => {
    'holdings': [for (final Holding h in holdings) h.toJson()],
    'securities': [for (final Security s in securities) s.toJson()],
  };
}

/// A buy, sell, dividend, fee or transfer in an investment account
/// (`InvestmentTransaction`). [amount] follows our sign: negative is an outflow.
final class InvestmentTransaction {
  const InvestmentTransaction({
    required this.id,
    required this.accountId,
    this.securityId,
    required this.date,
    required this.name,
    required this.type,
    this.subtype,
    required this.quantity,
    required this.price,
    required this.amount,
    this.fees,
    this.deletedAt,
    required this.syncVersion,
  });

  factory InvestmentTransaction.fromJson(Map<String, dynamic> json) =>
      InvestmentTransaction(
        id: json['id'] as String,
        accountId: json['account_id'] as String,
        securityId: json['security_id'] as String?,
        date: LocalDate.parse(json['date'] as String),
        name: json['name'] as String,
        type: json['type'] as String,
        subtype: json['subtype'] as String?,
        quantity: json['quantity'] as String,
        price: json['price'] as String,
        amount: _money(json['amount'])!,
        fees: _money(json['fees']),
        deletedAt: _instant(json['deleted_at']),
        syncVersion: json['sync_version'] as int,
      );

  final String id;
  final String accountId;
  final String? securityId;
  final LocalDate date;
  final String name;
  final String type;
  final String? subtype;

  /// A `Decimal`.
  final String quantity;

  /// A `Decimal`, per unit.
  final String price;
  final Money amount;
  final Money? fees;

  /// The tombstone, UTC.
  final DateTime? deletedAt;
  final int syncVersion;

  /// This transaction at [syncVersion], deleted at [deletedAt] when given.
  InvestmentTransaction copyWith({int? syncVersion, DateTime? deletedAt}) =>
      InvestmentTransaction(
        id: id,
        accountId: accountId,
        securityId: securityId,
        date: date,
        name: name,
        type: type,
        subtype: subtype,
        quantity: quantity,
        price: price,
        amount: amount,
        fees: fees,
        deletedAt: deletedAt ?? this.deletedAt,
        syncVersion: syncVersion ?? this.syncVersion,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'account_id': accountId,
    'security_id': securityId,
    'date': date.toJson(),
    'name': name,
    'type': type,
    'subtype': subtype,
    'quantity': quantity,
    'price': price,
    'amount': amount.toJson(),
    'fees': fees?.toJson(),
    'deleted_at': deletedAt == null
        ? null
        : const UtcInstantConverter().toJson(deletedAt!),
    'sync_version': syncVersion,
  };
}

/// The webhook codes `POST /sandbox/items/{item_id}/fire-webhook` takes (`WebhookCode`),
/// [wire] in Plaid's spelling.
enum SandboxWebhookCode {
  syncUpdatesAvailable('SYNC_UPDATES_AVAILABLE'),
  defaultUpdate('DEFAULT_UPDATE'),
  recurringTransactionsUpdate('RECURRING_TRANSACTIONS_UPDATE'),
  newAccountsAvailable('NEW_ACCOUNTS_AVAILABLE'),
  pendingDisconnect('PENDING_DISCONNECT'),
  userPermissionRevoked('USER_PERMISSION_REVOKED'),
  loginRepaired('LOGIN_REPAIRED'),
  error('ERROR');

  const SandboxWebhookCode(this.wire);

  final String wire;
}

/// A transaction to inject into a Sandbox Item (`SandboxTransaction`). [amount] is in the
/// app's sign (negative is money out); the client negates it into Plaid's on the wire.
/// [accountId] is one of the Item's accounts, or null for Plaid's choice (checking).
final class SandboxTransaction {
  const SandboxTransaction({
    required this.dateTransacted,
    required this.datePosted,
    required this.amount,
    required this.description,
    this.accountId,
  });

  final LocalDate dateTransacted;
  final LocalDate datePosted;
  final Money amount;
  final String description;
  final String? accountId;

  /// The contract's JSON, [amount] in Plaid's sign.
  Map<String, dynamic> toJson() => {
    'date_transacted': dateTransacted.toJson(),
    'date_posted': datePosted.toJson(),
    'amount': (-amount).toJson(),
    'description': description,
    'account_id': ?accountId,
  };
}
