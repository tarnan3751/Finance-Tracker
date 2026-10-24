// The accessibility baseline for every screen of the shell, in light and dark: tap
// targets are large enough and labelled, text has enough contrast, and nothing overflows
// at twice the text size.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

const Map<String, String> _screens = {
  'Accounts': '/accounts',
  'Transactions': '/transactions',
  'Settings': '/settings',
};

void main() {
  for (final MapEntry(key: String name, value: String location)
      in _screens.entries) {
    for (final Brightness brightness in Brightness.values) {
      testWidgets('$name (${brightness.name}) meets the Android and contrast '
          'guidelines', (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        // Disposed in `finally`, not through addTearDown: flutter_test checks for live
        // semantics handles before tear-downs run, so a failing guideline would add a
        // leak failure on top of its own.
        try {
          await pumpApp(
            tester,
            initialLocation: location,
            brightness: brightness,
          );

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          semantics.dispose();
        }
      });
    }

    testWidgets('$name lays out at text scale 2.0 without overflow', (
      tester,
    ) async {
      await pumpApp(tester, initialLocation: location, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(
        MediaQuery.textScalerOf(tester.element(find.byType(Scaffold).last))
            .scale(10),
        20,
      );
    });
  }
}
