// The session summary kept in sync_meta: its JSON round trip, a summary kept by an
// earlier build (with the retired `pull_blocked` and no `clamped`) read without error,
// and which clock warning each count raises.
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const SyncSummary summary = SyncSummary(
    pushed: 1,
    pulled: 2,
    applied: 3,
    rejectedForGood: 4,
    clockDrift: 5,
    clamped: 6,
  );

  test('round-trips through its JSON', () {
    expect(SyncSummary.fromJson(summary.toJson()), summary);
    expect(summary.toJson()['clamped'], 6);
  });

  test('reads a summary an earlier build kept as no clamp', () {
    final SyncSummary old = SyncSummary.fromJson(const {
      'pushed': 1,
      'pulled': 2,
      'applied': 3,
      'rejected_for_good': 4,
      'clock_drift': 0,
      'pull_blocked': true,
    });
    expect(old.clamped, 0);
    expect(old.clockAhead, isFalse);
    expect(old.clockBehind, isFalse);
  });

  test(
    'a refusal for drift means the clock is ahead, a clamp that it is behind',
    () {
      expect(summary.clockAhead, isTrue);
      expect(summary.clockBehind, isTrue);
      const SyncSummary quiet = SyncSummary(
        pushed: 0,
        pulled: 0,
        applied: 0,
        rejectedForGood: 0,
        clockDrift: 0,
        clamped: 0,
      );
      expect(quiet.clockAhead, isFalse);
      expect(quiet.clockBehind, isFalse);
    },
  );
}
