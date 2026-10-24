/// What the sync status shows (`docs/reference/sync-app.md`, **The controller**): the
/// controller's state and the summary of a session it keeps. No payloads, ever. Pure
/// Dart, no Flutter import.
library;

import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:sync_engine/sync_engine.dart';

/// Where sync stands on this device.
enum SyncPhase {
  /// The flavor never syncs (demo).
  unavailable,

  /// Nobody is signed in, so there is no server to sync with.
  signedOut,

  /// Signed in, no session running.
  idle,

  /// A session is running.
  running,
}

/// Why the last session failed.
enum SyncFailure {
  /// The server could not be reached.
  offline,

  /// The server answered with an error.
  server,

  /// Anything else; the log names its type.
  other,
}

/// The counts of one session, kept in `sync_meta` as `last_report`.
final class SyncSummary {
  /// A summary.
  const SyncSummary({
    required this.pushed,
    required this.pulled,
    required this.applied,
    required this.rejectedForGood,
    required this.clockDrift,
    required this.pullBlocked,
  });

  /// The summary of [report].
  factory SyncSummary.of(SyncReport report) => SyncSummary(
    pushed: report.pushed,
    pulled: report.pulled,
    applied: report.applied,
    rejectedForGood: report.rejected
        .where((r) => r.reason != PushRejectionReason.clockDrift)
        .length,
    clockDrift: report.rejected
        .where((r) => r.reason == PushRejectionReason.clockDrift)
        .length,
    pullBlocked: report.pullBlockedBy != null,
  );

  /// Reads [toJson]'s form.
  factory SyncSummary.fromJson(Map<String, Object?> json) => SyncSummary(
    pushed: json['pushed']! as int,
    pulled: json['pulled']! as int,
    applied: json['applied']! as int,
    rejectedForGood: json['rejected_for_good']! as int,
    clockDrift: json['clock_drift']! as int,
    pullBlocked: json['pull_blocked']! as bool,
  );

  /// Entries the relay accepted.
  final int pushed;

  /// Entries pulled from other devices.
  final int pulled;

  /// Records the pulled entries changed.
  final int applied;

  /// Entries the relay refused for good (`invalid`, `conflicting_duplicate`).
  final int rejectedForGood;

  /// Entries refused because this device's clock is too far ahead; retried later.
  final int clockDrift;

  /// Whether a pulled entry from a device whose clock is too far ahead held the pull back.
  final bool pullBlocked;

  /// Whether a clock too far ahead, here or on another device, held changes back.
  bool get heldByClockDrift => clockDrift > 0 || pullBlocked;

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'pushed': pushed,
    'pulled': pulled,
    'applied': applied,
    'rejected_for_good': rejectedForGood,
    'clock_drift': clockDrift,
    'pull_blocked': pullBlocked,
  };

  @override
  bool operator ==(Object other) =>
      other is SyncSummary &&
      other.pushed == pushed &&
      other.pulled == pulled &&
      other.applied == applied &&
      other.rejectedForGood == rejectedForGood &&
      other.clockDrift == clockDrift &&
      other.pullBlocked == pullBlocked;

  @override
  int get hashCode => Object.hash(
    pushed,
    pulled,
    applied,
    rejectedForGood,
    clockDrift,
    pullBlocked,
  );
}

/// The sync status of this device.
final class SyncStatus {
  /// A status.
  const SyncStatus({
    required this.phase,
    this.lastSyncAt,
    this.lastSummary,
    this.failure,
    this.ledger,
  });

  /// The status of a flavor that never syncs.
  static const SyncStatus unavailable = SyncStatus(
    phase: SyncPhase.unavailable,
  );

  /// The status while nobody is signed in.
  static const SyncStatus signedOut = SyncStatus(phase: SyncPhase.signedOut);

  /// The phase.
  final SyncPhase phase;

  /// When the last session finished, UTC; null before the first.
  final DateTime? lastSyncAt;

  /// The last finished session's counts.
  final SyncSummary? lastSummary;

  /// Why the last session failed, or null when it did not.
  final SyncFailure? failure;

  /// The outbox and held-record counts, once read.
  final SyncLedger? ledger;

  /// A copy with the given fields replaced; [failure] is replaced even when null.
  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSyncAt,
    SyncSummary? lastSummary,
    required SyncFailure? failure,
    SyncLedger? ledger,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastSummary: lastSummary ?? this.lastSummary,
    failure: failure,
    ledger: ledger ?? this.ledger,
  );

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.phase == phase &&
      other.lastSyncAt == lastSyncAt &&
      other.lastSummary == lastSummary &&
      other.failure == failure &&
      other.ledger == ledger;

  @override
  int get hashCode =>
      Object.hash(phase, lastSyncAt, lastSummary, failure, ledger);

  @override
  String toString() =>
      'SyncStatus(${phase.name}, last $lastSyncAt, failure $failure, $ledger)';
}
