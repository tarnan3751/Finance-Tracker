/// `FinanceApi` over the generated client (`packages/api_client`), on a Dio from
/// `buildDio` with the `AuthInterceptor` installed.
///
/// **The boundary goes through the wire JSON.** A generated model is serialized back to
/// the contract's JSON and read with the `shared_models` entity's (or `api_models`')
/// `fromJson`; a request is the entity's JSON deserialized into the generated model. The
/// contract's JSON is exactly `shared_models`' (`models_conform_test.dart` in
/// `contract_test` holds them equal), so the generated `source_` comes back as `source`,
/// `minor_units` stays an `int`, `Decimal` values stay strings, the generated `Date`
/// becomes a `LocalDate` and instants stay UTC milliseconds. Payloads are deep-copied to
/// plain JSON, so an `int` stays an `int`.
///
/// Every failure is an `ApiException`; a 2xx body this build cannot read is a
/// `ServerError`. The refresh call the interceptor makes goes
/// through a second Dio with the same options and adapter but no auth interceptor.
library;

import 'dart:async';
import 'dart:convert';

import 'package:api_client/api_client.dart' as api;
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/auth_interceptor.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

final Logger _log = Logger('api');

/// The HTTP implementation of [FinanceApi].
final class HttpFinanceApi implements FinanceApi {
  /// The API over [dio] (from `buildDio`), with the session in [tokens].
  HttpFinanceApi(Dio dio, {required TokenStore tokens, required Clock clock})
    : _dio = dio {
    final Dio refreshDio = Dio(dio.options.copyWith())
      ..httpClientAdapter = dio.httpClientAdapter
      ..interceptors.addAll(dio.interceptors);
    final api.AuthApi refreshAuth = api.ApiClient(
      dio: refreshDio,
      interceptors: const [],
    ).getAuthApi();
    final AuthInterceptor auth = AuthInterceptor(
      store: tokens,
      clock: clock,
      onSessionEnded: () => _sessionEnded.add(null),
      refresh: (refreshToken) async => _authResult(
        (await refreshAuth.refreshTokens(
          refreshRequest: _request<api.RefreshRequest>({
            'refresh_token': refreshToken,
          }),
          extra: {pathTemplateKey: '/auth/refresh'},
        )).data,
      ),
    );
    // Before the dev log, so the log sees the final outcome of a refreshed request.
    final int log = dio.interceptors.indexWhere((i) => i is DevLogInterceptor);
    dio.interceptors.insert(
      log < 0 ? dio.interceptors.length : log,
      auth..retryWith = dio,
    );
    _client = api.ApiClient(dio: dio, interceptors: const []);
  }

  final Dio _dio;
  late final api.ApiClient _client;
  final StreamController<void> _sessionEnded =
      StreamController<void>.broadcast();

  /// Closes the Dio and the [sessionEnded] stream.
  Future<void> close() async {
    _dio.close(force: true);
    await _sessionEnded.close();
  }

  @override
  Stream<void> get sessionEnded => _sessionEnded.stream;

  // --- the boundary ---------------------------------------------------------------------

  static final Serializers _serializers = api.standardSerializers;

  /// [generated] as the contract's JSON, plain (maps, lists, strings, ints, bools).
  static Map<String, dynamic> _json<T>(T generated) => jsonDecode(
    jsonEncode(_serializers.serialize(generated, specifiedType: FullType(T))),
  ) as Map<String, dynamic>;

  /// The generated request model of type [T] holding [json].
  static T _request<T>(Map<String, dynamic> json) =>
      _serializers.deserialize(json, specifiedType: FullType(T)) as T;

  static T _data<T>(T? data) => data ?? (throw const ServerError(status: 200));

  static AuthResult _authResult(api.AuthTokens? data) {
    final Map<String, dynamic> json = _json(_data(data));
    return AuthResult(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessExpiresIn: Duration(seconds: json['access_expires_in'] as int),
      device: Device.fromJson(json['device'] as Map<String, dynamic>),
    );
  }

  static LinkToken _linkToken(api.LinkToken? data) {
    final Map<String, dynamic> json = _json(_data(data));
    return LinkToken(
      linkToken: json['link_token'] as String,
      expiration: const UtcInstantConverter().fromJson(
        json['expiration'] as String,
      ),
    );
  }

  static LinkedItem _linkedItem(api.Item generated) {
    final Map<String, dynamic> json = _json(generated);
    return (
      item: Item.fromJson(json),
      institution: Institution.fromJson(
        json['institution'] as Map<String, dynamic>,
      ),
    );
  }

  static const Map<String, PushRejectionReason> _rejectionReasons = {
    'clock_drift': PushRejectionReason.clockDrift,
    'invalid': PushRejectionReason.invalid,
    'conflicting_duplicate': PushRejectionReason.conflictingDuplicate,
  };

  static const Map<String, SyncRunStatus> _runStatuses = {
    'started': SyncRunStatus.started,
    'not_ready': SyncRunStatus.notReady,
    'completed': SyncRunStatus.completed,
  };

  /// Runs [call] with the log's path template. A [DioException] is mapped; any other
  /// failure is a 2xx body this build cannot read (a value the entity refuses, a code it
  /// does not know), which is a [ServerError]: only the type is logged.
  static Future<T> _call<T>(
    String path,
    Future<T> Function(Map<String, dynamic> extra) call,
  ) async {
    try {
      return await call({pathTemplateKey: path});
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } on Object catch (e) {
      _log.warning('$path: an answer could not be read: ${e.runtimeType}');
      throw const ServerError();
    }
  }

  /// [value]'s entry in [values]; an unknown one is a [ServerError], never a guess.
  static V _known<V>(Map<String, V> values, Object? value) =>
      values[value] ?? (throw const ServerError());

  // --- auth -----------------------------------------------------------------------------

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String deviceName,
    String? displayName,
  }) => _call(
    '/auth/register',
    (extra) async => _authResult(
      (await _client.getAuthApi().register(
        registerRequest: _request<api.RegisterRequest>({
          'email': email,
          'password': password,
          'device_name': deviceName,
          'display_name': ?displayName,
        }),
        extra: extra,
      )).data,
    ),
  );

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    required String deviceName,
  }) => _call(
    '/auth/login',
    (extra) async => _authResult(
      (await _client.getAuthApi().login(
        loginRequest: _request<api.LoginRequest>({
          'email': email,
          'password': password,
          'device_name': deviceName,
        }),
        extra: extra,
      )).data,
    ),
  );

  @override
  Future<AuthResult> refreshTokens(String refreshToken) => _call(
    '/auth/refresh',
    (extra) async => _authResult(
      (await _client.getAuthApi().refreshTokens(
        refreshRequest: _request<api.RefreshRequest>({
          'refresh_token': refreshToken,
        }),
        extra: extra,
      )).data,
    ),
  );

  @override
  Future<void> logout(String refreshToken, {String? accessToken}) => _call(
    '/auth/logout',
    (extra) => _client.getAuthApi().logout(
      refreshRequest: _request<api.RefreshRequest>({
        'refresh_token': refreshToken,
      }),
      extra: {...extra, noRefreshKey: true, accessTokenKey: ?accessToken},
    ),
  );

  // --- me and devices -------------------------------------------------------------------

  @override
  Future<User> getMe({String? accessToken}) => _call(
    '/me',
    (extra) async => User.fromJson(
      _json(
        _data(
          (await _client.getMeApi().getMe(
            extra: {...extra, accessTokenKey: ?accessToken},
          )).data,
        ),
      ),
    ),
  );

  @override
  Future<void> deleteMe() =>
      _call('/me', (extra) => _client.getMeApi().deleteMe(extra: extra));

  @override
  Future<List<Device>> listDevices() => _call(
    '/devices',
    (extra) async => [
      for (final api.Device d in _data(
        (await _client.getDevicesApi().listDevices(extra: extra)).data,
      ))
        Device.fromJson(_json(d)),
    ],
  );

  @override
  Future<void> deleteDevice(String deviceId) => _call(
    '/devices/{device_id}',
    (extra) =>
        _client.getDevicesApi().deleteDevice(deviceId: deviceId, extra: extra),
  );

  // --- plaid ----------------------------------------------------------------------------

  @override
  Future<LinkToken> createLinkToken({
    required String androidPackageName,
    String? updateItemId,
  }) => _call(
    '/plaid/link-token',
    (extra) async => _linkToken(
      (await _client.getPlaidApi().createLinkToken(
        linkTokenRequest: _request<api.LinkTokenRequest>({
          'android_package_name': androidPackageName,
          'update_item_id': ?updateItemId,
        }),
        extra: extra,
      )).data,
    ),
  );

  @override
  Future<LinkedItem> exchangePublicToken(String publicToken) => _call(
    '/plaid/exchange',
    (extra) async => _linkedItem(
      _data(
        (await _client.getPlaidApi().exchangePublicToken(
          exchangeRequest: _request<api.ExchangeRequest>({
            'public_token': publicToken,
          }),
          extra: extra,
        )).data,
      ),
    ),
  );

  @override
  Future<List<LinkedItem>> listItems() => _call(
    '/plaid/items',
    (extra) async => [
      for (final api.Item item in _data(
        (await _client.getPlaidApi().listItems(extra: extra)).data,
      ))
        _linkedItem(item),
    ],
  );

  @override
  Future<void> deleteItem(String itemId) => _call(
    '/plaid/items/{item_id}',
    (extra) => _client.getPlaidApi().deleteItem(itemId: itemId, extra: extra),
  );

  @override
  Future<SyncRun> syncItem(String itemId) =>
      _call('/plaid/items/{item_id}/sync', (extra) async {
        final Map<String, dynamic> json = _json(
          _data(
            (await _client.getPlaidApi().syncItem(
              itemId: itemId,
              extra: extra,
            )).data,
          ),
        );
        return (
          status: _known(_runStatuses, json['status']),
          added: json['added'] as int,
          modified: json['modified'] as int,
          removed: json['removed'] as int,
          nextCursorSaved: json['next_cursor_saved'] as bool,
        );
      });

  @override
  Future<LinkToken> createUpdateLinkToken(
    String itemId, {
    required String androidPackageName,
  }) => _call(
    '/plaid/items/{item_id}/update-link-token',
    (extra) async => _linkToken(
      (await _client.getPlaidApi().createUpdateLinkToken(
        itemId: itemId,
        updateLinkTokenRequest: _request<api.UpdateLinkTokenRequest>({
          'android_package_name': androidPackageName,
        }),
        extra: extra,
      )).data,
    ),
  );

  // --- data -----------------------------------------------------------------------------

  @override
  Future<List<Account>> listAccounts() => _call(
    '/accounts',
    (extra) async => [
      for (final api.Account a in _data(
        (await _client.getDataApi().listAccounts(extra: extra)).data,
      ))
        Account.fromJson(_json(a)),
    ],
  );

  @override
  Future<VersionPage<Transaction>> listTransactions({
    int since = 0,
    int limit = 500,
  }) => _call('/transactions', (extra) async {
    final Map<String, dynamic> json = _json(
      _data(
        (await _client.getDataApi().listTransactions(
          since: since,
          limit: limit,
          extra: extra,
        )).data,
      ),
    );
    return (
      items: [
        for (final Object? t in json['transactions'] as List<dynamic>)
          Transaction.fromJson(t as Map<String, dynamic>),
      ],
      nextSince: json['next_since'] as int,
      hasMore: json['has_more'] as bool,
    );
  });

  @override
  Future<Liabilities> getLiabilities() => _call(
    '/liabilities',
    (extra) async => Liabilities.fromJson(
      _json(
        _data((await _client.getDataApi().getLiabilities(extra: extra)).data),
      ),
    ),
  );

  @override
  Future<Holdings> listHoldings() => _call(
    '/investments/holdings',
    (extra) async => Holdings.fromJson(
      _json(
        _data((await _client.getDataApi().listHoldings(extra: extra)).data),
      ),
    ),
  );

  @override
  Future<VersionPage<InvestmentTransaction>> listInvestmentTransactions({
    int since = 0,
    int limit = 500,
  }) => _call('/investments/transactions', (extra) async {
    final Map<String, dynamic> json = _json(
      _data(
        (await _client.getDataApi().listInvestmentTransactions(
          since: since,
          limit: limit,
          extra: extra,
        )).data,
      ),
    );
    return (
      items: [
        for (final Object? t
            in json['investment_transactions'] as List<dynamic>)
          InvestmentTransaction.fromJson(t as Map<String, dynamic>),
      ],
      nextSince: json['next_since'] as int,
      hasMore: json['has_more'] as bool,
    );
  });

  @override
  Future<List<RecurringStream>> listRecurringStreams() => _call(
    '/recurring',
    (extra) async => [
      for (final api.RecurringStream s in _data(
        (await _client.getDataApi().listRecurringStreams(extra: extra)).data,
      ))
        RecurringStream.fromJson(_json(s)),
    ],
  );

  // --- sync -----------------------------------------------------------------------------

  @override
  Future<PushResult> pushChanges(List<ChangeLogEntry> entries) =>
      _call('/sync/push', (extra) async {
        final Map<String, dynamic> json = _json(
          _data(
            (await _client.getSyncApi().pushChanges(
              pushRequest: _request<api.PushRequest>({
                'entries': [
                  for (final ChangeLogEntry e in entries)
                    e.toJson()..remove('synced'),
                ],
              }),
              extra: extra,
            )).data,
          ),
        );
        return PushResult(
          accepted: [
            for (final Object? hlc in json['accepted'] as List<dynamic>)
              Hlc.parse(hlc as String),
          ],
          rejected: [
            for (final Object? r in json['rejected'] as List<dynamic>)
              PushRejection(
                Hlc.parse((r as Map<String, dynamic>)['hlc'] as String),
                _known(_rejectionReasons, r['code']),
                r['reason'] as String,
              ),
          ],
        );
      });

  @override
  Future<PullPage> pullChanges({required int since, required int limit}) =>
      _call('/sync/pull', (extra) async {
        final Map<String, dynamic> json = _json(
          _data(
            (await _client.getSyncApi().pullChanges(
              since: since,
              limit: limit,
              extra: extra,
            )).data,
          ),
        );
        return PullPage(
          entries: [
            for (final Object? e in json['entries'] as List<dynamic>)
              ChangeLogEntry.fromJson({
                ...(e as Map<String, dynamic>)..remove('seq'),
                'synced': true,
              }),
          ],
          nextSince: json['next_since'] as int,
          hasMore: json['has_more'] as bool,
        );
      });

  // --- health ---------------------------------------------------------------------------

  @override
  Future<Health> getHealth() => _call('/health', (extra) async {
    final Map<String, dynamic> json = _json(
      _data((await _client.getHealthApi().getHealth(extra: extra)).data),
    );
    return (
      status: json['status'] as String,
      version: json['version'] as String,
    );
  });
}
