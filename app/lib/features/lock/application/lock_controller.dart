/// The app lock (`docs/reference/lock.md`): whether the app is locked, its settings on this
/// device, and the window's secure flag that follows them.
///
/// When the lock is enabled the app is locked on every cold start (`bootstrap` awaits
/// [LockController.restored] before the first frame), and on a return from the background
/// that lasted at least the "Lock after" timeout, measured on the monotonic clock, never
/// the wall clock. Only `paused` counts as the background: `inactive` (the unlock prompt,
/// a permission dialog, the notification shade) does not. A stay that began while
/// [LockHold] was held locks only once it lasts [heldStayBound] or the timeout, whichever
/// is longer: the app's own trip to another activity does not lock it, a long absence
/// from inside one still does. One prompt runs at a time; a failed or cancelled one
/// leaves the app locked, with the outcome for the lock screen to word.
///
/// The window is secure (`core/platform/screen_security.dart`) whenever the lock is
/// enabled, which also blanks the task switcher's thumbnail, or "Block screenshots" is on;
/// that setting starts at the flavor's `AppConfig.secureScreenDefault`. The flag is applied
/// once the settings are read, before the first frame, and again on every change.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/monotonic_clock_provider.dart';
import 'package:finance_tracker/core/platform/screen_security_provider.dart';
import 'package:finance_tracker/features/lock/application/device_auth_provider.dart';
import 'package:finance_tracker/features/lock/application/lock_hold.dart';
import 'package:finance_tracker/features/lock/domain/device_auth.dart';
import 'package:finance_tracker/features/lock/domain/lock_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lock_controller.g.dart';

final Logger _log = Logger('lock');

/// How long a stay in the background that began under a [LockHold] may last before it
/// locks the app, unless the "Lock after" timeout is longer.
const Duration heldStayBound = Duration(minutes: 5);

/// The lock's state.
@immutable
final class AppLockState {
  /// A state.
  const AppLockState({
    required this.enabled,
    required this.lockAfter,
    required this.secureScreen,
    required this.locked,
    this.covered = false,
    this.authenticating = false,
    this.failure,
  });

  /// Whether "Require unlock" is on.
  final bool enabled;

  /// The "Lock after" choice.
  final LockAfter lockAfter;

  /// Whether "Block screenshots" is on.
  final bool secureScreen;

  /// Whether the app is locked: the lock screen covers it until a prompt passes.
  final bool locked;

  /// Whether the app is covered while away, until its return decides between locking
  /// and uncovering (the time away is read asynchronously, and the content must not be
  /// drawn meanwhile).
  final bool covered;

  /// Whether the lock screen is up: locked, or covered while the return is decided.
  bool get shown => locked || covered;

  /// Whether a prompt is open.
  final bool authenticating;

  /// How the last unlock attempt ended when it did not unlock, or null.
  final AuthOutcome? failure;

  /// Whether the window is secure.
  bool get secure => enabled || secureScreen;

  AppLockState _with({
    bool? enabled,
    LockAfter? lockAfter,
    bool? secureScreen,
    bool? locked,
    bool? covered,
    bool? authenticating,
    AuthOutcome? failure,
  }) => AppLockState(
    enabled: enabled ?? this.enabled,
    lockAfter: lockAfter ?? this.lockAfter,
    secureScreen: secureScreen ?? this.secureScreen,
    locked: locked ?? this.locked,
    covered: covered ?? this.covered,
    authenticating: authenticating ?? this.authenticating,
    failure: failure,
  );

  @override
  bool operator ==(Object other) =>
      other is AppLockState &&
      other.enabled == enabled &&
      other.lockAfter == lockAfter &&
      other.secureScreen == secureScreen &&
      other.locked == locked &&
      other.covered == covered &&
      other.authenticating == authenticating &&
      other.failure == failure;

  @override
  int get hashCode => Object.hash(
    enabled,
    lockAfter,
    secureScreen,
    locked,
    covered,
    authenticating,
    failure,
  );
}

/// The app lock and its settings.
@Riverpod(keepAlive: true)
class LockController extends _$LockController {
  late Future<void> _restored;
  Future<Duration>? _pausedAt;
  bool _pausedHeld = false;
  bool? _appliedSecure;

  AppMetaStore get _meta => ref.read(appMetaStoreProvider);

  @override
  AppLockState build() {
    final AppLifecycleListener lifecycle = AppLifecycleListener(
      onHide: _hidden,
      onPause: _paused,
      onResume: () => unawaited(_resumed()),
    );
    ref.onDispose(lifecycle.dispose);
    _restored = _restore();
    return AppLockState(
      enabled: false,
      lockAfter: LockAfter.off,
      secureScreen: ref.read(appConfigProvider).secureScreenDefault,
      locked: false,
    );
  }

  /// Completes once the settings are read, the app locked if the lock is enabled, and the
  /// window's flag applied.
  Future<void> restored() => _restored;

  Future<void> _restore() async {
    final bool enabled = await _meta.read(AppMetaKeys.lockEnabled) == 'true';
    final LockAfter lockAfter = LockAfter.fromStored(
      await _meta.read(AppMetaKeys.lockTimeoutSeconds),
    );
    final String? secureScreen = await _meta.read(AppMetaKeys.secureScreen);
    state = state._with(
      enabled: enabled,
      lockAfter: lockAfter,
      secureScreen: secureScreen == null
          ? ref.read(appConfigProvider).secureScreenDefault
          : secureScreen == 'true',
      locked: enabled,
    );
    await _applySecure();
  }

  /// Prompts with [reason] and unlocks the app when the user passes. Does nothing while a
  /// prompt is open or the app is not locked.
  Future<void> unlock(String reason) async {
    if (!state.locked || state.authenticating) return;
    state = state._with(authenticating: true);
    final AuthOutcome outcome = await _authenticate(reason);
    state = outcome == AuthOutcome.success
        ? state._with(locked: false, authenticating: false)
        : state._with(authenticating: false, failure: outcome);
  }

  /// Turns the lock on once the user passes a prompt with [reason], and completes with how
  /// the prompt ended. Does nothing (completing with [AuthOutcome.unavailable]) while a
  /// prompt is open.
  Future<AuthOutcome> enable(String reason) async {
    if (state.authenticating) return AuthOutcome.unavailable;
    state = state._with(authenticating: true);
    final AuthOutcome outcome = await _authenticate(reason);
    if (outcome == AuthOutcome.success) {
      await _meta.write(AppMetaKeys.lockEnabled, 'true');
      state = state._with(enabled: true, authenticating: false);
      await _applySecure();
    } else {
      state = state._with(authenticating: false);
    }
    return outcome;
  }

  /// Turns the lock off.
  Future<void> disable() async {
    await _meta.write(AppMetaKeys.lockEnabled, 'false');
    state = state._with(enabled: false);
    await _applySecure();
  }

  /// Sets the "Lock after" choice to [lockAfter].
  Future<void> setLockAfter(LockAfter lockAfter) async {
    await _meta.write(AppMetaKeys.lockTimeoutSeconds, lockAfter.stored);
    state = state._with(lockAfter: lockAfter);
  }

  /// Turns "Block screenshots" on or off.
  Future<void> setSecureScreen({required bool on}) async {
    await _meta.write(AppMetaKeys.secureScreen, '$on');
    state = state._with(secureScreen: on);
    await _applySecure();
  }

  // The prompt itself takes the app to the background when the device asks for its
  // credential on a screen of its own, so it holds the lock open.
  Future<AuthOutcome> _authenticate(String reason) async {
    try {
      return await ref
          .read(lockHoldProvider)
          .holdOpen(() => ref.read(deviceAuthProvider).authenticate(reason));
    } on Object catch (e) {
      _log.warning('the unlock prompt failed: ${e.runtimeType}');
      return AuthOutcome.unavailable;
    }
  }

  // Leaving the screen: with a return that may lock, the app is covered at once, so no
  // frame between the return and the clock's answer shows its content; with "Immediately"
  // and no hold it is simply locked. A trip the app made itself (a hold) is covered too:
  // the hold only moves the decision on return, which uncovers a stay within its bound.
  void _hidden() {
    final Duration? timeout = state.lockAfter.timeout;
    if (!state.enabled || timeout == null || state.locked) return;
    state = timeout == Duration.zero && !ref.read(lockHoldProvider).isHeld
        ? state._with(locked: true)
        : state._with(covered: true);
  }

  void _paused() {
    _pausedHeld = ref.read(lockHoldProvider).isHeld;
    _pausedAt = ref.read(monotonicClockProvider).elapsed();
  }

  Future<void> _resumed() async {
    final Future<Duration>? pausedAt = _pausedAt;
    _pausedAt = null;
    final Duration? timeout = state.lockAfter.timeout;
    if (pausedAt == null || !state.enabled || timeout == null) {
      _uncover();
      return;
    }
    // A stay begun under a hold (the app's own trip to Link, a dialog, the camera)
    // locks only past the longer of the timeout and the bound.
    final Duration bound = _pausedHeld && timeout < heldStayBound
        ? heldStayBound
        : timeout;
    try {
      final Duration away =
          await ref.read(monotonicClockProvider).elapsed() - await pausedAt;
      if (away >= bound && state.enabled) {
        state = state._with(locked: true, covered: false);
      } else {
        _uncover();
      }
    } on Object catch (e) {
      // Without a reading the time away is unknown: lock rather than guess.
      _log.warning('the clock could not be read: ${e.runtimeType}');
      state = state._with(locked: true, covered: false);
    }
  }

  void _uncover() {
    if (state.covered) state = state._with(covered: false);
  }

  Future<void> _applySecure() async {
    final bool secure = state.secure;
    if (_appliedSecure == secure) return;
    _appliedSecure = secure;
    try {
      await ref.read(screenSecurityProvider).set(secure);
    } on Object catch (e) {
      _appliedSecure = null;
      _log.warning('the secure flag could not be set: ${e.runtimeType}');
    }
  }
}
