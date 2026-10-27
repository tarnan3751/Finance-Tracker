# Transactions

The transaction list with its search and filters, the merchant each row shows, and the
transaction editor, which is also a transaction's detail, with its splits and receipt.
Code: `app/lib/features/transactions/` (`application/`, `presentation/`, and
`domain/effective_category.dart`, `enrichment.dart`, `merchant_dictionary.dart`,
`split_math.dart`; the repository, `TransactionQuery` and the receipt store are
`data.md`'s, the image source `app-core.md`'s). Tests:
`app/test/features/transactions/`, `app/test/flows/`, and on a device
`app/integration_test/transactions_bulk_test.dart`, `transactions_search_test.dart` and
`splits_receipts_test.dart` (the harness).

## The list

`transactions_screen.dart`. Every account's transactions, newest first, under date
headers: "Today" and "Yesterday" from `todayProvider` (the clock's today in the device zone,
re-read at midnight and on resume), the weekday for
the rest of the last week, then the full date, through intl's `DateFormat` in the device
locale (`transaction_dates.dart`). A row (`transaction_tile.dart`, built from plain values,
no stream per row) shows the merchant's avatar and name (**Merchants**), the account and
the effective category (**The effective category**; "Uncategorized" when there is none,
"Split" for a transaction with splits, `transactionCategoryLabel`),
the amount colored by `FinanceColors`, a "Pending" label, and a "Hidden" label on a
transaction the user hid (**Hiding**). The account detail's ledger rows are the same
tile, with the same category label and the running balance; the ledger lists hidden rows,
labelled, since they count toward the balance.

- **Paging.** `TransactionListController` holds the filters and how many pages are loaded;
  `transactionPageProvider` watches the repository with `limit` = pages × 50
  (`transactionPageSize`), and the list asks for one more page when it is scrolled within
  600 pixels of its end. `loadMore(loaded:)` adds a page only when the transactions loaded
  fill every page asked for, so the many scroll events before the next page arrives ask
  for one page. A change of filters goes back to the first page. A widget test
  checks that with 2,000 transactions only the rows on screen are built.
- **Search.** The app bar's search field sets `TransactionFilters.text` 250 ms after the
  last keystroke (`TransactionsScreen.searchDebounce`); Close clears it at once, a
  pending keystroke included, and closes the field. The text is split into terms on
  whitespace, and each term must be found as words in a row, the last one a prefix, in
  the name, the merchant name, the notes or the tags, ignoring case and Latin diacritics:
  `cafe` finds "Café Crème", `acme pay` "Acme Corp Payroll", `o'bri` "O'Brien's", and
  `uber work` an Uber ride tagged `work`. Punctuation separates words and is never an
  operator (`NEAR`, `OR`, `-x` and `"` are plain text); a term with no letter or digit
  matches nothing. The order stays the list's date order. How the index does it, and the
  LIKE fallback on a SQLite without FTS5, are `data.md`'s **Full-text search**. A search
  that finds nothing says "No matches for “text”".
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
- **Duplicates.** Outside selection mode, the app bar's menu has "Review duplicates",
  with a badge on the menu button counting the likely duplicate pairs
  (`duplicateCandidatesProvider`); it opens the duplicate review (`duplicates.md`).

`TransactionFilters` and `DateFilter` are in `application/transaction_filters.dart`;
`toQuery(today, limit:)` makes the `TransactionQuery`, with `hidden: false` unless
`showHidden`.

## Saved filters

The filter sheet's "Save these filters" (enabled when the sheet or the search holds
something and nothing in it is invalid) asks for a name, trimmed and not empty (duplicates
are allowed), and saves what the sheet holds with the list's search text, after the other
saved filters; the sheet stays open. Its "Saved" section, first in the sheet, lists them:
a tap applies one, its search text filling the search field, and closes the sheet; the
menu ("Options for …") renames one or deletes it after a confirmation. The list leads its
chips with the name of the saved filter its filters equal (`appliedSavedFilterProvider`:
the first in order, derived, so a rename shows at once and any change of the filters
drops it); that chip clears the search and every filter.

A saved filter holds `TransactionFilters.toJson`: only what is set, ids and tags sorted, a
date preset by name (`this_month`, `last_month`, `last_90_days`, `this_year`; resolved
only when a query is built, so "This month" stays this month), a custom range as ISO
`start` and exclusive `end`, amounts as `Money`'s JSON, `show_hidden`. `fromJson` ignores
keys it does not know and refuses a known key of the wrong shape (`FormatException`);
`savedFiltersProvider` decodes each once and leaves out, logging only the exception's
type, one that does not decode, so it can never take the list or the sheet down.
Saved filters are kept on the device only in Phase 4 (`PLAN.md` §12): the
`SavedFilterRepository` (`domain/saved_filter_repository.dart`, `data.md`) holds the JSON
opaquely in `saved_filters`; nothing is synced or recorded. The demo flavor starts with
two (`data/demo_saved_filters.dart`): "Food and drink this month" and "Over $100, last 90
days".

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
The recurring detector groups transactions by the same name, normalized
(`recurringMerchantKey`, `recurring.md`), so a stream and its rows always agree on the
merchant.
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
  category", so the user sees what a choice would override; with splits it reads "Split
  across N categories" and is not tappable); the splits (**Splits**); notes; tags (typed,
  added on enter or a comma, with suggestions from the tags in use); the receipt
  (**Receipts**).
- **Saving.** A new transaction is `source: manual`, `pending: false`, with `createdAt` and
  `updatedAt` from the clock. An edit changes only the fields above and `updatedAt`; the
  source, the merchant name, the Plaid fields and `createdAt` stay as they were, so an
  imported or demo transaction keeps its provenance. The repository's
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
  meantime is explained. The receipt photo stays through the undo and is deleted when
  the snack bar closes by anything but Undo (`data.md`, **Receipts**).

## Splits

The editor's split section (`transaction_editor_screen.dart`) divides a transaction's
amount across categories. It shows "Add split" alone while there are none, so a
transaction without splits looks as before; else a "Splits" heading, one row per split
(a category from the picker, "None" not offered, over an amount field, with "Remove
split"), a running line, "Add split" and "Distribute evenly".

- **Amounts.** A split amount is typed without a sign, parsed like the transaction's
  (`Money.parse` in the account's currency, never rounded, zero refused), and saved with
  the transaction's sign, so an expense's splits are negative. A split in the opposite
  direction cannot be entered; a stored one is kept while its rows are untouched
  (below).
- **The sum rule.** The running line reads "Unallocated $12.34" while the splits fall
  short of the amount's magnitude and "Over by $1.00" past it (`split_math.dart`,
  `unallocated`). Save is refused while a split has no category ("Choose a category for
  every split") or the splits do not add up ("Splits must add up to $130.00"); the error
  follows the edits once shown. A single split of the whole amount is valid, and a
  category may repeat.
- **Stored splits kept as they are.** While no split row has been edited, added or
  removed and the amount (its sign and currency included) is the stored one, Save
  writes the stored splits back unchanged and skips the sum rule, and the running line
  shows what they leave of the amount as signed. So splits of mixed signs synced or
  imported from elsewhere (−$120.00 and +$20.00 on −$100.00), or a gap left when the
  bank changed a split Plaid transaction's amount, never block an unrelated edit such
  as the notes. Once a row is touched or the amount changes, the rows are read as
  magnitudes and the sum rule applies.
- **Distribute evenly** gives every row the amount's magnitude divided by
  `Money.split(n)` and reversed (`distributeEvenly`), so the parts sum exactly, differ by
  at most one minor unit, and the larger ones are the last rows: $10.00 in three is
  3.33, 3.33, 3.34.
- **The category.** A split transaction is categorized by its splits (`PLAN.md` §12):
  Save writes no `userCategoryId` while there are splits, and the list names it "Split".
  Removing every split brings back the category row with the choice the form had.
  Rules running on the form see its splits, so `setCategory` leaves it alone (`rules.md`).
- A split's note, which the editor does not show, is kept as it was.

## Receipts

A receipt photo is attached in the editor's last section (`receipt_view.dart`), saved
with Save, and kept on the device only (`data.md`, **Receipts**).

- **Adding.** "Take photo" and "Choose photo" ask the image source (`app-core.md`,
  **The image source**): the camera or the gallery through `image_picker` in dev and
  prod, the demo receipt in the demo flavor. A cancelled pick changes nothing; a device
  with no camera app, or an image that cannot be used (malformed, or neither a JPEG nor
  a PNG, so its metadata could not be stripped), is explained in a snack bar.
- **Showing.** A thumbnail, read as "Receipt image" with "open the receipt full screen"
  as its action, opens the photo full screen (`ReceiptViewScreen`, pushed without a
  route of its own), zoomable. Photos are shown from their bytes, so a replaced one,
  which keeps its path, never shows the old picture.
- **Replace** (camera or gallery, from a sheet) and **Remove receipt** change the form;
  Save writes them. A new photo is committed only once the transaction's write has
  succeeded, so a failed save leaves the receipt as it was; a removed one's file goes
  after the write.
- **Another device's receipt.** A `receiptPath` whose photo this device does not have
  (receipts never sync) shows "Receipt kept on another device", with Replace and Remove.
- A Plaid transaction takes a receipt like its category: `receipt_path` is one of the
  fields the user owns on it (`sync-app.md`).

`transactionUsageProvider` (`TransactionRepository.watchUsage`, `data.md`: limited and
distinct queries, never a scan of every transaction) gives the editor and the filter sheet
the tags in use and the recently used categories and accounts; `receiptProvider(path)`
the bytes of a receipt photo, or null when this device has none;
`transactionActionsProvider` makes the writes, the bulk ones included (`setCategory`,
`addTag`, `setHidden`, `deleteAll`, which also deletes the receipt photos), and the
receipt sweep (`sweepReceipts`).
