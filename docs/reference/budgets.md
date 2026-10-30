# Budgets

A budget limits spending on a category per monthly period, optionally carrying what is left
(or overspent) into the next period, and raises an alert when spending reaches 80 % and 100 %
of what is available. This file covers the model, the period and money semantics, the alerts,
the repositories, the providers and the screens. The decisions are in `PLAN.md` §12,
"Budget semantics (4a)".

Code:
- `app/lib/features/budgets/`: `domain/` (the repository and alert store interfaces, the
  period math, the status math), `data/` (Drift, in-memory and demo repositories, the alert
  stores, the demo budgets), `application/` (the providers, the alert evaluator) and
  `presentation/` (the screens, the card, the period selector, the alerts);
- `app/lib/core/platform/` (the `Notifier` boundary and the in-app notifications);
- the `budgets` and `budget_alerts` tables (`data.md`).

Tests: `app/test/features/budgets/` (the screens, their goldens and the alerts in
`presentation/`, on `test/helpers/budget_seed.dart`), `app/test/contract/budget_repository_contract.dart`,
`app/test/core/platform/`, the `budgets` group of `app/test/sync/two_device_convergence_test.dart`.

## The model

`shared_models` `Budget`:

| Field | JSON | What |
|---|---|---|
| `id` | `id` | UUID v4 for a user's budget |
| `categoryId` | `category_id` | The category budgeted. A parent category budgets its whole group |
| `period` | `period` | `BudgetPeriodKind`: `monthly` only |
| `periodStartDay` | `period_start_day` | The day of the month each period starts, 1 to 28. JSON outside that range is refused in every build |
| `amount` | `amount` | `Money` per period |
| `rollover` | `rollover` | Whether each period's remainder carries into the next |
| `startDate` | `start_date` | The first day of the budget's first period, from which rollover accumulates |

The entity carries no audit fields. The table stamps them, as it does for rules. A budget syncs
as the `budget` record: its JSON plus `deleted_at` (`sync-app.md`). It is user-authored, so
every field is recorded.

## Periods

`domain/budget_period.dart`, pure Dart. A period is a half-open `LocalDateRange` of local dates
in the device zone (`PLAN.md` §6.8).

`periodContaining(day, s)` starts on the latest date on or before `day` whose day of the month
is `s`, and ends one month later. Because `s` is at most 28, no month clamps it. Consecutive
periods therefore tile the calendar with no gap or overlap, and each is 28 to 31 days long.

`periodAt(day, s, offset)` is the period `offset` periods after the one containing `day`
(before it when negative).

`periodsFrom(startDate, s, through: day)` lists the periods from the one containing
`startDate` through the one containing `day`. The list is empty when `day` comes before the
first of them. A start day outside 1 to 28 is an `ArgumentError`.

"Today" is the `Today` provider's date (the clock's local date). A period therefore begins
exactly at local midnight of its start day, whatever the zone or DST.

## Spending

`spentIn(period, budget, transactions, lookup, {excluded})`, in `domain/budget_math.dart`.
Spending is the net of the transactions dated in the period that pass every test below:

- **Live:** `deletedAt` is null.
- **Not excluded:** the `excluded` predicate leaves out the hidden rows:
  `budgetStatusesProvider`, `budgetPeriodStatusesProvider` and
  `budgetPeriodEntriesProvider` pass `(t) => t.hidden`, so a transaction the user hid
  (`transactions.md`, **Hiding**) leaves the spending, the carry and a period's entries.
- **In the budget's currency.** Other currencies are ignored, never converted.
- **In the budget's category or a descendant of it.** Descendants are found through the parent
  chain of the live categories (`Category.parentId`).
  - A transaction with splits contributes each split whose own `categoryId` qualifies.
  - A transaction without splits contributes its amount when its **effective category**
    qualifies (`effective_category.dart`: the user category when it is live, else the
    category its Plaid code resolves to).

Each contribution is negated: outflows count positive and refunds negative. Pending
transactions count.

`entriesIn(period, budget, transactions, lookup, {excluded})` lists the rows counted, in the
transactions' order: a transaction whole, or each of its splits that qualifies. Spending is
summed from the same rows, so the two always agree.

The lookup holds only live categories. A budget whose own category has been deleted
therefore counts only split rows that still name it. Transactions whose user category was
that deleted category fall back to their Plaid category. The screens name such a budget
"Deleted category".

## Status, rollover and projection

`budgetStatus(budget, today, transactions, lookup, {excluded})` describes the period
containing `today`:

| Field | What |
|---|---|
| `period` | The current period |
| `spent` | `spentIn` of the current period |
| `carried` | Zero without `rollover`. With it, the signed sum over every earlier period since the one containing `startDate` of `amount − spent` |
| `available` | `amount + carried` |
| `remaining` | `available − spent` |
| `progress` | `Ratio` of `spent` over `available` in minor units: `numerator`, `denominator` and `percentBasisPoints` (rounded down; null when `available ≤ 0`) |
| `elapsedDays` | Days from the period's start through `today`, at least 1 |
| `projected` | `spent × period length ÷ elapsedDays`, `Money.multipliedBy`, half-even |
| `projectedOverspend` | `projected > available` |
| `thresholdsCrossed` | The thresholds of 8000 and 10000 basis points that `spent` has reached (`spent ≥ available × bp ÷ 10000`, exactly). Empty when `available ≤ 0` |

A budget whose first period is after today still has a status for today's period, with
nothing carried. Everything is integer `Money` arithmetic; no `double` is involved.

**Rollover, worked example.** A $400.00 budget on Food from 1 August, rollover on, start
day 1:
1. August spends $350.00, so it carries +$50.00.
2. September spends $460.00, so it carries −$60.00.
3. On 15 October, with $120.00 spent so far: `carried` is −$10.00, `available` is $390.00,
   `remaining` is $270.00, and `progress` is 12000/39000 (3076 basis points).

**Projection, worked examples.**
- The rollover example above, on 15 October: 15 of October's 31 days have elapsed.
  `projected` is 120 × 31 ÷ 15 = $248.00, which is not an overspend.
- A $600.00 budget with start day 25, on 30 October: the period is 25 October to
  24 November (31 days) and 6 days have elapsed. With $200.00 spent, `projected` is
  200 × 31 ÷ 6 = $1,033.33, so `projectedOverspend` is true.
- On a period's last day, `projected` equals `spent`.

## Alerts

`application/budget_alert_evaluator.dart`. For each status and each threshold it has reached,
the evaluator records `(budget, period start, threshold)` in the `BudgetAlertStore`:
`budget_alerts` in dev and prod, in memory in the demo and the tests.

- A threshold recorded for the first time is new. When one evaluation reaches both 80 % and
  100 %, both are recorded and only the higher one is told.
- A new period raises again. Nothing is raised while nothing is available.
- Alerts are per device: the table is never synced, so each device alerts once. That includes
  a budget that is already over when it first appears on a device.

Evaluations run one at a time and never throw; a failure is logged by its type.

A new alert is told through the `Notifier` (`core/platform/notifier.dart`) as a
`BudgetThresholdNotification`: budget id, category id, period start, threshold, spent,
available and the UTC instant it was raised. It is typed data with no text; whoever shows it
localizes it.

The in-app notifier appends it to `inAppNotificationsProvider`:
- newest first, one per key, at most 50, each with a read flag;
- `markRead(key)` and `markAllRead()`;
- kept in memory, so the list is empty after a restart. Persisting it is later scope. The
  `budget_alerts` row keeps an alert from firing again.

Android notification channels are Phase 8's, behind the same interface.

`budgetAlertWatcherProvider` listens to the statuses. It evaluates them
`budgetAlertDebounceProvider` (1 s) after they last changed, on a timer and never inside a
build. `bootstrap` listens to it in every flavor, so alerts run from startup. The demo budgets
exist to show them.

## Repositories

`BudgetRepository` (`domain/budget_repository.dart`) has these methods:
- `watchAll()`: the live budgets by `categoryId`, then id, in BINARY order;
- `watchById(id)`: null when the budget is missing or deleted;
- `upsert`: throws `EntityDeletedException` on a deleted id;
- `delete` (soft) and `restore`.

There are three implementations, all passing `runBudgetRepositoryContract`:
- **Drift**, over `budgets`, recording through the `ChangeRecorder`;
- **in memory**, with its own state, recording into the recorder it is given;
- **demo**, which records nothing.

The recording contract checks each write's entries.

**The demo budgets** (`data/demo_budgets.dart`, `demoBudgets(persona, today)`). Two per
persona, both starting two periods before today's:

| Budget | Category | Start day | Rollover | Amount | Behaviour on the persona's demo seed |
|---|---|---|---|---|---|
| `demo-budget-food` | `plaid:FOOD_AND_DRINK` (the group) | 1 | off | Below every recent month's spending: $500, $1,000, $300 or $800 | Runs over |
| `demo-budget-transport` | `plaid:TRANSPORTATION` | 15 | on | About twice the busiest month: $1,000, $1,500, $80 or $1,200 | Stays on pace and carries a surplus |

The amounts are for renter, family, student and small business, in that order.
`demo_budgets_test.dart` checks both against each persona's seed.

## Providers

`application/budgets_providers.dart`:
- `budgetsProvider`: the live budgets.
- `budgetStatusesProvider`: every live budget's status for `todayProvider`'s day, in budget
  order. It is recomputed when the budgets, the categories, the transactions or today change.
  It reads one `TransactionQuery` whose range runs from the earliest period a status needs
  to the latest current period's end: the first period for a budget with rollover, the
  current period for one without. With no budgets it runs no query.
- `budgetPeriodOffsetProvider`: which period the screens show, as an offset from each
  budget's current period (0 by default; `select(offset)`). The list and the detail share
  it.
- `budgetPeriodStatusesProvider(offset)`: every live budget's status in that period:
  `budgetStatus` on today for 0, else on the period's last day. Its query starts at the
  first period for a rollover budget, else at the shown period.
- `budgetPeriodEntriesProvider(budgetId, offset)`: `entriesIn` that budget's period at that
  offset, newest first; empty when the budget is gone.
- `budgetAlertDebounceProvider`, `budgetAlertEvaluatorProvider` and
  `budgetAlertWatcherProvider`: see **Alerts**.

`budgetRepositoryProvider` and `budgetAlertStoreProvider` are in `core/di/providers.dart`
(`app-core.md`): in memory by default, Drift in dev and prod, demo in the demo flavor (the
demo's alert store is in memory).

## Screens

`presentation/`. The budgets are the Budgets segment of the Plan tab, the third of five,
between Transactions and Insights (`app-core.md`, **The Plan tab**): each screen below is
under the "Plan" app bar and the segment control.

**The list** (`/budgets`, `budgets_screen.dart`). At the top is the period selector
(`budget_period_selector.dart`): previous and next, the period's name ("This period",
"Last period", "3 periods ago", "Next period", "In 2 periods") and a "This period" button
when another period is shown. When every budget starts its periods on the same day, the
selector also shows the dates in the device zone ("Oct 1 – Oct 31, 2026"). Otherwise each
card shows its own dates.

Below it is one `BudgetCard` per budget (`budget_card.dart`), by category name. A card
shows:
- the category's icon and name ("Deleted category" when it is gone), and "Includes N
  categories" when it budgets a group;
- a badge for the highest threshold of `thresholdsCrossed` ("80 % reached");
- the amount, with the carry when rollover moved it ("$500.00 + $42.00 carried", or
  "− … carried" for a deficit);
- in the current and past periods: a bar and the percent from `percentBasisPoints`, in the
  error colour past 100 %, or "Nothing available" when `available ≤ 0`; then spent, and left
  or over;
- in the current period only: the projection, "On pace: about $410.00 by the end" or
  "Projected over by $60.00" in the error colour with a warning icon (`projectedOverspend`);
- in a future period: what will be available, with no spending and no badge.

The bar and its percent are read as one sentence ("Groceries: 82 percent of $500.00 spent,
$90.00 left"). An empty list offers "Add budget"; otherwise a floating button does. Tapping a
card opens its detail.

**The detail** (`/budgets/:id/transactions`, `budget_detail_screen.dart`). The same
selector, showing the budget's own dates, then the budget's card for the period, then
`budgetPeriodEntriesProvider`'s rows as transaction tiles, newest first. A split row shows
the split's amount and category. Tapping a row opens the transaction. The app bar's pencil
opens the editor.

**The editor** (`/budgets/new`, `/budgets/:id`, `budget_editor_screen.dart`). Its fields:
- the category, from the category picker (any category; a parent budgets its group);
- the amount per period, read by `Money.parse` in the device locale. Its currency is chosen
  among the accounts' currencies and the budget's own, or is the device's default when
  there are none;
- the period start day, 1 to 28;
- carry-over;
- the first period. It defaults to the current period and is stored as the start of the
  period containing the date picked. The date picker ends at the current period's start,
  so the first period can move earlier but never later.

Save validates inline: a category, a positive amount, and a day from 1 to 28. A write to a
deleted budget is refused with "This budget no longer exists." Delete returns to the list
with an Undo that restores the budget.

**Alerts** (`budget_alerts.dart`). The Budgets segment's app bar has a bell (so does the
Insights tab's Reports segment, `reports.md`), badged with the unread
count of `inAppNotificationsProvider`. It opens a sheet over the whole app that lists the
notifications newest first ("Groceries reached 80 % of $500.00 on Oct 20", the day in the
device zone). Unread ones are bold, with a dot that reads "Unread". "Mark all read" clears
them all. Tapping one marks it read, selects the period it was raised for, and opens the
budget's detail. A bill due today or tomorrow is listed too ("Rent is due Nov 1",
`bills.md`, **Reminders**), left out once that occurrence is paid; tapping it marks it
read and opens the bill. So is the weekly summary's notice ("Your weekly summary is
ready", `reports.md`, **The weekly summary**); tapping it marks it read and opens the
summary.
