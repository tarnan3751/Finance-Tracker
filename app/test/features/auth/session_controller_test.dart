// The session controller against the fake server through the real client: restore
// (signed out, signed in at once then confirmed, a 401 signing out, offline keeping the
// session), sign-in, registration, one user per install, sign-out (with an expired
// access token too) and a session the server ends.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/http_finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/auth/application/device_name.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/api/support/fake_api.dart';

/// Holds every `GET /me` sent with [heldToken] until [release] completes.
final class _HoldingAdapter implements HttpClientAdapter {
  _HoldingAdapter(this._inner, this.heldToken);

  final HttpClientAdapter _inner;
  final String heldToken;
  final Completer<void> release = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path == '/v1/me' &&
        options.headers['Authorization'] == 'Bearer $heldToken') {
      await release.future;
    }
    return _inner.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}

/// [inner], except that its session read, or its install-user read, fails.
final class _FailingStore implements TokenStore {
  _FailingStore(
    this.inner, {
    this.failSession = false,
    this.failInstallUser = false,
  });

  final InMemoryTokenStore inner;
  final bool failSession;
  final bool failInstallUser;

  @override
  Future<Session?> read() async =>
      failSession ? throw StateError('storage is broken') : inner.read();

  @override
  Future<Session?> reload() => read();

  @override
  Future<void> write(Session session) => inner.write(session);

  @override
  Future<void> clear() => inner.clear();

  @override
  Future<void> update(Session? Function(Session? current) change) =>
      inner.update(change);

  @override
  Future<String?> readInstallUserId() async => failInstallUser
      ? throw PlatformException(code: 'decryption failed')
      : inner.readInstallUserId();

  @override
  Future<void> writeInstallUserId(String userId) =>
      inner.writeInstallUserId(userId);

  @override
  Future<void> clearInstallUserId() => inner.clearInstallUserId();
}

const String _email = 'ada@example.com';
const String _password = 'correct horse';

void main() {
  late FakeServer server;
  late InMemoryTokenStore store;
  late TokenStore tokens;

  setUp(() {
    server = newFakeServer();
    tokens = store = InMemoryTokenStore();
  });

  ProviderContainer container({HttpClientAdapter? adapter}) =>
      ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.prod()),
          clockProvider.overrideWithValue(fakeClientClock),
          fakeServerProvider.overrideWithValue(server),
          tokenStoreProvider.overrideWithValue(tokens),
          if (adapter == null)
            fakeFinanceApiOverride
          else
            financeApiProvider.overrideWith(
              (ref) => HttpFinanceApi(
                buildDio(
                  AppConfig.prod(),
                  adapter: adapter,
                  baseUrl: FakeServer.baseUrl,
                  version: () async => '1.0.0',
                ),
                tokens: tokens,
                clock: fakeClientClock,
              ),
            ),
          deviceNameProvider.overrideWith((ref) async => 'Pixel 6'),
        ],
      );

  Future<ProviderContainer> restored({HttpClientAdapter? adapter}) async {
    final ProviderContainer c = container(adapter: adapter);
    await c.read(sessionControllerProvider.notifier).restored();
    return c;
  }

  SessionState stateOf(ProviderContainer c) =>
      c.read(sessionControllerProvider);

  /// A session stored on this install for [_email], whose stored display name is stale.
  Session storeSession() {
    server.seedUser(email: _email, password: _password, displayName: 'Ada');
    final Session session = server.seedSession(
      email: _email,
      password: _password,
    );
    store
      ..session = session.withUser(session.user.copyWith(displayName: 'Old'))
      ..installUserId = session.userId;
    return session;
  }

  group('restore', () {
    test('nothing stored is signed out', () async {
      expect(stateOf(await restored()), const SignedOut());
    });

    test('a stored session is signed in at once, then confirmed', () async {
      storeSession();
      final ProviderContainer c = await restored();
      expect(stateOf(c), isA<SignedIn>());
      expect((stateOf(c) as SignedIn).user.displayName, 'Old');

      await pumpEventQueue();
      expect((stateOf(c) as SignedIn).user.displayName, 'Ada');
      expect(store.session!.user.displayName, 'Ada');
    });

    test('a session the server ended signs out', () async {
      final Session session = storeSession();
      final FakeClient other = FakeClient.signedIn(
        server,
        deviceName: 'Tablet',
      );
      await other.api.deleteDevice(session.deviceId);

      final ProviderContainer c = await restored();
      await pumpEventQueue();
      expect(stateOf(c), const SignedOut());
      expect(store.session, isNull);
      expect(store.installUserId, session.userId);
    });

    test(
      'a 401 for the restored session leaves a newer session alone',
      () async {
        final Session first = storeSession();
        final _HoldingAdapter held = _HoldingAdapter(
          server.adapter,
          first.accessToken,
        );
        final ProviderContainer c = await restored(adapter: held);
        final SessionController session = c.read(
          sessionControllerProvider.notifier,
        );
        // GET /me for the restored session is held; meanwhile the user signs out and in.
        await session.signOut();
        await session.signIn(email: _email, password: _password);
        final Session second = store.session!;
        expect(second.deviceId, isNot(first.deviceId));

        // The held GET /me now gets 401 token_revoked for the first device.
        held.release.complete();
        await pumpEventQueue();
        expect(stateOf(c), SignedIn(second.user, second.device));
        expect(store.session!.accessToken, second.accessToken);
      },
    );

    test('a store that fails still lets startup finish, signed out', () async {
      tokens = _FailingStore(store, failSession: true);
      final ProviderContainer c = await restored();
      expect(stateOf(c), const SignedOut());
    });

    test('offline keeps the session', () async {
      storeSession();
      server.failNextNetwork('getMe');
      final ProviderContainer c = await restored();
      await pumpEventQueue();
      expect(stateOf(c), isA<SignedIn>());
      expect(store.session, isNotNull);
    });
  });

  group('sign-in and registration', () {
    test('sign-in stores the session and records the install user', () async {
      final String userId = server.seedUser(email: _email, password: _password);
      final ProviderContainer c = await restored();
      await c
          .read(sessionControllerProvider.notifier)
          .signIn(email: _email, password: _password);

      final SignedIn state = stateOf(c) as SignedIn;
      expect(state.user.id, userId);
      expect(state.device.name, 'Pixel 6');
      expect(store.session!.device, state.device);
      expect(
        store.session!.accessExpiresAt,
        fakeNow.add(const Duration(minutes: 15)),
      );
      expect(store.installUserId, userId);
    });

    test('wrong credentials leave the install signed out', () async {
      server.seedUser(email: _email, password: _password);
      final ProviderContainer c = await restored();
      await expectLater(
        c
            .read(sessionControllerProvider.notifier)
            .signIn(email: _email, password: 'wrong password'),
        throwsA(isA<InvalidCredentials>()),
      );
      expect(stateOf(c), const SignedOut());
      expect(store.session, isNull);
    });

    test('registration signs in; a second one is refused offline', () async {
      final ProviderContainer c = await restored();
      final SessionController session = c.read(
        sessionControllerProvider.notifier,
      );
      await session.register(
        email: _email,
        password: _password,
        displayName: 'Ada',
      );
      expect((stateOf(c) as SignedIn).user.displayName, 'Ada');
      await session.signOut();

      final int calls = server.calls.length;
      await expectLater(
        session.register(email: 'bob@example.com', password: _password),
        throwsA(isA<OtherAccountOnDeviceException>()),
      );
      expect(server.calls, hasLength(calls));
    });

    test('an install user that cannot be read stops sign-in and registration '
        'before the network', () async {
      server.seedUser(email: _email, password: _password);
      tokens = _FailingStore(store, failInstallUser: true);
      final ProviderContainer c = await restored();
      final SessionController session = c.read(
        sessionControllerProvider.notifier,
      );
      final int calls = server.calls.length;
      await expectLater(
        session.register(email: 'bob@example.com', password: _password),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(
        session.signIn(email: _email, password: _password),
        throwsA(isA<PlatformException>()),
      );
      expect(server.calls, hasLength(calls));
      expect(store.installUserId, isNull);
      expect(store.session, isNull);
      expect(stateOf(c), const SignedOut());
    });

    test('another account cannot sign in on this install', () async {
      final ProviderContainer c = await restored();
      final SessionController session = c.read(
        sessionControllerProvider.notifier,
      );
      await session.register(email: _email, password: _password);
      await session.signOut();
      server.seedUser(email: 'bob@example.com', password: _password);

      await expectLater(
        session.signIn(email: 'bob@example.com', password: _password),
        throwsA(isA<OtherAccountOnDeviceException>()),
      );
      expect(stateOf(c), const SignedOut());
      expect(store.session, isNull);
      // The device that sign-in created was logged out again.
      final FakeClient bob = FakeClient.signedIn(
        server,
        email: 'bob@example.com',
        password: _password,
      );
      expect(await bob.api.listDevices(), hasLength(1));

      await session.signIn(email: _email, password: _password);
      expect(stateOf(c), isA<SignedIn>());
    });
  });

  group('sign-out and a session the server ends', () {
    test('sign-out logs the device out and clears the session', () async {
      final Session session = storeSession();
      final FakeClient other = FakeClient.signedIn(
        server,
        deviceName: 'Tablet',
      );
      final ProviderContainer c = await restored();
      await c.read(sessionControllerProvider.notifier).signOut();

      expect(stateOf(c), const SignedOut());
      expect(store.session, isNull);
      expect(
        (await other.api.listDevices()).map((d) => d.id),
        isNot(contains(session.deviceId)),
      );
    });

    test('sign-out with an expired access token still logs out', () async {
      final Session session = storeSession();
      final FakeClient other = FakeClient.signedIn(
        server,
        deviceName: 'Tablet',
      );
      final ProviderContainer c = await restored();
      await pumpEventQueue();
      server.advanceClock(const Duration(minutes: 16));

      await c.read(sessionControllerProvider.notifier).signOut();
      expect(server.calls, containsAllInOrder(['refreshTokens', 'logout']));
      expect(
        (await other.api.listDevices()).map((d) => d.id),
        isNot(contains(session.deviceId)),
      );
    });

    test('offline sign-out still signs out locally', () async {
      storeSession();
      server.failNextNetwork('logout');
      final ProviderContainer c = await restored();
      await c.read(sessionControllerProvider.notifier).signOut();
      expect(stateOf(c), const SignedOut());
      expect(store.session, isNull);
    });

    test('a revoked session signs out when the client next calls', () async {
      final Session session = storeSession();
      final ProviderContainer c = await restored();
      await pumpEventQueue();
      final FakeClient other = FakeClient.signedIn(
        server,
        deviceName: 'Tablet',
      );
      await other.api.deleteDevice(session.deviceId);

      final FinanceApi api = c.read(financeApiProvider);
      await expectLater(api.listDevices(), throwsA(isA<TokenRevoked>()));
      await pumpEventQueue();
      expect(stateOf(c), const SignedOut());
    });
  });

  group('the remote sign-out notice', () {
    bool notice(ProviderContainer c) =>
        c.read(sessionControllerProvider.notifier).takeRemoteSignOutNotice();

    test('a revocation leaves it, taken once', () async {
      final Session session = storeSession();
      final ProviderContainer c = await restored();
      await pumpEventQueue();
      await FakeClient.signedIn(
        server,
        deviceName: 'Tablet',
      ).api.deleteDevice(session.deviceId);
      await expectLater(
        c.read(financeApiProvider).listDevices(),
        throwsA(isA<TokenRevoked>()),
      );
      await pumpEventQueue();

      expect(notice(c), isTrue);
      expect(notice(c), isFalse);
      expect(store.installUserId, session.userId, reason: 'data kept');
    });

    test('the restore\'s 401 leaves it', () async {
      final Session session = storeSession();
      await FakeClient.signedIn(
        server,
        deviceName: 'Tablet',
      ).api.deleteDevice(session.deviceId);
      final ProviderContainer c = await restored();
      await pumpEventQueue();
      expect(stateOf(c), const SignedOut());
      expect(notice(c), isTrue);
    });

    test(
      'a sign-out here leaves none, and neither does ending locally',
      () async {
        storeSession();
        final ProviderContainer c = await restored();
        await c.read(sessionControllerProvider.notifier).signOut();
        expect(notice(c), isFalse);

        await c
            .read(sessionControllerProvider.notifier)
            .signIn(email: _email, password: _password);
        final int before = server.calls.length;
        await c.read(sessionControllerProvider.notifier).endLocally();
        expect(stateOf(c), const SignedOut());
        expect(store.session, isNull);
        expect(server.calls.skip(before), isEmpty, reason: 'no logout call');
        expect(notice(c), isFalse);
      },
    );

    test('a sign-out whose refresh is refused leaves none', () async {
      storeSession();
      final ProviderContainer c = await restored();
      await pumpEventQueue();
      server
        ..advanceClock(const Duration(minutes: 16))
        ..failNext('refreshTokens', 401, code: 'token_revoked');

      await c.read(sessionControllerProvider.notifier).signOut();
      await pumpEventQueue();
      expect(server.calls, containsAllInOrder(['logout', 'refreshTokens']));
      expect(stateOf(c), const SignedOut());
      expect(notice(c), isFalse);
    });

    test('a new sign-in drops a notice not yet shown', () async {
      final Session session = storeSession();
      final ProviderContainer c = await restored();
      await pumpEventQueue();
      await FakeClient.signedIn(
        server,
        deviceName: 'Tablet',
      ).api.deleteDevice(session.deviceId);
      await expectLater(
        c.read(financeApiProvider).listDevices(),
        throwsA(isA<TokenRevoked>()),
      );
      await pumpEventQueue();
      await c
          .read(sessionControllerProvider.notifier)
          .signIn(email: _email, password: _password);
      expect(notice(c), isFalse);
    });
  });
}
