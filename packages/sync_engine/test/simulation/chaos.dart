// The chaos simulation: a scenario is a device configuration and a list of steps generated
// up front from one seed (time passing, edits, syncs whose pages arrive reordered, twice or
// early, concurrent groups, bursts of edits to one record from many devices, partitions,
// restarts and clock skews of hours), then run against one relay and checked against the
// invariants of `docs/reference/sync.md`, **Testing**. Every step carries its own seed, so
// a step's content, faults and event-loop yields do not depend on the steps around it:
// [shrink] can drop steps and devices and the rest of the scenario runs as before.
import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../support/hooked_relay.dart';
import '../support/oracle.dart';
import 'harness.dart' show SimulationFailure, minute, schemas, startMillis;

const int hour = 60 * minute;

/// How a sync's pulled pages reach the device.
enum Delivery {
  /// As the relay served them.
  normal,

  /// Each page's entries in a random order.
  shuffled,

  /// Some entries twice, plus entries the relay served before.
  duplicated,

  /// Plus entries from after the page's cursor, ahead of their own page.
  early,
}

/// One step of a scenario.
sealed class ChaosStep {
  const ChaosStep();

  /// The devices the step names.
  Set<String> get devices;

  /// The step without [device], or null when nothing of it is left.
  ChaosStep? without(String device) => devices.contains(device) ? null : this;

  String describe();

  @override
  String toString() => describe();
}

/// Virtual time moves on by [millis].
final class Advance extends ChaosStep {
  const Advance(this.millis);
  final int millis;

  @override
  Set<String> get devices => const {};

  @override
  String describe() => 'advance ${_duration(millis)}';
}

/// [device] edits [type]/[id]: a create, update, delete or restore by the record's state,
/// its values (and, for an update, [field] when given) drawn from [seed].
final class Edit extends ChaosStep {
  const Edit(
    this.device,
    this.type,
    this.id,
    this.seed, {
    this.field,
    this.faults = false,
  });
  final String device;
  final EntityType type;
  final String id;
  final int seed;
  final String? field;
  final bool faults;

  @override
  Set<String> get devices => {device};

  @override
  String describe() =>
      'edit $device ${type.name}/$id${field == null ? '' : '.$field'}'
      '${faults ? ' faults' : ''} #$seed';
}

/// [device] runs a session, its pages arriving by [delivery].
final class Sync extends ChaosStep {
  const Sync(this.device, this.delivery, this.seed, {this.faults = false});
  final String device;
  final Delivery delivery;
  final int seed;
  final bool faults;

  @override
  Set<String> get devices => {device};

  @override
  String describe() =>
      'sync $device ${delivery.name}${faults ? ' faults' : ''} #$seed';
}

/// [members] (edits and syncs) run concurrently, interleaved by event-loop yields; a
/// [burst] is many devices editing one record at once.
final class Group extends ChaosStep {
  const Group(this.members, {this.burst = false});
  final List<ChaosStep> members;
  final bool burst;

  @override
  Set<String> get devices => {for (final m in members) ...m.devices};

  @override
  ChaosStep? without(String device) {
    final rest = [
      for (final m in members)
        if (!m.devices.contains(device)) m,
    ];
    if (rest.isEmpty) return null;
    if (rest.length == 1) return rest.single;
    return Group(rest, burst: burst);
  }

  @override
  String describe() =>
      '${burst ? 'burst' : 'group'} [${members.map((m) => m.describe()).join('; ')}]';
}

/// [device] loses the network until a [Heal].
final class Cut extends ChaosStep {
  const Cut(this.device);
  final String device;

  @override
  Set<String> get devices => {device};

  @override
  String describe() => 'cut $device';
}

/// [device] has the network again.
final class Heal extends ChaosStep {
  const Heal(this.device);
  final String device;

  @override
  Set<String> get devices => {device};

  @override
  String describe() => 'heal $device';
}

/// [device]'s process restarts: its clock and session come back from its store.
final class Restart extends ChaosStep {
  const Restart(this.device);
  final String device;

  @override
  Set<String> get devices => {device};

  @override
  String describe() => 'restart $device';
}

/// [device]'s wall clock now reads [offset] milliseconds from true time.
final class Skew extends ChaosStep {
  const Skew(this.device, this.offset);
  final String device;
  final int offset;

  @override
  Set<String> get devices => {device};

  @override
  String describe() => 'skew $device ${_signed(offset)}';
}

String _duration(int millis) {
  if (millis >= hour) {
    return '${millis ~/ hour}h${(millis % hour ~/ minute).toString().padLeft(2, '0')}m';
  }
  if (millis >= minute) {
    return '${millis ~/ minute}m${millis % minute ~/ 1000}s';
  }
  return '${millis}ms';
}

String _signed(int millis) =>
    millis < 0 ? '-${_duration(-millis)}' : '+${_duration(millis)}';

/// A scenario: the devices with their initial skews, the record space, and the steps.
final class ChaosScenario {
  const ChaosScenario({
    required this.skews,
    required this.types,
    required this.idsPerType,
    required this.batch,
    required this.steps,
  });

  /// The scenario [seed] determines.
  factory ChaosScenario.generate(int seed) {
    final r = Random(seed);
    int seedOf() => r.nextInt(1 << 32);
    int skew() => switch (r.nextInt(5)) {
      0 => 0,
      1 || 2 => r.nextInt(60 * minute + 1) - 30 * minute,
      _ => (r.nextBool() ? 1 : -1) * (hour + r.nextInt(5 * hour)),
    };
    final ids = [for (var i = 0, n = 3 + r.nextInt(4); i < n; i++) 'dev-$i'];
    final skews = {for (final d in ids) d: skew()};
    final types = ([
      ...schemas.keys,
    ]..shuffle(r)).take(1 + r.nextInt(3)).toList();
    final idsPerType = 2 + r.nextInt(4);
    final batch = r.nextInt(3) == 0 ? 2 + r.nextInt(4) : 200;
    final rate = {for (final d in ids) d: 0.1 + r.nextDouble() * 0.4};
    final cut = <String>{};
    String device() => ids[r.nextInt(ids.length)];
    Delivery delivery() => switch (r.nextInt(20)) {
      < 11 => Delivery.normal,
      < 14 => Delivery.shuffled,
      < 17 => Delivery.duplicated,
      _ => Delivery.early,
    };
    Edit edit(String d, {EntityType? type, String? id, String? field}) => Edit(
      d,
      type ?? types[r.nextInt(types.length)],
      id ?? 'e${r.nextInt(idsPerType)}',
      seedOf(),
      field: field,
      faults: r.nextInt(3) == 0,
    );

    final steps = <ChaosStep>[];
    for (var round = 0, n = 40 + r.nextInt(120); round < n; round++) {
      steps.add(
        Advance(
          r.nextInt(40) == 0
              ? hour * (1 + r.nextInt(3))
              : r.nextInt(10) == 0
              ? 1 + r.nextInt(30 * minute)
              : 1 + r.nextInt(3000),
        ),
      );
      if (r.nextInt(25) == 0) steps.add(Skew(device(), skew()));
      if (r.nextInt(20) == 0) steps.add(Restart(device()));
      if (r.nextInt(15) == 0) {
        final d = device();
        steps.add(cut.remove(d) ? Heal(d) : Cut(d));
        if (steps.last is Cut) cut.add(d);
      }
      if (r.nextInt(10) == 0) {
        final type = types[r.nextInt(types.length)];
        final id = 'e${r.nextInt(idsPerType)}';
        final fields = schemas[type]!.keys.toList();
        final field = r.nextBool() ? fields[r.nextInt(fields.length)] : null;
        final who = ([...ids]..shuffle(r)).take(2 + r.nextInt(ids.length - 1));
        steps.add(
          Group([
            for (final d in who) edit(d, type: type, id: id, field: field),
          ], burst: true),
        );
        continue;
      }
      final members = <ChaosStep>[
        for (final d in ids)
          if (r.nextDouble() < rate[d]!)
            Sync(d, delivery(), seedOf(), faults: r.nextInt(3) == 0),
      ];
      if (members.length < 2 || r.nextBool()) {
        for (var i = 1 + r.nextInt(2); i > 0; i--) {
          members.add(edit(device()));
        }
      }
      steps.add(members.length == 1 ? members.single : Group(members));
    }
    return ChaosScenario(
      skews: skews,
      types: types,
      idsPerType: idsPerType,
      batch: batch,
      steps: steps,
    );
  }

  /// Each device's skew at the start, by device id.
  final Map<String, int> skews;
  final List<EntityType> types;
  final int idsPerType;
  final int batch;
  final List<ChaosStep> steps;

  ChaosScenario withSteps(List<ChaosStep> steps) => ChaosScenario(
    skews: skews,
    types: types,
    idsPerType: idsPerType,
    batch: batch,
    steps: steps,
  );

  /// The scenario without [device] and every step naming it.
  ChaosScenario without(String device) => ChaosScenario(
    skews: {...skews}..remove(device),
    types: types,
    idsPerType: idsPerType,
    batch: batch,
    steps: [
      for (final s in steps)
        if (s.without(device) case final ChaosStep kept) kept,
    ],
  );

  /// The configuration and the numbered steps, one per line.
  String describe() => [
    '${skews.length} devices '
        '(${[for (final MapEntry(:key, :value) in skews.entries) '$key ${_signed(value)}'].join(', ')}), '
        'types ${types.map((t) => t.name).join(', ')}, $idsPerType ids each, batch $batch',
    for (final (i, s) in steps.indexed) '#$i $s',
  ].join('\n');
}

/// What a run exercised, summed over a budget.
final class ChaosStats {
  int scenarios = 0;
  int steps = 0;
  int driftRefused = 0;
  int partitions = 0;
  int restarts = 0;
  int bursts = 0;
  int reshapedPages = 0;

  @override
  String toString() =>
      '$scenarios scenarios, $steps steps: $bursts bursts, $partitions partitions, '
      '$restarts restarts, $reshapedPages pages reordered, duplicated or early, '
      '$driftRefused pushes refused for drift';
}

class _Fault implements Exception {
  _Fault(this.what);
  final String what;
  @override
  String toString() => 'injected $what';
}

String _iso(int millis) => const UtcInstantConverter().toJson(
  DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
);

final class _Device {
  _Device(this.run, this.id, this.skew) {
    relay = HookedRelay(run.relay)
      ..before = ((op) => _hook(op, before: true))
      ..after = ((op) => _hook(op, before: false));
    store.failBefore = (op) {
      if (faults && r.nextInt(60) == 0) throw _Fault('store $op');
    };
    _boot(HlcClock(id));
  }

  final ChaosRun run;
  final String id;
  int skew;
  bool partitioned = false;

  /// The randomness of the step running on this device: yields, faults, jitter.
  Random r = Random(0);
  bool faults = false;

  final store = InMemorySyncStore();
  late final HookedRelay relay;
  late HlcClock clock;
  late LocalEditor editor;
  late SyncSession session;

  /// Every entry this device recorded, in order.
  final produced = <ChangeLogEntry>[];

  /// The record each entity showed when the device last edited it, for stale edits.
  final snapshots = <EntityKey, Map<String, Object?>>{};

  /// The latest physical time this device has read.
  int maxNow = 0;

  /// The persisted clock when last checked.
  Hlc? persisted;

  int now() {
    final t = run.time + skew + r.nextInt(101) - 50;
    if (t > maxNow) maxNow = t;
    return t;
  }

  void _boot(HlcClock c) {
    clock = c;
    editor = LocalEditor(store, clock);
    session = SyncSession(
      store,
      relay,
      clock,
      nowWallMillis: now,
      pushBatchSize: run.scenario.batch,
      pullPageSize: run.scenario.batch,
    );
  }

  Future<void> _hook(String op, {required bool before}) async {
    for (var i = r.nextInt(4); i > 0; i--) {
      await Future<void>(() {});
    }
    if (before && partitioned) throw _Fault('$op: no network');
    if (faults && r.nextInt(20) == 0) {
      throw _Fault(before ? '$op request lost' : '$op response lost');
    }
  }

  Future<void> restart() async {
    final last = await store.lastClock();
    if (last != null && produced.isNotEmpty) {
      run.check(
        last.compareTo(produced.last.hlc) >= 0,
        '$id restarted with clock $last behind its last entry ${produced.last.hlc}',
      );
    }
    _boot(HlcClock(id, last: last));
    run.log('$id restarted at $last');
  }

  PullPage _reshape(PullPage page, Delivery delivery) {
    if (delivery == Delivery.normal) return page;
    final entries = [...page.entries];
    final log = run.relay.entries;
    switch (delivery) {
      case Delivery.normal:
        break;
      case Delivery.shuffled:
        entries.shuffle(r);
      case Delivery.duplicated:
        for (final e in page.entries) {
          if (r.nextBool()) entries.insert(r.nextInt(entries.length + 1), e);
        }
        final seen = min(page.nextSince, log.length);
        for (var i = r.nextInt(4); i > 0 && seen > 0; i--) {
          entries.insert(r.nextInt(entries.length + 1), log[r.nextInt(seen)]);
        }
      case Delivery.early:
        final ahead = log.length - page.nextSince;
        for (var i = r.nextInt(4); i > 0 && ahead > 0; i--) {
          entries.add(log[page.nextSince + r.nextInt(ahead)]);
        }
    }
    run.stats.reshapedPages++;
    return PullPage(
      entries: entries,
      unknownTypes: page.unknownTypes,
      nextSince: page.nextSince,
      hasMore: page.hasMore,
    );
  }

  Future<void> sync(Sync step) async {
    relay.deliver = (page) => _reshape(page, step.delivery);
    try {
      final report = await session.run();
      run.log(
        '$id ${step.describe()}: pushed ${report.pushed}, pulled ${report.pulled}, '
        'applied ${report.applied}, rejected ${report.rejected.length}',
      );
      for (final x in report.rejected) {
        run.check(
          x.reason == PushRejectionReason.clockDrift,
          '$id push rejected: $x',
        );
        run.stats.driftRefused++;
      }
    } on _Fault catch (e) {
      run.log('$id ${step.describe()} failed: $e');
    } finally {
      relay.deliver = null;
    }
  }

  Future<void> edit(Edit step) async {
    final r = Random(step.seed);
    final schema = schemas[step.type]!;
    final key = (type: step.type, id: step.id);
    final at = now();
    final existing = store.records[key];
    Map<String, Object?>? before;
    Map<String, Object?> after;
    String what;
    if (existing == null) {
      what = 'create';
      after = {
        'id': step.id,
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
      } else if (step.field == null && r.nextInt(6) == 0) {
        what = 'delete';
        after = {...before, 'deleted_at': _iso(at), 'updated_at': _iso(at)};
      } else {
        what = 'update';
        final names = schema.keys.toList();
        after = {...before, 'updated_at': _iso(at)};
        if (step.field case final String f) {
          after[f] = schema[f]!(r);
        } else {
          for (var i = r.nextInt(3) + 1; i > 0; i--) {
            final f = names[r.nextInt(names.length)];
            after[f] = schema[f]!(r);
          }
        }
      }
    }
    snapshots[key] = existing?.fields ?? after;
    final ChangeLogEntry? entry;
    try {
      entry = await editor.recordChange(step.type, step.id, before, after, at);
    } on _Fault catch (e) {
      run.log('$id edit $what ${step.type.name}/${step.id} failed: $e');
      return;
    }
    if (entry == null) return;
    run.check(
      produced.isEmpty || entry.hlc.compareTo(produced.last.hlc) > 0,
      '$id issued ${entry.hlc} after ${produced.isEmpty ? '' : produced.last.hlc}',
    );
    produced.add(entry);
    final stored = store.records[key]!;
    for (final f in entry.payload.keys) {
      final clock = stored.fieldClocks[f]!;
      if (clock == entry.hlc) {
        run.check(
          const DeepCollectionEquality().equals(
            stored.fields[f],
            entry.payload[f],
          ),
          '$id: local edit of $key.$f not visible right after it',
        );
      } else {
        // Only a remote clock this device did not adopt (beyond the bound) can be
        // greater than a clock it issues.
        run.check(
          clock.compareTo(entry.hlc) > 0,
          '$id: local edit of $key.$f lost to an older clock $clock',
        );
      }
    }
    run.log(
      '$id ${entry.operation.name}/$what ${step.type.name}/${step.id} ${entry.hlc} '
      '${entry.payload.keys}',
    );
  }

  /// The clock invariants, between steps: the persisted clock never goes back, and the
  /// clock never adopted a physical time more than the bound ahead of this device's.
  Future<void> checkClock() async {
    final last = await store.lastClock();
    if (last != null) {
      final before = persisted;
      run.check(
        before == null || last.compareTo(before) >= 0,
        '$id persisted clock went back from $before to $last',
      );
      persisted = last;
    }
    run.check(
      clock.last.wallMillis <= maxNow + clock.maxDrift.inMilliseconds + 1,
      '$id clock ${clock.last} is beyond its latest physical time $maxNow '
      'plus the bound',
    );
  }
}

/// One run of a scenario.
final class ChaosRun {
  ChaosRun(this.scenario, this.stats) {
    for (final MapEntry(:key, :value) in scenario.skews.entries) {
      devices[key] = _Device(this, key, value);
    }
  }

  final ChaosScenario scenario;
  final ChaosStats stats;
  final devices = <String, _Device>{};
  int time = startMillis;
  late final InMemorySyncRelay relay = InMemorySyncRelay(
    nowWallMillis: () => time,
  );
  final trace = <String>[];

  void log(String line) =>
      trace.add('[t+${_duration(time - startMillis)}] $line');

  void check(bool ok, String message) {
    if (!ok) throw SimulationFailure(message, trace);
  }

  /// Seeds each device a step names from the step's own seeds, so the step behaves the
  /// same whatever ran before it.
  void _seed(ChaosStep step, {required bool faults}) {
    final seeds = <String, int>{};
    void add(ChaosStep s) {
      switch (s) {
        case Edit(:final device, :final seed, faults: final f) ||
            Sync(:final device, :final seed, faults: final f):
          seeds[device] = (seeds[device] ?? 17) * 31 + seed;
          devices[device]!.faults = faults && f;
        case Group(:final members):
          members.forEach(add);
        default:
          break;
      }
    }

    add(step);
    for (final MapEntry(:key, :value) in seeds.entries) {
      devices[key]!.r = Random(value & 0x7fffffff);
    }
  }

  Future<void> _do(ChaosStep step) async {
    switch (step) {
      case Advance(:final millis):
        time += millis;
      case Edit():
        await devices[step.device]!.edit(step);
      case Sync():
        await devices[step.device]!.sync(step);
      case Group(:final members, :final burst):
        if (burst) stats.bursts++;
        await Future.wait([for (final m in members) _do(m)]);
      case Cut(:final device):
        devices[device]!.partitioned = true;
        stats.partitions++;
        log(step.describe());
      case Heal(:final device):
        devices[device]!.partitioned = false;
        log(step.describe());
      case Restart(:final device):
        stats.restarts++;
        await devices[device]!.restart();
      case Skew(:final device, :final offset):
        devices[device]!.skew = offset;
        log(step.describe());
    }
  }

  Future<void> run() async {
    stats.scenarios++;
    log(scenario.describe().split('\n').first);
    for (final step in scenario.steps) {
      stats.steps++;
      _seed(step, faults: true);
      await _do(step);
      for (final d in devices.values) {
        d.faults = false;
        await d.checkClock();
      }
    }

    // The fixed end: the network back, every clock right, time past every clock that was
    // ahead, no faults, normal delivery.
    final ahead = scenario.skews.values
        .followedBy([
          for (final d in devices.values) d.skew,
          for (final d in devices.values) d.maxNow - time,
        ])
        .fold(0, max);
    for (final d in devices.values) {
      d
        ..partitioned = false
        ..skew = 0;
    }
    time += ahead + hour + minute;
    log('final round');
    var n = 0;
    for (var pass = 0; pass < 2; pass++) {
      for (final d in devices.values) {
        time += 1 + n++;
        d.r = Random(n);
        await d.sync(Sync(d.id, Delivery.normal, n));
        await d.checkClock();
      }
    }
    for (final d in devices.values) {
      final quiet = await d.session.run();
      check(
        quiet.pushed == 0 && quiet.applied == 0 && quiet.rejected.isEmpty,
        '${d.id} not quiescent after the final round',
      );
    }
    _checkConvergence();
    await _checkCursors();
  }

  void _checkConvergence() {
    final log = relay.entries;
    final folded = relay.fold();
    final reference = canonical(folded);
    check(
      canonical(oracleFold(log)) == reference,
      'the relay fold disagrees with the oracle',
    );
    // Order independence: any order, with duplicates, folds to the same records.
    final r = Random(log.length);
    final scrambled = [...log, ...log.where((_) => r.nextBool())]..shuffle(r);
    check(
      canonical(mergeFold(scrambled)) == reference,
      'a reordered, duplicated delivery of the log folds differently',
    );
    for (final d in devices.values) {
      check(
        d.store.outbox.every((e) => e.synced),
        '${d.id} has unsynced entries',
      );
      check(d.store.rejected.isEmpty, '${d.id} has rejected entries');
      final tombstones = tombstoneMismatch(d.store.records, log);
      check(tombstones == null, '${d.id}: $tombstones');
      final state = canonical(d.store.records);
      if (state != reference) {
        throw SimulationFailure(
          '${d.id} diverged\n--- device ---\n$state\n--- relay ---\n$reference',
          trace,
        );
      }
      // Idempotence: every entry applied again, in any order, changes nothing.
      for (final e in scrambled) {
        final local = d.store.records[(type: e.entityType, id: e.entityId)];
        check(
          !merge(local, e).applied,
          '${d.id}: entry ${e.hlc} applied again changes its record',
        );
      }
      check(
        d.store.outbox.length == d.produced.length,
        '${d.id} outbox has ${d.store.outbox.length} entries, produced '
        '${d.produced.length}',
      );
    }
    // No entry lost or duplicated: the relay holds exactly what the devices produced.
    final byKey = <String, ChangeLogEntry>{};
    for (final e in log) {
      final key = '${e.deviceId}|${e.hlc.pack()}';
      check(byKey[key] == null, 'the relay holds $key twice');
      byKey[key] = e;
    }
    final produced = [for (final d in devices.values) ...d.produced];
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

  Future<void> _checkCursors() async {
    final last = relay.entries.length;
    for (final d in devices.values) {
      final cursor = await d.store.pullCursor() ?? 0;
      check(
        cursor == last,
        "${d.id}'s cursor is $cursor, the relay's last seq $last",
      );
    }
  }
}

/// Runs [scenario]; the failure, or null when every invariant held.
Future<Object?> runChaos(ChaosScenario scenario, [ChaosStats? stats]) async {
  try {
    await ChaosRun(scenario, stats ?? ChaosStats()).run();
    return null;
  } on Object catch (e) {
    return e;
  }
}

/// The smallest scenario found that still [fails]: chunks of steps dropped (halves down
/// to single steps), then members of groups, then whole devices with every step naming
/// them, repeated until nothing more can go or [budget] runs are spent.
Future<ChaosScenario> shrink(
  ChaosScenario scenario,
  Future<bool> Function(ChaosScenario candidate) fails, {
  int budget = 3000,
}) async {
  var current = scenario;
  var runs = 0;
  Future<bool> tryIt(ChaosScenario candidate) async {
    if (runs >= budget) return false;
    runs++;
    if (!await fails(candidate)) return false;
    current = candidate;
    return true;
  }

  var progress = true;
  while (progress && runs < budget) {
    progress = false;
    for (var size = current.steps.length ~/ 2; size >= 1; size ~/= 2) {
      var i = 0;
      while (i < current.steps.length) {
        final steps = [...current.steps]
          ..removeRange(i, min(i + size, current.steps.length));
        if (await tryIt(current.withSteps(steps))) {
          progress = true;
        } else {
          i += size;
        }
      }
    }
    for (var i = 0; i < current.steps.length; i++) {
      for (var j = 0; ;) {
        final step = current.steps[i];
        if (step is! Group || j >= step.members.length) break;
        final rest = [...step.members]..removeAt(j);
        final steps = [...current.steps]
          ..[i] = rest.length == 1
              ? rest.single
              : Group(rest, burst: step.burst);
        if (await tryIt(current.withSteps(steps))) {
          progress = true;
        } else {
          j++;
        }
      }
    }
    for (final device in [...current.skews.keys]) {
      if (current.skews.length > 1 && await tryIt(current.without(device))) {
        progress = true;
      }
    }
  }
  return current;
}
