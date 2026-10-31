// The ports the worker and the app coordinate through, within one isolate over a map
// registry: no app, a busy app, an app that syncs (and its outcome), an app that
// acknowledges and never finishes, a stale mapping removed, a slow app kept, a mapping
// replaced meanwhile kept, the app registering again; the lock taken once, a live
// holder kept and a dead one replaced; and a starting app waiting for the worker's own
// cycle, at once when none runs or its mapping is stale.
import 'dart:async';
import 'dart:isolate';

import 'package:finance_tracker/core/background/background_ports.dart';
import 'package:flutter_test/flutter_test.dart';

/// A registry whose first [stale] lookups still see [dead], as a worker in another
/// isolate can read a mapping another has just replaced.
final class _StaleRegistry implements PortRegistry {
  _StaleRegistry(this.dead, this.stale);

  final SendPort dead;
  int stale;
  final MapPortRegistry _inner = MapPortRegistry();

  @override
  SendPort? lookup(String name) {
    if (stale > 0) {
      stale--;
      return dead;
    }
    return _inner.lookup(name);
  }

  @override
  bool register(SendPort port, String name) => _inner.register(port, name);

  @override
  void remove(String name) => _inner.remove(name);
}

void main() {
  late MapPortRegistry registry;

  setUp(() => registry = MapPortRegistry());

  test('no app answers when none registered', () async {
    expect(await askApp(registry: registry), isA<NoApp>());
  });

  test('a busy app, then one that syncs, with its outcome', () async {
    bool running = false;
    DelegatedResult outcome = DelegatedResult.retry;
    final AppSyncPort app = AppSyncPort(
      () => running,
      () async => outcome,
      registry: registry,
    );
    addTearDown(app.close);
    expect(await askApp(registry: registry), isA<AppBusy>());
    running = true;
    expect(
      await askApp(registry: registry),
      isA<AppSynced>().having((a) => a.result, 'result', DelegatedResult.retry),
    );
    outcome = DelegatedResult.success;
    expect(
      await askApp(registry: registry),
      isA<AppSynced>().having(
        (a) => a.result,
        'result',
        DelegatedResult.success,
      ),
    );
    app.close();
    expect(registry.lookup(appPortName), isNull);
  });

  test(
    'an app that acknowledges and never finishes answers nothing more',
    () async {
      final Completer<DelegatedResult> never = Completer<DelegatedResult>();
      final AppSyncPort app = AppSyncPort(
        () => true,
        () => never.future,
        registry: registry,
      );
      addTearDown(app.close);
      expect(
        await askApp(
          registry: registry,
          done: const Duration(milliseconds: 100),
        ),
        isA<AppSynced>().having((a) => a.result, 'result', isNull),
      );
    },
  );

  test('a mapping nothing answers is removed', () async {
    final ReceivePort dead = ReceivePort();
    registry.register(dead.sendPort, appPortName);
    expect(
      await askApp(
        registry: registry,
        ack: const Duration(milliseconds: 100),
        secondAck: const Duration(milliseconds: 100),
      ),
      isA<NoApp>(),
    );
    expect(registry.lookup(appPortName), isNull);
    dead.close();
  });

  test(
    "a starting app waits for the worker's cycle, at most the ceiling",
    () async {
      await waitForBackgroundCycle(registry: registry);
      final BackgroundCyclePort cycle = (await acquireBackgroundCycle(
        registry: registry,
      ))!;
      final Stopwatch watch = Stopwatch()..start();
      Timer(const Duration(milliseconds: 300), cycle.release);
      await waitForBackgroundCycle(
        registry: registry,
        poll: const Duration(milliseconds: 20),
      );
      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(300));

      final BackgroundCyclePort stuck = (await acquireBackgroundCycle(
        registry: registry,
      ))!;
      addTearDown(stuck.release);
      watch.reset();
      await waitForBackgroundCycle(
        registry: registry,
        ceiling: const Duration(milliseconds: 200),
        poll: const Duration(milliseconds: 20),
      );
      expect(watch.elapsedMilliseconds, lessThan(1000));
    },
  );

  test('a stale worker mapping is removed at once', () async {
    final ReceivePort dead = ReceivePort();
    registry.register(dead.sendPort, backgroundPortName);
    dead.close();
    await waitForBackgroundCycle(
      registry: registry,
      ping: const Duration(milliseconds: 100),
    );
    expect(registry.lookup(backgroundPortName), isNull);
  });

  test('an app slow to acknowledge is kept, and asked once more', () async {
    final ReceivePort slow = ReceivePort();
    int asks = 0;
    slow.listen((message) {
      asks++;
      final SendPort reply = (message as List).first as SendPort;
      // Only the second ask is answered, late for the first wait.
      if (asks == 2) {
        reply
          ..send(['ack'])
          ..send(['done', 'success']);
      }
    });
    addTearDown(slow.close);
    registry.register(slow.sendPort, appPortName);
    expect(
      await askApp(
        registry: registry,
        ack: const Duration(milliseconds: 100),
        secondAck: const Duration(milliseconds: 500),
      ),
      isA<AppSynced>(),
    );
    expect(asks, 2);
    expect(registry.lookup(appPortName), slow.sendPort);
  });

  test('a mapping another app took meanwhile is not removed', () async {
    final ReceivePort dead = ReceivePort();
    registry.register(dead.sendPort, appPortName);
    final Future<AppAnswer> asked = askApp(
      registry: registry,
      ack: const Duration(milliseconds: 100),
      secondAck: const Duration(milliseconds: 100),
    );
    // A new engine's app replaces the dead one while the worker waits.
    registry.remove(appPortName);
    final AppSyncPort app = AppSyncPort(
      () => true,
      () async => DelegatedResult.success,
      registry: registry,
    );
    addTearDown(app.close);
    final SendPort? live = registry.lookup(appPortName);
    expect(await asked, isA<NoApp>());
    expect(registry.lookup(appPortName), live);
    dead.close();
  });

  test('the app registers again after a worker removed it', () async {
    final AppSyncPort app = AppSyncPort(
      () => true,
      () async => DelegatedResult.success,
      registry: registry,
    );
    addTearDown(app.close);
    final SendPort? own = registry.lookup(appPortName);
    registry.remove(appPortName);
    app.register();
    expect(registry.lookup(appPortName), own);
    app.register();
    expect(registry.lookup(appPortName), own);
  });

  test(
    'the lock is taken once; a live holder keeps it, a dead one loses it',
    () async {
      final BackgroundCyclePort first = (await acquireBackgroundCycle(
        registry: registry,
      ))!;
      expect(await acquireBackgroundCycle(registry: registry), isNull);
      first.release();
      final BackgroundCyclePort second = (await acquireBackgroundCycle(
        registry: registry,
      ))!;
      second.release();

      final ReceivePort dead = ReceivePort();
      registry.register(dead.sendPort, backgroundPortName);
      dead.close();
      final BackgroundCyclePort taken = (await acquireBackgroundCycle(
        registry: registry,
        ping: const Duration(milliseconds: 100),
      ))!;
      expect(registry.lookup(backgroundPortName), isNot(dead.sendPort));
      taken.release();
      expect(registry.lookup(backgroundPortName), isNull);
    },
  );

  test('a release leaves a lock another took alone', () async {
    final BackgroundCyclePort mine = (await acquireBackgroundCycle(
      registry: registry,
    ))!;
    registry.remove(backgroundPortName);
    final BackgroundCyclePort theirs = (await acquireBackgroundCycle(
      registry: registry,
    ))!;
    mine.release();
    expect(registry.lookup(backgroundPortName), isNotNull);
    theirs.release();
  });

  test('a worker and an app starting together see each other', () async {
    // Each registers before it looks at the other's name.
    final BackgroundCyclePort lock = (await acquireBackgroundCycle(
      registry: registry,
    ))!;
    int synced = 0;
    final AppSyncPort app = AppSyncPort(() => true, () async {
      synced++;
      return DelegatedResult.success;
    }, registry: registry);
    addTearDown(app.close);
    bool waited = false;
    final Future<void> starting = waitForBackgroundCycle(
      registry: registry,
      poll: const Duration(milliseconds: 10),
    ).then((_) => waited = true);
    // The worker, holding the lock, finds the app and leaves the sync to it.
    expect(await askApp(registry: registry), isA<AppSynced>());
    expect(waited, isFalse, reason: 'the lock is still held');
    lock.release();
    await starting;
    expect(synced, 1);
  });

  test(
    'a holder that stops answering ends the wait, its mapping removed',
    () async {
      final ReceivePort holder = ReceivePort();
      holder.listen((message) {
        ((message as List).first as SendPort).send(['pong']);
      });
      registry.register(holder.sendPort, backgroundPortName);
      // Its engine dies with its cycle pending: the name stays, the pings go unanswered.
      Timer(const Duration(milliseconds: 200), holder.close);
      final Stopwatch watch = Stopwatch()..start();
      await waitForBackgroundCycle(
        registry: registry,
        ping: const Duration(milliseconds: 100),
        poll: const Duration(milliseconds: 20),
      );
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(registry.lookup(backgroundPortName), isNull);
    },
  );

  test(
    'two workers taking one dead holder\'s lock: exactly one keeps it',
    () async {
      final ReceivePort dead = ReceivePort()..close();
      final _StaleRegistry racing = _StaleRegistry(dead.sendPort, 4);
      racing.register(dead.sendPort, backgroundPortName);
      final List<BackgroundCyclePort?> taken = await Future.wait([
        acquireBackgroundCycle(
          registry: racing,
          ping: const Duration(milliseconds: 50),
        ),
        acquireBackgroundCycle(
          registry: racing,
          ping: const Duration(milliseconds: 50),
        ),
      ]);
      expect(taken.whereType<BackgroundCyclePort>(), hasLength(1));
      taken.whereType<BackgroundCyclePort>().single.release();
      expect(racing.lookup(backgroundPortName), isNull);
    },
  );
}
