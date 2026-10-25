# Budgets

A budget limits spending on a category per monthly period, optionally carrying what is left
(or overspent) into the next period, and raises an alert when spending reaches 80 % and 100 %
of what is available. This file covers the model, the period and money semantics, the alerts,
the repositories and the providers. The screens are Phase 4b's. The decisions are in
`PLAN.md` §12, "Budget semantics (4a)".

Code:
- `app/lib/features/budgets/`: `domain/` (the repository and alert store interfaces, the
  period math, the status math), `data/` (Drift, in-memory and demo repositories, the alert
  stores, the demo budgets) and `application/` (the providers, the alert evaluator);
- `app/lib/core/platform/` (the `Notifier` boundary and the in-app notifications);
- the `budgets` and `budget_alerts` tables (`data.md`).

Tests: `app/test/features/budgets/`, `app/test/contract/budget_repository_contract.dart`,
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

`periodsFrom(startDate, s, through: day)` lists the periods from the one containing
`startDate` through the one containing `day`. The list is empty when `day` comes before the
first of them. A start day outside 1 to 28 is an `ArgumentError`.

"Today" is the `Today` provider's date (the clock's local date). A period therefore begins
exactly at local midnight of its start day, whatever the zone or DST.

## Spending

`spentIn(period, budget, transactions, lookup, {excluded})`, in `domain/budget_math.dart`.
Spending is the net of the transactions dated in the period that pass every test below:

- **Live:** `deletedAt` is null.
- **Not excluded:** the `excluded` predicate leaves out the hidden rows. It is wired to
  `hidden` once transactions have it (4c); until then it excludes nothing.
- **In the budget's currency.** Other currencies are ignored, never converted.
- **In the budget's category or a descendant of it.** Descendants are found through the parent
  chain of the live categories (`Category.parentId`).
  - A transaction with splits contributes each split whose own `categoryId` qualifies.
  - A transaction without splits contributes its amount when its **effective category**
    qualifies (`effective_category.dart`: the user category when it is live, else the
    category its Plaid code resolves to).

Each contribution is negated: outflows count positive and refunds negative. Pending
transactions count.

Caveat for 4b: the lookup holds only live categories. A budget whose own category has been
deleted therefore counts only split rows that still name it. Transactions whose user category
was that deleted category fall back to their Plaid category. The budgets screen should show
such a budget as being on a deleted category.

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
- `budgetAlertDebounceProvider`, `budgetAlertEvaluatorProvider` and
  `budgetAlertWatcherProvider`: see **Alerts**.

`budgetRepositoryProvider` and `budgetAlertStoreProvider` are in `core/di/providers.dart`
(`app-core.md`): in memory by default, Drift in dev and prod, demo in the demo flavor (the
demo's alert store is in memory).
