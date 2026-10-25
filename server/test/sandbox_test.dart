// The Sandbox control routes with the fake client: reset-login, fire-webhook and
// create-transactions, their validation, ownership, the removed Item and a server that
// cannot drive Sandbox.
import 'package:finance_tracker_server/server.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  late TestServer server;
  late Session ada;

  setUp(() async {
    server = await TestServer.start();
    ada = await server.register();
  });

  Future<String> link(TestServer s, Session who) async {
    final publicToken = await s.plaid.sandboxPublicTokenCreate(
      institutionId: 'ins_109508',
      products: const ['transactions'],
    );
    final item = await s.call(
      'post',
      '/plaid/exchange',
      token: who.access,
      body: {'public_token': publicToken},
    );
    return item.json['id']! as String;
  }

  Future<String> linkAndSync() async {
    final itemId = await link(server, ada);
    await server.call('post', '/plaid/items/$itemId/sync', token: ada.access);
    await server.call('post', '/plaid/items/$itemId/sync', token: ada.access);
    return itemId;
  }

  // The test clock is 2026-10-24 09:30 UTC, so Plaid's "today" (the date at UTC−12)
  // is 2026-10-23.
  Map<String, Object?> spotify({
    String? accountId,
    String date = '2026-10-23',
  }) => {
    'date_transacted': date,
    'date_posted': date,
    'amount': {'minor_units': 1599, 'currency': 'USD'},
    'description': 'SPOTIFY USA',
    'account_id': ?accountId,
  };

  Future<TestResponse> create(String itemId, List<Object?> transactions) =>
      server.call(
        'post',
        '/sandbox/items/$itemId/transactions',
        token: ada.access,
        body: {'transactions': transactions},
        validRequest: false,
      );

  test(
    'reset-login puts the Item into login_required on the next sync',
    () async {
      final itemId = await linkAndSync();
      final r = await server.call(
        'post',
        '/sandbox/items/$itemId/reset-login',
        token: ada.access,
      );
      expect(r.status, 204);
      final sync = await server.call(
        'post',
        '/plaid/items/$itemId/sync',
        token: ada.access,
      );
      expect(sync.status, 409);
      expect(sync.code, 'item_login_required');
      final item =
          (await server.call(
                'get',
                '/plaid/items',
                token: ada.access,
              )).list.single!
              as Map;
      expect(item['status'], 'login_required');
      expect(item['error_code'], 'ITEM_LOGIN_REQUIRED');
    },
  );

  test('fire-webhook accepts every code and refuses others', () async {
    final itemId = await linkAndSync();
    for (final code in [
      'SYNC_UPDATES_AVAILABLE',
      'DEFAULT_UPDATE',
      'RECURRING_TRANSACTIONS_UPDATE',
      'NEW_ACCOUNTS_AVAILABLE',
      'PENDING_DISCONNECT',
      'USER_PERMISSION_REVOKED',
      'LOGIN_REPAIRED',
      'ERROR',
    ]) {
      final r = await server.call(
        'post',
        '/sandbox/items/$itemId/fire-webhook',
        token: ada.access,
        body: {'webhook_code': code},
      );
      expect(r.status, 204, reason: code);
    }
    for (final body in [
      {'webhook_code': 'PENDING_EXPIRATION'},
      {'webhook_code': 'sync_updates_available'},
      <String, Object?>{},
      {'webhook_code': 'ERROR', 'error_code': 'X'},
    ]) {
      final r = await server.call(
        'post',
        '/sandbox/items/$itemId/fire-webhook',
        token: ada.access,
        body: body,
        validRequest: false,
      );
      expect(r.status, 400, reason: '$body');
    }
  });

  test(
    'created transactions arrive on the next sync, demo, in our sign',
    () async {
      final itemId = await linkAndSync();
      final accounts = (await server.call(
        'get',
        '/accounts',
        token: ada.access,
      )).list.cast<Map<String, Object?>>();
      final savings = accounts.firstWhere((a) => a['subtype'] == 'savings');
      final before =
          (await server.call(
                'get',
                '/transactions',
                token: ada.access,
              )).json['next_since']!
              as int;
      final r = await create(itemId, [
        spotify(),
        spotify(accountId: savings['id']! as String),
      ]);
      expect(r.status, 204, reason: '$r');
      await server.call('post', '/plaid/items/$itemId/sync', token: ada.access);
      final page = await server.call(
        'get',
        '/transactions?since=$before',
        token: ada.access,
      );
      final created = (page.json['transactions']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(created, hasLength(2));
      for (final t in created) {
        expect(t['source'], 'demo');
        expect(t['name'], 'SPOTIFY USA');
        expect(t['amount'], {'minor_units': -1599, 'currency': 'USD'});
        expect(t['date'], '2026-10-23');
      }
      final checking = accounts.firstWhere((a) => a['subtype'] == 'checking');
      expect(created.map((t) => t['account_id']), [
        checking['id'],
        savings['id'],
      ]);
    },
  );

  test(
    'create-transactions refuses what the contract and Plaid refuse',
    () async {
      final itemId = await linkAndSync();
      final cases = <List<Object?>, String>{
        []: 'transactions',
        List.filled(11, spotify()): 'transactions',
        [spotify(date: '2026-10-24')]: 'transactions[0].date_transacted',
        [spotify(date: '2024-10-22')]: 'transactions[0].date_posted',
        [spotify(accountId: 'nope')]: 'transactions[0].account_id',
        [
          {...spotify(), 'description': ''},
        ]: 'transactions[0].description',
        [
          {
            ...spotify(),
            'amount': {'minor_units': 1.5, 'currency': 'USD'},
          },
        ]: 'transactions[0].amount.minor_units',
        [
          {
            ...spotify(),
            'amount': {'minor_units': 1, 'currency': 'usd'},
          },
        ]: 'transactions[0].amount.currency',
        [
          {...spotify(), 'merchant': 'x'},
        ]: 'transactions[0].merchant',
        [
          {
            ...spotify(),
            'amount': {'minor_units': 1599, 'currency': 'EUR'},
          },
        ]: 'transactions[0].amount',
        [
          {...spotify(), 'date_posted': '2026-02-30'},
        ]: 'transactions[0].date_posted',
      };
      for (final MapEntry(key: body, value: field) in cases.entries) {
        final r = await create(itemId, body);
        expect(r.status, 400, reason: field);
        expect(
          [
            for (final e in r.json['errors']! as List<Object?>)
              (e! as Map)['field'],
          ],
          contains(field),
          reason: '$r',
        );
      }
    },
  );

  test(
    "the window runs from the UTC date minus 729 to Plaid's today",
    () async {
      final itemId = await linkAndSync();
      Future<int> status(String date) async =>
          (await create(itemId, [spotify(date: date)])).status;
      // 2026-10-24 09:30 UTC: the past bound is measured from the UTC date
      // (2026-10-24), strictly; the future bound is Plaid's today (2026-10-23).
      expect(await status('2024-10-24'), 400, reason: 'UTC date − 730');
      expect(await status('2024-10-25'), 204, reason: 'UTC date − 729');
      expect(await status('2026-10-23'), 204, reason: "Plaid's today");
      expect(await status('2026-10-24'), 400, reason: "Plaid's today + 1");
      // 13:00 UTC: Plaid's today has caught up with the UTC date.
      server.clock.advance(const Duration(hours: 3, minutes: 30));
      ada = await server.login();
      expect(await status('2026-10-24'), 204, reason: "Plaid's today");
      expect(await status('2026-10-25'), 400, reason: "Plaid's today + 1");
      expect(await status('2024-10-24'), 400, reason: 'UTC date − 730');
      expect(await status('2024-10-25'), 204, reason: 'UTC date − 729');
    },
  );

  test('a login-required Item refuses created transactions with 409', () async {
    final itemId = await linkAndSync();
    await server.call(
      'post',
      '/sandbox/items/$itemId/reset-login',
      token: ada.access,
    );
    final r = await create(itemId, [spotify()]);
    expect(r.status, 409);
    expect(r.code, 'item_login_required');
  });

  test("another user's Item is 404 and a removed Item 409", () async {
    final itemId = await linkAndSync();
    final eve = await server.register('eve@example.com');
    Future<List<TestResponse>> all(Session who) async => [
      await server.call(
        'post',
        '/sandbox/items/$itemId/reset-login',
        token: who.access,
      ),
      await server.call(
        'post',
        '/sandbox/items/$itemId/fire-webhook',
        token: who.access,
        body: {'webhook_code': 'DEFAULT_UPDATE'},
      ),
      await server.call(
        'post',
        '/sandbox/items/$itemId/transactions',
        token: who.access,
        body: {
          'transactions': [spotify()],
        },
      ),
    ];
    for (final r in await all(eve)) {
      expect(r.status, 404);
      expect(r.code, 'not_found');
    }
    await server.call(
      'delete',
      '/plaid/items/$itemId?history=keep',
      token: ada.access,
    );
    for (final r in await all(ada)) {
      expect(r.status, 409);
      expect(r.code, 'conflict');
    }
  });

  test('a server that cannot drive Sandbox answers 409 conflict', () async {
    final production = await TestServer.start(
      config: ServerConfig(
        jwtSecret: testConfig.jwtSecret,
        tokenEncryptionKey: testConfig.tokenEncryptionKey,
        argon2: testConfig.argon2,
        plaidEnv: 'production',
      ),
    );
    final user = await production.register();
    final itemId = await link(production, user);
    for (final (path, body) in [
      ('reset-login', null),
      ('fire-webhook', {'webhook_code': 'DEFAULT_UPDATE'}),
      (
        'transactions',
        {
          'transactions': [spotify()],
        },
      ),
    ]) {
      final r = await production.call(
        'post',
        '/sandbox/items/$itemId/$path',
        token: user.access,
        body: body,
      );
      expect(r.status, 409, reason: path);
      expect(r.code, 'conflict');
      expect(r.json['detail'], 'This server cannot drive Plaid Sandbox');
    }
  });
}
