// Goldens of bank data, light and dark at phone size, on the linked test store (two linked
// accounts at the test banks, Plaid transactions with raw names): the transaction list's
// merchant avatars and names. Tagged `golden`; see test/flutter_test_config.dart for
// where the files go and how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/seed.dart';

Widget _app(String location, Brightness brightness) => SizedBox.fromSize(
  size: phoneSize,
  child: buildTestApp(
    initialLocation: location,
    brightness: brightness,
    overrides: [storeOverride(linkedStore(manual: true))],
  ),
);

const Map<String, String> _screens = {'linked_transactions': '/transactions'};

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    for (final MapEntry(key: String name, value: String location)
        in _screens.entries) {
      goldenTest(
        'the $name screen, ${brightness.name}',
        fileName: '${name}_${brightness.name}',
        constraints: BoxConstraints.tight(phoneSize),
        builder: () => _app(location, brightness),
      );
    }
  }
}
