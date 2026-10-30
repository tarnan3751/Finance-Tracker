// The contract every ConflictStore implementation passes: the in-memory and Drift ones,
// each from its own test file under test/features/conflicts/data/, each given the way its
// conflicts arrive (a session's, through the sync store, for Drift).
import 'package:finance_tracker/features/conflicts/domain/conflict_store.dart';
import 'package:finance_tracker/features/conflicts/domain/sync_conflict.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

/// A conflict on [field] of transaction [id], seen at [seenAt] (the Drift store stamps its
/// own clock instead).
SyncConflict testConflict(
  String id,
  String field, {
  Object? local = 'mine',
  Object? remote = 'theirs',
  DateTime? seenAt,
}) => SyncConflict(
  entityType: EntityType.transaction,
  entityId: id,
  field: field,
  localValue: local,
  localClock: Hlc(1761318000000, 0, 'dev-a'),
  remoteValue: remote,
  remoteClock: Hlc(1761318060000, 0, 'dev-b'),
  entityLabel: null,
  seenAt: seenAt ?? DateTime.utc(2026, 10, 24, 15),
);

/// Registers the contract tests for the stores [create] builds; [add] keeps a conflict as
/// a session would.
void runConflictStoreContract(
  Future<ConflictStore> Function() create, {
  required Future<void> Function(SyncConflict conflict) add,
  Future<void> Function()? dispose,
}) {
  group('ConflictStore contract', () {
    late ConflictStore store;

    setUp(() async => store = await create());
    if (dispose != null) tearDown(dispose);

    test('starts empty', () async {
      expect(await store.watch().first, isEmpty);
    });

    test('keeps both values, both clocks and nested values', () async {
      await add(
        testConflict(
          't1',
          'tags',
          local: ['a', 'b'],
          remote: {'minor_units': 5, 'currency': 'USD'},
        ),
      );
      final SyncConflict kept = (await store.watch().first).single;
      expect(kept.key, (type: EntityType.transaction, id: 't1', field: 'tags'));
      expect(kept.localValue, ['a', 'b']);
      expect(kept.remoteValue, {'minor_units': 5, 'currency': 'USD'});
      expect(kept.localClock, Hlc(1761318000000, 0, 'dev-a'));
      expect(kept.remoteClock, Hlc(1761318060000, 0, 'dev-b'));
      expect(kept.seenAt.isUtc, isTrue);
    });

    test('one per entity and field: a newer one replaces it', () async {
      await add(testConflict('t1', 'notes', local: 'first'));
      await add(testConflict('t1', 'notes', local: 'second'));
      await add(testConflict('t1', 'name'));
      final List<SyncConflict> list = await store.watch().first;
      expect(list.map((c) => c.field).toSet(), {'name', 'notes'});
      expect(list.firstWhere((c) => c.field == 'notes').localValue, 'second');
    });

    test('dismiss forgets one; dismissing a gone one does nothing', () async {
      await add(testConflict('t1', 'notes'));
      await add(testConflict('t2', 'notes'));
      await store.dismiss(testConflict('t1', 'notes'));
      await store.dismiss(testConflict('t9', 'notes'));
      expect((await store.watch().first).map((c) => c.entityId), ['t2']);
    });

    test('a watcher sees each change', () async {
      final List<int> seen = [];
      final sub = store.watch().listen((l) => seen.add(l.length));
      addTearDown(sub.cancel);
      await pumpEventQueue();
      await add(testConflict('t1', 'notes'));
      await pumpEventQueue();
      await store.dismiss(testConflict('t1', 'notes'));
      await pumpEventQueue();
      expect(seen, [0, 1, 0]);
    });
  });
}
