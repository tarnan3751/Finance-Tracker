# Goals

The user's savings goals: a target and an optional date, progress from linked accounts'
balances or from logged contributions, a suggested monthly amount and whether the goal
is on track (`PLAN.md` §12 "Goals", "6d plan rulings"). The feature is
`app/lib/features/goals/`. Goals are user data (`PLAN.md` §7.1 Tier D): synced through the
change log, with no `source`.

## The model

`Goal` and `GoalContribution` (`shared_models`, `core.md`), stored in `goals` and
`goal_contributions` (`data.md`) and synced as the `goal` and `goal_contribution` records
(`sync-app.md`).

| `Goal` field | What |
|---|---|
| `name` | Required |
| `target` | `Money`, positive (the editor refuses zero and negatives) |
| `kind` | `balance`: the progress is the linked accounts' balances; `contribution`: the sum of the contributions |
| `linkedAccountIds` | The accounts a balance goal counts; the editor clears them when a goal is saved as a contribution goal |
| `targetDate` | Optional; none means no suggestion and no status. A new goal's is today or later; an existing goal keeps the date it has |
| `createdOn` | The local day the goal was created: where its plan starts |
| `note` | Optional |
| `archivedAt` | Set by archiving; an archived goal is kept, listed in a folded section |
| `deletedAt` | The tombstone |

A `GoalContribution` is `goalId`, `date`, `amount` (positive adds, negative withdraws),
`note` and `deletedAt`. Contributions are records of their own, not a field of the goal,
so contributions added on two devices at the same time both survive; a rename on one
device and an archive on another both survive too (different fields), and a delete wins
over a concurrent edit (`test/sync/two_device_convergence_test.dart`). A contribution may
reach a device before its goal: its row lands (no foreign key) and shows once the goal
arrives. A deleted goal hides its contributions without touching them; a restore brings
both back.

## The math

`domain/goal_math.dart`, pure, in integer minor units:

- **Progress**: a balance goal's is the sum of its linked accounts' balances as the
  accounts screens show them (`shownBalance`: reported by the institution, else derived
  from transactions; `accounts.md`), those in another currency than the target left out
  and listed, a linked account that no longer exists left out; a contribution goal's is
  the sum of its live contributions in the target's currency (one in another currency,
  recorded on another device before a currency change, is left out and listed, as the
  accounts are).
- **Remaining**: the target less the progress, never below zero.
- **Months left**: the most whole months `m` with today plus `m` months (clamped to short
  months: January 31 plus one month is February 28) on or before the target date; at
  least one when the date is after today; none when it is today, past or absent.
- **Suggestion**: the remaining amount over the months left, rounded up to the minor unit
  ("Set aside $175.00 a month"); none without months left or when nothing remains.
- **Status**: **done** once the progress reaches the target; else, with a target date,
  **on track** when the progress is at least the linear plan's amount for today (the
  target times the days from `createdOn` to today over the days from `createdOn` to the
  target date, rounded down, so a goal exactly on its plan is on track; the whole target
  on and after the target date), **behind** by the difference otherwise; without a
  target date, no status.

A withdrawal lowers the progress, so it raises the suggestion and can put a goal behind.

## Repositories and providers

`GoalRepository` (`watchAll()`, the live goals with archived ones, each a `GoalEntry` of
the goal and its live contributions by date then id, by creation day then id;
`watchById`; `create`; `update`, which keeps the stored archive state; `setArchived(id,
archived:)`; `delete`; `restore`; `addContribution`, refused for a missing or deleted goal,
an existing id or another currency than the target's; `deleteContribution`;
`restoreContribution`) in Drift, in-memory and demo implementations under
`test/contract/goal_repository_contract.dart`; every write records the goal or the
contribution it changed. The demo starts with two goals per persona
(`data/demo_goals.dart`), from the persona's demo seed without touching the engine: an
**Emergency fund**, a balance goal on the savings account (the first depository account
when there is none), twice its balance rounded up to a hundred (at least a thousand),
created six months before today and due a year after; and a **Holiday**, a contribution
goal of 1,800.00 created six months before today and due six months after, with six
monthly contributions of 125.00 from its creation day, so it is behind its plan.

| Provider (`application/goals_providers.dart`) | What |
|---|---|
| `goalEntriesProvider` | `GoalRepository.watchAll()` |
| `goalViewsProvider` | Each goal as the screens show it today, a `GoalView`: the goal, its contributions, the progress, the counted accounts with their shown balances, the accounts left out for their currency, the remaining amount, the months left, the suggestion and the status |
| `goalViewByIdProvider(id)` | One of them, or null |
| `goalActionsProvider` | `create`, `update`, `setArchived`, `delete`, `restore`, `addContribution`, `deleteContribution`, `restoreContribution` |

## Screens

**The goals** (`/goals`, `presentation/goals_screen.dart`), the Insights tab's Goals
segment (an `InsightsScaffold`, `app-core.md`, **The Insights tab**): a card per live goal
(`goal_card.dart`): its name, "By Oct 24, 2027" when it has a date, a progress bar (in
the error colour when behind), "$750.00 of $1,800.00", the status ("On track", "Behind
by $152.46" in the error colour, "Done"), and the suggestion; then **Archived (N)**,
folded. Each card reads as one sentence, each part once ("Holiday, By Apr 24, 2027,
41 percent of the target, $750.00 of $1,800.00, Behind by $152.46, Set aside $175.00 a
month"): the progress bar's own label is only the percent. The app bar opens a new goal; with none, an empty state does.

**A goal's detail** (`/goals/:id`, `goal_detail_screen.dart`): the card's summary and the
note; for a balance goal, the **Counted accounts** with the balance each is shown with,
captioned reported or from transactions, and the accounts not counted for their
currency; for a contribution goal, the **Contributions** newest first (amount, date and
note; one in another currency marked "Not counted, in EUR"), each with Delete and an Undo, and **Add contribution**
(`/goals/:id/contribute`, `contribution_editor_screen.dart`: the amount in the goal's
currency, Withdrawal, the date, today unless chosen and never after today, and a note). A contribution is not
edited: it is deleted and added again. The app bar opens the editor.

**The editor** (`/goals/new`, `/goals/:id/edit`, `goal_editor_screen.dart`): the name,
the target in a currency of the accounts (fixed, with a caption saying so, once the goal
has contributions or linked accounts), what the progress is from (Account balances or
Contributions), the accounts of a balance goal (at least one in the target's currency;
another currency's marked "In EUR, not counted"), the target date (optional, with Clear
date; today or later for a new goal, while an existing goal keeps the date it has) and a
note; an existing goal has Archive (or Unarchive) and Delete, each going back
to the goals with an Undo. A new goal's `createdOn` is today; an edit keeps it.

## Tests

The entities: `packages/shared_models/test/entities_round_trip_test.dart`. The math's
worked examples (month ends, a leap day, a past or absent date, a reached goal,
withdrawals): `test/features/goals/domain/goal_math_test.dart`. The views over the
in-memory repositories: `test/features/goals/application/goals_providers_test.dart`. The
repositories: `test/features/goals/data/` and `test/contract/recording_contract.dart`.
The records: `test/core/db/drift_sync_store_test.dart`; the schema step:
`test/drift/migration_test.dart`; convergence: `test/sync/two_device_convergence_test.dart`.
The screens: `test/features/goals/presentation/` (the flows, twice the text size, goldens
of the list, both details and the editor), on `test/helpers/goal_seed.dart`; and the
goal screens in `test/accessibility_test.dart`. On the harness:
`app/integration_test/goals_test.dart` (the demo's two goals, and a contribution added).
