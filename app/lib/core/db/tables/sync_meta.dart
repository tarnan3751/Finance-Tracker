/// The `sync_meta` table: this device's sync state (`docs/reference/sync-app.md`).
library;

import 'package:drift/drift.dart';

/// One fact: `pull_cursor`, `last_clock`, `device_id`, `last_sync_at`, `last_report`, and
/// the Plaid pull's `plaid_transactions_since`, `plaid_accounts_pulled_at`,
/// `plaid_items_pulled_at`, `plaid_pulled_at` (schema 3).
@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// The keys of `sync_meta`.
abstract final class SyncMetaKeys {
  /// The relay `seq` pulled up to.
  static const String pullCursor = 'pull_cursor';

  /// The persisted clock state, packed.
  static const String lastClock = 'last_clock';

  /// The clock's node: a provisional `local-<uuid>` until the server's device id replaces
  /// it.
  static const String deviceId = 'device_id';

  /// When the last session finished, epoch milliseconds UTC.
  static const String lastSyncAt = 'last_sync_at';

  /// The last session's report as JSON: counts and rejections, no payloads.
  static const String lastReport = 'last_report';

  /// The Plaid pull's transactions cursor: the server's `sync_version` pulled up to.
  static const String plaidTransactionsSince = 'plaid_transactions_since';

  /// When the Plaid pull last applied the linked accounts, epoch milliseconds UTC.
  static const String plaidAccountsPulledAt = 'plaid_accounts_pulled_at';

  /// When the Plaid pull last applied the Items, epoch milliseconds UTC.
  static const String plaidItemsPulledAt = 'plaid_items_pulled_at';

  /// When the last whole Plaid pull finished, epoch milliseconds UTC.
  static const String plaidPulledAt = 'plaid_pulled_at';
}
