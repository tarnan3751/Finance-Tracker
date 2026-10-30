# Lock

The app lock: the device's biometrics or screen lock asked for when the app starts and
after a timeout in the background, with the app's window kept out of screenshots and the
task switcher while the lock is on or "Block screenshots" is; the same in every flavor.
The decisions are in `PLAN.md` §12: "Lock, privacy and screenshots" and "Release
hardening". The account password as a fallback is not in this phase.

Code:
- `app/lib/features/lock/domain/` (pure Dart):
  - `device_auth.dart`: `DeviceAuth` (`isSupported()`, `authenticate(reason)`) and
    `AuthOutcome` (`success`, `failed`, `cancelled`, `noCredentials`, `lockedOut`,
    `unavailable`);
  - `lock_settings.dart`: `LockAfter` (`off`, `immediately`, `oneMinute`, `fiveMinutes`,
    `fifteenMinutes`) and how it is stored.
- `data/`:
  - `local_auth_device_auth.dart`: `local_auth` 3 (every flavor on a device);
  - `fake_device_auth.dart`: the tests' and the integration run's.
- `application/`:
  - `device_auth_provider.dart`: `deviceAuthProvider` (the fake by default, `local_auth`
    through `overridesFor` in every flavor) and `deviceAuthSupportedProvider`;
  - `lock_hold.dart`: `LockHold` and `lockHoldProvider`;
  - `lock_controller.dart`: `LockController` and `AppLockState`.
- `presentation/`:
  - `lock_gate.dart`: `LockGate` and `LockScreen`;
  - `security_section.dart`: the Settings section.
- The platform seams are `core/platform/screen_security.dart` and
  `core/platform/monotonic_clock.dart` (`app-core.md`, **Screen security** and **The
  monotonic clock**). The Android side is in `build.md`, **Android**.

## The controller

`LockController` (keep-alive) holds `AppLockState`: `enabled`, `lockAfter`,
`secureScreen`, `locked`, `authenticating` and `failure` (how the last attempt that did
not unlock ended), with `secure` = `enabled || secureScreen`.

- **Cold start.** `build()` starts reading the three `app_meta` keys and `bootstrap`
  awaits `restored()` before `runApp`, so with the lock enabled the first frame is the
  lock screen. Until the read completes (only in tests that do not await it) the state is
  unlocked with the lock off.
- **Return from the background.** An `AppLifecycleListener` records the monotonic clock
  (`SystemClock.elapsedRealtime`, deep sleep included; never the wall clock, which the
  user can change) at `paused`, and at `resumed` locks when the lock is enabled, the
  choice is not `off`, and the time away is at least its timeout (`immediately` is zero:
  every return). `inactive` alone (the unlock prompt, a permission dialog, the
  notification shade) is not the background. A clock that cannot be read locks.
- **Covered while away.** The clock is read over a channel, so the decision on return
  takes a round trip or two; the content must not be drawn meanwhile. At `hidden`, with
  the lock enabled and a choice other than `off`, the state is set at once: `locked` for
  `immediately` with no hold, otherwise `covered`. A held stay is covered too; the hold
  only moves the decision on return, which uncovers it within its bound. No frame is drawn while hidden or
  paused, so the first frame of the return is already the lock screen; at `resumed` the
  time away decides between locking and uncovering. `shown` (`locked || covered`) is what
  the gate follows; a covered lock screen has no button, since nothing is decided yet.
- **Unlock.** `unlock(reason)` runs one prompt at a time (a second call while one is
  open does nothing); `success` unlocks, anything else keeps the lock with the outcome in
  `failure`. `enable(reason)` turns the lock on only after a successful prompt;
  `disable()`, `setLockAfter()` and `setSecureScreen()` write their key and need none.
- **The secure flag.** Applied once the settings are read (before the first frame) and
  again whenever `secure` changes; a failure to set it is logged by type.

## Holding the lock open

The app's own trips to another activity must not lock it on their return: Plaid Link
(`LinkController.link` and `repair`), the "Save as" dialog and the share sheet
(`runExport`, and the backup's in `backup_screen.dart`), the restore's file picker
(`restore_flow.dart`), the camera and the photo picker (the transaction editor's receipt),
and the unlock prompt itself (a device credential screen pauses the app) run inside
`LockHold.holdOpen(action)`, a count of the activities open. A `paused` that arrives while
the count is above zero marks that stay as held, so it does not matter whether the
activity's result reaches Dart before or after `resumed` (Android delivers
`onActivityResult` before `onResume`). A held stay locks on its return only once it has
lasted `heldStayBound` (five minutes) or the "Lock after" timeout, whichever is longer
(`PLAN.md` §12): a trip to Link or the share sheet does not lock the app, but a user who
leaves from inside one and stays away longer comes back to the lock screen, with the held
flow's result handled behind it. With "Lock after" at "Only when the app starts" no return
locks, held or not.

Each held call completes only when its activity closes, so the hold spans the pause:
`share_plus` 13.3.1 on Android starts the chooser with `startActivityForResult` and
answers the call from `onActivityResult` (`ShareSuccessManager`), when the sheet closes;
`flutter_file_dialog`'s "Save as" and `image_picker` answer from their activity results;
Plaid Link's launcher completes on its exit or success event.

`holdOpen` is on its own keep-alive provider rather than on the controller because the
controller builds an `AppLifecycleListener`, which needs the Flutter binding: the
features that hold the lock (the Link controller among them) are tested in plain `test()`
containers without one.

## The gate

`FinanceTrackerApp`'s `MaterialApp.builder` wraps everything (the flavor banner and the
router) in `LockGate`, so the lock screen covers every route, sheet and dialog. While
locked, the app below stays built (its state survives) inside `ExcludeSemantics` and
`ExcludeFocus`, the opaque `LockScreen` takes every touch, and the gate's
`WidgetsBindingObserver`, registered before the router's back button dispatcher, consumes
the back button. The predictive back gesture would bypass it: Flutter's default Android
page transition (`PredictiveBackPageTransitionsBuilder`) claims the gesture for its route
and pops it on commit without a pop route. So while the lock screen is shown, the gate's
`Theme` gives Android pages `FadeForwardsPageTransitionsBuilder`, which claims nothing,
and the gesture's commit falls back to the pop route the gate keeps. The `Theme` is in
the tree whether locked or not, so the app below keeps its state. `LockScreen` shows the app's name, the unlock button (no prompt opens by
itself) and, after an attempt that did not unlock, why, in the app's words, with "Try
again": not recognized, cancelled, "Set a screen lock on this device first", too many
attempts, or the check could not run. A device whose screen lock was removed while the
lock was on shows "Set a screen lock on this device first": the way out is to set a
screen lock on the device again, unlock the app with it, and turn "Require unlock" off in
Settings if the lock is no longer wanted. There is no fallback to the account password in
this phase.

## Settings

The Security section of Settings, between Appearance and Data:

| Setting | `app_meta` key | Values |
|---|---|---|
| Require unlock | `lock_enabled` | `true`, `false`; absent is off |
| Lock after | `lock_timeout_seconds` | `0`, `60`, `300`, `900`, or `off` ("Only when the app starts"); absent is `off` |
| Block screenshots | `secure_screen` | `true`, `false`; absent is `AppConfig.secureScreenDefault` (prod on, dev and demo off) |

They describe the device, so they live in `app_meta`, which never syncs; in the demo
flavor `app_meta` is in memory and they last as long as the process. "Require unlock" is
disabled with "Set a screen lock on this device first" when `isDeviceSupported()` is
false (asked again whenever the app returns, so setting a screen lock up takes effect);
turning it on opens one prompt, and a prompt that does not pass leaves it off with a snack
bar saying why. "Lock after" is enabled with the lock and chosen in a dialog. "Block
screenshots" says it is always on while unlock is required. A backup restored onto
another device does not carry them: the restore drops the three keys (`backup.md`).

## local_auth

`LocalAuthDeviceAuth` calls `authenticate(localizedReason:, biometricOnly: false,
persistAcrossBackgrounding: true)`: the device credential is allowed, so a device with
only a PIN works, and the prompt survives a trip to the background. `true` is `success`,
`false` is `failed`; a `LocalAuthException` is mapped by code (`userCanceled`,
`systemCanceled`, `timeout`, `userRequestedFallback` to `cancelled`; `noCredentialsSet`,
`noBiometricsEnrolled`, `noBiometricHardware` to `noCredentials`; `temporaryLockout`,
`biometricLockout` to `lockedOut`; anything else, including codes the plugin adds later,
to `unavailable`), and only the code is logged. `isDeviceSupported()` failing counts as
unsupported.

## Tests

- `app/test/features/lock/lock_controller_test.dart`: the cold start with the lock on and
  off, the return at every `LockAfter` (a second short, then the timeout), the lock off,
  `inactive`, the hold with the activity's result before and after the resume, a held stay
  a second short of its bound and at it (the five minutes, or a longer timeout), a failed
  and a cancelled prompt, one prompt at a time, enabling, and the secure flag at start
  and on each change in prod and demo;
- `lock_gate_test.dart`: the gate on the real app (the lock screen, the app hidden from
  the screen reader, "Try again", the back button, the predictive back gesture), the
  lock screen on every frame of a return before the clock answers (and the cover lifted
  after a short one), the lock screen at text scale 2, the switch disabled without a
  screen lock, a cancelled enable, and the section's three settings round-tripping;
- the Lock screen, the Security section and the "Lock after" dialog in
  `app/test/accessibility_test.dart`, light and dark, and at text scale 2;
- the hold around Link (`test/features/items/application/link_controller_test.dart`) and
  the share sheet (`test/features/export/presentation/export_screen_test.dart`);
- `app/test/core/platform/platform_channels_test.dart`: the two channels and
  `secureScreenDefault`;
- on the harness, `app/integration_test/lock_test.dart`: the demo with the fake check and
  the lock on shows the lock screen, keeps it after a cancel, and shows the accounts
  after a pass; `MainActivity`'s two channels answer.
