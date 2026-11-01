// Leaving the demo that prod runs in the demo mode: the strip's Leave, confirmed, wipes,
// clears the stored mode and household and opens Welcome again on a new container, with
// no confirmation to dismiss. Its own file: the test binding's frames do not carry over
// from the other bootstrap tests.
import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
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

  testWidgets('leaving the demo wipes and opens Welcome again', (tester) async {
    final InMemoryAppModeStore modes = InMemoryAppModeStore(
      mode: AppMode.demo,
      demoPersona: PersonaId.student,
    );
    await tester.runAsync(
      () => startApp(
        AppConfig.prod(),
        modes: modes,
        wiringFor: modeWiring(modes),
      ),
    );
    await settleWipe(tester);
    final ProviderContainer first = _running(tester);
    expect(first.read(demoPersonaProvider), PersonaId.student);

    await tester.tap(find.text(l10n.demoStripLeave));
    await tester.pumpAndSettle();
    await _tapThrough(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.leaveDemoConfirm),
      ),
    );

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(modes.mode, isNull);
    expect(modes.demoPersona, isNull);
    expect(modes.clears, 1);
    final ProviderContainer second = _running(tester);
    expect(second, isNot(same(first)));
    expect(second.read(appConfigProvider).mode, isNull);
    expect(tester.takeException(), isNull);

    await tester.runAsync(stopApp);
    await tester.pumpWidget(const SizedBox());
  });
}
