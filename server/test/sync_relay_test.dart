// The relay's rules through POST /sync/push and GET /sync/pull.
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  late TestServer server;
  late Session a, b;
  late int now;

  setUp(() async {
    server = await TestServer.start();
    a = await server.register();
    b = await server.login();
    now = server.clock.value.millisecondsSinceEpoch;
  });

  String hlc(Session s, [int offset = 0, int counter = 0]) =>
      '${(now + offset).toString().padLeft(15, '0')}-'
      '${counter.toString().padLeft(5, '0')}-${s.deviceId}';

  Map<String, Object?> entry(
    Session s, {
    String? clock,
    String id = 'c1',
    String operation = 'create',
    Map<String, Object?> payload = const {'name': 'Food'},
    String? deviceId,
    String type = 'category',
  }) => {
    'entity_type': type,
    'entity_id': id,
    'operation': operation,
    'payload': payload,
    'hlc': clock ?? hlc(s),
    'device_id': deviceId ?? s.deviceId,
  };

  Future<TestResponse> push(Session s, List<Map<String, Object?>> entries) =>
      server.call(
        'post',
        '/sync/push',
        token: s.access,
        body: {'entries': entries},
      );

  Future<TestResponse> pull(Session s, {int since = 0, int limit = 500}) =>
      server.call(
        'get',
        '/sync/pull?since=$since&limit=$limit',
        token: s.access,
      );

  List<String> codes(TestResponse r) => [
    for (final j in r.json['rejected']! as List<Object?>)
      (j! as Map<String, Object?>)['code']! as String,
  ];

  test('an accepted entry reaches the other device with its seq', () async {
    final r = await push(a, [entry(a)]);
    expect(r.json, {
      'accepted': [hlc(a)],
      'rejected': <Object?>[],
    });
    final page = await pull(b);
    final entries = page.json['entries']! as List<Object?>;
    expect(entries.single, {...entry(a), 'seq': isA<int>()});
    expect(page.json['next_since'], (entries.single! as Map)['seq']);
    expect(page.json['has_more'], isFalse);
  });

  test(
    'a device never pulls its own entries, and its cursor still advances',
    () async {
      await push(a, [entry(a)]);
      final own = await pull(a);
      expect(own.json['entries'], isEmpty);
      final last = own.json['next_since']! as int;
      expect(last, greaterThan(0));
      expect((await pull(a, since: last)).json['next_since'], last);
    },
  );

  test('an identical resend is accepted again with no new seq', () async {
    await push(a, [entry(a)]);
    final first = (await pull(b)).json['next_since'];
    final again = await push(a, [entry(a)]);
    expect(again.json['accepted'], [hlc(a)]);
    final page = await pull(b);
    expect(page.json['entries'], hasLength(1));
    expect(page.json['next_since'], first);
  });

  test(
    'another payload under a stored clock is conflicting_duplicate',
    () async {
      await push(a, [entry(a)]);
      final r = await push(a, [
        entry(a, payload: {'name': 'Groceries'}),
      ]);
      expect(codes(r), ['conflicting_duplicate']);
      expect(r.json['accepted'], isEmpty);
    },
  );

  test('payload key order does not make a duplicate conflict', () async {
    await push(a, [
      entry(a, payload: {'name': 'Food', 'color': 1}),
    ]);
    final r = await push(a, [
      entry(a, payload: {'color': 1, 'name': 'Food'}),
    ]);
    expect(r.json['accepted'], hasLength(1));
  });

  test(
    'a resend with 1.0 for 1 is the same entry, as numbers compare',
    () async {
      await push(a, [
        entry(a, payload: {'name': 'Food', 'order': 1}),
      ]);
      final r = await push(a, [
        entry(a, payload: {'name': 'Food', 'order': 1.0}),
      ]);
      expect(r.json['accepted'], [hlc(a)]);
      expect(r.json['rejected'], isEmpty);
      expect((await pull(b)).json['entries'], hasLength(1));
    },
  );

  test('invalid entries', () async {
    final r = await push(a, [
      // Another device's entry, pushed with this device's token.
      entry(b),
      // A clock whose node is not the entry's device.
      entry(a, clock: hlc(b), deviceId: a.deviceId),
      entry(a, clock: hlc(a, 1), payload: const {}),
      entry(
        a,
        clock: hlc(a, 2),
        operation: 'delete',
        payload: const {'name': 'x'},
      ),
      entry(
        a,
        clock: hlc(a, 3),
        operation: 'delete',
        payload: const {'deleted_at': 'yesterday'},
      ),
      entry(
        a,
        clock: hlc(a, 4),
        id: 't1',
        payload: const {'source': 'plaid', 'name': 'x'},
      ),
      entry(
        a,
        clock: hlc(a, 5),
        operation: 'delete',
        payload: const {'deleted_at': '2026-10-24T09:30:00.000Z'},
      ),
    ]);
    expect(codes(r), List.filled(6, 'invalid'));
    expect(r.json['accepted'], [hlc(a, 5)]);
  });

  test('a clock more than an hour ahead is clock_drift', () async {
    const hour = 3600 * 1000;
    final r = await push(a, [
      entry(a, clock: hlc(a, hour)),
      entry(a, clock: hlc(a, hour + 1), id: 'c2'),
    ]);
    expect(r.json['accepted'], [hlc(a, hour)]);
    expect(codes(r), ['clock_drift']);
  });

  test('pages by limit, skipping own entries', () async {
    await push(a, [
      for (var i = 0; i < 3; i++) entry(a, clock: hlc(a, i), id: 'a$i'),
    ]);
    await push(b, [
      for (var i = 0; i < 2; i++) entry(b, clock: hlc(b, i), id: 'b$i'),
    ]);
    await push(a, [
      for (var i = 3; i < 5; i++) entry(a, clock: hlc(a, i), id: 'a$i'),
    ]);
    final ids = <Object?>[];
    var since = 0;
    var pages = 0;
    while (true) {
      final page = await pull(b, since: since, limit: 2);
      pages++;
      ids.addAll([
        for (final e in page.json['entries']! as List<Object?>)
          (e! as Map<String, Object?>)['entity_id'],
      ]);
      since = page.json['next_since']! as int;
      if (page.json['has_more'] == false) break;
    }
    expect(ids, ['a0', 'a1', 'a2', 'a3', 'a4']);
    expect(pages, 3);
    expect((await pull(a)).json['entries'], hasLength(2));
  });

  test('users never see each other\'s entries', () async {
    final eve = await server.register('eve@example.com');
    await push(a, [entry(a)]);
    final page = await pull(eve);
    expect(page.json['entries'], isEmpty);
    expect(page.json['next_since'], 0);
  });

  test('a cursor past the end is 409 sync_cursor_invalid', () async {
    await push(a, [entry(a)]);
    final last = (await pull(b)).json['next_since']! as int;
    final r = await pull(b, since: last + 1);
    expect(r.status, 409);
    expect(r.code, 'sync_cursor_invalid');
  });

  test('bad query parameters and bodies are 400', () async {
    for (final q in ['since=-1', 'limit=0', 'limit=501', 'since=x']) {
      final r = await server.call('get', '/sync/pull?$q', token: b.access);
      expect(r.status, 400, reason: q);
    }
    final r = await server.call(
      'post',
      '/sync/push',
      token: a.access,
      body: {
        'entries': [
          {...entry(a), 'hlc': 'not-a-clock', 'entity_type': 'item'},
        ],
      },
      validRequest: false,
    );
    expect(r.status, 400);
    expect(
      {
        for (final e in r.json['errors']! as List<Object?>)
          (e! as Map<String, Object?>)['field'],
      },
      {'entries[0].hlc', 'entries[0].entity_type'},
    );
  });

  test('every user-authored type is accepted and pulled, a goal '
      'contribution among them', () async {
    const types = [
      'account',
      'transaction',
      'category',
      'rule',
      'budget',
      'recurring_stream',
      'bill_reminder',
      'goal',
      'goal_contribution',
      'settings',
    ];
    final r = await push(a, [
      for (final (i, t) in types.indexed)
        entry(a, type: t, id: 'e$i', clock: hlc(a, 0, i)),
    ]);
    expect(r.json['rejected'], isEmpty);
    expect(r.json['accepted'], hasLength(types.length));
    expect([
      for (final e in (await pull(b)).json['entries']! as List<Object?>)
        (e! as Map<String, Object?>)['entity_type'],
    ], types);
  });

  test('push and pull stamp the device last_sync_at', () async {
    await push(a, [entry(a)]);
    final devices = await server.call('get', '/devices', token: a.access);
    final me = devices.list.cast<Map<String, Object?>>().firstWhere(
      (d) => d['id'] == a.deviceId,
    );
    expect(me['last_sync_at'], '2026-10-24T09:30:00.000Z');
  });
}
