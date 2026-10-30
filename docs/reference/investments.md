# Investments

The holdings, securities and investment transactions of the user's linked investment
accounts, as Plaid's Investments product reports them. Server-authoritative, never
synced. The decisions are `PLAN.md` §12, "Investments in the app" and "6a plan rulings".
The Investments segment that shows them is Phase 6e's; this file covers the data.

Code: `app/lib/features/investments/` (`domain/` the repository interfaces and
`HoldingView`, `data/` the Drift, in-memory and demo repositories, `application/` the
providers); `shared_models`' `Holding`, `Security`, `InvestmentTransaction` and `Decimal`
(`core.md`); the `securities`, `holdings` and `investment_transactions` tables
(`data.md`); the contract's three schemas and their app-side wire classes
(`core/api/api_models.dart`); the pull's two investment steps
(`core/plaid/plaid_pull.dart`); the demo mapping (`core/db/demo_seed.dart`).

Tests: `app/test/contract/holding_repository_contract.dart` and
`investment_transaction_repository_contract.dart` (run by
`app/test/features/investments/data/`), the investments group of
`app/test/core/plaid/plaid_pull_test.dart`, `app/test/core/api/fake_dataset_test.dart`,
the investment objects' case of `app/test/core/api/fake_contract_test.dart`,
`app/integration_test/investments_snapshots_test.dart`; on the server, the flow tests in
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
is `watchByAccount`.

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
