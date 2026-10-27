// The Plaid proxy and the data endpoints with the fake client: link token, exchange, a
// NOT_READY sync, a completed sync, then accounts, transactions, liabilities and recurring
// streams visible with source demo and increasing versions; and the paths around them.
import 'dart:convert';

import 'package:finance_tracker_server/server.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/plaid/item_service.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
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
    final s = who ?? ada;
    final token = await server.call(
      'post',
      '/plaid/link-token',
      token: s.access,
      body: {'android_package_name': _package},
    );
    expect(token.status, 200);
    final publicToken = await server.plaid.sandboxPublicTokenCreate(
      institutionId: 'ins_109508',
      products: const ['transactions'],
    );
    final item = await server.call(
      'post',
      '/plaid/exchange',
      token: s.access,
      body: {'public_token': publicToken},
    );
    expect(item.status, 201);
    expect(
      item.json['institution'],
      containsPair('name', 'First Platypus Bank'),
    );
    expect(item.json['status'], 'healthy');
    expect(item.json['last_successful_sync_at'], isNull);
    return item.json['id']! as String;
  }

  Future<TestResponse> sync(String itemId, [Session? who]) => server.call(
    'post',
    '/plaid/items/$itemId/sync',
    token: (who ?? ada).access,
  );

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

  Future<List<Map<String, Object?>>> transactions({int since = 0}) async {
    final r = await server.call(
      'get',
      '/transactions?since=$since',
      token: ada.access,
    );
    expect(r.status, 200);
    return (r.json['transactions']! as List<Object?>).cast();
  }

  test('link, NOT_READY, sync, then the data with source demo', () async {
    final itemId = await link();

    final first = await sync(itemId);
    expect(first.status, 202);
    expect(first.json, {
      'status': 'not_ready',
      'added': 0,
      'modified': 0,
      'removed': 0,
      'next_cursor_saved': false,
    });
    expect(
      (await server.call('get', '/accounts', token: ada.access)).list,
      isEmpty,
    );

    final second = await sync(itemId);
    expect(second.json, {
      'status': 'completed',
      'added': 12,
      'modified': 0,
      'removed': 0,
      'next_cursor_saved': true,
    });

    final items = await server.call('get', '/plaid/items', token: ada.access);
    expect(
      items.list.single,
      containsPair('last_successful_sync_at', isNotNull),
    );

    final accounts = (await server.call(
      'get',
      '/accounts',
      token: ada.access,
    )).list.cast<Map<String, Object?>>();
    expect(
      [for (final a in accounts) a['name']],
      ['Plaid Checking', 'Plaid Saving', 'Plaid Credit Card'],
    );
    expect([for (final a in accounts) a['display_order']], [0, 1, 2]);
    final credit = accounts[2];
    expect(credit['type'], 'credit');
    // Plaid reports the card owing 410.27; stored in the app's sign.
    expect(credit['current_balance'], {
      'minor_units': -41027,
      'currency': 'USD',
    });
    expect(credit['credit_limit'], {'minor_units': 200000, 'currency': 'USD'});
    expect(credit['item_id'], itemId);

    final txns = await transactions();
    expect(txns, hasLength(12));
    expect({for (final t in txns) t['source']}, {'demo'});
    final versions = [for (final t in txns) t['sync_version']! as int];
    expect(versions, [for (var v = 1; v <= 12; v++) v]);
    final netflix = txns.firstWhere((t) => t['name'] == 'NETFLIX.COM');
    expect(netflix['amount'], {'minor_units': -1549, 'currency': 'USD'});
    expect(netflix['account_id'], credit['id']);
    expect(netflix['merchant_name'], 'Netflix');
    expect(netflix['plaid_primary_category'], 'ENTERTAINMENT');
    final payroll = txns.firstWhere((t) => t['name'] == 'ACME CORP PAYROLL');
    expect(payroll['amount'], {'minor_units': 250000, 'currency': 'USD'});
    expect(txns.where((t) => t['pending'] == true), hasLength(1));

    final liabilities = await server.call(
      'get',
      '/liabilities',
      token: ada.access,
    );
    final card = (liabilities.json['credit']! as List<Object?>).single! as Map;
    expect(card['account_id'], credit['id']);
    expect(card['minimum_payment_amount'], {
      'minor_units': 2500,
      'currency': 'USD',
    });
    expect(
      (card['aprs']! as List<Object?>).single,
      containsPair('apr_percentage', '12.5'),
    );
    expect(card['source'], 'demo');
    expect(liabilities.json['mortgage'], isEmpty);

    final recurring = await server.call('get', '/recurring', token: ada.access);
    final stream = recurring.list.single! as Map<String, Object?>;
    expect(stream['merchant_name'], 'Netflix');
    expect(stream['cadence'], 'monthly');
    expect(stream['average_amount'], {'minor_units': -1549, 'currency': 'USD'});
    expect(stream['source'], 'demo');
    expect(stream['account_id'], credit['id']);
    // Plaid's member ids, served as the server's own transaction ids.
    expect(stream['transaction_ids'], [netflix['id']]);

    final holdings = await server.call(
      'get',
      '/investments/holdings',
      token: ada.access,
    );
    expect(holdings.json, {'holdings': <Object?>[], 'securities': <Object?>[]});
    final investments = await server.call(
      'get',
      '/investments/transactions',
      token: ada.access,
    );
    expect(investments.json['investment_transactions'], isEmpty);

    // Nothing the fake client produced is stored as plaid.
    await server.app.db.read((tx) {
      for (final table in [
        'accounts',
        'transactions',
        'recurring_streams',
        'liabilities',
        'securities',
        'holdings',
        'investment_transactions',
      ]) {
        expect(
          tx.first(
            "SELECT COUNT(*) AS n FROM $table WHERE source <> 'demo'",
          )!['n'],
          0,
          reason: table,
        );
      }
    });

    // A third sync finds nothing new and keeps the stream's id.
    final third = await sync(itemId);
    expect(third.json['added'], 0);
    final again = await server.call('get', '/recurring', token: ada.access);
    expect((again.list.single! as Map)['id'], stream['id']);

    // A member the server does not hold is left out; the others keep Plaid's order.
    await server.app.db.transaction((tx) async {
      final plaidId = tx.first(
        'SELECT plaid_transaction_id AS p FROM transactions WHERE id = ?',
        [netflix['id']],
      )!['p'];
      final payroll = tx.first(
        'SELECT plaid_transaction_id AS p FROM transactions WHERE id = ?',
        [txns.firstWhere((t) => t['name'] == 'ACME CORP PAYROLL')['id']],
      )!['p'];
      tx.execute('UPDATE recurring_streams SET plaid_transaction_ids = ?', [
        jsonEncode([payroll, 'not-held', plaidId]),
      ]);
    });
    final members = await server.call('get', '/recurring', token: ada.access);
    expect((members.list.single! as Map)['transaction_ids'], [
      txns.firstWhere((t) => t['name'] == 'ACME CORP PAYROLL')['id'],
      netflix['id'],
    ]);
  });

  test(
    'created, modified and removed transactions arrive by version',
    () async {
      final itemId = await link();
      await sync(itemId);
      await sync(itemId);
      final token = await accessTokenOf(itemId);
      final before = await transactions();
      final last = before.last['sync_version']! as int;

      await server.plaid.sandboxTransactionsCreate(token, [
        (
          dateTransacted: LocalDate(2026, 10, 23),
          datePosted: LocalDate(2026, 10, 24),
          amount: Money(899, 'USD'),
          description: 'SPOTIFY',
          accountId: null,
        ),
      ]);
      final plaidIds = await server.app.db.read(
        (tx) => {
          for (final r in tx.select(
            'SELECT id, plaid_transaction_id FROM transactions',
          ))
            r['plaid_transaction_id'] as String: r['id'] as String,
        },
      );
      final chipotle = plaidIds.keys.firstWhere((k) => k.endsWith('-tx12'));
      final atm = plaidIds.keys.firstWhere((k) => k.endsWith('-tx11'));
      server.plaid.modifyTransaction(token, chipotle, pending: false);
      server.plaid.removeTransaction(token, atm);

      final run = await sync(itemId);
      expect(run.json, containsPair('added', 1));
      expect(run.json, containsPair('modified', 1));
      expect(run.json, containsPair('removed', 1));

      final changed = await transactions(since: last);
      expect(changed, hasLength(3));
      expect(
        [for (final t in changed) t['sync_version']],
        [last + 1, last + 2, last + 3],
      );
      final spotify = changed.firstWhere((t) => t['name'] == 'SPOTIFY');
      expect(spotify['amount'], {'minor_units': -899, 'currency': 'USD'});
      expect(spotify['source'], 'demo');
      final posted = changed.firstWhere((t) => t['id'] == plaidIds[chipotle]);
      expect(posted['pending'], isFalse);
      final removed = changed.firstWhere((t) => t['id'] == plaidIds[atm]);
      expect(removed['deleted_at'], isNotNull);

      final empty = await server.call(
        'get',
        '/transactions?since=${last + 3}',
        token: ada.access,
      );
      expect(empty.json, {
        'transactions': <Object?>[],
        'next_since': last + 3,
        'has_more': false,
      });
    },
  );

  test('pages by limit, and a since beyond the version is 409', () async {
    final itemId = await link();
    await sync(itemId);
    await sync(itemId);
    final page = await server.call(
      'get',
      '/transactions?since=0&limit=5',
      token: ada.access,
    );
    expect(page.json['transactions'], hasLength(5));
    expect(page.json['next_since'], 5);
    expect(page.json['has_more'], isTrue);
    final rest = await server.call(
      'get',
      '/transactions?since=10&limit=5',
      token: ada.access,
    );
    expect(rest.json['transactions'], hasLength(2));
    expect(rest.json['has_more'], isFalse);
    for (final path in ['/transactions', '/investments/transactions']) {
      final beyond = await server.call(
        'get',
        '$path?since=13',
        token: ada.access,
      );
      expect(beyond.status, 409, reason: path);
      expect(beyond.code, 'sync_cursor_invalid');
      final bad = await server.call('get', '$path?limit=0', token: ada.access);
      expect(bad.status, 400);
    }
  });

  test('a sync run applies all pages or none', () async {
    final itemId = await link();
    await sync(itemId);
    server.plaid.failNext(
      'transactionsSync',
      const PlaidException(
        'TRANSACTIONS_ERROR',
        'TRANSACTIONS_SYNC_MUTATION_DURING_PAGINATION',
      ),
    );
    final restarted = await sync(itemId);
    expect(restarted.json['added'], 12);

    // A failure on a later page applies nothing, cursor included.
    final other = await link();
    await sync(other);
    final paged = ItemService(
      db: server.app.db,
      plaid: server.plaid,
      cipher: server.app.items.cipher,
      now: server.clock.call,
      syncPageSize: 5,
    );
    server.plaid.failNext(
      'transactionsSync',
      const PlaidException('API_ERROR', 'INTERNAL_SERVER_ERROR'),
      skip: 1,
    );
    await expectLater(
      paged.sync(ada.userId, other),
      throwsA(
        isA<ProblemException>().having(
          (e) => e.code,
          'code',
          ProblemCode.plaidError,
        ),
      ),
    );
    expect(await transactions(since: 12), isEmpty);
    final cursor = await server.app.db.read(
      (tx) =>
          tx.first('SELECT cursor FROM items WHERE id = ?', [other])!['cursor'],
    );
    expect(cursor, isNull);
    expect((await sync(other)).json['added'], 12);
  });

  test(
    'a failed secondary product is skipped and logged; the run completes',
    () async {
      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
      final itemId = await link();
      await sync(itemId);
      server.plaid.failNext(
        'liabilitiesGet',
        const PlaidException('INVALID_INPUT', 'PRODUCT_NOT_READY'),
      );
      final run = await sync(itemId);
      expect(run.status, 202);
      expect(run.json, containsPair('status', 'completed'));
      expect(run.json, containsPair('added', 12));
      expect(await transactions(), hasLength(12));
      final liabilities = await server.call(
        'get',
        '/liabilities',
        token: ada.access,
      );
      expect(liabilities.json['credit'], isEmpty);
      expect(
        (await server.call('get', '/recurring', token: ada.access)).list,
        hasLength(1),
      );
      final skipped = records
          .map((r) => r.object)
          .whereType<LogEvent>()
          .where((e) => e.event == 'item_sync_product_skipped')
          .single;
      expect(skipped.fields, containsPair('product', 'liabilities'));
      expect(skipped.fields, containsPair('code', 'PRODUCT_NOT_READY'));
      // The next run fetches it.
      await sync(itemId);
      final again = await server.call('get', '/liabilities', token: ada.access);
      expect(again.json['credit'], hasLength(1));
    },
  );

  test('two concurrent syncs of one Item apply its pages once', () async {
    final itemId = await link();
    await sync(itemId);
    final runs = await Future.wait([sync(itemId), sync(itemId)]);
    expect([for (final r in runs) r.json['added']]..sort(), [0, 12]);
    final txns = await transactions();
    expect(txns, hasLength(12));
    expect(txns.last['sync_version'], 12);
  });

  test('a sync whose Item goes away while Plaid is called is 404', () async {
    final itemId = await link();
    await sync(itemId);
    server.plaid.onCall = (method) async {
      if (method != 'transactionsRecurringGet') return;
      server.plaid.onCall = null;
      final deleted = await server.call(
        'delete',
        '/plaid/items/$itemId',
        token: ada.access,
      );
      expect(deleted.status, 204);
    };
    final r = await sync(itemId);
    expect(r.status, 404);
    expect(r.code, 'not_found');
    expect(await transactions(), isEmpty);
  });

  test('an Item Plaid no longer knows counts as removed', () async {
    final itemId = await link();
    await server.plaid.removeItem(await accessTokenOf(itemId));
    final r = await server.call(
      'delete',
      '/plaid/items/$itemId',
      token: ada.access,
    );
    expect(r.status, 204);
    expect(
      (await server.call('get', '/plaid/items', token: ada.access)).list,
      isEmpty,
    );
  });

  test(
    'a failed /item/get after the exchange removes the new Item at Plaid',
    () async {
      final before = server.plaid.liveItemCount;
      server.plaid.failNext(
        'getItem',
        const PlaidException('API_ERROR', 'INTERNAL_SERVER_ERROR'),
      );
      final r = await server.call(
        'post',
        '/plaid/exchange',
        token: ada.access,
        body: {'public_token': 'public-sandbox-x'},
      );
      expect(r.status, 502);
      expect(server.plaid.liveItemCount, before);
      expect(
        (await server.call('get', '/plaid/items', token: ada.access)).list,
        isEmpty,
      );
    },
  );

  test(
    'an exchange whose device is removed meanwhile is 401 and leaves no Item',
    () async {
      final other = await server.login();
      server.plaid.onCall = (method) async {
        if (method != 'getItem') return;
        server.plaid.onCall = null;
        final removed = await server.call(
          'delete',
          '/devices/${ada.deviceId}',
          token: other.access,
        );
        expect(removed.status, 204);
      };
      final r = await server.call(
        'post',
        '/plaid/exchange',
        token: ada.access,
        body: {'public_token': 'public-sandbox-x'},
      );
      expect(r.status, 401);
      expect(r.code, 'token_revoked');
      expect(server.plaid.liveItemCount, 0);
      expect(
        (await server.call('get', '/plaid/items', token: other.access)).list,
        isEmpty,
      );
    },
  );

  test('every data endpoint hides an Item already removed at Plaid', () async {
    final kept = await link();
    await sync(kept);
    await sync(kept);
    final removed = await link();
    await sync(removed);
    await sync(removed);
    // A deletion that stopped part-way: removed at Plaid, rows still stored.
    await server.app.items.removeAtPlaid(removed, await accessTokenOf(removed));
    final accounts = (await server.call(
      'get',
      '/accounts',
      token: ada.access,
    )).list;
    expect(accounts, hasLength(3));
    expect({for (final a in accounts) (a! as Map)['item_id']}, {kept});
    final txns = await transactions();
    expect(txns, hasLength(12));
    final liabilities = await server.call(
      'get',
      '/liabilities',
      token: ada.access,
    );
    expect(liabilities.json['credit'], hasLength(1));
    expect(
      (await server.call('get', '/recurring', token: ada.access)).list,
      hasLength(1),
    );
    final investments = await server.call(
      'get',
      '/investments/transactions',
      token: ada.access,
    );
    expect(investments.json['investment_transactions'], isEmpty);
  });

  test('pages /transactions/sync by count', () async {
    final itemId = await link();
    await sync(itemId);
    final small = ItemService(
      db: server.app.db,
      plaid: server.plaid,
      cipher: server.app.items.cipher,
      now: server.clock.call,
      syncPageSize: 5,
    );
    final run = await small.sync(ada.userId, itemId);
    expect(run['added'], 12);
    expect(await transactions(), hasLength(12));
  });

  test(
    'login required is 409 and marks the Item; update mode repairs it',
    () async {
      final itemId = await link();
      await sync(itemId);
      await sync(itemId);
      final token = await accessTokenOf(itemId);
      await server.plaid.sandboxItemResetLogin(token);
      final r = await sync(itemId);
      expect(r.status, 409);
      expect(r.code, 'item_login_required');
      final items = await server.call('get', '/plaid/items', token: ada.access);
      expect((items.list.single! as Map)['status'], 'login_required');

      final update = await server.call(
        'post',
        '/plaid/items/$itemId/update-link-token',
        token: ada.access,
        body: {'android_package_name': _package},
      );
      expect(update.status, 200);
      final viaLink = await server.call(
        'post',
        '/plaid/link-token',
        token: ada.access,
        body: {'android_package_name': _package, 'update_item_id': itemId},
      );
      expect(viaLink.status, 200);

      server.plaid.repairLogin(token);
      expect((await sync(itemId)).status, 202);
      final healthy = await server.call(
        'get',
        '/plaid/items',
        token: ada.access,
      );
      expect((healthy.list.single! as Map)['status'], 'healthy');
    },
  );

  test("another user's Item is 404 everywhere", () async {
    final itemId = await link();
    final eve = await server.register('eve@example.com');
    for (final (method, path, body) in [
      ('post', '/plaid/items/$itemId/sync', null),
      ('delete', '/plaid/items/$itemId', null),
      (
        'post',
        '/plaid/items/$itemId/update-link-token',
        {'android_package_name': _package},
      ),
      (
        'post',
        '/plaid/link-token',
        {'android_package_name': _package, 'update_item_id': itemId},
      ),
    ]) {
      final r = await server.call(method, path, token: eve.access, body: body);
      expect(r.status, 404, reason: path);
      expect(r.code, 'not_found');
    }
    expect(
      (await server.call('get', '/plaid/items', token: eve.access)).list,
      isEmpty,
    );
  });

  test('Plaid failures are 502, and its rate limit 429', () async {
    server.plaid.failNext(
      'exchangePublicToken',
      const PlaidException('INVALID_INPUT', 'INVALID_PUBLIC_TOKEN'),
    );
    final r = await server.call(
      'post',
      '/plaid/exchange',
      token: ada.access,
      body: {'public_token': 'public-sandbox-x'},
    );
    expect(r.status, 502);
    expect(r.code, 'plaid_error');
    server.plaid.failNext(
      'createLinkToken',
      const PlaidException('RATE_LIMIT_EXCEEDED', 'RATE_LIMIT'),
    );
    final limited = await server.call(
      'post',
      '/plaid/link-token',
      token: ada.access,
      body: {'android_package_name': _package},
    );
    expect(limited.status, 429);
    expect(limited.headers['retry-after'], '60');
  });

  test('an explicit null update_item_id is 400', () async {
    final r = await server.call(
      'post',
      '/plaid/link-token',
      token: ada.access,
      body: {'android_package_name': _package, 'update_item_id': null},
      validRequest: false,
    );
    expect(r.status, 400);
    expect(
      (r.json['errors']! as List<Object?>).single,
      containsPair('field', 'update_item_id'),
    );
  });

  test('a bad package name is 400', () async {
    final r = await server.call(
      'post',
      '/plaid/link-token',
      token: ada.access,
      body: {'android_package_name': 'not a package'},
      validRequest: false,
    );
    expect(r.status, 400);
  });

  test(
    'deleting an Item tombstones its transactions and removes the rest',
    () async {
      final itemId = await link();
      await sync(itemId);
      await sync(itemId);
      final r = await server.call(
        'delete',
        '/plaid/items/$itemId',
        token: ada.access,
      );
      expect(r.status, 204);
      expect(
        (await server.call('get', '/plaid/items', token: ada.access)).list,
        isEmpty,
      );
      expect(
        (await server.call('get', '/accounts', token: ada.access)).list,
        isEmpty,
      );
      expect(
        (await server.call('get', '/recurring', token: ada.access)).list,
        isEmpty,
      );
      final tombstones = await transactions(since: 12);
      expect(tombstones, hasLength(12));
      expect(tombstones.every((t) => t['deleted_at'] != null), isTrue);
      final again = await server.call(
        'delete',
        '/plaid/items/$itemId',
        token: ada.access,
      );
      expect(again.status, 404);
    },
  );

  test('a failed Item removal changes nothing', () async {
    final itemId = await link();
    server.plaid.failNext(
      'removeItem',
      const PlaidException('API_ERROR', 'INTERNAL_SERVER_ERROR'),
      times: 3,
    );
    final r = await server.call(
      'delete',
      '/plaid/items/$itemId',
      token: ada.access,
    );
    expect(r.status, 502);
    expect(
      (await server.call('get', '/plaid/items', token: ada.access)).list,
      hasLength(1),
    );
  });

  test('the access token is stored encrypted', () async {
    final itemId = await link();
    final token = await accessTokenOf(itemId);
    expect(token, startsWith('access-sandbox-fake-'));
    final raw = await server.app.db.read(
      (tx) => tx.first('SELECT * FROM items WHERE id = ?', [itemId])!,
    );
    for (final value in raw.values) {
      if (value is String) expect(value, isNot(contains(token)));
      if (value is List<int>) {
        expect(String.fromCharCodes(value), isNot(contains('access-sandbox')));
      }
    }
  });

  test('the webhook receiver answers 401 webhook_unverified', () async {
    final r = await server.call(
      'post',
      '/webhooks/plaid',
      body: {'webhook_type': 'TRANSACTIONS'},
      headers: {'plaid-verification': 'x.y.z'},
    );
    expect(r.status, 401);
    expect(r.code, 'webhook_unverified');
  });
}
