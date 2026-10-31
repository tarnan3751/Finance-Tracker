/// The [BackgroundWork] of the demo flavor and the tests: nothing runs, every call is
/// recorded.
library;

import 'package:finance_tracker/core/platform/background_work.dart';

/// One call [FakeBackgroundWork] recorded: [every] is a schedule's period or a delayed
/// run's delay.
typedef BackgroundWorkCall = ({String method, Duration? every});

/// Background work without a platform.
final class FakeBackgroundWork implements BackgroundWork {
  /// Every call, in order: `schedule` (with its period), `runNow`, `runLater` (with its
  /// delay), `cancel`.
  final List<BackgroundWorkCall> calls = [];

  /// The constraints the last schedule was given.
  BackgroundConstraints? constraints;

  bool _scheduled = false;

  /// Whether the periodic sync is scheduled.
  bool get scheduled => _scheduled;

  @override
  Future<void> schedulePeriodicSync({
    required Duration every,
    required BackgroundConstraints constraints,
  }) async {
    calls.add((method: 'schedule', every: every));
    this.constraints = constraints;
    _scheduled = true;
  }

  @override
  Future<void> runSyncNow() async => calls.add((method: 'runNow', every: null));

  @override
  Future<void> runSyncLater(Duration delay) async =>
      calls.add((method: 'runLater', every: delay));

  @override
  Future<void> cancelAll() async {
    calls.add((method: 'cancel', every: null));
    _scheduled = false;
  }

  @override
  Future<BackgroundWorkState> periodicState() async =>
      _scheduled ? BackgroundWorkState.scheduled : BackgroundWorkState.none;
}
