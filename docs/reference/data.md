# Data: the local database and the repositories

The app's encrypted local database, the repositories every screen reads from, the receipt
photos, the demo seed, and the one-time import of the original app's data. Code:
`app/lib/core/db/` (schema, open path, key store, in-memory store, receipt store, demo
seed, importer) and each feature's `domain/`
(interfaces) and `data/` (implementations): `features/accounts/`, `features/transactions/`,
`features/categories/`, `features/rules/`, `features/budgets/`, `features/settings/`, `features/items/`, `features/recurring/`, `features/liabilities/`. Tests: `app/test/contract/` (the contract
suites), `app/test/core/db/`, `app/test/drift/`, `app/integration_test/encrypted_database_test.dart`,
`app/integration_test/transactions_search_test.dart`.
The entities and `Money` are `shared_models` (`core.md`); the providers and startup are
`app-core.md`.

## The database

Drift on SQLite, at schema version 10 (`core/db/app_database.dart`; one file per table under
`core/db/tables/`). `app_database.dart` and the tables import no Flutter, so `drift_dev`
can run them in the Dart VM to dump the schema.

| Table | What |
|---|---|
| `accounts` | One row per account |
| `transactions` | One row per transaction; `hidden` (schema 6, a boolean, default false) is the user's hidden override |
| `transaction_tags` | A transaction's tags, `(transaction_id, position)` primary key, in list order |
| `transaction_splits` | A transaction's splits, `(transaction_id, position)` primary key, in list order |
| `categories` | The system categories and the user's |
| `app_settings` | The app preferences: `key` is the field name, `value` its JSON |
| `app_meta` | Facts about the install: `legacy_import_done`, `install_date`, `fts_definition` (**Full-text search**), `reminders_zone` and `reminders_scheduled_at` (the zone and time the bill reminders were last planned in, `bills.md`), `bill_suggestions_dismissed` (the bill suggestions dismissed on this device, `bills.md`, **Screens**), `forecast_selection` (the forecast's account selection on this device, the JSON of its changes from the default, `forecast.md`) |
| `change_log` | The sync outbox (schema 2): one row per local change-log entry (`sync-app.md`) |
| `record_clocks` | The sync clock of each field of each synced entity, `_create` holding its create's (schema 2) |
| `sync_meta` | The device's sync state: `pull_cursor`, `last_clock`, `device_id`, `last_sync_at`, `last_report` (schema 2); the Plaid pull's `plaid_transactions_since`, `plaid_accounts_pulled_at`, `plaid_items_pulled_at`, `plaid_pulled_at` (`sync-app.md`) |
| `held_records` | Sync records the entity tables cannot hold exactly, whole, with why: `incomplete`, `unrepresentable`, `unknown_fields`, `unsupported_type` (schema 2, `sync-app.md`) |
| `items` | The user's Plaid Items as the server last listed them: institution id, name, logo URL, logo bytes and color, `status` (the `ItemStatus` JSON name), Plaid's `error_code`, `last_successful_sync_at`, `pulled_at` (schema 3; `items.md`) |
| `rules` | The user's rules (schema 4, `rules.md`): `name`, `position`, and the `conditions` and `actions` as JSON lists of the `shared_models` JSON (an amount bound is `Money`'s `{minor_units, currency}`) |
| `budgets` | The user's budgets (schema 5, `budgets.md`): `category_id`, `period`, `period_start_day`, `amount_minor` in `currency`, `rollover`, `start_date` |
| `budget_alerts` | The budget alerts this device has raised, never synced (schema 5, `budgets.md`): `(budget_id, period_start, threshold_bp)` primary key, `raised_at` |
| `dismissed_pairs` | The duplicate pairs the user marked as not duplicates (schema 7, `duplicates.md`): `id_a` and `id_b`, two transaction ids in `BINARY` order (a CHECK), the primary key, and `dismissed_at`; local to the device, never recorded or synced, no foreign key |
| `bills` | The user's bills (schema 10, `bills.md`): `name`, `amount_minor` and `currency` (both or neither), `due_date` (the first), `cadence` (the JSON name, no CHECK), `account_id`, `stream_id`, `liability_account_id`, `reminder_offset_days` (a JSON array), `reminder_minutes` (a CHECK, 0 to 1439), `active`, `autopay`, `paid_occurrences` (a JSON array of ISO dates), the three audit columns |
| `bill_alerts` | The bill notifications this device raised, never synced (schema 10, `bills.md`): `(bill_id, due_date)` primary key, `raised_at` |
| `saved_filters` | The transaction list's saved filters (schema 8, `transactions.md`): `name`, `query_json` (`TransactionFilters.toJson`), `position`, `created_at`, `updated_at`; on this device only, never synced or recorded |
| `recurring_streams` | The recurring streams (schema 9, `recurring.md`): the server's (`plaid`, `demo`) and the detector's (`detected`), each replaced whole, never recorded: `account_id`, `merchant_name`, `cadence` (its JSON name, no CHECK), `average_amount_minor` in `currency`, `last_expected`, `next_expected`, `status`, `is_subscription`, `source`, `transaction_ids` (a JSON array), `pulled_at` |
| `stream_overrides` | The user's choices per stream (schema 9, `recurring.md`): `stream_id` primary key (no foreign key), `muted`, `is_subscription` and `display_name` (null: the stream's own), the three audit columns; synced as the `recurring_stream` record |
| `liabilities` | The linked accounts' liability detail (schema 9, `liabilities.md`): `(account_id, kind)` primary key, every amount a `*_minor` in the row's nullable `currency`, the dates, `is_overdue`, `aprs` (JSON), `interest_rate_bp`, `loan_term`, `payload` (the server's object as JSON), `source` (`plaid` or `demo`), `pulled_at`; server-authoritative, never recorded |

The full-text index (**Full-text search** below) adds a view, two tables and five triggers
that are not part of the Drift schema.

How values are stored (`core/db/converters.dart`):

- **Ids** are TEXT: UUID v4 for user-created records, Plaid's ids later, fixed strings for
  the seed and the system categories, UUID v5 for imported records.
- **`Money`** is never one column. A row with one currency has a `currency` TEXT, and each
  amount is a `<name>_minor` INTEGER in it: an account has `currency` and three nullable
  `current_balance_minor`, `available_balance_minor`, `credit_limit_minor`; a transaction
  `amount_minor` and `currency`; a split `amount_minor` in its transaction's currency.
  `moneyOrNull` puts one together on read and `minorUnitsIn` takes it apart on write,
  throwing `CurrencyMismatchException` for an amount in another currency.
- **`LocalDate`** is TEXT `yyyy-MM-dd`, so text order is date order.
- **Audit instants** (`created_at`, `updated_at`, `deleted_at`, `balances_as_of`) are INTEGER
  epoch milliseconds UTC; writing a non-UTC value or one with microseconds is an error.
  Drift's own `DateTimeColumn` is not used: it stores whole seconds.
- **Enums** are TEXT by name (`textEnum`), never an ordinal. Every enum in schema 1 has
  one-word values, so the name is the JSON name (`test/core/db/app_database_test.dart`
  checks it); an enum with multi-word values needs a converter that writes the JSON name,
  as `items.status` has (`ItemStatusColumnConverter`, with a CHECK over the names).
- **`Uri`** is its TEXT form.

Every entity table (`accounts`, `transactions`, `categories`) has `created_at`,
`updated_at`, `deleted_at` (nullable: deletes are soft, so Phase 2's sync can carry
tombstones) and `sync_version INTEGER NOT NULL DEFAULT 0`; `rules` and `budgets` have the
three audit columns and no `sync_version`, which is the server's version of Plaid data;
`budgets` has CHECKs holding `period` to the `BudgetPeriodKind` names and
`period_start_day` to 1 to 28. `transactions.source` has a CHECK
over the five provenance values and `accounts.type` one over the account types;
`transactions.deleted_with_account` (a boolean, default false) marks the rows an
account's delete removed. Tags and
splits reference their transaction with `ON DELETE CASCADE`; `beforeOpen` turns
`foreign_keys` on. There is no foreign key from `transactions.account_id` to `accounts`:
Phase 2's sync may apply a transaction before its account, so the repositories check that
the account exists. Indexes: `transactions(account_id, date)`,
`transactions(user_category_id)`, `transactions(pending_transaction_id)`,
`transaction_tags(tag)`, `categories(parent_id)`, `rules(position)`,
`budgets(category_id)`, `saved_filters(position)`, `recurring_streams(account_id)`,
`bills(due_date)`.

## Full-text search

`core/db/full_text_search.dart`. `TransactionQuery.text` is matched through an FTS5 index
of each transaction's name, merchant name, notes and tags, when the bundled SQLite has
FTS5, which the `sqlite3` package's SQLite3 Multiple Ciphers build has on the host and on
Android (checked on the harness AVD by `transactions_search_test.dart`).

- **The objects.** `transactions_fts_source`, a view of each transaction's `id`, `name`,
  `merchant_name`, `notes` and its tags joined by spaces in list order
  (`group_concat(tag, ' ' ORDER BY position)`); `transactions_fts_keys(fts_rowid INTEGER
  PRIMARY KEY, transaction_id TEXT NOT NULL UNIQUE)`, each transaction's FTS rowid;
  `transactions_fts`, a standalone FTS5 table (not external content) of the four text
  columns and `transaction_id UNINDEXED`, tokenized `unicode61 remove_diacritics 2`, each
  row at its key's rowid. The index is keyed by the transaction's id through an explicit
  INTEGER PRIMARY KEY, never by the implicit rowid of `transactions`, so `VACUUM`, which
  may renumber implicit rowids, leaves it intact. Soft-deleted rows stay indexed; the
  query filters them as every query does.
- **The triggers**, all AFTER and by id: on `transactions`, insert (adds the key with
  `ON CONFLICT DO NOTHING`, then the row from the view), update of `name`,
  `merchant_name` or `notes`, and delete (removes the FTS row, then the key); on
  `transaction_tags`, insert and delete. Each but the insert deletes the transaction's FTS
  row through its key and inserts it again from the view. A write that rewrites a row's
  tags runs the tag triggers once per tag.
- **At open.** `beforeOpen` checks `sqlite_compileoption_used('ENABLE_FTS5')` and records
  the answer as `AppDatabase.fullTextSearch` (a future, completed at open; it opens the
  database when asked first). With FTS5, `ensureFullTextSearch` creates whatever is
  missing, after dropping the rest, and rebuilds the index (clears the key table and the
  index, refills both from the view) in one transaction: a new database, one upgraded
  from schema 7 with its rows, and one last opened without FTS5 all end up with a full
  index. It does the same when `app_meta.fts_definition` is not `ftsDefinitionVersion`:
  **to change the definition** (a column, a tokenizer option, a trigger), change the
  statements and bump `ftsDefinitionVersion`, and every database built with the old one
  is rebuilt with the new one at its next open. Without FTS5 it drops the triggers a build with FTS5 left, logs it once, and
  leaves the table inert, since writes would otherwise fail with "no such module: fts5";
  the Drift repository then falls back to the LIKE match (**`TransactionQuery`**).
  `AppDatabase(allowFullTextSearch: false)` takes that path in tests.
- **The query.** `transactions.id IN (SELECT transaction_id FROM transactions_fts WHERE
  transactions_fts MATCH ?)`, the MATCH string bound: each whitespace-separated term
  quoted as an FTS5 string (`"` doubled, U+0000, which would end the string, as a space,
  a separator either way) and marked as a prefix (`"term"*`), the terms
  ANDed. No user text reaches the FTS5 query parser, so `NEAR`, `OR`, `-`, `(`, `*` and
  column filters are words or separators like any other. A term with no token character
  makes the condition false. Order stays the list's (`date DESC, ...`); there is no
  relevance ranking.
- **Not in the Drift schema.** The objects are made with SQL because they are
  conditional, so the schema dumps do not describe them. `migration_test.dart` pins them:
  after a schema 7 upgrade and on a new database, `sqlite_master` holds exactly the
  statements in `ftsCreateStatements`, and the index finds the upgraded rows.
  `test/helpers/fts_oracle.dart` (`expectIndexMatchesView`) compares the view, the key
  table and the index both ways, every column, plus FTS5's `integrity-check`;
  `test/core/db/full_text_search_test.dart` runs it after every write path (edits, tags,
  batches, deletes and restores, the account cascade, the Plaid apply path, a merged sync
  record, a row removed outright, `VACUUM`) and prints which path the host took
  (`full-text search: FTS5 (SQLite x.y.z)`), failing when it is not FTS5.

**In memory** the same matching runs in Dart (`features/transactions/domain/search_text.dart`):
a term is a phrase of its tokens, the last a prefix, within one field (the tags joined by
spaces). The tokenizer's table, `unicode61_table.dart` (the separator ranges and the
folds), is generated from the bundled SQLite's own tokenizer by
`dart run tool/generate_unicode61_table.dart` (in `app/`), so case and diacritics fold
exactly as FTS5 folds them (Latin diacritics only: Greek tonos, `ß` and ligatures stay).
`search_text_test.dart` compares the two on every code point; when the sqlite3 package
brings a SQLite whose tokenizer differs, that test fails, and rerunning the generator is
the fix. The transaction contract suite checks the Drift implementation against the Dart
reference over the Plaid Sandbox names with accented and non-Latin text.

## Encryption and the key

The native library is SQLite3 Multiple Ciphers (default cipher ChaCha20-Poly1305), from the
`sqlite3` package's build hook, selected in the **workspace root** `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

The root define reaches both the host test library and the Android build (checked:
`PRAGMA cipher` answers `chacha20` on the host and on the harness AVD). The hook downloads
hash-checked prebuilt binaries from the `sqlite3` package's GitHub release at build time and
caches them under `.dart_tool/hooks_runner/`, so a first build needs the network.
`sqlite3_flutter_libs`, `sqlcipher_flutter_libs` and `drift_flutter` are not used
(`PLAN.md` §12); a change of hook settings may need one `flutter clean`.

**Opening** (`core/db/open_database.dart`). `openAppDatabase(config, keyStore)` returns an
`AppDatabase` over a `LazyDatabase`; nothing happens until the first query, and
`bootstrap` opens it at startup with `verifyOpen()`. On open:

1. the file is `finance_tracker.db` under `getApplicationSupportDirectory()`; on Android
   `sqlite3.tempDirectory` is set to the app's temporary directory (process-wide);
2. the key: if the store has none and the file exists, `DatabaseKeyLostException` (a key is
   never recreated over existing data); if it has none and there is no file, a new key is
   created and stored before the file is; a stored key that is not 64 lowercase hex digits
   is also `DatabaseKeyLostException`;
3. the open sequence (`databaseSetup`), run once on a short-lived connection on the calling
   isolate, so its exceptions reach the caller as themselves, then as the `setup` of
   `NativeDatabase.createInBackground`:
   - `PRAGMA cipher;` must return a row, else `EncryptionUnavailableException`;
   - `PRAGMA key = "x'<64 hex>'"`: a raw 32-byte key, no key derivation;
   - `SELECT count(*) FROM sqlite_master;`: "file is not a database" (result code 26) is
     `DatabaseKeyMismatchException`.
4. `beforeOpen` turns foreign keys on and, in dev, logs the result of `PRAGMA cipher;` and
   of `SELECT sqlite3mc_version();`, run as two statements: sqlite3mc has no
   `pragma_cipher` table-valued function, and SQLCipher's `cipher_version` pragma does not
   exist in it. This dev-only path has its own host test and integration test.

**The key** (`core/db/database_key_store.dart`): `DatabaseKeyStore { read(); create(); }`.
`SecureDatabaseKeyStore` keeps 32 bytes from `Random.secure()`, hex-encoded, in
`flutter_secure_storage` under `db_key_v1`, with `AndroidOptions(resetOnError: false,
storageNamespace: 'finance_tracker')`: the default `resetOnError: true` would delete every
stored value when one fails to decrypt. A read that fails (`PlatformException`) is a
`DatabaseKeyLostException` carrying the cause. `InMemoryDatabaseKeyStore` is for tests.

**When it fails**, for any reason (the three typed failures, a damaged file's
`SqliteException`, the `onUpgrade` error after a downgrade), `bootstrap` logs the
exception's type only and shows `DatabaseErrorApp`, a plain localized screen, instead of
the app; nothing is deleted. `databaseFailureOf` picks its message: one each for no
cipher, a wrong key and a lost key, and a generic one for the rest. Phase 7's restore flow
handles a lost key. Closing a database whose open failed rethrows the failure (Drift's
`LazyDatabase.close`), so `bootstrap` leaves the container open on that path, and
`databaseProvider`'s dispose ignores the three typed failures (`isDatabaseOpenFailure`).

**Debugging.** `--dart-define=FT_PLAIN_DB=true` opens an unencrypted
`finance_tracker.plain.db` instead, in the dev flavor only (other flavors log a warning and
ignore it); the two files never mix. Host tests use `AppDatabase(NativeDatabase.memory())`
for the repositories, and `openDatabaseExecutor(file, keyStore: ...)` on a temporary file
for the open path (`keyStore: null` is the unencrypted path).

## Repositories

Each interface is in its feature's `domain/`, takes and returns `shared_models` entities,
and exposes streams that start with the current value and emit again only when it changes
(`distinct`). No Drift type leaves `data/`.

| Interface | Methods |
|---|---|
| `AccountRepository` | `watchAll()` (visible first, then hidden; by `displayOrder`, then id), `watchById`, `upsert`, `create(account, {openingBalance})`, `delete`, `restore`, `applyPlaid(accounts)`, `watchDerivedBalance(id)`, `watchDerivedBalances()` |
| `TransactionRepository` | `watch(TransactionQuery)`, `watchById`, `upsert`, `upsertAll(batch)`, `delete`, `deleteAll(ids)`, `restore`, `applyPlaid(page)`, `count(TransactionQuery)`, `watchUsage({recentLimit})` |
| `CategoryRepository` | `watchAll()` (by name ignoring ASCII case, then id), `watchById`, `upsert`, `delete`, `ensureSeeded()` |
| `ItemRepository` | `watchAll()` (by institution name ignoring ASCII case, then id), `watchById`, `applyPlaid(items, pulledAt:)`, `applyPlaidItem`, `saveLogo`, `markLoginRequired` |
| `RuleRepository` | `watchAll()` (by `position`, then id), `upsert`, `delete`, `restore`, `reorder(ids)` (`rules.md`) |
| `BudgetRepository` | `watchAll()` (by `categoryId`, then id), `watchById`, `upsert`, `delete`, `restore` (`budgets.md`) |
| `RecurringStreamRepository` | `watchAll()` (each stream with its live override as a `StreamView`, by merchant name ignoring ASCII case, then id), `watchById`, `applyPlaid(streams)`, `replaceDetected(streams)`, `setOverride(id, change)`, `clearOverride(id)` (`recurring.md`) |
| `LiabilityRepository` | `watchAll()` (by account, then kind), `watchByAccount`, `applyPlaid(liabilities)` (`liabilities.md`) |
| `BillRepository` | `watchAll()` (by first due date, then id), `watchById`, `upsert`, `delete`, `restore` (`bills.md`) |
| `SavedFilterRepository` | `watchAll()` (by `position`, then id), `save(name, filters)` (appended), `rename`, `delete` (final: the table is local, nothing is recorded); a blank name is an `ArgumentError` (`transactions.md`) |
| `SettingsRepository` | `watch()`, `read()`, `save()` |

The rules every implementation keeps:

- **Soft delete.** `delete` sets `deleted_at`; every read hides the record and `watchById`
  yields null. Deleting a missing or deleted record does nothing. `restore` is the only way
  back: an `upsert` of a deleted id throws `EntityDeletedException`
  (`core/db/database_exceptions.dart`), because deletes win over edits, as they will in
  sync.
- **Bank data is not deleted on the device.** `delete` of a linked account (one with an
  `itemId`) or of a `plaid` transaction throws `BankDataNotDeletableException`: a linked
  account goes only when its Item is unlinked, a Plaid transaction only when the bank
  removes it (`items.md`), so the Plaid apply paths below meet no local tombstone.
- **The account cascade.** Deleting an account deletes its live transactions and marks
  them (`deleted_with_account`); restoring it restores exactly the marked ones, so one
  deleted on its own stays deleted, even in the same millisecond. Restoring a transaction
  whose account is deleted throws `AccountNotFoundException`.
- **Account creation.** `create(account, openingBalance: transaction)` writes the account
  as `upsert` does and its opening balance transaction as the transaction repository's
  `upsert` does, in one write: Drift runs both in one database transaction (the
  transaction's write a nested one), the in-memory store checks both before writing
  either. When anything throws, neither is stored. An opening balance on another account
  is an `ArgumentError`.
- **Currencies.** An account's balances must be in its currency, and its currency cannot
  change once it has transactions (deleted ones included); a transaction's amount and
  splits must be in its account's currency; otherwise `CurrencyMismatchException`. A
  transaction on a missing or deleted account is `AccountNotFoundException`.
- **Audit fields.** A `Transaction` carries its own `createdAt`, `updatedAt` and
  `syncVersion`, and an upsert stores them as given (the caller stamps them from the
  clock); `createdAt` and `updatedAt` must be UTC with millisecond precision, else
  `ArgumentError` (`checkAuditInstants`); `deletedAt` in an upsert is ignored. Every delete
  and restore, the cascade included, stamps `updatedAt` with the clock, so Phase 2's sync
  sees the change. `Account`, `Category` and `Budget` carry none: the repositories stamp
  `created_at` on insert and `updated_at` on every write, deletes and restores included.
- **Recording.** Every user-authored write records one change-log entry per entity it
  changed, through the repository's `ChangeRecorder`, in the same database transaction
  (`sync-app.md`, **Recording**); the seeding of the system categories and the reads
  record nothing. The Drift repositories record into the Drift sync store, the in-memory
  ones into an `InMemorySyncStore`, the demo ones nothing.
- **Batches.** `upsertAll(batch)` writes several transactions in one database transaction
  (the in-memory store checks every one before writing any), each through `upsert`'s
  checks and recorded as `upsert` records it: one entry per transaction that changes, none
  for one written unchanged. A `plaid` transaction in a batch must already be stored and
  may change only the six fields the user owns and `updatedAt`
  (`checkPlaidOverridesOnly` in `repository_support.dart`). `deleteAll(ids)` deletes as
  `delete` does, in one write. A repeated id in `upsertAll` is an `ArgumentError` before
  anything is read; any transaction a batch refuses makes it write and record nothing and
  throw `TransactionBatchException` with that transaction's id and, as the cause, the
  failure it alone would have raised (`AccountNotFoundException`,
  `CurrencyMismatchException`, `EntityDeletedException`, `BankDataNotDeletableException`,
  `AuditInstantError`, or `PlaidOverridesOnlyError` naming the Plaid field, the last two
  `ArgumentError`s of their own types in `database_exceptions.dart`); any other error,
  an unrelated `ArgumentError` included, propagates as itself. Bulk edit
  (`transactions.md`) writes through them, and so will applying a rule to history.
- **Tags and splits** are replaced as a whole by `upsert`, in the same database
  transaction, and keep their order (duplicates included). Split sums are not checked
  against the amount here; the editor checks them (`transactions.md`, **Splits**).

**The Plaid apply paths** write what the server's Plaid pull brings (`sync-app.md`, **The
Plaid pull**), record nothing, and skip a local edit's checks (account existence,
currencies, deleted state), as applying a merged sync record does: the server is
authoritative.

- `AccountRepository.applyPlaid(accounts)` takes the server's whole list of linked
  accounts (`GET /accounts`). A listed account is written with every field the server sent
  and is live (`deleted_at` cleared), keeping the stored `is_hidden`, `display_order` and
  `created_at`; a new one goes after every stored account (`display_order` from the
  highest stored one plus one, in list order); an unchanged row is not rewritten. A stored
  linked account the list does not hold is soft-deleted (no cascade: its transactions'
  tombstones come from the server). Manual accounts are never touched. A balance in
  another currency than its account's throws `CurrencyMismatchException` before anything
  is written.
- `TransactionRepository.applyPlaid(page)` takes one page of `GET /transactions`. Each
  transaction is stored as sent, `source`, `created_at`, `updated_at`, `deleted_at` and
  `sync_version` included, its currency its amount's; one already stored keeps the six
  fields the user owns (`user_category_id`, `notes`, `tags`, `splits`, `receipt_path`,
  `hidden`, `withPlaidOverrides` in `repository_support.dart`; splits in another currency than the
  new amount are dropped, only their count logged) and its `deleted_with_account`. A
  tombstone for a transaction the device never had is skipped. It returns the live rows
  it inserted, for the arrival seam.
- `RecurringStreamRepository.applyPlaid(streams)` takes the server's whole list
  (`GET /recurring`) and replaces every `plaid` and `demo` stream with it, leaving the
  detector's streams and the overrides; a stream of another source or a repeated id is an
  `ArgumentError` before anything is written.
- `LiabilityRepository.applyPlaid(liabilities)` takes the server's whole list
  (`GET /liabilities`, read into entities) and replaces every stored liability; a source
  other than `plaid` or `demo`, a repeated account and kind, or amounts in two currencies
  are refused before anything is written.
- `ItemRepository.applyPlaid(items, pulledAt:)` replaces the stored Items with the
  server's list and returns them as stored: listed ones upserted with every field, the
  `removed` status and Plaid's `error_code` included (the logo bytes kept while the logo
  URL is unchanged), the others removed outright; `applyPlaidItem` writes one (an
  exchange's answer); `saveLogo` stores fetched bytes against their URL;
  `markLoginRequired` marks one `login_required` with `ITEM_LOGIN_REQUIRED`, as the server
  answered.

**Derived balances** are one SQL sum per live account over its live transactions in its
currency (`LEFT JOIN ... GROUP BY`, watched over `accounts` and `transactions`); pending
and hidden transactions count (a hidden one's money still moved); an account with none, or a missing or deleted one, is null.
`watchDerivedBalances` has a key for every live account. An overflow is an error event.
These are always derived; a balance the institution reports is the account's
`currentBalance` (`PLAN.md` §6).

**Usage** (`watchUsage`, `features/transactions/domain/transaction_usage.dart`): the
distinct tags of the live transactions in BINARY order, and their `recentLimit` (20 by
default, at least 1) most recently used user categories and accounts, each ordered by the
newest `created_at` among its transactions, ties by id; splits do not count as use. In
Drift these are three small queries (`SELECT DISTINCT` over `transaction_tags`, and
`GROUP BY ... ORDER BY MAX(created_at) DESC LIMIT ?` over `transactions`), so the editor's
suggestions never read every transaction.

**`TransactionQuery`** (`features/transactions/domain/transaction_query.dart`) is an
immutable value with equality. Its filters combine with AND, and an empty set, a null or
an empty `text` means no filter:

| Field | Matches | SQL |
|---|---|---|
| `accountIds` | on one of the accounts | `account_id IN (...)` |
| `categoryIds`, `categoryPlaidCodes` | the user category, or a split's category, is one of `categoryIds`; or, with no live user category, the Plaid code that resolves (the detailed code when a live category has it, else the primary) is one of `categoryPlaidCodes` (the effective category, `transactions.md`) | `user_category_id IN (...) OR EXISTS (split ...) OR (no live user category AND the resolving code IN (...))`, the live categories read by `EXISTS` over `categories` |
| `range` | dated in the half-open range | `date >= start AND date < end` |
| `text` | every whitespace-separated term as words in a row, the last a prefix, in the name, merchant name, notes or tags, case and Latin diacritics folded (**Full-text search**); a term with no letter or digit matches nothing, and text with no term is no filter. Without FTS5 (Drift only): the whole text as a substring of the name, merchant name or notes, ASCII letters case-insensitive | `id IN (SELECT transaction_id FROM transactions_fts WHERE transactions_fts MATCH ?)`; the fallback `LIKE '%text%' ESCAPE '\'`, with `\`, `%`, `_` escaped |
| `pending` | pending or posted | `pending = ?` |
| `hidden` | hidden by the user or not; null (the default) matches both, and the list asks for `false` unless "Show hidden" is on | `hidden = ?` |
| `tags` | carries any of the tags | `EXISTS (tag IN (...))` |
| `minAmount`, `maxAmount` | absolute amount within the bound, among transactions in the bound's currency | `currency = ? AND abs(amount_minor) >= ?` |
| `limit`, `offset` | paging; an offset alone is `LIMIT -1 OFFSET n` | |

The order is `date DESC, created_at DESC, id DESC`. `count` ignores paging. Text order is
SQLite's: `BINARY` compares UTF-8 bytes and `NOCASE` folds A to Z first, which the
in-memory implementation reproduces (`compareBinary`, `compareNoCase`); Dart's own
`compareTo` compares UTF-16 code units and orders characters above U+FFFF differently. The page's tags
and splits are loaded after the page, in chunks of 500 ids.

**Categories.** `ensureSeeded()` inserts the system categories that are missing
(`features/categories/data/category_defaults.dart`): one per Plaid primary category,
`plaid:<PRIMARY>`, and one per detailed category under it, `plaid:<DETAILED>`, all
`isSystem: true` with `plaidCategory` set. Names come from the codes in sentence case,
the primary prefix dropped (`FOOD_AND_DRINK_GROCERIES` is "Groceries" under "Food and
drink"), with a small override map for acronyms and punctuation; each primary has an icon
key (a Material icon name the UI maps) and an ARGB color its children share. Seeding never
touches existing rows, so edited icons and colors survive. A system category's name,
parent, Plaid code and system flag never change and it is never deleted
(`CategoryNotEditableException`, `CategoryNotDeletableException`); nothing creates a new
system category through `upsert`. Deleting a user category also deletes its live direct
children. Transactions keep a deleted category's id; the UI treats it as unset, showing
the category of their Plaid code, else "Uncategorized" (`transactions.md`, **The
effective category**).

**Settings** (`DriftSettingsRepository`): one `app_settings` row per field, `theme_mode`
(a JSON string) and `use_dynamic_color` (a JSON bool), so sync can merge them field by
field; a missing or unreadable value reads as that field's default.

## Three implementations, one contract

| Implementation | Where | Used by |
|---|---|---|
| Drift | `data/drift_*_repository.dart` | dev and prod |
| In memory | `data/in_memory_*_repository.dart`, over `core/db/in_memory_store.dart` | tests, and the default with no override |
| Demo | `data/demo_*_repository.dart`: the in-memory ones over the demo store | the demo flavor |

The in-memory account, transaction, category and item repositories share one `InMemoryStore`,
because balances, currency checks and the cascade cross repositories (the rule,
budget, recurring stream, liability and settings ones keep their own state: nothing crosses into them); its operations are
synchronous so the demo seed loads in a provider. Rules both implementations need
(the category edit rule, the audit-instant rule, the transaction order, SQLite's text
comparisons, list and map equality) are in `core/db/repository_support.dart`; the `BINARY`
order (`compareBinary`) lives in `core/util/binary_compare.dart`, which it re-exports, so
the rules engine orders rules the same way without importing the data layer.

The contract suites are in `app/test/contract/`, one file per repository:
`runAccountRepositoryContract`, `runTransactionRepositoryContract`,
`runCategoryRepositoryContract`, `runItemRepositoryContract`,
`runRuleRepositoryContract`, `runBudgetRepositoryContract`,
`runRecurringStreamRepositoryContract` and `runLiabilityRepositoryContract` take a factory of a
`RepositoryFixture` (the repositories of one implementation over one store) and a dispose
(the account and transaction suites' `applyPlaid` groups check the kept fields, the
tombstones, the order of new accounts, the server's `source` and that nothing is
recorded);
`runSettingsRepositoryContract` and `runSavedFilterRepositoryContract` take a factory of the
repository (saved filters have two implementations, Drift and in memory, the demo flavor
using the in-memory one with its two samples). Fixtures:
`memory_fixtures.dart` (in memory, and demo with an empty seed) and `drift_fixtures.dart`
(an in-memory `AppDatabase`), both with a `SteppingClock` that moves a millisecond per read
so two deletes never share an instant. Each implementation has a test file under
`test/features/<feature>/data/` (settings: `test/features/settings/`) that calls its
suite. `recording_contract.dart` (`runRecordingContract`) checks the entries every write
records; the Drift and in-memory implementations run it from `test/core/sync/`, and the
demo ones are checked to record nothing. A new repository gets a contract file and one
test file per implementation; a new rule gets a contract case, not an implementation
test.

Device-local stores that hold no user data to sync and no seed, such as the Plaid pull's
cursors and the dismissed duplicate pairs (`DismissedPairStore`, `duplicates.md`), have a
Drift and an in-memory implementation, the demo flavor using the in-memory one;
`runDismissedPairStoreContract` (`dismissed_pair_store_contract.dart`) runs on both.

## Receipts

`core/db/receipt_store.dart`, no Flutter import. A transaction's receipt photo is a file,
never a database row: `receiptPath` holds its relative name, `receipts/<transaction
id>.jpg` (`receiptPathFor`), and the photo never syncs (`PLAN.md` §12), so on another
device the path names nothing and the editor says the receipt is kept on another device.
The repositories hold no files; `TransactionActions` (`transactions.md`) writes them.

- **`FileReceiptStore`** (dev and prod, `receiptStoreProvider` through `overridesFor`)
  keeps them under `getApplicationSupportDirectory()`, Android's private `files/`
  directory, which no backup or device transfer carries (`build.md`, **Backup**).
  **`MemoryReceiptStore`** is the default: the tests' and the demo flavor's.
- **Writes.** `stage(id, bytes)` writes the photo under a temporary name
  (`<id>.jpg.staged`); `commit` renames it over `<id>.jpg` in one step; `discard`
  deletes it. A save stages, writes the transaction, and commits only once that write
  succeeded, so a failed save leaves the old photo in place. An id that is not letters,
  digits, `-` and `_` is an `ArgumentError`, so no path leaves the folder; `read` and
  `delete` take only paths of the form `receipts/<id>.jpg`, `read` giving null for a
  missing file and `delete` doing nothing.
- **Deletes.** A transaction's delete is soft and can be undone, so the photo stays
  with the row: a bulk delete (no undo) deletes its photos once the batch has
  committed, and the editor's delete deletes the photo when its undo snack bar closes by
  anything but Undo. Deleting an account leaves its transactions' photos to the sweep.
- **The sweep.** `sweep(keep, olderThan:)` deletes every file in the folder, staged
  ones included, whose path is not in `keep` and that was last written before
  `olderThan`. Once per launch in dev and prod, after the first frame, `bootstrap`
  runs `TransactionActions.sweepReceipts`, which reads the live transactions once and
  keeps their receipt paths, so a delete that became final while the app was not
  watching (killed during the undo, synced from another device, an account's delete, a
  pending Plaid transaction replaced by its posted one) loses its photo, and a photo
  saved while the sweep runs stays. A deleted transaction restored later by sync shows
  its receipt as kept on another device. Phase 7's account deletion wipes the folder.

No path is logged anywhere; a failure is logged by its type.

## The demo seed

`core/db/demo_seed.dart`. The demo flavor's data is the persona engine's demo seed
(`persona.md`): `demoSeedProvider` is `generateDemoSeed(persona, 1, clock.today())` over the
engine's full window, for the persona `demoPersonaProvider` holds: `initialDemoPersona()`
(the `FT_DEMO_PERSONA` dart-define's slug, `renter` when unset or unknown) at start, then
what Settings → Demo data selects. The demo `inMemoryStoreProvider` seeds the system
categories and loads it with `loadDemoSeed`, through the store's rules: the household's
accounts, then one `Opening balance` transaction (`source: demo`, id
`<account>-opening`) per non-zero opening balance, dated the day before the window, then
the transactions. The engine keeps each account's opening balance apart from its history;
loading it as a transaction, as a manual account's opening balance is, makes each derived
balance equal the balance the engine reports. **Investment accounts** have no transaction
history in the engine, so they derive to their uninvested cash only, a known gap until
Phase 6 brings holdings. The engine's Items are loaded first, with their institutions
(the demo's fake server lists the same ones). Its recurring expectations become the demo
recurring stream repository's `demo` streams and its card, mortgage and student-loan
liabilities the demo liability repository's (`recurring.md`, `liabilities.md`); its
holdings and anomalies are not loaded: the app has no repositories for them yet. Choosing another persona
rebuilds the store and the repositories over it, so the demo's own edits are lost. The demo's
rule repository holds two rules written for the persona it shows (`demo_rules.dart`,
`rules.md`), and its budget repository two budgets (`demo_budgets.dart`, `budgets.md`). The
demo flavor's in-app fake server serves the same seed (`FakeDataset.fromDemoSeed`,
`app-core.md`).

The screen tests keep the Phase 1 hand-written seed as a fixture,
`test/helpers/test_seed.dart` (`buildDemoSeed(today)`: two manual USD accounts,
`demo-checking` and `demo-card`, and twelve transactions between 58 days and 1 day before
`today`), which `seededStore()` loads.

## The legacy importer

`core/db/legacy_import/`. The original app (`git show fdf69c0:lib/main.dart`) stored
`transactions` (expenses) and `incomes` in shared_preferences as JSON arrays of
`{"amount": <double>, "description": <String>}`, plus `totalBalance`, through the legacy
`SharedPreferences` API, which the importer also uses. `LegacyImporter.runIfNeeded()` runs
from `bootstrap` in dev and prod after the database opens, unless
`app_meta.legacy_import_done` is set:

- one manual depository account named "Imported", after the existing accounts, in the
  currency of the device locale (`NumberFormat.simpleCurrency(locale:).currencyName`,
  USD when intl has none);
- one transaction per entry: dated `clock.today()`, `source: import`, the description as
  `name` (`merchantName` stays null, `PLAN.md` §12), expenses negative and incomes positive;
- amounts through `toStringAsFixed(scale)` then `Money.parse(..., locale: 'en_US')`, the only
  place a `double` is read, which rounds float error (0.1 + 0.2 is 0.30);
- ids are UUID v5 under `legacyImportNamespace`, so a run interrupted before it records
  `legacy_import_done` writes the same records again rather than duplicates, into the
  account it created and in that account's currency (whatever the device locale is now);
  if the user has deleted that account since, the three legacy keys are removed, the
  import is marked done and nothing is written; a transaction the user deleted stays
  deleted and is left out of the summary;
- an unreadable entry (not an object, no numeric amount, no text description, an amount too
  large for `Money`) or a list that is not JSON is skipped and counted; the three legacy keys
  are removed only when nothing was skipped.

A failure (a repository or storage exception) is logged by type and does not stop startup;
with `legacy_import_done` unset, the import runs again at the next launch. It returns an
`ImportSummary { transactions; total; skipped; }`, or null when it did nothing;
`bootstrap` leaves it in `legacyImportResultProvider`, which the app shell shows once as a
snack bar (`app-core.md`, **Routing and the shell**). Because the
package id changed (`PLAN.md` §12), it only serves an install that shares the original
app's data directory.

## Changing the schema

**Schema 10** adds `bills` and `bill_alerts`. Its step creates both tables and the
`bills(due_date)` index (only when `sqlite_master` lacks it) and, in the same
transaction, writes again every `bill_reminder` record held in `held_records`: a complete
record becomes a row, one of only updates stays `incomplete`, one with a field this
version does not know lands and stays held `unknown_fields`, and one that does not
decode (a cadence this version lacks) stays `unrepresentable`. `migration_test.dart`
opens a schema 9 database with a row, sync state, a stream override and each kind of
held bill record, and runs the step again at version 9 after a run whose version was not
written, with an alert already in the new table.

**Schema 9** adds `recurring_streams`, `stream_overrides` and `liabilities`. Its step, in
one transaction, creates the three tables (`IF NOT EXISTS`) and the stream index (only
when missing), and writes again every `recurring_stream` record held in `held_records`
(another device's overrides, held `unsupported_type` before this version): one that
decodes becomes a `stream_overrides` row (an override record is only updates, laid over
the defaults), one with unknown fields lands and stays held `unknown_fields`, and one
whose fields do not decode stays `unrepresentable`. `migration_test.dart` opens a schema 8
database with manual and Plaid rows, an Item, sync state and those held records, checks
the empty stream and liability tables, the released overrides and what stays held, and
runs the step again at version 8. The **every step runs again at the old version** group
covers every version from 1 to 8 (from 1 to 9 since schema 10).

**Schema 8** adds `saved_filters`; its step creates the empty table and its index, the
index only when `sqlite_master` lacks it: the version is written after `beforeOpen`,
whose index rebuild a kill can interrupt, so the step must run again at version 7. The
full-text index is not a step: `beforeOpen` builds it at every open where it is missing
(**Full-text search**). `migration_test.dart` opens a schema 7 database with manual and
Plaid rows and tags, and checks the empty table, the index over the old rows, the objects
equal to a new database's, the fallback leaving them out, and the step running again
over a run whose version was not written.

**Schema 7** adds `dismissed_pairs`; its step creates the empty table (`IF NOT EXISTS`, so a
run repeated at schema 6 keeps it and its rows), and `migration_test.dart` opens a schema 6
database with manual and Plaid rows (one hidden), a rule and sync state, checks they
survive, and repeats the upgrade at schema 6 after the table has a row.

**Schema 6** added `transactions.hidden`. Its column is added first in `onUpgrade`, before
every other step, and only when the table lacks it: the schema 2 backfill and the later
steps read the transactions through this version's table, which would otherwise name a
column an older file lacks. The step then writes again every held `transaction` record
(`releaseHeldRecords`, in its own transaction), so a newer device's hidden override, held
as `unknown_fields` on an older device, lands in its row; records still not representable
stay held. `migration_test.dart` opens a schema 5 database with manual and Plaid rows,
held transaction records and a budget with an alert. The older groups migrate to the
current version and validate against its dump, as an upgrade does. The same series made
the earlier steps idempotent (the procedure below): their indexes are created only when
missing, and the schema 2 backfill only when `change_log` is missing.

**Schema 5** added `budgets` and `budget_alerts`. Its step creates both tables and, in the
same transaction, writes again every `budget` record held in `held_records`, as schema 4 did
for rules: a complete record becomes a row, an updates-only one stays `incomplete`, one with
unknown fields lands and stays held `unknown_fields`, and one that does not decode (a start
day of 30, a period kind this version lacks) stays `unrepresentable`. `migration_test.dart`
opens a schema 4 database with rows, a rule, sync state and each kind of held budget record.

**Schema 4** added `rules`. Its step creates the table and, in the same transaction, writes
again every `rule` record held in `held_records` (`releaseHeldRecords` over the sync
store): rules another device recorded before this version could store them become rows,
and a record still not representable stays held for the reason that applies now
(`incomplete` with no create, `unknown_fields`, `unrepresentable`). `migration_test.dart`
opens a schema 3 database with rows, an Item, sync state and held rule records.

**Schema 3** added `items`; its step creates the empty table, and `migration_test.dart`
opens a schema 2 database with manual and Plaid rows, outbox entries and sync state and
checks they survive.

**Schema 2** added the sync tables (`change_log`, `record_clocks`, `sync_meta`,
`held_records`). Its step creates them and, in one transaction, backfills the change log
(`core/db/sync_backfill.dart`): every user-authored row (accounts with no Item, user
categories, `manual` and `import` transactions, stored settings) becomes a `create` entry at
a fresh clock of a provisional `local-<uuid>` node, with field clocks for every field; a row
already soft-deleted also gets a `delete` entry, and its `deleted_at` becomes that entry's
instant, as merging the entries anywhere gives. `migration_test.dart` opens a schema 1
database with data and checks the rows, the entries and that the stored records equal the
fold of the entries.

Every schema change follows these steps, in one series:

1. Change the tables and bump `schemaVersion` in `app_database.dart`.
2. Write the step in `MigrationStrategy.onUpgrade` (`if (from < N) { ... }`), idempotent
   (`PLAN.md` §12). Drift runs `onUpgrade` outside a transaction and writes the new
   version only after it returns, so when a later step fails, or the app is killed
   during the upgrade, the next open runs every step again at the old version, over
   whatever the first run committed. Each step must find its own work done and carry
   on: tables `IF NOT EXISTS` (Drift's `createTable`), an index only when
   `sqlite_master` lacks it (`_createIndex`), a column only when `PRAGMA table_info`
   lacks it (`_hasColumn`), a backfill only when its tables are missing, and releases
   of held records that find nothing the second time. A step with side effects runs in
   its own transaction, so it lands whole or not at all.
3. Regenerate the code: `dart run build_runner build` (in `app/`).
4. Dump the new version: `dart run drift_dev schema dump lib/core/db/app_database.dart
   drift_schemas/`, which writes `drift_schemas/drift_schema_vN.json`. Never edit an
   earlier version's dump.
5. Regenerate the test helpers: `dart run drift_dev schema generate drift_schemas/
   test/drift/generated/`.
6. Add the migration test to `test/drift/migration_test.dart`: `verifier.schemaAt(N - 1)`,
   rows inserted through its raw database, `AppDatabase(schema.newConnection())`,
   `verifier.migrateAndValidate(database, N)`, then reads that check the rows survived;
   and extend **every step runs again at the old version**, which migrates a database,
   sets its version back and migrates it again (and opens one that already holds a new
   column at the old version), checking the rows and the schema each time.

Commit the dump and the helpers with the change. The gate's codegen step repeats steps 3
to 5 and fails on any difference (`testing-tools.md`), and `migration_test.dart` fails when
a schema version has no dump.

## Commands

| What | Command (in `app/`) |
|---|---|
| Regenerate Drift code | `dart run build_runner build` |
| Dump the schema | `dart run drift_dev schema dump lib/core/db/app_database.dart drift_schemas/` |
| Regenerate the migration test helpers | `dart run drift_dev schema generate drift_schemas/ test/drift/generated/` |
| Run the contract suites | `flutter test test/features` |
| Run the encrypted database test on the emulator | `tools/emulator_tests.sh integration` (from the root) |
