// The push/pull session: batching, rejections, failures on either side and resume, the
// pull cursor across a crash, idempotent re-pulls, the clock bound, own entries, and one
// run at a time.
import 'dart:async';

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'support/hooked_relay.dart';

const hour = 3600 * 1000;
const type = EntityType.category;

/// One simulated device.
class Device {
  Device(this.id, SyncRelay relay, {this.now = 1000, int page = 200}) {
    clock = HlcClock(id);
    editor = LocalEditor(store, clock);
    session = SyncSession(
      store,
      relay,
      clock,
      nowWallMillis: () => now,
      pushBatchSize: page,
      pullPageSize: page,
    );
  }

  final String id;
  int now;
  final store = InMemorySyncStore();
  late final HlcClock clock;
  late final LocalEditor editor;
  late final SyncSession session;

  Future<void> create(String entityId, [String name = 'n']) async {
    await editor.recordChange(type, entityId, null, {
      'id': entityId,
      'name': name,
      'deleted_at': null,
    }, now);
    now++;
  }

  Future<void> rename(String entityId, String name) async {
    final before = (await store.read(type, entityId))!.fields;
    await editor.recordChange(type, entityId, before, {
      ...before,
      'name': name,
    }, now);
    now++;
  }

  String state() =>
      [for (final r in store.records.values) r.toCanonicalJson()].join('\n');
}

void main() {
  late InMemorySyncRelay inner;
  late HookedRelay relay;
  var relayNow = 1000;
  setUp(() {
    relayNow = 1000;
    inner = InMemorySyncRelay(nowWallMillis: () => relayNow);
    relay = HookedRelay(inner);
  });

  test('a change on one device reaches another', () async {
    final a = Device('a', relay), b = Device('b', relay);
    await a.create('c1', 'Food');
    final ra = await a.session.run();
    expect((ra.pushed, ra.pulled), (1, 0));
    expect(ra.rejected, isEmpty);
    final rb = await b.session.run();
    expect((rb.pushed, rb.pulled, rb.applied), (0, 1, 1));
    expect(rb.changed, {(type: type, id: 'c1')});
    expect(b.state(), a.state());
    expect(await a.store.unsynced(), isEmpty);
    expect(
      b.clock.last.compareTo((await a.store.lastClock())!),
      greaterThan(0),
    );
    expect(await b.store.lastClock(), b.clock.last);
    expect(await b.store.pullCursor(), 1);
  });

  test('pushes in clock order in batches of the batch size', () async {
    final a = Device('a', relay, page: 200);
    for (var i = 0; i < 450; i++) {
      await a.create('c$i');
    }
    final r = await a.session.run();
    expect(r.pushed, 450);
    expect(relay.pushCalls, 3);
    final walls = inner.entries.map((e) => e.hlc).toList();
    expect(walls, [...walls]..sort());
  });

  test(
    "the caller's own entries are not pulled, and the cursor passes them",
    () async {
      final a = Device('a', relay, page: 2), b = Device('b', relay, page: 2);
      await a.create('c1');
      await a.create('c2');
      await a.session.run();
      await b.create('c3');
      await b.session.run();
      await a.create('c4');
      final r = await a.session.run();
      expect(r.pulled, 1, reason: "only b's entry");
      expect(await a.store.pullCursor(), 4);
      final again = await a.session.run();
      expect((again.pulled, again.applied), (0, 0));
    },
  );

  test(
    'own entries from a relay that does not filter them are harmless',
    () async {
      final a = Device('a', relay), b = Device('b', relay);
      await a.create('c1');
      await a.rename('c1', 'x');
      await b.create('c2');
      await b.session.run();
      await a.session.run();
      final before = a.state();
      relay.filterOwn = false;
      await a.store.savePullCursor(0);
      final r = await a.session.run();
      expect(r.pulled, 3);
      expect(r.applied, 0);
      expect(r.changed, isEmpty);
      expect(a.state(), before);
    },
  );

  test(
    'a rejected entry stays unsynced and stops the push; it goes later',
    () async {
      final a = Device('a', relay, page: 2);
      a.now = 1000 + 2 * hour; // a's clock is two hours ahead of the relay
      await a.create('c1');
      await a.create('c2');
      await a.create('c3');
      final r = await a.session.run();
      expect(r.pushed, 0);
      expect(r.rejected.map((x) => x.reason), [
        PushRejectionReason.clockDrift,
        PushRejectionReason.clockDrift,
      ]);
      expect(
        relay.pushCalls,
        1,
        reason: 'the push stopped at the first rejection',
      );
      expect(await a.store.unsynced(), hasLength(3));
      relayNow = 1000 + 2 * hour;
      final later = await a.session.run();
      expect(later.pushed, 3);
      expect(later.rejected, isEmpty);
    },
  );

  test(
    'permanently rejected entries leave the outbox and do not block',
    () async {
      final a = Device('a', relay, page: 2);
      // Two malformed entries ahead of a good one in clock order: an empty payload, and a
      // clock issued by another node.
      await a.store.append(
        ChangeLogEntry(
          entityType: type,
          entityId: 'bad1',
          operation: ChangeOperation.update,
          payload: const {},
          hlc: Hlc(1, 0, 'a'),
          deviceId: 'a',
          synced: false,
        ),
      );
      await a.store.append(
        ChangeLogEntry(
          entityType: type,
          entityId: 'bad2',
          operation: ChangeOperation.update,
          payload: const {'name': 'x'},
          hlc: Hlc(2, 0, 'z'),
          deviceId: 'a',
          synced: false,
        ),
      );
      await a.create('good');
      final r = await a.session.run();
      expect(r.pushed, 1);
      expect(r.rejected.map((x) => x.reason), [
        PushRejectionReason.invalid,
        PushRejectionReason.invalid,
      ]);
      expect(inner.entries.single.entityId, 'good');
      expect(await a.store.unsynced(), isEmpty);
      expect(a.store.rejected.map((x) => (x.$1.entityId, x.$2)), [
        ('bad1', PushRejectionReason.invalid),
        ('bad2', PushRejectionReason.invalid),
      ]);
      final again = await a.session.run();
      expect(again.rejected, isEmpty);
    },
  );

  test('a conflicting duplicate is rejected for good', () async {
    final a = Device('a', relay);
    await a.create('c1');
    final original = (await a.store.unsynced()).single;
    await inner.push([
      original.copyWith(payload: const {'id': 'c1', 'name': 'other'}),
    ]);
    final r = await a.session.run();
    expect(r.rejected.single.reason, PushRejectionReason.conflictingDuplicate);
    expect(await a.store.unsynced(), isEmpty);
    expect(
      a.store.rejected.single.$2,
      PushRejectionReason.conflictingDuplicate,
    );
  });

  test('a create concurrent with a delete never resurrects it', () async {
    final a = Device('a', relay),
        b = Device('b', relay),
        c = Device('c', relay);
    await a.create('c1', 'from a');
    await a.session.run();
    await b.session.run();
    final before = (await b.store.read(type, 'c1'))!.fields;
    b.now += 10;
    await b.editor.recordChange(type, 'c1', before, {
      ...before,
      'deleted_at': '2026-10-24T00:00:00.000Z',
    }, b.now);
    await b.session.run();
    // c never saw either and creates the same id later, with a greater clock.
    c.now += 1000;
    await c.create('c1', 'from c');
    for (final d in [c, a, b, c]) {
      await d.session.run();
    }
    for (final d in [a, b, c]) {
      final r = (await d.store.read(type, 'c1'))!;
      expect(r.isDeleted, isTrue, reason: d.id);
      expect(r.fields['name'], 'from c', reason: d.id);
    }
    expect(a.state(), c.state());
    expect(b.state(), c.state());
  });

  test(
    'a push that never arrived leaves entries unsynced; the rerun sends them',
    () async {
      final a = Device('a', relay);
      await a.create('c1');
      relay.before = (op) => op == 'push' ? throw StateError('offline') : null;
      await expectLater(a.session.run(), throwsStateError);
      expect(inner.entries, isEmpty);
      expect(await a.store.unsynced(), hasLength(1));
      relay.before = null;
      expect((await a.session.run()).pushed, 1);
      expect(inner.entries, hasLength(1));
    },
  );

  test('a push whose response was lost is resent and stored once', () async {
    final a = Device('a', relay);
    await a.create('c1');
    relay.after = (op) => op == 'push' ? throw StateError('lost') : null;
    await expectLater(a.session.run(), throwsStateError);
    expect(inner.entries, hasLength(1));
    expect(await a.store.unsynced(), hasLength(1));
    relay.after = null;
    expect((await a.session.run()).pushed, 1);
    expect(inner.entries, hasLength(1));
    expect(await a.store.unsynced(), isEmpty);
  });

  test(
    'a pull failing on a later page keeps the earlier pages and resumes',
    () async {
      final a = Device('a', relay), b = Device('b', relay, page: 2);
      for (var i = 0; i < 5; i++) {
        await a.create('c$i');
      }
      await a.session.run();
      var pulls = 0;
      relay.before = (op) {
        if (op == 'pull' && ++pulls == 2) throw StateError('offline');
      };
      await expectLater(b.session.run(), throwsStateError);
      expect(await b.store.pullCursor(), 2);
      expect(b.store.records, hasLength(2));
      relay.before = null;
      final r = await b.session.run();
      expect(r.pulled, 3);
      expect(b.state(), a.state());
    },
  );

  test(
    'a crash between merging a page and saving its cursor re-pulls the page',
    () async {
      final a = Device('a', relay), b = Device('b', relay, page: 2);
      for (var i = 0; i < 4; i++) {
        await a.create('c$i');
      }
      await a.session.run();
      var saves = 0;
      b.store.failBefore = (op) {
        if (op == 'savePullCursor' && ++saves == 2) throw StateError('crash');
      };
      await expectLater(b.session.run(), throwsStateError);
      expect(
        await b.store.pullCursor(),
        2,
        reason: 'the second page rolled back',
      );
      expect(b.store.records, hasLength(2));
      b.store.failBefore = null;
      final r = await b.session.run();
      expect((r.pulled, r.applied), (2, 2));
      expect(b.state(), a.state());
    },
  );

  test(
    'a page merged but whose cursor was lost merges again idempotently',
    () async {
      final a = Device('a', relay), b = Device('b', relay);
      await a.create('c1');
      await a.rename('c1', 'x');
      await a.session.run();
      await b.session.run();
      final before = b.state();
      await b.store.savePullCursor(
        0,
      ); // as if the cursor had never been written
      final r = await b.session.run();
      expect((r.pulled, r.applied), (2, 0));
      expect(r.changed, isEmpty);
      expect(b.state(), before);
    },
  );

  test('an entry beyond the clock bound is applied and the clock clamps; '
      'a later local edit of its field wins everywhere', () async {
    relayNow = 1000 + 3 * hour;
    final a = Device('a', relay, page: 1), b = Device('b', relay, page: 1);
    await a.create('c1');
    a.now = 1000 + 3 * hour;
    await a.rename('c1', 'From a');
    await a.session.run();
    final r = await b.session.run(); // b's clock reads 1000, three hours behind
    expect((r.pulled, r.applied, r.clamped), (2, 2, 1));
    expect(await b.store.pullCursor(), 2);
    expect(b.state(), a.state());
    expect(b.clock.last.wallMillis, lessThanOrEqualTo(b.now + hour));
    expect(b.clock.last.compareTo(a.clock.last), lessThan(0));
    await b.rename('c1', 'From b');
    expect(
      (await b.store.read(type, 'c1'))!.fields['name'],
      'From b',
      reason:
          "b's edit is stamped after the value it changed, so it shows at once",
    );
    expect(b.clock.last.compareTo(a.clock.last), greaterThan(0));
    final pushed = await b.session.run();
    expect(pushed.pushed, 1);
    expect(pushed.rejected, isEmpty);
    await a.session.run();
    expect(b.state(), a.state());
    expect((await a.store.read(type, 'c1'))!.fields['name'], 'From b');
  });

  test('a run while one is in flight returns the same run', () async {
    final a = Device('a', relay);
    await a.create('c1');
    final gate = Completer<void>();
    relay.before = (_) => gate.future;
    final first = a.session.run();
    final second = a.session.run();
    expect(identical(first, second), isTrue);
    gate.complete();
    await first;
    relay.before = null;
    expect(identical(a.session.run(), first), isFalse);
    expect(relay.pushCalls, 1);
  });

  test(
    'concurrent edits on two devices converge after both sync twice',
    () async {
      final a = Device('a', relay), b = Device('b', relay);
      await a.create('c1', 'A');
      await a.session.run();
      await b.session.run();
      await a.rename('c1', 'from a');
      b.now += 5;
      await b.rename('c1', 'from b');
      await Future.wait([a.session.run(), b.session.run()]);
      await a.session.run();
      await b.session.run();
      expect(a.state(), b.state());
      expect(a.store.records.values.single.fields['name'], 'from b');
    },
  );

  test(
    'after a relay reset the run throws, and a reset cursor converges',
    () async {
      final a = Device('a', relay), b = Device('b', relay);
      for (var i = 0; i < 3; i++) {
        await b.create('c$i');
      }
      await b.session.run();
      await a.session.run();
      expect(await a.store.pullCursor(), 3);

      // The relay is wiped; b pushes one new change into the fresh one.
      final fresh = InMemorySyncRelay(nowWallMillis: () => relayNow);
      SyncSession sessionOn(Device d) =>
          SyncSession(d.store, fresh, d.clock, nowWallMillis: () => d.now);
      await b.create('after-reset');
      final bSession = sessionOn(b);
      // b had pulled too, so its run pushes and then hits the same invalid cursor.
      await expectLater(
        bSession.run(),
        throwsA(isA<SyncCursorInvalidException>()),
      );
      await b.store.savePullCursor(0);
      await bSession.run();
      expect(fresh.entries.single.entityId, 'after-reset');

      final aSession = sessionOn(a);
      await expectLater(
        aSession.run(),
        throwsA(
          isA<SyncCursorInvalidException>()
              .having((e) => e.since, 'since', 3)
              .having((e) => e.lastSeq, 'lastSeq', 1),
        ),
      );
      // The host's recovery: reset the cursor and run again.
      await a.store.savePullCursor(0);
      final r = await aSession.run();
      expect(r.applied, 1);
      expect(await a.store.pullCursor(), 1);
      expect(a.store.records.keys, contains((type: type, id: 'after-reset')));
      expect(a.state(), b.state());
    },
  );

  group('conflicts', () {
    // a and b rename c1 a minute apart; c only watches.
    Future<(Device, Device, Device)> race({int delay = 60 * 1000}) async {
      final a = Device('a', relay), b = Device('b', relay);
      final c = Device('c', relay);
      await a.create('c1', 'A');
      await a.session.run();
      await b.session.run();
      await c.session.run();
      await a.rename('c1', 'from a');
      b.now = a.now + delay;
      await b.rename('c1', 'from b');
      return (a, b, c);
    }

    test('the device whose own edit lost keeps the conflict', () async {
      final (a, b, c) = await race();
      final rb = await b.session.run();
      expect(rb.conflicts, 0);
      final ra = await a.session.run();
      expect(ra.conflicts, 1);
      final conflict = a.store.conflicts.single;
      expect(conflict.field, 'name');
      expect(conflict.localValue, 'from a');
      expect(conflict.localDevice, 'a');
      expect(conflict.remoteValue, 'from b');
      expect(conflict.remoteDevice, 'b');
      expect(a.store.records.values.single.fields['name'], 'from b');
      // b's value won: b merges a's older entry without overwriting anything.
      expect((await b.session.run()).conflicts, 0);
      expect(b.store.conflicts, isEmpty);
      // c overwrote a's value with b's too, but neither was c's own.
      expect((await c.session.run()).conflicts, 0);
      expect(c.store.conflicts, isEmpty);
      expect(a.state(), b.state());
      expect(c.state(), b.state());
    });

    test('keeping the lost value is an edit that wins everywhere', () async {
      final (a, b, _) = await race();
      await b.session.run();
      await a.session.run();
      final lost = a.store.conflicts.single;
      await a.rename('c1', lost.localValue! as String);
      await a.session.run();
      final rb = await b.session.run();
      // b's value lost within ten minutes in turn, so b is asked now.
      expect(rb.conflicts, 1);
      expect(b.store.conflicts.single.localValue, 'from b');
      expect(a.state(), b.state());
      expect(b.store.records.values.single.fields['name'], 'from a');
    });

    test('conflicts roll back with a page that fails', () async {
      final (a, b, _) = await race();
      await b.session.run();
      a.store.failBefore = (op) {
        if (op == 'savePullCursor') throw StateError('crash');
      };
      await expectLater(a.session.run(), throwsStateError);
      expect(a.store.conflicts, isEmpty);
      a.store.failBefore = null;
      expect((await a.session.run()).conflicts, 1);
      expect(a.store.conflicts, hasLength(1));
    });

    test('edits more than ten minutes apart are not conflicts', () async {
      final (a, b, _) = await race(delay: 11 * 60 * 1000);
      await b.session.run();
      final ra = await a.session.run();
      expect(ra.conflicts, 0);
      expect(a.store.conflicts, isEmpty);
    });
  });

  group('beforePush', () {
    SyncSession held(
      Device d,
      bool Function(ChangeLogEntry) wait, {
      int page = 200,
    }) => SyncSession(
      d.store,
      relay,
      d.clock,
      nowWallMillis: () => d.now,
      pushBatchSize: page,
      pullPageSize: page,
      beforePush: (batch) async => [
        for (final e in batch)
          if (!wait(e)) e,
      ],
    );

    test(
      'an entry held back stays unsynced and goes on the next run',
      () async {
        final a = Device('a', relay);
        await a.create('c1');
        await a.create('c2');
        await a.create('c3');
        final r = await held(a, (e) => e.entityId == 'c2').run();
        expect((r.pushed, r.deferred), (2, 1));
        expect([for (final e in inner.entries) e.entityId], ['c1', 'c3']);
        expect([for (final e in await a.store.unsynced()) e.entityId], ['c2']);
        final again = await a.session.run();
        expect((again.pushed, again.deferred), (1, 0));
        final b = Device('b', relay);
        await b.session.run();
        expect(b.store.records, a.store.records);
      },
    );

    test('entries held back never hold up the ones behind them', () async {
      final a = Device('a', relay);
      for (var i = 0; i < 9; i++) {
        await a.create('c$i');
      }
      // The first five wait; batches of two.
      final waiting = {for (var i = 0; i < 5; i++) 'c$i'};
      var calls = 0;
      final session = SyncSession(
        a.store,
        relay,
        a.clock,
        nowWallMillis: () => a.now,
        pushBatchSize: 2,
        beforePush: (batch) async {
          calls++;
          expect(batch.length, lessThanOrEqualTo(2));
          return [
            for (final e in batch)
              if (!waiting.contains(e.entityId)) e,
          ];
        },
      );
      final r = await session.run();
      expect((r.pushed, r.deferred), (4, 5));
      expect(calls, 5, reason: 'each entry is offered once');
      expect(
        [for (final e in inner.entries) e.entityId],
        ['c5', 'c6', 'c7', 'c8'],
      );
    });

    test('an entry held back by every batch ends the push', () async {
      final a = Device('a', relay);
      await a.create('c1');
      final r = await held(a, (_) => true).run();
      expect((r.pushed, r.deferred), (0, 1));
      expect(relay.pushCalls, 0);
    });
  });
}
