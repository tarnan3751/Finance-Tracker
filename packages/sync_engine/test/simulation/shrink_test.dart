// The chaos simulation's shrinker against a failure planted in the predicate: it must find
// the two steps and the two devices the failure needs, whatever else the scenario holds.
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'chaos.dart';

void main() {
  test('shrink keeps only the steps and devices a failure needs', () async {
    final scenario = ChaosScenario.generate(7);
    // Fails when an edit by dev-2 is later followed by a sync of dev-1, anywhere,
    // groups included.
    bool fails(ChaosScenario s) {
      var edited = false;
      for (final step in s.steps) {
        for (final m in step is Group ? step.members : [step]) {
          if (m case Edit(device: 'dev-2')) edited = true;
          if (m case Sync(device: 'dev-1') when edited) return true;
        }
      }
      return false;
    }

    final planted = scenario.withSteps([
      ...scenario.steps,
      const Edit('dev-2', EntityType.category, 'e0', 1),
      const Group([
        Edit('dev-0', EntityType.category, 'e1', 2),
        Sync('dev-1', Delivery.shuffled, 3),
      ]),
    ]);
    expect(fails(planted), isTrue);
    final minimal = await shrink(planted, (s) async => fails(s));
    expect(minimal.steps, hasLength(2));
    expect(minimal.steps.first, isA<Edit>());
    expect((minimal.steps.first as Edit).device, 'dev-2');
    expect(minimal.steps.last, isA<Sync>());
    expect((minimal.steps.last as Sync).device, 'dev-1');
    expect(minimal.skews.keys.toSet(), {'dev-1', 'dev-2'});
  });
}
