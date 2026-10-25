// The Item operations of contract 0.3.0 with the fake client: refreshing an Item and its
// balances, unlinking with the history kept or deleted (the `removed` status), the
// Item's `error_code`, and the institution logo route.
import 'package:finance_tracker_server/server.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

const _package = 'dev.tarnan.financetracker';

void main() {
  late TestServer server;
  late Session ada;

  setUp(() async {
    server = await TestServer.start();
    ada = await server.register();
  });

  Future<String> link([Session? who]) async {
    final publicToken = await server.plaid.sandboxPublicTokenCreate(
      institutionId: 'ins_109508',
      products: const ['transactions'],
    );
    final item = await server.call(
      'post',
      '/plaid/exchange',
      token: (who ?? ada).access,
      body: {'public_token': publicToken},
    );
    expect(item.status, 201);
    expect(item.json['error_code'], isNull);
    return item.json['id']! as String;
  }

  Future<TestResponse> post(String path, [Session? who]) =>
      server.call('post', path, token: (who ?? ada).access);

  Future<String> linkAndSync() async {
    final itemId = await link();
    expect(
      (await post('/plaid/items/$itemId/sync')).json['status'],
      'not_ready',
    );
    expect(
      (await post('/plaid/items/$itemId/sync')).json['status'],
      'completed',
    );
    return itemId;
  }

  Future<String> accessTokenOf(String itemId) async {
    final row = await server.app.db.read(
      (tx) => tx.first(
        'SELECT access_token_ciphertext, access_token_nonce FROM items WHERE id = ?',
        [itemId],
      ),
    );
    return server.app.items.cipher.open(
      row!['access_token_ciphertext'] as List<int>,
      nonce: row['access_token_nonce'] as List<int>,
      itemId: itemId,
    );
  }

  Future<List<Map<String, Object?>>> get(String path, [Session? who]) async {
    final r = await server.call('get', path, token: (who ?? ada).access);
    expect(r.status, 200, reason: '$r');
    final body = r.body;
    return (body is Map ? body['transactions']! as List<Object?> : r.list)
        .cast();
  }

  test(
    'refresh calls Plaid, answers started and syncs in the background',
    () async {
      final itemId = await linkAndSync();
      final token = await accessTokenOf(itemId);
      final calls = <String>[];
      server.plaid.onCall = (method) async => calls.add(method);
      final first = (await get('/transactions')).first;
      server.plaid.modifyTransaction(
        token,
        (await server.app.db.read(
              (tx) => tx.first(
                'SELECT plaid_transaction_id FROM transactions WHERE id = ?',
                [first['id']],
              ),
            ))!['plaid_transaction_id']!
            as String,
        name: 'REFRESHED',
      );
      final r = await post('/plaid/items/$itemId/refresh');
      expect(r.status, 202);
      expect(r.json, {
        'status': 'started',
        'added': 0,
        'modified': 0,
        'removed': 0,
        'next_cursor_saved': false,
      });
      await pumpEventQueue();
      expect(calls.take(3), [
        'transactionsRefresh',
        'accountsGet',
        'transactionsSync',
      ]);
      final changed = await get('/transactions?since=${first['sync_version']}');
      expect(changed.map((t) => t['name']), contains('REFRESHED'));
    },
  );

  test(
    'login required on refresh and balances is 409 and sets error_code',
    () async {
      final itemId = await linkAndSync();
      await server.plaid.sandboxItemResetLogin(await accessTokenOf(itemId));
      for (final path in ['refresh', 'balances']) {
        final r = await post('/plaid/items/$itemId/$path');
        expect(r.status, 409, reason: path);
        expect(r.code, 'item_login_required');
      }
      final item = (await get('/plaid/items')).single;
      expect(item['status'], 'login_required');
      expect(item['error_code'], 'ITEM_LOGIN_REQUIRED');

      server.plaid.repairLogin(await accessTokenOf(itemId));
      expect((await post('/plaid/items/$itemId/sync')).status, 202);
      final repaired = (await get('/plaid/items')).single;
      expect(repaired['status'], 'healthy');
      expect(repaired['error_code'], isNull);
    },
  );

  test('balances stores what Plaid reports and answers the accounts', () async {
    final itemId = await link();
    // Before any sync the Item has no accounts; the balance call brings them.
    final r = await post('/plaid/items/$itemId/balances');
    expect(r.status, 200, reason: '$r');
    expect(r.list, hasLength(3));
    server.clock.advance(const Duration(minutes: 10));
    final again = await post('/plaid/items/$itemId/balances');
    expect(again.status, 200, reason: '$again');
    expect(
      [for (final a in again.list) (a! as Map)['id']],
      [for (final a in r.list) (a! as Map)['id']],
    );
    for (final a in again.list.cast<Map<String, Object?>>()) {
      expect(a['item_id'], itemId);
      expect(a['balances_as_of'], '2026-10-24T09:40:00.000Z');
    }
    expect(await get('/accounts'), again.list);
  });

  test(
    'unlinking with history kept keeps the data and marks the Item removed',
    () async {
      final itemId = await linkAndSync();
      final accounts = await get('/accounts');
      final transactions = await get('/transactions');
      final r = await server.call(
        'delete',
        '/plaid/items/$itemId?history=keep',
        token: ada.access,
      );
      expect(r.status, 204);
      expect(server.plaid.liveItemCount, 0);
      final item = (await get('/plaid/items')).single;
      expect(item['status'], 'removed');
      expect(item['error_code'], isNull);
      expect(await get('/accounts'), accounts);
      expect(await get('/transactions'), transactions);

      for (final path in [
        '/plaid/items/$itemId/sync',
        '/plaid/items/$itemId/refresh',
        '/plaid/items/$itemId/balances',
      ]) {
        final refused = await post(path);
        expect(refused.status, 409, reason: path);
        expect(refused.code, 'conflict');
      }
      final update = await server.call(
        'post',
        '/plaid/items/$itemId/update-link-token',
        token: ada.access,
        body: {'android_package_name': _package},
      );
      expect(update.status, 404);

      // Keeping again changes nothing and calls Plaid no more.
      final calls = <String>[];
      server.plaid.onCall = (method) async => calls.add(method);
      expect(
        (await server.call(
          'delete',
          '/plaid/items/$itemId?history=keep',
          token: ada.access,
        )).status,
        204,
      );
      expect((await get('/plaid/items')).single['status'], 'removed');

      // Deleting the kept history drops it, still without calling Plaid.
      expect(
        (await server.call(
          'delete',
          '/plaid/items/$itemId?history=delete',
          token: ada.access,
        )).status,
        204,
      );
      expect(calls, isEmpty);
      expect(await get('/plaid/items'), isEmpty);
      expect(await get('/accounts'), isEmpty);
      final tombstones = await get('/transactions');
      expect(tombstones, hasLength(transactions.length));
      expect(tombstones.every((t) => t['deleted_at'] != null), isTrue);
    },
  );

  test(
    'a login-required answer to a call in flight does not undo a kept unlink',
    () async {
      final itemId = await linkAndSync();
      final accounts = await get('/accounts');
      // The sync's Plaid call is held until the Item has been unlinked with its history
      // kept; then Plaid answers ITEM_LOGIN_REQUIRED.
      var armed = true;
      server.plaid.onCall = (method) async {
        if (method != 'transactionsSync' || !armed) return;
        armed = false;
        final unlinked = await server.call(
          'delete',
          '/plaid/items/$itemId?history=keep',
          token: ada.access,
        );
        expect(unlinked.status, 204);
      };
      server.plaid.failNext(
        'transactionsSync',
        const PlaidException('ITEM_ERROR', 'ITEM_LOGIN_REQUIRED'),
      );
      final sync = await post('/plaid/items/$itemId/sync');
      expect(sync.status, 409);
      expect(sync.code, 'item_login_required');

      final item = (await get('/plaid/items')).single;
      expect(item['status'], 'removed');
      expect(item['error_code'], isNull);
      expect(await get('/accounts'), accounts);
      expect(
        (await server.call(
          'delete',
          '/plaid/items/$itemId?history=delete',
          token: ada.access,
        )).status,
        204,
      );
    },
  );

  test(
    'unlinking by default deletes the accounts and tombstones the transactions',
    () async {
      final itemId = await linkAndSync();
      final count = (await get('/transactions')).length;
      expect(
        (await server.call(
          'delete',
          '/plaid/items/$itemId',
          token: ada.access,
        )).status,
        204,
      );
      expect(await get('/plaid/items'), isEmpty);
      expect(await get('/accounts'), isEmpty);
      final tombstones = await get('/transactions');
      expect(tombstones, hasLength(count));
      expect(tombstones.every((t) => t['deleted_at'] != null), isTrue);
    },
  );

  test('an unknown history is 400', () async {
    final itemId = await link();
    final r = await server.call(
      'delete',
      '/plaid/items/$itemId?history=archive',
      token: ada.access,
    );
    expect(r.status, 400);
    expect(r.json['errors'], [
      {'field': 'history', 'message': 'must be keep or delete'},
    ]);
    expect(server.plaid.liveItemCount, 1);
  });

  test('account deletion after a kept unlink deletes everything', () async {
    final itemId = await linkAndSync();
    await server.call(
      'delete',
      '/plaid/items/$itemId?history=keep',
      token: ada.access,
    );
    expect((await server.call('delete', '/me', token: ada.access)).status, 204);
    for (final table in ['items', 'accounts', 'transactions']) {
      expect(await server.rowsOf(table, ada.userId), 0, reason: table);
    }
  });

  test('the logo route serves the stored PNG and the Item points at it', () async {
    final itemId = await link();
    const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3];
    await server.app.db.read(
      (tx) => tx.execute(
        'UPDATE items SET institution_logo = ?, institution_primary_color = ? '
        'WHERE id = ?',
        [png, 0xFF0075A3, itemId],
      ),
    );
    final institution =
        (await get('/plaid/items')).single['institution']!
            as Map<String, Object?>;
    expect(
      institution['logo_url'],
      'http://localhost/v1/institutions/ins_109508/logo',
    );
    expect(institution['primary_color'], 0xFF0075A3);
    final logo = await server.call(
      'get',
      '/institutions/ins_109508/logo',
      token: ada.access,
    );
    expect(logo.status, 200);
    expect(logo.headers['content-type'], 'image/png');
    expect(logo.body, png);

    final eve = await server.register('eve@example.com');
    final foreign = await server.call(
      'get',
      '/institutions/ins_109508/logo',
      token: eve.access,
    );
    expect(foreign.status, 404);
    expect(foreign.code, 'not_found');
    final unknown = await server.call(
      'get',
      '/institutions/ins_1/logo',
      token: ada.access,
    );
    expect(unknown.status, 404);
  });

  test('an institution without a logo is 404 and logo_url null', () async {
    await link();
    final institution =
        (await get('/plaid/items')).single['institution']!
            as Map<String, Object?>;
    expect(institution['logo_url'], isNull);
    final r = await server.call(
      'get',
      '/institutions/ins_109508/logo',
      token: ada.access,
    );
    expect(r.status, 404);
  });

  test("another user's Item is 404 on refresh and balances", () async {
    final itemId = await link();
    final eve = await server.register('eve@example.com');
    for (final path in ['refresh', 'balances']) {
      final r = await post('/plaid/items/$itemId/$path', eve);
      expect(r.status, 404, reason: path);
      expect(r.code, 'not_found');
    }
  });
}
