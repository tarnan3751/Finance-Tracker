# Reports and insights

The reports: spending and income by period, by category and by merchant, the savings rate,
comparisons with the period before and the year before, the top movers, the trends, the
anomaly flags ("Worth a look") and the weekly summary. They are the Insights tab's
Reports segment (`app-core.md`, **The Insights tab**). The decisions are in `PLAN.md`
§12: "Reports and insights", "Insights tab" and "6c plan rulings".

Code:
- `app/lib/features/reports/domain/` (pure Dart, integer `Money` only):
  - `transaction_kind.dart`: the classification;
  - `report_period.dart`: a period's totals;
  - `report.dart`: the comparisons, movers and trends;
  - `anomalies.dart`: the flags;
  - `weekly_summary.dart`: the week.
- `application/`:
  - `reports_providers.dart`: the start day, the currency, the offset and the report;
  - `anomaly_providers.dart`: the flags and the dismissals;
  - `weekly_summary_providers.dart`: the weeks and the notice.
- `presentation/`:
  - `reports_view.dart`: the segment's body;
  - `report_charts.dart`, `report_tables.dart`, `report_format.dart`;
  - `anomaly_list.dart`;
  - `weekly_summary_screen.dart`.

Tests:
- `app/test/features/reports/domain/`: the worked examples, a property test over seeded
  ledgers, the anomaly rule's examples and the anomaly harness;
- `application/`: the providers on the in-memory repositories, the dismissals and the
  weekly notice;
- `presentation/`: the screens and their goldens, light and dark at text scale 1 and 2,
  on `test/helpers/report_seed.dart`;
- the Reports, Reports tables and Weekly summary entries of `app/test/accessibility_test.dart`;
- on the harness, `app/integration_test/reports_test.dart`: the renter's reports in the
  demo flavor, with a planted anomaly flagged.

## Classification

A report counts each live, visible row in its currency as spending, income or a
transfer.
- **Which rows.** Deleted rows are left out. So are hidden rows (the providers exclude
  them) and rows in another currency, never converted. Pending rows count.
- **What counts.** A transaction without splits counts whole under its effective
  category (`transactions.md`). A transaction with splits counts each split in the
  currency, under the split's own category, as the budget math does. A split whose
  category is gone counts as uncategorized.
- **The code.** The kind comes from the category's Plaid code, or else from its nearest
  ancestor's. So a user category under "Income" is income.

| Code | Kind |
|---|---|
| `TRANSFER_IN*`, `TRANSFER_OUT*` | transfer |
| `LOAN_PAYMENTS*` or `LOAN_DISBURSEMENTS*`, an inflow | transfer (the receiving leg of a payment; borrowed money) |
| `INCOME*`, either sign | income |
| any other code | spending; a refund under it nets against it |
| no code at all | income when it comes in, spending when it goes out |

A known limit: an opening-balance transaction (a manual account's, or the demo seed's,
dated the day before its window) has no category. When it is positive it counts as
income in its period. Nothing marks it apart; recategorizing it as a transfer moves it.

## Periods

Report periods are the budgets' monthly periods (`budgets.md`, **Periods**).
- **The start day.** The day every live budget shares, or 1 (calendar months) when
  there are no budgets or they differ.
- **The currency.** The device's default currency (`defaultCurrencyCode()`) when an
  account holds it. Otherwise the first account's in display order.

`ReportPeriod.of(range, entries, lookup, currencyCode:, through:)` counts the rows dated
in the range, on or before `through` (today, while the period runs). It holds:

| Field | What |
|---|---|
| `spend` | Outflows positive, refunds negative |
| `income` | Inflows positive |
| `transferNet` | The transfers' sum in the app's sign |
| `counts` | The rows by kind |
| `spendByCategory`, `incomeByCategory` | `CategoryTotal {categoryId, parentId, own, total}` |
| `spendByMerchant` | `MerchantTotal {key, displayName, total, count}` by `recurringMerchantKey` (`recurring.md`), named after the newest row |
| `savingsRateBasisPoints` | (income − spend) × 10000 ÷ income, rounded down; null without income |

About the category totals:
- `total` is `own` plus the children's totals, the roll-up into every live ancestor.
- `categoryId` null means uncategorized.
- Both lists are largest first, then by id.
- `income − spend + transferNet` is the sum of the counted amounts.

Worked example, October to the 12th: a salary of $4,000.00, the rent of $1,650.00,
groceries of $60.00 and $40.00, and a $500.00 transfer to savings.
- spend is $1,750.00;
- income is $4,000.00;
- transferNet is −$500.00;
- the savings rate is 5625 basis points (56 %).

## Comparisons

`buildReport(period:, periodStartDay:, today:, currencyCode:, entries:, lookup:)` returns
a `Report` with these parts:

**Comparisons.** `current` is the period shown, counted to today while it runs.
`previous` is the period before (month over month), and `yearAgo` the period twelve
before (year over year).
- While the current period runs, both are counted over the same number of days from
  their start, clamped to their own length. On 31 March, February is counted whole.
- A `Change` is the current amount against the earlier one: the difference, and the
  percent in basis points of the earlier amount's magnitude, half-even. The percent is
  null ("new") when the earlier amount is zero.

**Top movers.** Categories, each by its own rows (not rolled up), and merchants, ranked
by the absolute change in spending against the period before, then by id.
- At most ten of each.
- None that did not change.

**Trends.** The spending and income of the last twelve periods ending with the current
one. The last six are the short trend.

## Anomalies

`detectAnomalies(transactions, window:, lookup:, scheduledIds:, rules:, excluded:)` flags
the rows dated in the window. It judges them against every row it is given. The result
is a hint list, not a verdict.

**Rows considered.**
- Live, not hidden outflows counted as spending.
- Less the scheduled payments: the members of the merged recurring streams, the rows
  under `detectorExcludedCodes` (`recurring.md`), and every outflow under
  `LOAN_PAYMENTS*` or `LOAN_DISBURSEMENTS*` (a loan paid out to a school or a seller).
- Less the rows a live rule's `merchantContains` condition matches. A merchant the user
  wrote a rule for is known to them.

**Legs.** A transaction without splits is one leg under its effective category. A
transaction with splits has one leg per split in its currency, under the split's own
category, as the reports classify it. Only the legs that pass the tests above count. A
transaction's outflow at its merchant is the sum of its considered legs.

**Unusual amount.** Judged on one of two bases, with priors dated from the same day
twelve months before up to the day before:
- **merchant:** the priors are the earlier transactions' outflows at the row's merchant
  key in its currency, one per transaction (its legs summed), and the row's own outflow
  is judged. So split visits count once each: six $40.00 visits split $20.00 / $20.00
  make $40.00 the usual, not $20.00;
- **category:** when the merchant has fewer than six priors, each leg is judged against
  the earlier legs in its own category instead, one prior per leg. A first visit split
  $10.00 of groceries and $590.00 of electronics is judged on each, so the $590.00 leg
  can stand out.

With at least six priors:
- `m` is their lower median magnitude (the lower middle, as `StreamBand` takes it);
- `MAD` is the lower median of their distances from `m`.

A magnitude `v` is flagged when `d = v − m > 0` and `v ≥ 2m`, and then:
- with `MAD > 0`: when `6745 × d > 35000 × MAD`, the modified z-score 0.6745 × d ÷ MAD
  above 3.5 (Iglewicz and Hoaglin) by cross-multiplication;
- with `MAD = 0`: when `100 × d > 20 × m` and `d` is at least 5 major units of the
  currency.

All of this is checked `Money` arithmetic. The twice-the-median guard keeps a $7 coffee
against a $5.30 usual off the list.

**New merchant.** The row's account has rows from at least six months before it, and
there is no live row at the merchant key in the six months before the row (any kind, any
account). Of two first visits on one day, only the one with the smaller id is new.

**One flag per row.** The merchant outflow, or every leg on the category basis, is
checked for an unusual amount first. Only when nothing is unusual can the row be a new
merchant, so the unusual flag wins. A flag carries:
- the transaction;
- `amount`, the outflow judged: the merchant outflow, or the leg judged on its category;
- its evidence: the basis (merchant or category), the median and the MAD, or the start
  of the six months.

The flags are sorted by date, then id, and depend only on the inputs.

**Dismissals.** Kept in `app_meta` under `dismissed_anomalies`, a JSON array of
transaction ids, on this device only and never synced. Undo restores a dismissal.

**Measured.** `anomaly_harness_test.dart` (tag `anomaly_harness`, run by the gate) runs the
rule over each persona's full demo seed (seeds 1 and 2, as of 2026-10-24). The scheduled
payments are the demo and the detected streams' members. No rules are given, by ruling:
a merchant a rule names is the user's choice to skip, not the rule's judgment, and one of
the student's demo rules happens to name the bookstore an anomaly is planted at.
- **Ground truth.** The seed's planted anomalies dated at least six months after their
  account's first row. The rule cannot call a merchant new on a shorter history.
- **Bars.** Recall must be at least 0.8 per persona and seed. Precision must be at least
  0.08: a regression floor, not a target. Anomalies are a hint list, and tuning their
  precision is later scope. The test prints both, the recall over every planted anomaly,
  the misses and the extras.

At landing:

| persona, seed | recall (evaluable) | recall (planted) | precision |
|---|---|---|---|
| renter, 1 | 4/4 | 4/6 | 4/11 |
| family, 1 | 6/6 | 6/6 | 6/13 |
| student, 1 | 3/3 | 3/4 | 3/8 |
| small business, 1 | 4/5 | 4/5 | 4/23 |
| renter, 2 | 4/4 | 4/4 | 4/14 |
| family, 2 | 3/3 | 4/4 | 4/12 |
| student, 2 | 4/4 | 4/5 | 4/6 |
| small business, 2 | 2/2 | 2/5 | 2/22 |

The extra flags are noisy early medians, merchants with two spending ranges (the small
business's personal and business meals), and sparse travel merchants read as new.

## The weekly summary

`weekContaining(day)` is the Monday-to-Sunday week. A `WeeklySummary` is a
`ReportPeriod` of a week, plus its three biggest top-level spending categories and its
biggest merchant.

`weeklyReportProvider` gives two weeks, in the reports' currency, hidden rows left out:
- the last complete week;
- the current week to today.

**The screen** (`/reports/weekly`, `WeeklySummaryRoute`) shows, in order:
- last week ("Last week, Oct 12 – Oct 18") with its totals, categories and merchant;
- this week so far;
- "Worth a look" since the last week began;
- the active bills whose next due date falls in next week (`billStatusesProvider`);
- each budget's spending against what is available (`budgetStatusesProvider`).

**The notice.** `weeklySummaryNoticeProvider` is listened to by `bootstrap` in every
flavor. On the first day in a week that it runs, it tells the `Notifier` a
`WeeklySummaryNotification` (key `weekly/<Monday of the week before>`). It then records
this week's Monday in `app_meta` under `weekly_summary_raised`, so the notice is raised
once a week on each device; a failure is logged by its type. Only a week that began on or
after the install day's week is summarised, so a fresh install waits for the next Monday.
The install day is `app_meta` `install_date`; the demo, which has none, counts the day
the app was launched. The alerts sheet
(`budgets.md`, **Alerts**) shows the notice as "Your weekly summary is ready", and a tap
marks it read and opens the screen. The system notification is Phase 8's.

## Providers

| Provider | What |
|---|---|
| `reportStartDayProvider` | The start day (**Periods**) |
| `reportCurrencyProvider` | The currency (**Periods**) |
| `reportPeriodOffsetProvider` | The period shown as an offset from today's, the screen's own (not the budgets'); `select(offset)` |
| `reportProvider(offset)` | The `Report` of that period over every live transaction (`recurringLedgerProvider`) |
| `anomaliesProvider(window)` | The flags in a window, less the dismissed ones |
| `dismissedAnomaliesProvider` | The dismissed ids; `dismiss(id)`, `restore(id)` |
| `weeklyReportProvider` | The two weeks |
| `weeklySummaryNoticeProvider` | The weekly notice (**The weekly summary**) |

## The screen

`ReportsView` is the body of the Reports segment (`/reports`, `ReportsRoute`). It has no
arguments and no Scaffold of its own; the segment's app bar carries the alerts bell
(`budgets.md`, **Alerts**), where the weekly summary's notice is. From the top:
- the budgets' period selector (`budget_period_selector.dart`), with no next button at
  the current period since nothing lies ahead;
- a Tables/Charts switch, which turns every chart below into its table;
- the headline: "Spent $2,526.50", "Income $4,300.00", "Kept 41 % of income" (in the
  error colour when negative), or "No income in this period";
- the comparisons: spending and income against the period before and against a year
  before, as "+$12.00 (+15 %)" or "(new)", with "Compared over the first N days of each
  period" while the period runs;
- **By category**, with a Spending | Income control. A donut (fl_chart `PieChart`) of
  the top-level groups, the total in its middle. A tap on a group with children shows
  them, plus the group's own rows as "<group> itself", and "All categories" goes back.
  Its table lists the name, the share and the amount, and a row with children opens
  them;
- **Income and spending**: the last six periods as paired bars (`BarChart`) with a
  legend; its table lists each period's income, spending and net, newest first;
- **Trend over 12 periods**: spending and income as two lines (`LineChart`), with the
  same table;
- **Top merchants**: the five merchants spent most at, with the purchase count;
- **Top movers**: categories, then merchants, each with the change and "before, now";
- **Worth a look** (`anomaly_list.dart`): the flags in the period. Each shows the
  merchant, the date and amount, and why: "Usually about $45.00 here", "… in this
  category", or "New: not seen in the last six months". A tap opens the transaction.
  Dismiss hides it on this device, with Undo;
- **Weekly summary**, which opens `/reports/weekly`.

**Accessibility and amounts.**
- Every chart is one semantics node with a summary (for example "Spending by category:
  $2,526.50 in all. The largest is Rent and utilities, $1,650.00."), with the drawing
  excluded.
- Every table row is one node read as a sentence.
- fl_chart gets each amount's minor units as a `double` for placement only; every amount
  shown is the `Money` formatted through intl. Percents are whole numbers from basis
  points, truncated toward zero.
