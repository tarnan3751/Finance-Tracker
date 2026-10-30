// The chaos simulation (`docs/reference/sync.md`, **Testing**): seeded scenarios of
// partitions, restarts, reordered, duplicated and early deliveries, clock skews of hours
// and bursts of edits to one record (chaos.dart), with the conflicts each device keeps
// resolved by later edits (kept or dismissed), and outbox entries held back before some
// pushes, after which every invariant must hold.
//
// Deterministic. SYNC_CHAOS_SEED overrides the base seed (default 20261030),
// SYNC_CHAOS_SCENARIOS the scenario count (default below, the gate's budget), and
// SYNC_CHAOS_SCENARIO runs the one scenario a failure names, printing its steps and trace:
// `SYNC_CHAOS_SEED=20261030 SYNC_CHAOS_SCENARIO=17 dart test test/simulation/chaos_test.dart`
// in packages/sync_engine. A failure prints the seed, the scenario, its steps and the
// smallest step list `shrink` finds that still fails.
@Tags(['chaos'])
library;

import 'dart:io';

import 'package:test/test.dart';

import 'chaos.dart';

const int defaultSeed = 20261030;
const int defaultScenarios = 400;
const int chunk = 50;

final env = Platform.environment;
final int baseSeed = int.tryParse(env['SYNC_CHAOS_SEED'] ?? '') ?? defaultSeed;
final int scenarios =
    int.tryParse(env['SYNC_CHAOS_SCENARIOS'] ?? '') ?? defaultScenarios;
final int? only = int.tryParse(env['SYNC_CHAOS_SCENARIO'] ?? '');

int scenarioSeed(int i) => baseSeed * 1000003 + i;

final stats = ChaosStats();

Future<void> runScenario(int i, {bool printSteps = false}) async {
  final scenario = ChaosScenario.generate(scenarioSeed(i));
  if (printSteps) print(scenario.describe());
  final failure = await runChaos(scenario, stats);
  if (failure == null) return;
  final minimal = await shrink(
    scenario,
    (candidate) async => await runChaos(candidate) != null,
  );
  fail(
    'chaos scenario $i failed (SYNC_CHAOS_SEED=$baseSeed SYNC_CHAOS_SCENARIO=$i): '
    '$failure\n--- the steps ---\n${scenario.describe()}\n'
    '--- the smallest failing scenario found ---\n${minimal.describe()}\n'
    '--- its failure ---\n${await runChaos(minimal)}',
  );
}

void main() {
  tearDownAll(() => print('chaos (seed $baseSeed): $stats'));

  if (only != null) {
    test(
      'chaos scenario $only (seed $baseSeed)',
      () => runScenario(only!, printSteps: true),
    );
    return;
  }

  test('a scenario replays exactly from its seed', () async {
    Future<String> trace() async {
      final run = ChaosRun(
        ChaosScenario.generate(scenarioSeed(0)),
        ChaosStats(),
      );
      await run.run();
      return run.trace.join('\n');
    }

    expect(await trace(), await trace());
  });

  for (var start = 0; start < scenarios; start += chunk) {
    final end = start + chunk < scenarios ? start + chunk : scenarios;
    test('chaos scenarios $start to ${end - 1} keep every invariant '
        '(seed $baseSeed)', () async {
      for (var i = start; i < end; i++) {
        await runScenario(i);
      }
    });
  }

  // Conflicts and their resolutions run through the invariants above; this keeps that
  // check from being vacuous at the gate's budget.
  if (scenarios >= defaultScenarios) {
    test('the scenarios kept conflicts, resolved them both ways and held back '
        'entries before a push', () {
      expect(stats.deferred, greaterThan(0));
      expect(stats.conflicts, greaterThan(0));
      expect(stats.kept, greaterThan(0));
      expect(stats.dismissed, greaterThan(0));
    });
  }
}
