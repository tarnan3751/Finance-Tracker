// Goldens of the sign-in and registration screens, light and dark at phone size. Tagged
// `golden`; see test/flutter_test_config.dart for where the files go and how to update
// them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const Map<String, String> _screens = {
  'sign_in': '/sign-in',
  'register': '/register',
};

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
        builder: () => SizedBox.fromSize(
          size: phoneSize,
          child: buildTestApp(
            initialLocation: location,
            brightness: brightness,
            signedIn: false,
          ),
        ),
      );
    }
  }
}
