# Accounts

The account list, an account's detail and the account editor. Code:
`app/lib/features/accounts/` (`application/`, `presentation/`; the repository is
`data.md`'s). The linked banks are `items.md`'s. Tests: `app/test/features/accounts/`, `app/test/flows/`. The routes are in
`app-core.md`, **Routing and the shell**.

## Balances

A balance is either reported by the institution or derived from transactions (`PLAN.md`
§6), and is captioned with which. `shownBalance(account, derived)`
(`application/accounts_providers.dart`) chooses: a linked account (`itemId` set) with a
`currentBalance` shows that, captioned "reported" on the list and "reported by
<institution>" on the detail ("reported by your bank" before the Item is stored), with
"as of <date time>" from `balancesAsOf` in the device's zone (the clock's location), and the
`availableBalance` and `creditLimit` under it when the bank gave them. A manual account,
and a linked account with no reported balance (never synced), shows its balance derived
from its transactions, captioned "from transactions"; one with no transactions shows zero.
The balances are shown as stored: a reported balance is in the app's sign, negative for
money owed, as the server stores it (`api.md`, **Balance signs**).

**Running balances.** The detail's ledger shows the balance after each transaction
(`withRunningBalances`). For an account with a reported balance (`reportedBalance`: a
linked account's `currentBalance`) it is worked back from that balance: the newest row is
the reported balance, and each older row the reported balance minus the amounts of every
newer transaction, pending ones included, so a linked account whose history on the device
is partial still ends at what its bank reports; each row is captioned "Running balance
<amount>, from the reported balance". Otherwise (a manual account, or a linked one never
synced) the balances are summed from the oldest transaction to the newest and captioned
"Running balance <amount>". A transaction in another currency than the account's has no
running balance and is left out of the walk.

| Provider (`application/accounts_providers.dart`) | What |
|---|---|
| `accountsProvider` | `AccountRepository.watchAll()` |
| `accountsByIdProvider` | The live accounts by id, for screens that name an account |
| `derivedBalancesProvider` | `watchDerivedBalances()` |
| `linkedBanksByIdProvider` | `ItemRepository.watchAll()` by Item id, unlinked Items included: the institution an account names |
| `accountProvider(id)` | `watchById(id)` |
| `accountLedgerProvider(id)` | The account's transactions newest first, each with the running balance after it (`withRunningBalances`, **Running balances**: anchored to the reported balance when there is one, else summed oldest to newest, then reversed) |
| `accountTransactionCountProvider(id)` | How many live transactions the account has (the editor's currency lock) |
| `accountActionsProvider` | `AccountActions`: `create`, `update`, `setHidden`, `reorder`, `delete` |

## Screens

- **List** (`accounts_screen.dart`). One card per visible account: for a linked account
  the institution's avatar (`MerchantAvatar` with the stored logo bytes, else its initial on
  `institutionColor`, labelled with the institution's name, which the card does not
  write), for a manual one the type icon; name, type label, the balance as shown and its
  caption. When the visible accounts hold more than one currency, a "Totals" row at the
  top has one total per currency of the balances as shown, never converted (`PLAN.md` §3),
  captioned "from transactions", "reported", or "reported and from transactions".
  Hidden accounts are in a collapsed "N hidden accounts" section. A long press drags a
  card (`ReorderableListView`), and the drop writes `displayOrder` 0, 1, 2... to the
  visible accounts whose order changed. With large text the balance moves under the name.
  "Add account" is the floating button, or the empty state's action. The app bar's
  "Linked banks" opens the linked banks (`items.md`).
- **Detail** (`account_detail_screen.dart`). For a linked account, the institution's
  avatar (decorative) and name, then Plaid's official name and mask ("•••• 0000", read as
  "ending in 0000"); the type; the balance block (**Balances**); then the transactions
  newest first, each captioned with its date, category and "Running balance". Edit; hide
  or show; delete, after a confirmation that names the number of transactions going with
  the account (`AccountRepository.delete` cascades). A linked account has no delete: it
  goes when its bank is unlinked (`items.md`); its menu has "Linked banks" instead, which
  opens the linked banks screen, where its bank syncs. "Add transaction" opens
  the editor on this account (`/transactions/new?account=<id>`).
- **Editor** (`account_editor_screen.dart`). Name (required), type (chips with icons),
  currency (a searchable full-screen picker over `Currency.minorUnitDigits`, default the
  device locale's currency through `defaultCurrencyCode()`, USD when intl has none). The
  currency is fixed once the account has transactions; a `CurrencyMismatchException` from
  the repository (deleted transactions count too) is explained in a snack bar. A new
  account takes an optional opening balance (signed: negative for money owed), parsed by
  `Money.parse` in the device locale and never rounded, which becomes a `manual`
  transaction named "Opening balance" on the date picked, today by default. The account
  and its opening balance are one repository write (`AccountRepository.create`): a
  failure leaves neither, and the editor stays open with the reason.
- **Refused writes.** Every account write (save, hide, show, reorder) that the repository
  refuses with `CurrencyMismatchException`, `EntityDeletedException` or
  `AccountNotFoundException` shows that exception's message in a snack bar
  (`account_errors.dart`); a refused reorder puts the list back in the stored order.

`test/features/accounts/presentation/linked_accounts_test.dart` checks the balance labels
(linked with a reported balance, linked never synced, manual), the totals, the as-of time
in another zone, the institution header, the mask's reading, the running balances'
captions and the menu's linked banks;
`test/features/accounts/application/running_balance_test.dart` the anchored running
balances on partial history; `test/features/linked_data_golden_test.dart` has the list and a linked account's detail
on the linked test data, light and dark.
