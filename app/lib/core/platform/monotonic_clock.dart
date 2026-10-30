/// The platform boundary for elapsed time that the user cannot change and that keeps
/// counting while the device sleeps (`docs/reference/app-core.md`, **The monotonic
/// clock**): the app lock measures the time in background with it (`features/lock/`).
/// `SystemClock.elapsedRealtime` through a MethodChannel to `MainActivity` is behind it in
/// every flavor (a Dart `Stopwatch` reads `CLOCK_MONOTONIC`, which stops in deep sleep);
/// a fake the test advances stands in for the tests. Pure Dart, no Flutter import.
library;

/// Time since an arbitrary fixed point, never going back.
abstract interface class MonotonicClock {
  /// The time elapsed since the clock's fixed point (the device's boot on Android).
  Future<Duration> elapsed();
}

/// The [MonotonicClock] of the tests: it stands still until the test advances it.
final class FakeMonotonicClock implements MonotonicClock {
  Duration _now = Duration.zero;

  /// Moves the clock on by [by].
  void advance(Duration by) => _now += by;

  @override
  Future<Duration> elapsed() async => _now;
}
