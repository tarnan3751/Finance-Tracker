// The lock's gate and the Security section on the real app: the lock screen covers the
// app on a cold start when the lock is enabled (and not otherwise), keeps the app from the
// screen reader and the back button, stays after a failed prompt with "Try again", and
// goes once the prompt passes; the predictive back gesture pops nothing under it; on a
// return it is up from the moment the app leaves the screen, before the clock answers;
// it lays out at twice the text size; the Security section's switch is disabled with the
// reason on a device with no screen lock, and its three settings round-trip through
// app_meta.
import 'dart:async';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_screen_security.dart';
import 'package:finance_tracker/core/platform/monotonic_clock.dart';
import 'package:finance_tracker/core/platform/monotonic_clock_provider.dart';
import 'package:finance_tracker/core/platform/screen_security_provider.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/features/lock/application/device_auth_provider.dart';
import 'package:finance_tracker/features/lock/application/lock_controller.dart';
import 'package:finance_tracker/features/lock/application/lock_hold.dart';
import 'package:finance_tracker/features/lock/data/fake_device_auth.dart';
import 'package:finance_tracker/features/lock/domain/device_auth.dart';
import 'package:finance_tracker/features/lock/domain/lock_settings.dart';
import 'package:finance_tracker/features/lock/presentation/lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Future<InMemoryAppMetaStore> _meta(Map<String, String> values) async {
  final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
  for (final MapEntry<String, String> e in values.entries) {
    await meta.write(e.key, e.value);
  }
  return meta;
}

/// Brings [text] in the Security section on screen and taps it.
Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _pumpSecuritySection(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Require unlock'), 100);
  await tester.pumpAndSettle();
}

/// A monotonic clock whose answers wait for [reply] when it is set, like a channel reply
/// that arrives frames later.
final class _SlowClock implements MonotonicClock {
  Duration now = Duration.zero;
  Completer<void>? reply;

  @override
  Future<Duration> elapsed() async {
    final Duration value = now;
    await reply?.future;
    return value;
  }
}

/// Sends the platform's predictive back gesture [method] with [arguments].
Future<void> _backGesture(
  WidgetTester tester,
  String method, [
  Object? arguments,
]) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
  'flutter/backgesture',
  const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
  (ByteData? _) {},
);

void main() {
  testWidgets('a locked cold start shows only the lock screen until unlocked', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final FakeDeviceAuth auth = FakeDeviceAuth(
      next: () async => AuthOutcome.failed,
    );
    await pumpApp(
      tester,
      overrides: [
        appMetaStoreProvider.overrideWithValue(
          await _meta({AppMetaKeys.lockEnabled: 'true'}),
        ),
        deviceAuthProvider.overrideWithValue(auth),
      ],
    );

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Finance Tracker'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
    // The app is built below but hidden from the screen reader.
    expect(find.semantics.byLabel('Accounts'), findsNothing);

    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(auth.prompts, ['Unlock to see your finances']);
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Not recognized. Try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    auth.next = () async => AuthOutcome.success;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsNothing);
    expect(find.semantics.byLabel('Accounts'), findsAny);
    semantics.dispose();
  });

  testWidgets('no lock screen when the lock is disabled', (tester) async {
    await pumpApp(tester);

    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('the back button does nothing while the app is locked', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/settings/categories',
      overrides: [
        appMetaStoreProvider.overrideWithValue(
          await _meta({AppMetaKeys.lockEnabled: 'true'}),
        ),
        deviceAuthProvider.overrideWithValue(FakeDeviceAuth()),
      ],
    );
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    String location() => container
        .read(goRouterProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    expect(location(), '/settings/categories');

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(location(), '/settings/categories');
    expect(find.byType(LockScreen), findsOneWidget);

    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(location(), '/settings');
  });

  testWidgets('the predictive back gesture pops nothing while locked', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/settings/categories',
      overrides: [
        appMetaStoreProvider.overrideWithValue(
          await _meta({AppMetaKeys.lockEnabled: 'true'}),
        ),
        deviceAuthProvider.overrideWithValue(FakeDeviceAuth()),
      ],
    );
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    String location() => container
        .read(goRouterProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    expect(find.byType(LockScreen), findsOneWidget);

    await _backGesture(tester, 'startBackGesture', <String, Object?>{
      'touchOffset': <double>[5, 300],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await tester.pump();
    await _backGesture(tester, 'updateBackGestureProgress', <String, Object?>{
      'x': 300.0,
      'y': 300.0,
      'progress': 0.9,
      'swipeEdge': 0,
    });
    await tester.pump();
    await _backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(location(), '/settings/categories');
  });

  for (final LockAfter choice in [LockAfter.immediately, LockAfter.oneMinute]) {
    testWidgets('a return at ${choice.name} never shows the app before the '
        'clock answers', (tester) async {
      final _SlowClock clock = _SlowClock();
      await pumpApp(
        tester,
        overrides: [
          appMetaStoreProvider.overrideWithValue(
            await _meta({
              AppMetaKeys.lockEnabled: 'true',
              AppMetaKeys.lockTimeoutSeconds: choice.stored,
            }),
          ),
          deviceAuthProvider.overrideWithValue(FakeDeviceAuth()),
          monotonicClockProvider.overrideWithValue(clock),
        ],
      );
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.byType(LockScreen), findsNothing);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      // Leaving: once hidden (no frame is drawn while hidden or paused), the state is
      // already the lock screen's, so the first frame of the return draws it.
      for (final AppLifecycleState state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      expect(container.read(lockControllerProvider).shown, isTrue);
      // The time away is past the timeout, and the channel answers frames later.
      clock.now = const Duration(minutes: 30);
      clock.reply = Completer<void>();
      // Returning: every frame from the first is the lock screen.
      for (final AppLifecycleState state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
        if (state != AppLifecycleState.hidden) {
          expect(find.byType(LockScreen), findsOneWidget, reason: '$state');
        }
      }
      for (int frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byType(LockScreen), findsOneWidget);
      }
      clock.reply!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);
    });
  }

  for (final (String name, Duration away, bool locks) in [
    ('past its bound locks', const Duration(hours: 2), true),
    ('within its bound uncovers', const Duration(minutes: 2), false),
  ]) {
    testWidgets('a held stay $name, never showing the app before the clock '
        'answers', (tester) async {
      final _SlowClock clock = _SlowClock();
      await pumpApp(
        tester,
        overrides: [
          appMetaStoreProvider.overrideWithValue(
            await _meta({
              AppMetaKeys.lockEnabled: 'true',
              AppMetaKeys.lockTimeoutSeconds: LockAfter.immediately.stored,
            }),
          ),
          deviceAuthProvider.overrideWithValue(FakeDeviceAuth()),
          monotonicClockProvider.overrideWithValue(clock),
        ],
      );
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );

      // The app's own trip to another activity (Plaid Link, the share sheet).
      final Completer<void> link = Completer<void>();
      final Future<void> held = container
          .read(lockHoldProvider)
          .holdOpen(() => link.future);
      for (final AppLifecycleState state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      expect(container.read(lockControllerProvider).shown, isTrue);
      clock.now = away;
      clock.reply = Completer<void>();
      link.complete();
      await held;
      for (final AppLifecycleState state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
        if (state != AppLifecycleState.hidden) {
          expect(find.byType(LockScreen), findsOneWidget, reason: '$state');
        }
      }
      for (int frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byType(LockScreen), findsOneWidget);
      }
      clock.reply!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LockScreen), locks ? findsOneWidget : findsNothing);
      expect(container.read(lockControllerProvider).locked, locks);
    });
  }

  testWidgets('a short return uncovers the app once the clock answers', (
    tester,
  ) async {
    final _SlowClock clock = _SlowClock();
    await pumpApp(
      tester,
      overrides: [
        appMetaStoreProvider.overrideWithValue(
          await _meta({
            AppMetaKeys.lockEnabled: 'true',
            AppMetaKeys.lockTimeoutSeconds: LockAfter.fiveMinutes.stored,
          }),
        ),
        deviceAuthProvider.overrideWithValue(FakeDeviceAuth()),
        monotonicClockProvider.overrideWithValue(clock),
      ],
    );
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    for (final AppLifecycleState state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    clock.now = const Duration(minutes: 1);
    clock.reply = Completer<void>();
    for (final AppLifecycleState state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    // Covered, with no button, until the clock answers: the return is not decided yet.
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Unlock'), findsNothing);
    clock.reply!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('the lock screen lays out at text scale 2.0', (tester) async {
    await pumpApp(
      tester,
      textScale: 2,
      overrides: [
        appMetaStoreProvider.overrideWithValue(
          await _meta({AppMetaKeys.lockEnabled: 'true'}),
        ),
        deviceAuthProvider.overrideWithValue(
          FakeDeviceAuth(next: () async => AuthOutcome.lockedOut),
        ),
      ],
    );
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the switch is disabled, with why, without a screen lock', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      overrides: [
        deviceAuthProvider.overrideWithValue(FakeDeviceAuth(supported: false)),
      ],
    );
    await _pumpSecuritySection(tester);

    final SwitchListTile toggle = tester.widget(
      find.widgetWithText(SwitchListTile, 'Require unlock'),
    );
    expect(toggle.onChanged, isNull);
    expect(find.text('Set a screen lock on this device first'), findsOneWidget);
    final ListTile lockAfter = tester.widget(
      find.widgetWithText(ListTile, 'Lock after'),
    );
    expect(lockAfter.enabled, isFalse);
  });

  testWidgets('a cancelled prompt leaves the lock off and says so', (
    tester,
  ) async {
    final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
    await pumpApp(
      tester,
      initialLocation: '/settings',
      overrides: [
        appMetaStoreProvider.overrideWithValue(meta),
        deviceAuthProvider.overrideWithValue(
          FakeDeviceAuth(next: () async => AuthOutcome.cancelled),
        ),
      ],
    );
    await _pumpSecuritySection(tester);

    await _tap(tester, 'Require unlock');

    expect(find.text('Unlock was cancelled.'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Require unlock'),
          )
          .value,
      isFalse,
    );
    expect(await meta.read(AppMetaKeys.lockEnabled), isNull);
  });

  testWidgets('the Security section round-trips its three settings', (
    tester,
  ) async {
    final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
    final FakeScreenSecurity screen = FakeScreenSecurity();
    final FakeDeviceAuth auth = FakeDeviceAuth();
    final List<Override> overrides = [
      appMetaStoreProvider.overrideWithValue(meta),
      deviceAuthProvider.overrideWithValue(auth),
      screenSecurityProvider.overrideWithValue(screen),
    ];
    await pumpApp(tester, initialLocation: '/settings', overrides: overrides);
    await _pumpSecuritySection(tester);
    expect(screen.calls, [true]);

    await _tap(tester, 'Require unlock');
    expect(auth.prompts, ["Confirm it's you to turn on the app lock"]);
    await _tap(tester, 'Lock after');
    await tester.tap(find.text('5 minutes'));
    await tester.pumpAndSettle();
    await _tap(tester, 'Block screenshots');

    expect(await meta.read(AppMetaKeys.lockEnabled), 'true');
    expect(await meta.read(AppMetaKeys.lockTimeoutSeconds), '300');
    expect(await meta.read(AppMetaKeys.secureScreen), 'false');
    // Still secure: the lock is on.
    expect(screen.calls, [true]);
    expect(find.text('5 minutes'), findsOneWidget);

    // A new start reads them back, locked.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, initialLocation: '/settings', overrides: overrides);
    final AppLockState lock = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(lockControllerProvider);
    expect(lock.enabled, isTrue);
    expect(lock.locked, isTrue);
    expect(lock.lockAfter.timeout, const Duration(minutes: 5));
    expect(lock.secureScreen, isFalse);
  });
}
