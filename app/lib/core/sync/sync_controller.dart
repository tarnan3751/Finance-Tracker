/// Runs the device's sync sessions and keeps their status (`docs/reference/sync-app.md`,
/// **The controller**).
///
/// When the local data syncs (dev and prod, `localDataSyncsProvider`) and someone is
/// signed in (`syncDeviceIdProvider`, from the session; `syncRelayProvider`, the API's
/// relay), a session runs: when the controller starts, when the app resumes,
/// [SyncController.syncNow], and the debounce (3 s by default) after the last local
/// change, which it sees as the outbox growing. One session runs at a time; a
/// trigger during a run runs one more after it. A device change (sign-out, sign-in) lets
/// a session in flight finish and discards its report. Before each session the device
/// clock adopts the server's device id, moving the outbox to it. A relay whose log was
/// reset (`SyncCursorInvalidException`) resets the pull cursor to 0 and runs again once.
/// The demo flavor never syncs.
library;

import 'dart:async';
import 'dart:convert';

import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/tables/sync_meta.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/device_clock.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sync_engine/sync_engine.dart';

part 'sync_controller.g.dart';

final Logger _log = Logger('sync');

/// The device's sync status, and "Sync now".
@Riverpod(keepAlive: true)
class SyncController extends _$SyncController {
  // The session machinery lives as long as the controller; build() runs once (keep-alive,
  // and the device id arrives through a listener), so none of it is ever reset while a
  // session is in flight.
  Future<void>? _running;
  bool _again = false;
  Timer? _debounce;
  int? _pending;
  StreamSubscription<SyncLedger>? _ledger;
  AppLifecycleListener? _lifecycle;

  @override
  SyncStatus build() {
    if (ref.watch(appConfigProvider).flavor == Flavor.demo ||
        !ref.watch(localDataSyncsProvider)) {
      return SyncStatus.unavailable;
    }
    // The change can reach the controller while a widget builds (a screen watching a
    // paused controller resumes it, which catches up on the device id), when setting the
    // state is not allowed: it is applied right after, unless the controller is gone.
    ref.listen<String?>(
      syncDeviceIdProvider,
      (_, next) => scheduleMicrotask(() {
        if (ref.mounted) _deviceChanged(next);
      }),
    );
    ref.onDispose(() {
      _debounce?.cancel();
      _lifecycle?.dispose();
      unawaited(_ledger?.cancel());
    });
    if (ref.read(syncDeviceIdProvider) == null) return SyncStatus.signedOut;
    _start();
    return const SyncStatus(phase: SyncPhase.idle);
  }

  /// Runs a session now, or one more after the one running. Completes when it has run;
  /// a failure is kept in the status, not thrown. Does nothing unless signed in.
  Future<void> syncNow() {
    if (state.phase != SyncPhase.idle && state.phase != SyncPhase.running) {
      return Future<void>.value();
    }
    final Future<void>? running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  // Signed in for the first time since the controller started: follow the outbox and the
  // app's lifecycle, restore the last status, and run a session.
  void _start() {
    if (_ledger != null) return;
    final DriftSyncStore store = ref.read(driftSyncStoreProvider);
    final Duration debounce = ref.read(syncDebounceProvider);
    _ledger = store.watchLedger().listen((SyncLedger value) {
      // The first value is the outbox at start, which the start's session pushes; only
      // a later growth is a local change to debounce.
      final bool grew = _pending != null && value.pending > _pending!;
      _pending = value.pending;
      state = state.copyWith(ledger: value, failure: state.failure);
      if (grew) {
        _debounce?.cancel();
        _debounce = Timer(debounce, () => unawaited(syncNow()));
      }
    });
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(syncNow()));
    unawaited(_restoreThenSync(store));
  }

  // The session's device changed (sign-out, sign-in, another account's sign-in). A
  // session in flight is left to finish (the engine cannot cancel one); the next run, one
  // at a time as ever, substitutes the new node before it pushes.
  void _deviceChanged(String? deviceId) {
    _debounce?.cancel();
    if (deviceId == null) {
      state = state.copyWith(phase: SyncPhase.signedOut, failure: null);
      return;
    }
    final bool started = _ledger != null;
    _start();
    state = state.copyWith(
      phase: _running == null ? SyncPhase.idle : SyncPhase.running,
      failure: null,
    );
    // A first start runs its own session after restoring the status.
    if (started) unawaited(syncNow());
  }

  Future<void> _restoreThenSync(DriftSyncStore store) async {
    final String? at = await store.meta(SyncMetaKeys.lastSyncAt);
    final String? report = await store.meta(SyncMetaKeys.lastReport);
    if (!ref.mounted) return;
    state = state.copyWith(
      lastSyncAt: at == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.parse(at), isUtc: true),
      lastSummary: report == null
          ? null
          : SyncSummary.fromJson(jsonDecode(report) as Map<String, Object?>),
      failure: state.failure,
    );
    await syncNow();
  }

  // After a session whose device changed: the phase the current device gives.
  void _settleAfterDeviceChange() {
    state = state.copyWith(
      phase: ref.read(syncDeviceIdProvider) == null
          ? SyncPhase.signedOut
          : SyncPhase.idle,
      failure: null,
    );
  }

  Future<void> _loop() async {
    do {
      _again = false;
      _debounce?.cancel();
      await _runOnce();
    } while (_again && ref.mounted);
  }

  Future<void> _runOnce() async {
    final DriftSyncStore store = ref.read(driftSyncStoreProvider);
    final DeviceClock deviceClock = ref.read(deviceClockProvider);
    final SyncRelay? relay = ref.read(syncRelayProvider);
    final String? deviceId = ref.read(syncDeviceIdProvider);
    final Clock clock = ref.read(clockProvider);
    if (relay == null || deviceId == null) return;
    state = state.copyWith(phase: SyncPhase.running, failure: state.failure);
    try {
      await deviceClock.adopt(deviceId);
      Future<SyncReport> session() async => SyncSession(
        store,
        relay,
        await store.transaction(deviceClock.current),
        nowWallMillis: () => clock.nowUtc().millisecondsSinceEpoch,
      ).run();
      SyncReport report;
      try {
        report = await session();
      } on SyncCursorInvalidException {
        // The relay's log was reset: pull everything again (merging is idempotent).
        _log.warning('the relay was reset; pulling from the start');
        await store.savePullCursor(0);
        report = await session();
      }
      final DateTime at = clock.nowUtc();
      final SyncSummary summary = SyncSummary.of(report);
      await store.saveMeta(
        SyncMetaKeys.lastSyncAt,
        '${at.millisecondsSinceEpoch}',
      );
      await store.saveMeta(
        SyncMetaKeys.lastReport,
        jsonEncode(summary.toJson()),
      );
      for (final PushRejection rejection in report.rejected) {
        // The clock and reason only: never a payload.
        _log.warning('push refused ${rejection.hlc}: ${rejection.reason.name}');
      }
      if (!ref.mounted) return;
      if (ref.read(syncDeviceIdProvider) != deviceId) {
        // The device changed during the session: its report is the old device's. What
        // the relay accepted stays synced (stored under the old node); the rest moves to
        // the new node on the next run.
        _settleAfterDeviceChange();
        return;
      }
      state = state.copyWith(
        phase: SyncPhase.idle,
        lastSyncAt: at,
        lastSummary: summary,
        failure: null,
      );
    } on Object catch (e) {
      _log.warning('sync failed: ${e.runtimeType}');
      if (!ref.mounted) return;
      if (ref.read(syncDeviceIdProvider) != deviceId) {
        _settleAfterDeviceChange();
        return;
      }
      state = state.copyWith(
        phase: SyncPhase.idle,
        failure: classifySyncError(e),
      );
    }
  }
}

/// The [SyncFailure] that [error] is: no answer is offline; any other API failure is the
/// server's.
SyncFailure classifySyncError(Object error) => switch (error) {
  NetworkError() => SyncFailure.offline,
  ApiException() => SyncFailure.server,
  _ => SyncFailure.other,
};
