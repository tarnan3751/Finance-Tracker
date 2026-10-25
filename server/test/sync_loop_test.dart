// The sync loop against the real client over the recorded fixtures, with synthesized
// answers where Sandbox did not show a case: NOT_READY answered at once to a request and
// retried by a background run, the restart after a mutation during pagination,
// pending-to-posted, the repeated exchange of one Item (the caller's, then another
// user's), the investment-transactions window, and the accounts /accounts/get lists
// (an investment-only Item, a page's balance winning, a failed call).
import 'dart:async';
import 'dart:convert';

import 'package:finance_tracker_server/server.dart';
import 'package:finance_tracker_server/src/plaid/item_service.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support/recorded_plaid_transport.dart';
import 'support/test_server.dart';

const _account = '3oB3Mjm6GgFPAM77GLMGfMRoAZbeX4sZvBV5K';

/// A synthesized `/transactions/sync` page on the fixtures' checking account.
RecordedAnswer _page({
  List<Map<String, Object?>> added = const [],
  List<String> removed = const [],
  String cursor = 'cursor-2',
  bool hasMore = false,
}) => (
  status: 200,
  body: jsonEncode({
    'accounts': [
      {
        'account_id': _account,
        'name': 'Plaid Checking',
        'official_name': null,
        'mask': '0000',
        'type': 'depository',
        'subtype': 'checking',
        'balances': {
          'current': 500,
          'available': null,
          'limit': null,
          'iso_currency_code': 'USD',
        },
      },
    ],
    'added': added,
    'modified': <Object?>[],
    'removed': [
      for (final id in removed) {'transaction_id': id, 'account_id': _account},
    ],
    'next_cursor': cursor,
    'has_more': hasMore,
    'transactions_update_status': 'HISTORICAL_UPDATE_COMPLETE',
    'request_id': 'req-synthesized',
  }).replaceAll('"amount":"4.25"', '"amount":4.25'),
);

Map<String, Object?> _transaction(
  String id, {
  required bool pending,
  String? pendingId,
}) => {
  'transaction_id': id,
  'account_id': _account,
  // Written as a JSON number by _page, never through a double.
  'amount': '4.25',
  'iso_currency_code': 'USD',
  'date': '2026-10-23',
  'authorized_date': '2026-10-22',
  'pending': pending,
  'pending_transaction_id': pendingId,
  'name': 'STARBUCKS 123',
  'merchant_name': 'Starbucks',
  'logo_url': null,
  'counterparties': <Object?>[],
  'personal_finance_category': {
    'primary': 'FOOD_AND_DRINK',
    'detailed': 'FOOD_AND_DRINK_COFFEE',
  },
};

/// The fixture page with `has_more` set, as a first page that another follows.
RecordedAnswer _pageWithMore() {
  final answer = fixtureAnswer('transactions_sync_page1');
  return (
    status: 200,
    body: answer.body.replaceFirst('"has_more": false', '"has_more": true'),
  );
}

void main() {
  late RecordedPlaidTransport transport;
  late TestServer server;
  late Session ada;
  late List<Duration> waits;

  setUp(() async {
    transport = RecordedPlaidTransport();
    server = await TestServer.start(plaid: (_) => transport.plaidClient());
    waits = [];
    server.onDelay = (wait) async => waits.add(wait);
    ada = await server.register();
    transport
      ..byDefault('/item/public_token/exchange', 'item_public_token_exchange')
      ..byDefault('/item/get', 'item_get')
      ..byDefault('/institutions/get_by_id', 'institutions_get_by_id')
      ..byDefault('/accounts/get', 'accounts_get')
      ..byDefault('/transactions/recurring/get', 'transactions_recurring_get');
  });

  Future<TestResponse> exchange(Session who) => server.call(
    'post',
    '/plaid/exchange',
    token: who.access,
    body: {'public_token': 'public-recorded'},
  );

  Future<String> link() async {
    final r = await exchange(ada);
    expect(r.status, 201, reason: '$r');
    return r.json['id']! as String;
  }

  Future<TestResponse> sync(String itemId) =>
      server.call('post', '/plaid/items/$itemId/sync', token: ada.access);

  Future<List<Map<String, Object?>>> transactions() async {
    final r = await server.call(
      'get',
      '/transactions?since=0',
      token: ada.access,
    );
    return (r.json['transactions']! as List<Object?>).cast();
  }

  group('NOT_READY', () {
    test('a requested run answers not_ready at once', () async {
      transport.script('/transactions/sync', ['transactions_sync_not_ready']);
      final itemId = await link();
      final r = await sync(itemId);
      expect(r.status, 202);
      expect(r.json['status'], 'not_ready');
      expect(transport.bodies('/transactions/sync'), hasLength(1));
      expect(waits, isEmpty);
    });

    test('a background run asks again every 5 s, then completes', () async {
      transport.script('/transactions/sync', [
        'transactions_sync_not_ready',
        'transactions_sync_not_ready',
        'transactions_sync_not_ready',
        'transactions_sync_page1',
      ]);
      final itemId = await link();
      final run = await server.app.items.sync(
        ada.userId,
        itemId,
        retryNotReady: true,
      );
      expect(run['status'], 'completed');
      expect(run['added'], 316);
      expect(waits, List.filled(3, const Duration(seconds: 5)));
    });

    test(
      "a request's run is not held behind a background run's wait",
      () async {
        transport
          ..byDefault('/transactions/sync', 'transactions_sync_not_ready')
          ..byDefault('/accounts/balance/get', 'accounts_balance_get');
        final itemId = await link();
        final waiting = Completer<void>();
        final release = Completer<void>();
        server.onDelay = (wait) async {
          waits.add(wait);
          if (!waiting.isCompleted) {
            waiting.complete();
            await release.future;
          }
        };
        final background = server.app.items.sync(
          ada.userId,
          itemId,
          retryNotReady: true,
        );
        await waiting.future;
        expect(server.app.items.isSyncing(itemId), isFalse);
        // The background run sits in its 5 s wait; the app's poll answers at once.
        final polled = await sync(itemId).timeout(const Duration(seconds: 2));
        expect(polled.json['status'], 'not_ready');
        final balances = await server
            .call('post', '/plaid/items/$itemId/balances', token: ada.access)
            .timeout(const Duration(seconds: 2));
        expect(balances.status, 200);
        release.complete();
        expect((await background)['status'], 'not_ready');
        expect(waits, List.filled(12, syncNotReadyWait));
      },
    );

    test('a background run gives up after 12 retries', () async {
      transport.byDefault('/transactions/sync', 'transactions_sync_not_ready');
      final itemId = await link();
      final run = await server.app.items.sync(
        ada.userId,
        itemId,
        retryNotReady: true,
      );
      expect(run['status'], 'not_ready');
      expect(transport.bodies('/transactions/sync'), hasLength(13));
      // One /accounts/get per attempt, NOT_READY included.
      expect(transport.bodies('/accounts/get'), hasLength(13));
      expect(waits, List.filled(12, syncNotReadyWait));
      expect(await transactions(), isEmpty);
    });
  });

  group('a mutation during pagination', () {
    RecordedAnswer mutation() => plaidErrorAnswer(
      400,
      'TRANSACTIONS_ERROR',
      'TRANSACTIONS_SYNC_MUTATION_DURING_PAGINATION',
    );

    test('restarts from the cursor the run began with', () async {
      transport.script('/transactions/sync', [
        _pageWithMore(),
        mutation(),
        _pageWithMore(),
        'transactions_sync_up_to_date',
      ]);
      final itemId = await link();
      final r = await sync(itemId);
      expect(r.json['status'], 'completed');
      expect(r.json['added'], 316);
      final bodies = transport.bodies('/transactions/sync');
      expect(bodies[0].containsKey('cursor'), isFalse);
      expect(bodies[2].containsKey('cursor'), isFalse);
      expect(bodies[1]['cursor'], bodies[3]['cursor']);
      expect(await transactions(), hasLength(316));
    });

    test('a fourth mutation fails the run and stores nothing', () async {
      transport.script('/transactions/sync', [
        for (var i = 0; i < 4; i++) ...[_pageWithMore(), mutation()],
      ]);
      final itemId = await link();
      final r = await sync(itemId);
      expect(r.status, 502);
      expect(r.code, 'plaid_error');
      expect(await transactions(), isEmpty);
      final row = await server.app.db.read(
        (tx) => tx.first('SELECT cursor FROM items WHERE id = ?', [itemId]),
      );
      expect(row!['cursor'], isNull);
    });
  });

  test(
    'a posted transaction names our pending one, which is tombstoned',
    () async {
      transport.script('/transactions/sync', [
        _page(
          added: [_transaction('pending-1', pending: true)],
          cursor: 'cursor-1',
        ),
        _page(
          added: [
            _transaction('posted-1', pending: false, pendingId: 'pending-1'),
          ],
          removed: ['pending-1'],
        ),
      ]);
      final itemId = await link();
      await sync(itemId);
      final pending = (await transactions()).single;
      expect(pending['pending'], isTrue);
      expect(pending['amount'], Money(-425, 'USD').toJson());
      expect(pending['authorized_date'], '2026-10-22');
      await sync(itemId);
      final rows = await transactions();
      final posted = rows.firstWhere((t) => t['pending'] == false);
      final tombstone = rows.firstWhere((t) => t['id'] == pending['id']);
      expect(posted['pending_transaction_id'], pending['id']);
      expect(posted['id'], isNot(pending['id']));
      expect(posted['source'], 'plaid');
      expect(tombstone['deleted_at'], isNotNull);
      expect(transport.bodies('/transactions/sync').last['cursor'], 'cursor-1');
    },
  );

  group('the same Item exchanged again', () {
    test("the caller's is resealed, healthy and answered once more", () async {
      transport.script('/item/public_token/exchange', [
        'item_public_token_exchange',
        'item_public_token_exchange_reused',
      ]);
      final itemId = await link();
      await server.app.db.read(
        (tx) => tx.execute(
          "UPDATE items SET status = 'login_required', "
          "error_code = 'ITEM_LOGIN_REQUIRED' WHERE id = ?",
          [itemId],
        ),
      );
      await server.app.db.read(
        (tx) => tx.execute(
          "UPDATE items SET products = '[]', institution_name = 'Old name'",
        ),
      );
      final before = await server.app.db.read(
        (tx) => tx.first('SELECT access_token_nonce FROM items'),
      );
      final again = await exchange(ada);
      expect(again.status, 201);
      expect(again.json['id'], itemId);
      expect(again.json['status'], 'healthy');
      expect(again.json['error_code'], isNull);
      final rows = await server.app.db.read(
        (tx) => tx.select(
          'SELECT access_token_nonce, products, institution_name FROM items',
        ),
      );
      expect(rows, hasLength(1));
      // Refreshed from the new /item/get.
      expect(rows.single['products'], '["transactions"]');
      expect(rows.single['institution_name'], 'First Platypus Bank');
      expect(
        rows.single['access_token_nonce'],
        isNot(before!['access_token_nonce']),
      );
      expect(transport.bodies('/item/remove'), isEmpty);
    });

    test('two overlapping exchanges of one Item make one row', () async {
      final results = await Future.wait([exchange(ada), exchange(ada)]);
      expect([for (final r in results) r.status], [201, 201]);
      expect(results.first.json['id'], results.last.json['id']);
      final rows = await server.app.db.read(
        (tx) => tx.select('SELECT id FROM items'),
      );
      expect(rows, hasLength(1));
      expect(transport.bodies('/item/remove'), isEmpty);
      expect(transport.bodies('/item/get'), hasLength(2));
    });

    test("a failed /item/get never removes the caller's Item", () async {
      final itemId = await link();
      transport.script('/item/get', [
        plaidErrorAnswer(500, 'API_ERROR', 'INTERNAL_SERVER_ERROR'),
      ]);
      final r = await exchange(ada);
      expect(r.status, 502);
      expect(transport.bodies('/item/remove'), isEmpty);
      final items = await server.call('get', '/plaid/items', token: ada.access);
      expect(items.list.single, containsPair('id', itemId));
    });

    test(
      "another user's is 400 on public_token; nothing stored or removed",
      () async {
        final lines = <String>[];
        final subscription = Logger.root.onRecord.listen(
          (r) => lines.add(formatRecord(r, LogFormat.json)),
        );
        addTearDown(subscription.cancel);
        await link();
        final bob = await server.register('bob@example.com');
        final r = await exchange(bob);
        expect(r.status, 400);
        expect(r.code, 'validation_failed');
        expect(r.json['errors'], [containsPair('field', 'public_token')]);
        expect(transport.bodies('/item/remove'), isEmpty);
        expect(transport.bodies('/item/get'), hasLength(1));
        final rows = await server.app.db.read(
          (tx) => tx.select('SELECT user_id FROM items'),
        );
        expect(rows.single['user_id'], ada.userId);
        expect(
          lines.where((l) => l.contains('exchange_foreign_item')),
          hasLength(1),
        );
      },
    );
  });

  group('investment transactions', () {
    setUp(() {
      transport
        ..byDefault('/item/get', (Map<String, Object?> _) {
          final body = jsonDecode(
            fixtureAnswer('item_get').body,
          ) as Map<String, Object?>;
          final item = body['item']! as Map<String, Object?>;
          item['products'] = ['investments', 'transactions'];
          return (status: 200, body: jsonEncode(body));
        })
        ..byDefault('/transactions/sync', 'transactions_sync_up_to_date')
        ..byDefault('/investments/holdings/get', (
          status: 200,
          body: '{"holdings":[],"securities":[],"request_id":"r"}',
        ));
    });

    RecordedAnswer noInvestments() => (
      status: 200,
      body:
          '{"investment_transactions":[],"securities":[],'
          '"total_investment_transactions":0,"request_id":"r"}',
    );

    test('730 days first, then from 30 days before the last fetch', () async {
      transport.script('/investments/transactions/get', [
        noInvestments(),
        plaidErrorAnswer(400, 'ITEM_ERROR', 'PRODUCT_NOT_READY'),
        noInvestments(),
      ]);
      final itemId = await link();
      expect((await sync(itemId)).json['status'], 'completed');
      server.clock.advance(const Duration(days: 3));
      ada = await server.login();
      // The fetch fails: skipped, and the window does not move.
      expect((await sync(itemId)).json['status'], 'completed');
      server.clock.advance(const Duration(days: 3));
      ada = await server.login();
      expect((await sync(itemId)).json['status'], 'completed');
      final starts = [
        for (final b in transport.bodies('/investments/transactions/get'))
          b['start_date'],
      ];
      expect(starts, ['2024-10-24', '2026-09-24', '2026-09-24']);
    });

    test('the window never reaches past 730 days', () {
      final today = LocalDate(2026, 10, 24);
      expect(investmentsWindowStart(today, null), LocalDate(2024, 10, 24));
      expect(
        investmentsWindowStart(
          today,
          DateTime.utc(2024, 11, 1).millisecondsSinceEpoch,
        ),
        LocalDate(2024, 10, 24),
      );
      expect(
        investmentsWindowStart(
          today,
          DateTime.utc(2026, 10, 23, 23, 59).millisecondsSinceEpoch,
        ),
        LocalDate(2026, 9, 23),
      );
    });
  });

  group('/accounts/get', () {
    Future<List<Map<String, Object?>>> accounts() async =>
        (await server.call('get', '/accounts', token: ada.access)).list.cast();

    Future<Map<String, Object?>?> itemRow(String itemId) => server.app.db.read(
      (tx) =>
          tx.first('SELECT cursor, status FROM items WHERE id = ?', [itemId]),
    );

    test("an investment-only Item's account, holdings and investments are stored", () async {
      // Synthesized after the Tartan Bank capture (`PLAN.md` §4, 2026-10-25): one
      // 401(k) that /accounts/get lists and no transactions page does.
      const retirement = 'tartan-401k-account';
      transport
        ..byDefault('/item/get', (Map<String, Object?> _) {
          final body = jsonDecode(
            fixtureAnswer('item_get').body,
          ) as Map<String, Object?>;
          (body['item']! as Map<String, Object?>)['products'] = [
            'investments',
            'transactions',
          ];
          return (status: 200, body: jsonEncode(body));
        })
        ..script('/accounts/get', [
          (
            status: 200,
            body: jsonEncode({
              'accounts': [
                {
                  'account_id': retirement,
                  'name': '401(k)',
                  'official_name': 'Tartan Bank Retirement Savings Plan',
                  'mask': '0401',
                  'type': 'investment',
                  'subtype': '401k',
                  'balances': {
                    'current': 41250,
                    'available': null,
                    'limit': null,
                    'iso_currency_code': 'USD',
                  },
                },
              ],
              'request_id': 'req-synthesized',
            }),
          ),
        ])
        ..script('/transactions/sync', [
          (
            status: 200,
            body: jsonEncode({
              'accounts': <Object?>[],
              'added': <Object?>[],
              'modified': <Object?>[],
              'removed': <Object?>[],
              'next_cursor': 'cursor-1',
              'has_more': false,
              'transactions_update_status': 'HISTORICAL_UPDATE_COMPLETE',
              'request_id': 'req-synthesized',
            }),
          ),
        ])
        ..byDefault('/investments/holdings/get', (
          status: 200,
          body:
              '{"holdings":[{"account_id":"$retirement","security_id":"sec-1",'
              '"quantity":10,"institution_price":150.5,'
              '"institution_price_as_of":"2026-10-23","institution_value":1505,'
              '"cost_basis":1200,"iso_currency_code":"USD"}],'
              '"securities":[{"security_id":"sec-1","name":"Target Date 2050",'
              '"ticker_symbol":"TD50","type":"mutual fund",'
              '"is_cash_equivalent":false,"close_price":150.5,'
              '"close_price_as_of":"2026-10-23","iso_currency_code":"USD"}],'
              '"request_id":"r"}',
        ))
        ..byDefault('/investments/transactions/get', (
          status: 200,
          body:
              '{"investment_transactions":[{"investment_transaction_id":"it-1",'
              '"account_id":"$retirement","security_id":"sec-1",'
              '"date":"2026-10-01","name":"CONTRIBUTION TD50","type":"buy",'
              '"subtype":"contribution","quantity":1,"price":150.5,'
              '"amount":150.5,"fees":0,"iso_currency_code":"USD"}],'
              '"securities":[],"total_investment_transactions":1,'
              '"request_id":"r"}',
        ));
      final itemId = await link();
      final run = await sync(itemId);
      expect(run.json['status'], 'completed', reason: '$run');

      final account = (await accounts()).single;
      expect(account['name'], '401(k)');
      expect(account['official_name'], 'Tartan Bank Retirement Savings Plan');
      expect(account['mask'], '0401');
      expect(account['type'], 'investment');
      expect(account['current_balance'], Money(4125000, 'USD').toJson());

      final holdings = await server.call(
        'get',
        '/investments/holdings',
        token: ada.access,
      );
      final holding = (holdings.json['holdings']! as List<Object?>).single;
      expect(holding, containsPair('account_id', account['id']));
      expect(holding, containsPair('quantity', '10'));
      final investments = await server.call(
        'get',
        '/investments/transactions?since=0',
        token: ada.access,
      );
      final investment =
          (investments.json['investment_transactions']! as List<Object?>)
              .single;
      expect(investment, containsPair('account_id', account['id']));
      final stored = await server.app.db.read(
        (tx) => tx.select(
          'SELECT source FROM accounts UNION SELECT source FROM holdings '
          'UNION SELECT source FROM investment_transactions',
        ),
      );
      expect(stored.map((r) => r['source']).toSet(), {'plaid'});
    });

    test("every listed account is stored, a page's balance winning", () async {
      // /accounts/get reports the checking account at 500.00; the page, which Plaid
      // answers later, at 612.00.
      transport.script('/transactions/sync', [
        (
          status: 200,
          body: _page().body.replaceFirst('"current":500', '"current":612'),
        ),
      ]);
      final itemId = await link();
      expect((await sync(itemId)).json['status'], 'completed');
      final rows = await accounts();
      // The page names one account; /accounts/get all seven, in its order, the
      // checking account's fields (its mask included) the page's.
      expect(
        [for (final a in rows) a['mask']],
        ['0000', '2000', '3000', '4000', '5000', '6000', '7000'],
      );
      final checking = rows.firstWhere((a) => a['subtype'] == 'checking');
      expect(checking['current_balance'], Money(61200, 'USD').toJson());
      final card = rows.firstWhere((a) => a['type'] == 'credit');
      expect(card['credit_limit'], Money(480000, 'USD').toJson());
      expect(
        transport.bodies('/accounts/get').single.keys,
        unorderedEquals(['client_id', 'secret', 'access_token']),
      );
    });

    test('a failed call fails the run and stores nothing', () async {
      transport
        ..script('/accounts/get', [
          plaidErrorAnswer(500, 'API_ERROR', 'INTERNAL_SERVER_ERROR'),
        ])
        ..script('/transactions/sync', ['transactions_sync_page1']);
      final itemId = await link();
      final r = await sync(itemId);
      expect(r.status, 502);
      expect(r.code, 'plaid_error');
      expect(transport.bodies('/transactions/sync'), isEmpty);
      expect(await accounts(), isEmpty);
      expect(await transactions(), isEmpty);
      expect((await itemRow(itemId))!['cursor'], isNull);
      // The next run lists the accounts and applies the page.
      final again = await sync(itemId);
      expect(again.json['status'], 'completed');
      expect(await accounts(), hasLength(7));
    });

    test('login required is 409 and marks the Item', () async {
      transport.script('/accounts/get', [
        'transactions_sync_item_login_required',
      ]);
      final itemId = await link();
      final r = await sync(itemId);
      expect(r.status, 409);
      expect(r.code, 'item_login_required');
      expect(transport.bodies('/transactions/sync'), isEmpty);
      final row = (await itemRow(itemId))!;
      expect(row['status'], 'login_required');
      expect(row['cursor'], isNull);
      expect(await accounts(), isEmpty);
    });
  });
}
