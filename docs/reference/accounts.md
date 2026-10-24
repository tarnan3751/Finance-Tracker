# Accounts

The account list, an account's detail and the account editor. Code:
`app/lib/features/accounts/` (`application/`, `presentation/`; the repository is
`data.md`'s). The linked banks are `items.md`'s. Tests: `app/test/features/accounts/`, `app/test/flows/`. The routes are in
`app-core.md`, **Routing and the shell**.

## Balances

Every balance on these screens is derived from transactions (`PLAN.md` §6) and captioned
"from transactions"; nothing stores one. An account with no transactions shows zero.
Phase 3's institution-reported balances (`Account.currentBalance`) get a different caption.

| Provider (`application/accounts_providers.dart`) | What |
|---|---|
| `accountsProvider` | `AccountRepository.watchAll()` |
| `accountsByIdProvider` | The live accounts by id, for screens that name an account |
| `derivedBalancesProvider` | `watchDerivedBalances()` |
| `accountProvider(id)` | `watchById(id)` |
| `accountLedgerProvider(id)` | The account's transactions newest first, each with the running balance after it (`withRunningBalances`: summed oldest to newest, then reversed) |
| `accountTransactionCountProvider(id)` | How many live transactions the account has (the editor's currency lock) |
| `accountActionsProvider` | `AccountActions`: `create`, `update`, `setHidden`, `reorder`, `delete` |

## Screens

- **List** (`accounts_screen.dart`). One card per visible account: type icon, name, type
  label, derived balance. When the visible accounts hold more than one currency, a
  "Totals" row at the top has one total per currency, never converted (`PLAN.md` §3).
  Hidden accounts are in a collapsed "N hidden accounts" section. A long press drags a
  card (`ReorderableListView`), and the drop writes `displayOrder` 0, 1, 2... to the
  visible accounts whose order changed. With large text the balance moves under the name.
  "Add account" is the floating button, or the empty state's action. The app bar's
  "Linked banks" opens the linked banks (`items.md`).
- **Detail** (`account_detail_screen.dart`). The type, the derived balance, then the
  transactions newest first, each captioned with its date, category and "Running balance".
  Edit; hide or show; delete, after a confirmation that names the number of transactions
  going with the account (`AccountRepository.delete` cascades). A linked account has no
  delete: it goes when its bank is unlinked (`items.md`). "Add transaction" opens
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
