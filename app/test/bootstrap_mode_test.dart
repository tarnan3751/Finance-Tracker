// bootstrap's start on the app mode the device stores: prod in the demo mode runs the
// demo flavor's launch smoke (the renter's accounts at the demo's banks, as they report
// them) on the demo's wiring. Its own file: the test binding's frames do not carry over
// from the other bootstrap tests.
import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mode_wiring.dart';
import 'helpers/wipe_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets("prod in the demo mode shows the renter's accounts", (
    tester,
  ) async {
    final InMemoryAppModeStore modes = InMemoryAppModeStore(mode: AppMode.demo);
    await tester.runAsync(
      () => startApp(
        AppConfig.prod(),
        modes: modes,
        wiringFor: modeWiring(modes),
      ),
    );
    await settleWipe(tester);

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(FinanceTrackerApp)),
    );
    final AppConfig config = container.read(appConfigProvider);
    expect(config.flavor, Flavor.prod);
    expect(config.isDemo, isTrue);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      AppConfig.prod().appName,
    );
    expect(find.text('Everyday Checking'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('Platypus Rewards Card'), findsOneWidget);
    expect(find.text('reported'), findsNWidgets(3));
    expect(find.text('from transactions'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.runAsync(stopApp);
    await tester.pumpWidget(const SizedBox());
  });
}
