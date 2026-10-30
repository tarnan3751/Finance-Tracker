/// The sync relay over SQLite: `POST /sync/push` and `GET /sync/pull`
/// (`docs/reference/server.md`, **The sync relay**; `docs/reference/sync.md`, **The
/// relay**).
///
/// The rules are `InMemorySyncRelay`'s, so the engine's sessions converge through it
/// exactly as through the reference (the server's convergence test runs both). Each pushed
/// entry is checked in order:
/// 1. `invalid`: its `device_id` is not the caller's device, its clock's node is not its
///    `device_id`, its payload is empty, a delete has no `deleted_at` instant, or (defence
///    in depth: Plaid data never syncs through the change log) its payload says
///    `source: plaid`;
/// 2. `clock_drift`: its wall time is more than [Hlc.maxDrift] (the clock bound the
///    devices share) ahead of the server's clock;
/// 3. a resend under a stored `(user, device, hlc)` is accepted again without a new `seq`
///    when it is identical, and rejected `conflicting_duplicate` otherwise;
/// 4. otherwise it is stored under the next `seq`.
///
/// `seq` is global but every rule reads it per user: a pull returns the user's entries
/// after `since` from devices other than the caller's, and `next_since` is the position
/// just before the next entry the caller will receive, or the user's last `seq`.
library;

import 'dart:convert';

import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:shared_models/shared_models.dart';

/// The contract's `PushRejectionCode`.
enum RejectionCode {
  clockDrift('clock_drift'),
  invalid('invalid'),
  conflictingDuplicate('conflicting_duplicate');

  const RejectionCode(this.wire);

  /// The snake_case value on the wire.
  final String wire;
}

/// One pushed entry, as read from the request.
typedef PushedEntry = ({
  String entityType,
  String entityId,
  String operation,
  Map<String, Object?> payload,
  String hlc,
  String deviceId,
});

/// Whether two decoded JSON values are equal: maps by key whatever their order, lists in
/// order, numbers by value (so `1` equals `1.0`), as the engine's `jsonEquality` compares
/// them.
bool jsonEquals(Object? a, Object? b) => switch ((a, b)) {
  (final Map<String, Object?> x, final Map<String, Object?> y) =>
    x.length == y.length &&
        x.keys.every((k) => y.containsKey(k) && jsonEquals(x[k], y[k])),
  (final List<Object?> x, final List<Object?> y) =>
    x.length == y.length &&
        [for (var i = 0; i < x.length; i++) i]
            .every((i) => jsonEquals(x[i], y[i])),
  (final Map<String, Object?> _, _) || (final List<Object?> _, _) => false,
  _ => a == b,
};

/// The relay.
final class ChangeLogRelay {
  /// The relay over [db]; [now] is the server's clock.
  ChangeLogRelay({required this.db, required this.now});

  /// The database.
  final AppDatabase db;

  /// The server's clock.
  final DateTime Function() now;

  /// Stores [entries] pushed by [deviceId] of [userId]; the contract's `PushResult`.
  Future<Map<String, Object?>> push(
    String userId,
    String deviceId,
    List<PushedEntry> entries,
  ) => db.transaction((tx) async {
    final nowMillis = now().millisecondsSinceEpoch;
    final accepted = <String>[];
    final rejected = <Map<String, Object?>>[];
    void reject(PushedEntry e, RejectionCode code, String reason) =>
        rejected.add({'hlc': e.hlc, 'code': code.wire, 'reason': reason});

    for (final e in entries) {
      final hlc = Hlc.parse(e.hlc);
      final problem = _invalid(e, hlc, deviceId);
      if (problem != null) {
        reject(e, RejectionCode.invalid, problem);
        continue;
      }
      final ahead = hlc.wallMillis - nowMillis;
      if (ahead > Hlc.maxDrift.inMilliseconds) {
        reject(e, RejectionCode.clockDrift, '$ahead ms ahead of the server');
        continue;
      }
      final stored = tx.first(
        'SELECT seq, entity_type, entity_id, operation, payload FROM change_log '
        'WHERE user_id = ? AND device_id = ? AND hlc = ?',
        [userId, e.deviceId, e.hlc],
      );
      if (stored == null) {
        tx.execute(
          'INSERT INTO change_log (user_id, device_id, hlc, entity_type, entity_id, '
          'operation, payload, received_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            userId,
            e.deviceId,
            e.hlc,
            e.entityType,
            e.entityId,
            e.operation,
            jsonEncode(e.payload),
            nowMillis,
          ],
        );
      } else if (stored['entity_type'] != e.entityType ||
          stored['entity_id'] != e.entityId ||
          stored['operation'] != e.operation ||
          !jsonEquals(jsonDecode(stored['payload'] as String), e.payload)) {
        reject(
          e,
          RejectionCode.conflictingDuplicate,
          'another payload is stored as seq ${stored['seq']}',
        );
        continue;
      }
      accepted.add(e.hlc);
    }
    _markSynced(tx, deviceId, nowMillis);
    return {'accepted': accepted, 'rejected': rejected};
  });

  /// Up to [limit] entries after [since] from [userId]'s devices other than [deviceId];
  /// the contract's `PullPage`. A [since] past the user's last `seq` is 409
  /// `sync_cursor_invalid`.
  Future<Map<String, Object?>> pull(
    String userId,
    String deviceId, {
    required int since,
    required int limit,
  }) => db.transaction((tx) async {
    final last =
        tx.first(
              'SELECT COALESCE(MAX(seq), 0) AS last FROM change_log WHERE user_id = ?',
              [userId],
            )!['last']
            as int;
    if (since > last) {
      throw ProblemException(
        409,
        ProblemCode.syncCursorInvalid,
        detail:
            'since $since is past the last seq $last; reset the cursor to 0 and pull '
            'again',
      );
    }
    final rows = tx.select(
      'SELECT * FROM change_log WHERE user_id = ? AND seq > ? AND device_id <> ? '
      'ORDER BY seq LIMIT ?',
      [userId, since, deviceId, limit + 1],
    );
    final hasMore = rows.length > limit;
    final page = hasMore ? rows.take(limit) : rows;
    _markSynced(tx, deviceId, now().millisecondsSinceEpoch);
    return {
      'entries': [
        for (final r in page)
          {
            'entity_type': r['entity_type'],
            'entity_id': r['entity_id'],
            'operation': r['operation'],
            'payload': jsonDecode(r['payload'] as String),
            'hlc': r['hlc'],
            'device_id': r['device_id'],
            'seq': r['seq'],
          },
      ],
      'next_since': hasMore ? (rows[limit]['seq'] as int) - 1 : last,
      'has_more': hasMore,
    };
  });

  static String? _invalid(PushedEntry e, Hlc hlc, String callerDeviceId) {
    if (e.deviceId != callerDeviceId) {
      return 'device_id is not the calling device';
    }
    if (hlc.nodeId != e.deviceId) return 'clock node is not the device';
    if (e.payload.isEmpty) return 'empty payload';
    if (e.operation == 'delete') {
      final at = e.payload['deleted_at'];
      if (at is! String) return 'delete without deleted_at';
      try {
        const UtcInstantConverter().fromJson(at);
      } on FormatException {
        return 'deleted_at is not an instant';
      }
    }
    if (e.payload['source'] == 'plaid') {
      return 'Plaid-sourced data does not sync through the change log';
    }
    return null;
  }

  static void _markSynced(Tx tx, String deviceId, int nowMillis) => tx.execute(
    'UPDATE devices SET last_sync_at = ? WHERE id = ?',
    [nowMillis, deviceId],
  );
}
