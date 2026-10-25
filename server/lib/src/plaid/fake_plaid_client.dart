/// The fake [PlaidClient] of `PLAID_MODE=fake` (`docs/reference/server.md`, **The fake
/// Plaid client**).
///
/// Deterministic canned data per institution from `fake_fixtures/<institution_id>.json`,
/// shaped like Sandbox responses. Its [provenance] is `demo`, so everything the server
/// stores from it carries `source: demo` and nothing fabricated wears `plaid` (`PLAN.md`
/// §7.1).
///
/// Tokens are derivable, so the fake keeps working after a restart with no state of its
/// own: a public token names its institution, an access token names its institution and
/// Item, and an Item's state is rebuilt from the fixture the first time its token is seen.
/// A public token the fake did not mint maps to the default institution (First Platypus
/// Bank). `/transactions/sync` answers `NOT_READY` on the first call with an empty cursor
/// for an Item it has just seen, then pages the fixture's transactions by `count`, then
/// empty pages, each listing the Item's accounts other than `investment` ones, as
/// Sandbox lists only the accounts Transactions covers; `accountsGet` lists them all.
/// `sandboxTransactionsCreate` appends. A custom user
/// (`override_username: user_custom`) is built from its configuration instead of a
/// fixture: its accounts (`starting_balance` as the current balance) and transactions,
/// at any of the persona engine's institutions, with no liabilities, recurring streams or
/// investments. Custom users and transactions created through Sandbox calls live only as
/// long as the process. The test hooks ([failNext], [onCall],
/// [modifyTransaction], [removeTransaction], [repairLogin], [addWebhookKey]) script what
/// Sandbox would do. `institutionsGetById` answers a fixture's institution, with its logo
/// and colour only when the fixture carries them.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:finance_tracker_server/src/ids.dart';
import 'package:finance_tracker_server/src/plaid/plaid_client.dart';
import 'package:finance_tracker_server/src/plaid/plaid_json.dart';
import 'package:shared_models/shared_models.dart';

/// The institution a token the fake did not mint maps to.
const defaultFakeInstitution = 'ins_109508';

/// The institutions a custom user may be created at: the persona engine's non-OAuth
/// test banks, by name.
const customUserInstitutions = {
  'ins_109508': 'First Platypus Bank',
  'ins_109509': 'First Gingham Credit Union',
  'ins_109510': 'Tattersall Federal Credit Union',
  'ins_109511': 'Tartan Bank',
};

final _publicToken = RegExp(r'^public-sandbox-fake-(ins_[0-9]+)-[0-9a-f-]+$');
final _accessToken = RegExp(r'^access-sandbox-fake-(ins_[0-9]+)-([0-9a-f-]+)$');

/// The fake client.
final class FakePlaidClient implements PlaidClient {
  FakePlaidClient._(this._fixtures, this.now);

  /// Loads every fixture under `lib/src/plaid/fake_fixtures/`. [now] is the server's
  /// clock, for Link token expirations.
  static Future<FakePlaidClient> load({
    required DateTime Function() now,
  }) async {
    final dir = await Isolate.resolvePackageUri(
      Uri.parse('package:finance_tracker_server/src/plaid/fake_fixtures/'),
    );
    final fixtures = <String, Map<String, Object?>>{};
    for (final file in Directory.fromUri(dir!).listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final institution = json['institution']! as Map<String, Object?>;
      fixtures[institution['institution_id']! as String] = json;
    }
    return FakePlaidClient._(fixtures, now);
  }

  final Map<String, Map<String, Object?>> _fixtures;

  /// The server's clock.
  final DateTime Function() now;

  final Map<String, _FakeItem> _items = {};

  /// Custom users by the public token minted for them: a fixture-shaped description.
  final Map<String, Map<String, Object?>> _customUsers = {};
  final Map<String, List<PlaidException?>> _failures = {};
  final Map<String, Map<String, Object?>> _webhookKeys = {};
  var _sandboxCounter = 0;

  @override
  DataSource get provenance => DataSource.demo;

  /// Makes the next [times] calls of [method] (the interface method's name) throw
  /// [error], after [skip] calls that succeed.
  void failNext(
    String method,
    PlaidException error, {
    int times = 1,
    int skip = 0,
  }) => _failures.putIfAbsent(method, () => []).addAll([
    ...List.filled(skip, null),
    ...List.filled(times, error),
  ]);

  /// Runs before every call, with the interface method's name, so a test can interleave
  /// other requests with a Plaid call in flight.
  Future<void> Function(String method)? onCall;

  /// How many Items the fake has seen that are not removed.
  int get liveItemCount => _items.values.where((i) => !i.removed).length;

  /// Changes a transaction of the Item of [accessToken]; it comes back as `modified`.
  void modifyTransaction(
    String accessToken,
    String transactionId, {
    Money? amount,
    bool? pending,
    String? name,
  }) {
    final item = _item(accessToken);
    final current = item.current[transactionId]!;
    final changed = PlaidTransaction(
      transactionId: current.transactionId,
      accountId: current.accountId,
      amount: amount ?? current.amount,
      date: current.date,
      authorizedDate: current.authorizedDate,
      pending: pending ?? current.pending,
      pendingTransactionId: current.pendingTransactionId,
      name: name ?? current.name,
      merchantName: current.merchantName,
      logoUrl: current.logoUrl,
      primaryCategory: current.primaryCategory,
      detailedCategory: current.detailedCategory,
    );
    item.current[transactionId] = changed;
    item.events.add((
      kind: _Kind.modified,
      transaction: changed,
      id: transactionId,
    ));
  }

  /// Removes a transaction of the Item of [accessToken]; it comes back as `removed`.
  void removeTransaction(String accessToken, String transactionId) {
    final item = _item(accessToken);
    item.current.remove(transactionId);
    item.events.add((
      kind: _Kind.removed,
      transaction: null,
      id: transactionId,
    ));
  }

  /// Serves [jwk] from `webhookVerificationKeyGet` under its `kid`, as Plaid serves the
  /// key that signs its webhooks.
  void addWebhookKey(Map<String, Object?> jwk) =>
      _webhookKeys[jwk['kid']! as String] = jwk;

  /// Ends the `ITEM_LOGIN_REQUIRED` state [sandboxItemResetLogin] started, as a completed
  /// update-mode Link would.
  void repairLogin(String accessToken) =>
      _item(accessToken).loginRequired = false;

  Future<void> _maybeFail(String method) async {
    await onCall?.call(method);
    final queue = _failures[method];
    if (queue != null && queue.isNotEmpty) {
      final failure = queue.removeAt(0);
      if (failure != null) throw failure;
    }
  }

  _FakeItem _item(String accessToken) {
    final known = _items[accessToken];
    if (known != null) {
      if (known.removed) {
        throw const PlaidException('ITEM_ERROR', 'ITEM_NOT_FOUND');
      }
      return known;
    }
    final match = _accessToken.firstMatch(accessToken);
    final fixture = match == null ? null : _fixtures[match[1]];
    if (match == null || fixture == null) {
      throw const PlaidException('INVALID_INPUT', 'INVALID_ACCESS_TOKEN');
    }
    final item = _items.putIfAbsent(
      accessToken,
      () => _FakeItem(fixture, 'fake-item-${match[2]}'),
    );
    if (item.removed) {
      throw const PlaidException('ITEM_ERROR', 'ITEM_NOT_FOUND');
    }
    return item;
  }

  _FakeItem _healthyItem(String accessToken) {
    final item = _item(accessToken);
    if (item.loginRequired) {
      throw const PlaidException(
        'ITEM_ERROR',
        'ITEM_LOGIN_REQUIRED',
        'the login details of this item have changed',
      );
    }
    return item;
  }

  PlaidLinkToken _linkToken() => (
    linkToken: 'link-sandbox-fake-${newId()}',
    expiration: now().toUtc().add(const Duration(hours: 4)),
  );

  @override
  Future<PlaidLinkToken> createLinkToken(LinkTokenRequest request) async {
    await _maybeFail('createLinkToken');
    return _linkToken();
  }

  @override
  Future<PlaidLinkToken> createUpdateLinkToken(
    String accessToken, {
    required String clientUserId,
    required String androidPackageName,
  }) async {
    await _maybeFail('createUpdateLinkToken');
    _item(accessToken);
    return _linkToken();
  }

  @override
  Future<PlaidExchange> exchangePublicToken(String publicToken) async {
    await _maybeFail('exchangePublicToken');
    final institution =
        _publicToken.firstMatch(publicToken)?[1] ?? defaultFakeInstitution;
    final suffix = newId();
    final accessToken = 'access-sandbox-fake-$institution-$suffix';
    final custom = _customUsers.remove(publicToken);
    if (custom != null) {
      _items[accessToken] = _FakeItem(custom, 'fake-item-$suffix');
    }
    return (accessToken: accessToken, itemId: _item(accessToken).itemId);
  }

  @override
  Future<PlaidItem> getItem(String accessToken) async {
    await _maybeFail('getItem');
    final item = _item(accessToken);
    final institution = item.fixture['institution']! as Map<String, Object?>;
    return PlaidItem(
      itemId: item.itemId,
      institutionId: institution['institution_id']! as String,
      institutionName: institution['name']! as String,
      products: [
        for (final p in item.fixture['products']! as List<Object?>)
          p! as String,
      ],
      errorCode: item.loginRequired ? 'ITEM_LOGIN_REQUIRED' : null,
    );
  }

  @override
  Future<void> removeItem(String accessToken) async {
    await _maybeFail('removeItem');
    _item(accessToken).removed = true;
  }

  @override
  Future<TransactionsSyncPage> transactionsSync(
    String accessToken,
    String cursor, {
    int count = 500,
  }) async {
    await _maybeFail('transactionsSync');
    final item = _healthyItem(accessToken);
    if (cursor.isEmpty && !item.notReadyServed) {
      item.notReadyServed = true;
      return const TransactionsSyncPage(notReady: true, nextCursor: '');
    }
    final position = cursor.isEmpty
        ? 0
        : int.tryParse(cursor.replaceFirst('fake-cursor-', '')) ?? -1;
    if (position < 0 || position > item.events.length) {
      throw const PlaidException('INVALID_INPUT', 'INVALID_FIELD', 'cursor');
    }
    final end = (position + count).clamp(0, item.events.length);
    final events = item.events.sublist(position, end);
    return TransactionsSyncPage(
      added: [
        for (final e in events)
          if (e.kind == _Kind.added) e.transaction!,
      ],
      modified: [
        for (final e in events)
          if (e.kind == _Kind.modified) e.transaction!,
      ],
      removed: [
        for (final e in events)
          if (e.kind == _Kind.removed) e.id,
      ],
      // As Sandbox does, a page lists only the accounts Transactions covers.
      accounts: [
        for (final a in item.accounts)
          if (a.type != 'investment') a,
      ],
      nextCursor: 'fake-cursor-$end',
      hasMore: end < item.events.length,
    );
  }

  @override
  Future<List<PlaidAccount>> accountsGet(String accessToken) async {
    await _maybeFail('accountsGet');
    return _healthyItem(accessToken).accounts;
  }

  @override
  Future<List<PlaidAccount>> accountsBalanceGet(String accessToken) async {
    await _maybeFail('accountsBalanceGet');
    return _healthyItem(accessToken).accounts;
  }

  @override
  Future<PlaidLiabilities> liabilitiesGet(String accessToken) async {
    await _maybeFail('liabilitiesGet');
    final item = _healthyItem(accessToken);
    final currencies = {
      for (final a in item.accounts) a.accountId: a.currencyCode,
    };
    return PlaidLiabilities.fromPlaidJson(
      item.prefixAccounts(item.fixture['liabilities']! as Map<String, Object?>),
      (accountId) => currencies[accountId]!,
    );
  }

  @override
  Future<PlaidHoldings> investmentsHoldingsGet(String accessToken) async {
    await _maybeFail('investmentsHoldingsGet');
    _healthyItem(accessToken);
    return (holdings: <PlaidHolding>[], securities: <PlaidSecurity>[]);
  }

  @override
  Future<PlaidInvestmentTransactions> investmentsTransactionsGet(
    String accessToken, {
    required LocalDate start,
    required LocalDate end,
  }) async {
    await _maybeFail('investmentsTransactionsGet');
    _healthyItem(accessToken);
    return (
      transactions: <PlaidInvestmentTransaction>[],
      securities: <PlaidSecurity>[],
    );
  }

  @override
  Future<PlaidRecurring> transactionsRecurringGet(
    String accessToken, {
    String? Function(String accountId)? currencyOf,
  }) async {
    await _maybeFail('transactionsRecurringGet');
    final item = _healthyItem(accessToken);
    final recurring = item.prefixAccounts(
      item.fixture['recurring']! as Map<String, Object?>,
    );
    List<PlaidRecurringStream> streams(String key) => [
      for (final s in recurring[key]! as List<Object?>)
        PlaidRecurringStream.fromPlaidJson(s! as Map<String, Object?>),
    ];
    return (
      inflow: streams('inflow_streams'),
      outflow: streams('outflow_streams'),
    );
  }

  @override
  Future<Map<String, Object?>> webhookVerificationKeyGet(String keyId) async {
    await _maybeFail('webhookVerificationKeyGet');
    return _webhookKeys[keyId] ??
        (throw const PlaidException(
          'INVALID_INPUT',
          'INVALID_WEBHOOK_VERIFICATION_KEY_ID',
        ));
  }

  @override
  Future<PlaidInstitution> institutionsGetById(String institutionId) async {
    await _maybeFail('institutionsGetById');
    final fixture = _fixtures[institutionId];
    if (fixture != null) {
      return PlaidInstitution.fromPlaidJson(
        fixture['institution']! as Map<String, Object?>,
      );
    }
    final name = customUserInstitutions[institutionId];
    if (name == null) {
      throw const PlaidException('INVALID_INPUT', 'INVALID_INSTITUTION');
    }
    return PlaidInstitution(institutionId: institutionId, name: name);
  }

  @override
  Future<String> sandboxPublicTokenCreate({
    required String institutionId,
    required List<String> products,
    String? overrideUsername,
    String? overridePassword,
    int? daysRequested,
  }) async {
    await _maybeFail('sandboxPublicTokenCreate');
    final token = 'public-sandbox-fake-$institutionId-${newId()}';
    if (overrideUsername == 'user_custom') {
      final name = customUserInstitutions[institutionId];
      if (name == null) {
        throw const PlaidException('INVALID_INPUT', 'INVALID_INSTITUTION');
      }
      _customUsers[token] = _customFixture(
        institutionId,
        name,
        products,
        overridePassword ?? '',
      );
      return token;
    }
    if (!_fixtures.containsKey(institutionId)) {
      throw const PlaidException('INVALID_INPUT', 'INVALID_INSTITUTION');
    }
    return token;
  }

  /// A custom user's configuration as a fixture: its accounts and their transactions in
  /// Plaid's response shapes, no liabilities and no recurring streams. A configuration
  /// it cannot read is Plaid's `INVALID_FIELD`.
  static Map<String, Object?> _customFixture(
    String institutionId,
    String name,
    List<String> products,
    String password,
  ) {
    final accounts = <Map<String, Object?>>[];
    final transactions = <Map<String, Object?>>[];
    try {
      final config = decodePlaidJson(password)! as Map<String, Object?>;
      for (final (i, raw)
          in (config['override_accounts']! as List<Object?>).indexed) {
        final account = raw! as Map<String, Object?>;
        final meta = account['meta']! as Map<String, Object?>;
        final currency = account['currency']! as String;
        final accountId = 'acc${i + 1}';
        accounts.add({
          'account_id': accountId,
          'name': meta['name']! as String,
          'official_name': meta['official_name'],
          'mask': meta['mask'],
          'type': account['type']! as String,
          'subtype': account['subtype'],
          'balances': {
            'current': account['starting_balance'],
            'available': null,
            'limit': meta['limit'],
            'iso_currency_code': currency,
          },
        });
        for (final t
            in (account['transactions'] as List<Object?>?) ?? const []) {
          final transaction = t! as Map<String, Object?>;
          transactions.add({
            'transaction_id': 't${transactions.length + 1}',
            'account_id': accountId,
            'amount': transaction['amount'],
            'iso_currency_code': transaction['currency'] ?? currency,
            'date': transaction['date_posted']! as String,
            'authorized_date': transaction['date_transacted'],
            'pending': false,
            'name': transaction['description']! as String,
          });
        }
      }
    } on Object {
      throw const PlaidException(
        'INVALID_INPUT',
        'INVALID_FIELD',
        'override_password is not a custom-user configuration',
      );
    }
    return {
      'institution': {'institution_id': institutionId, 'name': name},
      'products': products,
      'accounts': accounts,
      'transactions': transactions,
      'recurring': {
        'inflow_streams': <Object?>[],
        'outflow_streams': <Object?>[],
      },
      'liabilities': <String, Object?>{},
    };
  }

  @override
  Future<void> sandboxItemResetLogin(String accessToken) async {
    await _maybeFail('sandboxItemResetLogin');
    _item(accessToken).loginRequired = true;
  }

  @override
  Future<void> sandboxTransactionsCreate(
    String accessToken,
    List<SandboxTransaction> transactions,
  ) async {
    await _maybeFail('sandboxTransactionsCreate');
    final item = _healthyItem(accessToken);
    if (transactions.length > 10) {
      throw const PlaidException(
        'INVALID_INPUT',
        'INVALID_FIELD',
        'at most ten',
      );
    }
    for (final t in transactions) {
      final accountId = t.accountId ?? item.accounts.first.accountId;
      if (!item.accounts.any((a) => a.accountId == accountId)) {
        throw const PlaidException('INVALID_INPUT', 'INVALID_ACCOUNT_ID');
      }
    }
    for (final t in transactions) {
      final created = PlaidTransaction(
        transactionId: '${item.itemId}-sandbox-${++_sandboxCounter}',
        accountId: t.accountId ?? item.accounts.first.accountId,
        amount: t.amount,
        date: t.datePosted,
        authorizedDate: t.dateTransacted,
        pending: false,
        name: t.description,
      );
      item.current[created.transactionId] = created;
      item.events.add((
        kind: _Kind.added,
        transaction: created,
        id: created.transactionId,
      ));
    }
  }

  @override
  Future<void> sandboxItemFireWebhook(
    String accessToken,
    String webhookCode,
  ) async {
    await _maybeFail('sandboxItemFireWebhook');
    _item(accessToken);
  }

  @override
  Future<void> transactionsRefresh(String accessToken) async {
    await _maybeFail('transactionsRefresh');
    _healthyItem(accessToken);
  }
}

enum _Kind { added, modified, removed }

typedef _Event = ({_Kind kind, PlaidTransaction? transaction, String id});

final class _FakeItem {
  _FakeItem(this.fixture, this.itemId) {
    accounts = [
      for (final a in fixture['accounts']! as List<Object?>)
        PlaidAccount.fromPlaidJson(prefixAccounts(a! as Map<String, Object?>)),
    ];
    for (final t in fixture['transactions']! as List<Object?>) {
      final transaction = PlaidTransaction.fromPlaidJson(
        _prefix(t! as Map<String, Object?>, const [
          'account_id',
          'transaction_id',
          'pending_transaction_id',
        ]),
      );
      current[transaction.transactionId] = transaction;
      events.add((
        kind: _Kind.added,
        transaction: transaction,
        id: transaction.transactionId,
      ));
    }
  }

  final Map<String, Object?> fixture;
  final String itemId;
  late final List<PlaidAccount> accounts;
  final Map<String, PlaidTransaction> current = {};
  final List<_Event> events = [];
  bool notReadyServed = false;
  bool loginRequired = false;
  bool removed = false;

  /// Plaid's ids are unique per Item; the fixture's short ids are prefixed with the
  /// Item's, at every depth.
  Map<String, Object?> prefixAccounts(Map<String, Object?> json) =>
      _prefix(json, const ['account_id']);

  Map<String, Object?> _prefix(Map<String, Object?> json, List<String> keys) {
    Object? walk(Object? node) => switch (node) {
      final Map<String, Object?> map => {
        for (final MapEntry(:key, :value) in map.entries)
          key: keys.contains(key) && value is String
              ? '$itemId-$value'
              : walk(value),
      },
      final List<Object?> list => [for (final e in list) walk(e)],
      _ => node,
    };
    return walk(json)! as Map<String, Object?>;
  }
}
