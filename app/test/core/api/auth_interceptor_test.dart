// The bearer interceptor and its single-flight refresh, against scripted answers that
// let the tests order the races exactly: concurrent expiries share one refresh, a late
// expiry reuses the refreshed session, a refused refresh or a revoked token ends the
// session (and only the session the failing call used), other refresh failures keep it,
// and nothing is retried after a network error.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/http_finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'support/scripted_adapter.dart';

final Clock _clock = FixedClock(DateTime.utc(2026, 10, 24, 15), tz.UTC);

Session _session(String access, String refresh) => Session(
  accessToken: access,
  refreshToken: refresh,
  accessExpiresAt: DateTime.utc(2026, 10, 24, 15),
  user: testUser,
  device: testDevice,
);

String? _bearer(RequestOptions options) =>
    (options.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');

final class _Harness {
  _Harness(FutureOr<Answer> Function(RequestOptions, Object?) handler)
    : adapter = ScriptedAdapter(handler) {
    api = HttpFinanceApi(
      buildDio(
        AppConfig.prod(),
        adapter: adapter,
        baseUrl: Uri.parse('https://api.test'),
        version: () async => '1.0.0',
      ),
      tokens: store,
      clock: _clock,
    );
    api.sessionEnded.listen((_) => ended++);
  }

  final ScriptedAdapter adapter;
  final InMemoryTokenStore store = InMemoryTokenStore(
    session: _session('a1', 'r1'),
  );
  late final HttpFinanceApi api;
  int ended = 0;

  int get refreshes => adapter.count('POST', '/auth/refresh');
}

void main() {
  test(
    'five concurrent expiries cause one refresh, and all five succeed',
    () async {
      final Completer<void> release = Completer<void>();
      final _Harness h = _Harness((options, body) async {
        if (options.uri.path == '/v1/auth/refresh') {
          await release.future;
          expect(body, {'refresh_token': 'r1'});
          return ok(authTokens('a2', 'r2'));
        }
        return _bearer(options) == 'a2'
            ? ok(testUser.toJson())
            : problem(401, 'token_expired');
      });

      final List<Future<Object>> calls = [
        for (int i = 0; i < 5; i++) h.api.getMe(),
      ];
      await pumpEventQueue();
      release.complete();
      final List<Object> users = await Future.wait(calls);

      expect(users, hasLength(5));
      expect(h.refreshes, 1);
      expect(h.adapter.count('GET', '/me'), 10);
      expect(h.store.session!.accessToken, 'a2');
      expect(h.store.session!.refreshToken, 'r2');
      expect(
        h.store.session!.accessExpiresAt,
        DateTime.utc(2026, 10, 24, 15, 15),
      );
      expect(h.ended, 0);
    },
  );

  test('an expiry answered after the refresh reuses the new session', () async {
    final Completer<void> hold = Completer<void>();
    int expired = 0;
    final _Harness h = _Harness((options, body) async {
      if (options.uri.path == '/v1/auth/refresh') {
        return ok(authTokens('a2', 'r2'));
      }
      if (_bearer(options) == 'a2') return ok(testUser.toJson());
      if (expired++ == 1) await hold.future;
      return problem(401, 'token_expired');
    });

    final Future<Object> first = h.api.getMe();
    final Future<Object> late = h.api.getMe();
    await first;
    hold.complete();
    await late;
    expect(h.refreshes, 1);
  });

  test('a refused refresh ends the session', () async {
    final _Harness h = _Harness(
      (options, _) => options.uri.path == '/v1/auth/refresh'
          ? problem(401, 'token_revoked')
          : problem(401, 'token_expired'),
    );
    await expectLater(h.api.getMe(), throwsA(isA<TokenRevoked>()));
    expect(h.store.session, isNull);
    expect(h.ended, 1);
  });

  test('a refresh that is rate limited or offline keeps the session', () async {
    final _Harness h = _Harness(
      (options, _) => options.uri.path == '/v1/auth/refresh'
          ? problem(429, 'rate_limited', headers: {'Retry-After': '3'})
          : problem(401, 'token_expired'),
    );
    await expectLater(h.api.getMe(), throwsA(isA<RateLimited>()));
    expect(h.store.session!.refreshToken, 'r1');

    h.adapter.handler = (options, _) => options.uri.path == '/v1/auth/refresh'
        ? throw DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          )
        : problem(401, 'token_expired');
    await expectLater(h.api.getMe(), throwsA(isA<NetworkError>()));
    expect(h.store.session!.refreshToken, 'r1');
    expect(h.ended, 0);
    expect(h.refreshes, 2);
  });

  test(
    'token_revoked ends the session it was sent with, not a newer one',
    () async {
      final _Harness h = _Harness((_, _) => problem(401, 'token_revoked'));
      await expectLater(h.api.listDevices(), throwsA(isA<TokenRevoked>()));
      expect(h.store.session, isNull);
      expect(h.ended, 1);

      // A request sent with a1 is answered after another sign-in stored b1.
      h.store.session = _session('a1', 'r1');
      final Completer<void> hold = Completer<void>();
      h.adapter.handler = (_, _) async {
        await hold.future;
        return problem(401, 'token_revoked');
      };
      final Future<void> stale = h.api.listDevices();
      await pumpEventQueue();
      h.store.session = _session('b1', 'rb1');
      hold.complete();
      await expectLater(stale, throwsA(isA<TokenRevoked>()));
      expect(h.store.session!.accessToken, 'b1');
      expect(h.ended, 1);
    },
  );

  test('a POST that fails on the network is not sent again', () async {
    final _Harness h = _Harness(
      (options, _) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    );
    await expectLater(
      h.api.exchangePublicToken('public-1'),
      throwsA(isA<NetworkError>()),
    );
    expect(h.adapter.requests, hasLength(1));
  });

  test('public operations carry no token and never refresh', () async {
    final _Harness h = _Harness((_, _) => problem(401, 'invalid_credentials'));
    await expectLater(
      h.api.login(
        email: 'ada@example.com',
        password: 'wrong-pass',
        deviceName: 'x',
      ),
      throwsA(isA<InvalidCredentials>()),
    );
    expect(h.adapter.requests.single.headers['Authorization'], isNull);
    expect(h.refreshes, 0);
    expect(h.store.session, isNotNull);
  });

  test('logout and a call with its own token are never refreshed', () async {
    final _Harness h = _Harness((_, _) => problem(401, 'token_expired'));
    await expectLater(h.api.logout('r1'), throwsA(isA<TokenExpired>()));
    await expectLater(
      h.api.getMe(accessToken: 'fresh'),
      throwsA(isA<TokenExpired>()),
    );
    expect(h.adapter.requests.last.headers['Authorization'], 'Bearer fresh');
    expect(h.refreshes, 0);
    expect(h.store.session!.accessToken, 'a1');
  });

  test('a 2xx body this build cannot read is a ServerError', () async {
    final _Harness h = _Harness((options, _) {
      if (options.uri.path == '/v1/transactions') {
        // The generated client reads it; the entity refuses a lower-case currency.
        return ok({
          'transactions': [
            {
              'id': 't1',
              'account_id': 'a1',
              'amount': {'minor_units': -100, 'currency': 'usd'},
              'date': '2026-10-24',
              'authorized_date': null,
              'pending': false,
              'pending_transaction_id': null,
              'name': 'X',
              'merchant_name': null,
              'merchant_logo_url': null,
              'plaid_primary_category': null,
              'plaid_detailed_category': null,
              'user_category_id': null,
              'notes': null,
              'tags': <String>[],
              'splits': <Object>[],
              'receipt_path': null,
              'source': 'demo',
              'created_at': '2026-10-24T12:00:00.000Z',
              'updated_at': '2026-10-24T12:00:00.000Z',
              'deleted_at': null,
              'sync_version': 1,
            },
          ],
          'next_since': 1,
          'has_more': false,
        });
      }
      // A rejection code this build does not know.
      return ok({
        'accepted': <String>[],
        'rejected': [
          {
            'hlc': '001761318000000-00000-device-1',
            'code': 'try_again_later',
            'reason': 'new',
          },
        ],
      });
    });
    await expectLater(h.api.listTransactions(), throwsA(isA<ServerError>()));
    await expectLater(h.api.pushChanges(const []), throwsA(isA<ServerError>()));
  });
}
