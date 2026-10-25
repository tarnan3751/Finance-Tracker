# Rules

User-authored rules that categorize, tag, rename and hide transactions: applied by the Plaid pull
to the transactions it brings in, and on demand from the transaction editor; synced between
devices through the change log. Code: `app/lib/features/rules/` (`domain/rules_engine.dart`,
the evaluator; `domain/rule_repository.dart` and `data/`, the repositories;
`application/rule_runner.dart`, the arrival processor; `presentation/`, the screens).
Tests: `app/test/features/rules/`, `app/test/contract/rule_repository_contract.dart`,
`app/test/sync/two_device_convergence_test.dart` (**rules**). The model is `shared_models`'
`Rule`, `RuleCondition` and `RuleAction` (`core.md`); the table and the repositories'
shared rules are `data.md`'s, the sync record `sync-app.md`'s.

## The model

A rule has an id, a name, a `position`, a list of conditions and a list of actions. Its
record (and its table row) holds the conditions and actions as the `shared_models` JSON
lists; an amount bound is `Money`'s `{minor_units, currency}`, never a number with a
fraction.

| Condition | `text` / bounds | Matches when |
|---|---|---|
| `merchant_contains` | the text | the text, trimmed, is in the merchant name, else (a null, empty or blank merchant name) in the name, ignoring case (`toLowerCase`, which does not depend on the device locale) |
| `amount_between` | `min_amount`, `max_amount`, either one absent | the absolute amount is within the bounds, both inclusive; a bound in another currency than the transaction's never matches |
| `account` | the account id | the transaction is on that account |
| `plaid_category` | a Plaid code | the code is the transaction's primary or detailed Plaid category |

| Action | `value` | Does |
|---|---|---|
| `set_category` | a category id | sets `userCategoryId` when it is null, to a live category, on a transaction without splits (splits are the user's own categorization, `PLAN.md` §12) |
| `add_tag` | the tag | appends the tag when the transaction does not carry it |
| `rename` | the new name | sets the name of a `manual` or `import` transaction; a `plaid` or `demo` transaction keeps its bank's name (`merchant_name` is Plaid's, not an override), and the editor says so |
| `hide` | none | sets `hidden` when the transaction is not hidden, whatever its source; a hidden transaction still counts toward its account's balance (`transactions.md`) |

## Evaluation

`applyRules(rules, transaction, lookup:, ownedFields:)` (`rules_engine.dart`, pure Dart)
returns a `RuleOutcome`: the rule that matched, the changed transaction (null when nothing
changes) and the matching rule's actions that changed nothing, with why (`RuleSkip`).

- Rules are tried in `position` order, ties by id in SQLite's `BINARY` order (as the
  repositories list them), whatever order they are given in. A rule matches when every
  one of its conditions does; a rule with no condition or no action never matches (the
  editor requires both, but a synced rule is taken as it is).
- **The first matching rule wins**, and all its actions apply. No later rule is looked at,
  even when the winner's actions change nothing (a `hide` of a hidden row, or a rename of
  a bank row), so
  which rule wins never depends on what is already set.
- **Deterministic**: the same rules, transaction, categories and owned fields give the same
  outcome on every device; a seeded property test runs random rules over random
  transactions twice and in shuffled order and diffs nothing.
- **Idempotent**: the actions only fill what is unset, so applying the rules to their own
  result changes nothing. One exception: a `rename` changes the name `merchant_contains`
  falls back to, so on a transaction with no merchant name a second run can match a
  different rule. Rename applies only to manual and imported rows, which the rules reach
  only on demand, where the user sees the result before saving.
- `ownedFields` (record field names, `user_category_id`, `tags` and `hidden`) are left as
  they are:
  the runner's way of saying a person, or a rule on another device, has set them.

## On arrival

`RuleRunner` is the Plaid pull's `ArrivalProcessor`: the value of `arrivalProcessorProvider`
(`core/di/providers.dart`; `sync-app.md`, **The Plaid pull**). The pull calls it once per page, inside
the page's store transaction, with the rows the page inserted, as stored: overrides other
devices recorded and the pull laid over the new rows are already there.

- It reads the live rules and categories once per page, applies the engine to each row and
  upserts the changed ones through `TransactionRepository.upsert`: recorded like a user's
  edit, so on a `plaid` row an update of `user_category_id`, `tags` and `hidden` only. The row keeps
  the `updatedAt` the server sent, so every device holds the same row.
- **The guard.** On a `plaid` row, a field that already has a sync clock is the user's, or
  another device's rule's, and is left alone; the runner reads the record through the sync
  store the recorder writes to (`recordingSyncStoreProvider`; none in the demo, which never
  syncs).
- **Total**: it never throws, since a failure would roll the page back. Each upsert is its
  own nested transaction (a savepoint in Drift), so a row that cannot be written (its account
  gone, say) rolls back alone, with its entry; it is logged by rule id and exception type and
  skipped. Logs carry rule ids, counts and types only, never a name, merchant or amount.
- Rules run on every row a pull inserts, `plaid` in dev and prod and `demo` in the demo
  flavor's linked bank (not recorded there).

**Several devices.** Every device runs its own Plaid pull, so every device that inserts a
transaction runs the rules on it, and they record the same values; last-writer-wins
converges on them. The residual race, until Phase 7's conflict work: a device that inserts a
row before it has pulled another device's later edit of that row (the change-log session
before the pull failed) writes the rule's value at a later clock, which wins over that edit.

## On demand

The transaction editor's menu has "Run rules on this transaction" (`transactions.md`): the
engine runs on the values in the form, with no owned fields (the user is editing), and Save
writes the result like any edit. Nothing else runs rules on manual entries; applying a rule
to the existing ledger is Phase 4's.

## The repositories

`RuleRepository` (`data.md`): `watchAll()` by position then id, `upsert` (throws
`EntityDeletedException` on a deleted rule), soft `delete`, `restore`, and
`reorder(ids)`, which numbers the listed live rules 0, 1, 2… and puts the others after them
in their current order, ignoring unknown, deleted and repeated ids, so a list read before
another device's change still applies; only the rules whose position changes are written
and recorded. Concurrent reorders on two devices merge position by position: every device
ends with the same order (ties by id), which need not be either user's.

Three implementations pass `runRuleRepositoryContract`: Drift over the `rules` table
(`data.md`, **Schema 4**), in memory (its own state, like the settings), and the demo one,
which holds two rules for the persona the demo shows (`data/demo_rules.dart`; a test checks
each changes some of that persona's demo transactions).

## The screens

- **Rules** (`rules_screen.dart`, `/settings/rules`; from Settings → Data → Rules and the
  categories screen's menu). The live rules in the order they are tried, each with its
  condition and action counts; a drag handle (labelled for screen readers, and the list's
  move actions for assistive technology) reorders them; the delete button deletes with a
  five-second undo; "Add rule".
- **Editor** (`rule_editor_screen.dart`, `/settings/rules/new` and `/settings/rules/:id`).
  The name; the conditions, one card per row, added from a menu of every condition kind
  (text; an amount range with the currency chosen among the accounts' currencies, parsed as
  the transaction editor parses amounts; an account; a bank category from the category
  picker's built-in categories); the actions, added from a menu of set category, add tag,
  rename (with the caption that bank transactions keep their name) and hide (with the
  caption that hidden transactions still count toward their balance). A rule saves only with a
  name, a condition, an action and every row's value; a new rule goes after the last one.
  Delete offers an undo.
