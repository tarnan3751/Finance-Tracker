// Onboarding on a device: prod, started as bootstrap starts it on the device's own app
// mode store with no mode chosen, opens on Welcome; the demo and the renter's household
// restart it on the Accounts tab with the renter's accounts and the demo's strip; Leave,
// confirmed, wipes and opens Welcome again with the stored mode gone. Run on the
// harness's emulator with `tools/emulator_tests.sh integration -- <this file>`.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/onboarding/presentation/demo_strip.dart';
import 'package:finance_tracker/features/onboarding/presentation/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Pumps until [finder] finds something, for at most [seconds].
Future<void> _until(
  WidgetTester tester,
  Finder finder, {
  int seconds = 60,
}) async {
  for (int i = 0; i < seconds * 10 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Welcome, the demo, the renter, and leaving again', (
    tester,
  ) async {
    // What bootstrap sets up once per process.
    await setUpTimeZones();
    final AppModeStore modes = deviceAppModeStore();
    // A fresh install's choices: none, and no account on the device.
    await modes.clear();
    await SecureTokenStore().clearInstallUserId();

    await startApp(AppConfig.prod(), modes: modes);
    await _until(tester, find.byType(WelcomeScreen));
    expect(find.text('Spendthrift'), findsOneWidget);

    await tester.tap(find.text('Try the demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renter'));
    await _until(tester, find.text('Everyday Checking'));
    expect(find.text('Platypus Rewards Card'), findsOneWidget);
    expect(find.byType(DemoStrip), findsOneWidget);
    expect(find.text('Demo data'), findsOneWidget);
    expect((await modes.read()).mode, AppMode.demo);

    await tester.tap(find.text('Leave').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Leave'),
      ),
    );
    await _until(tester, find.byType(WelcomeScreen));
    expect((await modes.read()).mode, isNull);
    expect(find.text('Demo data'), findsNothing);
  });
}
