// The app lock on a device, in the demo flavor. Run on the harness's emulator with
// `tools/emulator_tests.sh integration`. The demo starts as bootstrap starts it (the time
// zones, then the container with the lock's settings read before the first frame), with
// the fake device check, so the AVD needs no enrolled biometrics, and the lock already
// enabled in app_meta: the lock screen covers the app from the first frame, a cancelled
// prompt keeps it, and a passed one shows the renter persona's accounts. MainActivity's
// two channels answer for real: the window's secure flag, set on and off, and
// SystemClock's elapsed time, which moves on. Every wait has a deadline and, when it
// passes, fails with the texts on screen rather than hanging the run.
import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/channel_monotonic_clock.dart';
import 'package:finance_tracker/core/platform/channel_screen_security.dart';
import 'package:finance_tracker/core/platform/monotonic_clock_provider.dart';
import 'package:finance_tracker/core/platform/screen_security.dart';
import 'package:finance_tracker/core/platform/screen_security_provider.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/lock/application/device_auth_provider.dart';
import 'package:finance_tracker/features/lock/application/lock_controller.dart';
import 'package:finance_tracker/features/lock/data/fake_device_auth.dart';
import 'package:finance_tracker/features/lock/domain/device_auth.dart';
import 'package:finance_tracker/features/lock/presentation/lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Pumps until [done], or fails after 60 s with the texts on screen.
Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() done,
  String what,
) async {
  final DateTime end = DateTime.now().add(const Duration(seconds: 60));
  while (!done()) {
    if (DateTime.now().isAfter(end)) {
      final List<String?> texts = [
        for (final Element e in find.byType(Text).evaluate())
          (e.widget as Text).data,
      ];
      fail('$what did not happen within 60 s; on screen: $texts');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shows(WidgetTester tester, Finder finder) =>
    _waitUntil(tester, () => finder.evaluate().isNotEmpty, '$finder showing');

Future<void> _gone(WidgetTester tester, Finder finder) =>
    _waitUntil(tester, () => finder.evaluate().isEmpty, '$finder going');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'lock: the gate covers the demo until the device check passes',
    timeout: const Timeout(Duration(minutes: 3)),
    (tester) async {
      await setUpTimeZones();
      final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
      await meta.write(AppMetaKeys.lockEnabled, 'true');
      final FakeDeviceAuth auth = FakeDeviceAuth(
        next: () async => AuthOutcome.cancelled,
      );
      // overridesFor(demo) with the fake check in place of local_auth (a provider may be
      // overridden once per container): the demo's data and API, and MainActivity's
      // channels for the secure flag and the clock.
      final AppConfig config = AppConfig.demo();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          ...localDataOverridesFor(config),
          ...apiOverridesFor(config),
          screenSecurityProvider.overrideWithValue(
            const ChannelScreenSecurity(),
          ),
          monotonicClockProvider.overrideWithValue(
            const ChannelMonotonicClock(),
          ),
          appMetaStoreProvider.overrideWithValue(meta),
          deviceAuthProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);
      // As bootstrap does: the lock's settings and the secure flag before the first
      // frame.
      await container.read(lockControllerProvider.notifier).restored();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FinanceTrackerApp(),
        ),
      );

      await _shows(tester, find.byType(LockScreen));
      expect(find.text('Finance Tracker Demo'), findsOneWidget);

      await tester.tap(find.text('Unlock'));
      await _shows(tester, find.text('Unlock was cancelled.'));
      expect(find.byType(LockScreen), findsOneWidget);

      auth.next = () async => AuthOutcome.success;
      await tester.tap(find.text('Try again'));
      await _gone(tester, find.byType(LockScreen));
      await _shows(tester, find.text('Everyday Checking'));
      expect(auth.prompts, hasLength(2));

      // The device's own clock answers through MainActivity, and moves on.
      final Duration first = await container
          .read(monotonicClockProvider)
          .elapsed();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      expect(
        await container.read(monotonicClockProvider).elapsed(),
        greaterThan(first),
      );

      // MainActivity's channel takes the flag both ways (a missing handler would throw).
      final ScreenSecurity screen = container.read(screenSecurityProvider);
      expect(screen, isA<ChannelScreenSecurity>());
      await screen.set(true);
      await screen.set(false);
      await container.read(lockControllerProvider.notifier).disable();
      expect(container.read(lockControllerProvider).secure, isFalse);
    },
  );
}
