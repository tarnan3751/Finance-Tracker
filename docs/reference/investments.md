# Investments

The holdings, securities and investment transactions of the user's linked investment
accounts, as Plaid's Investments product reports them. Server-authoritative, never
synced. The decisions are `PLAN.md` §12, "Investments in the app" and "6a plan rulings".
This file covers the data and the Investments segment that shows them (**The segment**).

Code: `app/lib/features/investments/` (`domain/` the repository interfaces,
`HoldingView` and the allocation and gain (`allocation.dart`), `data/` the Drift,
in-memory and demo repositories, `application/` the providers, `presentation/` the
segment); `shared_models`' `Holding`, `Security`, `InvestmentTransaction` and `Decimal`
(`core.md`); the `securities`, `holdings` and `investment_transactions` tables
(`data.md`); the contract's three schemas and their app-side wire classes
(`core/api/api_models.dart`); the pull's two investment steps
(`core/plaid/plaid_pull.dart`); the demo mapping (`core/db/demo_seed.dart`).

Tests: `app/test/contract/holding_repository_contract.dart` and
`investment_transaction_repository_contract.dart` (run by
`app/test/features/investments/data/`), the investments group of
`app/test/core/plaid/plaid_pull_test.dart`, `app/test/core/api/fake_dataset_test.dart`,
the investment objects' case of `app/test/core/api/fake_contract_test.dart`,
`app/integration_test/investments_snapshots_test.dart`; for the segment,
`app/test/features/investments/domain/allocation_test.dart`, the screen tests and goldens
light and dark at text scale 1 and 2 in `app/test/features/investments/presentation/` on
`test/helpers/investment_seed.dart`, the investments entries of
`app/test/accessibility_test.dart`, and on the harness
`app/integration_test/investments_view_test.dart` (the renter's empty state, then the
family's 401k in the demo flavor); on the server, the flow tests in
`server/test/plaid_flow_test.dart` and the sign assertion in
`server/test/http_plaid_client_test.dart`.

## The model

- A **`Holding`** is one account's position in one security, keyed by the two:
  `quantity` and `institutionPrice` are `Decimal`s (exact, their scales kept), and
  `institutionValue` and `costBasis` (null when not reported) are the institution's
  `Money` totals, never computed from the price. `institutionPriceAsOf` is the price's
  date.
- A **`Security`** is keyed by its id (Plaid's `security_id`, unique within the server's
  list, which de-duplicates by id): name,
  ticker, Plaid's `type` kept open (`equity`, `etf`, `mutual fund`, `cash`, ...),
  `isCashEquivalent`, and its `closePrice` (`Decimal`) on `closePriceAsOf`, in
  `currencyCode`.
- An **`InvestmentTransaction`** is keyed by the server's id: Plaid's `type` and `subtype`
  kept open (`buy`, `sell`, `cash`, `fee`, `transfer`, ...), `quantity` and `price`
  (`Decimal`s), the cash `amount` in the app's sign (negative for money out of the
  account's cash, as a buy; positive for money in, as a contribution: the server negates
  Plaid's, `api.md`, **Balance signs**), `fees`, the server's `deletedAt` tombstone and
  `syncVersion`.

Each carries `source`: `plaid`, or `demo` from the fake Plaid client or the demo flavor,
as the server stored it (the contract carries it since 0.5.0). Quantity history over
time is later scope; value history comes from the balance snapshots (`net-worth.md`).

## The pull and the repositories

After the liabilities, the Plaid pull (`sync-app.md`, **The Plaid pull**) fetches `GET
/investments/holdings` and replaces every holding and security with the server's in one
store transaction, then pages `GET /investments/transactions` from its own cursor,
`plaid_investment_transactions_since`, each page and its cursor one store transaction,
restarting from 0 once when the cursor is past the server. Each list fails alone, logged
by its type, and fails neither the run nor the other lists.

| Interface | Methods |
|---|---|
| `HoldingRepository` | `watchAll()` (each holding with its security as a `HoldingView`, null when the server did not list it; by account, then security name, else ticker, else id, ignoring ASCII case, then security id), `watchByAccount(id)`, `applyPlaid(holdings, securities)` (the full replace) |
| `InvestmentTransactionRepository` | `watchByAccount(id)` (live rows, newest date first, then id descending), `applyPage(page)` (rows replaced by id; a tombstone kept and left out of the list; a later live row brings it back) |

Both refuse, before writing anything, a record that is not `plaid` or `demo` or a repeated
key (`ArgumentError`), and amounts in two currencies (`CurrencyMismatchException`); both
record nothing. `holdingsProvider` is `watchAll()`; `investmentTransactionsProvider(accountId)`
is `watchByAccount`; `investmentAccountsProvider` is the live investment accounts that
are not hidden, in display order; `investmentValueHistoryProvider(accountId)` is the
account's balance snapshots (`net-worth.md`).

## The demo

`demoHoldings(seed)` and `demoInvestmentTransactions(seed)` (`core/db/demo_seed.dart`) map
the persona engine's brokerage (`persona.md`; only the family has one, so the default
renter demo has none) to the contract's objects, `demo`: each position on the as-of date,
its `quantityMilli` as a `Decimal` of three places, its price, value and cost as the engine
reports them; each security an `etf` (VTI, VXUS, BND; the engine carries no type) with id
`demo-security-<ticker>`, closing at the as-of price; each contribution a `cash`
`contribution` of money in and each purchase a `buy` of money out, with its security,
quantity and price. The demo repositories and `FakeDataset.fromDemoSeed` both start from
the mapping. The investment account itself reports its total, the holdings' value plus
its cash, as Plaid's current balance does.

## The segment

`InvestmentsView` (`presentation/investments_view.dart`; const, no arguments, no
Scaffold) is the body of the Insights tab's Investments segment, `/investments`
(`PLAN.md` §12, "Investments in the app", "Insights tab"; `app-core.md`, **Routing and
the shell**); `InvestmentsScreen`, a thin Scaffold titled "Investments" with no route,
serves the tests. It shows, for the investment accounts (`investmentAccountsProvider`),
with the empty state ("No investment accounts") when there are none:

- the **allocation**: every shown account's holdings by security type, one per currency
  of their values (headed "Allocation in USD" when there is more than one). A holding is
  allocated under "Cash" when its security is a cash equivalent, else under its
  security's type (Plaid's open string, trimmed and lower-cased, shown title-cased:
  "Mutual Fund"; "ETF" for `etf`), "Other" with no type or no security
  (`allocationOf`, `allocation.dart`); each type's value is the sum of its holdings'
  `institutionValue`. A donut (fl_chart; the positive slices drawn, the total in its
  middle) read by a screen reader as one summary (the total, how many types, the largest
  with its share), and its table, the equivalent and the legend: a swatch, the type, its
  share (whole percent, truncated) and its value, each row one semantics node;
- then each account in display order: its name and balance, labelled "reported" or
  "from transactions" as the accounts screens label it (`shownBalance`, `accounts.md`);
- its **value over time**: the account's balance snapshots in its currency, captioned
  "From install day: recorded on this device since" the first one, as a line
  (`value_history.dart`: days from the first snapshot along the x axis, so a day with no
  snapshot is a gap the line spans; a dot on the latest; the first and last dates
  below; a tooltip on touch) read as one summary (the first and latest values and dates),
  or, with the Table switch, its table, a row per recorded day newest first. Sandbox and
  demo prices do not move, so their lines are flat; the demo's snapshots start on the
  launch day, so its line is one point;
- its **holdings**, in the repository's order (`HoldingRow` in `investment_rows.dart`):
  the security's name (else its ticker, else "Unknown security"), the ticker, the
  quantity at the price ("12.500 at 245.10 USD": each `Decimal`'s canonical string,
  every scale digit kept, the price with its currency code, never a `double`),
  the value, then the cost basis and the gain (value less cost basis, with its percent
  of the cost basis, whole and truncated, when the cost basis is positive) or "Cost basis
  unavailable" when the institution reports none, and the price's date; each holding one
  semantics node;
- its **investment transactions**, newest first (`InvestmentTransactionRow`): the name,
  the amount in the app's sign, the date and the type title-cased with its subtype when
  it says something else ("Cash · Contribution", "Buy"), the quantity at the price when
  the row has a security, and the fees when reported; ten at first
  (`investmentTransactionsPage`), "Show more (N left)" adding ten each time.

The value history and the transactions show a progress indicator while their streams
load and the shared "could not load" line when one fails, never their empty texts. Each
account's section is keyed by the account, so its Table switch and its page follow it.
The allocation's colours are the scheme's primary, tertiary, secondary, inverse primary
the containers and the outline, never the error colour, so no slice reads as a loss.

fl_chart places marks by `double` values, which serve placement only: every amount on
screen, in a tooltip or in a summary is the `Money` formatted through intl.
