// The local edit path: diff, stamp, store and outbox in one transaction; an edit stamped
// past the values it changes, beyond the clock bound included, also over a store that
// reads values from the host's rows as the app's does.
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

const type = EntityType.budget;
const hour = 3600 * 1000;

/// A store shaped like the app's: the host writes an entity's row before recording the
/// change, and [read] takes values from the rows under the stored clocks, so the record
/// a recording reads already holds the edit's values.
final class RowStore implements SyncStore {
  final inner = InMemorySyncStore();
  final rows = <EntityKey, Map<String, Object?>>{};

  @override
  Future<EntityRecord?> read(EntityType type, String id) async {
    final r = await inner.read(type, id);
    if (r == null) return null;
    final row = rows[r.key]!;
    return EntityRecord(
      type: type,
      id: id,
      fields: {for (final f in r.fieldClocks.keys) f: row[f]},
      fieldClocks: r.fieldClocks,
      createdAt: r.createdAt,
    );
  }

  @override
  Future<void> write(EntityRecord record) async {
    await inner.write(record);
    rows[record.key] = {...?rows[record.key], ...record.fields};
  }

  @override
  Future<T> transaction<T>(Future<T> Function() body) =>
      inner.transaction(body);
  @override
  Future<void> holdUnknownType(UnknownTypeEntry entry) =>
      inner.holdUnknownType(entry);
  @override
  Future<List<ChangeLogEntry>> unsynced({int limit = 200}) =>
      inner.unsynced(limit: limit);
  @override
  Future<void> markSynced(Iterable<Hlc> hlcs) => inner.markSynced(hlcs);
  @override
  Future<void> markRejected(Iterable<Hlc> hlcs, PushRejectionReason reason) =>
      inner.markRejected(hlcs, reason);
  @override
  Future<void> recordConflicts(List<FieldConflict> conflicts) =>
      inner.recordConflicts(conflicts);
  @override
  Future<void> append(ChangeLogEntry entry) => inner.append(entry);
  @override
  Future<int?> pullCursor() => inner.pullCursor();
  @override
  Future<void> savePullCursor(int seq) => inner.savePullCursor(seq);
  @override
  Future<Hlc?> lastClock() => inner.lastClock();
  @override
  Future<void> saveClock(Hlc clock) => inner.saveClock(clock);
}

/// Another device's create of b1, stamped [at].
ChangeLogEntry remoteCreate(Hlc at) => ChangeLogEntry(
  entityType: type,
  entityId: 'b1',
  operation: ChangeOperation.create,
  payload: budget()..remove('deleted_at'),
  hlc: at,
  deviceId: at.nodeId,
  synced: true,
);

Map<String, Object?> budget({
  String? name,
  int amount = 5000,
  Object? deletedAt,
}) => {
  'id': 'b1',
  'name': name ?? 'Food',
  'amount': {'minor_units': amount, 'currency': 'USD'},
  'deleted_at': deletedAt,
};

void main() {
  late InMemorySyncStore store;
  late HlcClock clock;
  late LocalEditor editor;
  setUp(() {
    store = InMemorySyncStore();
    clock = HlcClock('dev-a');
    editor = LocalEditor(store, clock);
  });

  test('a create writes the record, the outbox entry and the clock', () async {
    final e = (await editor.recordChange(type, 'b1', null, budget(), 1000))!;
    expect(e.operation, ChangeOperation.create);
    expect(e.hlc, Hlc(1000, 0, 'dev-a'));
    final r = (await store.read(type, 'b1'))!;
    expect(r.fields, budget()..remove('deleted_at'));
    expect(r.createdAt, e.hlc);
    expect(r.fieldClocks.values.toSet(), {e.hlc});
    expect(await store.unsynced(), [e]);
    expect(await store.lastClock(), e.hlc);
  });

  test(
    'an update stamps only its fields and the clock moves forward',
    () async {
      await editor.recordChange(type, 'b1', null, budget(), 1000);
      final e = (await editor.recordChange(
        type,
        'b1',
        budget(),
        budget(amount: 6000),
        1000,
      ))!;
      expect(e.hlc, Hlc(1000, 1, 'dev-a'));
      final r = (await store.read(type, 'b1'))!;
      expect(r.fieldClocks['amount'], e.hlc);
      expect(r.fieldClocks['name'], Hlc(1000, 0, 'dev-a'));
      expect(await store.unsynced(), hasLength(2));
    },
  );

  test('no change records nothing', () async {
    await editor.recordChange(type, 'b1', null, budget(), 1000);
    expect(
      await editor.recordChange(type, 'b1', budget(), budget(), 2000),
      isNull,
    );
    expect(await store.unsynced(), hasLength(1));
  });

  test('a delete stores the entry wall instant as the tombstone', () async {
    await editor.recordChange(type, 'b1', null, budget(), 1000);
    final at = DateTime.utc(2026, 10, 24, 12).millisecondsSinceEpoch;
    final e = (await editor.recordChange(
      type,
      'b1',
      budget(),
      budget(deletedAt: 'whatever the host wrote'),
      at,
    ))!;
    expect(e.operation, ChangeOperation.delete);
    final r = (await store.read(type, 'b1'))!;
    expect(r.isDeleted, isTrue);
    expect(r.fields['deleted_at'], '2026-10-24T12:00:00.000Z');
  });

  test(
    'an edit from a stale snapshot does not revert a field merged meanwhile',
    () async {
      await editor.recordChange(type, 'b1', null, budget(), 1000);
      final snapshot = budget();
      // A remote rename arrives while the user edits the amount.
      final remote = ChangeLogEntry(
        entityType: type,
        entityId: 'b1',
        operation: ChangeOperation.update,
        payload: const {'name': 'Groceries'},
        hlc: Hlc(1500, 0, 'dev-b'),
        deviceId: 'dev-b',
        synced: true,
      );
      clock.receive(remote.hlc, 1500);
      await store.write(merge(await store.read(type, 'b1'), remote).record);
      await editor.recordChange(type, 'b1', snapshot, {
        ...snapshot,
        'amount': {'minor_units': 1, 'currency': 'USD'},
      }, 1600);
      final r = (await store.read(type, 'b1'))!;
      expect(r.fields['name'], 'Groceries');
      expect(r.fields['amount'], {'minor_units': 1, 'currency': 'USD'});
    },
  );

  test('a failure leaves neither the record nor the entry', () async {
    store.failBefore = (op) {
      if (op == 'append') throw StateError('disk');
    };
    await expectLater(
      editor.recordChange(type, 'b1', null, budget(), 1000),
      throwsStateError,
    );
    expect(store.records, isEmpty);
    expect(store.outbox, isEmpty);
  });

  group('an edit after a value from a clock beyond the bound', () {
    test(
      'is stamped past it, wins, and leaves the other fields alone',
      () async {
        final remote = Hlc(1000 + 5 * hour, 3, 'dev-b');
        await store.write(merge(null, remoteCreate(remote)).record);
        expect(
          clock.receive(remote, 1000),
          Hlc(1000, 0, 'dev-a'),
          reason: 'clamped',
        );
        final e = (await editor.recordChange(
          type,
          'b1',
          budget(),
          budget(name: 'Groceries'),
          1000,
        ))!;
        expect(e.hlc, Hlc(1000 + 5 * hour, 4, 'dev-a'));
        expect(clock.last, e.hlc);
        final r = (await store.read(type, 'b1'))!;
        expect(r.fields['name'], 'Groceries');
        expect(r.fieldClocks['name'], e.hlc);
        expect(r.fieldClocks['amount'], remote);
      },
    );

    test(
      'an edit of a field with no clock beyond the bound is a plain send',
      () async {
        await store.write(
          merge(null, remoteCreate(Hlc(900, 0, 'dev-b'))).record,
        );
        final e = (await editor.recordChange(
          type,
          'b1',
          budget(),
          budget(name: 'Groceries'),
          1000,
        ))!;
        expect(e.hlc, Hlc(1000, 0, 'dev-a'));
      },
    );

    test('over a store that reads the host\'s rows, the record keeps one clock per '
        'value and folds as anywhere else', () async {
      final rows = RowStore();
      final editor = LocalEditor(rows, clock);
      final remote = Hlc(1000 + 5 * hour, 0, 'dev-b');
      final created = remoteCreate(remote);
      await rows.write(merge(null, created).record);
      clock.receive(remote, 1000);
      // The host writes its row first, then records the change.
      rows.rows[(type: type, id: 'b1')]!['name'] = 'Groceries';
      final e = (await editor.recordChange(
        type,
        'b1',
        budget(),
        budget(name: 'Groceries'),
        1000,
      ))!;
      expect(e.hlc.compareTo(remote), greaterThan(0));
      final local = (await rows.read(type, 'b1'))!;
      expect(local.fields['name'], 'Groceries');
      expect(local.fieldClocks['name'], e.hlc);
      // Every other device folds the two entries, in either order, to the same record.
      for (final order in [
        [created, e],
        [e, created],
      ]) {
        var folded = merge(null, order.first).record;
        folded = merge(folded, order.last).record;
        expect(folded.toCanonicalJson(), local.toCanonicalJson());
      }
    });
  });
}
