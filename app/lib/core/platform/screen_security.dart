/// The platform boundary for the window's secure flag (`docs/reference/app-core.md`,
/// **Screen security**): while it is set, Android blanks the app in screenshots, screen
/// recordings and the task switcher's thumbnail (`FLAG_SECURE`). The lock feature sets it
/// whenever the lock is enabled or "Block screenshots" is on (`features/lock/`). A
/// MethodChannel to `MainActivity` is behind it in every flavor, [NoWindowScreenSecurity]
/// in the background task's engine, which has no window and no such channel; a fake that
/// records the calls stands in for the tests. Pure Dart, no Flutter import.
library;

/// Sets or clears the window's secure flag.
abstract interface class ScreenSecurity {
  /// Marks the app's window secure when [secure], or not.
  Future<void> set(bool secure);
}

/// The secure flag in an engine with no window (the background task's): nothing to set.
final class NoWindowScreenSecurity implements ScreenSecurity {
  /// The flag of no window.
  const NoWindowScreenSecurity();

  @override
  Future<void> set(bool secure) async {}
}
