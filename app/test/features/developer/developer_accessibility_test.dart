// The developer menu against the accessibility baseline, light and dark: the dev
// flavor's settings with the Developer section after a pull, and the Sandbox controls
// with an Item, an operation's outcome and a finished provisioning job; each against
// the Android tap-target, labelled tap-target and contrast guidelines, and laid out at
// twice the text size. The Sandbox controls are pushed, not routed, so they are checked
// here rather than in test/accessibility_test.dart's list of routes.
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/features/developer/application/developer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

const Size _size = Size(412, 2900);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The dev settings after Pull now; with [controls], the Sandbox controls after Refresh
/// balances and a finished provisioning job.
Future<void> _open(
  WidgetTester tester, {
  required bool controls,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  await pumpApp(
    tester,
    config: AppConfig.dev(),
    initialLocation: '/settings',
    size: _size,
    brightness: brightness,
    textScale: textScale,
    overrides: [storeOverride(seededStore())],
  );
  await _tap(tester, find.text('Pull now'));
  if (!controls) return;
  await _tap(tester, find.text('Sandbox controls'));
  await _tap(tester, find.text('Refresh balances'));
  await _tap(tester, find.text('Start'));
  ProviderScope.containerOf(tester.element(find.byType(Scaffold).last))
      .read(fakeServerProvider)
      .advanceClock(const Duration(minutes: 1));
  await tester.pump(provisionPollInterval);
  await tester.pumpAndSettle();
  expect(find.text('Job completed'), findsOneWidget);
  await tester.ensureVisible(find.text('Refresh balances'));
  await tester.pumpAndSettle();
}

void main() {
  for (final bool controls in [false, true]) {
    final String name = controls
        ? 'The Sandbox controls'
        : 'The Developer section';
    for (final Brightness brightness in Brightness.values) {
      testWidgets('$name (${brightness.name}) meets the Android and contrast '
          'guidelines', (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await _open(tester, controls: controls, brightness: brightness);
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
      await _open(tester, controls: controls, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  }
}
