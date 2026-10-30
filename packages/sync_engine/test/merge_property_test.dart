// Merge is commutative, associative and idempotent: folding a random set of entries in a
// random order, with random duplicates and in random groupings, always gives the oracle's
// records. Deterministic: `Random(seed)` with the default seed 20261024; set
// SYNC_ENGINE_SEED to explore. A failure names the seed and the case. Along any fold, the
// conflicts each merge reports are exactly the overwrites the rule names, and the record is
// the one the fold gives without looking at them.
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'support/oracle.dart';

final int seed =
    int.tryParse(Platform.environment['SYNC_ENGINE_SEED'] ?? '') ?? 20261024;
const int cases = 5000;

const _ids = ['x', 'y', 'z'];
const _fields = ['name', 'tags', 'amount', 'notes', 'deleted_at'];
const _nodes = ['a', 'b', 'c'];

Object? _value(Random r, String field) => switch (field) {
  'deleted_at' =>
    r.nextBool() ? null : '2026-10-24T15:00:0${r.nextInt(10)}.000Z',
  'tags' => [for (var i = 0; i < r.nextInt(3); i++) 't${r.nextInt(4)}'],
  'amount' => {'minor_units': r.nextInt(2000) - 1000, 'currency': 'USD'},
  _ => r.nextInt(4) == 0 ? null : '$field${r.nextInt(5)}',
};

List<ChangeLogEntry> _entries(Random r) {
  final seen = <Hlc>{};
  final out = <ChangeLogEntry>[];
  final n = r.nextInt(40) + 1;
  while (out.length < n) {
    final node = _nodes[r.nextInt(_nodes.length)];
    final hlc = Hlc(r.nextInt(30), r.nextInt(3), node);
    if (!seen.add(hlc)) continue;
    final op = ChangeOperation.values[r.nextInt(3)];
    final payload = <String, Object?>{};
    if (op == ChangeOperation.create) {
      for (final f in _fields) {
        // Another producer's create may carry deleted_at; merge ignores it.
        payload[f] = _value(r, f);
      }
    } else if (op == ChangeOperation.delete) {
      payload['deleted_at'] = '2026-10-24T15:00:00.000Z';
      if (r.nextBool()) payload['notes'] = _value(r, 'notes');
    } else {
      for (final f in _fields) {
        if (r.nextInt(3) == 0) payload[f] = _value(r, f);
      }
      if (payload.isEmpty) payload['name'] = _value(r, 'name');
    }
    out.add(
      ChangeLogEntry(
        entityType: EntityType.transaction,
        entityId: _ids[r.nextInt(_ids.length)],
        operation: op,
        payload: payload,
        hlc: hlc,
        deviceId: node,
        synced: false,
      ),
    );
  }
  return out;
}

void main() {
  test(
    'every order, duplication and grouping folds to the oracle (seed $seed)',
    () {
      final r = Random(seed);
      for (var i = 0; i < cases; i++) {
        final entries = _entries(r);
        final why = 'seed $seed, case $i: $entries';
        final expected = canonical(oracleFold(entries));

        final shuffled = [
          ...entries,
          for (final e in entries)
            if (r.nextInt(4) == 0) e,
        ]..shuffle(r);
        final folded = mergeFold(shuffled);
        expect(canonical(folded), expected, reason: why);
        expect(tombstoneMismatch(folded, entries), isNull, reason: why);

        // Grouping: fold a random part, then the whole set again in another order on top.
        final part = [...entries]..shuffle(r);
        final prefix = part.take(r.nextInt(entries.length + 1));
        final rest = [...entries]..shuffle(r);
        expect(
          canonical(mergeFold(rest, mergeFold(prefix))),
          expected,
          reason: why,
        );
      }
    },
  );

  test('the losers are exactly the overwrites the rule names (seed $seed)', () {
    final r = Random(seed + 1);
    for (var i = 0; i < cases; i++) {
      final entries = _entries(r)..shuffle(r);
      final state = <EntityKey, EntityRecord>{};
      for (final e in entries) {
        final key = (type: e.entityType, id: e.entityId);
        final before = state[key];
        final out = merge(before, e);
        final why = 'seed $seed, case $i, $e onto $before';
        final expected = <String>{
          if (before != null &&
              !before.isDeleted &&
              e.operation == ChangeOperation.update)
            for (final f in out.changedFields)
              if (f != 'deleted_at' &&
                  before.fields[f] != null &&
                  before.fieldClocks[f] != null &&
                  before.fieldClocks[f]!.nodeId != e.hlc.nodeId &&
                  e.hlc.wallMillis - before.fieldClocks[f]!.wallMillis <=
                      conflictWindow.inMilliseconds &&
                  !const DeepCollectionEquality().equals(
                    before.fields[f],
                    e.payload[f],
                  ))
                f,
        };
        expect({for (final c in out.losers) c.field}, expected, reason: why);
        for (final c in out.losers) {
          expect(c.localClock, before!.fieldClocks[c.field], reason: why);
          expect(c.localValue, before.fields[c.field], reason: why);
          expect(c.remoteClock, e.hlc, reason: why);
          expect(c.remoteValue, out.record.fields[c.field], reason: why);
          expect(c.localClock.compareTo(c.remoteClock), lessThan(0));
        }
        state[key] = out.record;
      }
      expect(canonical(state), canonical(mergeFold(entries)));
    }
  });
}
