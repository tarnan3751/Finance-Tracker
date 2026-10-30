# Liabilities

The liability detail of the user's linked card and loan accounts, as Plaid's Liabilities
product reports it: what bills need (the next due date, the minimum or monthly payment,
the statement, the last payment), what the payoff projections read (the rate and the
payment, `net-worth.md`, **Payoff**) and the rest Plaid reports (terms, origination,
year-to-date figures). Server-authoritative, never synced. The
decision is `PLAN.md` §12, "Liabilities in Phase 5".

Code: `app/lib/features/liabilities/` (`domain/` the repository interface, `data/` the
Drift, in-memory and demo repositories, `application/` the provider);
`shared_models`' `Liability` (`core.md`); the `liabilities` table (`data.md`); the
contract's three liability schemas and their app-side wire classes
(`core/api/api_models.dart`); the pull's liability step (`core/plaid/plaid_pull.dart`);
the demo mapping (`core/db/demo_seed.dart`).

Tests: `app/test/contract/liability_repository_contract.dart` (run by
`app/test/features/liabilities/data/`), `app/test/core/api/liability_mapping_test.dart`,
the liability group of `app/test/core/plaid/plaid_pull_test.dart`,
`app/test/core/api/fake_dataset_test.dart`, `app/integration_test/items_flow_test.dart`.

## The model

A `Liability` is one account's liability of one kind (`credit`, `mortgage`, `student`),
keyed by the two. Its fields are typed and nullable, present as the kind allows:

| Kind | Fields |
|---|---|
| `credit` | `nextPaymentDueDate`, `minimumPaymentAmount`, `lastStatementBalance`, `lastStatementIssueDate`, `lastPaymentAmount`, `lastPaymentDate`, `isOverdue`, `aprs` (each `LiabilityApr`: Plaid's type, the rate, the balance it applies to) |
| `mortgage` | `nextPaymentDueDate`, `lastPaymentAmount`, `lastPaymentDate`, `interestRateBasisPoints`, `originationDate`, `originationPrincipal`, `loanTerm` (Plaid's text, `30 year`), `nextMonthlyPayment`, `ytdInterestPaid`, `ytdPrincipalPaid` |
| `student` | `nextPaymentDueDate`, `minimumPaymentAmount`, `lastStatementBalance`, `lastStatementIssueDate`, `lastPaymentAmount`, `lastPaymentDate`, `isOverdue`, `interestRateBasisPoints`, `originationDate`, `originationPrincipal`, `ytdInterestPaid`, `ytdPrincipalPaid` |

Amounts are `Money`, positive (owed, paid), in the account's currency. Rates are integer
basis points (1 % is 100): the contract carries them as `Decimal` strings, converted at
the boundary (`basisPointsOf`) and rounded half to even past the second decimal place, so
a mortgage at `3.875` is 388 bp. The whole object as the server sent it is the `payload`,
the exact rate strings and the fields not typed included, for Phase 6. `source` is `plaid`
or `demo`, as the server stored it (`/liabilities` carries it since contract 0.4.0).

## The pull and the repository

The Plaid pull fetches `GET /liabilities` once per run, after the recurring streams,
reads the three lists into entities (`Liabilities.toEntities`, the wire classes'
`toLiability`) and replaces every stored liability with them in one store transaction. A
failure is logged by its type and fails neither the run nor the stream step.

`LiabilityRepository` (`domain/liability_repository.dart`), in Drift, in-memory and demo
implementations under one contract suite: `watchAll()` (by account id, then kind),
`watchByAccount(accountId)`, and `applyPlaid(liabilities)`, the full replace, which
refuses a source other than `plaid` or `demo` or a repeated account and kind
(`ArgumentError`), or amounts in two currencies (`CurrencyMismatchException`), before
writing anything, and records nothing. `liabilitiesProvider`
(`application/liabilities_providers.dart`) is `watchAll()`.

## The demo

`demoLiabilities(seed)` (`core/db/demo_seed.dart`) maps the persona engine's liabilities
(`persona.md`) to the contract's objects, `demo`:

- a card: its statement balance and date, minimum payment, due date, last payment, and
  its rate as one `purchase_apr`;
- a mortgage: its rate (`fixed`, as the engine amortizes), term, maturity, next payment
  (the next due, else the monthly payment), due date, origination and year-to-date
  interest;
- a student loan: its name, rate, payoff date (the maturity), monthly payment as the
  minimum, due date, last payment, origination, year-to-date interest, and its status
  (`deferment` with no payment, else `repayment`).

Fields the engine does not model stay null. **Auto loans are left out**: Plaid's
Liabilities product reports credit, mortgage and student detail only (the contract has
no auto-loan schema, and a Sandbox custom user with an auto-loan `liability` block is
refused, `PLAN.md` §4), and dressing one as another kind would misrepresent it. The demo
repository and `FakeDataset.fromDemoSeed` both start from the mapping.
