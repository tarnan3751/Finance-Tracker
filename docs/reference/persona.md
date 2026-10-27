# Persona engine

The single source of synthesized financial life (`PLAN.md` §7.1). Code:
`tools/persona_engine/`, a pure Dart workspace member (VM only) that depends on
`shared_models`. One persona, one seed and one window give one household, written three
ways:

1. the **demo seed** the demo flavor loads, with `source: demo` on every record, with the
   whole window;
2. **Plaid Sandbox custom users**, one per institution, for `/sandbox/public_token/create`,
   each carrying the newest history that fits one request;
3. the **Sandbox manifest**, which says per Item what the custom user carries and what it
   leaves out.

The engine never calls Plaid. The development server's provisioning job provisions a
persona into Sandbox from these outputs through the engine's Dart API, driven by
`tools/scripts/provision_persona.sh` or the developer menu (`docs/reference/server.md`,
**Provisioning**); against real Sandbox only the coordinator runs it.

## Using it

```dart
import 'package:persona_engine/persona_engine.dart';

final seed = generateDemoSeed(PersonaId.family, 1, LocalDate(2026, 10, 24));
seed.household.transactions; // List<Transaction>, every one source: demo
```

```
dart run persona_engine --persona <renter|family|student|small_business> --seed <int>
    --output <dir> [--format demo|sandbox-user|all] [--days 730]
    [--as-of 2026-10-24] [--no-interest-legs]
```

The CLI writes into `<dir>/<persona>/`: `demo_seed.json` (`--format demo`), and
`sandbox_user_<institution>.json` with `sandbox_manifest.json` (`--format sandbox-user`).
The window is the `--days` (1 to 730) ending on `--as-of`: the persona's history, which the
demo seed carries whole and a Sandbox custom user only as far as it fits (**What Sandbox
receives**). The as-of date defaults to the goldens' date, never today: the engine reads
no clock.

## Determinism

- **PRNG.** The engine has its own PCG32 (`lib/src/random/pcg32.dart`), as O'Neill's
  reference `pcg-c-basic` defines it: XSH-RR output, a 64-bit state, and unbiased bounded
  draws by rejection. `dart:math`'s `Random` makes no promise across Dart versions.
  `test/pcg32_test.dart` checks the author's published `pcg32-demo` output for
  `pcg32_srandom_r(42, 54)`, rounds 1 and 5: the raw outputs, coins, dice and the card deal
  (https://www.pcg-random.org/using-pcg-c-basic.html). Dart's native `int` wraps modulo
  2^64, which is the arithmetic the reference relies on, so the package does not run on the
  web.
- **Seeding.** The root generator's state is the seed and its stream is the 64-bit FNV-1a
  hash of the persona's slug. Each component then gets a child in a fixed order: every
  income, bill, subscription and spending stream, then the brokerage, then the anomalies.
  A child is `fork(key)`, two root draws for the state and `fnv1a64(key)` for the stream, so
  tuning one stream leaves every other stream's draws unchanged.
- **Order.** Iteration follows the persona's lists. Transactions are sorted stably (by
  posting date, then emission order) before ids are assigned. JSON maps are written in
  the order the code builds them.
- **No floating point.** `Money`, integer basis points (625 is 6.25 %), per-mille weights
  and integer thousandths of a share. `test/provenance_test.dart` fails if `lib/` mentions
  `dart:math`, `double`, `DateTime.now` or `Random(` outside a comment.

## The model

A `Persona` (`lib/src/model/persona.dart`) is data: institutions (Plaid's non-OAuth test
banks), accounts (type, Plaid subtype, limit, APY, an opening balance for depository and
card accounts, and an optional `coverFrom` account that tops it up rather than letting a
day end below zero), plus lists of specs.

**A household is defined relative to its as-of date.** Loan originations and the
brokerage's opening are months before as-of, never calendar dates. Loans and the
brokerage are replayed from that start, so the household has the same shape on any
as-of date, and its state on the as-of date (principals, interest paid this year,
positions) does not depend on the window's length. Cadences stay calendar patterns, as
in life: rent on the 1st, a biweekly Friday payday counted from a fixed anchor, the
estimated-tax dates, semester starts. A loan or brokerage that would start inside the
window is refused.

| Spec | What it emits |
|---|---|
| `IncomeSpec` | An inflow on a `Schedule`, with variance; with a skip chance it is gig income and has no recurring expectation |
| `BillSpec` | A fixed outflow (rent, a utility with a seasonal curve, insurance, a quarterly tax); the `subscriptions` list uses the same type |
| `SpendingSpec` | Purchases from a merchant pool at a rate in purchases per thousand days, scaled by a weekly and a seasonal shape, posting up to N days later |
| `LoanSpec` | Replayed from origination: monthly interest charged to the loan account, then, from repayment start to maturity, the payment as a transfer from checking; a deferred loan only accrues |
| `DisbursementSpec` | A disbursement on a deferred student loan: a transfer from the loan account to checking, optionally paying tuition from checking the same day |
| `CardSpec` | Statement close, interest on a carried balance, and the payment as a transfer |
| `TransferSpec` | A fixed transfer between the household's accounts, skipped when it would leave the source below a floor, with an optional sweep above a level |
| `BrokerageSpec` | Replayed from its opening: a rollover, a daily price walk per security, and payroll-deducted contributions bought by weight |

A `Schedule` is `Weekly`, `Biweekly` (from an anchor date), `SemiMonthly`, `Monthly` or
`Yearly` (one or more month-days), each with a weekend rule: none, roll back to Friday
(payroll) or roll forward to Monday (bills). Days past a month's end clamp to its last day.

The four personas live in `lib/src/personas/`, sharing merchant pools (`merchants.dart`)
and shapes (`shapes.dart`). Raw descriptions are strings Plaid recognizes (`NETFLIX.COM`,
`WHOLEFDS MKT #10234`), each with its normalized `merchantName` and a Plaid v2 detailed
category; the primary category is looked up in `shared_models`' taxonomy, and an unknown
code is an error. Employers, landlords and servicers are fictional; the identities use
`555` numbers and `example.com` addresses.

| Persona | Institutions | Shape |
|---|---|---|
| `renter` | Platypus | Weekly gig payouts that sometimes skip, six subscriptions, a card paying 75 % of each statement and carrying the rest with interest, a small savings account |
| `family` | Platypus, Tartan, Gingham, Tattersall | Two salaries (biweekly, semi-monthly), a mortgage (at Tattersall), two auto loans (at Gingham), a 401(k) fed by payroll (at Tartan), childcare and kids' spending, a card paid in full |
| `student` | Platypus, Gingham | Undergraduate loan in repayment, graduate loan in deferment disbursed each semester with tuition paid the same day, a campus job, irregular tutoring, a monthly transfer from a parent, thin spending |
| `small_business` | Platypus, Gingham | Stripe payouts and a retainer into business checking, a business card, quarterly estimated taxes, owner's draws into personal checking |

## The day walk

`generateHousehold` (`lib/src/generate/generator.dart`) walks each day of the window in a
fixed order:

1. the price walk;
2. income;
3. loans: a disbursement (and the tuition it pays), then a due date;
4. bills and subscriptions;
5. card payments due, then statement closes;
6. transfers and sweeps;
7. brokerage contributions;
8. spending;
9. the planted anomalies;
10. month-end savings interest;
11. cover transfers.

Every movement goes through the `Ledger`: `post` for one account, `transfer` for two of
the household's accounts, whose legs are one value negated, on one date, recorded as a
`TransferPair`. A posting date past the as-of date is clamped to it, so nothing is
pending and no date is in the future.

- **Balances are never stored.** Each account has an `OpeningBalance` for the day before
  the window. It is not a transaction. It is the persona's figure for depository and card
  accounts, the amortized balance for a loan, and the uninvested cash for an investment
  account, whose positions that day are `openingHoldings`. A non-investment account's
  `currentBalance` is its opening plus its transactions. The generator recomputes the sum from the entries and throws if it
  differs. The demo plays the institution: accounts belong to demo Items
  (`demo-item-<persona>-<institution>`, `healthy`) at Plaid's test institutions, and report
  that derived balance with `balancesAsOf` the as-of date at 00:00Z. Available balance is
  set for depository accounts (the balance) and cards (limit minus owed).
- **Loans.** Each due date after origination charges `principal x APR / 12`, rounded
  half-even (`monthlyInterest`), as its own transaction on the loan account.
  - From `nonRepaymentMonths` after origination to maturity, the payment is made, capped
    at what is owed, so the principal falls by the payment less the interest.
  - The payment is not a persona value. It is the smallest whole-cent amount that leaves
    nothing owed after the last due date on or before maturity, found by bisection over a
    replay of the due dates; no `pow`.
  - A paid-off loan reports zero, and nothing is paid after maturity.
  - `ytdInterestPaid` is the interest the payments covered (each payment pays the month's
    interest first) in the as-of date's calendar year, replayed from January 1 whatever
    the window. It is zero in deferment.
  - Disbursements are allowed only on a deferred loan.
- **Cards.** At close, a statement not paid in full is charged interest on the unpaid part,
  and the new statement is the balance owed. On the due date the payment is the policy's
  share of the statement, limited to what checking can spare above its floor but never
  below the minimum payment.
- **Investments.** No `Transaction` records: `InvestmentTransaction`s inside the window
  (`cash` contributions, `buy`s in thousandths of a share at the day's price) and
  `Holding`s valued on the as-of date only (`PLAN.md` §7.1, tier C). The replay from the
  opening walks prices every day, so positions and prices on any date are the same
  whatever the window. The account's balance is the holdings' value plus uninvested cash.
- **Shapes.** A spending stream's daily rate is `rate x weekly[weekday] x
  seasonal[month] / 10^6`, in purchases per thousand days. The whole thousands are
  certain; the remainder is one more purchase with that chance.
- **Anomalies.** Each 365-day block gets two or three, a shorter final block its share:
  either a usual merchant at four to eight times its usual maximum, or a new merchant.
  - New merchants come from a pool that shares no merchant name or raw description with
    the household's regular pools, payees and subscriptions; the generator refuses a
    persona that breaks this.
  - They are drawn without replacement, so each appears exactly once in the household.
    Once the pool is used up, the rest are unusual amounts.
  - They are listed in `anomalies` as ground truth for the insights feature.
- **Recurring expectations.** Regular income, bills, subscriptions and loan payments are
  listed in `recurring` with their schedule, tolerance (two days under a weekend rule, else
  zero) and amount range. They are the engine's own records, the ground truth of the
  app's detector; the app turns each into a `demo` `RecurringStream` for its demo flavor
  and in-app fake (`recurring.md`, **The demo**), and the engine's liabilities into the
  contract's liability objects (`liabilities.md`, **The demo**). The engine's own
  `Liability` shares its name with `shared_models`' entity, so its libraries that use it
  hide the shared one.

Ids are `demo-<persona>-<account>` for accounts, `demo-<persona>-t000001` onward for
transactions in date order, and `demo-<persona>-i000001` onward for investment
transactions. Audit fields are the posting date at 00:00Z, and `syncVersion` is 0.

## The demo seed

`DemoSeed.toJson()` holds the household's `shared_models` entities in their own JSON
(amounts as `{minor_units, currency}`): institutions, items, accounts and transactions.
Next to them are the package's own records: opening balances, transfers, recurring
expectations, holdings, investment transactions, liabilities and anomalies. The app calls
`generateDemoSeed` directly, with seed 1 as of the device's today, for the persona the demo
flavor shows (`data.md`, **The demo seed**); the JSON is for inspection and the goldens.

## Sandbox custom users

Each institution is one Item and one custom user, `sandbox_user_<institution>.json`, in
Plaid's documented `UserCustomPassword` schema (https://plaid.com/docs/sandbox/user-custom/;
`override_username: user_custom`, the configuration stringified as `override_password`,
per https://plaid.com/docs/api/sandbox/#sandboxpublic_tokencreate):

- Top level: `version: 2`, a `seed`, `roll_dates_forward: false` and `override_accounts`.
  No `inflow_model`, which would add Plaid's own transactions. No `mfa` or `force_error`.
  The dates are the generator's; the provisioning job shifts them (**Dates in
  Sandbox**, below).
- Account fields:
  - `type`, `subtype`, `starting_balance` and `currency`;
  - `meta` (`name`, `official_name`, `mask`, `limit` on cards, `apy` on savings);
  - `identity` on every account. Plaid fills any account's unspecified identity fields
    with its defaults; only the names are shared across an Item;
  - `transactions` (`date_transacted`, `date_posted`, `amount`, `description`,
    `currency`);
  - `holdings` and `investment_transactions` on investment accounts: the newest 60 buys,
    since the holdings carry the whole position;
  - **Products by institution.** Each institution's accounts need only the products
    Sandbox grants it (verified 2026-10-24, `PLAN.md` §4): First Platypus Bank, First
    Gingham Credit Union and Tartan Bank support `transactions`, `liabilities` and
    `investments`; Tattersall Federal Credit Union supports `transactions` only. So no
    persona puts a card, a student loan or an investment account at Tattersall; the
    family's mortgage is there, and its 401(k) at Tartan.
  - `liability`: `credit` for cards and `student` for student loans, and **no other
    loan kind carries one**. A mortgage has none ("Mortgages are not currently supported
    in the custom Sandbox"), and an auto loan has none because a block of `type: loan`
    makes `/sandbox/public_token/create` answer 500 `INTERNAL_SERVER_ERROR` (verified
    against Sandbox on 2026-10-24 by bisection: the same configuration without the block
    is accepted; `PLAN.md` §4). The demo seed keeps every liability.
- **Signs.** In Plaid's convention positive is money out, so `amount` is the domain amount
  negated. `starting_balance` is the balance on the as-of date: money held for depository
  and investment accounts, money owed (positive) for cards and loans.
- **Numbers.** Every number is written by `writeJson` from a `JsonDecimal`, whose text
  comes from `Money.toDecimalString()` or an integer scale. A `double` is refused.
- **Limits.** At most ten accounts, and at most `sandboxConfigByteBudget` (90,000) bytes
  in the request (**What Sandbox receives**). The files are written indented for review;
  the size is measured on what the request carries.

## What Sandbox receives

A Sandbox Item's history is its custom user's transactions and nothing more. Two facts,
verified against Sandbox on 2026-10-25 (`PLAN.md` §4), make it so:

- `/sandbox/transactions/create` accepts rows dated up to two years back, but
  `/transactions/sync` serves an injected row only when it is dated Plaid's today. Older
  injected rows answer 200 and never arrive, so the engine writes no injection batches and
  the provisioning job injects nothing. The developer menu still injects "a transaction
  arriving now".
- `/sandbox/public_token/create` refuses a request over 100,000 bytes (`INVALID_BODY`
  "maximum content length 100000 bytes"). A configuration's rows two years old do arrive,
  but a persona's whole two years do not fit: the family's Platypus history is about
  286 KB compact.

So each custom user carries **the newest whole days that fit** (`splitForSandbox`, with
`sandboxUsers` supplying the measure). Per institution the candidates are its accounts'
transactions (less the interest legs under `--no-interest-legs`). The cut takes the most
newest days whose configuration stays within `sandboxConfigByteBudget`, 90,000 bytes, by a
binary search over day boundaries (a configuration grows with every row). A day is kept or
left out whole, so no day is half-recorded. The size is `sandboxRequestBytes`: the UTF-8
length of the compact configuration written as a JSON string, the form
`override_password` takes in the request. Escaping adds about 14 % (each quote gains a
backslash), and the 10,000 bytes left under Plaid's limit hold the request's other fields
(keys, institution, products, options), which come to under 1 KB. Rows are not shortened:
the JSON is already compact, and the descriptions and fields are what Plaid reads.

The cut depends only on the persona, the seed, the as-of date, the window and the budget.
The older rows are left out: not injected, only counted in the manifest. At seed 1 over
730 days the large Items carry about 600 rows (renter Platypus from 2026-03-09, 230 days;
family Platypus from 2026-04-05, 203 days); the small Items (the family's Gingham and
Tattersall, the student's Gingham) carry their whole history. The demo seed always
carries the whole window, so features that need two years of bank history are exercised in
the demo flavor, and in dev on the days Sandbox holds (`PLAN.md` §7.1).

**Each Item is cut on its own.** A transfer whose legs sit on two of the household's Items
(a loan payment from checking at another bank) can therefore reach Sandbox with one leg
only, for the days before the shorter Item's first carried day. In the family at seed 1,
the auto-loan payments received at Gingham and the mortgage payments received at
Tattersall before 2026-04-05 are in Sandbox, while their outflows from the Platypus
checking account are not, since Platypus carries from that day. This is deliberate: the
loan Items keep their whole two years rather than every Item being cut to the shortest
span. The demo seed keeps every pair.

**The interest switch.** `--no-interest-legs` (`includeInterestLegs: false`) leaves card
and loan interest charges out of the Sandbox outputs; the demo seed always has them.
Plaid's custom-user page says: "Note that account types supported by Liabilities will
accrue interest in the Sandbox. The types impacted are account type credit with subtype
credit or paypal, and account type loan with subtype student or mortgage." The personas'
cards are subtype `credit card` and their auto loans `auto`, so Phase 3 should expect
accrual only on the student loans and the mortgage, and none on the cards.

## The manifest

`sandbox_manifest.json` (`sandboxManifest`) records the persona, the seed, the `as_of`
date, `include_interest_legs`, the date-shift rule and `request_byte_budget`, and per Item:
its institution and Plaid institution id, its `sandbox_user_file`,
`custom_user_transactions` (the rows carried), `first_day_carried` (null when it carries
none), `days_carried` (calendar days from that day through `as_of`, inclusive: the span
Sandbox holds complete) and `transactions_left_out`. A provisioned Item's synced rows can be
checked against it.

## Dates in Sandbox

Every file holds the generator's dates, ending on the as-of date. Before any call, the
provisioning job shifts **every date of every Item of the persona by one amount**:
the Item creation date minus `as_of`. That covers the custom users' transaction,
investment, holding and liability dates. The as-of date then
lands on the creation day, and the legs of a transfer between two Items stay on one date.
The window is at most 730 days and ends on the as-of date; a row whose shifted date still
falls outside Plaid's window when its Item is linked (the oldest day of a 730-day persona
before 12:00 UTC) is dropped by the job and counted in `skipped` (`server.md`,
**Provisioning**).

The job generates at the engine's default as-of date (the goldens' date, 2026-10-24), so a
provisioned persona is the committed `days730` fixtures moved by the shift, and takes the
creation day as Plaid's today reckoned at UTC−12, a date never ahead of Plaid's in any
zone (`PLAN.md` §12). `shiftSandboxUserDates(config, days)` moves every date of a custom
user (the keys in `sandboxUserDateKeys`) and nothing else.

`PLAN.md` §7.1 says the custom users have `roll_dates_forward` on. That was changed at
implementation, and the decision is recorded in §12. With the flag on, Plaid shifts each
Item so that *its own* newest activity lands on the creation day. Items whose activity
stops before the as-of date would then move further than the others: the family's mortgage
Item, last active on the 1st, would move 23 days more than its checking account, and the
two legs of each mortgage payment would land on different dates. One shift for the whole
persona keeps the Items aligned.

## Goldens

`test/goldens/<persona>/` holds, for seed 1 as of 2026-10-24:

- `days120/`: every output over 120 days, compared byte for byte;
- `days730/`: the custom users and the manifest over the full window, compared byte for
  byte. These are the fixtures Phase 3 provisions;
- `digests.json`: the FNV-1a 64 of every full-window output, so the large demo seed is
  covered without being committed.

`tool/golden_set.dart` defines them, `test/determinism_test.dart` compares them, and
`dart run tool/update_goldens.dart` (in the package) rewrites them. A golden changes only
under a tier A brief that says so (`CLAUDE.md`, **Tiers**).

## Tests

| File | What it proves |
|---|---|
| `pcg32_test.dart` | PCG32 matches the reference output; FNV-1a matches its published vectors; bounded draws and forks |
| `schedule_test.dart` | Nominal dates, month-end clamping, the weekend rule |
| `ledger_test.dart` | Transfers are one value negated; zero, future and uncategorized entries are refused |
| `generator_test.dart` | On a fixture persona with every spec kind: the window, order, ids, closure and reproducibility; a loan's amortized opening and computed payment; a matured loan at zero; a deferred loan with its disbursements and tuition; year-to-date interest; the as-of state the same for every window; the refusals (an overlapping or repeated anomaly pool, a loan starting inside the window) |
| `personas_test.dart` | The four personas are well formed and use only non-OAuth test banks |
| `balance_test.dart` | Closure; transfer pairing; loans replayed month by month from their opening; positions are their opening plus their buys; depository accounts never end a day below zero |
| `recurrence_test.dart` | Every expectation occurs once per scheduled date within tolerance, in range, with no extras; monthly subscriptions once a month |
| `coverage_test.dart` | All 18 primary categories used; every code is Plaid v2; anomalies two or three a year, both kinds, each new merchant exactly once; weekly and seasonal shapes visible |
| `sandbox_limits_test.dart`, `sandbox_output_test.dart` | The limits, the partition, signs, starting balances, the liability blocks (none on a mortgage or an auto loan, while the demo seed keeps both), the cut (the newest whole days that fit, and one more day over the budget), the request-bytes measure, the manifest, the interest switch, the date shift moving every date and nothing else |
| `provenance_test.dart` | Every record is `demo`, in the model and the JSON; no clock, `dart:math` or `double` in `lib/` |
| `determinism_test.dart` | Same seed, same bytes; another seed differs; the goldens match |
| `property_test.dart` | Every invariant (closure, pairing, dates, the depository floor, provenance, loans, positions, anomalies, the Sandbox limits) over 100 seeds per persona; and over 15 as-of dates from 2024 to 2030 (month ends, leap days, year ends, around a semester's disbursement) times windows of 1, 2, 7, 31, 120, 365 and 730 days, which also checks that the as-of state does not depend on the window; and the Sandbox outputs over 730 and 120 days, rendered twice byte-identically and within the request budget |
| `cli_test.dart` | The command line's files and errors |

## Commands

| What | Command |
|---|---|
| Run the package's tests | `tools/run_tests.sh tools/persona_engine` |
| Explore the property tests from another seed | `PERSONA_ENGINE_SEED=5000 dart test test/property_test.dart` (in the package) |
| Write a persona's outputs | `dart run persona_engine --persona family --seed 1 --output <dir>` (in the package) |
| Regenerate the goldens | `dart run tool/update_goldens.dart` (in the package) |
