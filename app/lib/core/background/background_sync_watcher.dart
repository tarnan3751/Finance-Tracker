/// The app's side of the background sync (`docs/reference/background.md`,
/// **Scheduling**, **After a run**), while something listens (`bootstrap` does, for the
/// life of the app; the data must sync, so never in the demo flavor):
///
/// - schedules the periodic sync whenever someone is signed in and the device-local
///   switch is on (`background_sync_enabled`, absent meaning on; [setEnabled]), and
///   cancels it on a sign-out or when the switch goes off;
/// - on resume, when the worker ran a cycle of its own since the app last looked
///   (`background_last_run` moved, not run by the app), tells every Drift stream to read
///   again: a stream does not see another connection's writes.
///
/// A platform failure is logged by type.
library;

import 'dart:async';

import 'package:finance_tracker/core/background/background_cycle.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/background_work.dart';
import 'package:finance_tracker/core/platform/background_work_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'background_sync_watcher.g.dart';

final Logger _log = Logger('background');

/// Keeps the schedule and the screens in step with the background sync.
@Riverpod(keepAlive: true)
class BackgroundSyncWatcher extends _$BackgroundSyncWatcher {
  AppLifecycleListener? _lifecycle;
  String? _lastSeen;

  @override
  void build() {
    if (!ref.watch(localDataSyncsProvider)) return;
    ref.listen<String?>(
      syncDeviceIdProvider,
      (_, deviceId) => unawaited(_apply(deviceId)),
      fireImmediately: true,
    );
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_resumed()));
    ref.onDispose(() => _lifecycle?.dispose());
    unawaited(_look());
  }

  /// Whether the background sync is on (on until the user turns it off).
  Future<bool> enabled() async =>
      await ref
          .read(appMetaStoreProvider)
          .read(AppMetaKeys.backgroundSyncEnabled) !=
      'false';

  /// Turns the background sync on or off on this device.
  Future<void> setEnabled(bool on) async {
    await ref
        .read(appMetaStoreProvider)
        .write(AppMetaKeys.backgroundSyncEnabled, '$on');
    await _apply(ref.read(syncDeviceIdProvider));
  }

  Future<void> _apply(String? deviceId) async {
    final BackgroundWork work = ref.read(backgroundWorkProvider);
    try {
      if (deviceId != null && await enabled()) {
        await work.schedulePeriodicSync(
          every: backgroundSyncEvery,
          constraints: backgroundSyncConstraints,
        );
      } else {
        await work.cancelAll();
      }
    } on Object catch (e) {
      _log.warning('the background sync schedule failed: ${e.runtimeType}');
    }
  }

  // The last run as the app last saw it; true when it moved and the worker ran it.
  Future<bool> _look() async {
    final String? now = await ref
        .read(appMetaStoreProvider)
        .read(AppMetaKeys.backgroundLastRun);
    final bool moved = _lastSeen != null && now != _lastSeen;
    _lastSeen = now ?? '';
    return moved && !(BackgroundRun.parse(now)?.delegated ?? true);
  }

  Future<void> _resumed() async {
    try {
      if (!await _look() || !ref.mounted) return;
      final AppDatabase database = ref.read(databaseProvider);
      database.markTablesUpdated(database.allTables);
    } on Object catch (e) {
      _log.warning('the background run was not read: ${e.runtimeType}');
    }
  }
}
