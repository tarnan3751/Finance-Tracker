/// The [BackgroundWork] of dev and prod, over `workmanager` 0.10.10 (MIT;
/// `docs/reference/background.md`, **Scheduling**).
///
/// - The plugin is initialized once, on first use, with the app's dispatcher (a top-level
///   function the plugin starts in a new engine when the work runs).
/// - The periodic sync is unique work `ft.sync.periodic`, every [backgroundSyncEvery] with
///   the given constraints, `ExistingPeriodicWorkPolicy.keep` (a restart keeps the
///   cadence; the plugin's own default would update it), a linear backoff from
///   WorkManager's default delay of 30 s, and no foreground service.
/// - The one-off is unique work `ft.sync.once` (kept while one waits) on a connected
///   network, expedited on Android 12 and later and run as plain work when the quota is
///   out; below Android 12 expedited work needs a foreground notification the plugin's
///   worker does not give, so it is plain work there.
/// - The developer menu's delayed sync is unique work `ft.sync.dev` with an initial delay
///   on a connected network, replacing one that waits, never expedited (WorkManager
///   refuses a delay on expedited work).
/// - All three carry the tag `ft.sync`, which [cancelAll] cancels: never WorkManager's own
///   cancel-everything, which would also cancel the Plaid SDK's work.
/// - The flavor travels in the input data, so one dispatcher serves every flavor.
library;

import 'package:finance_tracker/core/platform/background_work.dart';
import 'package:workmanager/workmanager.dart';

/// The unique name of the periodic sync.
const String periodicSyncName = 'ft.sync.periodic';

/// The unique name of the one-off sync.
const String oneOffSyncName = 'ft.sync.once';

/// The unique name of the developer menu's delayed sync.
const String delayedSyncName = 'ft.sync.dev';

/// The tag every sync carries.
const String syncTag = 'ft.sync';

/// The task name the dispatcher receives.
const String syncTaskName = 'sync';

/// The input data key naming the flavor.
const String flavorInputKey = 'flavor';

/// Background work through WorkManager.
final class WorkmanagerBackgroundWork implements BackgroundWork {
  /// The work of [flavor], run by [dispatcher], through `platform` (the plugin's
  /// registered implementation by default); [sdkInt] is Android's API level.
  WorkmanagerBackgroundWork({
    required this.dispatcher,
    required this.flavor,
    required this.sdkInt,
    this._platform,
  });

  /// The top-level function the plugin runs the work in.
  final void Function() dispatcher;

  /// The flavor's name, handed to the dispatcher.
  final String flavor;

  /// Android's API level.
  final Future<int> Function() sdkInt;

  final WorkmanagerPlatform? _platform;
  Future<void>? _initialized;

  // The plugin's facade puts its Android implementation in place when first built.
  WorkmanagerPlatform get _work {
    if (_platform case final WorkmanagerPlatform platform) return platform;
    Workmanager();
    return WorkmanagerPlatform.instance;
  }

  Future<void> _ready() => _initialized ??= _work.initialize(dispatcher);

  Map<String, dynamic> get _input => {flavorInputKey: flavor};

  @override
  Future<void> schedulePeriodicSync({
    required Duration every,
    required BackgroundConstraints constraints,
  }) async {
    await _ready();
    await _work.registerPeriodicTask(
      periodicSyncName,
      syncTaskName,
      frequency: every,
      inputData: _input,
      constraints: Constraints(
        networkType: constraints.networkConnected
            ? NetworkType.connected
            : NetworkType.notRequired,
        requiresBatteryNotLow: constraints.batteryNotLow,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(seconds: 30),
      tag: syncTag,
    );
  }

  @override
  Future<void> runSyncNow() async {
    await _ready();
    final bool expedited = await sdkInt() >= 31;
    await _work.registerOneOffTask(
      oneOffSyncName,
      syncTaskName,
      inputData: _input,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      outOfQuotaPolicy: expedited
          ? OutOfQuotaPolicy.runAsNonExpeditedWorkRequest
          : null,
      expedited: expedited,
      tag: syncTag,
    );
  }

  @override
  Future<void> runSyncLater(Duration delay) async {
    await _ready();
    await _work.registerOneOffTask(
      delayedSyncName,
      syncTaskName,
      inputData: _input,
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      tag: syncTag,
    );
  }

  @override
  Future<void> cancelAll() async {
    await _ready();
    await _work.cancelByTag(syncTag);
  }

  @override
  Future<BackgroundWorkState> periodicState() async {
    await _ready();
    final WorkInfo? info = await _work.getWorkInfo(periodicSyncName);
    return switch (info?.state) {
      WorkState.scheduled => BackgroundWorkState.scheduled,
      WorkState.running => BackgroundWorkState.running,
      _ => BackgroundWorkState.none,
    };
  }
}
