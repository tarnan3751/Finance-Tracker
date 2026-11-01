// bootstrap finishing a wipe cut short after its last step cleared the stored mode: the
// next start, with no mode chosen, still finds the wipe's pending record through the
// preferences (`DriftLocalWipe`), finishes it before anything opens, confirms it for its
// reason, and on Done opens Welcome. Its own file: the test binding's frames do not carry over
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
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mode_wiring.dart';
import 'helpers/wipe_support.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets(
    'a start with no mode chosen finishes a pending wipe, then Welcome',
    (tester) async {
      // Killed after the mode was cleared: only the pending record is left.
      SharedPreferences.setMockInitialValues({
        DriftLocalWipe.pendingKey: WipeReason.deviceErased.name,
      });
      final Directory directory = Directory.systemTemp.createTempSync(
        'ft-unset-',
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
      // The wipe's file steps run on real time.
      for (
        int i = 0;
        i < 3 && find.text(l10n.erasedDone).evaluate().isEmpty;
        i++
      ) {
        await settleWipe(tester);
      }
      // Finished first, before anything opens, and confirmed for its reason.
      expect(find.byType(SpendthriftApp), findsNothing);
      expect(find.text(l10n.erasedDeviceTitle), findsOneWidget);
      expect(await wipe.pending(), isNull);
      await tester.runAsync(() async {
        await tester.tap(find.text(l10n.erasedDone));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      for (
        int i = 0;
        i < 3 && find.byType(WelcomeScreen).evaluate().isEmpty;
        i++
      ) {
        await settleWipe(tester);
      }

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect((await modes.read()).mode, isNull);
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(SpendthriftApp)),
      );
      expect(container.read(appConfigProvider).mode, isNull);
      // The new start's first frame runs its post-frame setup before it stops.
      await settleWipe(tester);
      expect(tester.takeException(), isNull);

      await tester.runAsync(stopApp);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
