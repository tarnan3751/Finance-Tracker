# Sync in the app

How the app hosts the sync engine (`sync.md`): what it stores, what it records, how pulled
changes reach the screens, how it talks to the server, and when sessions run. Code:
`app/lib/core/sync/` (the record codec, the recorder, the device clock, the HTTP relay,
the controller and its status),
`app/lib/core/db/drift_sync_store.dart`, `app/lib/core/db/sync_backfill.dart`, the
schema 2 tables under `app/lib/core/db/tables/`, the repositories' writes
(`data.md`), and `app/lib/features/settings/presentation/sync_section.dart`. Tests:
`app/test/core/db/drift_sync_store_test.dart`, `app/test/core/sync/`,
`app/test/contract/recording_contract.dart`, `app/test/drift/migration_test.dart`,
`app/test/sync/two_device_convergence_test.dart`,
`app/integration_test/sync_two_devices_test.dart`.

Sync covers the user-authored data the app stores now: accounts, transactions,
categories and the settings. Other entity types arrive with their phases; a record of one
pulled before then is kept (**The store**, held records).

## Records

A record's fields are the entity's `shared_models` JSON (`core/sync/entity_codec.dart`)
plus what the app keeps beside it:

| Type | Fields |
|---|---|
| `account` | `Account.toJson()` and `deleted_at` (the entity carries no tombstone) |
| `transaction` | `Transaction.toJson()` (its own `deleted_at`) and `deleted_with_account`, the account cascade's flag, synced so a restore on any device brings back the same rows |
| `category` | `Category.toJson()` and `deleted_at` |
| `settings` | the one record `settings/local`: `theme_mode`, `use_dynamic_color` |

Tags, splits and amounts are whole field values. The audit fields of accounts and
categories (`created_at`, `updated_at`) are not in their JSON, so each device stamps its
own; a transaction's are in its record and sync.

## The store

`DriftSyncStore` implements the engine's `SyncStore` over the database:

| Table | Holds |
|---|---|
| `change_log` | the outbox: local `seq`, entity type and id, operation, payload JSON, packed clock (unique), device id, `synced`, and `rejected_reason` for an entry the relay refused for good |
| `record_clocks` | the clock of each field of each record; the reserved field `_create` holds the clock of its earliest create |
| `sync_meta` | `pull_cursor`, `last_clock`, `device_id` (the clock's node), `last_sync_at`, `last_report` (counts only) |
| `held_records` | the whole fields of records the entity tables cannot hold exactly, with the reason: `incomplete`, `unrepresentable`, `unknown_fields`, `unsupported_type` |

`transaction` is Drift's: a call inside a repository's transaction joins it.

**Reading** a record takes its clocks from `record_clocks` (none: no record) and its values
from its row, restricted to the fields that have a clock, so `deleted_at` is absent until
the first delete. While a record is held, its values come from `held_records` instead, so
a later local edit merges against the whole record, never against what the row could
keep.

**Writing** a record saves its clocks and materializes it:

- a **complete** record (its create merged) of an account, transaction or category
  replaces the row, tags and splits included, as the record says. The repositories' write
  checks are not applied: they are preconditions of a local edit, and applying them to
  merged state would make the result depend on arrival order. A transaction keeps its own
  amount's currency even when its account's differs (derived balances leave such a row
  out), and may arrive before its account (there is no foreign key). `deleted_at` and
  `deleted_with_account` come from the record; a deleted record's other fields still land,
  so a later restore shows them;
- an **incomplete** record (only updates merged) whose row exists is laid over the row: a
  Plaid transaction's overrides, a system category's icon or color, the settings (which
  always exist);
- a record the table cannot hold exactly is also kept whole in `held_records`:
  - `unknown_fields`: fields this version does not know (a newer app's). The known ones
    land in the row; the unknown ones survive local edits and travel back to every device;
  - `unrepresentable`: splits the table cannot store (in another currency than the
    amount, or not decoding). Every other field lands and the row has no splits, so
    devices holding the same record show the same row and balances; a record that does
    not decode at all leaves the row as it was;
  - `incomplete`: only updates merged, and no row yet;
  - `unsupported_type`: an entity the app does not store yet.

  A later merge the table can hold exactly writes the row and deletes the held one.
  Settings → Sync counts held records.

A live transaction can sit on an account this device does not show (another device
recorded it while this one deleted the account, a Phase 7 conflict; or it arrived before
its account): the Transactions tab labels it by its category alone, and its editor says
the account no longer exists.

Pulled changes reach the screens through Drift's watchers on the tables the store writes.

## Recording

Every user-authored repository write calls `ChangeRecorder.record(type, id, before,
after)` once per entity it changed, with record fields, inside the write's own transaction
(`data.md`, **Repositories**). `EngineChangeRecorder` runs the engine's `LocalEditor` over
the sync store, reading the device clock inside the store transaction. `before` is the
stored entity (the snapshot an edit screen started from is Phase 7's `basedOn`). Settings
are recorded as updates against what is stored (the defaults before any save), so first
saves on two devices merge field by field.

The filter by `source` is `userAuthoredChange`, shared by every implementation:

| Change | Recorded |
|---|---|
| a `manual` or `import` transaction | all of it |
| a `plaid` transaction | only `user_category_id`, `notes`, `tags`, `splits`, `receipt_path`, as updates; nothing at creation |
| a `derived` or `demo` transaction | nothing |
| an account with an `item_id` | nothing, until Phase 3 rules on linked-account overrides |
| categories, settings | all of it; the seeding of the system categories is not recorded |

An account delete or restore records the account and each transaction its cascade
changed; a category delete, the category and its children; a create with an opening
balance, both.

## The device's node

`DeviceClock` holds the device's one `HlcClock`, shared by every edit and every session.
Its node starts as a provisional `local-<uuid v4>` (a new database, or the schema 2
backfill), so changes made before the first sign-in are recorded. Before each session the
controller calls `adopt(deviceId)` with the server's id for this device, which in one
transaction (`DriftSyncStore.substituteNode`) replaces only the node of every unsynced,
unrejected entry's clock, wall and counter kept (an edit keeps its time under
last-writer-wins), and of every field clock equal to one of those clocks, the persisted
clock and `device_id`. Synced and rejected entries keep their node. Clocks stay unique:
every substituted clock shares the substitution and the new id is unused.

Every login is a new server device (`server.md`), so a re-login substitutes again. An
entry accepted before a re-login whose response was lost is sent again under the new
node with the same wall and counter: the relay stores both, and merge converges on the
one with the greater node, whose payload is the same. A device identity stable across
logins is Phase 7 scope.

## The relay

`HttpSyncRelay` (`core/sync/http_sync_relay.dart`) is the engine's `SyncRelay` over the
API: it pushes and pulls through `SyncEndpoints`, the API's two sync operations in the
engine's types, which `FinanceApiSyncEndpoints` takes from the app's `FinanceApi`
(`HttpFinanceApi` maps the wire: rejection codes to `PushRejectionReason`, the accepted
clocks, the pulled entries as plain JSON, `next_since` and `has_more`; `app-core.md`,
**The API client**). The adapter adds two things: a pull for a device other than its
session's is refused (the server knows the device from the token), and the API's
`SyncCursorInvalid` (409 `sync_cursor_invalid`) becomes `SyncCursorInvalidException(since,
0)`, the last `seq` being unknown over HTTP. `syncRelayProvider` is that relay as the
signed-in device; every other `ApiException` propagates for the controller to classify.

## The controller

`SyncController` (`core/sync/sync_controller.dart`) runs when this build's local data
syncs (`localDataSyncsProvider`: true for the Drift data of dev and prod through
`overridesFor`, false for the in-memory data of the tests and the demo flavor, where the
status is `unavailable` and Settings has no Sync section) and someone is signed in
(`syncDeviceIdProvider`, the session's `SignedIn` device id; otherwise the status is
`signedOut`). `bootstrap` starts it once the stored session is read. A session runs:

- when the controller starts;
- when the app resumes (`AppLifecycleListener`);
- `syncDebounceProvider` (3 s) after the last local change, seen as the outbox growing
  (the outbox found at start is the start session's);
- on Sync now.

One session runs at a time; a trigger during one runs one more after it. The controller
is built once and hears the device id through a listener, which applies a change in a
microtask (Riverpod may resume the paused controller, and so deliver the change, while a
widget builds, when its state cannot be set), so a sign-out and a sign-in
during a session never start a second one: the session in flight finishes (the engine
cannot cancel one), its report is discarded, and the next session adopts the new device
id first. What the relay accepted during it stays synced under the old node; the rest of
the outbox moves to the new one, so each entry reaches the relay once. Each session
adopts the device id, then runs `SyncSession` with the shared clock. A
`SyncCursorInvalidException` (the relay's log was reset) saves cursor 0 and runs again once.
The demo flavor never syncs, and nothing runs, or opens the database, while signed out.
A failed session is classified: a `NetworkError` is offline, any other `ApiException`
the server's, anything else other.

The status (`SyncStatus`) is the phase, the last sync time, the last session's counts
(`SyncSummary`: pushed, pulled, applied, refused for good, refused for clock drift, pull
held back), why the last session failed (offline, server, other) and the ledger (entries
waiting, entries refused for good and the clock of the newest, held records). The time
and counts persist in `sync_meta`. Settings → Sync (dev and prod) shows them: the last
sync in the device's zone, the changes waiting, a clock far ahead holding changes back,
the refused changes with the time of the latest, the records this version cannot show,
and Sync now. Counts and times only: a change's content is never shown or logged.

## Testing

| Suite | What it proves |
|---|---|
| `test/drift/migration_test.dart` | A schema 1 database with data migrates: rows kept, one create per user-authored row and a delete per deleted one, clocks increasing on one node, the stored records equal to the fold of the entries |
| `test/core/db/drift_sync_store_test.dart` | The engine's store contract cases; records round-tripping through the tables (randomized transactions included); the held reasons, the row each leaves and their release; unknown fields surviving a local edit; the node substitution; the ledger |
| `test/contract/recording_contract.dart` | Exactly the entries each write records, in the Drift and in-memory implementations; a refused write records nothing; a Drift write and its entry roll back together |
| `test/core/sync/sync_controller_test.dart` | The triggers, the debounce (none on top of the start), single flight with one coalesced rerun, a sign-out and sign-in during a held push (one push at a time, each entry once on the relay), the cursor reset, failures in the status, persistence, demo, in-memory data and signed-out |
| `test/core/sync/http_sync_relay_test.dart` | The relay over stub endpoints: pass-through, the device check, the cursor exception, a session through it |
| `test/core/api/fake_dataset_test.dart` | Every persona's household served by the fake server as the engine gave it; the demo flavor's fake on the persona the demo shows |
| `test/features/transactions/presentation/orphan_transaction_test.dart` | A live transaction on an account this device does not show: labelled by its category, and the editor says the account is gone |
| `integration_test/sync_two_devices_test.dart` | On a device: two app instances, encrypted databases and the real client, sync through the fake server, one driven through its screens |
| `test/sync/two_device_convergence_test.dart` | Devices, each the app's wiring over its own database, converge through one relay: offline edits, delete against edit and against restore, the cascade, settings, a system category, an amount moved to another currency against splits in the old one, clock skew, a wiped relay, changes before sign-in, and a seeded random run on three devices |
