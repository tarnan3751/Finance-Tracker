/// What the sync status shows (`docs/reference/sync-app.md`, **The controller**): the
/// controller's state, the summary of a session it keeps, and how the Plaid pull after
/// it went. No payloads, ever. Pure
/// Dart, no Flutter import.
library;

import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:sync_engine/sync_engine.dart';

/// Where sync stands on this device.
enum SyncPhase {
  /// This build's data does not sync: the demo flavor, or in-memory repositories.
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
    required this.clamped,
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
    clamped: report.clamped,
  );

  /// Reads [toJson]'s form; a summary kept before `clamped` existed (with the retired
  /// `pull_blocked`) reads as no clamp.
  factory SyncSummary.fromJson(Map<String, Object?> json) => SyncSummary(
    pushed: json['pushed']! as int,
    pulled: json['pulled']! as int,
    applied: json['applied']! as int,
    rejectedForGood: json['rejected_for_good']! as int,
    clockDrift: json['clock_drift']! as int,
    clamped: json['clamped'] as int? ?? 0,
  );

  /// Entries the relay accepted.
  final int pushed;

  /// Entries pulled from other devices.
  final int pulled;

  /// Records the pulled entries changed.
  final int applied;

  /// Entries the relay refused for good (`invalid`, `conflicting_duplicate`).
  final int rejectedForGood;

  /// Entries refused because this device's clock is more than the bound ahead of the
  /// server's; they stay queued and are retried.
  final int clockDrift;

  /// Pulled entries more than the bound ahead of this device's clock, whose time the
  /// clock did not adopt (`SyncReport.clamped`): this device's clock is behind.
  final int clamped;

  /// Whether this device's clock is ahead, so some of its changes wait to sync.
  bool get clockAhead => clockDrift > 0;

  /// Whether this device's clock is behind, so changes made here may be overridden.
  bool get clockBehind => clamped > 0;

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'pushed': pushed,
    'pulled': pulled,
    'applied': applied,
    'rejected_for_good': rejectedForGood,
    'clock_drift': clockDrift,
    'clamped': clamped,
  };

  @override
  bool operator ==(Object other) =>
      other is SyncSummary &&
      other.pushed == pushed &&
      other.pulled == pulled &&
      other.applied == applied &&
      other.rejectedForGood == rejectedForGood &&
      other.clockDrift == clockDrift &&
      other.clamped == clamped;

  @override
  int get hashCode => Object.hash(
    pushed,
    pulled,
    applied,
    rejectedForGood,
    clockDrift,
    clamped,
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
    this.plaidPulledAt,
    this.plaidFailure,
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

  /// When the last whole Plaid pull finished, UTC; null before the first.
  final DateTime? plaidPulledAt;

  /// Why the last Plaid pull failed, or null when it did not.
  final SyncFailure? plaidFailure;

  /// A copy with the given fields replaced; [failure] is replaced even when null, and
  /// [plaidFailure] whenever it is given, null included.
  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSyncAt,
    SyncSummary? lastSummary,
    required SyncFailure? failure,
    SyncLedger? ledger,
    DateTime? plaidPulledAt,
    Object? plaidFailure = _unchanged,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastSummary: lastSummary ?? this.lastSummary,
    failure: failure,
    ledger: ledger ?? this.ledger,
    plaidPulledAt: plaidPulledAt ?? this.plaidPulledAt,
    plaidFailure: identical(plaidFailure, _unchanged)
        ? this.plaidFailure
        : plaidFailure as SyncFailure?,
  );

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.phase == phase &&
      other.lastSyncAt == lastSyncAt &&
      other.lastSummary == lastSummary &&
      other.failure == failure &&
      other.ledger == ledger &&
      other.plaidPulledAt == plaidPulledAt &&
      other.plaidFailure == plaidFailure;

  @override
  int get hashCode => Object.hash(
    phase,
    lastSyncAt,
    lastSummary,
    failure,
    ledger,
    plaidPulledAt,
    plaidFailure,
  );

  @override
  String toString() =>
      'SyncStatus(${phase.name}, last $lastSyncAt, failure $failure, $ledger, '
      'plaid $plaidPulledAt $plaidFailure)';
}

const Object _unchanged = Object();
