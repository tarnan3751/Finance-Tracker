// The multi-device sync simulation (`PLAN.md` §9): thousands of seeded scenarios, each a
// few virtual devices editing, syncing, failing and recovering (harness.dart), after
// which every device must hold byte-identical records equal to the relay's fold and to
// the brute-force oracle, agree with the tombstone rule checked on its own, and no entry
// may be lost or duplicated.
//
// Deterministic. SYNC_SIM_SEED overrides the base seed (default 20261024),
// SYNC_SIM_SCENARIOS the scenario count (default below), and SYNC_SIM_SCENARIO runs the
// one scenario a failure names: `SYNC_SIM_SEED=20261024 SYNC_SIM_SCENARIO=17 dart test
// test/simulation` in packages/sync_engine.
import 'dart:io';

import 'package:test/test.dart';

import 'harness.dart';

const int defaultSeed = 20261024;
const int defaultScenarios = 4000;
const int chunk = 100;

final env = Platform.environment;
final int baseSeed = int.tryParse(env['SYNC_SIM_SEED'] ?? '') ?? defaultSeed;
final int scenarios =
    int.tryParse(env['SYNC_SIM_SCENARIOS'] ?? '') ?? defaultScenarios;
final int? only = int.tryParse(env['SYNC_SIM_SCENARIO'] ?? '');

int scenarioSeed(int i) => baseSeed * 1000003 + i;

Future<void> runScenario(int i) async {
  try {
    await Simulation(scenarioSeed(i)).run();
  } on SimulationFailure catch (e) {
    fail(
      'scenario $i failed (SYNC_SIM_SEED=$baseSeed SYNC_SIM_SCENARIO=$i): $e',
    );
  }
}

void main() {
  if (only != null) {
    test('scenario $only (seed $baseSeed)', () => runScenario(only!));
    return;
  }
  for (var start = 0; start < scenarios; start += chunk) {
    final end = start + chunk < scenarios ? start + chunk : scenarios;
    test('scenarios $start to ${end - 1} converge (seed $baseSeed)', () async {
      for (var i = start; i < end; i++) {
        await runScenario(i);
      }
    });
  }
}
