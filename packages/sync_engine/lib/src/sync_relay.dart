/// The server side of sync as the engine sees it (`docs/reference/sync.md`, **The
/// relay**).
library;

import 'package:meta/meta.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/src/unknown_type.dart';

/// The relay every device pushes to and pulls from: the dev server's `/sync` endpoints
/// (lane 2d) or [InMemorySyncRelay].
///
/// It stores every accepted entry once, unique by device id and clock, under a
/// monotonically increasing `seq`, and serves them in `seq` order. A device's pull cursor
/// is a `seq`, never a clock: device clocks do not order the stream. A resent entry is
/// accepted again without a new `seq`. A pull never returns the pulling device's own
/// entries, and its cursor still advances past them.
abstract interface class SyncRelay {
  /// Offers [entries]; each is accepted or rejected.
  Future<PushResult> push(List<ChangeLogEntry> entries);

  /// Up to [limit] entries with a `seq` greater than [since] pushed by devices other than
  /// [deviceId], in `seq` order.
  ///
  /// Throws [SyncCursorInvalidException] when [since] is past the relay's last `seq`.
  Future<PullPage> pull({
    required int since,
    int limit = 200,
    required String deviceId,
  });
}

/// A pull cursor past the end of the relay's log: the relay was reset (a wiped dev
/// server) after the device last pulled. The dev server answers it as
/// `409 sync_cursor_invalid`. The session lets it propagate; the host catches it, calls
/// `SyncStore.savePullCursor(0)` and runs the session again, which is safe because merge
/// is idempotent.
final class SyncCursorInvalidException implements Exception {
  /// The exception for a pull from [since] when the relay's last `seq` is [lastSeq].
  const SyncCursorInvalidException(this.since, this.lastSeq);

  /// The cursor the device pulled from.
  final int since;

  /// The relay's last `seq` (0 when it holds nothing).
  final int lastSeq;

  @override
  String toString() =>
      "SyncCursorInvalidException: cursor $since is past the relay's last seq $lastSeq";
}

/// Why the relay refused an entry.
enum PushRejectionReason {
  /// The entry's wall time is too far ahead of the relay's clock; it is retried later.
  clockDrift,

  /// The entry is malformed: its clock's node is not its device, its payload is empty, or
  /// a delete carries no `deleted_at` instant.
  invalid,

  /// The relay already holds another payload under this device and clock.
  conflictingDuplicate,
}

/// One refused entry.
@immutable
final class PushRejection {
  /// A rejection of the entry stamped [hlc].
  const PushRejection(this.hlc, this.reason, this.message);

  /// The refused entry's clock.
  final Hlc hlc;

  /// Why.
  final PushRejectionReason reason;

  /// A description for logs.
  final String message;

  @override
  String toString() => 'PushRejection($hlc, ${reason.name}: $message)';
}

/// The relay's answer to a push.
@immutable
final class PushResult {
  /// A result.
  const PushResult({required this.accepted, required this.rejected});

  /// The clocks of the entries stored (or already held).
  final List<Hlc> accepted;

  /// The entries refused.
  final List<PushRejection> rejected;
}

/// One page of a pull.
@immutable
final class PullPage {
  /// A page.
  const PullPage({
    required this.entries,
    this.unknownTypes = const [],
    required this.nextSince,
    required this.hasMore,
  });

  /// The entries, in `seq` order.
  final List<ChangeLogEntry> entries;

  /// The page's entries of types this build does not know, kept apart from [entries]
  /// (merge is order-free, so `seq` order across the two lists does not matter).
  final List<UnknownTypeEntry> unknownTypes;

  /// The cursor for the next pull: the position just before the next entry the caller
  /// will receive. It can lie past the caller's own entries, which are never returned:
  /// while [hasMore], it is just before the next entry from another device; otherwise it
  /// is the relay's last `seq`; and it is the request's `since` when the relay holds
  /// nothing after it. The server relay (lane 2d) follows the same rule.
  final int nextSince;

  /// Whether entries for this device remain after [nextSince].
  final bool hasMore;
}
