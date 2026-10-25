/// The background poll of every Item (`docs/reference/server.md`, **The poll scheduler**;
/// `PLAN.md` §6.5).
///
/// Every `PLAID_POLL_INTERVAL_SECONDS` (180 by default, at least 60, `0` for none) after
/// the previous tick ended, a tick runs `ItemService.sync` as a background run (it retries
/// `NOT_READY`) for every Item that is not removed at Plaid, not `removed`, not
/// `login_required` and whose user still exists: one Item at a time, [PollScheduler.stagger]
/// apart, skipping an Item whose run (a request's, a webhook's) is already in flight. Then
/// it refreshes institution metadata older than a day. An Item's failure is counted and the
/// tick goes on; a failure outside an Item (the database) is logged and the loop lives on.
/// Each tick logs one `poll_completed` line. One sync per Item every three minutes is far
/// inside Plaid's 50 a minute per Item. [PollScheduler.stop] ends the wait at once and lets
/// the Item in flight finish, up to ten seconds.
library;

import 'dart:async';

import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/logging.dart';
import 'package:finance_tracker_server/src/plaid/item_service.dart';
import 'package:logging/logging.dart';

/// What one tick did.
typedef PollReport = ({
  int items,
  int completed,
  int notReady,
  int skipped,
  int failed,
});

/// The scheduler.
final class PollScheduler {
  /// A scheduler over [items], ticking every [interval]; [delay] waits (instant or
  /// recorded in tests), else a timer that [stop] cancels, so a stopped server exits.
  PollScheduler({
    required this.db,
    required this.items,
    required this.interval,
    this.delay,
    this.stagger = const Duration(seconds: 2),
  });

  /// The database.
  final AppDatabase db;

  /// The Item flows.
  final ItemService items;

  /// The wait between the end of one tick and the start of the next.
  final Duration interval;

  /// The wait between two Items of a tick.
  final Duration stagger;

  /// Waits, when a test gives them.
  final Future<void> Function(Duration)? delay;

  final Logger _log = Logger('plaid');
  final Completer<void> _stopped = Completer();
  Future<void>? _loop;

  /// Starts the loop: a tick, then [interval], until [stop].
  void start() {
    _loop ??= () async {
      while (!_stopped.isCompleted) {
        await tick();
        await _wait(interval);
      }
    }();
  }

  /// Ends the loop: the wait ends at once, the Item in flight may finish for up to ten
  /// seconds.
  Future<void> stop() async {
    if (!_stopped.isCompleted) _stopped.complete();
    await _loop?.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  Future<void> _wait(Duration wait) {
    if (delay case final delay?) {
      return Future.any([delay(wait), _stopped.future]);
    }
    final elapsed = Completer<void>();
    final timer = Timer(wait, elapsed.complete);
    return Future.any([elapsed.future, _stopped.future])
        .whenComplete(timer.cancel);
  }

  /// One pass over every Item the poll may sync.
  Future<PollReport> tick() async {
    final watch = Stopwatch()..start();
    var completed = 0, notReady = 0, skipped = 0, failed = 0;
    List<({String id, String userId})> due;
    try {
      due = await db.read(
        (tx) => [
          for (final r in tx.select(
            'SELECT i.id, i.user_id FROM items i JOIN users u ON u.id = i.user_id '
            'WHERE i.plaid_removed_at IS NULL '
            "AND i.status NOT IN ('login_required', 'removed') "
            'ORDER BY i.created_at, i.id',
          ))
            (id: r['id']! as String, userId: r['user_id']! as String),
        ],
      );
    } on Object catch (e) {
      _log.severe(LogEvent('poll_failed', errorFields(e)));
      return (items: 0, completed: 0, notReady: 0, skipped: 0, failed: 0);
    }
    for (final (i, item) in due.indexed) {
      if (_stopped.isCompleted) break;
      if (i > 0) await _wait(stagger);
      if (_stopped.isCompleted) break;
      if (items.isSyncing(item.id)) {
        skipped++;
        continue;
      }
      try {
        final run = await items.sync(item.userId, item.id, retryNotReady: true);
        if (run['status'] == 'completed') {
          completed++;
        } else {
          notReady++;
        }
      } on Object catch (e) {
        failed++;
        _log.warning(
          LogEvent('poll_item_failed', {
            'item_id': item.id,
            ...errorFields(e),
            if (e is ProblemException) 'code': e.code.wire,
          }),
        );
      }
    }
    try {
      if (!_stopped.isCompleted) await items.refreshStaleInstitutions();
    } on Object catch (e) {
      _log.warning(LogEvent('poll_failed', errorFields(e)));
    }
    final report = (
      items: due.length,
      completed: completed,
      notReady: notReady,
      skipped: skipped,
      failed: failed,
    );
    _log.info(
      LogEvent('poll_completed', {
        'items': report.items,
        'completed': completed,
        'not_ready': notReady,
        'skipped': skipped,
        'failed': failed,
        'duration_ms': watch.elapsedMilliseconds,
      }),
    );
    return report;
  }
}
