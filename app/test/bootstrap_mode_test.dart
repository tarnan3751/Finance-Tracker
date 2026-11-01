// bootstrap's start on the app mode the device stores: prod in the demo mode runs the
// demo flavor's launch smoke (the renter's accounts at the demo's banks, as they report
// them) on the demo's wiring; a fresh install opens on Welcome, and its choices restart
// the app on the chosen mode (the demo on the chosen household, or the live mode at
// sign-in). Its own file: the test binding's frames do not carry over from the other
// bootstrap tests.
import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:finance_tracker/features/auth/presentation/sign_in_screen.dart';
import 'package:finance_tracker/features/onboarding/presentation/welcome_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mode_wiring.dart';
import 'helpers/wipe_support.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

ProviderContainer _running(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(FinanceTrackerApp)));

// Taps [finder] with real time for the restart's frames and awaits, then settles.
Future<void> _tapThrough(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() async {
    await tester.tap(finder);
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await settleWipe(tester);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

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
    // The three cards' and the hero card's.
    expect(find.text('reported'), findsNWidgets(4));
    expect(find.text('from transactions'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.runAsync(stopApp);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Welcome, the demo and a household restart on that household', (
    tester,
  ) async {
    final InMemoryAppModeStore modes = InMemoryAppModeStore();
    await tester.runAsync(
      () => startApp(
        AppConfig.prod(),
        modes: modes,
        wiringFor: modeWiring(modes),
      ),
    );
    await settleWipe(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    final ProviderContainer first = _running(tester);
    expect(first.read(appConfigProvider).mode, isNull);

    await _tapThrough(tester, find.text(l10n.welcomeTryDemo));
    await _tapThrough(tester, find.text(l10n.demoPersonaFamily));

    final ProviderContainer second = _running(tester);
    expect(second, isNot(same(first)));
    expect(second.read(appConfigProvider).isDemo, isTrue);
    expect(second.read(demoPersonaProvider), PersonaId.family);
    expect(find.byType(AccountsScreen), findsOneWidget);
    final String account = second
        .read(demoSeedProvider)
        .household
        .accounts
        .first
        .name;
    expect(find.text(account), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.runAsync(stopApp);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Welcome and my own server restart live, at sign-in', (
    tester,
  ) async {
    final InMemoryAppModeStore modes = InMemoryAppModeStore();
    await tester.runAsync(
      () => startApp(
        AppConfig.prod(),
        modes: modes,
        wiringFor: modeWiring(modes),
      ),
    );
    await settleWipe(tester);

    await _tapThrough(tester, find.text(l10n.welcomeUseServer));

    expect(modes.mode, AppMode.live);
    expect(_running(tester).read(appConfigProvider).isLive, isTrue);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.runAsync(stopApp);
    await tester.pumpWidget(const SizedBox());
  });
}
