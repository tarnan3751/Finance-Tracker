# Data: the local database and the repositories

The app's encrypted local database, the repositories every screen reads from, the demo seed,
and the one-time import of the original app's data. Code: `app/lib/core/db/` (schema, open
path, key store, in-memory store, demo seed, importer) and each feature's `domain/`
(interfaces) and `data/` (implementations): `features/accounts/`, `features/transactions/`,
`features/categories/`, `features/settings/`, `features/items/`. Tests: `app/test/contract/` (the contract
suites), `app/test/core/db/`, `app/test/drift/`, `app/integration_test/encrypted_database_test.dart`.
The entities and `Money` are `shared_models` (`core.md`); the providers and startup are
`app-core.md`.

## The database

Drift on SQLite, at schema version 3 (`core/db/app_database.dart`; one file per table under
`core/db/tables/`). `app_database.dart` and the tables import no Flutter, so `drift_dev`
can run them in the Dart VM to dump the schema.

| Table | What |
|---|---|
| `accounts` | One row per account |
| `transactions` | One row per transaction |
| `transaction_tags` | A transaction's tags, `(transaction_id, position)` primary key, in list order |
| `transaction_splits` | A transaction's splits, `(transaction_id, position)` primary key, in list order |
| `categories` | The system categories and the user's |
| `app_settings` | The app preferences: `key` is the field name, `value` its JSON |
| `app_meta` | Facts about the install: `legacy_import_done`, `install_date` |
| `change_log` | The sync outbox (schema 2): one row per local change-log entry (`sync-app.md`) |
| `record_clocks` | The sync clock of each field of each synced entity, `_create` holding its create's (schema 2) |
| `sync_meta` | The device's sync state: `pull_cursor`, `last_clock`, `device_id`, `last_sync_at`, `last_report` (schema 2); the Plaid pull's `plaid_transactions_since`, `plaid_accounts_pulled_at`, `plaid_items_pulled_at`, `plaid_pulled_at` (`sync-app.md`) |
| `held_records` | Sync records the entity tables cannot hold exactly, whole, with why: `incomplete`, `unrepresentable`, `unknown_fields`, `unsupported_type` (schema 2, `sync-app.md`) |
| `items` | The user's Plaid Items as the server last listed them: institution id, name, logo URL, logo bytes and color, `status` (the `ItemStatus` JSON name), Plaid's `error_code`, `last_successful_sync_at`, `pulled_at` (schema 3; `items.md`) |

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
tombstones) and `sync_version INTEGER NOT NULL DEFAULT 0`. `transactions.source` has a CHECK
over the five provenance values and `accounts.type` one over the account types;
`transactions.deleted_with_account` (a boolean, default false) marks the rows an
account's delete removed. Tags and
splits reference their transaction with `ON DELETE CASCADE`; `beforeOpen` turns
`foreign_keys` on. There is no foreign key from `transactions.account_id` to `accounts`:
Phase 2's sync may apply a transaction before its account, so the repositories check that
the account exists. Indexes: `transactions(account_id, date)`,
`transactions(user_category_id)`, `transactions(pending_transaction_id)`,
`transaction_tags(tag)`, `categories(parent_id)`. Full-text search arrives in Phase 4 as a
migration.

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
| `TransactionRepository` | `watch(TransactionQuery)`, `watchById`, `upsert`, `delete`, `restore`, `applyPlaid(page)`, `count(TransactionQuery)`, `watchUsage({recentLimit})` |
| `CategoryRepository` | `watchAll()` (by name ignoring ASCII case, then id), `watchById`, `upsert`, `delete`, `ensureSeeded()` |
| `ItemRepository` | `watchAll()` (by institution name ignoring ASCII case, then id), `watchById`, `applyPlaid(items, pulledAt:)`, `applyPlaidItem`, `saveLogo`, `markLoginRequired` |
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
  sees the change. `Account` and `Category` carry none: the repositories stamp
  `created_at` on insert and `updated_at` on every write, deletes and restores included.
- **Recording.** Every user-authored write records one change-log entry per entity it
  changed, through the repository's `ChangeRecorder`, in the same database transaction
  (`sync-app.md`, **Recording**); the seeding of the system categories and the reads
  record nothing. The Drift repositories record into the Drift sync store, the in-memory
  ones into an `InMemorySyncStore`, the demo ones nothing.
- **Tags and splits** are replaced as a whole by `upsert`, in the same database
  transaction, and keep their order (duplicates included). Split sums are not checked
  against the amount here.

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
  `sync_version` included, its currency its amount's; one already stored keeps the five
  fields the user owns (`user_category_id`, `notes`, `tags`, `splits`, `receipt_path`,
  `withPlaidOverrides` in `repository_support.dart`; splits in another currency than the
  new amount are dropped, only their count logged) and its `deleted_with_account`. A
  tombstone for a transaction the device never had is skipped. It returns the live rows
  it inserted, for the arrival seam.
- `ItemRepository.applyPlaid(items, pulledAt:)` replaces the stored Items with the
  server's list and returns them as stored: listed ones upserted with every field, the
  `removed` status and Plaid's `error_code` included (the logo bytes kept while the logo
  URL is unchanged), the others removed outright; `applyPlaidItem` writes one (an
  exchange's answer); `saveLogo` stores fetched bytes against their URL;
  `markLoginRequired` marks one `login_required` with `ITEM_LOGIN_REQUIRED`, as the server
  answered.

**Derived balances** are one SQL sum per live account over its live transactions in its
currency (`LEFT JOIN ... GROUP BY`, watched over `accounts` and `transactions`); pending
transactions count; an account with none, or a missing or deleted one, is null.
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
| `text` | in `name`, `merchant_name` or `notes`, ASCII letters case-insensitive | `LIKE '%text%' ESCAPE '\'`, with `\`, `%`, `_` escaped |
| `pending` | pending or posted | `pending = ?` |
| `tags` | carries any of the tags | `EXISTS (tag IN (...))` |
| `minAmount`, `maxAmount` | absolute amount within the bound, among transactions in the bound's currency | `currency = ? AND abs(amount_minor) >= ?` |
| `limit`, `offset` | paging; an offset alone is `LIMIT -1 OFFSET n` | |

The order is `date DESC, created_at DESC, id DESC`. `count` ignores paging. Text matching
folds only A to Z, as SQLite's `LIKE` and `NOCASE` do: `é` and `É` differ. Text order is
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
because balances, currency checks and the cascade cross repositories; its operations are
synchronous so the demo seed loads in a provider. Rules both implementations need
(the category edit rule, the audit-instant rule, the transaction order, SQLite's text
comparisons, list and map equality) are
in `core/db/repository_support.dart`.

The contract suites are in `app/test/contract/`, one file per repository:
`runAccountRepositoryContract`, `runTransactionRepositoryContract`,
`runCategoryRepositoryContract` and `runItemRepositoryContract` take a factory of a
`RepositoryFixture` (the repositories of one implementation over one store) and a dispose
(the account and transaction suites' `applyPlaid` groups check the kept fields, the
tombstones, the order of new accounts, the server's `source` and that nothing is
recorded);
`runSettingsRepositoryContract` takes a factory of the repository. Fixtures:
`memory_fixtures.dart` (in memory, and demo with an empty seed) and `drift_fixtures.dart`
(an in-memory `AppDatabase`), both with a `SteppingClock` that moves a millisecond per read
so two deletes never share an instant. Each implementation has a test file under
`test/features/<feature>/data/` (settings: `test/features/settings/`) that calls its
suite. `recording_contract.dart` (`runRecordingContract`) checks the entries every write
records; the Drift and in-memory implementations run it from `test/core/sync/`, and the
demo ones are checked to record nothing. A new repository gets a contract file and one
test file per implementation; a new rule gets a contract case, not an implementation
test.

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
(the demo's fake server lists the same ones); its liabilities, holdings, recurring
expectations and anomalies are not: the app has no repositories for them yet. Choosing another persona
rebuilds the store and the repositories over it, so the demo's own edits are lost. The
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
2. Write the step in `MigrationStrategy.onUpgrade` (`if (from < N) { ... }`).
3. Regenerate the code: `dart run build_runner build` (in `app/`).
4. Dump the new version: `dart run drift_dev schema dump lib/core/db/app_database.dart
   drift_schemas/`, which writes `drift_schemas/drift_schema_vN.json`. Never edit an
   earlier version's dump.
5. Regenerate the test helpers: `dart run drift_dev schema generate drift_schemas/
   test/drift/generated/`.
6. Add the migration test to `test/drift/migration_test.dart`: `verifier.schemaAt(N - 1)`,
   rows inserted through its raw database, `AppDatabase(schema.newConnection())`,
   `verifier.migrateAndValidate(database, N)`, then reads that check the rows survived.

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
