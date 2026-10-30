/// The platform boundary for work Android runs while the app is closed
/// (`docs/reference/background.md`, **Scheduling**): the periodic background sync and a
/// one-off sync on demand. `workmanager` is behind it in dev and prod
/// (`workmanager_background_work.dart`); a fake that records every call stands in for the
/// demo flavor, which never schedules anything, and the tests
/// (`fake_background_work.dart`). Pure Dart, no Flutter import.
library;

/// What a scheduled sync waits for.
final class BackgroundConstraints {
  /// The constraints: a connected network, and the battery not low, when asked.
  const BackgroundConstraints({
    this.networkConnected = true,
    this.batteryNotLow = true,
  });

  /// Whether a connected network is needed.
  final bool networkConnected;

  /// Whether the battery must not be low.
  final bool batteryNotLow;

  @override
  bool operator ==(Object other) =>
      other is BackgroundConstraints &&
      other.networkConnected == networkConnected &&
      other.batteryNotLow == batteryNotLow;

  @override
  int get hashCode => Object.hash(networkConnected, batteryNotLow);
}

/// How often the background sync runs: hourly (WorkManager's window makes it 60 to 75
/// minutes), on a network, with the battery not low.
const Duration backgroundSyncEvery = Duration(minutes: 60);

/// What the background sync waits for.
const BackgroundConstraints backgroundSyncConstraints = BackgroundConstraints();

/// Where the platform has the periodic sync.
enum BackgroundWorkState {
  /// Scheduled, waiting for its next run.
  scheduled,

  /// Running now.
  running,

  /// Not scheduled: never, cancelled, or finished for good.
  none,
}

/// Schedules the background sync.
abstract interface class BackgroundWork {
  /// Schedules the periodic sync every [every] under [constraints]. Idempotent: a sync
  /// already scheduled keeps its cadence.
  Future<void> schedulePeriodicSync({
    required Duration every,
    required BackgroundConstraints constraints,
  });

  /// Runs one sync as soon as a network is connected, whether or not the app is open.
  Future<void> runSyncNow();

  /// Cancels the periodic sync and any one-off not yet run; a run in progress finishes.
  Future<void> cancelAll();

  /// Where the periodic sync stands.
  Future<BackgroundWorkState> periodicState();
}
