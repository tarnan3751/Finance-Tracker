/// The schema and its migrations (`docs/reference/server.md`, **Storage**).
///
/// [migrations] is append-only: entry `i` takes the schema from version `i` to `i + 1`, and
/// `schema_migrations` records each version applied. Every row a user owns reaches `users`
/// through an `ON DELETE CASCADE` chain, so deleting the user deletes everything. Instants
/// are INTEGER milliseconds UTC, dates ISO TEXT, amounts `*_minor` INTEGER beside a
/// currency code, and `Decimal` values (prices, quantities) TEXT. Every row of Plaid data
/// carries the `source` its client stamped (`demo` from the fake client).
library;

import 'package:sqlite3/sqlite3.dart';

/// A database whose schema is newer than this server knows.
final class SchemaTooNewException implements Exception {
  /// The database is at [version]; the server knows [known].
  const SchemaTooNewException(this.version, this.known);

  /// The database's schema version.
  final int version;

  /// The newest version this server knows.
  final int known;

  @override
  String toString() =>
      'SchemaTooNewException: the database is at schema $version, this server knows $known';
}

/// The migrations, oldest first.
const List<String> migrations = [_v1, _v2, _v3, _v4, _v5];

/// Applies every migration [db] has not yet applied, each in its own transaction. A rerun
/// applies nothing.
void migrate(Database db) {
  db.execute(
    'CREATE TABLE IF NOT EXISTS schema_migrations ('
    'version INTEGER PRIMARY KEY, applied_at INTEGER NOT NULL)',
  );
  final current =
      db
              .select(
                'SELECT COALESCE(MAX(version), 0) AS v FROM schema_migrations',
              )
              .first['v']
          as int;
  if (current > migrations.length) {
    throw SchemaTooNewException(current, migrations.length);
  }
  for (var version = current + 1; version <= migrations.length; version++) {
    db.execute('BEGIN IMMEDIATE');
    try {
      db.execute(migrations[version - 1]);
      db.execute(
        'INSERT INTO schema_migrations (version, applied_at) VALUES (?, ?)',
        [version, DateTime.now().millisecondsSinceEpoch],
      );
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}

const _v1 = '''
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  display_name TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE TABLE devices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  last_seen_at INTEGER NOT NULL,
  last_sync_at INTEGER
);
CREATE INDEX devices_by_user ON devices (user_id);

CREATE TABLE refresh_tokens (
  id TEXT PRIMARY KEY,
  device_id TEXT NOT NULL REFERENCES devices (id) ON DELETE CASCADE,
  token_hash BLOB NOT NULL UNIQUE,
  family_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  rotated_from TEXT,
  revoked_at INTEGER
);
CREATE INDEX refresh_tokens_by_device ON refresh_tokens (device_id);
CREATE INDEX refresh_tokens_by_family ON refresh_tokens (family_id);

CREATE TABLE items (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  plaid_item_id TEXT NOT NULL UNIQUE,
  institution_id TEXT NOT NULL,
  institution_name TEXT NOT NULL,
  products TEXT NOT NULL,
  access_token_ciphertext BLOB NOT NULL,
  access_token_nonce BLOB NOT NULL,
  status TEXT NOT NULL,
  cursor TEXT,
  run_start_cursor TEXT,
  last_successful_sync_at INTEGER,
  created_at INTEGER NOT NULL,
  plaid_removed_at INTEGER
);
CREATE INDEX items_by_user ON items (user_id);

CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES items (id) ON DELETE CASCADE,
  plaid_account_id TEXT NOT NULL,
  type TEXT NOT NULL,
  subtype TEXT,
  name TEXT NOT NULL,
  official_name TEXT,
  mask TEXT,
  currency_code TEXT NOT NULL,
  current_balance_minor INTEGER,
  available_balance_minor INTEGER,
  credit_limit_minor INTEGER,
  balances_as_of INTEGER,
  display_order INTEGER NOT NULL,
  source TEXT NOT NULL,
  UNIQUE (item_id, plaid_account_id)
);
CREATE INDEX accounts_by_user ON accounts (user_id);

CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  item_id TEXT NOT NULL,
  account_id TEXT NOT NULL,
  plaid_transaction_id TEXT NOT NULL,
  amount_minor INTEGER NOT NULL,
  currency TEXT NOT NULL,
  date TEXT NOT NULL,
  authorized_date TEXT,
  pending INTEGER NOT NULL,
  pending_transaction_id TEXT,
  name TEXT NOT NULL,
  merchant_name TEXT,
  merchant_logo_url TEXT,
  plaid_primary_category TEXT,
  plaid_detailed_category TEXT,
  source TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  sync_version INTEGER NOT NULL,
  UNIQUE (item_id, plaid_transaction_id)
);
CREATE INDEX transactions_by_version ON transactions (user_id, sync_version);

CREATE TABLE recurring_streams (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES items (id) ON DELETE CASCADE,
  plaid_stream_id TEXT NOT NULL,
  account_id TEXT NOT NULL,
  merchant_name TEXT NOT NULL,
  cadence TEXT NOT NULL,
  average_amount_minor INTEGER NOT NULL,
  currency TEXT NOT NULL,
  last_date TEXT,
  next_date TEXT,
  status TEXT NOT NULL,
  is_subscription INTEGER NOT NULL,
  source TEXT NOT NULL,
  UNIQUE (item_id, plaid_stream_id)
);

CREATE TABLE securities (
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES items (id) ON DELETE CASCADE,
  security_id TEXT NOT NULL,
  name TEXT,
  ticker_symbol TEXT,
  type TEXT,
  is_cash_equivalent INTEGER,
  close_price TEXT,
  close_price_as_of TEXT,
  currency_code TEXT NOT NULL,
  source TEXT NOT NULL,
  PRIMARY KEY (item_id, security_id)
);

CREATE TABLE holdings (
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES items (id) ON DELETE CASCADE,
  account_id TEXT NOT NULL,
  security_id TEXT NOT NULL,
  quantity TEXT NOT NULL,
  institution_price TEXT NOT NULL,
  institution_price_as_of TEXT,
  institution_value_minor INTEGER NOT NULL,
  cost_basis_minor INTEGER,
  currency_code TEXT NOT NULL,
  source TEXT NOT NULL,
  PRIMARY KEY (item_id, account_id, security_id)
);

CREATE TABLE investment_transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  item_id TEXT NOT NULL,
  account_id TEXT NOT NULL,
  plaid_investment_transaction_id TEXT NOT NULL,
  security_id TEXT,
  date TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  subtype TEXT,
  quantity TEXT NOT NULL,
  price TEXT NOT NULL,
  amount_minor INTEGER NOT NULL,
  fees_minor INTEGER,
  currency TEXT NOT NULL,
  source TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  sync_version INTEGER NOT NULL,
  UNIQUE (item_id, plaid_investment_transaction_id)
);
CREATE INDEX investment_transactions_by_version
  ON investment_transactions (user_id, sync_version);

CREATE TABLE liabilities (
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES items (id) ON DELETE CASCADE,
  account_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  payload TEXT NOT NULL,
  source TEXT NOT NULL,
  PRIMARY KEY (account_id, kind)
);

CREATE TABLE change_log (
  seq INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  hlc TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  payload TEXT NOT NULL,
  received_at INTEGER NOT NULL,
  UNIQUE (user_id, device_id, hlc)
);
CREATE INDEX change_log_by_user ON change_log (user_id, seq);

CREATE TABLE user_versions (
  user_id TEXT PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
  version INTEGER NOT NULL
);
''';

/// v2: an Item's Plaid error code, its institution's cached logo (PNG bytes) and ARGB
/// colour, and the `removed` status (an Item unlinked with its history kept, which keeps
/// `plaid_removed_at` and stays visible).
const _v2 = '''
ALTER TABLE items ADD COLUMN error_code TEXT;
ALTER TABLE items ADD COLUMN institution_logo BLOB;
ALTER TABLE items ADD COLUMN institution_primary_color INTEGER;
''';

/// v3: when an Item's investment transactions were last fetched, so the next fetch asks
/// only for the days since (with an overlap) instead of 730 days every run.
const _v3 = '''
ALTER TABLE items ADD COLUMN investments_synced_at INTEGER;
''';

/// v4: each recurring stream's members, Plaid's `transaction_ids` as a JSON array of
/// Plaid's ids; `/recurring` serves them as the server's own transaction ids.
const _v4 = '''
ALTER TABLE recurring_streams ADD COLUMN plaid_transaction_ids TEXT NOT NULL DEFAULT '[]';
''';

/// v5: who stored each receipt photo (`PUT /receipts/{sha256}`): one row per user and
/// hash; the bytes are a file per hash under the receipts directory, shared by its
/// owners.
const _v5 = '''
CREATE TABLE receipts (
  user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  sha256 TEXT NOT NULL,
  size INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, sha256)
);
CREATE INDEX receipts_by_hash ON receipts (sha256);
''';
