// DELETE /me: every Item removed at Plaid first, with retries; nothing deleted unless all
// removals succeed; then every row of the user gone and every session ended.
import 'dart:async';

import 'package:finance_tracker_server/server.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  late TestServer server;
  late Session ada, eve;
  late String itemA, itemB;

  Future<String> linkAndSync(Session s) async {
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
    final id = item.json['id']! as String;
    await server.call('post', '/plaid/items/$id/sync', token: s.access);
    await server.call('post', '/plaid/items/$id/sync', token: s.access);
    return id;
  }

  Future<Map<String, int>> census(String userId) async {
    final tables = await server.app.db.read(
      (tx) => [
        for (final r in tx.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT IN ('schema_migrations', 'sqlite_sequence')",
        ))
          r['name'] as String,
      ],
    );
    return {for (final t in tables) t: await server.rowsOf(t, userId)};
  }

  setUp(() async {
    server = await TestServer.start();
    ada = await server.register();
    await server.login();
    eve = await server.register('eve@example.com');
    itemA = await linkAndSync(ada);
    itemB = await linkAndSync(ada);
    await linkAndSync(eve);
    await server.call(
      'post',
      '/sync/push',
      token: ada.access,
      body: {
        'entries': [
          {
            'entity_type': 'category',
            'entity_id': 'c1',
            'operation': 'create',
            'payload': {'name': 'Food'},
            'hlc':
                '${server.clock.value.millisecondsSinceEpoch.toString().padLeft(15, '0')}'
                '-00000-${ada.deviceId}',
            'device_id': ada.deviceId,
          },
        ],
      },
    );
  });

  test('deletes every row of the user and nothing of anyone else', () async {
    final eveBefore = await census(eve.userId);
    final before = await census(ada.userId);
    expect(before['transactions'], 24);
    expect(before['change_log'], 1);
    expect(before['devices'], 2);

    final r = await server.call('delete', '/me', token: ada.access);
    expect(r.status, 204);

    final after = await census(ada.userId);
    expect(after.values.toSet(), {0}, reason: '$after');
    expect(await census(eve.userId), eveBefore);
    expect(
      (await server.call('get', '/me', token: ada.access)).code,
      'token_revoked',
    );
    final login = await server.call(
      'post',
      '/auth/login',
      body: {
        'email': 'ada@example.com',
        'password': 'correct horse battery',
        'device_name': 'X',
      },
    );
    expect(login.status, 401);
  });

  test('a transient Plaid failure is retried', () async {
    server.plaid.failNext(
      'removeItem',
      const PlaidException('API_ERROR', 'INTERNAL_SERVER_ERROR'),
      times: 2,
    );
    final r = await server.call('delete', '/me', token: ada.access);
    expect(r.status, 204);
  });

  test(
    'a permanent failure is 502 and deletes nothing; a retry finishes',
    () async {
      // The first Item is removed at Plaid; then every attempt at the second fails.
      final before = await census(ada.userId);
      final items = await server.app.items.itemsToRemove(ada.userId);
      await server.app.items.removeAtPlaid(
        items.first.id,
        items.first.accessToken,
      );
      server.plaid.failNext(
        'removeItem',
        const PlaidException('API_ERROR', 'INTERNAL_SERVER_ERROR'),
        times: 3,
      );
      final r = await server.call('delete', '/me', token: ada.access);
      expect(r.status, 502);
      expect(r.code, 'plaid_error');
      final after = await census(ada.userId);
      expect(after, before, reason: 'no row was deleted');
      expect((await server.call('get', '/me', token: ada.access)).status, 200);
      // The Item already removed at Plaid is hidden and skipped on the retry.
      final listed = await server.call(
        'get',
        '/plaid/items',
        token: ada.access,
      );
      expect(listed.list, hasLength(1));
      expect({itemA, itemB}.difference({(listed.list.single! as Map)['id']}), {
        items.first.id,
      });

      final retry = await server.call('delete', '/me', token: ada.access);
      expect(retry.status, 204);
      expect((await census(ada.userId))['users'], 0);
    },
  );

  test('an Item linked while the deletion retries is removed too', () async {
    var linkedDuringRetry = '';
    server.plaid.failNext(
      'removeItem',
      const PlaidException('API_ERROR', 'INTERNAL_SERVER_ERROR'),
    );
    server.onDelay = (_) async {
      server.onDelay = null;
      linkedDuringRetry = await linkAndSync(ada);
    };
    final r = await server.call('delete', '/me', token: ada.access);
    expect(r.status, 204);
    expect(linkedDuringRetry, isNotEmpty);
    expect((await census(ada.userId)).values.toSet(), {0});
    // Only eve's Item is still live at Plaid.
    expect(server.plaid.liveItemCount, 1);
  });

  test('Items that keep appearing make it 502 with nothing deleted', () async {
    final before = await census(ada.userId);
    server.plaid.onCall = (method) async {
      if (method != 'removeItem') return;
      final saved = server.plaid.onCall;
      server.plaid.onCall = null;
      await linkAndSync(ada);
      server.plaid.onCall = saved;
    };
    final r = await server.call('delete', '/me', token: ada.access);
    server.plaid.onCall = null;
    expect(r.status, 502);
    expect(r.code, 'plaid_error');
    expect((await census(ada.userId))['users'], 1);
    expect(
      (await census(ada.userId))['transactions'],
      greaterThan(before['transactions']!),
    );
    expect((await server.call('get', '/me', token: ada.access)).status, 200);
  });

  test('an Item Plaid no longer knows does not block the deletion', () async {
    final items = await server.app.items.itemsToRemove(ada.userId);
    await server.plaid.removeItem(items.first.accessToken);
    final r = await server.call('delete', '/me', token: ada.access);
    expect(r.status, 204);
    expect((await census(ada.userId)).values.toSet(), {0});
  });

  test('a sync whose user is deleted while Plaid is called is 404', () async {
    server.plaid.onCall = (method) async {
      if (method != 'transactionsRecurringGet') return;
      server.plaid.onCall = null;
      final deleted = await server.call('delete', '/me', token: ada.access);
      expect(deleted.status, 204);
    };
    final other = await server.login();
    final r = await server.call(
      'post',
      '/plaid/items/$itemA/sync',
      token: other.access,
    );
    expect(r.status, 404);
    expect(r.code, 'not_found');
    expect((await census(ada.userId)).values.toSet(), {0});
  });

  test(
    'an exchange still at Plaid when the user is deleted leaves no Item',
    () async {
      final live = server.plaid.liveItemCount;
      final release = Completer<void>();
      final held = Completer<void>();
      server.plaid.onCall = (method) async {
        if (method != 'getItem') return;
        server.plaid.onCall = null;
        held.complete();
        await release.future;
      };
      final exchange = server.call(
        'post',
        '/plaid/exchange',
        token: ada.access,
        body: {'public_token': 'public-sandbox-x'},
      );
      await held.future;
      final deleted = await server.call('delete', '/me', token: ada.access);
      expect(deleted.status, 204);
      release.complete();
      final r = await exchange;
      expect(r.status, 401);
      expect(r.code, 'token_revoked');
      // Ada's two Items were removed by the deletion, the racing one by the exchange.
      expect(server.plaid.liveItemCount, live - 2);
      expect(server.plaid.liveItemCount, 1);
      expect((await census(ada.userId)).values.toSet(), {0});
    },
  );
}
