/// The real [PlaidClient] of `PLAID_MODE=sandbox`, over Plaid's REST API
/// (`docs/reference/server.md`, **The HTTP Plaid client**).
///
/// Every call is a `POST` of a JSON body carrying `client_id` and `secret`, with
/// `Plaid-Version: 2020-09-14` and a 60 s timeout (`PLAN.md` §4). Request bodies are written
/// by `writeJson`, amounts as `JsonDecimal` text; responses are read by `decodePlaidJson`,
/// so no Plaid number ever becomes a `double`, and amounts are rounded half-even to the
/// currency's scale because Sandbox writes some finer than a cent (`PLAN.md` §12). Its
/// [provenance] is `plaid`; every record it returns is built from Plaid's answer alone.
///
/// A non-2xx answer becomes a [PlaidException] from Plaid's error object; an answer without
/// one, a timeout, a network failure or a response the records cannot read becomes an
/// `API_ERROR` with `HTTP_<status>`, `TIMEOUT`, `NETWORK_ERROR` or `INVALID_RESPONSE`.
/// Each call logs one `plaid_call` line (path, status, duration, `request_id`); a body, a
/// token or a key is never logged. When [HttpPlaidClient.webhookUrl] is set, Link tokens
/// and Sandbox public tokens name it, so Plaid delivers the Item's webhooks there.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show IOException;

import 'package:finance_tracker_server/src/logging.dart';
import 'package:finance_tracker_server/src/plaid/plaid_client.dart';
import 'package:finance_tracker_server/src/plaid/plaid_json.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:persona_engine/persona_engine.dart' show JsonDecimal, writeJson;
import 'package:shared_models/shared_models.dart';

/// The API version every call names.
const plaidApiVersion = '2020-09-14';

/// The base URL of each `PLAID_ENV`.
const plaidBaseUrls = {
  'sandbox': 'https://sandbox.plaid.com',
  'development': 'https://development.plaid.com',
  'production': 'https://production.plaid.com',
};

/// The `webhook_type` `/sandbox/item/fire_webhook` needs for each code it fires.
const fireWebhookTypes = {
  'SYNC_UPDATES_AVAILABLE': 'TRANSACTIONS',
  'DEFAULT_UPDATE': 'TRANSACTIONS',
  'RECURRING_TRANSACTIONS_UPDATE': 'TRANSACTIONS',
  'NEW_ACCOUNTS_AVAILABLE': 'ITEM',
  'PENDING_DISCONNECT': 'ITEM',
  'USER_PERMISSION_REVOKED': 'ITEM',
  'LOGIN_REPAIRED': 'ITEM',
  'ERROR': 'ITEM',
};

/// The page size of `/investments/transactions/get` (Plaid's maximum).
const investmentsPageSize = 500;

/// The real client.
final class HttpPlaidClient implements PlaidClient {
  /// A client for [baseUrl] with Plaid's [clientId] and [secret]; [httpClient] is the
  /// transport (a recorded one in tests).
  HttpPlaidClient({
    required this._clientId,
    required this._secret,
    required this.baseUrl,
    this.webhookUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 60),
  }) : _http = httpClient ?? http.Client();

  final String _clientId;
  final String _secret;
  final http.Client _http;

  /// Plaid's base URL for the environment ([plaidBaseUrls]).
  final Uri baseUrl;

  /// Where Plaid delivers webhooks (`PLAID_WEBHOOK_URL`), or null.
  final String? webhookUrl;

  /// The limit on each call (`/transactions/refresh` can take 30 s).
  final Duration timeout;

  /// How Plaid's amounts are brought to the currency's scale.
  static const rounding = RoundingMode.halfEven;

  final Logger _log = Logger('plaid');

  @override
  DataSource get provenance => DataSource.plaid;

  /// Closes the transport.
  void close() => _http.close();

  Future<Map<String, Object?>> _call(
    String path,
    Map<String, Object?> body,
  ) async {
    final watch = Stopwatch()..start();
    final payload = writeJson({
      'client_id': _clientId,
      'secret': _secret,
      ...body,
    }, pretty: false);
    final http.Response response;
    try {
      response = await _http
          .post(
            baseUrl.resolve(path),
            headers: const {
              'content-type': 'application/json',
              'plaid-version': plaidApiVersion,
            },
            body: payload,
          )
          .timeout(timeout);
    } on TimeoutException {
      _failed(path, 'TIMEOUT', watch);
      throw const PlaidException('API_ERROR', 'TIMEOUT');
    } on http.ClientException {
      _failed(path, 'NETWORK_ERROR', watch);
      throw const PlaidException('API_ERROR', 'NETWORK_ERROR');
    } on IOException {
      _failed(path, 'NETWORK_ERROR', watch);
      throw const PlaidException('API_ERROR', 'NETWORK_ERROR');
    }
    Map<String, Object?>? json;
    try {
      final decoded = decodePlaidJson(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, Object?>) json = decoded;
    } on FormatException {
      json = null;
    }
    final requestId = switch (json?['request_id']) {
      final String id => id,
      _ => null,
    };
    final status = response.statusCode;
    _log.info(
      LogEvent('plaid_call', {
        'path': path,
        'status': status,
        'duration_ms': watch.elapsedMilliseconds,
        'request_id': requestId,
      }),
    );
    if (status >= 200 && status < 300) {
      if (json == null) {
        throw PlaidException('API_ERROR', 'INVALID_RESPONSE', '', requestId);
      }
      return json;
    }
    if (json case {
      'error_type': final String type,
      'error_code': final String code,
    }) {
      final message = json['error_message'];
      throw PlaidException(
        type,
        code,
        message is String ? message : '',
        requestId,
      );
    }
    throw PlaidException(
      status == 429 ? 'RATE_LIMIT_EXCEEDED' : 'API_ERROR',
      'HTTP_$status',
      '',
      requestId,
    );
  }

  void _failed(String path, String code, Stopwatch watch) => _log.warning(
    LogEvent('plaid_call', {
      'path': path,
      'code': code,
      'duration_ms': watch.elapsedMilliseconds,
    }),
  );

  /// [_call], then [read] of its answer; an answer [read] cannot handle is
  /// `INVALID_RESPONSE`.
  Future<T> _read<T>(
    String path,
    Map<String, Object?> body,
    T Function(Map<String, Object?> json) read,
  ) async {
    final json = await _call(path, body);
    try {
      return read(json);
    } on Object catch (e) {
      _log.warning(
        LogEvent('plaid_response_unreadable', {
          'path': path,
          'error_type': e.runtimeType.toString(),
        }),
      );
      throw PlaidException(
        'API_ERROR',
        'INVALID_RESPONSE',
        '',
        json['request_id'] as String?,
      );
    }
  }

  static List<Map<String, Object?>> _list(Object? value) => [
    for (final e in (value as List<Object?>?) ?? const <Object?>[])
      e! as Map<String, Object?>,
  ];

  static List<PlaidAccount> _accounts(Map<String, Object?> json) => [
    for (final a in _list(json['accounts']))
      PlaidAccount.fromPlaidJson(a, rounding: rounding),
  ];

  static List<PlaidSecurity> _securities(Map<String, Object?> json) => [
    for (final s in _list(json['securities']))
      PlaidSecurity.fromPlaidJson(s, rounding: rounding),
  ];

  static PlaidLinkToken _linkToken(Map<String, Object?> json) => (
    linkToken: json['link_token']! as String,
    expiration: DateTime.parse(json['expiration']! as String).toUtc(),
  );

  Map<String, Object?> _linkBase(String clientUserId, String package) => {
    'client_name': 'Finance Tracker',
    'language': 'en',
    'country_codes': const ['US'],
    'user': {'client_user_id': clientUserId},
    'android_package_name': package,
    if (webhookUrl != null) 'webhook': webhookUrl,
  };

  @override
  Future<PlaidLinkToken> createLinkToken(LinkTokenRequest request) =>
      _read('/link/token/create', {
        ..._linkBase(request.clientUserId, request.androidPackageName),
        'products': request.products,
        'transactions': {'days_requested': request.daysRequested},
      }, _linkToken);

  @override
  Future<PlaidLinkToken> createUpdateLinkToken(
    String accessToken, {
    required String clientUserId,
    required String androidPackageName,
  }) => _read('/link/token/create', {
    ..._linkBase(clientUserId, androidPackageName),
    'access_token': accessToken,
    'update': {'account_selection_enabled': false},
  }, _linkToken);

  @override
  Future<PlaidExchange> exchangePublicToken(String publicToken) => _read(
    '/item/public_token/exchange',
    {'public_token': publicToken},
    (json) => (
      accessToken: json['access_token']! as String,
      itemId: json['item_id']! as String,
    ),
  );

  @override
  Future<PlaidItem> getItem(String accessToken) =>
      _read('/item/get', {'access_token': accessToken}, (json) {
        final item = json['item']! as Map<String, Object?>;
        final error = item['error'] as Map<String, Object?>?;
        return PlaidItem(
          itemId: item['item_id']! as String,
          institutionId: item['institution_id']! as String,
          institutionName: item['institution_name']! as String,
          products: [
            for (final p in item['products']! as List<Object?>) p! as String,
          ],
          errorCode: error?['error_code'] as String?,
        );
      });

  @override
  Future<void> removeItem(String accessToken) =>
      _call('/item/remove', {'access_token': accessToken});

  @override
  Future<TransactionsSyncPage> transactionsSync(
    String accessToken,
    String cursor, {
    int count = 500,
  }) => _read(
    '/transactions/sync',
    {
      'access_token': accessToken,
      if (cursor.isNotEmpty) 'cursor': cursor,
      'count': count,
      'options': {'personal_finance_category_version': 'v2'},
    },
    (json) {
      if (json['transactions_update_status'] == 'NOT_READY') {
        return TransactionsSyncPage(
          notReady: true,
          nextCursor: json['next_cursor'] as String? ?? '',
        );
      }
      List<PlaidTransaction> transactions(String key) => [
        for (final t in _list(json[key]))
          PlaidTransaction.fromPlaidJson(t, rounding: rounding),
      ];
      return TransactionsSyncPage(
        added: transactions('added'),
        modified: transactions('modified'),
        removed: [
          for (final r in _list(json['removed']))
            r['transaction_id']! as String,
        ],
        accounts: _accounts(json),
        nextCursor: json['next_cursor']! as String,
        hasMore: json['has_more']! as bool,
      );
    },
  );

  @override
  Future<List<PlaidAccount>> accountsGet(String accessToken) =>
      _read('/accounts/get', {'access_token': accessToken}, _accounts);

  @override
  Future<List<PlaidAccount>> accountsBalanceGet(String accessToken) =>
      _read('/accounts/balance/get', {'access_token': accessToken}, _accounts);

  @override
  Future<PlaidLiabilities> liabilitiesGet(String accessToken) =>
      _read('/liabilities/get', {'access_token': accessToken}, (json) {
        final currencies = {
          for (final a in _accounts(json)) a.accountId: a.currencyCode,
        };
        return PlaidLiabilities.fromPlaidJson(
          json['liabilities']! as Map<String, Object?>,
          (accountId) => currencies[accountId]!,
          rounding: rounding,
        );
      });

  @override
  Future<PlaidHoldings> investmentsHoldingsGet(String accessToken) => _read(
    '/investments/holdings/get',
    {'access_token': accessToken},
    (json) => (
      holdings: [
        for (final h in _list(json['holdings']))
          PlaidHolding.fromPlaidJson(h, rounding: rounding),
      ],
      securities: _securities(json),
    ),
  );

  @override
  Future<PlaidInvestmentTransactions> investmentsTransactionsGet(
    String accessToken, {
    required LocalDate start,
    required LocalDate end,
  }) async {
    final transactions = <PlaidInvestmentTransaction>[];
    final securities = <String, PlaidSecurity>{};
    var total = 0;
    do {
      final page = await _read(
        '/investments/transactions/get',
        {
          'access_token': accessToken,
          'start_date': start.toString(),
          'end_date': end.toString(),
          'options': {
            'count': investmentsPageSize,
            'offset': transactions.length,
          },
        },
        (json) => (
          total: json['total_investment_transactions']! as int,
          transactions: [
            for (final t in _list(json['investment_transactions']))
              PlaidInvestmentTransaction.fromPlaidJson(t, rounding: rounding),
          ],
          securities: _securities(json),
        ),
      );
      total = page.total;
      transactions.addAll(page.transactions);
      for (final s in page.securities) {
        securities[s.securityId] = s;
      }
      if (page.transactions.isEmpty) break;
    } while (transactions.length < total);
    return (transactions: transactions, securities: [...securities.values]);
  }

  @override
  Future<PlaidRecurring> transactionsRecurringGet(
    String accessToken, {
    String? Function(String accountId)? currencyOf,
  }) => _read('/transactions/recurring/get', {'access_token': accessToken}, (
    json,
  ) {
    List<PlaidRecurringStream> streams(String key) => [
      for (final s in _list(json[key]))
        if (_streamCurrency(s, currencyOf) case final currency?)
          PlaidRecurringStream.fromPlaidJson(
            s,
            rounding: rounding,
            currency: currency,
          ),
    ];
    return (
      inflow: streams('inflow_streams'),
      outflow: streams('outflow_streams'),
    );
  });

  /// The currency of stream [s]: its average's, else its account's; null leaves it out.
  static String? _streamCurrency(
    Map<String, Object?> s,
    String? Function(String accountId)? currencyOf,
  ) {
    final average = s['average_amount'] as Map<String, Object?>?;
    return average?['iso_currency_code'] as String? ??
        average?['unofficial_currency_code'] as String? ??
        currencyOf?.call(s['account_id']! as String);
  }

  @override
  Future<Map<String, Object?>> webhookVerificationKeyGet(String keyId) => _read(
    '/webhook_verification_key/get',
    {'key_id': keyId},
    (json) => json['key']! as Map<String, Object?>,
  );

  @override
  Future<PlaidInstitution> institutionsGetById(String institutionId) => _read(
    '/institutions/get_by_id',
    {
      'institution_id': institutionId,
      'country_codes': const ['US'],
      'options': {'include_optional_metadata': true},
    },
    (json) => PlaidInstitution.fromPlaidJson(
      json['institution']! as Map<String, Object?>,
    ),
  );

  @override
  Future<String> sandboxPublicTokenCreate({
    required String institutionId,
    required List<String> products,
    String? overrideUsername,
    String? overridePassword,
    int? daysRequested,
  }) {
    final options = <String, Object?>{
      'override_username': ?overrideUsername,
      'override_password': ?overridePassword,
      if (daysRequested != null)
        'transactions': {'days_requested': daysRequested},
      if (webhookUrl != null) 'webhook': webhookUrl,
    };
    return _read('/sandbox/public_token/create', {
      'institution_id': institutionId,
      'initial_products': products,
      if (options.isNotEmpty) 'options': options,
    }, (json) => json['public_token']! as String);
  }

  @override
  Future<void> sandboxItemResetLogin(String accessToken) =>
      _call('/sandbox/item/reset_login', {'access_token': accessToken});

  @override
  Future<void> sandboxTransactionsCreate(
    String accessToken,
    List<SandboxTransaction> transactions,
  ) => _call('/sandbox/transactions/create', {
    'access_token': accessToken,
    'transactions': [
      for (final t in transactions)
        {
          'date_transacted': t.dateTransacted.toString(),
          'date_posted': t.datePosted.toString(),
          'amount': JsonDecimal(t.amount.toDecimalString()),
          'description': t.description,
          'iso_currency_code': t.amount.currencyCode,
          if (t.accountId != null) 'account_id': t.accountId,
        },
    ],
  });

  @override
  Future<void> sandboxItemFireWebhook(String accessToken, String webhookCode) =>
      _call('/sandbox/item/fire_webhook', {
        'access_token': accessToken,
        'webhook_type': fireWebhookTypes[webhookCode] ?? 'ITEM',
        'webhook_code': webhookCode,
      });

  @override
  Future<void> transactionsRefresh(String accessToken) =>
      _call('/transactions/refresh', {'access_token': accessToken});
}
