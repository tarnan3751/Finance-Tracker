// Goldens of the Welcome screen of a fresh install, light and dark at phone size. Tagged
// `golden`; see test/flutter_test_config.dart for where the files go and how to update
// them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    goldenTest(
      'the Welcome screen, ${brightness.name}',
      fileName: 'welcome_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () => SizedBox.fromSize(
        size: phoneSize,
        child: buildTestApp(
          config: AppConfig.prod().withChoices(mode: null),
          brightness: brightness,
          signedIn: false,
        ),
      ),
    );
  }
}
