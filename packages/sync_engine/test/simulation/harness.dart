// The multi-device simulation harness: virtual devices with skewed clocks editing a shared
// id space, syncing through one relay at random times, with partitions, interleaved
// sessions, injected failures, replayed pushes, restarts and a wall clock that jumps
// backwards. Everything is driven by one seeded Random and virtual time, so a scenario
// replays exactly from its seed.
import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../support/hooked_relay.dart';
import '../support/oracle.dart';

/// 2026-10-24T00:00:00Z, the virtual epoch.
const int startMillis = 1792800000000;
const int minute = 60 * 1000;

/// A failure of an invariant, carrying the scenario's trace.
class SimulationFailure implements Exception {
  SimulationFailure(this.message, this.trace);
  final String message;
  final List<String> trace;

  @override
  String toString() {
    final tail = trace.length > 80 ? trace.sublist(trace.length - 80) : trace;
    return '$message\n--- last ${tail.length} of ${trace.length} trace lines ---\n'
        '${tail.join('\n')}';
  }
}

class _Injected implements Exception {
  _Injected(this.what);
  final String what;
  @override
  String toString() => 'injected $what';
}

/// The fields each entity type carries in the simulation, with the shared_models names,
/// and a generator for each. Nested values (Money maps, lists, lists of maps) exercise
/// whole-field replacement.
final Map<EntityType, Map<String, Object? Function(Random)>> schemas = {
  EntityType.account: {
    'name': (r) => 'Account ${r.nextInt(9)}',
    'type': (r) => ['depository', 'credit', 'loan'][r.nextInt(3)],
    'is_hidden': (r) => r.nextBool(),
    'display_order': (r) => r.nextInt(10),
  },
  EntityType.transaction: {
    'name': (r) => 'Payee ${r.nextInt(9)}',
    'amount': _money,
    'date': (r) => '2026-10-${(r.nextInt(28) + 1).toString().padLeft(2, '0')}',
    'notes': (r) => r.nextInt(3) == 0 ? null : 'note ${r.nextInt(99)}',
    'tags': (r) => [
      for (var i = r.nextInt(4); i > 0; i--) 'tag${r.nextInt(6)}',
    ],
    'splits': (r) => [
      for (var i = r.nextInt(3); i > 0; i--)
        {
          'category_id': 'c${r.nextInt(5)}',
          'amount': _money(r),
          'note': r.nextBool() ? null : 'split',
        },
    ],
    'user_category_id': (r) => r.nextInt(4) == 0 ? null : 'c${r.nextInt(5)}',
  },
  EntityType.category: {
    'name': (r) => 'Category ${r.nextInt(9)}',
    'color': (r) => r.nextInt(1 << 24),
    'parent_id': (r) => r.nextBool() ? null : 'c${r.nextInt(5)}',
  },
  EntityType.rule: {
    'conditions': (r) => [
      for (var i = r.nextInt(3) + 1; i > 0; i--)
        {'kind': 'merchant_contains', 'value': 'm${r.nextInt(5)}'},
    ],
    'priority': (r) => r.nextInt(5),
  },
  EntityType.budget: {
    'amount': _money,
    'period_start_day': (r) => r.nextInt(28) + 1,
    'rollover': (r) => r.nextBool(),
  },
  EntityType.goal: {
    'name': (r) => 'Goal ${r.nextInt(9)}',
    'target': _money,
    'account_ids': (r) => [
      for (var i = r.nextInt(3); i > 0; i--) 'a${r.nextInt(4)}',
    ],
  },
  EntityType.billReminder: {
    'due_date': (r) =>
        '2026-11-${(r.nextInt(28) + 1).toString().padLeft(2, '0')}',
    'offsets_days': (r) => [
      for (var i = r.nextInt(3) + 1; i > 0; i--) r.nextInt(7),
    ],
  },
  EntityType.settings: {
    'theme': (r) => ['system', 'light', 'dark'][r.nextInt(3)],
    'lock_timeout_seconds': (r) => r.nextInt(600),
  },
};

Map<String, Object?> _money(Random r) => {
  'minor_units': r.nextInt(200000) - 100000,
  'currency': 'USD',
};

String _iso(int millis) => const UtcInstantConverter().toJson(
  DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
);

class SimDevice {
  SimDevice(this.sim, this.id, this.skew, this.syncProbability) {
    relay = HookedRelay(sim.relay);
    relay.before = (op) => _hook(op, before: true);
    relay.after = (op) => _hook(op, before: false);
    store.failBefore = (op) {
      if (sim.faults && sim.r.nextInt(150) == 0) throw _Injected('store $op');
    };
    _boot(HlcClock(id));
  }

  final Simulation sim;
  final String id;
  final int skew;
  final double syncProbability;
  int backJump = 0;

  final store = InMemorySyncStore();
  late final HookedRelay relay;
  late HlcClock clock;
  late LocalEditor editor;
  late SyncSession session;

  /// Every entry this device recorded, in order.
  final produced = <ChangeLogEntry>[];

  /// Snapshots taken when the device last showed each entity, for stale edits.
  final snapshots = <EntityKey, Map<String, Object?>>{};

  int now() => sim.time + skew + backJump + sim.r.nextInt(101) - 50;

  void _boot(HlcClock c) {
    clock = c;
    editor = LocalEditor(store, clock);
    session = SyncSession(
      store,
      relay,
      clock,
      nowWallMillis: now,
      pushBatchSize: sim.batch,
      pullPageSize: sim.batch,
    );
  }

  /// A process restart: the clock comes back from the store.
  Future<void> restart() async {
    final Hlc? last;
    try {
      last = await store.lastClock();
    } on _Injected {
      return;
    }
    if (last != null && produced.isNotEmpty) {
      sim.check(
        last.compareTo(produced.last.hlc) >= 0,
        '$id restarted with clock $last behind its last entry ${produced.last.hlc}',
      );
    }
    _boot(HlcClock(id, last: last));
    sim.log('$id restarted at $last');
  }

  Future<void> _hook(String op, {required bool before}) async {
    for (var i = sim.r.nextInt(4); i > 0; i--) {
      await Future<void>(() {});
    }
    if (!sim.faults) return;
    if (sim.r.nextInt(25) == 0) {
      throw _Injected(before ? '$op request lost' : '$op response lost');
    }
  }

  Future<void> sync(String why) async {
    try {
      final report = await session.run();
      sim.log(
        '$id sync ($why): pushed ${report.pushed}, pulled ${report.pulled}, '
        'applied ${report.applied}, rejected ${report.rejected.length}'
        '${report.clamped == 0 ? '' : ', clamped ${report.clamped}'}',
      );
      sim.check(report.clamped == 0, '$id clamped a clock skewed by minutes');
      sim.check(
        report.rejected.isEmpty,
        '$id push rejected: ${report.rejected}',
      );
    } on _Injected catch (e) {
      sim.log('$id sync ($why) failed: $e');
    }
  }

  /// One random local edit.
  Future<void> edit() async {
    final r = sim.r;
    final type = sim.types[r.nextInt(sim.types.length)];
    final schema = schemas[type]!;
    final entityId = 'e${r.nextInt(sim.idsPerType)}';
    final key = (type: type, id: entityId);
    final at = now();
    final existing = store.records[key];
    Map<String, Object?>? before;
    Map<String, Object?> after;
    String what;
    if (existing == null) {
      what = 'create';
      after = {
        'id': entityId,
        for (final f in schema.entries) f.key: f.value(r),
        'updated_at': _iso(at),
        'deleted_at': null,
      };
    } else if (!existing.isComplete) {
      return; // the host shows no incomplete record, so it cannot be edited
    } else {
      final stale = snapshots[key];
      before = stale != null && r.nextInt(4) == 0 ? stale : existing.fields;
      if (existing.isDeleted) {
        if (r.nextInt(3) != 0) return;
        what = 'restore';
        after = {...before, 'deleted_at': null, 'updated_at': _iso(at)};
      } else if (r.nextInt(6) == 0) {
        what = 'delete';
        after = {...before, 'deleted_at': _iso(at), 'updated_at': _iso(at)};
      } else {
        what = 'update';
        final names = schema.keys.toList();
        after = {...before, 'updated_at': _iso(at)};
        for (var i = r.nextInt(3) + 1; i > 0; i--) {
          final f = names[r.nextInt(names.length)];
          after[f] = schema[f]!(r);
        }
      }
    }
    snapshots[key] = existing?.fields ?? after;
    final ChangeLogEntry? entry;
    try {
      entry = await editor.recordChange(type, entityId, before, after, at);
    } on _Injected catch (e) {
      sim.log('$id edit $what ${type.name}/$entityId failed: $e');
      return;
    }
    if (entry == null) return;
    sim.check(
      produced.isEmpty || entry.hlc.compareTo(produced.last.hlc) > 0,
      '$id issued ${entry.hlc} after ${produced.isEmpty ? '' : produced.last.hlc}',
    );
    produced.add(entry);
    final stored = store.records[key]!;
    for (final f in entry.payload.keys) {
      sim.check(
        const DeepCollectionEquality().equals(
          stored.fields[f],
          entry.payload[f],
        ),
        '$id: local edit of $key.$f not visible right after it',
      );
    }
    sim.log(
      '$id ${entry.operation.name}/$what ${type.name}/$entityId ${entry.hlc} ${entry.payload.keys}',
    );
  }

  /// Re-pushes a random part of the entries the relay already accepted.
  Future<void> replayOldPush() async {
    final old = store.outbox.where((e) => e.synced).toList();
    if (old.isEmpty) return;
    final start = sim.r.nextInt(old.length);
    final batch = old.sublist(
      start,
      min(old.length, start + 1 + sim.r.nextInt(5)),
    );
    final count = sim.relay.entries.length;
    final result = await sim.relay.push(batch);
    sim.check(
      result.accepted.length == batch.length && result.rejected.isEmpty,
      '$id replay of ${batch.length} old entries not accepted idempotently: '
      '${result.rejected}',
    );
    sim.check(sim.relay.entries.length == count, '$id replay added entries');
    sim.log('$id replayed ${batch.length} old entries');
  }
}

/// One scenario.
class Simulation {
  Simulation(int seed) : r = Random(seed) {
    final deviceCount = 3 + r.nextInt(6);
    final allTypes = [...schemas.keys]..shuffle(r);
    types = allTypes.take(1 + r.nextInt(3)).toList();
    idsPerType = 2 + r.nextInt(5);
    steps = 30 + r.nextInt(90);
    batch = r.nextInt(3) == 0 ? 2 + r.nextInt(4) : 200;
    for (var i = 0; i < deviceCount; i++) {
      final skew = r.nextInt(10 * minute + 1) - 5 * minute;
      final neverSyncs = r.nextInt(6) == 0;
      devices.add(
        SimDevice(this, 'dev-$i', skew, neverSyncs ? 0 : r.nextDouble() * 0.4),
      );
    }
    if (r.nextInt(5) == 0) replayer = devices[r.nextInt(deviceCount)];
    if (r.nextInt(5) == 0) {
      jumper = devices[r.nextInt(deviceCount)];
      jumpAt = r.nextInt(steps);
      jumpBy = minute + r.nextInt(9 * minute);
    }
  }

  final Random r;
  late final List<EntityType> types;
  late final int idsPerType;
  late final int steps;
  late final int batch;
  final devices = <SimDevice>[];
  SimDevice? replayer;
  SimDevice? jumper;
  int jumpAt = -1;
  int jumpBy = 0;

  int time = startMillis;
  bool faults = true;
  late final InMemorySyncRelay relay = InMemorySyncRelay(
    nowWallMillis: () => time,
  );
  final trace = <String>[];

  void log(String line) => trace.add('[t+${time - startMillis}] $line');

  void check(bool ok, String message) {
    if (!ok) throw SimulationFailure(message, trace);
  }

  Future<void> run() async {
    log(
      '${devices.length} devices '
      '(${[for (final d in devices) '${d.id} skew ${d.skew} p ${d.syncProbability.toStringAsFixed(2)}'].join('; ')}), '
      'types ${types.map((t) => t.name)}, $idsPerType ids each, $steps steps, batch $batch, '
      'replayer ${replayer?.id}, jumper ${jumper?.id} at $jumpAt by $jumpBy',
    );
    for (var step = 0; step < steps; step++) {
      time += 1 + r.nextInt(3000);
      if (step == jumpAt) {
        jumper!.backJump -= jumpBy;
        log('${jumper!.id} wall clock jumps back $jumpBy ms');
      }
      if (r.nextInt(30) == 0) {
        await devices[r.nextInt(devices.length)].restart();
      }
      final concurrent = <Future<void>>[];
      for (final d in devices) {
        if (r.nextDouble() < d.syncProbability) {
          concurrent.add(d.sync('step $step'));
        }
      }
      if (concurrent.length < 2 || r.nextBool()) {
        // Sessions run alone or interleaved; an edit may land in the middle of them.
        concurrent.add(devices[r.nextInt(devices.length)].edit());
      }
      if (replayer != null && r.nextInt(15) == 0) {
        concurrent.add(replayer!.replayOldPush());
      }
      await Future.wait(concurrent);
    }

    faults = false;
    log('final round');
    for (var pass = 0; pass < 2; pass++) {
      for (final d in devices) {
        time += 1 + r.nextInt(1000);
        await d.sync('final $pass');
      }
    }
    for (final d in devices) {
      final quiet = await d.session.run();
      check(
        quiet.pushed == 0 && quiet.applied == 0,
        '${d.id} not quiescent after the final round',
      );
    }
    _checkConvergence();
  }

  void _checkConvergence() {
    final relayEntries = relay.entries;
    final reference = canonical(relay.fold());
    check(
      canonical(oracleFold(relayEntries)) == reference,
      'the relay fold disagrees with the oracle',
    );
    for (final d in devices) {
      check(
        d.store.outbox.every((e) => e.synced),
        '${d.id} has unsynced entries',
      );
      check(d.store.rejected.isEmpty, '${d.id} has rejected entries');
      final tombstones = tombstoneMismatch(d.store.records, relayEntries);
      check(tombstones == null, '${d.id}: $tombstones');
      final state = canonical(d.store.records);
      if (state != reference) {
        throw SimulationFailure(
          '${d.id} diverged\n--- device ---\n$state\n--- relay ---\n$reference',
          trace,
        );
      }
      check(
        d.store.outbox.length == d.produced.length,
        '${d.id} outbox has ${d.store.outbox.length} entries, produced ${d.produced.length}',
      );
    }
    // No entry lost or duplicated: the relay holds exactly what the devices produced.
    final byKey = <String, ChangeLogEntry>{};
    for (final e in relayEntries) {
      final key = '${e.deviceId}|${e.hlc.pack()}';
      check(byKey[key] == null, 'the relay holds $key twice');
      byKey[key] = e;
    }
    final produced = [for (final d in devices) ...d.produced];
    check(
      produced.length == byKey.length,
      'devices produced ${produced.length} entries, the relay holds ${byKey.length}',
    );
    for (final e in produced) {
      final stored = byKey['${e.deviceId}|${e.hlc.pack()}'];
      check(stored != null, 'entry ${e.hlc} was lost');
      check(
        const DeepCollectionEquality().equals(stored!.payload, e.payload) &&
            stored.operation == e.operation &&
            stored.entityId == e.entityId &&
            stored.entityType == e.entityType,
        'entry ${e.hlc} changed on the way',
      );
    }
  }
}
