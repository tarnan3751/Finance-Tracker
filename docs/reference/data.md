# Data: the local database and the repositories

The app's encrypted local database, the repositories every screen reads from, the demo seed,
and the one-time import of the original app's data. Code: `app/lib/core/db/` (schema, open
path, key store, in-memory store, demo seed, importer) and each feature's `domain/`
(interfaces) and `data/` (implementations): `features/accounts/`, `features/transactions/`,
`features/categories/`, `features/settings/`. Tests: `app/test/contract/` (the contract
suites), `app/test/core/db/`, `app/test/drift/`, `app/integration_test/encrypted_database_test.dart`.
The entities and `Money` are `shared_models` (`core.md`); the providers and startup are
`app-core.md`.

## The database

Drift on SQLite, at schema version 1 (`core/db/app_database.dart`; one file per table under
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
  checks it); an enum with multi-word values needs a converter that writes the JSON name.
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
| `AccountRepository` | `watchAll()` (visible first, then hidden; by `displayOrder`, then id), `watchById`, `upsert`, `delete`, `restore`, `watchDerivedBalance(id)`, `watchDerivedBalances()` |
| `TransactionRepository` | `watch(TransactionQuery)`, `watchById`, `upsert`, `delete`, `restore`, `count(TransactionQuery)` |
| `CategoryRepository` | `watchAll()` (by name ignoring ASCII case, then id), `watchById`, `upsert`, `delete`, `ensureSeeded()` |
| `SettingsRepository` | `watch()`, `read()`, `save()` |

The rules every implementation keeps:

- **Soft delete.** `delete` sets `deleted_at`; every read hides the record and `watchById`
  yields null. Deleting a missing or deleted record does nothing. `restore` is the only way
  back: an `upsert` of a deleted id throws `EntityDeletedException`
  (`core/db/database_exceptions.dart`), because deletes win over edits, as they will in
  sync.
- **The account cascade.** Deleting an account deletes its live transactions and marks
  them (`deleted_with_account`); restoring it restores exactly the marked ones, so one
  deleted on its own stays deleted, even in the same millisecond. Restoring a transaction
  whose account is deleted throws `AccountNotFoundException`.
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
- **Tags and splits** are replaced as a whole by `upsert`, in the same database
  transaction, and keep their order (duplicates included). Split sums are not checked
  against the amount here.

**Derived balances** are one SQL sum per live account over its live transactions in its
currency (`LEFT JOIN ... GROUP BY`, watched over `accounts` and `transactions`); pending
transactions count; an account with none, or a missing or deleted one, is null.
`watchDerivedBalances` has a key for every live account. An overflow is an error event.
These are always derived; a balance the institution reports is the account's
`currentBalance` (`PLAN.md` §6).

**`TransactionQuery`** (`features/transactions/domain/transaction_query.dart`) is an
immutable value with equality. Its filters combine with AND, and an empty set, a null or
an empty `text` means no filter:

| Field | Matches | SQL |
|---|---|---|
| `accountIds` | on one of the accounts | `account_id IN (...)` |
| `categoryIds` | the user category, or a split's category, is one of them | `user_category_id IN (...) OR EXISTS (split ...)` |
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
children. Transactions keep a deleted category's id; the UI shows them uncategorized.

**Settings** (`DriftSettingsRepository`): one `app_settings` row per field, `theme_mode`
(a JSON string) and `use_dynamic_color` (a JSON bool), so sync can merge them field by
field; a missing or unreadable value reads as that field's default.

## Three implementations, one contract

| Implementation | Where | Used by |
|---|---|---|
| Drift | `data/drift_*_repository.dart` | dev and prod |
| In memory | `data/in_memory_*_repository.dart`, over `core/db/in_memory_store.dart` | tests, and the default with no override |
| Demo | `data/demo_*_repository.dart`: the in-memory ones over the demo store | the demo flavor |

The in-memory account, transaction and category repositories share one `InMemoryStore`,
because balances, currency checks and the cascade cross repositories; its operations are
synchronous so the demo seed loads in a provider. Rules both implementations need
(the category edit rule, the audit-instant rule, the transaction order, SQLite's text
comparisons, list and map equality) are
in `core/db/repository_support.dart`.

The contract suites are in `app/test/contract/`, one file per repository:
`runAccountRepositoryContract`, `runTransactionRepositoryContract` and
`runCategoryRepositoryContract` take a factory of a `RepositoryFixture` (the three
repositories of one implementation over one store) and a dispose;
`runSettingsRepositoryContract` takes a factory of the repository. Fixtures:
`memory_fixtures.dart` (in memory, and demo with an empty seed) and `drift_fixtures.dart`
(an in-memory `AppDatabase`), both with a `SteppingClock` that moves a millisecond per read
so two deletes never share an instant. Each implementation has a test file under
`test/features/<feature>/data/` (settings: `test/features/settings/`) that calls its
suite. A new repository gets a contract file and one test file per implementation; a new
rule gets a contract case, not an implementation test.

## The demo seed

`core/db/demo_seed.dart`. `buildDemoSeed(today)` returns a `DemoSeed { accounts;
transactions; }`: two manual USD accounts (`demo-checking`, `demo-card`) and twelve
transactions between 58 days and 1 day before `today`, categorized with the system
categories, two with tags and one with splits, one pending, all `source: DataSource.demo`.
It is deterministic for a day (fixed ids, audit instants at noon UTC of each date). The
demo flavor's `inMemoryStoreProvider` seeds the system categories and loads
`buildDemoSeed(clock.today())` with `loadDemoSeed`, which goes through the store's rules.
Phase 2's persona engine replaces the content and produces the same `DemoSeed` shape.

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
`bootstrap` leaves it in `legacyImportResultProvider` for Phase 1d's snackbar. Because the
package id changed (`PLAN.md` §12), it only serves an install that shares the original
app's data directory.

## Changing the schema

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
