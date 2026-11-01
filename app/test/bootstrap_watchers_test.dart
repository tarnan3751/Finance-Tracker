// bootstrap's watchers: the budget alert watcher, the recurring detector and the weekly
// summary's notice start after the first frame, not before it, and a burst of writes runs
// the detector once (`bootstrap_stopped_test.dart`: nothing starts on an app stopped
// before its first frame). Its own file: the test binding's frames do not carry over
// from the other bootstrap tests.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/reports/application/weekly_summary_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/seed.dart';
import 'helpers/startup_wiring.dart';
import 'helpers/wipe_support.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
    'the watchers start after the first frame and a burst runs the detector once',
    (tester) async {
      final StartupWiring wiring = StartupWiring();
      await tester.runAsync(wiring.start);
      // startApp has returned and the app is in place, but no frame has been drawn.
      expect(wiring.alertsStarted, isFalse);
      expect(wiring.detectorStarted, isFalse);
      expect(wiring.container.exists(weeklySummaryNoticeProvider), isFalse);

      // runApp attaches the tree on a timer: the first frame is drawn once it is in.
      await settleWipe(tester);
      expect(wiring.alertsStarted, isTrue);
      expect(wiring.detectorStarted, isTrue);
      expect(wiring.container.exists(weeklySummaryNoticeProvider), isTrue);

      final ProviderContainer container = wiring.container;
      // The first run, on the demo's ledger.
      await settleWipe(tester);
      final int first = wiring.streams.runs;
      expect(first, greaterThanOrEqualTo(1));

      // Ten writes in a row, inside the detector's debounce: one more run.
      await tester.runAsync(() async {
        final String account =
            (await container.read(accountRepositoryProvider).watchAll().first)
                .first
                .id;
        for (int i = 0; i < 10; i++) {
          await container
              .read(transactionRepositoryProvider)
              .upsert(
                testTransaction(
                  'burst-$i',
                  accountId: account,
                  name: 'Burst $i',
                ),
              );
        }
      });
      await settleWipe(tester);
      expect(wiring.streams.runs, first + 1);

      await tester.runAsync(stopApp);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
