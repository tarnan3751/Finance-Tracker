# Net worth

The observed history of every account's balance, from which the net worth series is
computed. This file covers the data half: the daily balance snapshots and their writer.
The series, the pre-install reconstruction and the screens are Phase 6b's. The decisions
are `PLAN.md` §12, "Balance snapshots and net worth" and "6a plan rulings".

Code: `app/lib/features/net_worth/` (`domain/balance_snapshot_repository.dart`, `data/`
the Drift, in-memory and demo repositories, `application/snapshot_writer.dart` the
writer and its runner); `shared_models`' `BalanceSnapshot` (`core.md`); the
`balance_snapshots` table (`data.md`); `app_meta` `snapshots_written_on`.

Tests: `app/test/contract/balance_snapshot_repository_contract.dart` (run by
`app/test/features/net_worth/data/`), `app/test/features/net_worth/application/
snapshot_writer_test.dart`, `app/integration_test/investments_snapshots_test.dart`, the
schema 10 to 11 group of `app/test/drift/migration_test.dart`.

## The snapshots

One `BalanceSnapshot` per account per local date (the device's zone, `PLAN.md` §6.8):
`current`, `available` and `limit` (null when not reported) in the account's currency,
in the app's sign, and `source`. They are per device: never recorded or synced, and the
history of an account that goes stays.

`BalanceSnapshotRepository`, in Drift, in-memory and demo implementations under one
contract suite: `watchAll()` (by date, then account), `watchByAccount(id)` (by date),
`latestDate()`, and `writeDay(date, snapshots)`, which replaces every row of that date in
one write and never touches another date; a snapshot of another date or two of one
account is an `ArgumentError`, and an available balance or limit in another currency
than the current one a `CurrencyMismatchException`, before anything is written.

## The writer

`SnapshotWriter.write(today, firstOfDay:)` writes today's row for every live account:

- `current` is the balance the account is shown with (`shownBalance`, `accounts.md`):
  the reported balance, else the one derived from its transactions. A reported
  investment balance already includes the holdings (Plaid's `balances.current` is the
  total), so only an investment account with no reported balance adds its holdings'
  `institution_value` to the cash its transactions give.
- `available` and `limit` are the account's reported ones.
- `source`: `manual` for an account with no Item; for a linked one `demo` in the demo
  flavor or when any of its stored rows (its newest transactions, its holdings, its
  liabilities) is `demo`, else `plaid`. `Account` has no source of its own; adding one is
  later scope.

It writes nothing when a later day than today is stored (the device's clock moved back),
and a first-of-day write writes nothing when `snapshots_written_on` already says today
and today's rows are stored (rows gone with their store, as on the demo's persona
switch, are written again). Every other write replaces today's rows, so they follow the
day's pulls.

`snapshotWriterRunnerProvider` runs it for the clock's date when the write runs (so a
pull that lands just after local midnight writes the new day, before `todayProvider`
ticks): a first-of-day write when built and whenever `todayProvider` moves to a new local
day, and a replacing write after every whole Plaid pull (`PlaidPull.completed`, whoever
started it) and every sync session (a new `lastSyncAt`), one write at a time; a failure
is logged by type and never stops the next write. Its state is the last
day it wrote. Nothing runs unless something listens: `bootstrap` does, after the first
frame, in every flavor. The demo's snapshots start empty with each persona and the
runner writes the launch day's, `demo` and `manual`.
