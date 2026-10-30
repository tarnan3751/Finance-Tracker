/// The app lock's settings on this device (`docs/reference/lock.md`), kept in `app_meta`
/// because they describe the device, not the user's data: whether the lock is enabled
/// (`lock_enabled`), how long the app may stay in the background before it locks again
/// (`lock_timeout_seconds`), and whether screenshots are blocked (`secure_screen`). Pure
/// Dart, no Flutter import.
library;

/// How long the app may be in the background before it locks on its return.
enum LockAfter {
  /// Never on a return; the lock still holds every cold start.
  off(null),

  /// On every return from the background.
  immediately(Duration.zero),

  /// After a minute in the background.
  oneMinute(Duration(minutes: 1)),

  /// After five minutes in the background.
  fiveMinutes(Duration(minutes: 5)),

  /// After fifteen minutes in the background.
  fifteenMinutes(Duration(minutes: 15));

  const LockAfter(this.timeout);

  /// The time in background that locks the app, or null for [off].
  final Duration? timeout;

  /// The value stored under `lock_timeout_seconds`: the seconds, or `off`.
  String get stored => timeout == null ? 'off' : '${timeout!.inSeconds}';

  /// The choice stored as [value]: [off] when nothing or something unknown is stored.
  static LockAfter fromStored(String? value) =>
      LockAfter.values.firstWhere((a) => a.stored == value, orElse: () => off);
}
