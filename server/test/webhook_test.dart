// POST /webhooks/plaid with the fake client serving a test key: a verified delivery
// dispatched (sync, recurring, every status), and every way a delivery fails to verify
// (no header, a forged signature, a stale or future iat, a tampered body, an unknown kid,
// HS256 and none, an expired key, a short signature), each a 401 that touches nothing.
// The signing keys come from fixed test scalars; no key material is committed.
import 'dart:async';
import 'dart:convert';

import 'package:cryptography/dart.dart' show DartSha256;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:finance_tracker_server/server.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

const _kid = 'test-kid-1';

/// A P-256 private key from a fixed, test-only scalar derived from [label].
ECPrivateKey _testKey(String label) {
  final d = const DartSha256().hashSync(utf8.encode(label)).bytes;
  return JWTKey.fromJWK({
    'kty': 'EC',
    'crv': 'P-256',
    'd': base64Url.encode(d).replaceAll('=', ''),
  }) as ECPrivateKey;
}

/// The public JWK of [key] as `/webhook_verification_key/get` serves it.
Map<String, Object?> _publicJwk(
  ECPrivateKey key, {
  String kid = _kid,
  int? expiredAt,
}) {
  final jwk = key.toJWK(keyID: kid)..remove('d');
  return {...jwk, 'created_at': 1700000000, 'expired_at': expiredAt};
}

String _sha256Hex(String body) => [
  for (final b in const DartSha256().hashSync(utf8.encode(body)).bytes)
    b.toRadixString(16).padLeft(2, '0'),
].join();

void main() {
  late TestServer server;
  late Session ada;
  late ECPrivateKey key;
  late String itemId;
  late String plaidItemId;
  late List<String> calls;
  late List<String> lines;

  setUp(() async {
    server = await TestServer.start();
    ada = await server.register();
    key = _testKey('finance-tracker webhook test key');
    server.plaid.addWebhookKey(_publicJwk(key));
    final publicToken = await server.plaid.sandboxPublicTokenCreate(
      institutionId: 'ins_109508',
      products: const ['transactions'],
    );
    final item = await server.call(
      'post',
      '/plaid/exchange',
      token: ada.access,
      body: {'public_token': publicToken},
    );
    itemId = item.json['id']! as String;
    plaidItemId =
        (await server.app.db.read(
              (tx) => tx.first('SELECT plaid_item_id FROM items'),
            ))!['plaid_item_id']!
            as String;
    calls = [];
    server.plaid.onCall = (method) async => calls.add(method);
    lines = [];
    final subscription = Logger.root.onRecord.listen(
      (r) => lines.add(formatRecord(r, LogFormat.json)),
    );
    addTearDown(subscription.cancel);
  });

  int nowSeconds() => server.clock.value.millisecondsSinceEpoch ~/ 1000;

  String sign(
    String body, {
    ECPrivateKey? by,
    String kid = _kid,
    int? iat,
    String? claimedBody,
  }) => JWT(
    {
      'iat': iat ?? nowSeconds(),
      'request_body_sha256': _sha256Hex(claimedBody ?? body),
    },
    header: {'kid': kid},
  ).sign(by ?? key, algorithm: JWTAlgorithm.ES256, noIssueAt: true);

  String webhook(
    String type,
    String code, {
    String? item,
    Map<String, Object?>? error,
  }) => jsonEncode({
    'webhook_type': type,
    'webhook_code': code,
    'item_id': item ?? plaidItemId,
    'error': ?error,
    'environment': 'sandbox',
  });

  Future<TestResponse> deliver(String body, String? token) => server.call(
    'post',
    '/webhooks/plaid',
    rawBody: body,
    headers: {'plaid-verification': ?token},
  );

  Future<Map<String, Object?>> itemRow() async {
    final row = await server.app.db.read(
      (tx) => tx.first(
        'SELECT status, error_code, last_successful_sync_at FROM items '
        'WHERE id = ?',
        [itemId],
      ),
    );
    return {...row!};
  }

  Future<void> rejected(TestResponse r, String reason) async {
    expect(r.status, 401, reason: '$r');
    expect(r.code, 'webhook_unverified');
    expect(
      lines.where((l) => l.contains('webhook_rejected')).last,
      contains('"reason":"$reason"'),
    );
    expect(lines.where((l) => l.contains('webhook_received')), isEmpty);
    expect(
      calls.where((m) => m != 'webhookVerificationKeyGet'),
      isEmpty,
      reason: 'an unverified delivery reaches no other Plaid call',
    );
    expect((await itemRow())['last_successful_sync_at'], isNull);
  }

  group('a verified delivery', () {
    test(
      'SYNC_UPDATES_AVAILABLE starts a background sync; 204 at once',
      () async {
        final body = webhook('TRANSACTIONS', 'SYNC_UPDATES_AVAILABLE');
        final r = await deliver(body, sign(body));
        expect(r.status, 204);
        await pumpUntil(
          () async => (await itemRow())['last_successful_sync_at'] != null,
        );
        // The fake answers NOT_READY first: the background run asked again.
        expect(calls.where((m) => m == 'transactionsSync'), hasLength(2));
        expect(
          lines.where((l) => l.contains('webhook_received')),
          hasLength(1),
        );
      },
    );

    test('DEFAULT_UPDATE syncs too', () async {
      final body = webhook('TRANSACTIONS', 'DEFAULT_UPDATE');
      expect((await deliver(body, sign(body))).status, 204);
      await pumpUntil(
        () async => (await itemRow())['last_successful_sync_at'] != null,
      );
    });

    test('RECURRING_TRANSACTIONS_UPDATE refetches the streams alone', () async {
      await server.app.items.sync(ada.userId, itemId, retryNotReady: true);
      calls.clear();
      final body = webhook('TRANSACTIONS', 'RECURRING_TRANSACTIONS_UPDATE');
      expect((await deliver(body, sign(body))).status, 204);
      await pumpUntil(
        () async => lines.any((l) => l.contains('item_recurring_refreshed')),
      );
      expect(calls, ['webhookVerificationKeyGet', 'transactionsRecurringGet']);
    });

    test('ITEM codes set the status and the code', () async {
      Future<void> send(String code, [Map<String, Object?>? error]) async {
        server.clock.advance(const Duration(seconds: 1));
        final body = webhook('ITEM', code, error: error);
        expect((await deliver(body, sign(body))).status, 204);
      }

      await send('ERROR', {'error_code': 'ITEM_LOGIN_REQUIRED'});
      expect(await itemRow(), containsPair('status', 'login_required'));
      expect(
        await itemRow(),
        containsPair('error_code', 'ITEM_LOGIN_REQUIRED'),
      );
      await send('LOGIN_REPAIRED');
      expect(await itemRow(), containsPair('status', 'healthy'));
      expect(await itemRow(), containsPair('error_code', null));
      await send('ERROR', {'error_code': 'INSTITUTION_DOWN'});
      expect(await itemRow(), containsPair('status', 'error'));
      expect(await itemRow(), containsPair('error_code', 'INSTITUTION_DOWN'));
      await send('ERROR');
      expect(await itemRow(), containsPair('status', 'error'));
      expect(await itemRow(), containsPair('error_code', null));
      await send('USER_PERMISSION_REVOKED');
      expect(
        await itemRow(),
        containsPair('error_code', 'USER_PERMISSION_REVOKED'),
      );
      await send('USER_ACCOUNT_REVOKED');
      expect(await itemRow(), containsPair('status', 'error'));
      await send('PENDING_DISCONNECT');
      expect(await itemRow(), containsPair('status', 'pending_expiration'));
      await send('PENDING_EXPIRATION');
      expect(await itemRow(), containsPair('error_code', 'PENDING_EXPIRATION'));

      // A completed sync keeps a pending expiration; LOGIN_REPAIRED ends it.
      final run = await server.app.items.sync(
        ada.userId,
        itemId,
        retryNotReady: true,
      );
      expect(run['status'], 'completed');
      expect(await itemRow(), containsPair('status', 'pending_expiration'));
      final items = await server.call('get', '/plaid/items', token: ada.access);
      expect(items.list.single, containsPair('status', 'pending_expiration'));
      await send('LOGIN_REPAIRED');
      expect(await itemRow(), containsPair('status', 'healthy'));
    });

    test('a completed sync still clears an error status', () async {
      final body = webhook('ITEM', 'ERROR', error: {'error_code': 'X'});
      await deliver(body, sign(body));
      await server.app.items.sync(ada.userId, itemId, retryNotReady: true);
      expect(await itemRow(), containsPair('status', 'healthy'));
      expect(await itemRow(), containsPair('error_code', null));
    });

    test(
      'an unknown or removed Item and an unhandled code are 204, logged',
      () async {
        final unknown = webhook('TRANSACTIONS', 'DEFAULT_UPDATE', item: 'nope');
        expect((await deliver(unknown, sign(unknown))).status, 204);
        expect(
          lines.where((l) => l.contains('webhook_unknown_item')),
          hasLength(1),
        );

        final other = webhook('ITEM', 'NEW_ACCOUNTS_AVAILABLE');
        expect((await deliver(other, sign(other))).status, 204);
        expect(lines.where((l) => l.contains('webhook_ignored')), hasLength(1));

        await server.app.db.read(
          (tx) => tx.execute(
            'UPDATE items SET plaid_removed_at = 1 WHERE id = ?',
            [itemId],
          ),
        );
        final removed = webhook('ITEM', 'LOGIN_REPAIRED');
        await server.app.db.read(
          (tx) => tx.execute(
            "UPDATE items SET status = 'login_required' WHERE id = ?",
            [itemId],
          ),
        );
        expect((await deliver(removed, sign(removed))).status, 204);
        expect(await itemRow(), containsPair('status', 'login_required'));
        expect(
          lines.where((l) => l.contains('webhook_unknown_item')),
          hasLength(2),
        );
      },
    );

    test('a verified body that is not a JSON object is 400', () async {
      const body = '[1, 2]';
      final r = await deliver(body, sign(body));
      expect(r.status, 400);
    });

    test('the key is cached for an hour, then fetched again', () async {
      for (var i = 0; i < 2; i++) {
        final body = webhook('ITEM', 'LOGIN_REPAIRED');
        expect((await deliver(body, sign(body))).status, 204);
      }
      expect(
        calls.where((m) => m == 'webhookVerificationKeyGet'),
        hasLength(1),
      );
      server.clock.advance(const Duration(minutes: 61));
      final body = webhook('ITEM', 'LOGIN_REPAIRED');
      expect((await deliver(body, sign(body))).status, 204);
      expect(
        calls.where((m) => m == 'webhookVerificationKeyGet'),
        hasLength(2),
      );
    });
  });

  group('an unverified delivery is 401 and processed not at all', () {
    late String body;

    setUp(() {
      body = webhook('TRANSACTIONS', 'SYNC_UPDATES_AVAILABLE');
    });

    test('no header', () async {
      await rejected(await deliver(body, null), 'missing_header');
    });

    test('not a JWT', () async {
      await rejected(await deliver(body, 'abc.def'), 'malformed');
    });

    test('a forged signature', () async {
      final forger = _testKey('somebody else');
      await rejected(
        await deliver(body, sign(body, by: forger)),
        'bad_signature',
      );
    });

    test('a short signature', () async {
      final token = sign(body);
      final parts = token.split('.');
      final signature = base64Url.decode(base64Url.normalize(parts[2]));
      final short =
          '${parts[0]}.${parts[1]}.'
          '${base64Url.encode(signature.sublist(0, 63)).replaceAll('=', '')}';
      await rejected(await deliver(body, short), 'bad_signature');
    });

    test('a stale iat and a future one', () async {
      await rejected(
        await deliver(body, sign(body, iat: nowSeconds() - 301)),
        'stale',
      );
      await rejected(
        await deliver(body, sign(body, iat: nowSeconds() + 301)),
        'stale',
      );
      // Within the five minutes either way it verifies.
      final fresh = webhook('ITEM', 'LOGIN_REPAIRED');
      expect(
        (await deliver(fresh, sign(fresh, iat: nowSeconds() - 299))).status,
        204,
      );
    });

    test('a tampered body', () async {
      final token = sign(body);
      final tampered = body.replaceFirst('SYNC_UPDATES', 'SYNC_UPDATEZ');
      await rejected(await deliver(tampered, token), 'body_mismatch');
    });

    test('an unknown kid, fetched once however many arrive at once', () async {
      final release = Completer<void>();
      server.plaid.onCall = (method) async {
        calls.add(method);
        if (method == 'webhookVerificationKeyGet') await release.future;
      };
      final token = sign(body, kid: 'unknown-kid');
      final first = deliver(body, token);
      final second = deliver(body, token);
      await Future<void>.delayed(Duration.zero);
      release.complete();
      await rejected(await first, 'unknown_kid');
      await rejected(await second, 'unknown_kid');
      expect(calls, ['webhookVerificationKeyGet']);
      // Not cached: a later delivery asks again.
      await rejected(await deliver(body, token), 'unknown_kid');
      expect(calls, hasLength(2));
    });

    test('HS256 and none are refused before any key is fetched', () async {
      final hs256 = JWT(
        {'iat': nowSeconds(), 'request_body_sha256': _sha256Hex(body)},
        header: {'kid': _kid},
      ).sign(SecretKey('shared'), noIssueAt: true);
      await rejected(await deliver(body, hs256), 'bad_alg');
      String part(Object json) =>
          base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
      final none =
          '${part({'alg': 'none', 'kid': _kid})}.'
          '${part({'iat': nowSeconds(), 'request_body_sha256': _sha256Hex(body)})}.';
      await rejected(await deliver(body, none), 'bad_alg');
      expect(calls, isEmpty);
    });

    test('a key with any expired_at, past or future', () async {
      server.plaid.addWebhookKey(_publicJwk(key, expiredAt: nowSeconds() - 1));
      await rejected(await deliver(body, sign(body)), 'key_expired');
      server.clock.advance(const Duration(hours: 2));
      server.plaid.addWebhookKey(
        _publicJwk(key, expiredAt: nowSeconds() + 3600),
      );
      await rejected(await deliver(body, sign(body)), 'key_expired');
    });

    test('a key Plaid cannot be asked for', () async {
      server.plaid.failNext(
        'webhookVerificationKeyGet',
        const PlaidException('API_ERROR', 'TIMEOUT'),
      );
      await rejected(await deliver(body, sign(body)), 'key_unavailable');
    });

    test('no log line carries the token or the body', () async {
      final token = sign(body, iat: nowSeconds() - 1000);
      await deliver(body, token);
      for (final line in lines) {
        expect(line, isNot(contains(token)));
        expect(line, isNot(contains(plaidItemId)));
      }
    });
  });
}

/// Lets the event loop run until [done] holds (at most about ten seconds).
Future<void> pumpUntil(Future<bool> Function() done) async {
  for (var i = 0; i < 1000; i++) {
    if (await done()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('the condition never held');
}
