// The golden of the help's first section, light, at phone size: its headings,
// paragraphs and bullets. Tagged `golden`; see test/flutter_test_config.dart for where the
// files go and how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  goldenTest(
    'the help, getting started',
    fileName: 'help_light',
    constraints: BoxConstraints.tight(phoneSize),
    builder: () => SizedBox.fromSize(
      size: phoneSize,
      child: buildTestApp(initialLocation: '/settings/help/getting-started'),
    ),
  );
}
