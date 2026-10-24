// The in-app fake server against the contract (`api/openapi.yaml`): every operation is
// driven through the generated client (and, for bodies the client would never send and
// for the webhook, whose generated method cannot serialize its body, raw Dio), and every
// request and answer that crosses the adapter is checked with contract_test in strict
// mode: the request body against the operation's schema, the answer against the schema
// of its status (which must be declared; an image/png answer is its bytes), the content
// type and the X-Request-Id. A table
// test holds the fake's routes equal to the document's operations, with the same
// security.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:api_client/api_client.dart' as api;
import 'package:built_value/serializer.dart';
import 'package:contract_test/contract_test.dart';
import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'support/fake_api.dart';

final OpenApiDocument _contract = OpenApiDocument.load(
  File('../api/openapi.yaml'),
);

/// One request and its answer, as they crossed the adapter.
typedef _Exchange = ({
  String method,
  String path,
  Object? request,
  int status,
  Object? response,
  String? contentType,
  String? requestId,
});

/// Records every exchange with the fake server's adapter.
final class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._inner);

  final HttpClientAdapter _inner;
  final List<_Exchange> exchanges = [];

  static Future<List<int>> _bytes(Stream<Uint8List>? stream) async => [
    if (stream != null)
      for (final Uint8List chunk in await stream.toList()) ...chunk,
  ];

  static Object? _decode(List<int> bytes, {String? contentType}) =>
      contentType == 'image/png'
      ? bytes
      : bytes.isEmpty
      ? null
      : jsonDecode(utf8.decode(bytes));

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final List<int> request = await _bytes(requestStream);
    final ResponseBody response = await _inner.fetch(
      options,
      request.isEmpty ? null : Stream.value(Uint8List.fromList(request)),
      cancelFuture,
    );
    final List<int> body = await _bytes(response.stream);
    final String? contentType =
        response.headers[Headers.contentTypeHeader]?.single;
    exchanges.add((
      method: options.method,
      path: options.uri.path.replaceFirst('/v1', ''),
      request: _decode(request),
      status: response.statusCode,
      response: _decode(body, contentType: contentType),
      contentType: contentType,
      requestId: response.headers['x-request-id']?.single,
    ));
    return ResponseBody.fromBytes(
      body,
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

final Serializers _serializers = api.standardSerializers;

T _model<T>(Map<String, Object?> json) =>
    _serializers.deserialize(json, specifiedType: FullType(T)) as T;

/// A PNG signature and a few bytes: what the fake serves as a logo.
final Uint8List _logo = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, //
]);

/// The sample dataset, its Item's institution with [_logo].
FakeDataset _sampleWithLogo() => FakeDataset(
  items: [
    for (final FakeItemData i in FakeDataset.sample(
      LocalDate(2026, 10, 24),
    ).items)
      FakeItemData(
        id: i.id,
        institution: i.institution,
        accounts: i.accounts,
        transactions: i.transactions,
        recurringStreams: i.recurringStreams,
        liabilities: i.liabilities,
        holdings: i.holdings,
        securities: i.securities,
        investmentTransactions: i.investmentTransactions,
        institutionLogo: _logo,
      ),
  ],
);

/// The status [call] was answered with.
Future<int> _status(Future<Response<dynamic>> Function() call) async {
  try {
    return (await call()).statusCode!;
  } on DioException catch (e) {
    return e.response?.statusCode ?? -1;
  }
}

/// The generated client for one signed-in user, plus raw Dio, over one fake server.
final class _Harness {
  _Harness({FakeDataset? dataset}) : server = newFakeServer(dataset: dataset) {
    recorder = _RecordingAdapter(server.adapter);
    final String base = apiBaseUrl(FakeServer.baseUrl);
    client = api.ApiClient(
      dio: Dio(BaseOptions(baseUrl: base))..httpClientAdapter = recorder,
    );
    raw = Dio(BaseOptions(baseUrl: base, validateStatus: (_) => true))
      ..httpClientAdapter = recorder;
  }

  final FakeServer server;
  late final _RecordingAdapter recorder;
  late final api.ApiClient client;
  late final Dio raw;

  /// Exchanges sent with a body the contract refuses on purpose (their request is not
  /// checked; their 400 answer is).
  final Set<int> invalidOnPurpose = {};

  String? accessToken;

  Future<Response<dynamic>> rawSend(
    String method,
    String path, {
    Object? body,
    bool invalid = true,
  }) {
    if (invalid) invalidOnPurpose.add(recorder.exchanges.length);
    return raw.request<dynamic>(
      path,
      data: body,
      options: Options(
        method: method,
        headers: {'Authorization': ?_bearer},
        contentType: 'application/json',
      ),
    );
  }

  String? get _bearer => accessToken == null ? null : 'Bearer $accessToken';

  void signInAs(String token) {
    accessToken = token;
    client.setBearerAuth('bearerAuth', token);
  }

  /// Checks every exchange so far against the contract; returns the statuses seen per
  /// operation.
  Map<String, Set<int>> verify() {
    final Map<String, Set<int>> seen = {};
    for (int i = 0; i < recorder.exchanges.length; i++) {
      final _Exchange e = recorder.exchanges[i];
      final match = FakeServer.match(e.method, e.path);
      expect(match, isNotNull, reason: '${e.method} ${e.path}');
      final String template = match!.route.template;
      final String method = e.method.toLowerCase();
      final String what = '${e.method} $template ${e.status}';
      if (e.request != null && !invalidOnPurpose.contains(i)) {
        expect(
          e.request,
          conformsToRequest(_contract, template, method),
          reason: what,
        );
      }
      expect(
        e.response,
        conformsToResponse(_contract, template, method, e.status),
        reason: what,
      );
      expect(e.requestId, isNotEmpty, reason: '$what: X-Request-Id');
      if (e.response != null) {
        expect(
          e.contentType,
          _contract.responseMediaType(template, method, e.status),
          reason: what,
        );
      }
      (seen[match.route.operationId] ??= {}).add(e.status);
    }
    return seen;
  }
}

void main() {
  test(
    'the fake serves exactly the contract operations, with their security',
    () {
      final Set<(String, String, String, bool)> fake = {
        for (final FakeRoute r in FakeServer.routes)
          (r.operationId, r.method.toLowerCase(), r.template, r.authenticated),
      };
      final Set<(String, String, String, bool)> contract = {
        for (final Operation o in _contract.operations)
          (
            o.operation['operationId']! as String,
            o.method,
            o.path,
            switch (o.operation['security']) {
              final List<Object?> security => security.isNotEmpty,
              _ => true,
            },
          ),
      };
      expect(fake, contract);
    },
  );

  test('the client version is the contract version', () {
    expect(
      contractVersion,
      (_contract.root['info']! as Map<String, Object?>)['version'],
    );
  });

  test(
    'every operation, its successes and its documented errors, conform',
    () async {
      final _Harness h = _Harness(dataset: _sampleWithLogo());
      final api.AuthApi auth = h.client.getAuthApi();
      final api.PlaidApi plaid = h.client.getPlaidApi();
      final api.DataApi data = h.client.getDataApi();
      final api.SyncApi sync = h.client.getSyncApi();
      final api.DevicesApi devices = h.client.getDevicesApi();
      final api.MeApi me = h.client.getMeApi();

      // health
      expect(await _status(() => h.client.getHealthApi().getHealth()), 200);
      h.server.failNext('getHealth', 500);
      expect(await _status(() => h.client.getHealthApi().getHealth()), 500);

      // auth: the contract's own examples first.
      final Map<String, Object?> registerExample = {
        'email': 'ada@example.com',
        'password': 'correct horse battery',
        'device_name': 'Pixel 8',
        'display_name': 'Ada',
      };
      final Response<dynamic> registered = await h.rawSend(
        'POST',
        '/auth/register',
        body: registerExample,
        invalid: false,
      );
      expect(registered.statusCode, 201);
      expect(
        await _status(
          () => auth.register(
            registerRequest: _model<api.RegisterRequest>(registerExample),
          ),
        ),
        409,
      );
      expect(
        (await h.rawSend(
          'POST',
          '/auth/register',
          body: {'email': 'x', 'password': 'short', 'device_name': ''},
        )).statusCode,
        400,
      );
      h.server.failNext('register', 429);
      expect(
        await _status(
          () => auth.register(
            registerRequest: _model<api.RegisterRequest>({
              ...registerExample,
              'email': 'bob@example.com',
            }),
          ),
        ),
        429,
      );

      final api.LoginRequest login = _model<api.LoginRequest>({
        'email': 'ada@example.com',
        'password': 'correct horse battery',
        'device_name': 'Pixel 8',
      });
      final Response<api.AuthTokens> first = await auth.login(
        loginRequest: login,
      );
      expect(first.statusCode, 200);
      expect(
        await _status(
          () => auth.login(
            loginRequest: login.rebuild((b) => b..password = 'wrong password'),
          ),
        ),
        401,
      );
      expect(
        (await h.rawSend('POST', '/auth/login', body: {'email': 1})).statusCode,
        400,
      );
      h.server.failNext('login', 429);
      expect(await _status(() => auth.login(loginRequest: login)), 429);

      final api.RefreshRequest firstRefresh = _model<api.RefreshRequest>({
        'refresh_token': first.data!.refreshToken,
      });
      final Response<api.AuthTokens> rotated = await auth.refreshTokens(
        refreshRequest: firstRefresh,
      );
      expect(rotated.statusCode, 200);
      expect(
        await _status(() => auth.refreshTokens(refreshRequest: firstRefresh)),
        401,
      );
      expect(
        (await h.rawSend(
          'POST',
          '/auth/refresh',
          body: <String, Object?>{},
        )).statusCode,
        400,
      );
      h.server.failNext('refreshTokens', 429);
      expect(
        await _status(() => auth.refreshTokens(refreshRequest: firstRefresh)),
        429,
      );

      // A live session: the second login (the first's family was revoked by the reuse).
      expect(await _status(me.getMe), 401);
      final Response<api.AuthTokens> session = await auth.login(
        loginRequest: login,
      );
      h.signInAs(session.data!.accessToken);
      expect(await _status(me.getMe), 200);

      // devices
      final Response<api.AuthTokens> tablet = await auth.login(
        loginRequest: login.rebuild((b) => b..deviceName = 'Tablet'),
      );
      expect(await _status(devices.listDevices), 200);
      expect(await _status(() => devices.deleteDevice(deviceId: 'nope')), 404);
      expect(
        await _status(
          () => devices.deleteDevice(deviceId: tablet.data!.device.id),
        ),
        204,
      );

      // plaid
      final Map<String, Object?> linkExample = {
        'android_package_name': 'dev.tarnan.financetracker',
      };
      expect(
        (await h.rawSend(
          'POST',
          '/plaid/link-token',
          body: linkExample,
          invalid: false,
        )).statusCode,
        200,
      );
      final api.LinkTokenRequest linkRequest = _model<api.LinkTokenRequest>(
        linkExample,
      );
      expect(
        await _status(
          () => plaid.createLinkToken(
            linkTokenRequest: linkRequest.rebuild(
              (b) => b..updateItemId = 'nope',
            ),
          ),
        ),
        404,
      );
      expect(
        (await h.rawSend(
          'POST',
          '/plaid/link-token',
          body: {'android_package_name': 'not a package'},
        )).statusCode,
        400,
      );
      for (final int status in [429, 502]) {
        h.server.failNext('createLinkToken', status);
        expect(
          await _status(
            () => plaid.createLinkToken(linkTokenRequest: linkRequest),
          ),
          status,
        );
      }

      final api.ExchangeRequest exchange = _model<api.ExchangeRequest>({
        'public_token': 'public-demo-sample-item-1',
      });
      expect(
        await _status(
          () => plaid.exchangePublicToken(exchangeRequest: exchange),
        ),
        201,
      );
      expect(
        (await h.rawSend(
          'POST',
          '/plaid/exchange',
          body: {'public_token': ''},
        )).statusCode,
        400,
      );
      for (final int status in [429, 502]) {
        h.server.failNext('exchangePublicToken', status);
        expect(
          await _status(
            () => plaid.exchangePublicToken(exchangeRequest: exchange),
          ),
          status,
        );
      }
      expect(await _status(plaid.listItems), 200);

      // The Item's data before its first sync: empty, and versions start at 0.
      expect(await _status(data.listAccounts), 200);
      expect(await _status(data.listTransactions), 200);

      const String item = 'sample-item-1';
      expect(
        await _status(() => plaid.syncItem(itemId: item)),
        202,
      ); // not_ready
      expect(
        await _status(() => plaid.syncItem(itemId: item)),
        202,
      ); // completed
      expect(await _status(() => plaid.syncItem(itemId: 'nope')), 404);
      for (final (int status, String? code) in [
        (409, 'item_login_required'),
        (429, null),
        (502, null),
      ]) {
        h.server.failNext('syncItem', status, code: code);
        expect(await _status(() => plaid.syncItem(itemId: item)), status);
      }

      // refresh, balances and the logo
      expect(await _status(() => plaid.refreshItem(itemId: item)), 202);
      expect(await _status(() => plaid.syncItem(itemId: item)), 202);
      expect(await _status(() => plaid.refreshItem(itemId: 'nope')), 404);
      expect(await _status(() => plaid.refreshBalances(itemId: item)), 200);
      expect(await _status(() => plaid.refreshBalances(itemId: 'nope')), 404);
      for (final String operation in ['refreshItem', 'refreshBalances']) {
        for (final (int status, String? code) in [
          (409, 'item_login_required'),
          (429, null),
          (502, null),
        ]) {
          h.server.failNext(operation, status, code: code);
          expect(
            await _status(
              () => operation == 'refreshItem'
                  ? plaid.refreshItem(itemId: item)
                  : plaid.refreshBalances(itemId: item),
            ),
            status,
          );
        }
      }
      final api.InstitutionsApi institutions = h.client.getInstitutionsApi();
      final Response<Uint8List> logo = await institutions.getInstitutionLogo(
        institutionId: 'ins_109508',
      );
      expect(logo.data, _logo);
      expect(
        await _status(
          () => institutions.getInstitutionLogo(institutionId: 'ins_1'),
        ),
        404,
      );

      final api.UpdateLinkTokenRequest update =
          _model<api.UpdateLinkTokenRequest>(linkExample);
      expect(
        await _status(
          () => plaid.createUpdateLinkToken(
            itemId: item,
            updateLinkTokenRequest: update,
          ),
        ),
        200,
      );
      expect(
        await _status(
          () => plaid.createUpdateLinkToken(
            itemId: 'nope',
            updateLinkTokenRequest: update,
          ),
        ),
        404,
      );
      expect(
        (await h.rawSend(
          'POST',
          '/plaid/items/$item/update-link-token',
          body: {'android_package_name': 'x', 'extra': 1},
        )).statusCode,
        400,
      );
      for (final int status in [429, 502]) {
        h.server.failNext('createUpdateLinkToken', status);
        expect(
          await _status(
            () => plaid.createUpdateLinkToken(
              itemId: item,
              updateLinkTokenRequest: update,
            ),
          ),
          status,
        );
      }

      // sandbox
      final api.SandboxApi sandbox = h.client.getSandboxApi();
      final api.FireWebhookRequest fire = _model<api.FireWebhookRequest>({
        'webhook_code': 'SYNC_UPDATES_AVAILABLE',
      });
      expect(
        await _status(
          () => sandbox.sandboxFireWebhook(
            itemId: item,
            fireWebhookRequest: fire,
          ),
        ),
        204,
      );
      expect(
        await _status(
          () => sandbox.sandboxFireWebhook(
            itemId: 'nope',
            fireWebhookRequest: fire,
          ),
        ),
        404,
      );
      expect(
        (await h.rawSend(
          'POST',
          '/sandbox/items/$item/fire-webhook',
          body: {'webhook_code': 'PENDING_EXPIRATION'},
        )).statusCode,
        400,
      );
      final api.CreateSandboxTransactionsRequest inject =
          _model<api.CreateSandboxTransactionsRequest>({
            'transactions': [
              {
                'date_transacted': '2026-10-23',
                'date_posted': '2026-10-24',
                'amount': {'minor_units': 1599, 'currency': 'USD'},
                'description': 'NETFLIX.COM',
                'account_id': 'sample-checking',
              },
            ],
          });
      expect(
        await _status(
          () => sandbox.sandboxCreateTransactions(
            itemId: item,
            createSandboxTransactionsRequest: inject,
          ),
        ),
        204,
      );
      expect(
        await _status(
          () => sandbox.sandboxCreateTransactions(
            itemId: 'nope',
            createSandboxTransactionsRequest: inject,
          ),
        ),
        404,
      );
      expect(
        (await h.rawSend(
          'POST',
          '/sandbox/items/$item/transactions',
          body: {'transactions': <Object>[]},
        )).statusCode,
        400,
      );
      for (final String operation in [
        'sandboxResetLogin',
        'sandboxFireWebhook',
        'sandboxCreateTransactions',
      ]) {
        for (final int status in [409, 429, 500, 502]) {
          h.server.failNext(operation, status);
          expect(
            await _status(
              () => switch (operation) {
                'sandboxResetLogin' => sandbox.sandboxResetLogin(itemId: item),
                'sandboxFireWebhook' => sandbox.sandboxFireWebhook(
                  itemId: item,
                  fireWebhookRequest: fire,
                ),
                _ => sandbox.sandboxCreateTransactions(
                  itemId: item,
                  createSandboxTransactionsRequest: inject,
                ),
              },
            ),
            status,
          );
        }
      }
      expect(
        await _status(() => sandbox.sandboxResetLogin(itemId: 'nope')),
        404,
      );
      expect(await _status(() => sandbox.sandboxResetLogin(itemId: item)), 204);
      expect(await _status(() => plaid.syncItem(itemId: item)), 409);
      expect(
        await _status(
          () => sandbox.sandboxCreateTransactions(
            itemId: item,
            createSandboxTransactionsRequest: inject,
          ),
        ),
        409,
      );
      expect(
        await _status(
          () => plaid.createUpdateLinkToken(
            itemId: item,
            updateLinkTokenRequest: _model<api.UpdateLinkTokenRequest>(
              linkExample,
            ),
          ),
        ),
        200,
      );
      expect(
        await _status(
          () => plaid.exchangePublicToken(
            exchangeRequest: _model<api.ExchangeRequest>({
              'public_token': 'public-demo-update-$item',
            }),
          ),
        ),
        201,
      );
      expect(await _status(() => plaid.syncItem(itemId: item)), 202);

      // provisioning
      final api.ProvisionRequest provision = _model<api.ProvisionRequest>({
        'persona': 'renter',
        'seed': 1,
        'days': 30,
      });
      final Response<api.ProvisionJob> job = await sandbox.provisionPersona(
        provisionRequest: provision,
      );
      expect(job.statusCode, 202);
      expect(
        await _status(
          () => sandbox.provisionPersona(provisionRequest: provision),
        ),
        409,
      );
      expect(
        (await h.rawSend(
          'POST',
          '/sandbox/provision',
          body: {'persona': 'renter', 'days': 10},
        )).statusCode,
        400,
      );
      h.server.failNext('provisionPersona', 500);
      expect(
        await _status(
          () => sandbox.provisionPersona(provisionRequest: provision),
        ),
        500,
      );
      h.server.advanceClock(const Duration(seconds: 1));
      expect(
        await _status(() => sandbox.getProvisionJob(jobId: job.data!.id)),
        200,
      );
      expect(await _status(() => sandbox.getProvisionJob(jobId: 'nope')), 404);
      for (final int status in [409, 500]) {
        h.server.failNext('getProvisionJob', status);
        expect(
          await _status(() => sandbox.getProvisionJob(jobId: job.data!.id)),
          status,
        );
      }

      // data, filled
      expect(await _status(data.listAccounts), 200);
      expect(await _status(() => data.listTransactions(limit: 5)), 200);
      expect(await _status(() => data.listTransactions(since: 5)), 200);
      expect(await _status(() => data.listTransactions(since: 99)), 409);
      expect((await h.rawSend('GET', '/transactions?limit=0')).statusCode, 400);
      expect(await _status(data.getLiabilities), 200);
      expect(await _status(data.listHoldings), 200);
      expect(await _status(data.listInvestmentTransactions), 200);
      expect(
        await _status(() => data.listInvestmentTransactions(since: 99)),
        409,
      );
      expect(
        (await h.rawSend(
          'GET',
          '/investments/transactions?since=-1',
        )).statusCode,
        400,
      );
      expect(await _status(data.listRecurringStreams), 200);

      // sync
      final String device = session.data!.device.id;
      final int wall = fakeNow.millisecondsSinceEpoch;
      Map<String, Object?> entry(int wall, String deviceId) => {
        'entity_type': 'category',
        'entity_id': 'cat-1',
        'operation': 'create',
        'payload': {'name': 'Coffee', 'sort': 1},
        'hlc': '${wall.toString().padLeft(15, '0')}-00000-$deviceId',
        'device_id': deviceId,
      };
      expect(
        await _status(
          () => sync.pushChanges(
            pushRequest: _model<api.PushRequest>({
              'entries': [entry(wall, device), entry(wall, 'other-device')],
            }),
          ),
        ),
        200,
      );
      expect(
        (await h.rawSend(
          'POST',
          '/sync/push',
          body: {
            'entries': [
              {...entry(wall, device), 'hlc': 'not-a-clock'},
            ],
          },
        )).statusCode,
        400,
      );
      // Another device of the user pulls the entry.
      h.signInAs((await auth.login(loginRequest: login)).data!.accessToken);
      expect(await _status(sync.pullChanges), 200);
      expect(await _status(() => sync.pullChanges(since: 99)), 409);
      expect((await h.rawSend('GET', '/sync/pull?limit=501')).statusCode, 400);
      h.signInAs(session.data!.accessToken);

      // webhooks: raw Dio, because the generated receivePlaidWebhook cannot serialize
      // its own body (no builder factory for BuiltMap<String, JsonObject>); the app never
      // calls it.
      expect(
        (await h.raw.post<dynamic>(
          '/webhooks/plaid',
          data: {
            'webhook_type': 'TRANSACTIONS',
            'webhook_code': 'SYNC_UPDATES_AVAILABLE',
          },
          options: Options(
            headers: {'Plaid-Verification': 'eyJhbGciOiJFUzI1NiJ9.e30.sig'},
          ),
        )).statusCode,
        401,
      );

      // Item deletion: kept, refused while removed, then deleted
      expect(
        (await h.rawSend(
          'DELETE',
          '/plaid/items/$item?history=archive',
        )).statusCode,
        400,
      );
      expect(
        await _status(() => plaid.deleteItem(itemId: item, history: 'keep')),
        204,
      );
      expect(await _status(() => plaid.syncItem(itemId: item)), 409);
      expect(await _status(() => plaid.refreshItem(itemId: item)), 409);
      expect(await _status(() => plaid.refreshBalances(itemId: item)), 409);
      h.server.failNext('deleteItem', 502);
      expect(await _status(() => plaid.deleteItem(itemId: item)), 502);
      expect(await _status(() => plaid.deleteItem(itemId: item)), 204);
      expect(await _status(() => plaid.deleteItem(itemId: item)), 404);
      expect(await _status(() => data.listTransactions(since: 12)), 200);

      // logout: another device's token is refused; its own signs it out.
      final api.RefreshRequest sessionRefresh = _model<api.RefreshRequest>({
        'refresh_token': session.data!.refreshToken,
      });
      expect(
        await _status(
          () => auth.logout(
            refreshRequest: _model<api.RefreshRequest>({
              'refresh_token': rotated.data!.refreshToken,
            }),
          ),
        ),
        401,
      );
      expect(
        (await h.rawSend(
          'POST',
          '/auth/logout',
          body: {'refresh_token': 7},
        )).statusCode,
        400,
      );
      expect(
        await _status(() => auth.logout(refreshRequest: sessionRefresh)),
        204,
      );

      // account deletion, on a fresh session
      h.signInAs((await auth.login(loginRequest: login)).data!.accessToken);
      h.server.failNext('deleteMe', 502);
      expect(await _status(me.deleteMe), 502);
      expect(await _status(me.deleteMe), 204);
      expect(await _status(devices.listDevices), 401);

      final Map<String, Set<int>> seen = h.verify();
      // Every operation was exercised, and every one but the webhook (which answers 401
      // until Phase 3 verifies deliveries) succeeded at least once.
      expect(seen.keys.toSet(), {
        for (final FakeRoute r in FakeServer.routes) r.operationId,
      });
      for (final MapEntry(key: String id, value: Set<int> statuses)
          in seen.entries) {
        if (id == 'receivePlaidWebhook') continue;
        expect(
          statuses.any((s) => s >= 200 && s < 300),
          isTrue,
          reason: '$id: $statuses',
        );
      }
    },
  );

  test('an unknown route is a 404 problem', () async {
    final _Harness h = _Harness();
    final Response<dynamic> response = await h.raw.get<dynamic>('/nothing');
    expect(response.statusCode, 404);
    expect(response.data, conformsToSchema(_contract, 'Problem'));
  });
}
