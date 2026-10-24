// The token store: the session round trip through secure storage, an unreadable value
// read as signed out, and the install's user surviving sign-out.
import 'dart:convert';

import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_adapter.dart';

final Session _session = Session(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  accessExpiresAt: DateTime.utc(2026, 10, 24, 15, 15),
  user: testUser,
  device: testDevice,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a written session reads back, from a fresh store too', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final SecureTokenStore store = SecureTokenStore();
    expect(await store.read(), isNull);
    await store.write(_session);

    final Session? read = await SecureTokenStore().read();
    expect(read!.toJson(), _session.toJson());
    expect(read.userId, 'user-1');
    expect(read.deviceId, 'device-1');
  });

  test('the stored value is one JSON object under session_v1', () async {
    FlutterSecureStorage.setMockInitialValues({});
    await SecureTokenStore().write(_session);
    final String? raw = await const FlutterSecureStorage().read(
      key: SecureTokenStore.sessionKey,
    );
    expect(raw, contains('"access_expires_at":"2026-10-24T15:15:00.000Z"'));
    expect(raw, contains('"user":{'));
    expect(raw, contains('"device":{'));
  });

  test('an unreadable session is deleted and read as signed out', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureTokenStore.sessionKey: '{"access_token": 1}',
    });
    expect(await SecureTokenStore().read(), isNull);
    expect(
      await const FlutterSecureStorage().read(key: SecureTokenStore.sessionKey),
      isNull,
    );
  });

  test(
    'a session whose user the entity refuses is read as signed out',
    () async {
      // shared_models reads JSON checked: a missing field is a
      // CheckedFromJsonException, not a FormatException or a TypeError.
      final Map<String, dynamic> json = _session.toJson();
      (json['user'] as Map<String, dynamic>).remove('email');
      FlutterSecureStorage.setMockInitialValues({
        SecureTokenStore.sessionKey: jsonEncode(json),
      });
      expect(await SecureTokenStore().read(), isNull);
      expect(
        await const FlutterSecureStorage().read(
          key: SecureTokenStore.sessionKey,
        ),
        isNull,
      );
    },
  );

  test('update applies its change to the latest session, after a write queued '
      'before it', () async {
    final Session refreshed = Session(
      accessToken: 'access-2',
      refreshToken: 'refresh-2',
      accessExpiresAt: DateTime.utc(2026, 10, 24, 15, 30),
      user: testUser,
      device: testDevice,
    );
    FlutterSecureStorage.setMockInitialValues({});
    for (final TokenStore store in [SecureTokenStore(), InMemoryTokenStore()]) {
      await store.write(_session);
      // A confirmation read the old pair; a refresh writes the new one before the
      // confirmation writes its user.
      expect((await store.read())!.accessToken, 'access-1');
      final Future<void> refresh = store.write(refreshed);
      final Future<void> confirm = store.update(
        (latest) => latest!.withUser(testUser.copyWith(displayName: 'Ada L.')),
      );
      await Future.wait([refresh, confirm]);

      final Session after = (await store.read())!;
      expect(after.accessToken, 'access-2', reason: '${store.runtimeType}');
      expect(after.refreshToken, 'refresh-2');
      expect(after.user.displayName, 'Ada L.');

      await store.update((_) => null);
      expect(await store.read(), isNull);
    }
  });

  test('clear removes the session and keeps the install user', () async {
    FlutterSecureStorage.setMockInitialValues({'db_key_v1': 'key'});
    final SecureTokenStore store = SecureTokenStore();
    await store.write(_session);
    await store.writeInstallUserId('user-1');
    await store.clear();

    expect(await store.read(), isNull);
    expect(await SecureTokenStore().read(), isNull);
    expect(await SecureTokenStore().readInstallUserId(), 'user-1');
    expect(await const FlutterSecureStorage().read(key: 'db_key_v1'), 'key');
  });

  test('nothing that carries a token prints it', () {
    const AuthResult result = AuthResult(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      accessExpiresIn: Duration(minutes: 15),
      device: testDevice,
    );
    final LinkToken link = LinkToken(
      linkToken: 'link-sandbox-1',
      expiration: DateTime.utc(2026, 10, 24, 19),
    );
    for (final Object value in [_session, result]) {
      expect('$value', isNot(contains('access-1')));
      expect('$value', isNot(contains('refresh-1')));
    }
    expect('$link', isNot(contains('link-sandbox-1')));
  });

  test('InMemoryTokenStore keeps the same rules', () async {
    final InMemoryTokenStore store = InMemoryTokenStore(session: _session);
    await store.writeInstallUserId('user-1');
    await store.clear();
    expect(await store.read(), isNull);
    expect(await store.readInstallUserId(), 'user-1');
  });
}
