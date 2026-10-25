/// The server's view of Plaid (`docs/reference/server.md`, **PlaidClient**).
///
/// [PlaidClient] has the calls the server makes: `FakePlaidClient` in fake mode,
/// `HttpPlaidClient` over Plaid's REST API in sandbox mode. The request and response types
/// are the server's own records, not Plaid's full shapes. Their `fromPlaidJson` factories
/// read Plaid's snake_case JSON (the fake's fixtures, the real client's responses),
/// building `Money` at this boundary with `plaidMoney`, so a JSON number must reach them as
/// its text or an `int`, never a `double`. Their `rounding` is null for the fake (strict)
/// and half-even for the real client, whose Sandbox answers carry sub-cent amounts.
/// Amounts keep Plaid's sign here (a positive transaction amount is money out of the
/// account); ingestion flips it into ours.
library;

import 'dart:convert';

import 'package:finance_tracker_server/src/plaid/plaid_money.dart';
import 'package:shared_models/shared_models.dart';

/// A failure Plaid reported (`error_type`, `error_code`).
final class PlaidException implements Exception {
  /// A failure.
  const PlaidException(
    this.errorType,
    this.errorCode, [
    this.message = '',
    this.requestId,
  ]);

  /// Plaid's `error_type` (`ITEM_ERROR`, `RATE_LIMIT_EXCEEDED`, ...).
  final String errorType;

  /// Plaid's `error_code` (`ITEM_LOGIN_REQUIRED`, ...).
  final String errorCode;

  /// Plaid's message, for logs.
  final String message;

  /// Plaid's `request_id` for the failed call, when it answered with one.
  final String? requestId;

  /// The Item needs re-authentication through Link in update mode.
  bool get isLoginRequired => errorCode == 'ITEM_LOGIN_REQUIRED';

  /// Plaid's rate limit.
  bool get isRateLimit => errorType == 'RATE_LIMIT_EXCEEDED';

  /// The Item changed while `/transactions/sync` was paginating: restart from the cursor
  /// the run began with (`PLAN.md` §4).
  bool get isMutationDuringPagination =>
      errorCode == 'TRANSACTIONS_SYNC_MUTATION_DURING_PAGINATION';

  @override
  String toString() => 'PlaidException($errorType/$errorCode)';
}

/// What `/link/token/create` is asked for.
final class LinkTokenRequest {
  /// A request.
  const LinkTokenRequest({
    required this.clientUserId,
    required this.androidPackageName,
    this.products = const ['transactions'],
    this.daysRequested = 730,
  });

  /// Our user id, which Plaid echoes as `client_user_id`.
  final String clientUserId;

  /// The app's package name, registered with Plaid.
  final String androidPackageName;

  /// The products to initialize.
  final List<String> products;

  /// The transaction history requested; fixed at Item creation (`PLAN.md` §12: 730).
  final int daysRequested;
}

/// A Link token.
typedef PlaidLinkToken = ({String linkToken, DateTime expiration});

/// The result of exchanging a public token.
typedef PlaidExchange = ({String accessToken, String itemId});

/// An Item as `/item/get` describes it.
final class PlaidItem {
  /// An Item.
  const PlaidItem({
    required this.itemId,
    required this.institutionId,
    required this.institutionName,
    required this.products,
    this.errorCode,
  });

  /// Plaid's `item_id`.
  final String itemId;

  /// Plaid's `institution_id`.
  final String institutionId;

  /// The institution's name.
  final String institutionName;

  /// The products the Item was created with (`transactions`, `liabilities`, ...).
  final List<String> products;

  /// The Item's `error.error_code`, null when healthy.
  final String? errorCode;
}

/// An account with the balances the institution reported.
final class PlaidAccount {
  /// An account.
  const PlaidAccount({
    required this.accountId,
    required this.name,
    this.officialName,
    this.mask,
    required this.type,
    this.subtype,
    required this.currencyCode,
    this.current,
    this.available,
    this.limit,
  });

  /// Reads an element of Plaid's `accounts` array.
  factory PlaidAccount.fromPlaidJson(
    Map<String, Object?> json, {
    RoundingMode? rounding,
  }) {
    final balances = json['balances']! as Map<String, Object?>;
    final currency = _currency(balances);
    Money? money(String key) =>
        optionalPlaidMoney(balances[key], currency, rounding: rounding);
    return PlaidAccount(
      accountId: json['account_id']! as String,
      name: json['name']! as String,
      officialName: json['official_name'] as String?,
      mask: json['mask'] as String?,
      type: json['type']! as String,
      subtype: json['subtype'] as String?,
      currencyCode: currency,
      current: money('current'),
      available: money('available'),
      limit: money('limit'),
    );
  }

  /// Plaid's `account_id`.
  final String accountId;

  /// The account's name.
  final String name;

  /// The institution's official name.
  final String? officialName;

  /// The last digits of the account number.
  final String? mask;

  /// Plaid's `type` (`depository`, `credit`, `loan`, `investment`, ...).
  final String type;

  /// Plaid's `subtype`.
  final String? subtype;

  /// The balances' currency.
  final String currencyCode;

  /// The current balance as reported (for credit, the amount owed).
  final Money? current;

  /// The available balance as reported.
  final Money? available;

  /// The credit limit as reported.
  final Money? limit;
}

/// A transaction as `/transactions/sync` reports it.
final class PlaidTransaction {
  /// A transaction.
  const PlaidTransaction({
    required this.transactionId,
    required this.accountId,
    required this.amount,
    required this.date,
    this.authorizedDate,
    required this.pending,
    this.pendingTransactionId,
    required this.name,
    this.merchantName,
    this.logoUrl,
    this.primaryCategory,
    this.detailedCategory,
  });

  /// Reads an element of Plaid's `added` or `modified` array. The logo is Plaid's
  /// `logo_url`, else the first `merchant` counterparty's.
  factory PlaidTransaction.fromPlaidJson(
    Map<String, Object?> json, {
    RoundingMode? rounding,
  }) {
    final category = json['personal_finance_category'] as Map<String, Object?>?;
    final authorized = json['authorized_date'] as String?;
    final counterpartyLogo = [
      for (final c in (json['counterparties'] as List<Object?>?) ?? const [])
        if (c case {'type': 'merchant', 'logo_url': final String url}) url,
    ].firstOrNull;
    return PlaidTransaction(
      transactionId: json['transaction_id']! as String,
      accountId: json['account_id']! as String,
      amount: plaidMoney(json['amount']!, _currency(json), rounding: rounding),
      date: LocalDate.parse(json['date']! as String),
      authorizedDate: authorized == null ? null : LocalDate.parse(authorized),
      pending: json['pending']! as bool,
      pendingTransactionId: json['pending_transaction_id'] as String?,
      name: json['name']! as String,
      merchantName: json['merchant_name'] as String?,
      logoUrl: json['logo_url'] as String? ?? counterpartyLogo,
      primaryCategory: category?['primary'] as String?,
      detailedCategory: category?['detailed'] as String?,
    );
  }

  /// Plaid's `transaction_id`.
  final String transactionId;

  /// Plaid's `account_id`.
  final String accountId;

  /// The amount in **Plaid's sign**: positive is money out of the account.
  final Money amount;

  /// The posted (or, while pending, transacted) date.
  final LocalDate date;

  /// The authorized date.
  final LocalDate? authorizedDate;

  /// Whether the transaction is pending.
  final bool pending;

  /// For a posted transaction, Plaid's id of the pending one it replaces.
  final String? pendingTransactionId;

  /// Plaid's raw name.
  final String name;

  /// Plaid's cleaned merchant name.
  final String? merchantName;

  /// The merchant's logo.
  final String? logoUrl;

  /// `personal_finance_category.primary`.
  final String? primaryCategory;

  /// `personal_finance_category.detailed`.
  final String? detailedCategory;
}

/// One page of `/transactions/sync`. [notReady] is Plaid's `NOT_READY`: the first
/// extraction has not finished, the arrays are empty, and the caller retries shortly; it
/// never means "no transactions".
final class TransactionsSyncPage {
  /// A page.
  const TransactionsSyncPage({
    this.notReady = false,
    this.added = const [],
    this.modified = const [],
    this.removed = const [],
    this.accounts = const [],
    required this.nextCursor,
    this.hasMore = false,
  });

  /// `transactions_update_status == NOT_READY`.
  final bool notReady;

  /// New transactions.
  final List<PlaidTransaction> added;

  /// Changed transactions.
  final List<PlaidTransaction> modified;

  /// The ids of removed transactions.
  final List<String> removed;

  /// The Item's accounts with current balances.
  final List<PlaidAccount> accounts;

  /// The cursor after this page.
  final String nextCursor;

  /// Whether another page follows.
  final bool hasMore;
}

/// A recurring stream from `/transactions/recurring/get`.
final class PlaidRecurringStream {
  /// A stream.
  const PlaidRecurringStream({
    required this.streamId,
    required this.accountId,
    required this.merchantName,
    required this.frequency,
    required this.averageAmount,
    this.lastDate,
    this.predictedNextDate,
    required this.isActive,
  });

  /// Reads an element of `inflow_streams` or `outflow_streams`; an empty `merchant_name`
  /// counts as none. Sandbox's `average_amount` may carry no currency code; [currency] is
  /// then the stream's account's.
  factory PlaidRecurringStream.fromPlaidJson(
    Map<String, Object?> json, {
    RoundingMode? rounding,
    String? currency,
  }) {
    final average = json['average_amount']! as Map<String, Object?>;
    final last = json['last_date'] as String?;
    final next = json['predicted_next_date'] as String?;
    final merchant = json['merchant_name'] as String?;
    return PlaidRecurringStream(
      streamId: json['stream_id']! as String,
      accountId: json['account_id']! as String,
      merchantName: merchant == null || merchant.isEmpty
          ? json['description']! as String
          : merchant,
      frequency: json['frequency']! as String,
      averageAmount: plaidMoney(
        average['amount']!,
        _currencyOrNull(average) ??
            currency ??
            (throw const FormatException('No currency code')),
        rounding: rounding,
      ),
      lastDate: last == null ? null : LocalDate.parse(last),
      predictedNextDate: next == null ? null : LocalDate.parse(next),
      isActive: json['is_active']! as bool,
    );
  }

  /// Plaid's `stream_id`.
  final String streamId;

  /// Plaid's `account_id`.
  final String accountId;

  /// The merchant, or the stream's description when Plaid has no merchant.
  final String merchantName;

  /// Plaid's `frequency` (`WEEKLY`, `MONTHLY`, ...).
  final String frequency;

  /// The average amount in Plaid's sign (positive is money out).
  final Money averageAmount;

  /// The last occurrence.
  final LocalDate? lastDate;

  /// Plaid's prediction of the next occurrence.
  final LocalDate? predictedNextDate;

  /// Whether the stream is still active.
  final bool isActive;
}

/// `/transactions/recurring/get`'s streams.
typedef PlaidRecurring = ({
  List<PlaidRecurringStream> inflow,
  List<PlaidRecurringStream> outflow,
});

/// `/liabilities/get`, each liability kept as the contract's JSON shape (amounts already
/// `Money` JSON, rates `Decimal`), keyed by Plaid's account id.
final class PlaidLiabilities {
  /// The liabilities.
  const PlaidLiabilities({
    this.credit = const [],
    this.mortgage = const [],
    this.student = const [],
  });

  /// Reads `liabilities` from a `/liabilities/get` response; [currencyOf] gives each
  /// account's currency, which Plaid's liability objects do not carry.
  factory PlaidLiabilities.fromPlaidJson(
    Map<String, Object?> json,
    String Function(String accountId) currencyOf, {
    RoundingMode? rounding,
  }) {
    List<Map<String, Object?>> read(
      String kind,
      Map<String, Object?> Function(Map<String, Object?>, String, RoundingMode?)
      shape,
    ) => [
      for (final raw in (json[kind] as List<Object?>?) ?? const <Object?>[])
        if (raw case final Map<String, Object?> l)
          shape(l, currencyOf(l['account_id']! as String), rounding),
    ];
    return PlaidLiabilities(
      credit: read('credit', _credit),
      mortgage: read('mortgage', _mortgage),
      student: read('student', _student),
    );
  }

  /// `CreditLiability` objects.
  final List<Map<String, Object?>> credit;

  /// `MortgageLiability` objects.
  final List<Map<String, Object?>> mortgage;

  /// `StudentLoanLiability` objects.
  final List<Map<String, Object?>> student;

  static Map<String, Object?>? _money(
    Object? value,
    String currency,
    RoundingMode? r,
  ) => optionalPlaidMoney(value, currency, rounding: r)?.toJson();

  static String? _decimalOrNull(Object? value, RoundingMode? r) =>
      value == null ? null : plaidDecimal(value, exponents: r != null);

  static Map<String, Object?> _credit(
    Map<String, Object?> j,
    String c,
    RoundingMode? r,
  ) => {
    'account_id': j['account_id'],
    'aprs': [
      for (final a in [
        for (final raw in (j['aprs'] as List<Object?>?) ?? const <Object?>[])
          raw! as Map<String, Object?>,
      ])
        {
          'apr_percentage': plaidDecimal(
            a['apr_percentage']!,
            exponents: r != null,
          ),
          'apr_type': a['apr_type'],
          'balance_subject_to_apr': _money(a['balance_subject_to_apr'], c, r),
          'interest_charge_amount': _money(a['interest_charge_amount'], c, r),
        },
    ],
    'is_overdue': j['is_overdue'],
    'last_payment_amount': _money(j['last_payment_amount'], c, r),
    'last_payment_date': j['last_payment_date'],
    'last_statement_issue_date': j['last_statement_issue_date'],
    'last_statement_balance': _money(j['last_statement_balance'], c, r),
    'minimum_payment_amount': _money(j['minimum_payment_amount'], c, r),
    'next_payment_due_date': j['next_payment_due_date'],
  };

  static Map<String, Object?> _mortgage(
    Map<String, Object?> j,
    String c,
    RoundingMode? r,
  ) {
    final rate = j['interest_rate'] as Map<String, Object?>?;
    return {
      'account_id': j['account_id'],
      'loan_type_description': j['loan_type_description'],
      'loan_term': j['loan_term'],
      'interest_rate_percentage': _decimalOrNull(rate?['percentage'], r),
      'interest_rate_type': rate?['type'],
      'current_late_fee': _money(j['current_late_fee'], c, r),
      'escrow_balance': _money(j['escrow_balance'], c, r),
      'has_pmi': j['has_pmi'],
      'has_prepayment_penalty': j['has_prepayment_penalty'],
      'last_payment_amount': _money(j['last_payment_amount'], c, r),
      'last_payment_date': j['last_payment_date'],
      'maturity_date': j['maturity_date'],
      'next_monthly_payment': _money(j['next_monthly_payment'], c, r),
      'next_payment_due_date': j['next_payment_due_date'],
      'origination_date': j['origination_date'],
      'origination_principal_amount': _money(
        j['origination_principal_amount'],
        c,
        r,
      ),
      'past_due_amount': _money(j['past_due_amount'], c, r),
      'ytd_interest_paid': _money(j['ytd_interest_paid'], c, r),
      'ytd_principal_paid': _money(j['ytd_principal_paid'], c, r),
    };
  }

  static Map<String, Object?> _student(
    Map<String, Object?> j,
    String c,
    RoundingMode? r,
  ) {
    final status = j['loan_status'] as Map<String, Object?>?;
    final plan = j['repayment_plan'] as Map<String, Object?>?;
    return {
      'account_id': j['account_id'],
      'loan_name': j['loan_name'],
      'guarantor': j['guarantor'],
      'interest_rate_percentage': plaidDecimal(
        j['interest_rate_percentage']!,
        exponents: r != null,
      ),
      'is_overdue': j['is_overdue'],
      'expected_payoff_date': j['expected_payoff_date'],
      'last_payment_amount': _money(j['last_payment_amount'], c, r),
      'last_payment_date': j['last_payment_date'],
      'last_statement_balance': _money(j['last_statement_balance'], c, r),
      'last_statement_issue_date': j['last_statement_issue_date'],
      'minimum_payment_amount': _money(j['minimum_payment_amount'], c, r),
      'next_payment_due_date': j['next_payment_due_date'],
      'origination_date': j['origination_date'],
      'origination_principal_amount': _money(
        j['origination_principal_amount'],
        c,
        r,
      ),
      'outstanding_interest_amount': _money(
        j['outstanding_interest_amount'],
        c,
        r,
      ),
      'loan_status_type': status?['type'],
      'repayment_plan_type': plan?['type'],
      'ytd_interest_paid': _money(j['ytd_interest_paid'], c, r),
      'ytd_principal_paid': _money(j['ytd_principal_paid'], c, r),
    };
  }
}

/// A security referenced by holdings or investment transactions.
final class PlaidSecurity {
  /// A security.
  const PlaidSecurity({
    required this.securityId,
    this.name,
    this.tickerSymbol,
    this.type,
    this.isCashEquivalent,
    this.closePrice,
    this.closePriceAsOf,
    required this.currencyCode,
  });

  /// Reads an element of Plaid's `securities` array.
  factory PlaidSecurity.fromPlaidJson(
    Map<String, Object?> json, {
    RoundingMode? rounding,
  }) {
    final close = json['close_price'];
    final asOf = json['close_price_as_of'] as String?;
    return PlaidSecurity(
      securityId: json['security_id']! as String,
      name: json['name'] as String?,
      tickerSymbol: json['ticker_symbol'] as String?,
      type: json['type'] as String?,
      isCashEquivalent: json['is_cash_equivalent'] as bool?,
      closePrice: close == null
          ? null
          : plaidDecimal(close, exponents: rounding != null),
      closePriceAsOf: asOf == null ? null : LocalDate.parse(asOf),
      currencyCode: _currency(json),
    );
  }

  /// Plaid's `security_id`.
  final String securityId;

  /// The name.
  final String? name;

  /// The ticker.
  final String? tickerSymbol;

  /// Plaid's security type.
  final String? type;

  /// Whether it is a cash equivalent.
  final bool? isCashEquivalent;

  /// The closing price, a `Decimal`.
  final String? closePrice;

  /// The date of [closePrice].
  final LocalDate? closePriceAsOf;

  /// The prices' currency.
  final String currencyCode;
}

/// A position in one security.
final class PlaidHolding {
  /// A holding.
  const PlaidHolding({
    required this.accountId,
    required this.securityId,
    required this.quantity,
    required this.institutionPrice,
    this.institutionPriceAsOf,
    required this.institutionValue,
    this.costBasis,
    required this.currencyCode,
  });

  /// Reads an element of Plaid's `holdings` array.
  factory PlaidHolding.fromPlaidJson(
    Map<String, Object?> json, {
    RoundingMode? rounding,
  }) {
    final currency = _currency(json);
    final exponents = rounding != null;
    final asOf = json['institution_price_as_of'] as String?;
    return PlaidHolding(
      accountId: json['account_id']! as String,
      securityId: json['security_id']! as String,
      quantity: plaidDecimal(json['quantity']!, exponents: exponents),
      institutionPrice: plaidDecimal(
        json['institution_price']!,
        exponents: exponents,
      ),
      institutionPriceAsOf: asOf == null ? null : LocalDate.parse(asOf),
      institutionValue: plaidMoney(
        json['institution_value']!,
        currency,
        rounding: rounding,
      ),
      costBasis: optionalPlaidMoney(
        json['cost_basis'],
        currency,
        rounding: rounding,
      ),
      currencyCode: currency,
    );
  }

  /// Plaid's `account_id`.
  final String accountId;

  /// Plaid's `security_id`.
  final String securityId;

  /// Shares, a `Decimal`.
  final String quantity;

  /// The per-unit price, a `Decimal`.
  final String institutionPrice;

  /// The date of [institutionPrice].
  final LocalDate? institutionPriceAsOf;

  /// The position's value as reported.
  final Money institutionValue;

  /// The cost basis as reported.
  final Money? costBasis;

  /// The currency.
  final String currencyCode;
}

/// `/investments/holdings/get`.
typedef PlaidHoldings = ({
  List<PlaidHolding> holdings,
  List<PlaidSecurity> securities,
});

/// An investment transaction.
final class PlaidInvestmentTransaction {
  /// A transaction.
  const PlaidInvestmentTransaction({
    required this.investmentTransactionId,
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
  });

  /// Reads an element of Plaid's `investment_transactions` array.
  factory PlaidInvestmentTransaction.fromPlaidJson(
    Map<String, Object?> json, {
    RoundingMode? rounding,
  }) {
    final currency = _currency(json);
    final exponents = rounding != null;
    return PlaidInvestmentTransaction(
      investmentTransactionId: json['investment_transaction_id']! as String,
      accountId: json['account_id']! as String,
      securityId: json['security_id'] as String?,
      date: LocalDate.parse(json['date']! as String),
      name: json['name']! as String,
      type: json['type']! as String,
      subtype: json['subtype'] as String?,
      quantity: plaidDecimal(json['quantity']!, exponents: exponents),
      price: plaidDecimal(json['price']!, exponents: exponents),
      amount: plaidMoney(json['amount']!, currency, rounding: rounding),
      fees: optionalPlaidMoney(json['fees'], currency, rounding: rounding),
    );
  }

  /// Plaid's `investment_transaction_id`.
  final String investmentTransactionId;

  /// Plaid's `account_id`.
  final String accountId;

  /// Plaid's `security_id`.
  final String? securityId;

  /// The date.
  final LocalDate date;

  /// The description.
  final String name;

  /// Plaid's type.
  final String type;

  /// Plaid's subtype.
  final String? subtype;

  /// Shares, a `Decimal`.
  final String quantity;

  /// The per-unit price, a `Decimal`.
  final String price;

  /// The amount in Plaid's sign (positive is money out of the account).
  final Money amount;

  /// The fees.
  final Money? fees;
}

/// `/investments/transactions/get`.
typedef PlaidInvestmentTransactions = ({
  List<PlaidInvestmentTransaction> transactions,
  List<PlaidSecurity> securities,
});

/// An institution as `/institutions/get_by_id` describes it with its optional metadata.
final class PlaidInstitution {
  /// An institution.
  const PlaidInstitution({
    required this.institutionId,
    required this.name,
    this.logo,
    this.primaryColor,
  });

  /// Reads Plaid's `institution` object. A `logo` that is not base64 of a PNG, or a
  /// `primary_color` that is not `#rrggbb`, counts as none.
  factory PlaidInstitution.fromPlaidJson(Map<String, Object?> json) {
    List<int>? logo;
    if (json['logo'] case final String text) {
      try {
        final bytes = base64.decode(text);
        var png = bytes.length > _png.length;
        for (var i = 0; png && i < _png.length; i++) {
          png = bytes[i] == _png[i];
        }
        if (png) logo = bytes;
      } on FormatException {
        logo = null;
      }
    }
    int? color;
    if (json['primary_color'] case final String hex) {
      try {
        color = plaidColor(hex);
      } on FormatException {
        color = null;
      }
    }
    return PlaidInstitution(
      institutionId: json['institution_id']! as String,
      name: json['name']! as String,
      logo: logo,
      primaryColor: color,
    );
  }

  static const _png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  /// Plaid's `institution_id`.
  final String institutionId;

  /// The institution's name.
  final String name;

  /// The logo's PNG bytes.
  final List<int>? logo;

  /// The brand colour as the contract's opaque ARGB.
  final int? primaryColor;
}

/// A transaction for `/sandbox/transactions/create`, [amount] in Plaid's sign (positive
/// is money out). [accountId] is Plaid's `account_id`, per transaction; null lets Plaid
/// pick the Item's checking account.
typedef SandboxTransaction = ({
  LocalDate dateTransacted,
  LocalDate datePosted,
  Money amount,
  String description,
  String? accountId,
});

/// The Plaid calls the server makes.
abstract interface class PlaidClient {
  /// The provenance every record from this client is stored with: `demo` for the fake,
  /// `plaid` for the real client (`PLAN.md` §7.1).
  DataSource get provenance;

  /// `/link/token/create`.
  Future<PlaidLinkToken> createLinkToken(LinkTokenRequest request);

  /// `/link/token/create` in update mode for the Item of [accessToken].
  Future<PlaidLinkToken> createUpdateLinkToken(
    String accessToken, {
    required String clientUserId,
    required String androidPackageName,
  });

  /// `/item/public_token/exchange`.
  Future<PlaidExchange> exchangePublicToken(String publicToken);

  /// `/item/get`.
  Future<PlaidItem> getItem(String accessToken);

  /// `/item/remove`.
  Future<void> removeItem(String accessToken);

  /// `/transactions/sync` from [cursor] (empty for the first call), [count] at most 500.
  Future<TransactionsSyncPage> transactionsSync(
    String accessToken,
    String cursor, {
    int count = 500,
  });

  /// `/accounts/get`: every account of the Item, the canonical list (a
  /// `/transactions/sync` page lists only the accounts Transactions covers). Not the
  /// live balance call.
  Future<List<PlaidAccount>> accountsGet(String accessToken);

  /// `/accounts/balance/get`.
  Future<List<PlaidAccount>> accountsBalanceGet(String accessToken);

  /// `/liabilities/get`.
  Future<PlaidLiabilities> liabilitiesGet(String accessToken);

  /// `/investments/holdings/get`.
  Future<PlaidHoldings> investmentsHoldingsGet(String accessToken);

  /// `/investments/transactions/get` from [start] to [end].
  Future<PlaidInvestmentTransactions> investmentsTransactionsGet(
    String accessToken, {
    required LocalDate start,
    required LocalDate end,
  });

  /// `/transactions/recurring/get`. [currencyOf] gives an account's currency (null when the
  /// server does not know the account) for a stream whose amounts carry none; such a
  /// stream of an unknown account is left out.
  Future<PlaidRecurring> transactionsRecurringGet(
    String accessToken, {
    String? Function(String accountId)? currencyOf,
  });

  /// `/webhook_verification_key/get`: the JWK for [keyId].
  Future<Map<String, Object?>> webhookVerificationKeyGet(String keyId);

  /// `/institutions/get_by_id` with the optional metadata (logo, colour).
  Future<PlaidInstitution> institutionsGetById(String institutionId);

  /// `/sandbox/public_token/create`; with [overrideUsername] `user_custom` and a
  /// custom-user configuration (JSON text) as [overridePassword], a custom user
  /// (`docs/reference/persona.md`, **Sandbox custom users**). [daysRequested] is
  /// `options.transactions.days_requested` (1 to 730).
  Future<String> sandboxPublicTokenCreate({
    required String institutionId,
    required List<String> products,
    String? overrideUsername,
    String? overridePassword,
    int? daysRequested,
  });

  /// `/sandbox/item/reset_login`.
  Future<void> sandboxItemResetLogin(String accessToken);

  /// `/sandbox/transactions/create`, at most ten.
  Future<void> sandboxTransactionsCreate(
    String accessToken,
    List<SandboxTransaction> transactions,
  );

  /// `/sandbox/item/fire_webhook`.
  Future<void> sandboxItemFireWebhook(String accessToken, String webhookCode);

  /// `/transactions/refresh`.
  Future<void> transactionsRefresh(String accessToken);
}

String _currency(Map<String, Object?> json) =>
    _currencyOrNull(json) ?? (throw const FormatException('No currency code'));

String? _currencyOrNull(Map<String, Object?> json) =>
    json['iso_currency_code'] as String? ??
    json['unofficial_currency_code'] as String?;
