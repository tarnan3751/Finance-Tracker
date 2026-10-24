// The local edit path: diff, stamp, store and outbox in one transaction.
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

const type = EntityType.budget;

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
}
