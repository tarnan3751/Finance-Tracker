/// The in-app fake server: every operation of `api/openapi.yaml`, in process, behind a Dio
/// adapter (`fake_http_adapter.dart`), so the demo flavor and the tests run the generated
/// client, `HttpFinanceApi` and the auth interceptor unchanged with no network.
///
/// It follows the dev server's rules (`docs/reference/server.md`):
///
/// - **Auth.** Emails are lower-cased and unique (409 `email_taken`); registration and
///   every login create a device and a refresh-token family. Access tokens are opaque
///   random strings valid 15 minutes on the server's clock (`token_expired` after);
///   refresh tokens are random, kept by SHA-256 only, valid 30 days and rotated on use;
///   presenting a revoked one revokes its family (reuse detection, no grace window) and is
///   `token_revoked`, as is an unknown one. The bearer check also requires the device to
///   hold a live family, so logout and device removal end its access tokens at once. A
///   missing or unknown access token is `invalid_credentials`.
/// - **Passwords** are salted SHA-256: this is the fake only, which never holds a real
///   password worth protecting; the dev server uses Argon2id.
/// - **Sync.** One `InMemorySyncRelay` per user, the engine's reference relay, on the
///   server's clock. Before an entry reaches it, one whose `device_id` is not the caller's
///   or whose payload says `source: plaid` is rejected `invalid`, as the dev server does;
///   the relay rejects the rest (`clock_drift`, `invalid`, `conflicting_duplicate`) and
///   leaves out the caller's own entries on pull. A `since` past the user's last `seq` is
///   409 `sync_cursor_invalid`.
/// - **Plaid.** Over a [FakeDataset]: a link token, then an exchange that links the
///   dataset Item a `public-demo-<item id>` token names (any other token links the first);
///   exchanging an Item already linked returns it again. A sync answers `not_ready` once,
///   then `completed`, applying the Item's rows with their ids as given and the next
///   `sync_version`s of the user (transactions in dataset order, then investment
///   transactions). A refresh answers `started` and makes the next sync re-apply the
///   Item's transactions as modified; the balance refresh answers the Item's accounts.
///   Unlinking with `history=delete` (the default) tombstones its transactions under new
///   versions and drops its accounts; with `keep` the data stays and the Item is listed
///   `removed`, and every call that would reach Plaid for it is 409 `conflict`. The logo
///   route serves a dataset Item's `institutionLogo`, and `logo_url` points at it only
///   then. The webhook is always 401 `webhook_unverified`.
/// - **Sandbox.** Reset-login makes the Item `login_required` (`ITEM_LOGIN_REQUIRED`):
///   sync, refresh, the balance refresh and created transactions answer 409
///   `item_login_required` until an update-mode link token is created for it and
///   `public-demo-update-<item id>` is exchanged, which repairs it and returns it.
///   Fire-webhook is a no-op. Created transactions are appended to the user's data at
///   once, `source: demo`, in our sign, under new `sync_version`s. A provisioning job is
///   queued, and completes on the first `getProvisionJob` after the clock has moved past
///   its creation: it links the persona's Items from `FakeDataset.fromDemoSeed` for the
///   user (the demo data, with no injection batches) and applies them.
/// - **Data.** `/transactions` and `/investments/transactions` page by version with the
///   same 409 for a `since` past the user's version.
/// - **Shapes.** Success bodies are `shared_models` or `api_models` JSON; every 4xx and
///   5xx is `application/problem+json` (`ValidationProblem` for a 400), and a 401 carries
///   `WWW-Authenticate: Bearer`. An unknown route is 404 `not_found`. Every answer has an
///   `X-Request-Id`. `fake_contract_test.dart` validates them against the contract.
///
/// Not mirrored: the dev server's rate limiter; a test scripts a 429 with [failNext].
/// Hooks for tests: [failNext], [failNextNetwork], [latency], [advanceClock], [calls].
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_http_adapter.dart';
import 'package:finance_tracker/core/api/fake/fake_validation.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:persona_engine/persona_engine.dart'
    show PersonaId, generateDemoSeed;
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

/// One contract operation the fake serves.
final class FakeRoute {
  const FakeRoute(
    this.operationId,
    this.method,
    this.template, {
    this.authenticated = true,
  });

  final String operationId;

  /// Upper case.
  final String method;

  /// The contract's path template, without `/v1`.
  final String template;

  /// Whether the contract requires `bearerAuth`.
  final bool authenticated;

  RegExp get _pattern => RegExp(
    '^${template.replaceAllMapped(RegExp(r'\{[a-z_]+\}'), (_) => '([^/]+)')}\$',
  );

  List<String> get _parameterNames => [
    for (final Match m in RegExp(r'\{([a-z_]+)\}').allMatches(template)) m[1]!,
  ];
}

/// A request as the fake sees it. [body] is the decoded JSON, or [invalidJson].
typedef FakeRequest = ({
  String method,
  String path,
  Map<String, String> query,
  Map<String, String> headers,
  Object? body,
});

/// An answer: a status, a JSON body (null for none) and headers.
typedef FakeResponse = ({
  int status,
  Object? body,
  Map<String, String> headers,
});

/// The [FakeRequest.body] of a request whose body is not JSON.
const Object invalidJson = _InvalidJson();

final class _InvalidJson {
  const _InvalidJson();
}

/// A scripted failure of the next call to an operation.
typedef _Failure = ({int? status, String? code});

final class _User {
  _User(this.id, this.email, this.salt, this.hash, this.displayName, this.at);

  final String id;
  final String email;
  final String salt;
  final String hash;
  final String displayName;
  final DateTime at;

  User toUser() =>
      User(id: id, email: email, displayName: displayName, createdAt: at);
}

final class _Refresh {
  _Refresh(this.deviceId, this.familyId, this.expiresAt);

  final String deviceId;
  final String familyId;
  final DateTime expiresAt;
  DateTime? revokedAt;
}

typedef _Access = ({String userId, String deviceId, DateTime expiresAt});

final class _LinkedItem {
  _LinkedItem(this.data);

  final FakeItemData data;
  int syncCalls = 0;
  DateTime? lastSuccessfulSyncAt;
  bool applied = false;
  ItemStatus status = ItemStatus.healthy;
  String? errorCode;

  /// Set by a refresh: the next completed sync re-applies the transactions as modified.
  bool refreshPending = false;

  /// Whether an update-mode link token was created since the login was reset.
  bool updateTokenIssued = false;

  /// How many transactions were created through Sandbox, for their ids.
  int created = 0;
}

final class _FakeJob {
  _FakeJob({
    required this.id,
    required this.userId,
    required this.persona,
    required this.seed,
    required this.days,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final PersonaId persona;
  final int seed;
  final int days;
  final DateTime createdAt;

  /// `queued` or `completed`: the fake's jobs never fail on their own.
  String status = 'queued';
  DateTime? finishedAt;
  final List<String> itemIds = [];

  Map<String, Object?> toJson() => {
    'id': id,
    'persona': persona.slug,
    'seed': seed,
    'status': status,
    'created_at': const UtcInstantConverter().toJson(createdAt),
    'finished_at': finishedAt == null
        ? null
        : const UtcInstantConverter().toJson(finishedAt!),
    'progress': {
      'items_total': itemIds.length,
      'items_linked': itemIds.length,
      'batches_total': 0,
      'batches_sent': 0,
      'skipped': 0,
    },
    'error': null,
    'item_ids': [...itemIds],
  };
}

final class _UserData {
  _UserData(this.relay);

  final InMemorySyncRelay relay;
  final Map<String, _LinkedItem> items = {};
  final Map<String, Transaction> transactions = {};
  final Map<String, InvestmentTransaction> investmentTransactions = {};
  int version = 0;
}

/// The fake server.
final class FakeServer {
  /// A server over [dataset] (none by default) whose clock is [now] (the system's, UTC,
  /// by default), drawing ids and tokens from [random] (secure by default). [localDate]
  /// is the device's calendar date at an instant, which a provisioning job generates its
  /// persona at, as the demo store does (the UTC date by default).
  FakeServer({
    FakeDataset? dataset,
    DateTime Function()? now,
    Random? random,
    LocalDate Function(DateTime instant)? localDate,
  }) : dataset = dataset ?? FakeDataset(items: const []),
       _now = now ?? (() => DateTime.now().toUtc()),
       _random = random ?? Random.secure(),
       _localDate = localDate ?? LocalDate.fromDateTime;

  /// What an exchange can link.
  final FakeDataset dataset;
  final DateTime Function() _now;
  final Random _random;
  final LocalDate Function(DateTime instant) _localDate;

  /// The base URL a client of the fake uses; it never leaves the process.
  static final Uri baseUrl = Uri.parse('https://fake.financetracker.test');

  /// How long every answer takes; zero (no timer at all) by default.
  Duration latency = Duration.zero;

  /// The adapter to give the client's Dio.
  late final HttpClientAdapter adapter = FakeHttpAdapter(this);

  static const Duration accessLifetime = Duration(minutes: 15);
  static const Duration refreshLifetime = Duration(days: 30);

  /// Every contract operation, with the contract's template and security.
  static const List<FakeRoute> routes = [
    FakeRoute('register', 'POST', '/auth/register', authenticated: false),
    FakeRoute('login', 'POST', '/auth/login', authenticated: false),
    FakeRoute('refreshTokens', 'POST', '/auth/refresh', authenticated: false),
    FakeRoute('logout', 'POST', '/auth/logout'),
    FakeRoute('getMe', 'GET', '/me'),
    FakeRoute('deleteMe', 'DELETE', '/me'),
    FakeRoute('listDevices', 'GET', '/devices'),
    FakeRoute('deleteDevice', 'DELETE', '/devices/{device_id}'),
    FakeRoute('createLinkToken', 'POST', '/plaid/link-token'),
    FakeRoute('exchangePublicToken', 'POST', '/plaid/exchange'),
    FakeRoute('listItems', 'GET', '/plaid/items'),
    FakeRoute('deleteItem', 'DELETE', '/plaid/items/{item_id}'),
    FakeRoute('syncItem', 'POST', '/plaid/items/{item_id}/sync'),
    FakeRoute('refreshItem', 'POST', '/plaid/items/{item_id}/refresh'),
    FakeRoute('refreshBalances', 'POST', '/plaid/items/{item_id}/balances'),
    FakeRoute(
      'getInstitutionLogo',
      'GET',
      '/institutions/{institution_id}/logo',
    ),
    FakeRoute(
      'createUpdateLinkToken',
      'POST',
      '/plaid/items/{item_id}/update-link-token',
    ),
    FakeRoute('listAccounts', 'GET', '/accounts'),
    FakeRoute('listTransactions', 'GET', '/transactions'),
    FakeRoute('getLiabilities', 'GET', '/liabilities'),
    FakeRoute('listHoldings', 'GET', '/investments/holdings'),
    FakeRoute('listInvestmentTransactions', 'GET', '/investments/transactions'),
    FakeRoute('listRecurringStreams', 'GET', '/recurring'),
    FakeRoute('pushChanges', 'POST', '/sync/push'),
    FakeRoute('pullChanges', 'GET', '/sync/pull'),
    FakeRoute(
      'receivePlaidWebhook',
      'POST',
      '/webhooks/plaid',
      authenticated: false,
    ),
    FakeRoute(
      'sandboxResetLogin',
      'POST',
      '/sandbox/items/{item_id}/reset-login',
    ),
    FakeRoute(
      'sandboxFireWebhook',
      'POST',
      '/sandbox/items/{item_id}/fire-webhook',
    ),
    FakeRoute(
      'sandboxCreateTransactions',
      'POST',
      '/sandbox/items/{item_id}/transactions',
    ),
    FakeRoute('provisionPersona', 'POST', '/sandbox/provision'),
    FakeRoute('getProvisionJob', 'GET', '/sandbox/provision/{job_id}'),
    FakeRoute('getHealth', 'GET', '/health', authenticated: false),
  ];

  /// The route [method] [path] (without `/v1`) matches, with its path parameters.
  static ({FakeRoute route, Map<String, String> parameters})? match(
    String method,
    String path,
  ) {
    for (final FakeRoute route in routes) {
      if (route.method != method) continue;
      final RegExpMatch? m = route._pattern.firstMatch(path);
      if (m == null) continue;
      final List<String> names = route._parameterNames;
      return (
        route: route,
        parameters: {
          for (int i = 0; i < names.length; i++)
            names[i]: Uri.decodeComponent(m[i + 1]!),
        },
      );
    }
    return null;
  }

  // --- test hooks -----------------------------------------------------------------------

  Duration _offset = Duration.zero;
  final Map<String, List<_Failure>> _failures = {};

  /// The operation ids of every request answered, in order (`unknown` for no route).
  final List<String> calls = [];

  /// The server's clock: UTC, millisecond precision.
  DateTime now() {
    final DateTime t = _now().add(_offset);
    return DateTime.fromMillisecondsSinceEpoch(
      t.millisecondsSinceEpoch,
      isUtc: true,
    );
  }

  /// Moves the server's clock on by [by] (to expire tokens in a test).
  void advanceClock(Duration by) => _offset += by;

  /// The next call to [operationId] is answered [status] with [code] (by default the
  /// code the contract gives that status), before anything else is checked.
  void failNext(String operationId, int status, {String? code}) =>
      (_failures[operationId] ??= []).add((status: status, code: code));

  /// The next call to [operationId] fails with no answer, as a lost connection.
  void failNextNetwork(String operationId) =>
      (_failures[operationId] ??= []).add((status: null, code: null));

  /// Whether the next call to [operationId] fails on the network; consumes it if so.
  bool takeNetworkFailure(String operationId) {
    final List<_Failure>? queue = _failures[operationId];
    if (queue == null || queue.isEmpty || queue.first.status != null) {
      return false;
    }
    queue.removeAt(0);
    return true;
  }

  // --- state ----------------------------------------------------------------------------

  final Map<String, _User> _users = {};
  final Map<String, Device> _devices = {};
  final Map<String, _Refresh> _refreshByHash = {};
  final Map<String, _Access> _access = {};
  final Map<String, _UserData> _data = {};
  final Map<String, _FakeJob> _jobs = {};
  int _counter = 0;

  String _id(String prefix) => '$prefix-${++_counter}';

  String _secret(String prefix) {
    final List<int> bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return '$prefix-${base64Url.encode(bytes).replaceAll('=', '')}';
  }

  static String _sha256(String text) =>
      sha256.convert(utf8.encode(text)).toString();

  _UserData _dataOf(String userId) => _data[userId] ??= _UserData(
    InMemorySyncRelay(nowWallMillis: () => now().millisecondsSinceEpoch),
  );

  // --- seeding --------------------------------------------------------------------------

  /// Whether a user has [email].
  bool hasUser(String email) => _users.containsKey(email.toLowerCase());

  /// Creates a user directly, as registration would; returns its id.
  String seedUser({
    required String email,
    required String password,
    String? displayName,
  }) => _createUser(email, password, displayName).id;

  /// Signs [email] in directly, as a login would, and returns the session a client would
  /// store; the demo flavor and the tests start signed in through it.
  Session seedSession({
    required String email,
    required String password,
    String deviceName = 'Android device',
  }) {
    final _User? user = _users[email.toLowerCase()];
    if (user == null || !_passwordMatches(user, password)) {
      throw ArgumentError('no such user: $email');
    }
    final Map<String, Object?> tokens = _signIn(user, deviceName);
    return Session(
      accessToken: tokens['access_token']! as String,
      refreshToken: tokens['refresh_token']! as String,
      accessExpiresAt: now().add(accessLifetime),
      user: user.toUser(),
      device: _devices[(tokens['device']! as Map)['id']]!,
    );
  }

  /// Links every dataset Item to the user [email] and applies it, as a completed sync.
  void seedLinkedItems(String email) {
    final _User user = _users[email.toLowerCase()]!;
    final _UserData data = _dataOf(user.id);
    for (final FakeItemData item in dataset.items) {
      final _LinkedItem linked = data.items[item.id] ??= _LinkedItem(item);
      linked.syncCalls = 1;
      _apply(data, linked);
    }
  }

  _User _createUser(String email, String password, String? displayName) {
    final String key = email.toLowerCase();
    final String salt = _secret('salt');
    final _User user = _User(
      _id('user'),
      key,
      salt,
      _sha256('$salt:$password'),
      displayName ?? key.substring(0, key.indexOf('@')),
      now(),
    );
    _users[key] = user;
    return user;
  }

  bool _passwordMatches(_User user, String password) =>
      _sha256('${user.salt}:$password') == user.hash;

  Map<String, Object?> _signIn(_User user, String deviceName) {
    final Device device = Device(
      id: _id('device'),
      userId: user.id,
      name: deviceName,
    );
    _devices[device.id] = device;
    return _tokens(user.id, device, _id('family'));
  }

  Map<String, Object?> _tokens(String userId, Device device, String familyId) {
    final String access = _secret('fake-at');
    final String refresh = _secret('fake-rt');
    _access[access] = (
      userId: userId,
      deviceId: device.id,
      expiresAt: now().add(accessLifetime),
    );
    _refreshByHash[_sha256(refresh)] = _Refresh(
      device.id,
      familyId,
      now().add(refreshLifetime),
    );
    return {
      'access_token': access,
      'refresh_token': refresh,
      'access_expires_in': accessLifetime.inSeconds,
      'device': device.toJson(),
    };
  }

  bool _deviceLive(String deviceId) => _refreshByHash.values.any(
    (r) =>
        r.deviceId == deviceId &&
        r.revokedAt == null &&
        r.expiresAt.isAfter(now()),
  );

  void _revokeFamily(String familyId) {
    for (final _Refresh r in _refreshByHash.values) {
      if (r.familyId == familyId) r.revokedAt ??= now();
    }
  }

  void _removeDevice(String deviceId) {
    for (final _Refresh r in _refreshByHash.values) {
      if (r.deviceId == deviceId) r.revokedAt ??= now();
    }
    _devices.remove(deviceId);
  }

  // --- the pipeline ---------------------------------------------------------------------

  /// Answers [request]; never throws.
  Future<FakeResponse> handle(FakeRequest request) async {
    final String requestId = _id('req');
    FakeResponse response;
    final matched = match(request.method, request.path);
    calls.add(matched?.route.operationId ?? 'unknown');
    try {
      if (matched == null) {
        throw const _Problem(404, 'not_found', 'No such route');
      }
      final _Failure? failure = _takeFailure(matched.route.operationId);
      if (failure != null) {
        final int status = failure.status!;
        throw _Problem(status, failure.code ?? _defaultCode(status), null);
      }
      final _Caller? caller = matched.route.authenticated
          ? _authenticate(request.headers['authorization'])
          : null;
      response = await _dispatch(
        matched.route.operationId,
        request,
        matched.parameters,
        caller,
      );
    } on _Problem catch (p) {
      response = _problem(p);
    } on FakeValidationException catch (e) {
      response = (
        status: 400,
        body: {
          'type': _type('validation_failed'),
          'title': 'Validation failed',
          'status': 400,
          'code': 'validation_failed',
          'errors': [
            for (final FakeFieldError f in e.errors)
              {'field': f.field, 'message': f.message},
          ],
        },
        headers: const {},
      );
    }
    return (
      status: response.status,
      body: response.body,
      headers: {...response.headers, 'X-Request-Id': requestId},
    );
  }

  _Failure? _takeFailure(String operationId) {
    final List<_Failure>? queue = _failures[operationId];
    if (queue == null || queue.isEmpty) return null;
    return queue.removeAt(0);
  }

  static String _defaultCode(int status) => switch (status) {
    400 => 'validation_failed',
    401 => 'invalid_credentials',
    404 => 'not_found',
    409 => 'conflict',
    429 => 'rate_limited',
    502 => 'plaid_error',
    _ => 'internal',
  };

  static String _type(String code) => 'urn:finance-tracker:problem:$code';

  static const Map<String, String> _titles = {
    'validation_failed': 'Validation failed',
    'invalid_credentials': 'Invalid credentials',
    'email_taken': 'Email already registered',
    'token_expired': 'Token expired',
    'token_revoked': 'Token revoked',
    'not_found': 'Not found',
    'conflict': 'Conflict',
    'item_login_required': 'Item login required',
    'plaid_error': 'Plaid error',
    'rate_limited': 'Too many requests',
    'internal': 'Internal error',
    'sync_cursor_invalid': 'Sync cursor invalid',
    'webhook_unverified': 'Webhook unverified',
  };

  static FakeResponse _problem(_Problem p) {
    if (p.code == 'validation_failed') {
      return (
        status: 400,
        body: {
          'type': _type(p.code),
          'title': _titles[p.code],
          'status': 400,
          'code': p.code,
          'errors': const <Object>[],
        },
        headers: const {},
      );
    }
    return (
      status: p.status,
      body: {
        'type': _type(p.code),
        'title': _titles[p.code] ?? p.code,
        'status': p.status,
        'detail': ?p.detail,
        'code': p.code,
      },
      headers: {
        if (p.status == 401) 'WWW-Authenticate': 'Bearer',
        if (p.status == 429) 'Retry-After': '1',
      },
    );
  }

  _Caller _authenticate(String? authorization) {
    final RegExpMatch? m = RegExp(
      r'^Bearer (\S+)$',
      caseSensitive: false,
    ).firstMatch(authorization ?? '');
    final _Access? access = m == null ? null : _access[m[1]!];
    if (access == null) {
      throw const _Problem(
        401,
        'invalid_credentials',
        'A bearer access token is required',
      );
    }
    if (!access.expiresAt.isAfter(now())) {
      throw const _Problem(401, 'token_expired', 'The access token expired');
    }
    final Device? device = _devices[access.deviceId];
    final _User? user = _userById(access.userId);
    if (device == null ||
        user == null ||
        device.userId != user.id ||
        !_deviceLive(device.id)) {
      throw const _Problem(
        401,
        'token_revoked',
        'This device has been signed out',
      );
    }
    return (user: user, device: device);
  }

  _User? _userById(String id) {
    for (final _User u in _users.values) {
      if (u.id == id) return u;
    }
    return null;
  }

  static FakeResponse _ok(Object? body, [int status = 200]) =>
      (status: status, body: body, headers: const {});

  static const FakeResponse _noContent = (
    status: 204,
    body: null,
    headers: <String, String>{},
  );

  Future<FakeResponse> _dispatch(
    String operationId,
    FakeRequest request,
    Map<String, String> parameters,
    _Caller? caller,
  ) async {
    Map<String, Object?> body() {
      if (identical(request.body, invalidJson)) {
        throw FakeValidationException.single('', 'the body is not JSON');
      }
      return bodyObject(request.body);
    }

    return switch (operationId) {
      'register' => _register(body()),
      'login' => _login(body()),
      'refreshTokens' => _refresh(body()),
      'logout' => _logout(body(), caller!),
      'getMe' => _ok(caller!.user.toUser().toJson()),
      'deleteMe' => _deleteMe(caller!),
      'listDevices' => _ok([
        for (final Device d in _devices.values)
          if (d.userId == caller!.user.id && _deviceLive(d.id)) d.toJson(),
      ]),
      'deleteDevice' => _deleteDevice(parameters['device_id']!, caller!),
      'createLinkToken' => _linkToken(body(), caller!),
      'exchangePublicToken' => _exchange(body(), caller!),
      'listItems' => _ok([
        for (final _LinkedItem i in _dataOf(caller!.user.id).items.values)
          _itemJson(i),
      ]),
      'deleteItem' => _deleteItem(
        parameters['item_id']!,
        request.query,
        caller!,
      ),
      'syncItem' => _syncItem(parameters['item_id']!, caller!),
      'refreshItem' => _refreshItem(parameters['item_id']!, caller!),
      'refreshBalances' => _ok([
        for (final Account a in _healthy(
          parameters['item_id']!,
          caller!,
        ).data.accounts)
          a.copyWith(itemId: parameters['item_id']).toJson(),
      ]),
      'sandboxResetLogin' => _resetLogin(parameters['item_id']!, caller!),
      'sandboxFireWebhook' => _fireWebhook(
        parameters['item_id']!,
        body(),
        caller!,
      ),
      'provisionPersona' => _provision(body(), caller!),
      'getProvisionJob' => _provisionJob(parameters['job_id']!, caller!),
      'sandboxCreateTransactions' => _createTransactions(
        parameters['item_id']!,
        body(),
        caller!,
      ),
      'getInstitutionLogo' => _logo(parameters['institution_id']!, caller!),
      'createUpdateLinkToken' => _updateLinkToken(
        parameters['item_id']!,
        body(),
        caller!,
      ),
      'listAccounts' => _ok(_accounts(caller!)),
      'listTransactions' => _transactions(request.query, caller!),
      'getLiabilities' => _ok(_liabilities(caller!).toJson()),
      'listHoldings' => _ok(_holdings(caller!).toJson()),
      'listInvestmentTransactions' => _investmentTransactions(
        request.query,
        caller!,
      ),
      'listRecurringStreams' => _ok([
        for (final _LinkedItem i in _applied(caller!))
          for (final RecurringStream s in i.data.recurringStreams) s.toJson(),
      ]),
      'pushChanges' => await _push(body(), caller!),
      'pullChanges' => await _pull(request.query, caller!),
      'receivePlaidWebhook' => _webhook(body()),
      'getHealth' => _ok({'status': 'ok', 'version': contractVersion}),
      _ => throw StateError('no handler for $operationId'),
    };
  }

  // --- auth -----------------------------------------------------------------------------

  FakeResponse _register(Map<String, Object?> json) {
    final FakeReader r = FakeReader(json, const {
      'email',
      'password',
      'device_name',
      'display_name',
    });
    final String? email = r.string('email', email: true);
    final String? password = r.string('password', minLength: 8, maxLength: 128);
    final String? deviceName = r.string(
      'device_name',
      minLength: 1,
      maxLength: 100,
    );
    final String? displayName = r.string(
      'display_name',
      required: false,
      minLength: 1,
      maxLength: 100,
    );
    r.done();
    if (_users.containsKey(email!.toLowerCase())) {
      throw const _Problem(
        409,
        'email_taken',
        'An account with that email exists',
      );
    }
    final _User user = _createUser(email, password!, displayName);
    return _ok(_signIn(user, deviceName!), 201);
  }

  FakeResponse _login(Map<String, Object?> json) {
    final FakeReader r = FakeReader(json, const {
      'email',
      'password',
      'device_name',
    });
    final String? email = r.string('email', email: true);
    final String? password = r.string('password', minLength: 8, maxLength: 128);
    final String? deviceName = r.string(
      'device_name',
      minLength: 1,
      maxLength: 100,
    );
    r.done();
    final _User? user = _users[email!.toLowerCase()];
    if (user == null || !_passwordMatches(user, password!)) {
      throw const _Problem(
        401,
        'invalid_credentials',
        'The email or password is wrong',
      );
    }
    return _ok(_signIn(user, deviceName!));
  }

  String _refreshToken(Map<String, Object?> json) {
    final FakeReader r = FakeReader(json, const {'refresh_token'});
    final String? token = r.string('refresh_token', minLength: 1);
    r.done();
    return token!;
  }

  FakeResponse _refresh(Map<String, Object?> json) {
    final _Refresh? row = _refreshByHash[_sha256(_refreshToken(json))];
    if (row == null) {
      throw const _Problem(
        401,
        'token_revoked',
        'The refresh token is not valid; sign in again',
      );
    }
    if (row.revokedAt != null) {
      // Reuse: the whole family goes.
      _revokeFamily(row.familyId);
      throw const _Problem(
        401,
        'token_revoked',
        'The refresh token is not valid; sign in again',
      );
    }
    if (!row.expiresAt.isAfter(now())) {
      throw const _Problem(
        401,
        'token_expired',
        'The refresh token has expired; sign in again',
      );
    }
    row.revokedAt = now();
    final Device device = _devices[row.deviceId]!;
    return _ok(_tokens(device.userId, device, row.familyId));
  }

  FakeResponse _logout(Map<String, Object?> json, _Caller caller) {
    final _Refresh? row = _refreshByHash[_sha256(_refreshToken(json))];
    if (row == null || row.deviceId != caller.device.id) {
      throw const _Problem(
        401,
        'token_revoked',
        'That refresh token does not belong to this device',
      );
    }
    _revokeFamily(row.familyId);
    _devices.remove(caller.device.id);
    return _noContent;
  }

  FakeResponse _deleteMe(_Caller caller) {
    final String userId = caller.user.id;
    for (final Device d in [..._devices.values]) {
      if (d.userId == userId) _removeDevice(d.id);
    }
    _users.remove(caller.user.email);
    _data.remove(userId);
    return _noContent;
  }

  FakeResponse _deleteDevice(String deviceId, _Caller caller) {
    final Device? device = _devices[deviceId];
    if (device == null || device.userId != caller.user.id) {
      throw const _Problem(404, 'not_found', 'No device with that id');
    }
    _removeDevice(deviceId);
    return _noContent;
  }

  // --- plaid ----------------------------------------------------------------------------

  FakeResponse _linkToken(Map<String, Object?> json, _Caller caller) {
    final FakeReader r = FakeReader(json, const {
      'android_package_name',
      'update_item_id',
    });
    r.string('android_package_name', pattern: packageNameShape);
    final String? update = r.string(
      'update_item_id',
      required: false,
      minLength: 1,
    );
    r.done();
    if (update != null) _updatable(update, caller);
    return _ok(_newLinkToken());
  }

  FakeResponse _updateLinkToken(
    String itemId,
    Map<String, Object?> json,
    _Caller caller,
  ) {
    final FakeReader r = FakeReader(json, const {'android_package_name'});
    r.string('android_package_name', pattern: packageNameShape);
    r.done();
    _updatable(itemId, caller);
    return _ok(_newLinkToken());
  }

  /// [_item] for an update-mode link token, which it records: a `removed` Item is 404,
  /// as on the server.
  _LinkedItem _updatable(String itemId, _Caller caller) {
    final _LinkedItem linked = _item(itemId, caller);
    if (linked.status == ItemStatus.removed) {
      throw const _Problem(404, 'not_found', 'The Item was unlinked');
    }
    return linked..updateTokenIssued = true;
  }

  Map<String, Object?> _newLinkToken() => {
    'link_token': _secret('link-fake'),
    'expiration': const UtcInstantConverter().toJson(
      now().add(const Duration(hours: 4)),
    ),
  };

  _LinkedItem _item(String itemId, _Caller caller) =>
      _dataOf(caller.user.id).items[itemId] ??
      (throw const _Problem(404, 'not_found', 'No Item with that id'));

  /// [_item] for a call that would reach Plaid: a `removed` Item is 409 `conflict`.
  _LinkedItem _active(String itemId, _Caller caller) {
    final _LinkedItem linked = _item(itemId, caller);
    if (linked.status == ItemStatus.removed) {
      throw const _Problem(
        409,
        'conflict',
        'The Item was unlinked; link it again to use it',
      );
    }
    return linked;
  }

  /// [_active] for a call that reads or writes the Item's data at Plaid: one that needs
  /// re-authentication is 409 `item_login_required`.
  _LinkedItem _healthy(String itemId, _Caller caller) {
    final _LinkedItem linked = _active(itemId, caller);
    if (linked.status == ItemStatus.loginRequired) {
      throw const _Problem(
        409,
        'item_login_required',
        'The Item needs re-authentication through Link in update mode',
      );
    }
    return linked;
  }

  FakeResponse _exchange(Map<String, Object?> json, _Caller caller) {
    final FakeReader r = FakeReader(json, const {'public_token'});
    final String? token = r.string('public_token', minLength: 1);
    r.done();
    if (token!.startsWith('public-demo-update-')) {
      return _repair(token.substring('public-demo-update-'.length), caller);
    }
    if (dataset.items.isEmpty) {
      throw const _Problem(502, 'plaid_error', 'The fake has no Items to link');
    }
    final FakeItemData data =
        (token.startsWith('public-demo-')
            ? dataset.item(token.substring('public-demo-'.length))
            : null) ??
        dataset.items.first;
    final _UserData user = _dataOf(caller.user.id);
    if (user.items[data.id]?.status == ItemStatus.removed) {
      // Linking an unlinked Item again starts it afresh; its kept rows are re-applied.
      user.items.remove(data.id);
    }
    final _LinkedItem linked = user.items[data.id] ??= _LinkedItem(data);
    return _ok(_itemJson(linked), 201);
  }

  /// The end of update-mode Link for [itemId]: repaired when an update-mode token was
  /// created for it since its login was reset; returned either way.
  FakeResponse _repair(String itemId, _Caller caller) {
    final _LinkedItem? linked = _dataOf(caller.user.id).items[itemId];
    if (linked == null || linked.status == ItemStatus.removed) {
      throw const _Problem(502, 'plaid_error', 'No Item to update');
    }
    if (linked.status == ItemStatus.loginRequired && linked.updateTokenIssued) {
      linked
        ..status = ItemStatus.healthy
        ..errorCode = null
        ..updateTokenIssued = false;
    }
    return _ok(_itemJson(linked), 201);
  }

  // --- sandbox --------------------------------------------------------------------------

  FakeResponse _resetLogin(String itemId, _Caller caller) {
    _active(itemId, caller)
      ..status = ItemStatus.loginRequired
      ..errorCode = 'ITEM_LOGIN_REQUIRED'
      ..updateTokenIssued = false;
    return _noContent;
  }

  static const Set<String> _webhookCodes = {
    'SYNC_UPDATES_AVAILABLE',
    'DEFAULT_UPDATE',
    'RECURRING_TRANSACTIONS_UPDATE',
    'NEW_ACCOUNTS_AVAILABLE',
    'PENDING_DISCONNECT',
    'USER_PERMISSION_REVOKED',
    'LOGIN_REPAIRED',
    'ERROR',
  };

  FakeResponse _fireWebhook(
    String itemId,
    Map<String, Object?> json,
    _Caller caller,
  ) {
    final FakeReader r = FakeReader(json, const {'webhook_code'});
    r.oneOf('webhook_code', _webhookCodes);
    r.done();
    _active(itemId, caller);
    return _noContent;
  }

  /// "Today" for Plaid's Sandbox: the date at UTC−12, as on the server.
  LocalDate get _plaidToday =>
      LocalDate.fromDateTime(now().subtract(const Duration(hours: 12)));

  FakeResponse _createTransactions(
    String itemId,
    Map<String, Object?> json,
    _Caller caller,
  ) {
    final FakeReader r = FakeReader(json, const {'transactions'});
    final List<Object?>? raw = r.list('transactions');
    final _LinkedItem linked = _item(itemId, caller);
    final Map<String, String> currencies = {
      for (final Account a in linked.data.accounts) a.id: a.currencyCode,
    };
    // Without an account id, Plaid picks the checking account.
    final String? fallback =
        (linked.data.accounts
                    .where((Account a) => a.subtype == 'checking')
                    .firstOrNull ??
                linked.data.accounts.firstOrNull)
            ?.id;
    final LocalDate today = _plaidToday;
    final List<Transaction> created = [];
    if (raw != null && (raw.isEmpty || raw.length > 10)) {
      r.errors.add((
        field: 'transactions',
        message: 'must hold 1 to 10 transactions',
      ));
    } else if (raw != null) {
      for (final (int i, Object? element) in raw.indexed) {
        if (element is! Map<String, Object?>) {
          r.errors.add((
            field: 'transactions[$i]',
            message: 'must be an object',
          ));
          continue;
        }
        final FakeReader t = FakeReader(
          element,
          const {
            'date_transacted',
            'date_posted',
            'amount',
            'description',
            'account_id',
          },
          prefix: 'transactions[$i]',
          errors: r.errors,
        );
        final LocalDate? transacted = t.date('date_transacted');
        final LocalDate? posted = t.date('date_posted');
        final Money? amount = t.money('amount');
        final String? description = t.string(
          'description',
          minLength: 1,
          maxLength: 200,
        );
        final String? accountId = t.string(
          'account_id',
          required: false,
          minLength: 1,
        );
        for (final (String key, LocalDate? date) in [
          ('date_transacted', transacted),
          ('date_posted', posted),
        ]) {
          if (date != null &&
              (date.isAfter(today) || date.isBefore(today.addDays(-730)))) {
            r.errors.add((
              field: 'transactions[$i].$key',
              message: 'must be today or up to 730 days back',
            ));
          }
        }
        if (accountId != null && !currencies.containsKey(accountId)) {
          r.errors.add((
            field: 'transactions[$i].account_id',
            message: 'is not an account of this Item',
          ));
          continue;
        }
        final String? currency = currencies[accountId ?? fallback];
        if (amount != null &&
            currency != null &&
            amount.currencyCode != currency) {
          r.errors.add((
            field: 'transactions[$i].amount',
            message: "currency must be the account's",
          ));
          continue;
        }
        if (transacted == null ||
            posted == null ||
            amount == null ||
            description == null ||
            fallback == null) {
          continue;
        }
        final DateTime at = now();
        created.add(
          Transaction(
            id: '$itemId-sandbox-${linked.created + created.length + 1}',
            accountId: accountId ?? fallback,
            // Plaid's sign on the wire (positive is money out), ours in the store.
            amount: -amount,
            date: posted,
            authorizedDate: transacted,
            pending: false,
            name: description,
            source: DataSource.demo,
            createdAt: at,
            updatedAt: at,
            syncVersion: 0,
          ),
        );
      }
    }
    r.done();
    _healthy(itemId, caller);
    final _UserData data = _dataOf(caller.user.id);
    for (final Transaction t in created) {
      data.transactions[t.id] = t.copyWith(syncVersion: ++data.version);
    }
    linked.created += created.length;
    return _noContent;
  }

  // --- provisioning ---------------------------------------------------------------------

  FakeResponse _provision(Map<String, Object?> json, _Caller caller) {
    final FakeReader r = FakeReader(json, const {'persona', 'seed', 'days'});
    final String? persona = r.oneOf('persona', {
      for (final PersonaId p in PersonaId.values) p.slug,
    });
    final int? seed = r.integer(
      'seed',
      required: false,
      fallback: 1,
      min: 1,
      max: 0x7FFFFFFF,
    );
    final int? days = r.integer(
      'days',
      required: false,
      fallback: 730,
      min: 30,
      max: 730,
    );
    r.done();
    if (_jobs.values.any(
      (j) => j.userId == caller.user.id && j.status == 'queued',
    )) {
      throw const _Problem(
        409,
        'conflict',
        'A provisioning job of this user is already running',
      );
    }
    final _FakeJob job = _FakeJob(
      id: _id('job'),
      userId: caller.user.id,
      persona: PersonaId.fromSlug(persona!),
      seed: seed!,
      days: days!,
      createdAt: now(),
    );
    _jobs[job.id] = job;
    return _ok(job.toJson(), 202);
  }

  /// The job [jobId]; a queued one completes once the clock has moved past its creation,
  /// linking the persona's demo Items for the user and applying them.
  FakeResponse _provisionJob(String jobId, _Caller caller) {
    final _FakeJob? job = _jobs[jobId];
    if (job == null || job.userId != caller.user.id) {
      throw const _Problem(
        404,
        'not_found',
        'No provisioning job with that id',
      );
    }
    if (job.status == 'queued' && now().isAfter(job.createdAt)) {
      final FakeDataset persona = FakeDataset.fromDemoSeed(
        generateDemoSeed(
          job.persona,
          job.seed,
          _localDate(now()),
          days: job.days,
        ),
      );
      final _UserData data = _dataOf(caller.user.id);
      for (final FakeItemData item in persona.items) {
        if (data.items[item.id]?.status == ItemStatus.removed) {
          data.items.remove(item.id);
        }
        final _LinkedItem linked = data.items[item.id] ??= _LinkedItem(item);
        linked.syncCalls = 1;
        if (!linked.applied) _apply(data, linked);
        job.itemIds.add(item.id);
      }
      job
        ..status = 'completed'
        ..finishedAt = now();
    }
    return _ok(job.toJson());
  }

  Map<String, Object?> _itemJson(_LinkedItem i) => {
    ...Item(
      id: i.data.id,
      institutionId: i.data.institution.id,
      status: i.status,
      lastSuccessfulSyncAt: i.lastSuccessfulSyncAt,
      errorCode: i.errorCode,
    ).toJson(),
    'institution': i.data.institution
        .copyWith(
          logoUrl: i.data.institutionLogo == null
              ? null
              : baseUrl.resolve(
                  '/v1/institutions/'
                  '${Uri.encodeComponent(i.data.institution.id)}/logo',
                ),
        )
        .toJson(),
  };

  FakeResponse _logo(String institutionId, _Caller caller) {
    for (final _LinkedItem i in _dataOf(
      caller.user.id,
    ).items.values.toList().reversed) {
      final Uint8List? logo = i.data.institutionLogo;
      if (i.data.institution.id == institutionId && logo != null) {
        return _ok(logo);
      }
    }
    throw const _Problem(404, 'not_found', 'No logo for that institution');
  }

  FakeResponse _deleteItem(
    String itemId,
    Map<String, String> query,
    _Caller caller,
  ) {
    final String history = query['history'] ?? 'delete';
    if (history != 'keep' && history != 'delete') {
      throw FakeValidationException.single('history', 'must be keep or delete');
    }
    final _UserData data = _dataOf(caller.user.id);
    final _LinkedItem linked = _item(itemId, caller);
    if (history == 'keep') {
      linked
        ..status = ItemStatus.removed
        ..errorCode = null;
      return _noContent;
    }
    final Set<String> accounts = {
      for (final Account a in linked.data.accounts) a.id,
    };
    final DateTime at = now();
    data.transactions.updateAll(
      (id, t) => accounts.contains(t.accountId) && t.deletedAt == null
          ? t.copyWith(
              deletedAt: at,
              updatedAt: at,
              syncVersion: ++data.version,
            )
          : t,
    );
    data.investmentTransactions.updateAll(
      (id, t) => accounts.contains(t.accountId) && t.deletedAt == null
          ? t.copyWith(deletedAt: at, syncVersion: ++data.version)
          : t,
    );
    data.items.remove(itemId);
    return _noContent;
  }

  FakeResponse _syncItem(String itemId, _Caller caller) {
    final _UserData data = _dataOf(caller.user.id);
    final _LinkedItem linked = _healthy(itemId, caller);
    if (linked.syncCalls++ == 0) {
      return _ok(_run('not_ready', 0, false), 202);
    }
    if (linked.applied && linked.refreshPending) {
      linked.refreshPending = false;
      final int modified = _apply(data, linked);
      return _ok(_run('completed', 0, true, modified: modified), 202);
    }
    final int added = linked.applied ? 0 : _apply(data, linked);
    return _ok(_run('completed', added, true), 202);
  }

  FakeResponse _refreshItem(String itemId, _Caller caller) {
    _healthy(itemId, caller).refreshPending = true;
    return _ok(_run('started', 0, false), 202);
  }

  static Map<String, Object?> _run(
    String status,
    int added,
    bool saved, {
    int modified = 0,
  }) => {
    'status': status,
    'added': added,
    'modified': modified,
    'removed': 0,
    'next_cursor_saved': saved,
  };

  /// Applies [linked]'s rows under the user's next versions; returns how many
  /// transactions were added.
  int _apply(_UserData data, _LinkedItem linked) {
    for (final Transaction t in linked.data.transactions) {
      data.transactions[t.id] = t.copyWith(syncVersion: ++data.version);
    }
    for (final InvestmentTransaction t in linked.data.investmentTransactions) {
      data.investmentTransactions[t.id] = t.copyWith(
        syncVersion: ++data.version,
      );
    }
    linked
      ..applied = true
      ..lastSuccessfulSyncAt = now();
    return linked.data.transactions.length;
  }

  Iterable<_LinkedItem> _applied(_Caller caller) =>
      _dataOf(caller.user.id).items.values.where((i) => i.applied);

  // --- data -----------------------------------------------------------------------------

  List<Object?> _accounts(_Caller caller) {
    final List<Account> accounts = [
      for (final _LinkedItem i in _applied(caller))
        for (final Account a in i.data.accounts) a.copyWith(itemId: i.data.id),
    ]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return [for (final Account a in accounts) a.toJson()];
  }

  Liabilities _liabilities(_Caller caller) {
    final Iterable<Liabilities> all = _applied(caller)
        .map((i) => i.data.liabilities);
    return Liabilities(
      credit: [for (final Liabilities l in all) ...l.credit],
      mortgage: [for (final Liabilities l in all) ...l.mortgage],
      student: [for (final Liabilities l in all) ...l.student],
    );
  }

  Holdings _holdings(_Caller caller) {
    final Map<String, Security> securities = {};
    final List<Holding> holdings = [];
    for (final _LinkedItem i in _applied(caller)) {
      holdings.addAll(i.data.holdings);
      for (final Security s in i.data.securities) {
        securities[s.id] = s;
      }
    }
    return Holdings(holdings: holdings, securities: [...securities.values]);
  }

  /// One version page of [rows] (by `sync_version`) for [query].
  ({List<T> rows, int nextSince, bool hasMore}) _page<T>(
    Map<String, String> query,
    _UserData data,
    Iterable<T> rows,
    int Function(T) version,
  ) {
    final int since = queryInt(query, 'since', fallback: 0, min: 0);
    final int limit = queryInt(query, 'limit', fallback: 500, min: 1, max: 500);
    if (since > data.version) {
      throw const _Problem(
        409,
        'sync_cursor_invalid',
        'since is beyond the current version',
      );
    }
    final List<T> after = [
      for (final T row in rows)
        if (version(row) > since) row,
    ]..sort((a, b) => version(a).compareTo(version(b)));
    final List<T> page = after.take(limit).toList();
    return (
      rows: page,
      nextSince: page.isEmpty ? since : version(page.last),
      hasMore: after.length > limit,
    );
  }

  FakeResponse _transactions(Map<String, String> query, _Caller caller) {
    final _UserData data = _dataOf(caller.user.id);
    final page = _page(
      query,
      data,
      data.transactions.values,
      (Transaction t) => t.syncVersion,
    );
    return _ok({
      'transactions': [for (final Transaction t in page.rows) t.toJson()],
      'next_since': page.nextSince,
      'has_more': page.hasMore,
    });
  }

  FakeResponse _investmentTransactions(
    Map<String, String> query,
    _Caller caller,
  ) {
    final _UserData data = _dataOf(caller.user.id);
    final page = _page(
      query,
      data,
      data.investmentTransactions.values,
      (InvestmentTransaction t) => t.syncVersion,
    );
    return _ok({
      'investment_transactions': [
        for (final InvestmentTransaction t in page.rows) t.toJson(),
      ],
      'next_since': page.nextSince,
      'has_more': page.hasMore,
    });
  }

  // --- sync -----------------------------------------------------------------------------

  static final Set<String> _entityTypes = {
    for (final EntityType t in EntityType.values) _snake(t.name),
  };
  static final Set<String> _operations = {
    for (final ChangeOperation o in ChangeOperation.values) o.name,
  };

  static String _snake(String camel) =>
      camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  Future<FakeResponse> _push(Map<String, Object?> json, _Caller caller) async {
    final FakeReader r = FakeReader(json, const {'entries'});
    final List<Object?>? raw = r.list('entries');
    final List<ChangeLogEntry> entries = [];
    for (int i = 0; i < (raw?.length ?? 0); i++) {
      final Object? item = raw![i];
      if (item is! Map<String, Object?>) {
        r.errors.add((field: 'entries[$i]', message: 'must be an object'));
        continue;
      }
      final FakeReader e = FakeReader(
        item,
        const {
          'entity_type',
          'entity_id',
          'operation',
          'payload',
          'hlc',
          'device_id',
        },
        prefix: 'entries[$i]',
        errors: r.errors,
      );
      final int before = r.errors.length;
      e
        ..oneOf('entity_type', _entityTypes)
        ..string('entity_id')
        ..oneOf('operation', _operations)
        ..object('payload')
        ..string('hlc', pattern: hlcShape)
        ..string('device_id');
      if (r.errors.length == before) {
        entries.add(ChangeLogEntry.fromJson({...item, 'synced': false}));
      }
    }
    r.done();

    final List<Hlc> accepted = [];
    final List<PushRejection> rejected = [];
    final List<ChangeLogEntry> toRelay = [];
    for (final ChangeLogEntry e in entries) {
      if (e.deviceId != caller.device.id) {
        rejected.add(
          PushRejection(
            e.hlc,
            PushRejectionReason.invalid,
            'device_id is not the calling device',
          ),
        );
      } else if (e.payload['source'] == 'plaid') {
        rejected.add(
          PushRejection(
            e.hlc,
            PushRejectionReason.invalid,
            'Plaid data never syncs through the change log',
          ),
        );
      } else {
        toRelay.add(e);
      }
    }
    final PushResult result = await _dataOf(caller.user.id).relay.push(toRelay);
    accepted.addAll(result.accepted);
    rejected.addAll(result.rejected);
    _touchSync(caller.device);
    return _ok({
      'accepted': [for (final Hlc h in accepted) h.pack()],
      'rejected': [
        for (final PushRejection p in rejected)
          {
            'hlc': p.hlc.pack(),
            'code': _snake(p.reason.name),
            'reason': p.message,
          },
      ],
    });
  }

  Future<FakeResponse> _pull(Map<String, String> query, _Caller caller) async {
    final int since = queryInt(query, 'since', fallback: 0, min: 0);
    final int limit = queryInt(query, 'limit', fallback: 500, min: 1, max: 500);
    final InMemorySyncRelay relay = _dataOf(caller.user.id).relay;
    final PullPage page;
    try {
      page = await relay.pull(
        since: since,
        limit: limit,
        deviceId: caller.device.id,
      );
    } on SyncCursorInvalidException {
      throw const _Problem(
        409,
        'sync_cursor_invalid',
        "since is beyond the server's last seq",
      );
    }
    final List<ChangeLogEntry> log = relay.entries;
    final Map<String, int> seqOf = {
      for (int i = 0; i < log.length; i++)
        '${log[i].deviceId}|${log[i].hlc.pack()}': i + 1,
    };
    _touchSync(caller.device);
    return _ok({
      'entries': [
        for (final ChangeLogEntry e in page.entries)
          {
            ...e.toJson()..remove('synced'),
            'seq': seqOf['${e.deviceId}|${e.hlc.pack()}'],
          },
      ],
      'next_since': page.nextSince,
      'has_more': page.hasMore,
    });
  }

  void _touchSync(Device device) =>
      _devices[device.id] = device.copyWith(lastSyncAt: now());

  FakeResponse _webhook(Map<String, Object?> json) => throw const _Problem(
    401,
    'webhook_unverified',
    'Webhook deliveries are not verified until Phase 3',
  );
}

typedef _Caller = ({_User user, Device device});

final class _Problem implements Exception {
  const _Problem(this.status, this.code, this.detail);

  final int status;
  final String code;
  final String? detail;
}
