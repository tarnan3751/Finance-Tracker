# Backup and restore

Everything the app holds, exported into one file encrypted with a passphrase the user
chooses, kept anywhere (Save as or Share), and restored onto a fresh install or after a
lost database key, the restored content provably equal to the source. The decisions are
in `PLAN.md` §12: "Backup archive" and "Backup content and restore" (2026-10-30), with
the 7a plan's rulings (the demo has no backup, the offer holds sync, the account rule,
the restart, the encodings). The wipe that clears an install for a restore is
7b's; receipt blob sync 7d's.

Code:
- `app/lib/features/backup/domain/` (pure Dart, no Flutter import):
  - `backup_format.dart`: the header, its caps, and the typed failures;
  - `backup_cipher.dart`: the key (Argon2id, then HKDF) and the frames;
  - `backup_manifest.dart` and `backup_archive.dart`: the plaintext;
  - `passphrase_strength.dart`: the passphrase rule and its hint.
- `data/database_dump.dart`: the canonical dump of every table, the tolerant import, and
  whether an install has data.
- `application/`:
  - `backup_worker.dart`: the work run in isolates (seal, open and check, restore), and
    its progress;
  - `backup_service.dart`: the export, opening a file, the restore's work, the account
    rule, and the isolate runner;
  - `backup_providers.dart`: the service, the environment (runner and directory), the
    app restart a restore runs under, and the restore offer.
- `presentation/`:
  - `backup_screen.dart`: Settings → Data → Backup (`/settings/backup`);
  - `restore_flow.dart`: the restore, the same from its three places;
  - `restore_offer_screen.dart`: the fresh install's offer (`/restore`);
  - `restoring_app.dart`: the screen shown while the app is stopped for a restore;
  - `backup_messages.dart`: the messages, stage labels and progress line.
- The file picker is `core/platform/backup_picker.dart` (`app-core.md`, **The backup
  picker**); the hand-over is the file exporter (`app-core.md`, **The file exporter**);
  the restart is `startApp` in `bootstrap.dart` (`app-core.md`, **Startup**).

Tests:
- `app/test/features/backup/domain/`: the header and its caps, the frames (every boundary
  size, a flipped byte in each frame, a dropped, swapped or cut frame, appended bytes, a
  wrong passphrase), the key, the plaintext and its checks, the passphrase rule;
- `data/database_dump_test.dart`: the tolerant import (unknown tables and columns
  dropped, missing columns defaulted), a foreign key or constraint failure rolling it
  all back, the skipped keys, what counts as data, and what `openBackup` refuses (a
  newer schema, a receipt path outside the folder, a wrong passphrase);
- `backup_round_trip_test.dart`, the acceptance test (**Tests** below);
- `backup_fixture_test.dart`: the committed schema 12 backup restores into the current
  schema, through the app's own path too (opened in an isolate, restored over old
  database files under a new key), and the account rule;
- `presentation/backup_screen_test.dart`: the export's rule, hint, progress and
  hand-over, every refusal's message, the confirmation and the restart, the demo's
  entry, the offer, the lost-key screen;
- `app/test/core/platform/backup_picker_test.dart`: the picker's boundary;
  `test/core/router/auth_redirect_test.dart`: the offer's redirect;
  `test/core/sync/sync_controller_test.dart`: the hold while it is pending;
- on the harness, `app/integration_test/backup_test.dart` (**Tests**).

## The format

An `FTBK` file is a 62-byte header, then frames. Big-endian:

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | magic `FTBK` |
| 4 | 1 | format version, 1 (anything else is refused as made by a newer version) |
| 5 | 1 | KDF id, 1 (Argon2id version 1.3) |
| 6 | 4 | Argon2id memory, KiB (an import refuses more than 131072, 128 MiB) |
| 10 | 4 | Argon2id iterations (an import refuses 0 or more than 6) |
| 14 | 4 | Argon2id parallelism (an import refuses 0, more than 8, or less memory than 8 KiB a lane) |

The caps are twice the standard cost in every dimension: a hostile header costs its KDF's
time and memory before anything authenticates, and nothing cancels the KDF yet.
| 18 | 16 | salt |
| 34 | 24 | base nonce |
| 58 | 4 | frame size, 65536 (the only one v1 accepts) |

- **The key.** Argon2id (`cryptography` 2.9.0's pure Dart `DartArgon2id`, which runs its
  lanes in isolates of its own) over the passphrase's UTF-8 bytes, exactly as typed (no
  trimming, no Unicode normalization: a passphrase typed with another composition of the
  same letters is another passphrase), with the header's salt and cost, gives a 32-byte
  master key; HKDF-SHA256 of it, salted with the header's salt, info `FTBK v1 frames`,
  gives the frame key.
- **The cost.** An export uses m = 64 MiB, t = 3, p = 4 (`KdfParameters.standard`,
  RFC 9106's second recommendation). Measured on 2026-10-30, the debug build (JIT) on the
  harness AVD (`ft-lane`, Android 36, arm64, on an Apple Silicon host): 3.1 s for the
  first derivation in a process, 0.9 s after; on the host (macOS, JIT), about 2 s for
  a whole export of the family persona. A release build (AOT) is faster; a mid-range
  phone has not been measured (the coordinator's Pixel 6 run). The cost travels in the
  header, so a later build can change it and still open older files; the tests use
  8 MiB, t = 1, p = 1.
- **The frames.** The plaintext is cut into 64 KiB chunks; every frame but the last is
  full, and the last holds the rest, 0 to 65535 bytes: when the plaintext fills its
  frames exactly, an empty last frame follows, so a file always ends in a short frame.
  Each is sealed with XChaCha20-Poly1305 under the frame key. Its nonce is the base
  nonce with the frame index, as 8 big-endian bytes, XORed into its last 8 bytes; its
  associated data is the header, the index (8 bytes) and a last-frame flag (1 byte). On
  disk a frame is its ciphertext then its 16-byte tag.
- **What fails.** A changed byte anywhere (the header is in every frame's associated
  data), swapped frames, a dropped frame, a file cut inside a frame or at a frame
  boundary (no short last frame), or bytes appended all fail. A failure on the first
  frame reads as "the passphrase is wrong, or the file is damaged" (the two look the
  same); a later one as "damaged or incomplete".
- **The passphrase** is at least 12 characters (code points); a hint under the field
  says weak, fair or strong from its length and the kinds of character in it (advice,
  not a gate). There is no recovery: a forgotten passphrase loses the backup, and the
  screen says so.

## The content

The plaintext is UTF-8 NDJSON, one JSON value per line:

1. **The manifest**: `format` (`FTBK`), `format_version`, `schema_version`, `app_version`
   (version and build), `created_at` (UTC, ISO with milliseconds), `user_id` (the
   install's user, the first account signed in on it; null for an install that never
   signed in), `device_id` (the source's sync node), `tables` (each table's row count,
   in dump order), `receipts` (how many follow), and `dump_sha256` (of the table lines).
2. **The tables.** Every Drift table in the schema's order (`AppDatabase.allTables`, a
   new table appended), each a header line `{"table", "columns", "rows"}` then its rows,
   each a JSON array in the header's column order, sorted by primary key. Values by the
   column's declared type: INTEGER an integer, BOOLEAN `true`/`false`, TEXT a string (the
   ISO dates, the `Decimal`s, the JSON columns as their text), BLOB base64 (an Item's
   logo), and every audit instant a UTC ISO string with milliseconds: a column through
   `UtcMillisColumnConverter`, the nullable ones (`deleted_at`, `balances_as_of`,
   `last_successful_sync_at`) included, which Drift wraps in a `NullAwareTypeConverter`
   (the dump tests the converter's `DateTime`-from-`int` type, so it sees both); the
   import accepts only that string for them. `Money` is already an integer `_minor`
   column beside a `currency`. A table with no primary key, or a column of another type
   (a REAL, a Drift `dateTime()`), makes the dump throw, and the gate dumps every table
   of the current schema, so a schema change cannot break export unnoticed. The full-text objects and
   `sqlite_sequence` are not Drift tables and do not travel; `conflicts`, this device's
   sync conflicts (`sync-app.md`, **Conflicts**), is device-local and left out
   (`backupExcludedTables`), and ignored if a backup carries it.
3. **The receipts**, in path order: `{"receipt": "receipts/<id>.jpg", "sha256", "bytes"
   (base64)}`, for every path a transaction row (live or deleted) references whose file
   exists.

Everything travels: the entity tables, the local-only ones (alerts, dismissed pairs,
saved filters, snapshots), `app_settings`, `app_meta`, and the sync state (`change_log`,
`record_clocks`, `sync_meta` with its pull and Plaid cursors, `held_records`). The bytes
are canonical: the same database gives the same dump, so two backups of it differ only in
the manifest's `created_at` and the header's salt and nonce. Reading back checks the
whole: the manifest, each table's header and row count, the dump's SHA-256, each
receipt's SHA-256 and their count, and nothing after the last.

## Restore

**Where.** Settings → Data → Backup, "Restore from a backup"; the offer at `/restore`;
and the screen of a lost database key (`DatabaseErrorApp` for
`DatabaseKeyLostException`). The demo flavor has no database: its Settings entry says
that its generated data is not kept or backed up, and offers neither.

**The offer.** In dev and prod, when someone is signed in, the database holds nothing
(below), and `app_meta.restore_offer_answered` is absent, `RestoreOffer` is pending: the
router holds the app at `/restore` and the sync controller runs no session (nor while the
offer is being worked out, as right after a sign-in), so a backup lands before the
server's copy of the data does. "Start fresh" records the answer (the
key, a UTC instant) and lets both go on; a restore ends it with a database that is not
empty.

**An empty install.** `hasLocalData` is false when no table holds a row but the
install's bookkeeping (`app_meta`, `sync_meta`, `app_settings`) and the seeded system
categories. A restore onto an install with data is refused ("Delete the app's data
first", which 7b's wipe will offer), checked before the file is picked and again after
the confirmation; the lost-key screen has no data it can read.

**The steps.**

1. The file from the backup picker, read through a handle: a file over 512 MiB is refused
   unread, then its 62-byte header is read and refused on a wrong magic, version or a
   cost over the caps before the rest is read; then its passphrase in a dialog.
2. In an isolate, `openBackup`: the header and its caps, the key, every frame
   authenticated, the content read back and checked, the schema version (a newer one is
   refused), every receipt path checked against `receipts/<id>.jpg`, and a trial import
   into a database in memory, so a backup that cannot be restored is refused before
   anything on the device is touched. It returns the manifest and the frame key.
3. The account: a backup with a user restores only for that user, the signed-in one, or
   on the lost-key screen the install's recorded user when it can be read, or when none
   is recorded the stored session's (its account would otherwise get the backup's
   outbox at the next sync); a backup of an install that never signed in restores for
   anyone, as a new install's own edits do at its first sign-in.
4. A confirmation with the backup's date, app version and counts; on the lost-key screen,
   that the data that can no longer be opened will be deleted.
5. The app restarts around the rest (`appRestartProvider`, `startApp`): the restoring
   screen is shown, the app is stopped (its database closed, sync stopped), then
   the database file and its `-wal`, `-shm` and `-journal` are deleted, a new key is
   created, and in an isolate the receipts are written (staged and committed) and the
   tables imported into a new database. On the lost-key screen, the backup's user then
   becomes the install's when none was recorded, so another account cannot sign in onto
   it. The app then starts as at launch: the full-text index is built at that open.
   A failure here is shown with a Continue button that starts the app on what the
   device holds.

**The import** (`importTables`), on a database just created at the current schema and
opened without the full-text objects: foreign keys off; in one transaction, each table in
the backup's order (parents before `transaction_tags` and `transaction_splits`, the only
foreign keys); a table or column this build does not know is dropped; a column the backup
lacks takes its SQL default (the schema policy is additive); `PRAGMA foreign_key_check`
must find nothing; any failure rolls the whole import back; then foreign keys on.

**What a restore changes.**
- It drops the device bookkeeping keys `reminders_zone`, `reminders_scheduled_at` and
  `snapshots_written_on`, so the new device plans its reminders and writes its snapshots
  itself, and `fts_definition`, which the first open writes again.
- It drops the app lock's settings `lock_enabled`, `lock_timeout_seconds` and
  `secure_screen`, which describe the device they were chosen on (`lock.md`): the restored
  device starts with the lock off and its flavor's screenshot default.
- It resets the device's sync identity, in the import's transaction:
  `DriftSyncStore.substituteNode(provisionalNodeId())` moves every unsynced, unrejected
  outbox entry, the field clocks equal to theirs, the persisted clock and `device_id` to
  a new `local-<uuid>` node, wall and counter kept. The relay refuses an entry whose
  `device_id` is not the calling device or whose clock's node is not its `device_id`
  (`server/lib/src/sync/change_log_relay.dart`, and the in-app fake the same), and the
  restored install signs in as a new server device: its first session's
  `DeviceClock.adopt` moves the entries to that device before the push
  (`sync-app.md`, **The device's node**). The install never stamps with its source's
  node. Synced and rejected entries keep theirs; an entry the source pushed after the
  backup is sent again under the new node with the same wall, counter and payload, and
  merge converges. The first sync then reconciles with the server: what changed there
  since the backup arrives, tombstones winning.

## In the app

- **Off the UI isolate.** `BackupService.export` reads the dump in one transaction on
  the app's connection and the receipts through the receipt store, then hands them to
  `sealBackup` in an isolate of its own (`runInIsolate`: `Isolate.run`, the progress
  sent back through a port); `openBackupFile` runs `openBackup` the same way, and the
  restore's work runs `restoreBackup`, which opens Drift over the new file itself. The
  closures sent to an isolate are built in top-level functions, so each captures only
  its own arguments. Argon2id spawns its own lane isolates inside.
- **Providers** (`backup_providers.dart`): `backupServiceProvider` over the dev and prod
  database; `backupEnvironmentProvider`, the runner and the directory of the database
  and the receipts (an isolate and the application support directory; the tests give
  the calling isolate and a temporary directory); `appRestartProvider`, which `startApp`
  supplies (`app-core.md`, **Startup**); `restoreOfferProvider`, the offer
  (**Restore**).
- **Logging.** A failure is logged by its type only; no passphrase, path or content is.

## Screens

- **Backup** (`/settings/backup`): the export (what a backup holds; the passphrase twice,
  the hint, the no-recovery warning; Save as and Share, the file
  `finance-tracker-<local date>.ftbk`, `application/octet-stream`) and the restore.
- **Progress.** Export: "Reading your data", "Securing with your passphrase"
  (indeterminate: Argon2id reports none), "Encrypting" (frames done of all). Restore:
  "Securing with your passphrase", "Checking the backup" (frames), then, on the
  restoring screen, "Checking the backup" again (the frames are opened once more in the
  restore's isolate) and "Restoring" (receipts and rows done of all). Each is a labelled bar
  in a live region, its value spoken as a percentage; it is updated at a new stage, at
  the end, and otherwise only about every tenth or every second (`ProgressThrottle`), so
  a screen reader is not read every 64 KiB frame. While a restore runs on the offer,
  "Start fresh" waits. After a Save as or Share, the passphrase fields are cleared.
- **Refusals**, one message each: not a backup; over 512 MiB; made by a newer version (format or
  schema); settings this app does not accept (the caps); the passphrase is wrong or the
  file damaged; damaged or incomplete; another account; this device already has data;
  the file could not be opened; and anything else ("could not be restored, nothing was
  changed").

## Tests

- **The acceptance test** (`backup_round_trip_test.dart`, in the gate): a database holding
  the family persona (linked through the in-app fake server and pulled as the dev flavor
  pulls it) and manual data of every kind (accounts, transactions with tags, splits,
  notes and receipts, a deleted one, rules, budgets, bills, goals and contributions,
  settings, a saved filter, alerts, a snapshot, the device keys, a held record, and an
  outbox with synced, rejected and unsynced entries) is exported, restored into a new
  encrypted database and opened as the app opens it. Every table's dump equals the
  source's, row for row, once the source is transformed by exactly what a restore
  changes (the three keys dropped, the identity moved to the new node); the receipt files
  are equal byte for byte; the rebuilt index finds a restored transaction; the restored
  outbox pushes to the relay as a new device with nothing refused. Two exports with the
  same instant, salt and nonce are byte-identical, and with another instant differ only
  in `created_at`.
- **The older schema** (`backup_fixture_test.dart`):
  `test/fixtures/backup/ftbk-v1-schema12.ftbk`, made by that test at schema 12 with `FT_WRITE_BACKUP_FIXTURE=1` (passphrase in the
  test), restores into the current schema with its rows, receipt and index. It is the
  current schema today; it becomes an older one with the next schema step, and stays.
- **On the harness** (`integration_test/backup_test.dart`): the demo build on the dev
  wiring, as `sync_two_devices_test.dart` runs it, over the in-app fake server. A source
  install (a temporary encrypted file) holding the family persona and a manual account
  and transaction with a receipt exports through Settings → Backup with the standard
  cost, which the fake exporter records; its receipt is then removed. A fresh install
  starts through `startApp` as the dev flavor does (the database file under the
  application support directory), signed in as the same user on a new device: the offer
  holds it at `/restore`, the fake picker hands it the file, the passphrase opens it, the
  confirmation restores it through the real restart, and the app comes back on the
  restored data, the receipt photo in place and the transaction found by search. The
  real Storage Access Framework round trip is the coordinator's, on a phone.

## Known limits

- **In memory.** The archive is built and read whole in memory. An export holds the
  dumped rows, the dump and plaintext bytes and the sealed file, and copies the rows and
  receipts into the sealing isolate and the file back. A restore holds the file (copied
  into the opening isolate, then into the restoring one), its plaintext, the decoded
  rows and receipts, and in the opening isolate a trial import into a database in
  memory as large as the real one; so the peak is several times the file. Receipts
  travel as base64, a third larger than the photos. Checked at the family persona's
  size: 3,174 rows (2,386 transactions) and the test's receipts make a dump and a file
  of about 0.8 MB, a few megabytes at the peak. A household with years of history and a
  few hundred receipt photos (about 300 KB each) makes a file of over 100 MB and a peak
  of several hundred; streaming the frames and the import is later scope.
- **512 MiB.** A file over 512 MiB is refused unread, with its own message.
- **The dev escape hatch.** A restore writes the encrypted `finance_tracker.db`; a dev
  build run with `FT_PLAIN_DB=true` does not see it.
