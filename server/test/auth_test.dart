import 'package:finance_tracker_server/server.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  late TestServer server;
  setUp(() async => server = await TestServer.start());

  group('register', () {
    test('creates the user and its first device', () async {
      final r = await server.call(
        'post',
        '/auth/register',
        body: {
          'email': 'Ada@Example.com',
          'password': 'correct horse battery',
          'device_name': 'Pixel 8',
        },
      );
      expect(r.status, 201);
      expect(r.json['access_expires_in'], 900);
      final session = Session(r.json);
      final me = await server.call('get', '/me', token: session.access);
      expect(me.status, 200);
      expect(me.json['email'], 'ada@example.com');
      expect(me.json['display_name'], 'ada');
    });

    test('takes the display name given', () async {
      final r = await server.call(
        'post',
        '/auth/register',
        body: {
          'email': 'ada@example.com',
          'password': 'correct horse battery',
          'device_name': 'Pixel 8',
          'display_name': 'Ada Lovelace',
        },
      );
      final me = await server.call('get', '/me', token: Session(r.json).access);
      expect(me.json['display_name'], 'Ada Lovelace');
    });

    test(
      'answers 409 email_taken for a registered email, in any case',
      () async {
        await server.register();
        final r = await server.call(
          'post',
          '/auth/register',
          body: {
            'email': 'ADA@example.com',
            'password': 'another password',
            'device_name': 'Pixel 9',
          },
        );
        expect(r.status, 409);
        expect(r.code, 'email_taken');
      },
    );

    test('answers 400 with every field error', () async {
      final r = await server.call(
        'post',
        '/auth/register',
        body: {'email': 'not-an-email', 'password': 'short', 'extra': 1},
        validRequest: false,
      );
      expect(r.status, 400);
      expect(r.code, 'validation_failed');
      final fields = {
        for (final e in r.json['errors']! as List<Object?>)
          (e! as Map<String, Object?>)['field'],
      };
      expect(fields, {'email', 'password', 'device_name', 'extra'});
    });

    test('answers 400 for an explicit null display_name', () async {
      final r = await server.call(
        'post',
        '/auth/register',
        body: {
          'email': 'ada@example.com',
          'password': 'correct horse battery',
          'device_name': 'Pixel 8',
          'display_name': null,
        },
        validRequest: false,
      );
      expect(r.status, 400);
      expect(
        (r.json['errors']! as List<Object?>).single,
        containsPair('field', 'display_name'),
      );
    });

    test('answers 400 for a body that is not JSON or too large', () async {
      final notJson = await server.call(
        'post',
        '/auth/register',
        rawBody: '{nope',
      );
      expect(notJson.status, 400);
      final wrongType = await server.call(
        'post',
        '/auth/register',
        rawBody: 'email=a',
        contentType: 'text/plain',
      );
      expect(wrongType.status, 400);
      final huge = await server.call(
        'post',
        '/auth/register',
        rawBody: '{"email": "${'a' * (1024 * 1024)}"}',
      );
      expect(huge.status, 400);
      expect(
        (huge.json['errors']! as List<Object?>).single,
        containsPair('field', ''),
      );
    });
  });

  group('login', () {
    test('signs a new device in', () async {
      final first = await server.register();
      final second = await server.login();
      expect(second.deviceId, isNot(first.deviceId));
      expect(second.userId, first.userId);
      final devices = await server.call('get', '/devices', token: first.access);
      expect(devices.list, hasLength(2));
    });

    test(
      'answers 401 invalid_credentials for a wrong password or email',
      () async {
        await server.register();
        for (final (email, password) in [
          ('ada@example.com', 'wrong password'),
          ('nobody@example.com', 'correct horse battery'),
        ]) {
          final r = await server.call(
            'post',
            '/auth/login',
            body: {'email': email, 'password': password, 'device_name': 'X'},
          );
          expect(r.status, 401);
          expect(r.code, 'invalid_credentials');
          expect(r.headers['www-authenticate'], 'Bearer');
        }
      },
    );

    test('rehashes a password stored under other parameters', () async {
      await server.register();
      final stronger = await TestServer.start(
        config: ServerConfig(
          jwtSecret: testConfig.jwtSecret,
          tokenEncryptionKey: testConfig.tokenEncryptionKey,
          argon2: const Argon2Parameters(
            memoryKib: 128,
            iterations: 2,
            parallelism: 1,
          ),
        ),
      );
      // Move the weak hash into the stronger server's database.
      final hash = await server.app.db.read(
        (tx) => tx.first('SELECT password_hash FROM users')!['password_hash'],
      );
      await stronger.register();
      await stronger.app.db.read(
        (tx) => tx.execute('UPDATE users SET password_hash = ?', [hash]),
      );
      await stronger.login();
      final upgraded = await stronger.app.db.read(
        (tx) => tx.first('SELECT password_hash FROM users')!['password_hash'],
      );
      expect(upgraded, startsWith(r'$argon2id$v=19$m=128,t=2,p=1$'));
      await stronger.login();
    });
  });

  group('tokens', () {
    test('refresh rotates the pair', () async {
      final session = await server.register();
      final r = await server.call(
        'post',
        '/auth/refresh',
        body: {'refresh_token': session.refresh},
      );
      expect(r.status, 200);
      final next = Session(r.json);
      expect(next.refresh, isNot(session.refresh));
      expect(next.deviceId, session.deviceId);
      expect((await server.call('get', '/me', token: next.access)).status, 200);
    });

    test('reusing a rotated refresh token revokes the family', () async {
      final session = await server.register();
      final rotated = Session(
        (await server.call(
          'post',
          '/auth/refresh',
          body: {'refresh_token': session.refresh},
        )).json,
      );
      final reuse = await server.call(
        'post',
        '/auth/refresh',
        body: {'refresh_token': session.refresh},
      );
      expect(reuse.status, 401);
      expect(reuse.code, 'token_revoked');
      // The thief's and the owner's tokens of that family are dead.
      final again = await server.call(
        'post',
        '/auth/refresh',
        body: {'refresh_token': rotated.refresh},
      );
      expect(again.code, 'token_revoked');
      final me = await server.call('get', '/me', token: rotated.access);
      expect(me.status, 401);
      expect(me.code, 'token_revoked');
    });

    test('an unknown refresh token is token_revoked', () async {
      final r = await server.call(
        'post',
        '/auth/refresh',
        body: {'refresh_token': 'nope'},
      );
      expect(r.code, 'token_revoked');
    });

    test('a refresh token expires after 30 days', () async {
      final session = await server.register();
      server.clock.advance(const Duration(days: 30));
      final r = await server.call(
        'post',
        '/auth/refresh',
        body: {'refresh_token': session.refresh},
      );
      expect(r.status, 401);
      expect(r.code, 'token_expired');
    });

    test('an access token expires after 15 minutes', () async {
      final session = await server.register();
      server.clock.advance(const Duration(minutes: 14, seconds: 59));
      expect(
        (await server.call('get', '/me', token: session.access)).status,
        200,
      );
      server.clock.advance(const Duration(seconds: 1));
      final r = await server.call('get', '/me', token: session.access);
      expect(r.status, 401);
      expect(r.code, 'token_expired');
    });

    test('a missing or malformed bearer is invalid_credentials', () async {
      expect((await server.call('get', '/me')).code, 'invalid_credentials');
      expect(
        (await server.call('get', '/me', token: 'a.b.c')).code,
        'invalid_credentials',
      );
    });

    test('logout revokes the family and removes the device', () async {
      final session = await server.register();
      final other = await server.login();
      final r = await server.call(
        'post',
        '/auth/logout',
        body: {'refresh_token': session.refresh},
        token: session.access,
      );
      expect(r.status, 204);
      expect(
        (await server.call('get', '/me', token: session.access)).code,
        'token_revoked',
      );
      final refresh = await server.call(
        'post',
        '/auth/refresh',
        body: {'refresh_token': session.refresh},
      );
      expect(refresh.code, 'token_revoked');
      final devices = await server.call('get', '/devices', token: other.access);
      expect(devices.list, hasLength(1));
    });

    test("logout with another device's refresh token is 401", () async {
      final session = await server.register();
      final other = await server.login();
      final r = await server.call(
        'post',
        '/auth/logout',
        body: {'refresh_token': other.refresh},
        token: session.access,
      );
      expect(r.status, 401);
      expect(r.code, 'token_revoked');
    });
  });

  group('devices', () {
    test('deleting a device ends only its session', () async {
      final a = await server.register();
      final b = await server.login();
      final r = await server.call(
        'delete',
        '/devices/${b.deviceId}',
        token: a.access,
      );
      expect(r.status, 204);
      expect(
        (await server.call('get', '/me', token: b.access)).code,
        'token_revoked',
      );
      expect((await server.call('get', '/me', token: a.access)).status, 200);
      final refresh = await server.call(
        'post',
        '/auth/refresh',
        body: {'refresh_token': b.refresh},
      );
      expect(refresh.status, 401);
    });

    test('a device of another user, or none, is 404', () async {
      final a = await server.register();
      final eve = await server.register('eve@example.com');
      for (final id in [eve.deviceId, 'missing']) {
        final r = await server.call('delete', '/devices/$id', token: a.access);
        expect(r.status, 404);
        expect(r.code, 'not_found');
      }
    });

    test('a device may remove itself', () async {
      final a = await server.register();
      final r = await server.call(
        'delete',
        '/devices/${a.deviceId}',
        token: a.access,
      );
      expect(r.status, 204);
      expect((await server.call('get', '/me', token: a.access)).status, 401);
    });
  });

  group('rate limit', () {
    test(
      'the 11th call in a minute from one IP is 429 with Retry-After',
      () async {
        for (var i = 0; i < 10; i++) {
          final r = await server.call(
            'post',
            '/auth/login',
            body: {
              'email': 'x@example.com',
              'password': 'whatever1',
              'device_name': 'X',
            },
          );
          expect(r.status, 401);
        }
        final limited = await server.call(
          'post',
          '/auth/login',
          body: {
            'email': 'x@example.com',
            'password': 'whatever1',
            'device_name': 'X',
          },
        );
        expect(limited.status, 429);
        expect(limited.code, 'rate_limited');
        expect(
          int.parse(limited.headers['retry-after']!),
          inInclusiveRange(1, 6),
        );

        // Another IP and another operation have their own buckets.
        final otherIp = await server.call(
          'post',
          '/auth/login',
          body: {
            'email': 'x@example.com',
            'password': 'whatever1',
            'device_name': 'X',
          },
          headers: {'x-test-ip': '10.0.0.2'},
        );
        expect(otherIp.status, 401);
        final refresh = await server.call(
          'post',
          '/auth/refresh',
          body: {'refresh_token': 'nope'},
        );
        expect(refresh.status, 401);

        // A token comes back every six seconds.
        server.clock.advance(const Duration(seconds: 6));
        final later = await server.call(
          'post',
          '/auth/login',
          body: {
            'email': 'x@example.com',
            'password': 'whatever1',
            'device_name': 'X',
          },
        );
        expect(later.status, 401);
      },
    );

    test('refresh is limited too', () async {
      late TestResponse r;
      for (var i = 0; i < 11; i++) {
        r = await server.call(
          'post',
          '/auth/refresh',
          body: {'refresh_token': 'nope'},
        );
      }
      expect(r.status, 429);
    });
  });
}
