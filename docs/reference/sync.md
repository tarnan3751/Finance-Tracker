# Sync: the change-log engine

How user-authored data moves between devices (`PLAN.md` §6.4). Code: `packages/sync_engine/`,
pure Dart with no Flutter and no IO, used by the app and by the dev server. It depends on
`shared_models` for `Hlc`, `ChangeLogEntry`, `ChangeOperation`, `EntityType` and
`UtcInstantConverter` (`docs/reference/core.md`).

The engine covers **user-authored data only**: manual accounts and transactions,
categories, rules, budgets, recurring streams, bill reminders, goals and settings, plus the
user's overrides. **Plaid-sourced data never goes through it.** Plaid-sourced data is
server-authoritative, and the app pulls it by the server's version number. The engine
never reads `source` and has no way of telling a Plaid row from a manual one. Keeping
Plaid-sourced rows out of the change log is the host's filter, by `source`, in the app's
repositories: before calling `LocalEditor.recordChange`, a repository checks that the
change is to user-authored data. Whether the dev server's relay also refuses such
entries, as a defence in depth, is lane 2d's decision.

## Pieces

| Piece | What it is |
|---|---|
| `HlcClock` | The device's hybrid logical clock. It stamps local changes and advances past received ones. |
| `EntityRecord` | One entity's field-level state: its JSON fields, a clock per field, and the clock of its create. |
| `diff` | Turns a local edit (before and after JSON) into a `ChangeLogEntry`. |
| `merge` | Applies an entry to a record, last-writer-wins per field. |
| `SyncStore` | What the host stores: records, outbox, pull cursor, clock, transactions. `InMemorySyncStore` is the reference implementation. |
| `SyncRelay` | The server as the engine sees it: push entries, pull by `seq`. `InMemorySyncRelay` is the reference implementation. |
| `LocalEditor` | The local edit path: diff, stamp, store and outbox in one transaction. |
| `SyncSession` | One sync: push the outbox, then pull and merge. |

## The clock

`HlcClock(nodeId, {last, maxDrift})` follows Figure 5 of Kulkarni, Demirbas, Madappa, Avva
and Leone, "Logical Physical Clocks and Consistent Snapshots in Globally Distributed
Databases" (2014). `l` is the wall time in milliseconds, `c` the counter and `pt` the
device's physical clock.

- **`send(pt)`**: `l = max(l, pt)`. If `l` did not change, `c + 1`; otherwise `c = 0`.
- **`receive(m, pt)`**: `l = max(l, l.m, pt)`. If all three of `l`, `l.m` and the old `l`
  are equal, then `c = max(c, c.m) + 1`. If only the old `l` equals the new `l`, then
  `c + 1`. If only `l.m` does, then `c.m + 1`. If `pt` is ahead of both, then `0`.
- **Drift.** A remote wall time more than `maxDrift` (one hour by default) ahead of `pt`
  throws `ClockDriftException`. The state is unchanged and the entry is not applied. This
  is the paper's rule for ignoring out-of-bounds messages. `checkDrift` makes the same
  check without receiving.
- **Counter overflow.** A counter that would pass `Hlc.maxCounter` advances `l` by one
  millisecond and resets `c` to 0. The paper lets it roll over. Advancing keeps the clock
  monotonic and still greater than the remote clock.
- **A wall clock that goes backwards** leaves `l` where it was, and the counter increments
  until `pt` catches up. The paper's corrective reset of `l` to `pt` is never applied,
  because last-writer-wins needs every new clock to be greater than every clock the device
  has issued or seen.
- **Persistence.** The clock does no IO. `last` is its state. `LocalEditor` and
  `SyncSession` save it with `SyncStore.saveClock` in the same transaction as the work that
  advanced it. At startup the host resumes the clock with
  `HlcClock(deviceId, last: await store.lastClock())`. One clock instance is shared by the
  device's `LocalEditor` and `SyncSession`.

## Records and merge

An `EntityRecord` holds the entity's snake_case JSON exactly as `shared_models` writes it.
Each **top-level field** is a last-writer-wins register with its own clock (`fieldClocks`).
A nested value is one value, compared deeply and replaced whole:

- a list such as `tags`, or `splits` (a list of maps);
- a map such as a `Money` `{minor_units, currency}`.

The engine never merges inside one, so an amount's units and currency always come from
the same change.

- **`deleted_at` is the tombstone register.** It has its own clock, like every field, but
  only `update` and `delete` entries write it; a `create` never does. It is therefore
  absent until the first delete. The entity is deleted while it is non-null
  (`isDeleted`). The engine interprets no other field.
- **`createdAt`** is the clock of the earliest `create` merged. It is null while only
  updates have arrived (out-of-order delivery), so `isComplete` is false. The host does not
  show an incomplete record.
- **`toCanonicalJson()`** sorts keys at every depth and writes clocks packed. Equal
  records have byte-identical canonical forms under JSON number equality. The one
  exception is a number written once as `1` and once as `1.0`: the values are equal but
  encode differently. That never arises in practice, because no user-authored field is a
  double.

`merge(local, entry)` does the following:

1. For each field in the payload, the entry's value is taken when the field has no clock
   or a smaller one. An equal clock is the same change seen again, so nothing happens.
2. A `create` never writes `deleted_at`: merge skips that field in any create, whoever
   produced the entry. This is a defence in depth, since `diff` already leaves it out.
   A create lowers `createdAt` to its clock if that clock is earlier. A create for an id
   that already exists is an update of every other field it carries.
3. `MergeOutcome` reports the merged record, the fields taken (`changedFields`), and
   whether anything changed (`applied`).

**Why every device converges.** Each field register is a join semilattice: the join keeps
the pair with the greater clock. `createdAt` is also a join semilattice, under minimum.
Merging an entry joins the record with the entry. Join is commutative, associative and
idempotent, so any set of entries, delivered in any order, any number of times and in any
grouping, folds to the same record. This rests on one premise: one clock identifies one
payload. That holds because:

- a device's clock is strictly monotonic and persisted before an entry leaves the
  transaction that made it;
- the clock carries the device id;
- the relay refuses a resent clock that carries another payload.

**Tombstones win over concurrent edits.** Two kinds of entry can be concurrent with a
delete, and neither writes `deleted_at`:

- an edit made without knowing about the delete, because its diff has no change there;
- a create, because a create never writes `deleted_at`. Examples are the same id created
  on a device that never saw the delete, and a singleton id such as settings, or a seeded
  category, created on two devices.

However late such an entry's clock is, the entity stays deleted. Its other fields still
apply, so a later restore shows them. Only an `update` writing `deleted_at: null` with a
clock greater than the tombstone's restores the entity. A delete-versus-restore race
resolves by clock. The join argument above is unaffected: a create simply does not touch
the tombstone register. Put independently of merge, the rule is that an entity is deleted
exactly when the greatest-clock non-create write to `deleted_at` is non-null. The
simulation and the property test check that rule directly.

## Diff

`diff(type, id, before, after, hlc)` returns the entry for a local edit, or null when
nothing changed.

- **Fields** are the union of both maps' top-level keys. A key missing from one map counts
  as null there, so removing a key writes it as null. Values are compared with deep
  equality: maps by key, and lists in order, so a reordered `tags` is a change. A value
  that is not JSON is an `ArgumentError`.
- **Operation**:
  - `create` when `before` is null. The payload is all of `after` except `deleted_at`.
    An empty `after` is an `ArgumentError`, because the relay would refuse such an entry
    forever. So is a non-null `deleted_at`, because a new entity is not born deleted.
  - `delete` when `deleted_at` goes from null to non-null. The payload is the changed
    fields, and its `deleted_at` is the entry's wall instant (`hlc.wall` written by
    `UtcInstantConverter`), whatever the host put there.
  - `update` otherwise. A restore is an update with `deleted_at: null`.
- **`before` is the snapshot the edit started from, not the stored record.** A field the
  user did not touch is left out, so a remote change merged while the edit screen was open
  is not reverted.
- The entry's `deviceId` is the clock's node id, and `synced` is false.

## The store

`SyncStore` is implemented by the host: the app over the Drift database, the server over
SQLite, and `InMemorySyncStore` for tests and the simulation.

| Method | Contract |
|---|---|
| `transaction(body)` | All-or-nothing and serialized. If `body` throws, every write made inside it is discarded and the error rethrown. No other transaction's reads or writes interleave with it. A call inside `body`, a nested `transaction` included, joins it. A call outside any transaction is atomic on its own. |
| `read(type, id)` / `write(record)` | The device's records by `(type, id)`. |
| `append(entry)` | Adds a local entry to the outbox, unsynced. |
| `unsynced({limit})` | Up to `limit` unsynced outbox entries, in clock order. |
| `markSynced(hlcs)` | Marks the entries the relay accepted. Clocks are unique per device, so a clock identifies an outbox entry. |
| `markRejected(hlcs, reason)` | Takes entries the relay refused for good (`invalid`, `conflictingDuplicate`) out of the outbox. The store keeps them with the reason, for the host to inspect, and `unsynced` never returns them again. |
| `pullCursor()` / `savePullCursor(seq)` | The relay `seq` pulled up to (null before the first pull). |
| `lastClock()` / `saveClock(hlc)` | The persisted `HlcClock.last`. |

The transaction is what keeps local edits and pulls safe:

- A local edit's record and its outbox entry are written together. Without that, a crash
  between the two would leave a change that never syncs.
- A pull's read-merge-write never interleaves with a local edit to the same record.
  Otherwise the pull could write back a stale read and lose the edit locally while the
  outbox still sends it.

The in-memory store's rollback tests (`test/in_memory_sync_store_test.dart`) are the
reference behaviour for any implementation. Drift's `transaction` meets the contract.

## The relay

`SyncRelay` is the dev server's `/sync` endpoints (lane 2d), or `InMemorySyncRelay`.

- **`push(entries)`** returns `PushResult`: the `accepted` clocks and the `rejected` ones,
  each with a `PushRejectionReason`.
  - `clockDrift`: the entry's wall time is more than an hour ahead of the relay's clock.
    This is transient: the entry stays in the outbox and is retried later.
  - `invalid`: the clock's node is not the entry's device, the payload is empty, or a
    delete has no `deleted_at` instant. This is permanent.
  - `conflictingDuplicate`: another payload is already stored under this device and clock.
    This is permanent.
- **Storage.** Every accepted entry is stored once, keyed by `(device_id, hlc)`, under a
  monotonically increasing `seq`. A resent identical entry is accepted again and gets no
  new `seq`. This is what makes a lost push response harmless.
- **`pull(since:, limit:, deviceId:)`** returns `PullPage`: up to `limit` entries with a
  `seq` greater than `since`, in `seq` order. The pulling device's own entries are left
  out. `nextSince` is the cursor for the next pull: the position just before the next
  entry the caller will receive. It can lie past the caller's own entries, which are never
  returned:
  - while `hasMore`, it is just before the next entry from another device;
  - otherwise it is the relay's last `seq`;
  - it is the request's `since` when the relay holds nothing after it.

  A `since` past the relay's last `seq` throws `SyncCursorInvalidException` (`409
  sync_cursor_invalid` from the server); see **The host's responsibilities**.

  The server relay (lane 2d) is held to this rule. The cursor is a `seq`, never a clock, because device clocks do not
  order the stream (`GET /sync/pull?since=<seq>` in the contract). Merge tolerates a device
  receiving its own entries anyway: they are idempotent.
- **Wire form.** `InMemorySyncRelay` keeps entries as JSON text and decodes them on pull, so
  tests cross the same wire form as the server. `entries` and `fold()` (every entry merged
  in `seq` order) are its reference views.

## Local edits

`LocalEditor(store, clock).recordChange(type, id, before, after, nowWallMillis)` is what
the app's repositories call for a change to user-authored data. In one store transaction
it:

1. stamps a clock with `send` and saves the clock;
2. diffs the change;
3. merges the entry into the stored record (so the local record is exactly what merging
   the entry gives on any other device) and writes the record;
4. appends the entry to the outbox.

It returns the entry, or null when nothing changed. A failure leaves neither the record
nor the entry.

## The session

`SyncSession(store, relay, clock, nowWallMillis:)` has one method, `run()`, which returns a
`SyncReport`: counts, rejections, `changed` (the `(type, id)` keys whose records changed,
for the host to react to) and `pullBlockedBy`.

1. **Push.** `unsynced(limit: 200)`, push, and repeat until the outbox is empty. Each
   entry has one of three fates:
   - **accepted**: `markSynced`, counted in `pushed`;
   - **rejected for good** (`invalid` or `conflictingDuplicate`): `markRejected`, so it
     leaves the outbox and never blocks the entries behind it. The push continues with
     the next batch;
   - **rejected for drift** (`clockDrift`): it stays unsynced, and the push phase ends for
     this run. It is offered again on the next run, and heals once real time catches up.

   Every rejection is listed in `SyncReport.rejected` with its reason. An entry that is
   rejected for good has already changed its own device's record, so that device keeps a
   value nobody else will see. Only a producer bug can cause this, because `LocalEditor`
   never builds such an entry, and the host should surface it.
2. **Pull.** From the saved cursor (0 when there is none), pull pages of 200 with the
   device's own id. Each page is one store transaction: receive every entry's clock,
   merge, write each changed record, then save the clock and the cursor. Repeat until
   `hasMore` is false.
3. **Drift.** Before applying a page, every entry is checked with `checkDrift`. If one is
   too far ahead of the device's clock, none of the page is applied, the cursor stays
   before it, and the report carries the `ClockDriftException`. A later run applies the
   page once the device's clock has caught up.

Failures, and why a rerun is always safe:

- **A push that throws** leaves its entries unsynced. The relay accepts a resent entry
  idempotently, including when it had stored the entry and only the response was lost.
- **A pull or a page transaction that throws** keeps the last saved cursor. Earlier pages
  stay applied, and a re-pulled page merges idempotently.
- A store or relay error propagates out of `run()`. Whatever was saved before it stays
  saved. `SyncCursorInvalidException` propagates unchanged too, for the host to reset
  the cursor.
- A call to `run()` while a run is in flight returns that run.

## The host's responsibilities

- **Filter Plaid-sourced rows** before `recordChange`, by `source`, in the app's
  repositories (see the top of this file).
- **Share one `HlcClock`** between the device's `LocalEditor` and `SyncSession`, and
  resume it at startup with `HlcClock(deviceId, last: await store.lastClock())`.
- **Implement `SyncStore.transaction`** to the contract above. Drift's `transaction` does.
- **Run `SyncSession.run()`** when there is network, and react to `SyncReport.changed`.
  Surface `pullBlockedBy` and any rejection that is not drift, and let a user or a log
  inspect the entries the store kept as rejected.
- **Handle a relay whose log was reset.** If the relay was wiped (for example a
  development server deleted), a pull from a cursor past the end of its log throws
  `SyncCursorInvalidException`, which carries `since` and the relay's last `seq`. The dev
  server answers it as `409 sync_cursor_invalid`, and the host's relay client maps that
  response to the exception. `SyncSession.run` lets it propagate unchanged. The host
  catches it, calls `savePullCursor(0)` and runs the session again. Merge is idempotent,
  so a full re-pull is safe.

## Testing

| Suite | What it proves |
|---|---|
| `test/hlc_clock_test.dart` | Every branch of Figure 5 with hand-computed values; the Figure 4 loop, where `c` resets once `pt` passes `l`; Theorems 1 and 2 on seeded random traces; counter overflow; drift; a backwards wall clock. Figure 6's printed values are inside the figure graphic and are not reproduced. |
| `test/diff_test.dart`, `test/merge_test.dart` | Classification; a create carries no `deleted_at`, and empty or deleted creates are refused; nested values replaced whole; delete versus edit in both orders; delete versus restore; a create concurrent with a delete, which stays deleted; a create carrying `deleted_at` from another producer, which is ignored; a create arriving after its own updates; duplicate creates; idempotent reapplication. |
| `test/merge_property_test.dart` | Random entry sets folded in random orders, duplications and groupings all equal a brute-force oracle (`test/support/oracle.dart`), and agree with the tombstone rule checked on its own, 5000 cases. |
| `test/in_memory_sync_store_test.dart`, `test/in_memory_sync_relay_test.dart` | The store and relay contracts. |
| `test/local_editor_test.dart`, `test/sync_session_test.dart` | The edit path; batching; the three fates of a pushed entry (permanently rejected entries leave the outbox and do not block the good ones; drift waits); a create on an offline device after another device's delete, which stays deleted everywhere; a relay reset, recovered by resetting the cursor; push failures before storing and after storing; a pull failing on a later page; a crash between pages; a re-pulled page; the drift block; own entries excluded, or harmless when a relay does not filter them. |
| `test/simulation/` | The multi-device simulation, below. |

**The simulation** (`test/simulation/harness.dart`) runs 4000 scenarios in the normal test
run. That takes about 15 seconds on the development machine, and the whole package about
16. Each scenario has:

- three to eight devices, with clock skews up to ±5 minutes plus jitter;
- a shared id space over a random choice of entity types, with creates, nested-value
  updates, deletes and restores, some made from stale snapshots;
- random sync rates, with some devices offline until the end;
- interleaved sessions, and edits that land during their own device's session;
- injected lost requests, lost responses and failed store operations;
- restarts that resume the clock from the store, replays of old pushes, and a wall clock
  that jumps back by up to ten minutes.

After a final round without faults, the simulation checks:

- every device is byte-identical to every other and to the relay's fold;
- the fold equals the oracle;
- every device agrees with the tombstone rule, checked independently of merge;
- the relay holds exactly the entries the devices produced, once each;
- each device's clocks strictly increase;
- a local edit is visible as soon as it is recorded.

Virtual time and one seeded `Random` per scenario make every run deterministic.

## Commands

All commands run in `packages/sync_engine` unless noted.

| What | Command |
|---|---|
| Run the package's tests | `tools/run_tests.sh packages/sync_engine` (at the root) |
| More simulation scenarios | `SYNC_SIM_SCENARIOS=20000 dart test test/simulation` |
| Another simulation seed | `SYNC_SIM_SEED=7 dart test test/simulation` |
| Replay the scenario a failure names, with its trace | `SYNC_SIM_SEED=<seed> SYNC_SIM_SCENARIO=<n> dart test test/simulation` |
| Another seed for the clock and merge property tests | `SYNC_ENGINE_SEED=7 dart test` |
