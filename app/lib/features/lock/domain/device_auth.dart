/// The platform boundary for the app lock's check (`docs/reference/lock.md`): the device's
/// biometrics, or its PIN, pattern or password when the user prefers or has no biometrics
/// enrolled. `local_auth` is behind it in every flavor; a fake stands in for the tests and
/// the lock's integration run, so neither needs enrolled biometrics. Pure Dart, no Flutter
/// import.
library;

/// Asks the device who is holding it.
abstract interface class DeviceAuth {
  /// Whether the device can check its user: biometrics enrolled or a screen lock set.
  Future<bool> isSupported();

  /// Prompts with [reason] and completes with what came of it; never throws.
  Future<AuthOutcome> authenticate(String reason);
}

/// What came of one prompt.
enum AuthOutcome {
  /// The user proved who they are.
  success,

  /// The user did not pass the check.
  failed,

  /// The user, the system or a timeout closed the prompt.
  cancelled,

  /// The device has no screen lock and no biometrics to check with.
  noCredentials,

  /// Too many failed attempts; the device refuses for a while.
  lockedOut,

  /// The check could not run (no window to show it in, a device error).
  unavailable,
}
