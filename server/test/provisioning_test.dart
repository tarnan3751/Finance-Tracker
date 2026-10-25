// The persona provisioning job against the fake client, on a clock the job's waits move:
// the queued answer, the counters, the one date shift, the custom users carrying the
// history with nothing injected, a history Sandbox delivers late, an investment-only Item, the NOT_READY, rate-limit and
// 5xx retries, a recorded failure, the transactions skipped when a job crosses Plaid's
// window, one job per user, and the route rules.
import 'dart:convert';

import 'package:finance_tracker_server/server.dart';
import 'package:finance_tracker_server/src/plaid/provisioning_service.dart'
    show isPlaidServerError, provisioningAsOf;
import 'package:logging/logging.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  late TestServer server;
  late Session ada;
  late List<Duration> waits;
  late List<(String, DateTime)> calls;

  setUp(() async {
    server = await TestServer.start();
    ada = await server.register();
    waits = [];
    calls = [];
    server.onDelay = (wait) async {
      waits.add(wait);
      server.clock.advance(wait);
    };
    server.plaid.onCall = (method) async =>
        calls.add((method, server.clock.value));
  });

  Future<TestResponse> provision(Map<String, Object?> body, [Session? who]) =>
      server.call(
        'post',
        '/sandbox/provision',
        token: (who ?? ada).access,
        body: body,
      );

  /// Runs a job to its end; the job as `getProvisionJob` reports it, read with a fresh
  /// session since the job's waits may outlive the first one's access token.
  Future<Map<String, Object?>> runJob(Map<String, Object?> body) async {
    final started = await provision(body);
    expect(started.status, 202, reason: '$started');
    final id = started.json['id']! as String;
    await server.app.provisioning.finished(id);
    ada = await server.login();
    final job = await server.call(
      'get',
      '/sandbox/provision/$id',
      token: ada.access,
    );
    expect(job.status, 200);
    return job.json;
  }

  Future<List<Map<String, Object?>>> allTransactions() async {
    final rows = <Map<String, Object?>>[];
    var since = 0;
    while (true) {
      final page = await server.call(
        'get',
        '/transactions?since=$since',
        token: ada.access,
      );
      rows.addAll(
        (page.json['transactions']! as List<Object?>)
            .cast<Map<String, Object?>>(),
      );
      since = page.json['next_since']! as int;
      if (page.json['has_more'] != true) return rows;
    }
  }

  test('a job is queued, links the persona and completes', () async {
    final started = await provision({'persona': 'renter', 'days': 120});
    expect(started.status, 202);
    expect(started.json['status'], 'queued');
    expect(started.json['persona'], 'renter');
    expect(started.json['seed'], 1);
    expect(started.json['created_at'], '2026-10-24T09:30:00.000Z');
    expect(started.json['finished_at'], isNull);
    expect(started.json['item_ids'], isEmpty);

    final id = started.json['id']! as String;
    await server.app.provisioning.finished(id);
    ada = await server.login();
    final job = (await server.call(
      'get',
      '/sandbox/provision/$id',
      token: ada.access,
    )).json;
    expect(job['status'], 'completed', reason: '$job');
    expect(job['error'], isNull);
    expect(job['finished_at'], isNotNull);
    expect(job['progress'], {
      'items_total': 1,
      'items_linked': 1,
      'batches_total': 0,
      'batches_sent': 0,
      'skipped': 0,
    });
    final items = (await server.call(
      'get',
      '/plaid/items',
      token: ada.access,
    )).list.cast<Map<String, Object?>>();
    expect([for (final i in items) i['id']], job['item_ids']);
    expect(
      items.single['institution'],
      containsPair('name', 'First Platypus Bank'),
    );
    expect(items.single['status'], 'healthy');

    // Every transaction of the custom user arrived once, as the
    // fake's demo data, every date moved by the one shift: Plaid's today (UTC−12, so
    // 2026-10-23) minus the engine's as-of date (2026-10-24). Nothing was injected.
    final household = generateHousehold(
      personaFor(PersonaId.renter),
      seed: 1,
      asOf: provisioningAsOf,
      days: 120,
    );
    final user = sandboxUsers(household).single;
    String key(LocalDate date, Money amount, String name) =>
        '${date.toIso()} ${amount.minorUnits} $name';
    final expected = [
      for (final t in user.split.customUser)
        key(t.date.addDays(-1), t.amount, t.name),
    ]..sort();
    final stored = await allTransactions();
    expect(
      [
        for (final t in stored)
          key(
            LocalDate.parse(t['date']! as String),
            Money.fromJson(t['amount']! as Map<String, dynamic>),
            t['name']! as String,
          ),
      ]..sort(),
      expected,
    );
    expect(stored.map((t) => t['source']).toSet(), {'demo'});
    expect(
      stored
          .map((t) => t['date']! as String)
          .reduce((a, b) => a.compareTo(b) > 0 ? a : b),
      '2026-10-23',
    );

    // The accounts are the persona's, by name and mask.
    final accounts = (await server.call(
      'get',
      '/accounts',
      token: ada.access,
    )).list.cast<Map<String, Object?>>();
    expect(
      {for (final a in accounts) '${a['name']} ${a['mask']}'},
      {
        for (final a in household.persona.accounts)
          if (a.institution == 'platypus') '${a.name} ${a.mask}',
      },
    );

    // The first sync met NOT_READY once and waited, and the second sync came 5 s after
    // it completed; those were the only waits.
    expect(waits, [const Duration(seconds: 5), const Duration(seconds: 5)]);
    expect(
      calls.map((c) => c.$1),
      isNot(contains('sandboxTransactionsCreate')),
    );
  });

  test('an investment-only Item is linked and the job completes', () async {
    // The family's 401(k) is the only account of its Tartan Bank Item, and no
    // transactions page lists it (`PLAN.md` §4, 2026-10-25): the sync takes it from
    // /accounts/get.
    final job = await runJob({'persona': 'family', 'days': 30});
    expect(job['status'], 'completed', reason: '$job');
    expect((job['progress']! as Map)['items_linked'], 4);
    final accounts = (await server.call(
      'get',
      '/accounts',
      token: ada.access,
    )).list.cast<Map<String, Object?>>();
    expect(
      {for (final a in accounts) '${a['name']} ${a['mask']}'},
      {
        for (final a in personaFor(PersonaId.family).accounts)
          '${a.name} ${a.mask}',
      },
    );
    final retirement = personaFor(PersonaId.family).accounts
        .firstWhere((a) => a.type == AccountType.investment);
    expect(
      accounts.firstWhere((a) => a['mask'] == retirement.mask),
      containsPair('type', 'investment'),
    );
  });

  test(
    'a 730-day job carries the newest history that fits, and injects none',
    () async {
      // 09:30 UTC: Plaid's oldest date is 2024-10-25 (the UTC date minus 729), and no
      // custom user of the family carries the persona's first day (2024-10-25, shifted to
      // 2024-10-24), so nothing is skipped either.
      final job = await runJob({'persona': 'family'});
      expect(job['status'], 'completed', reason: '$job');
      expect(job['progress'], {
        'items_total': 4,
        'items_linked': 4,
        'batches_total': 0,
        'batches_sent': 0,
        'skipped': 0,
      });
      expect(
        calls.map((c) => c.$1),
        isNot(contains('sandboxTransactionsCreate')),
      );
      final household = generateHousehold(
        personaFor(PersonaId.family),
        seed: 1,
        asOf: provisioningAsOf,
      );
      final users = sandboxUsers(household);
      final platypus = users.firstWhere(
        (u) => u.split.institution.key == 'platypus',
      );
      expect(platypus.split.injected, isNotEmpty);
      String key(LocalDate date, Money amount, String name) =>
          '${date.toIso()} ${amount.minorUnits} $name';
      final stored = await allTransactions();
      expect(
        [
          for (final t in stored)
            key(
              LocalDate.parse(t['date']! as String),
              Money.fromJson(t['amount']! as Map<String, dynamic>),
              t['name']! as String,
            ),
        ]..sort(),
        [
          for (final u in users)
            for (final t in u.split.customUser)
              key(t.date.addDays(-1), t.amount, t.name),
        ]..sort(),
      );
    },
  );

  test('the second sync stores the history Sandbox delivers late', () async {
    // Sandbox answers a large custom user's first completed sync with part of its rows
    // and delivers the rest on a later sync (`PLAN.md` §4).
    server.plaid.lateHistoryAfter = 100;
    final job = await runJob({'persona': 'renter', 'days': 120});
    expect(job['status'], 'completed', reason: '$job');
    final household = generateHousehold(
      personaFor(PersonaId.renter),
      seed: 1,
      asOf: provisioningAsOf,
      days: 120,
    );
    final carried = sandboxUsers(household).single.split.customUser;
    expect(carried.length, greaterThan(100));
    expect(await allTransactions(), hasLength(carried.length));
  });

  test('a Plaid 5xx is retried 15 s apart, at most three times', () async {
    const error = PlaidException('API_ERROR', 'INTERNAL_SERVER_ERROR');
    server.plaid.failNext('sandboxPublicTokenCreate', error);
    final job = await runJob({'persona': 'renter', 'days': 30});
    expect(job['status'], 'completed', reason: '$job');
    expect(job['item_ids'], hasLength(1));
    expect(waits.where((w) => w == const Duration(seconds: 15)), hasLength(1));

    waits.clear();
    server.plaid.failNext('sandboxPublicTokenCreate', error, times: 4);
    final failed = await runJob({'persona': 'renter', 'days': 30, 'seed': 2});
    expect(failed['status'], 'failed');
    expect(failed['error'], 'link platypus: INTERNAL_SERVER_ERROR');
    expect(waits.where((w) => w == const Duration(seconds: 15)), hasLength(3));
  });

  for (final (method, skip) in [
    ('exchangePublicToken', 0),
    ('getItem', 0),
    ('transactionsSync', 0),
    // The NOT_READY answer and the first completed sync, then the second sync.
    ('transactionsSync', 2),
  ]) {
    final where = method == 'transactionsSync'
        ? (skip == 0 ? 'the first sync' : 'the second sync')
        : method;
    test(
      'a Plaid 5xx on $where is retried once and the job completes',
      () async {
        server.plaid.failNext(
          method,
          const PlaidException('API_ERROR', 'INTERNAL_SERVER_ERROR'),
          skip: skip,
        );
        final job = await runJob({'persona': 'renter', 'days': 30});
        expect(job['status'], 'completed', reason: '$job');
        expect(job['item_ids'], hasLength(1));
        expect(
          waits.where((w) => w == const Duration(seconds: 15)),
          hasLength(1),
        );
        if (skip == 2) {
          // The retry came after the NOT_READY wait and the second sync's.
          expect(waits, const [
            Duration(seconds: 5),
            Duration(seconds: 5),
            Duration(seconds: 15),
          ]);
        }
        // A failed /item/get removed its Item at Plaid; one Item is left.
        expect(server.plaid.liveItemCount, 1);
        expect(
          (await server.call('get', '/plaid/items', token: ada.access)).list,
          hasLength(1),
        );
      },
    );
  }

  test('a 4xx on the exchange fails the job at once', () async {
    server.plaid.failNext(
      'exchangePublicToken',
      const PlaidException('INVALID_INPUT', 'INVALID_PUBLIC_TOKEN'),
    );
    final job = await runJob({'persona': 'renter', 'days': 30});
    expect(job['status'], 'failed');
    expect(
      job['error'],
      'link platypus: plaid_error (Plaid answered INVALID_PUBLIC_TOKEN)',
    );
    expect(job['item_ids'], isEmpty);
    expect(waits.where((w) => w == const Duration(seconds: 15)), isEmpty);
  });

  test(
    'four 5xx in a row on the first sync fail the job with the code',
    () async {
      server.plaid.failNext(
        'transactionsSync',
        const PlaidException('API_ERROR', 'HTTP_503'),
        times: 4,
      );
      final job = await runJob({'persona': 'renter', 'days': 30});
      expect(job['status'], 'failed');
      expect(job['error'], 'first sync platypus: HTTP_503');
      expect(
        waits.where((w) => w == const Duration(seconds: 15)),
        hasLength(3),
      );
    },
  );

  test('isPlaidServerError names Plaid failing on its side only', () {
    for (final code in [
      'INTERNAL_SERVER_ERROR',
      'HTTP_500',
      'HTTP_503',
      'TIMEOUT',
      'NETWORK_ERROR',
    ]) {
      expect(isPlaidServerError(PlaidException('API_ERROR', code)), isTrue);
    }
    for (final e in const [
      PlaidException('API_ERROR', 'HTTP_400'),
      PlaidException('API_ERROR', 'INVALID_RESPONSE'),
      PlaidException('INVALID_INPUT', 'INTERNAL_SERVER_ERROR'),
      PlaidException('RATE_LIMIT_EXCEEDED', 'HTTP_429'),
    ]) {
      expect(isPlaidServerError(e), isFalse, reason: '$e');
    }
  });

  test(
    'a rate limit on /item/get retries with a fresh custom user, one Item kept',
    () async {
      server.plaid.failNext(
        'getItem',
        const PlaidException('RATE_LIMIT_EXCEEDED', 'RATE_LIMIT'),
      );
      final job = await runJob({'persona': 'renter', 'days': 30});
      expect(job['status'], 'completed', reason: '$job');
      expect(job['item_ids'], hasLength(1));
      expect(
        calls.where((c) => c.$1 == 'sandboxPublicTokenCreate'),
        hasLength(2),
      );
      // The first exchange's Item was removed at Plaid as an orphan.
      expect(server.plaid.liveItemCount, 1);
      expect(
        (await server.call('get', '/plaid/items', token: ada.access)).list,
        hasLength(1),
      );
    },
  );

  test('a rate limit is retried after 60 s, at most three times', () async {
    server.plaid.failNext(
      'sandboxPublicTokenCreate',
      const PlaidException('RATE_LIMIT_EXCEEDED', 'RATE_LIMIT'),
      times: 3,
    );
    final job = await runJob({'persona': 'renter', 'days': 120});
    expect(job['status'], 'completed', reason: '$job');
    expect(waits.where((w) => w == const Duration(seconds: 60)), hasLength(3));

    server.plaid.failNext(
      'sandboxPublicTokenCreate',
      const PlaidException('RATE_LIMIT_EXCEEDED', 'RATE_LIMIT'),
      times: 4,
    );
    final failed = await runJob({'persona': 'renter', 'days': 120, 'seed': 2});
    expect(failed['status'], 'failed');
    expect(failed['error'], 'link platypus: RATE_LIMIT');
  });

  test('the first other Plaid failure fails the job, with no token logged', () async {
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);
    addTearDown(subscription.cancel);
    server.plaid.failNext(
      'sandboxPublicTokenCreate',
      const PlaidException('INVALID_INPUT', 'INVALID_INSTITUTION'),
      skip: 1,
    );
    final job = await runJob({'persona': 'family', 'days': 120});
    expect(job['status'], 'failed');
    expect(job['error'], 'link tartan: INVALID_INSTITUTION');
    expect(job['item_ids'], hasLength(1));
    expect((job['progress']! as Map)['items_linked'], 1);
    expect(job['finished_at'], isNotNull);
    final logged = [
      for (final r in records)
        '${r.message} ${r.object is LogEvent ? jsonEncode((r.object! as LogEvent).fields) : ''}',
    ].join('\n');
    expect(logged, contains('provision_failed'));
    for (final secret in [
      'access-sandbox',
      'public-sandbox',
      'override_accounts',
    ]) {
      expect(logged, isNot(contains(secret)));
    }
  });

  test('what leaves the window while the job runs is skipped', () async {
    // The window is checked when each Item is linked, against the shift computed once: a
    // job that stalls for 40 days in its first Item's sync finds the second Item's oldest
    // rows (the student's loans, back to the persona's first month) outside Plaid's
    // window, and leaves them out of that custom user.
    var stalled = false;
    server.plaid.onCall = (method) async {
      if (method == 'transactionsSync' && !stalled) {
        stalled = true;
        server.clock.advance(const Duration(days: 40));
      }
    };
    final job = await runJob({'persona': 'student'});
    expect(job['status'], 'completed', reason: '$job');
    final skipped =
        (job['progress']! as Map<String, Object?>)['skipped']! as int;
    expect(skipped, greaterThan(0));
    final stored = await allTransactions();
    final household = generateHousehold(
      personaFor(PersonaId.student),
      seed: 1,
      asOf: provisioningAsOf,
    );
    expect(
      stored.length + skipped,
      sandboxUsers(household).fold(0, (n, u) => n + u.split.customUser.length),
    );
    // The second Item was linked 40 days after 09:30 UTC on 2026-10-24; the first one's
    // history starts well inside the window either way.
    final oldest = LocalDate(2026, 12, 3).addDays(-729);
    for (final t in stored) {
      for (final key in const ['date', 'authorized_date']) {
        expect(
          LocalDate.parse(t[key]! as String).isBefore(oldest),
          isFalse,
          reason: '$key of $t',
        );
      }
    }
  });

  test('one job per user at a time; a finished one does not block', () async {
    final first = await provision({'persona': 'renter', 'days': 30});
    final again = await provision({'persona': 'renter', 'days': 30});
    expect(again.status, 409);
    expect(again.code, 'conflict');
    final eve = await server.register('eve@example.com');
    expect(
      (await provision({'persona': 'renter', 'days': 30}, eve)).status,
      202,
    );
    await server.app.provisioning.finished(first.json['id']! as String);
    final next = await provision({'persona': 'student', 'days': 30});
    expect(next.status, 202);

    // A failed job does not block either.
    await server.app.provisioning.finished(next.json['id']! as String);
    server.plaid.failNext(
      'sandboxPublicTokenCreate',
      const PlaidException('INVALID_INPUT', 'INVALID_INSTITUTION'),
    );
    final failing = await provision({'persona': 'renter', 'days': 30});
    await server.app.provisioning.finished(failing.json['id']! as String);
    expect(
      server.app.provisioning.get(
        ada.userId,
        failing.json['id']! as String,
      )['status'],
      'failed',
    );
    expect((await provision({'persona': 'renter', 'days': 30})).status, 202);
  });

  test('another user\'s job and an unknown one are 404', () async {
    final started = await provision({'persona': 'renter', 'days': 30});
    final eve = await server.register('eve@example.com');
    for (final (who, id) in [
      (eve, started.json['id']! as String),
      (ada, 'nope'),
    ]) {
      final r = await server.call(
        'get',
        '/sandbox/provision/$id',
        token: who.access,
      );
      expect(r.status, 404);
      expect(r.code, 'not_found');
    }
    await server.app.provisioning.finished(started.json['id']! as String);
  });

  test('the fake refuses a custom user it cannot read or place', () async {
    for (final (institution, password, code) in [
      ('ins_109508', 'not json', 'INVALID_FIELD'),
      ('ins_109508', '[]', 'INVALID_FIELD'),
      ('ins_3', '{"override_accounts": []}', 'INVALID_INSTITUTION'),
    ]) {
      await expectLater(
        server.plaid.sandboxPublicTokenCreate(
          institutionId: institution,
          products: const ['transactions'],
          overrideUsername: 'user_custom',
          overridePassword: password,
        ),
        throwsA(isA<PlaidException>().having((e) => e.errorCode, 'code', code)),
      );
    }
  });

  test('a body outside the contract is 400', () async {
    for (final body in [
      <String, Object?>{},
      {'persona': 'retiree'},
      {'persona': 'renter', 'seed': 0},
      {'persona': 'renter', 'days': 29},
      {'persona': 'renter', 'days': 731},
      {'persona': 'renter', 'days': 365.0},
      {'persona': 'renter', 'colour': 'blue'},
    ]) {
      final r = await server.call(
        'post',
        '/sandbox/provision',
        token: ada.access,
        body: body,
        validRequest: false,
      );
      expect(r.status, 400, reason: '$body');
    }
  });

  test('a server that cannot drive Sandbox refuses both routes', () async {
    final production = await TestServer.start(
      config: ServerConfig(
        jwtSecret: testConfig.jwtSecret,
        tokenEncryptionKey: testConfig.tokenEncryptionKey,
        argon2: testConfig.argon2,
        plaidEnv: 'production',
      ),
    );
    final user = await production.register();
    final post = await production.call(
      'post',
      '/sandbox/provision',
      token: user.access,
      body: {'persona': 'renter'},
    );
    expect(post.status, 409);
    expect(post.code, 'conflict');
    final get = await production.call(
      'get',
      '/sandbox/provision/any',
      token: user.access,
    );
    expect(get.status, 409);
  });
}
