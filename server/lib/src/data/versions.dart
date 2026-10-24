/// The per-user change counter behind `sync_version` (`docs/reference/server.md`, **Data
/// endpoints**).
///
/// Every insert, change or tombstone of a transaction or an investment transaction takes
/// the next value inside its own write transaction, so `GET /transactions?since=` and
/// `GET /investments/transactions?since=` return exactly the rows written after a page.
library;

import 'package:finance_tracker_server/src/db/database.dart';

/// The next version for [userId].
int nextVersion(Tx tx, String userId) =>
    tx.select(
          'INSERT INTO user_versions (user_id, version) VALUES (?, 1) '
          'ON CONFLICT (user_id) DO UPDATE SET version = version + 1 '
          'RETURNING version',
          [userId],
        ).first['version']
        as int;

/// The last version handed out for [userId], 0 before the first.
int currentVersion(Tx tx, String userId) =>
    tx.first('SELECT version FROM user_versions WHERE user_id = ?', [
          userId,
        ])?['version']
        as int? ??
    0;
