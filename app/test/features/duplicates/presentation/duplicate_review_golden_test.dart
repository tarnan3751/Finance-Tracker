// Goldens of the duplicate review, light and dark at phone size, on the test seed with
// two manual entries that repeat seed transactions (duplicate_seed.dart). Tagged
// `golden`; see test/flutter_test_config.dart for where the files go and how to update
// them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/duplicate_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    goldenTest(
      'the duplicate review, ${brightness.name}',
      fileName: 'duplicate_review_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () => SizedBox.fromSize(
        size: phoneSize,
        child: buildTestApp(
          initialLocation: '/transactions/duplicates',
          brightness: brightness,
          overrides: [storeOverride(duplicateStore())],
        ),
      ),
    );
  }
}
