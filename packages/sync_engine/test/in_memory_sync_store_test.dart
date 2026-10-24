// The in-memory store, the reference for the SyncStore contract: transactions roll back
// on a throw, serialize with each other and with standalone calls, and nest.
import 'dart:async';

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

EntityRecord record(String id, String name) => EntityRecord(
  type: EntityType.goal,
  id: id,
  fields: {'name': name},
  fieldClocks: {'name': Hlc(1, 0, 'a')},
);

ChangeLogEntry entry(int wall) => ChangeLogEntry(
  entityType: EntityType.goal,
  entityId: 'g',
  operation: ChangeOperation.update,
  payload: const {'name': 'x'},
  hlc: Hlc(wall, 0, 'a'),
  deviceId: 'a',
  synced: false,
);

void main() {
  test('a throwing transaction leaves nothing behind', () async {
    final store = InMemorySyncStore();
    await store.write(record('g1', 'before'));
    await store.savePullCursor(3);
    await expectLater(
      store.transaction(() async {
        await store.write(record('g1', 'after'));
        await store.write(record('g2', 'new'));
        await store.append(entry(5));
        await store.savePullCursor(9);
        await store.saveClock(Hlc(9, 0, 'a'));
        throw StateError('crash');
      }),
      throwsStateError,
    );
    expect((await store.read(EntityType.goal, 'g1'))!.fields['name'], 'before');
    expect(await store.read(EntityType.goal, 'g2'), isNull);
    expect(await store.unsynced(), isEmpty);
    expect(await store.pullCursor(), 3);
    expect(await store.lastClock(), isNull);
  });

  test('a failing operation inside a transaction rolls it back', () async {
    final store = InMemorySyncStore()
      ..failBefore = (op) {
        if (op == 'savePullCursor') throw StateError('disk');
      };
    await expectLater(
      store.transaction(() async {
        await store.write(record('g1', 'x'));
        await store.savePullCursor(1);
      }),
      throwsStateError,
    );
    expect(store.records, isEmpty);
  });

  test('transactions do not interleave, and standalone calls wait', () async {
    final store = InMemorySyncStore();
    final events = <String>[];
    final gate = Completer<void>();
    final first = store.transaction(() async {
      events.add('first start');
      await gate.future;
      await store.write(record('g1', 'first'));
      events.add('first end');
    });
    final second = store.transaction(() async {
      events.add('second start');
      events.add(
        'second sees ${(await store.read(EntityType.goal, 'g1'))?.fields['name']}',
      );
    });
    final read = store
        .read(EntityType.goal, 'g1')
        .then((r) => events.add('read ${r?.fields['name']}'));
    await Future<void>.delayed(Duration.zero);
    expect(events, ['first start']);
    gate.complete();
    await Future.wait([first, second, read]);
    expect(events, [
      'first start',
      'first end',
      'second start',
      'second sees first',
      'read first',
    ]);
  });

  test('a nested transaction joins the outer one', () async {
    final store = InMemorySyncStore();
    await expectLater(
      store.transaction(() async {
        await store.transaction(() => store.write(record('g1', 'inner')));
        throw StateError('outer fails');
      }),
      throwsStateError,
    );
    expect(store.records, isEmpty);
  });

  test(
    'unsynced is in clock order, limited, and markSynced removes entries',
    () async {
      final store = InMemorySyncStore();
      for (final w in [5, 1, 3, 2, 4]) {
        await store.append(entry(w));
      }
      expect((await store.unsynced(limit: 3)).map((e) => e.hlc.wallMillis), [
        1,
        2,
        3,
      ]);
      await store.markSynced([Hlc(1, 0, 'a'), Hlc(3, 0, 'a')]);
      expect((await store.unsynced()).map((e) => e.hlc.wallMillis), [2, 4, 5]);
      expect(store.outbox, hasLength(5));
    },
  );

  test(
    'markRejected moves entries out of the outbox, with their reason',
    () async {
      final store = InMemorySyncStore();
      for (final w in [1, 2, 3]) {
        await store.append(entry(w));
      }
      await store.markRejected([Hlc(2, 0, 'a')], PushRejectionReason.invalid);
      expect((await store.unsynced()).map((e) => e.hlc.wallMillis), [1, 3]);
      expect(store.outbox, hasLength(2));
      expect(store.rejected.single.$1.hlc, Hlc(2, 0, 'a'));
      expect(store.rejected.single.$2, PushRejectionReason.invalid);
      await expectLater(
        store.transaction(() async {
          await store.markRejected([
            Hlc(1, 0, 'a'),
          ], PushRejectionReason.invalid);
          throw StateError('crash');
        }),
        throwsStateError,
      );
      expect(store.rejected, hasLength(1));
      expect(store.outbox, hasLength(2));
    },
  );
}
