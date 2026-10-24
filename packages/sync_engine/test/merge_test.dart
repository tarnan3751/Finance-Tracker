// Field-level merge: last-writer-wins per field, tombstones, out-of-order delivery,
// idempotence, and the record's canonical form.
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'support/oracle.dart';

const type = EntityType.category;
const tomb = '2026-10-24T15:00:00.000Z';

ChangeLogEntry entry(
  ChangeOperation op,
  Map<String, Object?> payload,
  int wall, [
  String node = 'a',
]) => ChangeLogEntry(
  entityType: type,
  entityId: 'c1',
  operation: op,
  payload: payload,
  hlc: Hlc(wall, 0, node),
  deviceId: node,
  synced: false,
);

/// A create as another producer might send it, with `deleted_at` in the payload; merge
/// ignores that field in a create (diff never puts it there).
ChangeLogEntry create(int wall, [String node = 'a', String name = 'Food']) =>
    entry(
      ChangeOperation.create,
      {'id': 'c1', 'name': name, 'color': 1, 'deleted_at': null},
      wall,
      node,
    );

ChangeLogEntry update(Map<String, Object?> p, int wall, [String node = 'a']) =>
    entry(ChangeOperation.update, p, wall, node);

ChangeLogEntry delete(int wall, [String node = 'a']) =>
    entry(ChangeOperation.delete, {'deleted_at': tomb}, wall, node);

EntityRecord fold(List<ChangeLogEntry> entries) =>
    mergeFold(entries)[(type: type, id: 'c1')]!;

/// Folds [entries] in every order and checks that all agree with each other and the
/// oracle; returns the result.
EntityRecord foldAllOrders(List<ChangeLogEntry> entries) {
  final expected = oracleFold(entries)[(type: type, id: 'c1')]!;
  expect(tombstoneMismatch(mergeFold(entries), entries), isNull);
  void permute(List<ChangeLogEntry> done, List<ChangeLogEntry> rest) {
    if (rest.isEmpty) {
      expect(
        fold(done).toCanonicalJson(),
        expected.toCanonicalJson(),
        reason: '$done',
      );
      return;
    }
    for (var i = 0; i < rest.length; i++) {
      permute([...done, rest[i]], [...rest]..removeAt(i));
    }
  }

  permute([], entries);
  return expected;
}

void main() {
  test('a create into nothing makes a complete record', () {
    final out = merge(null, create(10));
    expect(out.applied, isTrue);
    expect(out.changedFields, {'id', 'name', 'color'});
    expect(out.record.fields.containsKey('deleted_at'), isFalse);
    expect(out.record.isComplete, isTrue);
    expect(out.record.createdAt, Hlc(10, 0, 'a'));
    expect(out.record.fieldClocks.values.toSet(), {Hlc(10, 0, 'a')});
  });

  test('the later clock wins per field, independently', () {
    final r = foldAllOrders([
      create(10),
      update({'name': 'Groceries'}, 20, 'b'),
      update({'name': 'Dining', 'color': 2}, 15, 'c'),
    ]);
    expect(r.fields['name'], 'Groceries');
    expect(r.fields['color'], 2);
  });

  test('the node id breaks a tie on wall and counter', () {
    final r = foldAllOrders([
      update({'name': 'from a'}, 20, 'a'),
      update({'name': 'from b'}, 20, 'b'),
    ]);
    expect(r.fields['name'], 'from b');
  });

  test('reapplying an entry changes nothing', () {
    final once = merge(null, create(10)).record;
    final again = merge(once, create(10));
    expect(again.applied, isFalse);
    expect(again.changedFields, isEmpty);
    expect(identical(again.record, once), isTrue);
  });

  test('an older entry is ignored', () {
    final r = merge(null, update({'name': 'new'}, 20)).record;
    final out = merge(r, update({'name': 'old'}, 10, 'b'));
    expect(out.applied, isFalse);
    expect(out.record.fields['name'], 'new');
  });

  group('delete versus edit', () {
    test('an edit with a later clock than the delete leaves it deleted', () {
      final r = foldAllOrders([
        create(10),
        delete(20, 'a'),
        update({'name': 'Late'}, 30, 'b'),
      ]);
      expect(r.isDeleted, isTrue);
      expect(
        r.fields['name'],
        'Late',
        reason: 'the edit still applies to its field',
      );
    });

    test('an edit with an earlier clock than the delete leaves it deleted', () {
      final r = foldAllOrders([
        create(10),
        update({'name': 'Early'}, 15, 'b'),
        delete(20, 'a'),
      ]);
      expect(r.isDeleted, isTrue);
      expect(r.fields['name'], 'Early');
    });

    test('a later restore shows the edits made while deleted', () {
      final r = foldAllOrders([
        create(10),
        delete(20, 'a'),
        update({'name': 'Late'}, 30, 'b'),
        update({'deleted_at': null}, 40, 'c'),
      ]);
      expect(r.isDeleted, isFalse);
      expect(r.fields['name'], 'Late');
    });
  });

  group('delete versus restore', () {
    test('a restore with a later clock than the tombstone restores', () {
      final r = foldAllOrders([
        create(10),
        delete(20, 'a'),
        update({'deleted_at': null}, 25, 'b'),
      ]);
      expect(r.isDeleted, isFalse);
    });

    test('a delete with a later clock than the restore wins', () {
      final r = foldAllOrders([
        create(10),
        delete(20, 'a'),
        update({'deleted_at': null}, 25, 'b'),
        delete(30, 'c'),
      ]);
      expect(r.isDeleted, isTrue);
    });

    test('a restore older than the tombstone does not restore', () {
      final r = foldAllOrders([
        create(10),
        update({'deleted_at': null}, 15, 'b'),
        delete(20, 'a'),
      ]);
      expect(r.isDeleted, isTrue);
    });
  });

  test('a create arriving after its own updates loses the fields they set', () {
    final updated = mergeFold([
      update({'name': 'Renamed'}, 20),
      update({'color': 9}, 30),
    ])[(type: type, id: 'c1')]!;
    expect(updated.isComplete, isFalse);
    final out = merge(updated, create(10));
    expect(out.applied, isTrue);
    expect(out.changedFields, {'id'});
    expect(out.record.isComplete, isTrue);
    expect(out.record.fields, {'id': 'c1', 'name': 'Renamed', 'color': 9});
    foldAllOrders([
      create(10),
      update({'name': 'Renamed'}, 20),
      update({'color': 9}, 30),
    ]);
  });

  test('a create with a later clock than a tombstone leaves it deleted', () {
    // The same id created on a device that never saw the delete (or a singleton id
    // such as settings created twice): the tombstone wins, the create's fields apply.
    final r = foldAllOrders([create(10), delete(20), create(30, 'b', 'Again')]);
    expect(r.isDeleted, isTrue);
    expect(r.fields['name'], 'Again');
    expect(r.createdAt, Hlc(10, 0, 'a'));
  });

  test('a create carrying a non-null deleted_at does not delete', () {
    final odd = entry(ChangeOperation.create, {
      'id': 'c1',
      'name': 'x',
      'deleted_at': tomb,
    }, 10);
    final r = foldAllOrders([
      odd,
      update({'name': 'y'}, 20, 'b'),
    ]);
    expect(r.isDeleted, isFalse);
    expect(r.fields.containsKey('deleted_at'), isFalse);
  });

  test('only a later update restores after a create-delete race', () {
    final r = foldAllOrders([
      create(10),
      delete(20),
      create(30, 'b'),
      update({'deleted_at': null}, 40, 'c'),
    ]);
    expect(r.isDeleted, isFalse);
  });

  test(
    'two creates of one id keep the earliest createdAt and merge per field',
    () {
      final r = foldAllOrders([create(30, 'b', 'B'), create(10, 'a', 'A')]);
      expect(r.createdAt, Hlc(10, 0, 'a'));
      expect(r.fields['name'], 'B');
    },
  );

  test('a create with no new field but an earlier clock still applies', () {
    final r = merge(null, create(20)).record;
    final out = merge(r, entry(ChangeOperation.create, {'name': 'x'}, 10, 'b'));
    expect(out.applied, isTrue);
    expect(out.changedFields, isEmpty);
    expect(out.record.createdAt, Hlc(10, 0, 'b'));
  });

  test('an entry for another entity is refused', () {
    final r = EntityRecord.empty(EntityType.goal, 'c1');
    expect(() => merge(r, create(10)), throwsArgumentError);
  });

  group('EntityRecord', () {
    test('canonical JSON is independent of insertion order', () {
      final a = EntityRecord(
        type: type,
        id: 'c1',
        fields: {
          'b': 1,
          'a': {'y': 1, 'x': 2},
        },
        fieldClocks: {'b': Hlc(1, 0, 'n'), 'a': Hlc(2, 0, 'n')},
      );
      final b = EntityRecord(
        type: type,
        id: 'c1',
        fields: {
          'a': {'x': 2, 'y': 1},
          'b': 1,
        },
        fieldClocks: {'a': Hlc(2, 0, 'n'), 'b': Hlc(1, 0, 'n')},
      );
      expect(a.toCanonicalJson(), b.toCanonicalJson());
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('fields and clocks must have the same keys', () {
      expect(
        () => EntityRecord(
          type: type,
          id: 'c1',
          fields: {'a': 1},
          fieldClocks: {},
        ),
        throwsArgumentError,
      );
    });

    test('deleted means a non-null deleted_at', () {
      final r = merge(null, delete(10)).record;
      expect(r.isDeleted, isTrue);
      expect(r.isComplete, isFalse);
      expect(r.key, (type: type, id: 'c1'));
    });
  });
}
