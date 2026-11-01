// bootstrap finishing a leave of the demo cut short: prod killed in the middle of
// leaving its demo (the wipe's pending record, `demoLeft`, still in the preferences, and
// the demo mode with it) finishes the wipe on the next start, before anything opens, and
// lands on Welcome with the stored mode, household and pending record gone, with no
// confirmation to dismiss. Its own file: the test binding's frames do not carry over
// from the other bootstrap tests.
import 'dart:async';
import 'dart:io';

import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_background_work.dart';
import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/features/onboarding/presentation/welcome_screen.dart';
import 'package:finance_tracker/features/widgets/data/fake_widget_writer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mode_wiring.dart';
import 'helpers/wipe_support.dart';

void main() {
  testWidgets('a start finishes leaving the demo and opens Welcome', (
    tester,
  ) async {
    // Killed part way through leaving: the pending record and the demo mode stored.
    SharedPreferences.setMockInitialValues({
      DriftLocalWipe.pendingKey: WipeReason.demoLeft.name,
      PreferencesAppModeStore.modeKey: AppMode.demo.name,
      PreferencesAppModeStore.personaKey: 'family',
    });
    final Directory directory = Directory.systemTemp.createTempSync(
      'ft-leave-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final PreferencesAppModeStore modes = PreferencesAppModeStore(
      preferences: SharedPreferences.getInstance,
      installUser: () async => null,
    );
    final DriftLocalWipe wipe = DriftLocalWipe(
      directory: () async => directory,
      receipts: MemoryReceiptStore(),
      widgets: FakeWidgetWriter(),
      preferences: SharedPreferences.getInstance,
      keys: InMemoryDatabaseKeyStore(null),
      tokens: InMemoryTokenStore(),
      reminders: FakeReminderScheduler(),
      background: FakeBackgroundWork(),
      modes: modes,
    );

    // startApp waits on frames while it finishes the wipe, so it is not awaited here.
    await tester.runAsync(() async {
      unawaited(
        startApp(
          AppConfig.prod(),
          modes: modes,
          wiringFor: modeWiring(
            modes,
            extra: [localWipeProvider.overrideWithValue(wipe)],
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    // Finished first, before anything opens, saying the demo is being left.
    expect(find.byType(FinanceTrackerApp), findsNothing);
    expect(find.text('Leaving the demo…'), findsOneWidget);
    // The wipe's file steps and the restart run on real time.
    for (
      int i = 0;
      i < 3 && find.byType(WelcomeScreen).evaluate().isEmpty;
      i++
    ) {
      await settleWipe(tester);
    }

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(await wipe.pending(), isNull);
    final StoredAppMode stored = await modes.read();
    expect(stored.mode, isNull);
    expect(stored.demoPersona, isNull);
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(FinanceTrackerApp)),
    );
    expect(container.read(appConfigProvider).mode, isNull);
    expect(tester.takeException(), isNull);

    await tester.runAsync(stopApp);
    await tester.pumpWidget(const SizedBox());
  });
}
