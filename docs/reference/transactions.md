# Transactions

The transaction list with its search and filters, and the transaction editor, which is
also a transaction's detail. Code: `app/lib/features/transactions/` (`application/`,
`presentation/`, and `domain/effective_category.dart`; the repository and
`TransactionQuery` are `data.md`'s). Tests:
`app/test/features/transactions/`, `app/test/flows/`.

## The list

`transactions_screen.dart`. Every account's transactions, newest first, under date
headers: "Today" and "Yesterday" from `todayProvider` (the clock's today in the device zone,
re-read at midnight and on resume), the weekday for
the rest of the last week, then the full date, through intl's `DateFormat` in the device
locale (`transaction_dates.dart`). A row (`transaction_tile.dart`, built from plain values,
no stream per row) shows the category's icon, the merchant name or else the description,
the account and the effective category (**The effective category**; "Uncategorized" when
there is none), the amount colored by `FinanceColors`, and a "Pending" label. The account
detail's ledger rows show the effective category too.

- **Paging.** `TransactionListController` holds the filters and how many pages are loaded;
  `transactionPageProvider` watches the repository with `limit` = pages × 50
  (`transactionPageSize`), and the list asks for one more page when it is scrolled within
  600 pixels of its end. `loadMore(loaded:)` adds a page only when the transactions loaded
  fill every page asked for, so the many scroll events before the next page arrives ask
  for one page. A change of filters goes back to the first page. A widget test
  checks that with 2,000 transactions only the rows on screen are built.
- **Search.** The app bar's search field sets `TransactionFilters.text`.
- **Filters** (`transaction_filter_sheet.dart`, a bottom sheet). Accounts, categories
  (through the category picker; a top-level category takes the categories under it along,
  the query's category set being expanded with their ids, and every category included
  brings its Plaid code, so the filter matches the effective category), a date range (`DatePreset`: this month, last month, the
  last 90 days, this year, or a custom range from the range picker), an amount range
  (absolute amounts in one currency, chosen among the accounts' currencies when there is
  more than one; invalid input, or a maximum below the minimum, is an inline error that
  disables Apply) and tags. A preset is kept as a preset and
  resolved against `todayProvider` each time the query is built (`DateFilter.rangeOn`), so
  "This month" follows the calendar, past midnight included. Active filters show as chips under the app bar, each
  removing its filter.

`TransactionFilters` and `DateFilter` are in `application/transaction_filters.dart`;
`toQuery(today, limit:)` makes the `TransactionQuery`.

## The effective category

A transaction is shown and filtered under its effective category (`PLAN.md` §12):
`userCategoryId` when it names a live category; else the system category whose
`plaidCategory` is the transaction's `plaidDetailedCategory`; else the one whose
`plaidCategory` is its `plaidPrimaryCategory`; else none, "Uncategorized". A deleted or
unknown user category counts as unset. `effectiveCategory` and `plaidCategoryOf`
(`domain/effective_category.dart`, pure Dart) resolve it from a `CategoryLookup` (the live
categories by id and by Plaid code), which `transactionCategoryLookupProvider` builds once
from the categories stream for the list, the account ledger and the editor. The resolution
never writes `userCategoryId`: it stays the user's explicit choice, so sync and the
override rules see only what the user did.

The category filter matches the same rule: `toQuery` passes the Plaid codes of the
categories included (`plaidCodeOf`) as `TransactionQuery.categoryPlaidCodes` next to their
ids, and each repository matches a transaction with no live user category by the code that
resolves, the detailed one taking precedence over the primary (`data.md`). The counts
behind "N transactions will become uncategorized" pass ids only, so they count
`userCategoryId` (and splits): deleting a user category never changes a Plaid-resolved
category, and system categories cannot be deleted.

## The editor

`transaction_editor_screen.dart`, for `/transactions/new` and `/transactions/:id`.

- **Fields.** Expense or income (a `SegmentedButton` that sets the sign); the amount,
  unsigned, parsed by `Money.parse` in the device locale for the account's currency, with
  the currency's symbol as prefix; empty, zero, signed, misplaced separators and more
  decimals than the currency has are inline errors, never rounded (`amount_input.dart`);
  the account (default: the route's `account`, else the only account, else the most
  recently used account, else the first); the date (today by default, from
  the clock); the description (required; it is `Transaction.name`); the category (a
  full-screen picker: search, "None", recently used, the hierarchy, and "Manage" to
  category management; the picker's selection is the user's own choice, and with none
  the row shows the category the Plaid code resolves to, captioned "From your bank's
  category", so the user sees what a choice would override); notes; tags (typed, added on enter or a comma, with suggestions
  from the tags in use).
- **Saving.** A new transaction is `source: manual`, `pending: false`, with `createdAt` and
  `updatedAt` from the clock. An edit changes only the fields above and `updatedAt`; the
  source, the merchant name, the splits, the Plaid fields and `createdAt` stay as they
  were, so an imported or demo transaction keeps its provenance. The repository's
  `AccountNotFoundException`, `CurrencyMismatchException` and `EntityDeletedException` are
  explained in a snack bar.
- **Deleting.** Delete soft-deletes and shows "Transaction deleted" with Undo for five
  seconds in the tab's own messenger, so it appears on the screen below, above the
  navigation bar, with that screen's floating button lifted over it (`undoDuration`; `persist: false`, since a snack bar with an action otherwise
  stays); Undo calls `TransactionRepository.restore`, and an account deleted in the
  meantime is explained.

`transactionUsageProvider` (`TransactionRepository.watchUsage`, `data.md`: limited and
distinct queries, never a scan of every transaction) gives the editor and the filter sheet
the tags in use and the recently used categories and accounts;
`transactionActionsProvider` makes the writes.
