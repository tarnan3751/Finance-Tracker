// bootstrap stopped before its first frame: a stopApp that comes first (a restart or a
// wipe) disposes the container, and the first frame's callback starts no watcher on it.
// Its own file: the test binding's frames do not carry over from the other bootstrap
// tests.
import 'package:finance_tracker/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/startup_wiring.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
    'a stop before the first frame starts nothing on the stopped app',
    (tester) async {
      final StartupWiring wiring = StartupWiring();
      await tester.runAsync(() async {
        await wiring.start();
        await stopApp();
      });
      // The first frame, of whatever replaced the app: its post-frame callback finds the
      // container stopped.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(wiring.alertsStarted, isFalse);
      expect(wiring.detectorStarted, isFalse);
    },
  );
}
