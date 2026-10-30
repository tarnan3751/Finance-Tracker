# Net worth

The observed history of every account's balance, the net worth series computed from it
with the history before it reconstructed from transactions, and the liabilities' payoff
projections, with the screen that shows them. The decisions are `PLAN.md` §7.1 (tier C),
§12 "Balance snapshots and net worth", "Payoff projections", "6a plan rulings" and "6b
plan rulings".

Code: `app/lib/features/net_worth/`:
- `domain/` (pure Dart, integer `Money` only): `balance_snapshot_repository.dart`,
  `net_worth_series.dart` (`NetWorthPoint`, the observed series), `reconstruction.dart`
  (the derived prefix, `netWorthHistory`), `payoff.dart` (the amortization and its terms),
  `payoff_entries.dart` (the user's entries);
- `data/`: the Drift, in-memory and demo snapshot repositories;
- `application/`: `snapshot_writer.dart` (the writer and its runner),
  `net_worth_providers.dart` (**Providers**);
- `presentation/`: `net_worth_view.dart` (`NetWorthView`, the headline, the range),
  `net_worth_chart.dart`, `net_worth_table.dart`, `liability_payoff_card.dart`,
  `net_worth_screen.dart` (`NetWorthScreen`).

`shared_models`' `BalanceSnapshot` (`core.md`); the `balance_snapshots` table
(`data.md`); `app_meta` `snapshots_written_on` and `payoff_entries`.

Tests: `app/test/contract/balance_snapshot_repository_contract.dart` (run by
`app/test/features/net_worth/data/`), `app/test/features/net_worth/application/`
(`snapshot_writer_test.dart`; `net_worth_providers_test.dart`, where the series the
screen reads is reproduced from the stored rows by an independent fold, and the entries'
persistence), `app/test/features/net_worth/domain/` (the series; the reconstruction,
with every walked day and every prefix day of the family persona checked against the
engine's own balances;
payoff, with the engine's loans amortized to their maturity),
`app/test/features/net_worth/presentation/` (the screen, its table's rows equal to the
rows' series, and goldens light and dark at text scale 1 and 2 on
`test/helpers/net_worth_seed.dart`), the net worth entries of
`app/test/accessibility_test.dart`, `app/integration_test/investments_snapshots_test.dart`
and `app/integration_test/net_worth_test.dart` (the demo family's history and mortgage
payoff), the schema 10 to 11 group of `app/test/drift/migration_test.dart`.

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

## The series

`observedNetWorth(snapshots, types)` (`net_worth_series.dart`) is computed from the stored
snapshots alone, one series per currency, one `NetWorthPoint {date, assets, liabilities,
netWorth, derived, carried}` per day from the first date a snapshot in that currency is
stored for to the last:

- on a day with snapshots, **assets** are the sum of that day's balances of asset accounts
  (depository, investment, other) and **liabilities** the sum of that day's balances of
  credit and loan accounts, negated. Both are signed: an overdraft lowers the assets, a
  card in credit lowers the liabilities, and net worth (assets − liabilities) is the sum
  of the day's balances exactly. An account is typed by the live accounts; a snapshot of
  one no longer live is an asset when its balance is not negative, else a liability;
- a day with no snapshot (the app did not run) carries the day before's values, with
  `carried` set: the table marks it.

An observed point carries no single `source` (its rows mix `plaid`, `manual` and `demo`);
only a `derived` one is labelled.

## The reconstruction

`reconstructedPrefix` (`reconstruction.dart`) gives the history before the series' first
day S, computed on read and never stored, every point `derived`:

- each depository or credit account with a snapshot on S is walked back from it:
  balance(d − 1) = balance(d) − the sum of its transactions dated d. Pending transactions
  are left out; hidden ones count (the money moved), both legs of a transfer count, other
  currencies and deleted ones do not. Before its earliest such transaction E the
  account holds flat at B(E − 1), the balance before its history starts (zero for a
  manual account whose first row is its opening balance, the balance before the bank's
  horizon for a linked one), and an account with no such transaction holds flat at its
  snapshot, so every walked account is present on every day of the prefix and none
  appears with a step;
- each loan, investment or other account with a snapshot on S is held flat at it (loan
  interest and prices are not in the transactions);
- an account whose first snapshot is after S has no derived history: the observed span
  stays rows only.

The prefix runs from the earliest walked transaction across the accounts to S − 1 and
joins the observed
series at S, whose point is the snapshots' own, so the two meet exactly.
`netWorthHistory` is the prefix followed by the observed series, per currency. On a
fresh install (and in the demo, whose snapshots start at launch) S is today, so the
whole of the transactions' history before it is estimated.

## Payoff

`projectPayoff(owed, rateBasisPoints, payment, extra, today)` (`payoff.dart`) amortizes
monthly in integer minor units: each month the interest is balance × rate ÷ 120000
rounded half to even once (as the persona engine charges it), the balance grows by it and
falls by the payment plus the extra, the last payment being what is left. It answers
`PaidOff(months, totalInterest, date, lastPayment)` with the date `today` plus the
months; `NeverPaidOff(firstInterest)` when the payment does not exceed the first month's
interest; `BeyondCap` past 600 months ("Over 50 years"); `NothingOwed`.

`payoffTermsOf(balance, liability, enteredRate:, enteredPayment:)` picks the inputs: what
is owed is the account's balance as shown (`shownBalance`, `accounts.md`) negated; the
rate is the liability's `interestRateBasisPoints`, else its `purchase_apr`, else its first
APR; the payment is the minimum for a card or a student loan and the next monthly
payment for a mortgage (`liabilities.md`). What the bank does not report the user may
enter; a reported value always wins.

The entries (`PayoffEntry`: a payment above zero, a rate from 0 to 100 % in basis
points, an extra not negative; anything else refused) are kept per account in `app_meta`
under `payoff_entries` as `{"<account id>": {"payment": Money, "rate_bp": int, "extra":
Money}}`, on this device only and never synced; an entry that does not read is dropped.
`payoffEntriesControllerProvider` applies the changes one at a time: the state is
updated, then written; when the write fails the state goes back and the change's Future
fails, and the card says the entry could not be saved.

## Providers

| Provider (`application/net_worth_providers.dart`) | What |
|---|---|
| `balanceSnapshotsProvider` | `BalanceSnapshotRepository.watchAll()` |
| `netWorthSeriesProvider` | `netWorthHistory` per currency from the snapshots, the live accounts' types and every live transaction (`recurringLedgerProvider`); the screen reads only this |
| `payoffEntriesControllerProvider` | The entries (**Payoff**) |
| `liabilityPayoffsProvider` | Every live credit and loan account that owes something, hidden ones included (net worth counts them), in the accounts' order, with its terms, its entry, its projection at the payment and, with an extra, at the payment plus the extra |

## The screen

`NetWorthView` (const, no Scaffold) is the body of the Insights tab's Net worth segment,
one scroll:

- the headline: "Net worth on <date>", the latest net worth, and its change against the
  point 30 days before ("…, against an estimate" when that point is derived);
- the range control (3 m, 1 y, All; a year by default) with the Table / Chart switch, and
  a chip per currency when the history holds more than one (the device's currency first
  shown when held);
- the chart (fl_chart 1.2.0): net worth, assets and liabilities, each line dashed over
  the estimated span and solid from the first snapshot, a legend with "Dashed: estimated
  from transactions", dates along the bottom, a tooltip on touch; a screen reader hears
  one summary naming the span, the first and last net worth, the last day's assets and
  liabilities and "Before <date>, estimated from transactions". fl_chart places points by
  `double` coordinates for placement only; every amount shown is a point's `Money`;
- or the table, the chart's equivalent: one row per day, newest first, with the date, the
  net worth, the assets and liabilities, and "Estimated from transactions" or "No
  snapshot this day: the day before's values", each row one semantics sentence;
- the liabilities, one card each: the name and what is owed ("Hidden account" under the
  name of a hidden one, which net worth still counts), the rate and the payment
  with where each came from, the projection ("Paid off in N months, <month>; <amount> in
  interest", "Never paid off: …" in the error colour, "Over 50 years to pay off"), Enter
  rate and Enter payment where the bank reports none (a dialog refusing what an entry may
  not hold), and an "Extra a month" slider of twenty steps up to about the payment (each
  step a twentieth of it rounded up to a whole unit) with "With <extra> more a month: N
  months sooner, <amount> less interest". The stored extra is the one source of the
  slider's position, its label and that line: when the payment changes it is snapped to
  the new steps and written back.

The empty state shows when no snapshot is stored. The Insights tab mounts the view at
`/net-worth` in its `InsightsScaffold` (`app-core.md`, **Routing and the shell**);
`NetWorthScreen` (a Scaffold titled "Net worth" around the view) serves the tests.
