// The poll scheduler with the fake client and recorded waits: which Items a tick syncs
// (not login_required, not removed, not removed at Plaid), one at a time and staggered,
// as background runs that retry NOT_READY; an Item in flight skipped; an Item's failure
// counted without stopping the tick; a database failure logged with the loop still
// alive; stop() ending the wait at once.
import 'dart:async';

import 'package:finance_tracker_server/server.dart';
import 'package:finance_tracker_server/src/plaid/poll_scheduler.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  late TestServer server;
  late Session ada;
  late List<Duration> waits;

  setUp(() async {
    server = await TestServer.start();
    waits = [];
    server.onDelay = (wait) async => waits.add(wait);
    ada = await server.register();
  });

  Future<String> link() async {
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
    expect(item.status, 201);
    return item.json['id']! as String;
  }

  Future<void> setStatus(String itemId, String sql) => server.app.db.read(
    (tx) => tx.execute('UPDATE items SET $sql WHERE id = ?', [itemId]),
  );

  Future<List<String>> syncedItems() async => [
    for (final r in await server.app.db.read(
      (tx) => tx.select(
        'SELECT id FROM items WHERE last_successful_sync_at IS NOT NULL '
        'ORDER BY created_at, id',
      ),
    ))
      r['id']! as String,
  ];

  test('a tick syncs the Items it may, one at a time, staggered', () async {
    final first = await link();
    server.clock.advance(const Duration(seconds: 1));
    final second = await link();
    server.clock.advance(const Duration(seconds: 1));
    final loginRequired = await link();
    server.clock.advance(const Duration(seconds: 1));
    final kept = await link();
    server.clock.advance(const Duration(seconds: 1));
    final half = await link();
    await setStatus(loginRequired, "status = 'login_required'");
    await setStatus(kept, "status = 'removed', plaid_removed_at = 1");
    await setStatus(half, 'plaid_removed_at = 1');
    final calls = <String>[];
    server.plaid.onCall = (method) async => calls.add(method);

    final report = await server.app.poller.tick();
    expect(report, (
      items: 2,
      completed: 2,
      notReady: 0,
      skipped: 0,
      failed: 0,
    ));
    expect(await syncedItems(), [first, second]);
    // Each fresh fake Item answers NOT_READY once: the background run waits 5 s and asks
    // again; the second Item starts 2 s after the first ends.
    expect(waits, const [
      Duration(seconds: 5),
      Duration(seconds: 2),
      Duration(seconds: 5),
    ]);
    expect(calls.where((m) => m == 'transactionsSync'), hasLength(4));
  });

  test('an Item whose run is in flight is skipped', () async {
    final itemId = await link();
    final release = Completer<void>();
    server.plaid.onCall = (method) async {
      if (method == 'transactionsSync') await release.future;
    };
    final inFlight = server.app.items.sync(ada.userId, itemId);
    await Future<void>.delayed(Duration.zero);
    expect(server.app.items.isSyncing(itemId), isTrue);
    final report = await server.app.poller.tick();
    expect(report.skipped, 1);
    expect(report.completed, 0);
    release.complete();
    await inFlight;
    expect(server.app.items.isSyncing(itemId), isFalse);
  });

  test("an Item's failure is counted and the tick goes on", () async {
    final failing = await link();
    server.clock.advance(const Duration(seconds: 1));
    final healthy = await link();
    server.plaid.failNext(
      'transactionsSync',
      const PlaidException('API_ERROR', 'INTERNAL_SERVER_ERROR'),
    );
    final lines = <String>[];
    final subscription = Logger.root.onRecord.listen(
      (r) => lines.add(formatRecord(r, LogFormat.json)),
    );
    addTearDown(subscription.cancel);
    final report = await server.app.poller.tick();
    expect(report.failed, 1);
    expect(report.completed, 1);
    expect(await syncedItems(), [healthy]);
    expect(
      lines.where((l) => l.contains('poll_item_failed')).single,
      allOf(contains(failing), contains('plaid_error')),
    );
    expect(lines.where((l) => l.contains('poll_completed')), hasLength(1));
  });

  test('a database failure is logged and the loop lives on', () async {
    await link();
    final ticks = <Completer<void>>[];
    final poller = PollScheduler(
      db: server.app.db,
      items: server.app.items,
      interval: const Duration(minutes: 3),
      delay: (wait) {
        if (wait != const Duration(minutes: 3)) return Future.value();
        final c = Completer<void>();
        ticks.add(c);
        return c.future;
      },
    );
    final lines = <String>[];
    final subscription = Logger.root.onRecord.listen(
      (r) => lines.add(formatRecord(r, LogFormat.json)),
    );
    addTearDown(subscription.cancel);
    await server.app.db.read(
      (tx) => tx.execute('ALTER TABLE items RENAME TO items_away'),
    );
    poller.start();
    await pumpUntil(() => ticks.isNotEmpty);
    expect(lines.where((l) => l.contains('poll_failed')), hasLength(1));
    await server.app.db.read(
      (tx) => tx.execute('ALTER TABLE items_away RENAME TO items'),
    );
    ticks.single.complete();
    await pumpUntil(() => ticks.length == 2);
    expect(await syncedItems(), hasLength(1));
    await poller.stop();
  });

  test(
    "stop cancels the default timer, so a stopped server's process exits",
    () async {
      final poller = PollScheduler(
        db: server.app.db,
        items: server.app.items,
        interval: const Duration(hours: 1),
      );
      poller.start();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final watch = Stopwatch()..start();
      await poller.stop();
      expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    },
  );

  test('stop ends the wait at once', () async {
    final poller = PollScheduler(
      db: server.app.db,
      items: server.app.items,
      interval: const Duration(minutes: 3),
      delay: (_) => Completer<void>().future,
    );
    poller.start();
    await Future<void>.delayed(Duration.zero);
    await poller.stop().timeout(const Duration(seconds: 1));
  });
}

/// Lets the event loop run until [done] holds (at most a second).
Future<void> pumpUntil(bool Function() done) async {
  for (var i = 0; i < 1000 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(done(), isTrue);
}
