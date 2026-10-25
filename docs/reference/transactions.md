# Transactions

The transaction list with its search and filters, the merchant each row shows, and the
transaction editor, which is also a transaction's detail. Code:
`app/lib/features/transactions/` (`application/`, `presentation/`, and
`domain/effective_category.dart`, `enrichment.dart`, `merchant_dictionary.dart`; the
repository and
`TransactionQuery` are `data.md`'s). Tests:
`app/test/features/transactions/`, `app/test/flows/`, and on a device
`app/integration_test/transactions_bulk_test.dart` (the harness).

## The list

`transactions_screen.dart`. Every account's transactions, newest first, under date
headers: "Today" and "Yesterday" from `todayProvider` (the clock's today in the device zone,
re-read at midnight and on resume), the weekday for
the rest of the last week, then the full date, through intl's `DateFormat` in the device
locale (`transaction_dates.dart`). A row (`transaction_tile.dart`, built from plain values,
no stream per row) shows the merchant's avatar and name (**Merchants**), the account and
the effective category (**The effective category**; "Uncategorized" when there is none),
the amount colored by `FinanceColors`, a "Pending" label, and a "Hidden" label on a
transaction the user hid (**Hiding**). The account detail's ledger rows are the same
tile, with the effective category and the running balance; the ledger lists hidden rows,
labelled, since they count toward the balance.

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
  disables Apply), tags, and "Show hidden" (off by default; on, it lights the filter
  badge and shows an "Including hidden" chip that turns it off). A preset is kept as a preset and
  resolved against `todayProvider` each time the query is built (`DateFilter.rangeOn`), so
  "This month" follows the calendar, past midnight included. Active filters show as chips under the app bar, each
  removing its filter.

`TransactionFilters` and `DateFilter` are in `application/transaction_filters.dart`;
`toQuery(today, limit:)` makes the `TransactionQuery`, with `hidden: false` unless
`showHidden`.

## Hiding

`Transaction.hidden` is the user's override (`PLAN.md` §12): a hidden transaction still
counts toward its account's balance, since the money moved, and is left out of the
default list, budgets and reports. It is set from the editor's menu, by bulk edit or by
a rule's `hide` (`rules.md`), on any source; on a `plaid` row it is recorded as an
override like the category (`sync-app.md`), so it survives the bank's later updates.

## Bulk edit

A long press on a row starts selection mode (`transactions_screen.dart`): each row shows
a checkbox in the avatar's place and a tap toggles it (unticking the last leaves the
mode); the app bar shows the count (read as "N selected"), Cancel, and the actions Set
category (the category picker, "None" included), Add tag (a prompt; rows that carry the
tag are left alone), Hide, or Unhide when every selected row is hidden, Delete (enabled
when no selected row is `plaid`, after a confirmation naming the count; no undo), and in
its menu Select all (the rows loaded). Back and Cancel leave it, and a row that leaves
the list (hidden, deleted, filtered out) leaves the selection. Each action ends selection
and writes the rows it changes, read again from the repository when it runs, in the
same sync-store transaction as the write (the database's in dev and prod, none in the
demo), so an edit synced since the selection is kept, a row deleted since is skipped,
and nothing synced in between is written back; stamped `updatedAt`, through one
`TransactionRepository.upsertAll` (Delete through `deleteAll`, `data.md`), so it is one
recorded batch, all or nothing; a snack bar gives the count changed, or says nothing
changed when the batch was refused (a row deleted meanwhile, say). A `plaid` row takes
the category, tags and hidden only, which is all these actions change.

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

## Merchants

A row's name and avatar come from `EnrichedMerchant.resolve(transaction)`
(`domain/enrichment.dart`, pure Dart), the enrichment fallback of `PLAN.md` §7.1 Tier B
and §12:

- **Name.** Plaid's `merchantName` when present, never replaced; else, for a `manual`
  transaction, its description as typed; else the dictionary's name for the raw `name`;
  else the raw name cleaned (`cleanMerchantName`: the leading noise skipped, then the words
  up to the first carrying a digit or masked digits or following a `#`, a `*` or a spaced
  dash, in title case when the raw name is all capitals, acronyms and company suffixes
  such as ATM, LLC and IRS kept in capitals).
- **Logo.** Plaid's `merchantLogoUrl`, untouched (a public CDN URL, loaded by
  `MerchantAvatar` through `Image.network`); null when Plaid gave none. No logo is bundled.
- **Color.** The dictionary's brand color for Plaid's merchant name or the raw name, else
  `paletteColor(name)`: one of twelve Material 800 shades by a 32-bit FNV-1a hash of the
  normalized name, the same on every device and run. `institutionColor` is Plaid's
  `primary_color`, else the palette color of the institution's name.

**The dictionary** (`domain/merchant_dictionary.dart`, `merchantDictionary`) holds about 150
merchants, each a display name, the raw-name prefixes that mean it and an ARGB brand color
where the brand has a well-known one. `lookupMerchant` normalizes the raw name
(`normalizeMerchantText`: lower case, apostrophes dropped, other punctuation a space) and
matches a key as the whole first words, longest first, trying again after each piece of
leading noise is skipped: a processor's prefix before a `*` (`SQ *`, `TST*`, `PAYPAL *`,
`DNH*`, ...), numbers, dates, masked digits (`XXXX`), and card words (`POS PURCHASE`,
`PURCHASE AUTHORIZED ON`, `CHECKCARD`, `INTERAC PURCHASE`, ...). So `NETFLIX.COM` is
Netflix, `INTERAC PURCHASE - 67200 TARGET #052` Target, and `APPLEBEES` never Apple.

Nothing is written: like the effective category the fallback is display-side, so a
fallback name never reaches the database, the change log, the server or a Plaid field.
`test/features/transactions/domain/enrichment_test.dart` runs it over the 316 raw names
Plaid Sandbox returned (`test/fixtures/plaid_transaction_names.json`, names only, from the
server's `transactions_sync_page1.json` fixture); `transaction_tile_test.dart` checks the
rows (logo, dictionary hit, cleaned name, pending).

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
- **Running the rules.** The app bar's menu has "Run rules on this transaction", for a new
  transaction too: the rules (`rules.md`) apply to the values in the form, which it
  validates first; the description, category and tags they change fill the form, a snack
  bar names the rule (or says none matches, or that it had nothing to change), and only
  Save writes the result, recorded like any edit. Nothing runs the rules on a manual
  entry by itself.
- **Hidden.** The menu's "Hidden", checked when the transaction is hidden, toggles the
  form's value (a rule's `hide` checks it too); Save writes it.
- **Deleting.** A Plaid transaction has no Delete: only the bank removes one (`data.md`).
  Delete soft-deletes and shows "Transaction deleted" with Undo for five
  seconds in the tab's own messenger, so it appears on the screen below, above the
  navigation bar, with that screen's floating button lifted over it (`undoDuration`; `persist: false`, since a snack bar with an action otherwise
  stays); Undo calls `TransactionRepository.restore`, and an account deleted in the
  meantime is explained.

`transactionUsageProvider` (`TransactionRepository.watchUsage`, `data.md`: limited and
distinct queries, never a scan of every transaction) gives the editor and the filter sheet
the tags in use and the recently used categories and accounts;
`transactionActionsProvider` makes the writes, the bulk ones included (`setCategory`,
`addTag`, `setHidden`, `deleteAll`).
