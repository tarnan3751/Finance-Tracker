# Sync in the app

How the app hosts the sync engine (`sync.md`): what it stores, what it records, how pulled
changes reach the screens, how it talks to the server, and when sessions run; and the
Plaid pull, which brings the server's bank data after each session. Code:
`app/lib/core/sync/` (the record codec, the recorder, the device clock, the HTTP relay,
the controller and its status, the receipt uploader), `app/lib/core/plaid/plaid_pull.dart`,
`app/lib/core/db/drift_plaid_pull_store.dart`,
`app/lib/core/db/drift_sync_store.dart`, `app/lib/core/db/sync_backfill.dart`, the
schema 2 tables under `app/lib/core/db/tables/`, the repositories' writes
(`data.md`), `app/lib/features/conflicts/` (the conflicts' store, actions and screen), and
`app/lib/features/settings/presentation/sync_section.dart`. Tests:
`app/test/core/db/drift_sync_store_test.dart`, `app/test/core/sync/`,
`app/test/contract/recording_contract.dart`, `app/test/drift/migration_test.dart`,
`app/test/sync/two_device_convergence_test.dart`,
`app/integration_test/sync_two_devices_test.dart`, `app/integration_test/receipts_sync_test.dart`,
`app/test/core/plaid/plaid_pull_test.dart`, `app/test/features/conflicts/`.

Sync covers the user-authored data the app stores now: accounts, transactions,
categories, rules, budgets, the overrides of recurring streams, bills, goals and their
contributions, and the settings. Other entity types arrive with their phases; a record of one
pulled before then is kept (**The store**, held records), and so is a record of a type
this build does not know at all, a newer version's (**Unknown types**).

## Records

A record's fields are the entity's `shared_models` JSON (`core/sync/entity_codec.dart`)
plus what the app keeps beside it:

| Type | Fields |
|---|---|
| `account` | `Account.toJson()` and `deleted_at` (the entity carries no tombstone) |
| `transaction` | `Transaction.toJson()` (its own `deleted_at`) and `deleted_with_account`, the account cascade's flag, synced so a restore on any device brings back the same rows; `receipt_path` (the same `receipts/<id>.jpg` on every device) and `receipt_sha256` (the photo's hash) name the receipt photo, which travels as a blob (**Receipts**) |
| `category` | `Category.toJson()` and `deleted_at` |
| `rule` | `Rule.toJson()` and `deleted_at`; `conditions` and `actions` are whole field values, so concurrent edits of two conditions of one rule resolve last-writer-wins on the list |
| `budget` | `Budget.toJson()` and `deleted_at`; the amount is one whole field value (`{minor_units, currency}`) and `start_date` an ISO date (`budgets.md`) |
| `recurring_stream` | the user's override of one stream, keyed by the stream's id: `muted`, `is_subscription`, `display_name` and `deleted_at`; never the stream itself, which is the server's or the detector's (`recurring.md`) |
| `bill_reminder` | `BillReminder.toJson()` and `deleted_at`; the amount, the reminder offsets and the paid occurrences are whole field values, so two devices marking different occurrences at once keep one device's list (`bills.md`) |
| `goal` | `Goal.toJson()` (its own `deleted_at` and `archived_at`); the target and the linked accounts are whole field values (`goals.md`) |
| `goal_contribution` | `GoalContribution.toJson()` (its own `deleted_at`): one record per contribution, never a field of its goal, so contributions added on two devices both survive |
| `settings` | the one record `settings/local`: `theme_mode`, `use_dynamic_color` |

Tags, splits and amounts are whole field values. The audit fields of accounts, categories,
rules, budgets, bills, goals and contributions (`created_at`, `updated_at`) are not in their JSON, so each device stamps its
own; a transaction's are in its record and sync.

## The store

`DriftSyncStore` implements the engine's `SyncStore` over the database:

| Table | Holds |
|---|---|
| `change_log` | the outbox: local `seq`, entity type and id, operation, payload JSON, packed clock (unique), device id, `synced`, and `rejected_reason` for an entry the relay refused for good |
| `record_clocks` | the clock of each field of each record; the reserved field `_create` holds the clock of its earliest create |
| `sync_meta` | `pull_cursor`, `last_clock`, `device_id` (the clock's node), `last_sync_at`, `last_report` (counts only) |
| `held_records` | the whole fields of records the entity tables cannot hold exactly, with the reason: `incomplete`, `unrepresentable`, `unknown_fields`, `unsupported_type` |
| `conflicts` | this device's own values a pulled change overwrote within ten minutes (**Conflicts**); device-local, never synced |

`transaction` is Drift's: a call inside a repository's transaction joins it.

**Reading** a record takes its clocks from `record_clocks` (none: no record) and its values
from its row, restricted to the fields that have a clock, so `deleted_at` is absent until
the first delete. While a record is held, its values come from `held_records` instead, so
a later local edit merges against the whole record, never against what the row could
keep.

**Writing** a record saves its clocks and materializes it:

- a **complete** record (its create merged) of an account, transaction, category, rule,
  budget, bill, goal or contribution replaces the row, tags and splits included, as the record says. The repositories' write
  checks are not applied: they are preconditions of a local edit, and applying them to
  merged state would make the result depend on arrival order. A transaction keeps its own
  amount's currency even when its account's differs (derived balances leave such a row
  out), and may arrive before its account (there is no foreign key), as a contribution may before its
  goal (it lands, and shows once the goal arrives). `deleted_at` and
  `deleted_with_account` come from the record; a deleted record's other fields still land,
  so a later restore shows them;
- an **incomplete** record (only updates merged) whose row exists is laid over the row: a
  Plaid transaction's overrides, a system category's icon or color, the settings (which
  always exist); a stream's override, whose record is only ever updates, is laid over
  its stored row or over the defaults when there is none, so it never waits for a
  create;
- a record the table cannot hold exactly is also kept whole in `held_records`:
  - `unknown_fields`: fields this version does not know (a newer app's). The known ones
    land in the row; the unknown ones survive local edits and travel back to every device;
  - `unrepresentable`: splits the table cannot store (in another currency than the
    amount, or not decoding). Every other field lands and the row has no splits, so
    devices holding the same record show the same row and balances; a record that does
    not decode at all leaves the row as it was; a goal or contribution that does not decode
    (a kind this version lacks) is held so too, its row as it was;
  - `incomplete`: only updates merged, and no row yet;
  - `unsupported_type`: an entity the app does not store (since schema 12, only a
    settings record other than `settings/local`), or of a type this build does not know
    at all (**Unknown types**), kept under its raw type name.

  A later merge the table can hold exactly writes the row and deletes the held one.
  `materializeHeld(type, ids)` writes the held records of those entities again: the
  Plaid pull calls it for the transactions it inserts, so overrides pulled through the
  change log before their Plaid row existed (held `incomplete`) land on the row. Settings
  → Sync counts held records.

A live transaction can sit on an account this device does not show (another device
recorded it while this one deleted the account, a Phase 7 conflict; or it arrived before
its account): the Transactions tab labels it by its category alone, and its editor says
the account no longer exists.

**Unknown types.** A pulled page may carry an entry of a type a newer version added. The
client reads the page's JSON itself (`HttpFinanceApi.pullChanges`, not the generated
model, whose closed enum would fail the whole page) and returns such an entry apart, in
`PullPage.unknownTypes`, with its raw `entity_type`. The session receives its clock and
hands it to `DriftSyncStore.holdUnknownType` in the page's transaction, which folds it
into the field clocks (`record_clocks`) and fields (`held_records`, `unsupported_type`)
kept under the raw name, exactly as `merge` would fold them; the rest of the page applies
and the cursor advances, so a device on an older build keeps receiving every other change.
Its outbox never holds one: a build only records types it knows. The version that knows
the type releases these records as for any held type (`releaseHeldRecords` finds them under
the type's JSON name), in its schema step and again at every open: `openLocalData` calls
`releaseKnownHeldRecords` after the migrations, which releases the held records of every
type this build knows that has any (`DriftSyncStore.heldTypes`, one query when nothing is
held), so a build that learns a type without a schema step still releases them. A release
that throws (a held row that does not read back) is logged by type and leaves the records
held, so it never blocks a launch; the next open tries again. The server refuses a push of a
type it does not know.

Pulled changes reach the screens through Drift's watchers on the tables the store writes.

## Conflicts

The engine reports a field value of this device's that a pulled change from another
device overwrote within ten minutes (`sync.md`, **Conflicts**; `PLAN.md` §12,
"Conflicts and receipt blobs" and "7d plan rulings"). The app keeps and shows them:

- **The table.** `DriftSyncStore.recordConflicts`, inside the page's transaction, writes
  one `conflicts` row (schema 13) per entity and field: both values as JSON, both packed
  clocks (each clock's node is the device that wrote it), the entity's label (a
  transaction's merchant, else its name; the name of an account, category, rule, bill or
  goal; a stream override's display name; else none) and when it was seen (UTC). A newer
  conflict on the field replaces the older. One on an audit instant (`created_at`,
  `updated_at`), which every edit moves, is not kept.
- **Settling.** Every `write` of a record settles its conflicts: all of them go when the
  record is deleted (a pulled delete included), and each one whose field's clock is no
  longer the clock that won (a later edit from anywhere, "Keep this device's value"
  included); the rest take the entity's current name as their label. So a conflict
  always offers the value there now. A Plaid transaction's sync record carries no
  tombstone, so `applyPlaid` deletes the conflicts of every row it tombstones (Plaid's
  removal, a pending row its posted one replaced).
- **Not in a backup.** The table is device-local: a backup leaves it out and a restore
  ignores it (`backup.md`), so a restored install starts with no conflicts.
- **Expiry.** `openLocalData` sweeps the conflicts seen more than thirty days ago
  (`DriftSyncStore.sweepConflicts`) at every open; a failed sweep is logged by type and
  never keeps the app from starting.
- **The store.** `ConflictStore` (`features/conflicts/domain/`): `watch()` (the most
  recently seen first) and `dismiss`. Drift (`DriftConflictStore`, dev and prod) and in
  memory (`InMemoryConflictStore`, the tests' and the demo's, which never syncs, so it
  stays empty) pass one contract suite (`test/contract/conflict_store_contract.dart`).
- **The screen.** Settings → Sync shows "Conflicts (n)" while there are any; it opens
  the Conflicts screen (`/settings/conflicts`), one card per conflict: the record's
  kind and label, the field (by name), this device's value and the other value (an
  amount in its currency, a category or an account by name, a list joined, splits
  counted, none, yes or no; a receipt photo's hash as "Photo, on this device" or "Photo,
  not on this device"), each with the device that wrote it (this device; a name from `GET /devices`; else
  the node id, for a device no longer listed) and when, from its clock, in the device's
  zone.
- **The actions** (`ConflictActions`). "Keep the other" forgets the conflict. "Keep this
  device's value", in one sync-store transaction, reads the record and, while it is live
  (a transaction's row too, which a Plaid removal tombstones while its record says
  nothing) and the field still holds the winning clock, records a change writing the lost value
  again (and `updated_at` now, for a record that has one) through the engine's
  `LocalEditor` over the Drift store, with the device's clock: the same local edit path a
  repository's recorder takes, so it is stamped after the clock that won and wins on every
  device, and the row is materialised by `DriftSyncStore.write` exactly as a pulled merge
  is, so the full-text index, the repositories' streams and everything derived from the
  row follow. Its write settles the conflict. Otherwise, and on a build that records
  nothing (the demo), it only forgets it. A "keep this" within ten minutes of the winning
  edit shows on the other device as that device's own conflict. On a receipt photo's
  conflict, keeping this device's photo is offered only while its file here still hashes
  to it (the upload then has the bytes); otherwise the card says "This photo is no longer
  on this device" and only "Keep the other" remains. The action reads and hashes the file
  again inside its transaction, since a fetch on another tab may have replaced it after
  the screen looked, and refuses then, forgetting the conflict and saying so; a fetch
  also makes every reader of the local photo read it again.

## Receipts

A receipt photo's file is device-local (`data.md`, **Receipts**); what syncs is the
transaction's `receipt_path`, the same `receipts/<id>.jpg` on every device, and its
`receipt_sha256`. The photo travels as a blob by that hash (contract 0.7.0, `PUT` and
`GET /receipts/{sha256}`; `api.md`):

- **Upload before push.** The controller gives each session a `ReceiptUploader`
  (`core/sync/receipt_uploader.dart`) as its `beforePush`. An outbox entry of a
  transaction whose payload sets `receipt_sha256` to a hash waits until that photo is
  on the server. If the record no longer holds that hash (a later edit, here or pulled,
  replaced it), or the photo with that hash is not here (replaced or gone), the entry
  goes as it is: its value has already lost, or the bytes cannot be had. Otherwise the
  photo is uploaded (idempotent, so a retry after a lost answer is harmless); on success,
  or a refusal no retry can change (400, 413, 415, logged by status only), the entry
  goes; on any other failure it is held back until the next session, without holding up
  the entries behind it. Each hash is uploaded once a session.
- **Hashes for older photos.** Photos attached before hashes existed get theirs after
  the first frame, once (`TransactionActions.fillReceiptHashes`), as a recorded change,
  which then uploads and syncs; a photo whose file is on another device is left to it.
  The pass is one query for the rows with a path and no hash
  (`TransactionRepository.unhashedReceipts`), which finds nothing once every row has one.
- **Fetch on view.** A pulled `receipt_sha256` is stored like any field; nothing is
  fetched then. "Receipt not downloaded" is derived where the photo is shown: no file
  here, or a file whose hash differs (a photo replaced elsewhere). The receipt view
  fetches it on first view (`transactions.md`, **Receipts**).

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
| a `plaid` transaction | only `user_category_id`, `notes`, `tags`, `splits`, `receipt_path`, `receipt_sha256`, `hidden`, as updates; nothing at creation |
| a `derived` or `demo` transaction | nothing |
| an account with an `item_id` | nothing, until Phase 3 rules on linked-account overrides |
| categories, rules, budgets, bills, goals, contributions, settings | all of it; the seeding of the system categories is not recorded |
| a stream's override | as updates against the stored override, or the defaults when there is none (as settings are), so first choices on two devices merge field by field; a clear is a delete |
| recurring streams, liabilities | nothing: the server's, or the detector's on each device |

A rule's change to an arriving transaction (`rules.md`, **On arrival**) is an ordinary
transaction write: on a `plaid` row an update of `user_category_id` or `tags`, so other
devices receive the result.

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

A restored install (`backup.md`, **Restore**) gets a new provisional node in the
import's transaction (`substituteNode(provisionalNodeId())`), so it never stamps with the
node of the device the backup came from; its first session's `adopt` moves the unsynced
outbox on to its own server device, which the relay requires (an entry naming another
device is refused as `invalid`).

Every login is a new server device (`server.md`), so a re-login substitutes again. An
entry accepted before a re-login whose response was lost is sent again under the new
node with the same wall and counter: the relay stores both, and merge converges on the
one with the greater node, whose payload is the same. A device identity stable across
logins is Phase 7 scope.

**The device's clock and the bound.** The clock is the engine's `HlcClock` with its
default bound, `Hlc.maxDrift` (one hour), the bound the dev server's relay and the in-app
fake's relay refuse pushes by (`sync.md`, **The clock bound**). `DeviceClock` adds no rule
of its own. A pulled change more than an hour ahead of the device's clock is applied, and
the clock stays at the device's own time; only a device whose clock is behind the
server's meets one. An edit made after such a change is stamped past it, because the
recorder goes through `LocalEditor`, so it shows at once and wins on every device. It is
not refused for drift unless the server's clock has stepped back since it accepted the
change (or in a one-millisecond counter-overflow corner); then the refusal is transient,
the change stays queued, and the "ahead" line can show briefly though this device's clock
is right. This matters here more than in the engine's own store: the
repositories write the row before recording, and the sync store reads values from the
rows, so an edit stamped below the stored clock would leave its value under the other
device's clock.

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
adopts the device id, then runs `SyncSession` with the shared clock and the receipt
uploader as its `beforePush` (**Receipts**). A
`SyncCursorInvalidException` (the relay's log was reset) saves cursor 0 and runs again once.
The demo flavor never syncs, and nothing runs, or opens the database, while signed out.
While the restore offer is pending or not yet known (`restoreOfferProvider`, `backup.md`,
**Restore**), no session runs; once it is answered (or found not to apply) one runs.
A failed session is classified: a `NetworkError` is offline, any other `ApiException`
the server's, anything else other. After each successful session the Plaid pull runs
(**The Plaid pull**), so Sync now covers both; a device change during the pull (a
sign-out) settles the status for the new device and discards the pull's outcome, as it
does a session's report; otherwise its outcome is kept in the status apart
from the session's.

The status (`SyncStatus`) is the phase, the last sync time, the last session's counts
(`SyncSummary`: pushed, pulled, applied, refused for good, refused for clock drift,
received clocks clamped), why the last session failed (offline, server, other) and the
ledger (entries waiting, entries refused for good and the clock of the newest, held
records). The time and counts persist in `sync_meta`. A summary kept by an earlier build,
without the clamp count, reads as no clamp. The status also has the last whole Plaid
pull's time (`plaid_pulled_at`, restored at start) and why the last pull failed,
classified the same way. Settings → Sync (dev and prod) shows them: the last sync in the
device's zone, Bank data (when it was last updated, or why the update failed), the changes
waiting, "Check your device's clock: it is ahead, so some changes wait to sync" when the
last session's pushes were refused for drift (they stay queued), "Check your device's
clock: it is behind, so changes made here may be overridden" when it clamped a received
clock, the refused changes with the time of the latest, the records this version cannot
show, "Conflicts (n)" while there are any (**Conflicts**), and Sync now. Counts and times only: a change's content is never shown or logged.

## The Plaid pull

Plaid data is server-authoritative and only pulled, never pushed (`PLAN.md` §6.4).
`PlaidPull` (`core/plaid/plaid_pull.dart`, `plaidPullProvider`) brings the server's
Items, linked accounts, Plaid-sourced transactions, recurring streams, liabilities and
investments into the store through the
repositories' apply paths (`data.md`, **The Plaid apply paths**), which record nothing
and keep the `source` the server sent. One run:

1. `GET /plaid/items` and `GET /accounts`, applied together in one store transaction:
   the accounts first (a linked account the list lacks is soft-deleted), then the Items
   (an Item the list lacks is removed), with `plaid_accounts_pulled_at` and
   `plaid_items_pulled_at`;
2. `GET /transactions` from `plaid_transactions_since` (0 at first), 500 a page, through
   `has_more`. Each page is one store transaction: the page applied, the held records
   of the rows it inserted materialized, the arrival processor run on those rows, and the
   cursor saved; a failure anywhere in a page rolls it back and leaves the cursor. A
   cursor past the server's version (`SyncCursorInvalid`) restarts from 0 once per run,
   replacing rows by id;
3. `GET /recurring` and then `GET /liabilities`, each the server's whole list, each
   applied in its own store transaction (`RecurringStreamRepository.applyPlaid`: every
   server-supplied stream replaced, the detector's and the overrides kept;
   `LiabilityRepository.applyPlaid`: every liability replaced; `recurring.md`,
   `liabilities.md`), then `GET /investments/holdings`, likewise
   (`HoldingRepository.applyPlaid`: every holding and security replaced), then `GET
   /investments/transactions` from `plaid_investment_transactions_since` (0 at first),
   paged as the transactions are, each page and its cursor one store transaction
   (`InvestmentTransactionRepository.applyPage`: rows replaced by id, tombstones kept;
   `investments.md`), restarting from 0 once on `SyncCursorInvalid`. A failure of any of
   these lists is logged by its type and fails neither the run nor the others: the
   transactions matter more;
4. the institution logos the Items lack (never fetched, or their URL changed), through
   `GET /institutions/{id}/logo`; a failed fetch is logged and tried again next run, and
   never fails the pull;
5. `plaid_pulled_at`, when the run succeeded (a failed list does not stop it); the run's
   log line gives the counts of each list, and `PlaidPull.completed` emits that instant,
   which the balance snapshot writer follows (`net-worth.md`).

`run()` is single-flight: a call during a run gets one more run after it, shared by every
caller during that run, so data a caller has just made the server hold (an Item sync that
completed) is always pulled. A failure is thrown to the caller; only counts and exception
types are logged. It runs after each successful sync session (`SyncController`), after
each Item action (`items.md`, **The Link controller**) and from the developer menu (dev
only, `developer.md`); the demo flavor, which has no sessions, pulls after its Item
actions only.

`PlaidPullStore` keeps the cursors and runs a page's writes as one: `DriftPlaidPullStore`
(dev and prod) in `sync_meta` and one database transaction; `InMemoryPlaidPullStore` (the
tests and the demo flavor) beside the in-memory store, so the demo's persona switch
starts it afresh, its writes not atomic. The demo's starts its transactions and
investment transactions cursors at
the version the fake server's data had reached when it seeded the demo user
(`FakeServer.seededSyncVersionOf`, recorded at seeding, so it does not matter that the
store is first built during a Link, after the fake applied the new bank): its store is
loaded from the same seed, so a pull applies only what a Link action adds, never the
seed again over the demo's own edits. **The arrival seam**: `ArrivalProcessor.onArrived
(added)` runs on each page's newly inserted live rows inside the page's transaction, so
arrival and cursor commit together. It gets the rows as stored after the held records
were materialized (`PlaidPullStore.materializeHeld` returns them read back), so an
override another device recorded before the row arrived is already on it and a processor
never re-reads rows; `arrivalProcessorProvider` is the rules' `RuleRunner` (`rules.md`,
**On arrival**), and a processor must not fail on a row it cannot handle.

## Testing

| Suite | What it proves |
|---|---|
| `test/drift/migration_test.dart` | A schema 12 database keeps its rows, gains the empty `conflicts` table and `receipt_sha256` (empty for this device's own photos, filled for the held transaction records a newer device sent with a hash, which land), and the step runs again at version 12, with or without the column already added; a schema 10 database keeps its rows and gains the four empty investment and snapshot tables, and the step runs again at version 10; a schema 1 database with data migrates: rows kept, one create per user-authored row and a delete per deleted one, clocks increasing on one node, the stored records equal to the fold of the entries; a schema 3 database's held rule records become rows, or stay held for the reason that now applies; a schema 5 database's held transaction records carrying `hidden` land in their rows; a schema 8 database's held `recurring_stream` records become overrides, or stay held; a schema 9 database's held `bill_reminder` records become bills (a complete one), or stay held `incomplete` (updates only), `unknown_fields` (a newer field, the rest landing) or `unrepresentable` (a cadence this version lacks), and the step runs again at version 9; a schema 11 database's held `goal` and `goal_contribution` records become rows (a contribution whose goal never arrived among them), or stay held for the reason that applies, and the step runs again at version 11 |
| `test/core/db/drift_sync_store_conflicts_test.dart` | A conflict kept with both values, clocks, the label and when, a newer one replacing it, audit instants left out; dropped when its field's clock moves on or the entity is deleted, relabelled on a rename; swept after thirty days, not before |
| `test/features/conflicts/` | The conflict store contract over Drift (conflicts arriving through the sync store) and in memory; the actions over the dev wiring syncing with an engine-only second device: a conflict a pull produces, "Keep this device's value" shown by the repository's stream at once, syncing and winning on the other device (which keeps its own conflict in turn), "Keep the other" writing nothing, a conflict whose entity is deleted since going, a Plaid removal dropping its row's conflicts and keeping on a removed row writing nothing, one whose field moved on only forgotten, the demo's wiring only forgetting; the screen: both values, devices by name, this device or node id, times in a non-UTC zone, amounts, accounts and lists, a receipt photo here or not with keeping it offered only while it is here, both actions, the empty state, and Settings → Sync's entry only while there are conflicts |
| `test/core/sync/receipt_uploader_test.dart` | Over the fake server: the photo uploaded before the push of its change; a failed upload holding back only its change, which goes next session; a change whose hash was replaced since, or whose photo is gone, or whose file hashes differently, going without an upload; a 400, 413 or 415 letting it go; a 5xx or 401 holding it back; one photo named twice uploaded once |
| `test/core/db/drift_sync_store_test.dart` | The engine's store contract cases; records round-tripping through the tables (randomized transactions and rules included, a stream override of updates only, live and cleared; a bill, live and deleted, and one recorded before its new fields landing with their defaults; a goal live, archived and deleted; a contribution live and deleted, before its goal exists; a goal's updates laid over its row or held `incomplete`); the held reasons (a bill that does not decode held with its row left as it was, a bill field this version does not know held with the rest landing, a goal kind or contribution amount that does not decode held with the row as it was, a goal field this version does not know held with the rest landing), the row each leaves and their release; unknown fields surviving a local edit; a type this build does not know held under its raw name, folded in any order, and released whole by a version that knows the type; the node substitution; the ledger |
| `test/core/api/pull_unknown_types_test.dart`, `test/core/sync/unknown_types_session_test.dart` | A pulled page read by the client: an unknown `entity_type` kept apart with its raw name, the rest as before, a malformed page still a server error; a session over the Drift store applying the rest of such a page, advancing the cursor and holding the entry |
| `test/contract/recording_contract.dart` | Exactly the entries each write records, in the Drift and in-memory implementations; a refused write records nothing; a Drift write and its entry roll back together |
| `test/core/sync/sync_controller_test.dart` | The triggers, the debounce (none on top of the start), single flight with one coalesced rerun, a sign-out and sign-in during a held push (one push at a time, each entry once on the relay), the cursor reset, failures in the status, persistence, demo, in-memory data and signed-out, the Plaid pull after a session and its failure kept apart |
| `test/core/plaid/plaid_pull_test.dart` | Over the fake server into the Drift repositories: everything applied as sent and nothing recorded, the streams, the liabilities and the holdings replaced and the investment transactions paged from their cursor with tombstones and a restart, a failure of any list leaving the run and the others whole, each whole run announced, paging with the cursor per page, a failed page rolled back and its cursor kept, the cursor reset, an unlinked Item's data going, an override pulled before its row landing on it, single flight; and the in-memory repositories |
| `test/core/sync/sync_summary_test.dart` | The session summary's JSON round trip, a summary kept by an earlier build read as no clamp, and which clock line each count raises |
| `test/core/sync/http_sync_relay_test.dart` | The relay over stub endpoints: pass-through, the device check, the cursor exception, a session through it |
| `test/core/api/fake_dataset_test.dart` | Every persona's household served by the fake server as the engine gave it; the demo flavor's fake on the persona the demo shows |
| `test/features/transactions/presentation/orphan_transaction_test.dart` | A live transaction on an account this device does not show: labelled by its category, and the editor says the account is gone |
| `integration_test/sync_two_devices_test.dart` | On a device: two app instances, encrypted databases and the real client, sync through the fake server, one driven through its screens |
| `integration_test/receipts_sync_test.dart` | On a device: two app instances, each with its own receipt folder; one attaches a photo and syncs (the upload before the push); the other, through its screens, syncs, opens the transaction, fetches the photo on first view, shows it and keeps it |
| `test/sync/two_device_convergence_test.dart` | Devices, each the app's wiring over its own database, converge through one relay: offline edits, delete against edit and against restore, the cascade, settings, a system category, an amount moved to another currency against splits in the old one, clock skew, a wiped relay, a device cut off while the others make more than a page of changes and rejoining with every cursor at the relay's end, a restart between edits resuming the clock, a device three hours behind applying what it pulls with its clock within the bound and its later edit shown at once, accepted and winning, changes before sign-in, a seeded random run on three devices; rules: concurrent edits, a reorder against an edit, concurrent reorders, delete against edit, two devices filing one bank transaction by a synced rule, and a seeded random run of rule edits; hidden: a hide against a notes edit and a batch hide, hide against unhide by clock, a hidden bank row kept through the bank's update and a hide pulled before its row; stream overrides: first choices on two devices merging, a clear winning over an edit and restored by a later choice, an override reaching a device before its stream; bills: a paid mark and a rename on two devices both surviving, two concurrent marks keeping the later device's list whole, a delete winning over an edit and a restore showing it; goals: contributions added on two devices at once both surviving, a rename and an archive on two devices both surviving, a delete winning over an edit and a restore showing the edit and the contributions, a contribution reaching a device before its goal landing and showing once the goal arrives; a conflict: kept by the device whose value lost, kept both ways ("keep this" winning everywhere, the other device keeping its own conflict in turn; "keep the other" changing nothing), converging each time |
