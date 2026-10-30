// The app lock's controller: locked on a cold start only when enabled, the resume rule at
// every "Lock after" choice on a fake monotonic clock, `inactive` not counted as the
// background, a hold suppressing the lock whichever of its end and the resume comes first,
// one prompt at a time, a failed prompt keeping the lock, and the window's secure flag set
// at start and on every change.
import 'dart:async';

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_screen_security.dart';
import 'package:finance_tracker/core/platform/monotonic_clock.dart';
import 'package:finance_tracker/core/platform/monotonic_clock_provider.dart';
import 'package:finance_tracker/core/platform/screen_security_provider.dart';
import 'package:finance_tracker/features/lock/application/device_auth_provider.dart';
import 'package:finance_tracker/features/lock/application/lock_controller.dart';
import 'package:finance_tracker/features/lock/application/lock_hold.dart';
import 'package:finance_tracker/features/lock/data/fake_device_auth.dart';
import 'package:finance_tracker/features/lock/domain/device_auth.dart';
import 'package:finance_tracker/features/lock/domain/lock_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// One app's lock on fakes.
final class _Lock {
  _Lock({
    AppConfig? config,
    Map<String, String> meta = const {},
    FakeDeviceAuth? auth,
  }) : auth = auth ?? FakeDeviceAuth() {
    for (final MapEntry<String, String> e in meta.entries) {
      unawaited(this.meta.write(e.key, e.value));
    }
    container = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(config ?? AppConfig.prod()),
        appMetaStoreProvider.overrideWithValue(this.meta),
        deviceAuthProvider.overrideWithValue(this.auth),
        screenSecurityProvider.overrideWithValue(screen),
        monotonicClockProvider.overrideWithValue(clock),
      ],
    );
  }

  final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
  final FakeDeviceAuth auth;
  final FakeScreenSecurity screen = FakeScreenSecurity();
  final FakeMonotonicClock clock = FakeMonotonicClock();
  late final ProviderContainer container;

  LockController get controller =>
      container.read(lockControllerProvider.notifier);
  AppLockState get state => container.read(lockControllerProvider);

  Future<void> start() => controller.restored();
}

/// Plays the lifecycle states one at a time, as the engine reports them.
Future<void> _go(WidgetTester tester, List<AppLifecycleState> states) async {
  for (final AppLifecycleState state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
}

const List<AppLifecycleState> _toBackground = [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
];
const List<AppLifecycleState> _toForeground = [
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

/// Leaves the app in the background for [away], then brings it back.
Future<void> _away(WidgetTester tester, _Lock lock, Duration away) async {
  await _go(tester, _toBackground);
  lock.clock.advance(away);
  await _go(tester, _toForeground);
}

void main() {
  testWidgets('a cold start is locked when the lock is enabled', (
    tester,
  ) async {
    final _Lock lock = _Lock(meta: {AppMetaKeys.lockEnabled: 'true'});
    await lock.start();

    expect(lock.state.enabled, isTrue);
    expect(lock.state.locked, isTrue);
  });

  testWidgets('a cold start is not locked when the lock is disabled', (
    tester,
  ) async {
    final _Lock plain = _Lock();
    await plain.start();
    final _Lock off = _Lock(meta: {AppMetaKeys.lockEnabled: 'false'});
    await off.start();

    expect(plain.state.locked, isFalse);
    expect(off.state.locked, isFalse);
  });

  for (final LockAfter choice in LockAfter.values) {
    testWidgets('a return locks at ${choice.name} and not before', (
      tester,
    ) async {
      final _Lock lock = _Lock(
        meta: {
          AppMetaKeys.lockEnabled: 'true',
          AppMetaKeys.lockTimeoutSeconds: choice.stored,
        },
      );
      await lock.start();
      await lock.controller.unlock('reason');
      expect(lock.state.locked, isFalse);

      final Duration? timeout = choice.timeout;
      if (timeout == null) {
        await _away(tester, lock, const Duration(days: 1));
        expect(lock.state.locked, isFalse);
        return;
      }
      if (timeout > Duration.zero) {
        await _away(tester, lock, timeout - const Duration(seconds: 1));
        expect(lock.state.locked, isFalse);
      }
      await _away(tester, lock, timeout);
      expect(lock.state.locked, isTrue);
    });
  }

  testWidgets('a return never locks when the lock is disabled', (tester) async {
    final _Lock lock = _Lock(
      meta: {AppMetaKeys.lockTimeoutSeconds: LockAfter.immediately.stored},
    );
    await lock.start();

    await _away(tester, lock, const Duration(hours: 1));

    expect(lock.state.locked, isFalse);
  });

  testWidgets('inactive is not the background', (tester) async {
    final _Lock lock = _Lock(
      meta: {
        AppMetaKeys.lockEnabled: 'true',
        AppMetaKeys.lockTimeoutSeconds: LockAfter.immediately.stored,
      },
    );
    await lock.start();
    await lock.controller.unlock('reason');

    await _go(tester, [AppLifecycleState.inactive]);
    lock.clock.advance(const Duration(hours: 1));
    await _go(tester, [AppLifecycleState.resumed]);

    expect(lock.state.locked, isFalse);
  });

  testWidgets('a hold keeps the lock open, however the return is ordered', (
    tester,
  ) async {
    final _Lock lock = _Lock(
      meta: {
        AppMetaKeys.lockEnabled: 'true',
        AppMetaKeys.lockTimeoutSeconds: LockAfter.immediately.stored,
      },
    );
    await lock.start();
    await lock.controller.unlock('reason');
    final LockHold hold = lock.container.read(lockHoldProvider);

    // The activity's result arrives before the resume (onActivityResult, then onResume).
    Completer<void> picked = Completer<void>();
    Future<void> held = hold.holdOpen(() => picked.future);
    await _go(tester, _toBackground);
    lock.clock.advance(const Duration(minutes: 4));
    picked.complete();
    await held;
    expect(hold.isHeld, isFalse);
    await _go(tester, _toForeground);
    expect(lock.state.locked, isFalse);

    // The resume arrives while the activity's future is still open.
    picked = Completer<void>();
    held = hold.holdOpen(() => picked.future);
    await _away(tester, lock, const Duration(minutes: 4));
    picked.complete();
    await held;
    expect(lock.state.locked, isFalse);

    // Without a hold, the same stay locks.
    await _away(tester, lock, const Duration(minutes: 4));
    expect(lock.state.locked, isTrue);
  });

  for (final (LockAfter choice, Duration bound) in [
    (LockAfter.immediately, heldStayBound),
    (LockAfter.oneMinute, heldStayBound),
    (LockAfter.fifteenMinutes, const Duration(minutes: 15)),
  ]) {
    testWidgets('a held stay at ${choice.name} locks from $bound on', (
      tester,
    ) async {
      final _Lock lock = _Lock(
        meta: {
          AppMetaKeys.lockEnabled: 'true',
          AppMetaKeys.lockTimeoutSeconds: choice.stored,
        },
      );
      await lock.start();
      await lock.controller.unlock('reason');
      final LockHold hold = lock.container.read(lockHoldProvider);

      Future<void> heldStay(Duration away) async {
        final Completer<void> shared = Completer<void>();
        final Future<void> held = hold.holdOpen(() => shared.future);
        await _away(tester, lock, away);
        shared.complete();
        await held;
      }

      // Shorter than the bound: the app's own trip does not lock it.
      await heldStay(bound - const Duration(seconds: 1));
      expect(lock.state.locked, isFalse);

      // As long as the bound: it does, the held flow resuming behind the lock screen.
      await heldStay(bound);
      expect(lock.state.locked, isTrue);
    });
  }

  testWidgets('a failed or cancelled prompt keeps the lock, with why', (
    tester,
  ) async {
    final FakeDeviceAuth auth = FakeDeviceAuth(
      next: () async => AuthOutcome.failed,
    );
    final _Lock lock = _Lock(
      meta: {AppMetaKeys.lockEnabled: 'true'},
      auth: auth,
    );
    await lock.start();

    await lock.controller.unlock('reason');
    expect(lock.state.locked, isTrue);
    expect(lock.state.failure, AuthOutcome.failed);

    auth.next = () async => AuthOutcome.cancelled;
    await lock.controller.unlock('reason');
    expect(lock.state.locked, isTrue);
    expect(lock.state.failure, AuthOutcome.cancelled);

    auth.next = () async => AuthOutcome.success;
    await lock.controller.unlock('reason');
    expect(lock.state.locked, isFalse);
    expect(lock.state.failure, isNull);
  });

  testWidgets('one prompt runs at a time', (tester) async {
    final Completer<AuthOutcome> answer = Completer<AuthOutcome>();
    final FakeDeviceAuth auth = FakeDeviceAuth(next: () => answer.future);
    final _Lock lock = _Lock(
      meta: {AppMetaKeys.lockEnabled: 'true'},
      auth: auth,
    );
    await lock.start();

    final Future<void> first = lock.controller.unlock('reason');
    final Future<void> second = lock.controller.unlock('reason');
    expect(lock.state.authenticating, isTrue);
    answer.complete(AuthOutcome.success);
    await Future.wait([first, second]);

    expect(auth.prompts, hasLength(1));
    expect(lock.state.locked, isFalse);
  });

  testWidgets('enabling the lock needs one successful prompt', (tester) async {
    final FakeDeviceAuth auth = FakeDeviceAuth(
      next: () async => AuthOutcome.cancelled,
    );
    final _Lock lock = _Lock(config: AppConfig.demo(), auth: auth);
    await lock.start();

    expect(await lock.controller.enable('reason'), AuthOutcome.cancelled);
    expect(lock.state.enabled, isFalse);
    expect(await lock.meta.read(AppMetaKeys.lockEnabled), isNull);

    auth.next = () async => AuthOutcome.success;
    expect(await lock.controller.enable('reason'), AuthOutcome.success);
    expect(lock.state.enabled, isTrue);
    expect(lock.state.locked, isFalse);
    expect(await lock.meta.read(AppMetaKeys.lockEnabled), 'true');
  });

  testWidgets('the secure flag is set at start and on every change', (
    tester,
  ) async {
    final _Lock demo = _Lock(config: AppConfig.demo());
    await demo.start();
    expect(demo.screen.calls, [false]);

    await demo.controller.setSecureScreen(on: true);
    await demo.controller.setSecureScreen(on: false);
    await demo.controller.enable('reason');
    // Screenshots stay blocked while the lock is on, whatever the setting.
    await demo.controller.setSecureScreen(on: false);
    await demo.controller.disable();
    expect(demo.screen.calls, [false, true, false, true, false]);

    final _Lock prod = _Lock();
    await prod.start();
    expect(prod.screen.calls, [true]);

    final _Lock chosen = _Lock(meta: {AppMetaKeys.secureScreen: 'false'});
    await chosen.start();
    expect(chosen.screen.calls, [false]);

    final _Lock locked = _Lock(
      config: AppConfig.demo(),
      meta: {AppMetaKeys.lockEnabled: 'true'},
    );
    await locked.start();
    expect(locked.screen.calls, [true]);
  });
}
