// Conflicts in merge (`docs/reference/sync.md`, **Conflicts**): an update that overwrites
// another node's different, non-null value at most ten minutes older reports it as a
// loser; creates, deletes, restores, tombstoned records, `deleted_at`, equal values, a
// null old value, a node's own earlier value and a value the entry does not win never
// do, and reporting never changes the merged record.
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

const type = EntityType.category;
const t0 = 1792854000000; // 2026-10-24T15:00:00Z
const minute = 60000;
const tomb = '2026-10-24T15:00:00.000Z';

ChangeLogEntry entry(
  ChangeOperation op,
  Map<String, Object?> payload,
  int wall, [
  String node = 'a',
  int counter = 0,
]) => ChangeLogEntry(
  entityType: type,
  entityId: 'c1',
  operation: op,
  payload: payload,
  hlc: Hlc(wall, counter, node),
  deviceId: node,
  synced: false,
);

ChangeLogEntry create(int wall, [String node = 'a']) => entry(
  ChangeOperation.create,
  {'id': 'c1', 'name': 'Food', 'color': 1},
  wall,
  node,
);

ChangeLogEntry update(
  Map<String, Object?> p,
  int wall, [
  String node = 'a',
  int counter = 0,
]) => entry(ChangeOperation.update, p, wall, node, counter);

/// The record after [entries], merged in order.
EntityRecord fold(List<ChangeLogEntry> entries) {
  EntityRecord? record;
  for (final e in entries) {
    record = merge(record, e).record;
  }
  return record!;
}

void main() {
  // A's create, A's rename at t0, then B's rename [delay] later.
  MergeOutcome bRenames(int delay, {String name = 'Groceries'}) {
    final local = fold([
      create(t0 - minute),
      update({'name': 'Food!'}, t0),
    ]);
    return merge(local, update({'name': name}, t0 + delay, 'b'));
  }

  test('an overwrite within ten minutes is a conflict, with both sides', () {
    final out = bRenames(9 * minute + 59999);
    expect(out.changedFields, {'name'});
    expect(out.losers, [
      FieldConflict(
        entityType: type,
        entityId: 'c1',
        field: 'name',
        localValue: 'Food!',
        localClock: Hlc(t0, 0, 'a'),
        remoteValue: 'Groceries',
        remoteClock: Hlc(t0 + 9 * minute + 59999, 0, 'b'),
      ),
    ]);
    expect(out.losers.single.localDevice, 'a');
    expect(out.losers.single.remoteDevice, 'b');
  });

  test('exactly ten minutes apart is still a conflict', () {
    expect(bRenames(10 * minute).losers, hasLength(1));
  });

  test('more than ten minutes apart is not', () {
    final out = bRenames(10 * minute + 1);
    expect(out.applied, isTrue);
    expect(out.losers, isEmpty);
  });

  test('the same clock time from another node is a conflict', () {
    expect(bRenames(0).losers, hasLength(1));
  });

  test('an equal value is not a conflict', () {
    expect(bRenames(minute, name: 'Food!').losers, isEmpty);
  });

  test('equal nested values are not, different ones are', () {
    final local = fold([
      create(t0 - minute),
      update({
        'tags': ['a', 'b'],
      }, t0),
    ]);
    expect(
      merge(
        local,
        update(
          {
            'tags': ['a', 'b'],
          },
          t0 + minute,
          'b',
        ),
      ).losers,
      isEmpty,
    );
    expect(
      merge(
        local,
        update(
          {
            'tags': ['b', 'a'],
          },
          t0 + minute,
          'b',
        ),
      ).losers.single.field,
      'tags',
    );
  });

  test('only the fields the entry wins and that differ are losers', () {
    final local = fold([
      create(t0 - minute),
      update({'name': 'Food!', 'color': 2}, t0),
      update({'icon': 'cart'}, t0 + 5 * minute, 'c'),
    ]);
    final out = merge(
      local,
      update(
        {'name': 'Groceries', 'color': 2, 'icon': 'bag'},
        t0 + minute,
        'b',
      ),
    );
    // icon's clock (c at +5 min) is later than the entry's: it keeps c's value.
    expect(out.changedFields, {'name', 'color'});
    expect([for (final c in out.losers) c.field], ['name']);
  });

  test(
    'a non-null value the create set is a conflict when overwritten soon',
    () {
      final local = fold([create(t0)]);
      final out = merge(local, update({'name': 'Groceries'}, t0 + minute, 'b'));
      expect(out.losers.single.localClock, Hlc(t0, 0, 'a'));
      expect(out.losers.single.localValue, 'Food');
    },
  );

  test("a null local value never conflicts, a create's default or a clear", () {
    final created = fold([
      entry(ChangeOperation.create, {
        'id': 'c1',
        'name': 'Food',
        'icon': null,
      }, t0),
    ]);
    expect(
      merge(created, update({'icon': 'cart'}, t0 + minute, 'b')).losers,
      isEmpty,
    );
    final cleared = fold([
      create(t0 - minute),
      update({'name': null}, t0),
    ]);
    final out = merge(cleared, update({'name': 'Groceries'}, t0 + minute, 'b'));
    expect(out.changedFields, {'name'});
    expect(out.losers, isEmpty);
  });

  test('clearing a non-null value is a conflict', () {
    final local = fold([
      create(t0 - minute),
      update({'name': 'Food!'}, t0),
    ]);
    final out = merge(local, update({'name': null}, t0 + minute, 'b'));
    expect(out.losers.single.remoteValue, isNull);
  });

  test("a node's later edit of its own value is not a conflict", () {
    final local = fold([
      create(t0 - minute, 'b'),
      update({'name': 'x'}, t0, 'b'),
    ]);
    expect(
      merge(local, update({'name': 'y'}, t0 + minute, 'b')).losers,
      isEmpty,
    );
  });

  test('an entry that loses reports nothing', () {
    final local = fold([
      create(t0 - minute),
      update({'name': 'Food!'}, t0),
    ]);
    final out = merge(local, update({'name': 'old'}, t0 - 1, 'b'));
    expect(out.applied, isFalse);
    expect(out.losers, isEmpty);
  });

  test('a create over an existing record is not a conflict', () {
    final local = fold([create(t0)]);
    final out = merge(
      local,
      entry(
        ChangeOperation.create,
        {'id': 'c1', 'name': 'Other', 'color': 3},
        t0 + minute,
        'b',
      ),
    );
    expect(out.changedFields, containsAll(['name', 'color']));
    expect(out.losers, isEmpty);
  });

  test('a delete is not a conflict, whatever it overwrites', () {
    final local = fold([
      create(t0 - minute),
      update({'name': 'Food!'}, t0),
    ]);
    final out = merge(
      local,
      entry(
        ChangeOperation.delete,
        {'deleted_at': tomb, 'name': 'gone'},
        t0 + minute,
        'b',
      ),
    );
    expect(out.record.isDeleted, isTrue);
    expect(out.losers, isEmpty);
  });

  test('an edit of a tombstoned record, and a restore, are not conflicts', () {
    final deleted = fold([
      create(t0 - 2 * minute),
      update({'name': 'Food!'}, t0 - minute),
      entry(ChangeOperation.delete, {'deleted_at': tomb}, t0),
    ]);
    expect(
      merge(deleted, update({'name': 'Groceries'}, t0 + minute, 'b')).losers,
      isEmpty,
    );
    expect(
      merge(
        deleted,
        update({'deleted_at': null, 'name': 'Back'}, t0 + minute, 'b'),
      ).losers,
      isEmpty,
    );
  });

  test('deleted_at itself is never a loser', () {
    final local = fold([
      create(t0 - 2 * minute),
      entry(ChangeOperation.delete, {'deleted_at': tomb}, t0 - minute),
      update({'deleted_at': null}, t0),
    ]);
    expect(local.isDeleted, isFalse);
    final out = merge(local, update({'deleted_at': tomb}, t0 + minute, 'b'));
    expect(out.record.isDeleted, isTrue);
    expect(out.losers, isEmpty);
  });

  test('a field with no clock yet is not a conflict', () {
    final local = fold([create(t0)]);
    final out = merge(local, update({'icon': 'cart'}, t0 + minute, 'b'));
    expect(out.changedFields, {'icon'});
    expect(out.losers, isEmpty);
  });

  test('an update into nothing is not a conflict', () {
    expect(merge(null, update({'name': 'x'}, t0, 'b')).losers, isEmpty);
  });

  test('reporting losers does not change the merged record', () {
    final local = fold([
      create(t0 - minute),
      update({'name': 'Food!'}, t0),
    ]);
    final e = update({'name': 'Groceries'}, t0 + minute, 'b');
    final out = merge(local, e);
    expect(out.losers, isNotEmpty);
    expect(
      out.record,
      fold([
        create(t0 - minute),
        update({'name': 'Food!'}, t0),
        e,
      ]),
    );
    expect(out.record.fields['name'], 'Groceries');
    expect(out.record.fieldClocks['name'], e.hlc);
  });
}
