// Goldens of the goal screens, light and dark at phone size, on the goal seed
// (goal_seed.dart) and the test seed: the list with the archived section folded, a
// contribution goal's detail with its contributions, a balance goal's detail with its
// counted account, and the editor of the balance goal. Tagged `golden`; see
// test/flutter_test_config.dart for where the files go and how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/goal_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Widget _app(Brightness brightness, String location) => SizedBox.fromSize(
  size: phoneSize,
  child: buildTestApp(
    initialLocation: location,
    brightness: brightness,
    overrides: [storeOverride(seededStore()), goalsOverride()],
  ),
);

const Map<String, String> _screens = {
  'goals_list': '/goals',
  'goal_contributions': '/goals/goal-trip',
  'goal_balance': '/goals/goal-fund',
  'goal_editor': '/goals/goal-fund/edit',
};

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    for (final MapEntry(key: String name, value: String location)
        in _screens.entries) {
      goldenTest(
        '$name, ${brightness.name}',
        fileName: '${name}_${brightness.name}',
        constraints: BoxConstraints.tight(phoneSize),
        builder: () => _app(brightness, location),
      );
    }
  }
}
