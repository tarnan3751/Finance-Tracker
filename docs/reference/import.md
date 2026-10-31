# Import

Transactions brought in from a bank's CSV export (`PLAN.md` §12, "CSV import design"):
the file is read and parsed, its columns mapped once and the mapping remembered for that
header, and its rows land on one account as `source: import`, a user-entered source that
syncs like a manual one (`PLAN.md` §7.1). Code: `app/lib/features/import/` (`domain/`, pure
Dart; `application/import_providers.dart`, the work; `data/demo_csv_picker.dart`, the
demo's sample; `presentation/`, the screen) and
`app/lib/core/platform/csv_picker_provider.dart`. Tests: `app/test/features/import/` (the flow in
`presentation/import_flow_test.dart`, the screens' accessibility in
`test/accessibility_test.dart`), and on a device `app/integration_test/import_test.dart`
(the harness: the demo's sample into a new account and its undo, then a Chase export
through the fake picker, each checked on the Accounts tab), with the fixtures under
`fixtures/` (the shapes of
a Chase checking export, a Bank of America export with its summary preamble, a Monzo export,
a European export with `;` and decimal commas, a UTF-16 and a Windows-1252 file, and the
app's own export; every name in them is fictional).

## Picking

The file comes through the backup picker's seam (`app-core.md`, **The backup picker**):
`csvPickerProvider`, the system's "open document" dialog showing `text/*`,
`application/csv` and `application/vnd.ms-excel` (the type Drive and many banks give a
CSV; a spreadsheet picked by mistake finds no table) in dev and prod. In the demo flavor it
is `DemoCsvPicker`: whatever is picked, a sample export of a fictional bank (Lakeshore
Mutual Bank, `lakeshore-mutual-checking.csv`: a title line, a blank line, then `Date`,
`Description`, `Amount`, `Balance`, sixteen rows over the last four weeks in `MM/dd/yyyy`)
built from the clock's today, so the same day gives the same file; its rows land as
`import` like any file's, the demo being where synthesis is allowed (`PLAN.md` §7.1), under
the demo banner.

`ImportActions.pick` holds the lock open while the dialog is up (`lock.md`), refuses a file
over 20 MB (`maxImportBytes`) unread, reads it in 1 MiB ranges into memory with its
SHA-256, and closes it whatever happens. `read` parses it, in an isolate (`compute`) past
256 KiB.

## Reading the file

`domain/text_decoding.dart` and `domain/csv_reader.dart`.

- **Encoding.** The first bytes are sniffed for a byte order mark: `EF BB BF` is UTF-8,
  `FF FE` UTF-16 little-endian, `FE FF` UTF-16 big-endian, each read after its mark (the
  UTF-16 decoder is the app's own, carrying a byte split across chunks). With no mark the
  file is read as strict UTF-8 and, when that fails, again as Windows-1252: what banks call
  Latin-1 is nearly always Windows-1252, whose 0x80 to 0x9F are printable (`€` is 0x80).
  A table read in that fallback is `lossy`, and the review says accented characters may be
  wrong. UTF-16 with no mark is not recognized.
- **Parsing.** The decoded text streams through the `csv` package's `CsvDecoder` (8.0.0,
  MIT), one row per event, every field kept as text (`dynamicTyping` off), blank lines
  skipped, quotes and doubled quotes and line breaks inside quotes honoured.
- **The delimiter.** One of `,` `;` tab `|`, given, or detected over the first 64 Ki
  characters by `detectDelimiter`: the one splitting the longest run of consecutive records
  into the same number of fields, at least three, counted with quotes respected, so a
  preamble or a comma inside a quoted description does not decide it (the package's own
  detection counts raw characters and is not used).
- **The header.** `findHeaderRow` (`domain/header_detection.dart`): the first row with at
  least three non-empty fields followed by a row of the same width, or wider only by blank
  fields (Chase ends every record but the header with a comma), so Bank of America's
  summary block is passed over.

## The mapping

`domain/import_mapping.dart`: an `ImportMapping` gives each `ImportRole` its column (date,
description, amount, or debit and credit, merchant, notes, category, tags), with the date
format, the decimal separator and "outflows are negative". The date and the description are
required, and the amount is one signed column or a debit and a credit column, never both: a
Monzo-style file has all three, and reading both would count each row twice.

- **Dates** (`domain/date_formats.dart`): `ImportDateFormat` is `yyyy-MM-dd`, `MM/dd/yyyy`,
  `dd/MM/yyyy`, `dd.MM.yyyy` or `yyyy/MM/dd`, read strictly (its separators, one- or
  two-digit days and months, four-digit years, a date that exists); a time after the date
  is ignored, since a transaction has a date (`PLAN.md` §6.8). `detectDateFormats` gives the
  formats that read the most samples, so one stray row does not hide the format; more than
  one means the order of day and month is ambiguous.
- **Amounts** (`domain/amount_parser.dart`, **Amounts**).

## Amounts

`parseMinorUnits` reads a field straight into minor units, never through a `double`:
currency symbols are stripped, and so is one currency word at the start or the end beside
the number (an ISO code the app knows, `Currency.isKnown`, as in `USD 12.34`, or `kr`,
`12,50 kr`); any other letter refuses the field, so `12.00 DR` or `12.00 DBT` is never read
as a credit; whitespace (no-break spaces
included) goes too; parentheses, or a minus in front or at the end (`-` or U+2212), make
it negative, and a `+` in front is allowed (one sign only); the decimal separator is the
mapping's, and the other one or `'` groups thousands before it, in groups of exactly three
digits after a first group of one to three, so a field written with the other separator
(`12,50` read with a point, `-82.17` with a comma, `,5`, `1,2,3.4`) is refused and its
row listed as skipped rather than misread; the digits become an integer as written, padded to the
currency's digits (`Currency.scaleOf`) or rounded half-even past them (`1.005` dollars is
100 cents, `1.015` is 102), and a value beyond `Money`'s range is refused.
`detectDecimalSeparator` reads each sample's last `.` or `,` as decimal unless it repeats
(then it groups) or it is the only one with exactly three digits after it (`1,234` says
nothing); the majority wins, and a tie is no answer.

## Conversion

`convertRows` (`domain/row_conversion.dart`) turns the rows after the header into
`ImportedRow`s, numbered as rows of the file (from 1, blank lines not counted), or
`RowFailure`s with their `RowProblem`: a date not in the format, no amount, an amount that
does not read, a zero amount, both a debit and a credit, or neither a description nor a
merchant (the merchant stands in for a blank description). With debit and credit columns
the amount is the credit's magnitude less the debit's, so either sign convention in those
columns reads the same; "outflows are negative" off negates a signed amount, for exports
where spending is positive. A field past the end of a short row is blank. Tags are read
only from a mapped tags column, split on `;` and trimmed, duplicates dropped; a field with
no `;` is one tag.

## Duplicates

`likelyDuplicates(incoming, existing)` (`domain/import_duplicates.dart`) gives the incoming
rows that are likely already on the account, either way:

- a pair the duplicates detector (`duplicates.md`) finds among the existing and incoming
  rows that joins an incoming row to an existing one; on one account that is a bank row
  and an entered one;
- a re-import: the detector never pairs two entered rows of one account, so the same file,
  or an overlapping export, imported again into a manual account is caught by an incoming
  row repeating an existing `manual` or `import` row of the account with the same date,
  amount and name (trimmed, case folded, whitespace collapsed). Each existing row answers
  for one incoming row, so two identical coffees in the file against one stored are one
  duplicate and one new row; a hidden existing row counts, a deleted one does not.

Either way each existing row answers for one incoming row: the re-import matches first,
then the detector's pairs nearest in date first (then the incoming row's place in the
file, then the existing row's id), so on a linked account two identical incoming rows
against one bank row are one duplicate and one new row. Two incoming rows never mark each
other.

## Presets and imports

`domain/import_records.dart`, kept in `app_meta` as JSON lists, newest first, at most
twenty each, on this device only (never synced; they travel in a backup with `app_meta`):

- an `ImportPreset` per header (`import_presets`), keyed by `headerSignature` (the SHA-256
  of the header's trimmed fields joined by U+001F): each role's column by its header text
  and its occurrence among headers with that text, the amount mode, the date format, the
  separator, the sign switch, the delimiter, the header row, the account and when it was
  saved; a preset for a header replaces the earlier one;
- an `ImportBatch` per import (`import_history`): its id, when it was written (a UTC
  instant), the file's name and SHA-256, the account, the count, the transaction ids,
  whether it is still `pending` (**Writing**), and when it was undone. Twenty are kept: a
  twenty-first import retires the oldest record, and with it that import's Undo.

A stored value that does not decode is an `ImportRecordsFormatException`, which the caller
logs by type and reads as an empty list.

## Writing

`ImportActions.review` reads the rows through the mapping into `Transaction`s on the target
account (an existing one, or a new manual account by name, type and currency, whose
currency is then the import's): new UUIDs, `source: import`, `pending: false`, the name,
the merchant column as `merchantName` (an `import` row's merchant is the file's, not
Plaid's), notes, tags, and the category matched by name ignoring case among the live
categories (the first in their order when names repeat; an unmatched name leaves it
uncategorized). It marks the likely duplicates against the target account's live rows,
hidden ones included, from three days before the file's first date to three after its
last (a new account has none), and says whether a live import of a file with the same
SHA-256 is recorded. Past 256 KiB the conversion and the duplicate marking run in an
isolate (`compute`), as the parse does, and the review's totals (count, dates, money in
and out, with and without the duplicates) are summed once, when it is made.

`write(review, includeDuplicates:)` then, in an order that never leaves rows without a
record that undoes them:

1. creates the new account when one was asked for (`AccountActions.create`);
2. records the batch as `pending`, with the ids of its rows, which are known up front;
3. writes the rows, without the duplicates unless asked, in one
   `TransactionRepository.upsertAll` (all or nothing), stamped with the clock's now; the
   change recorder records each for sync as it records a manual row (the demo records
   nothing); a refused batch drops the pending record, soft-deletes the account it just
   created and rethrows, and the screen says the import failed;
4. runs the user's rules on them (`arrivalProcessorProvider`, `rules.md`, **On
   arrival**), each change an upsert of its own after the batch;
5. rewrites today's balance snapshots (`SnapshotWriterRunner.writeNow`, `net-worth.md`;
   a failure is logged), and the widgets follow the data (`widgets.md`);
6. marks the batch complete and saves the preset for the header (with the account). A
   failure here leaves the rows in and is reported as imported, but with the history not
   saved.

`ImportActions.history` (behind `importHistoryProvider`) sorts out an import cut short
between steps 2 and 6, by a kill or a failed write: a `pending` batch any of whose rows is
stored is marked complete, one whose rows never landed is dropped once it is more than two
minutes old by the clock (`pendingGrace`; a younger one may be a write still under way,
read by the other route's screen, and stays pending), and the history is written back. The actions are made with every collaborator they use, the snapshot
runner's `writeNow` included, so a write that outlives its provider, or the screen, still
finishes.

The write is all or nothing on purpose (`PLAN.md` §12, "9a plan rulings"): a bank export
is hundreds to a few thousand rows, and 10,000 rows take about 12 s on the development
Mac (Drift in memory, the change recorder on; the parse and review about a quarter of a
second), most of it the one `upsertAll`. While it runs the screen shows its progress bar
and back is held. A chunked import is later scope.

`undo(batch)` deletes the batch's transactions still live, edited ones included, through
`TransactionActions.deleteAll` (one write, tombstones that sync; their receipt photos
go too), rewrites today's snapshots and marks the batch undone. The record is on the
importing device only, so another device that synced the rows has no Undo for them, and an
account the import created stays.

Logs carry counts and exception types only, never a file name, a name or an amount.

## The screen

`presentation/import_screen.dart`, at `/settings/import` (Settings → Data → Import
transactions) and `/transactions/import` (the transaction list's menu): one flow in steps
on one page, back stepping back through them (review to mapping, mapping to the start)
before it leaves.

- **The start.** What the import does, "Choose a CSV file", and under **Imports** this
  device's imports, newest first: the file's name ("Unnamed file" without one), how many
  transactions and the local date, "undone" once undone, and "Undo this import", which asks
  first ("This deletes the N transactions this import added, including any you have
  edited since.") and says "Import undone". A file over the cap, one the dialog or the
  read failed on, one that is not text (a byte order mark over bytes that do not decode),
  or one with no table is told there, and nothing else changes.
- **The mapping screen** (`import_mapping_view.dart`). The file's header row (the first
  twenty rows offered, each as its row number and first fields) and field separator (a
  change reads the file again and detects the header); the amount as one column or money
  out and in; a column for each role (date, description, amount or money out and money
  in, then merchant, notes, category and tags, "Not used" for the optional ones), each
  column offered by its header with a sample value; the date format, detected from the
  date column: when the order of day and month is ambiguous, each reading is offered with
  the file's first three dates read that way ("03/10/2026 is Mar 10, 2026"), the one in
  the device locale's order chosen to start with; otherwise a choice of every format,
  saying so when none reads the column; the decimal separator, detected from the amount
  columns and asked to be checked when they do not say (a comma to start with when the
  fields are separated by `;`, else a point); "Money out is negative" for one amount
  column; and the account, an existing one or "New manual account" with its name, type
  and currency (the device locale's to start with). The preset for the header, when there
  is one, fills it all ("Mapped as you mapped this layout last time."), the account only
  while it is live. Review is enabled once the required columns, a date format and an
  account are chosen; a review that cannot be prepared (the account's rows not read, say)
  is told under the mapping, which stays as it was, back working again.
- **The review screen** (`import_review_view.dart`). How many transactions will be
  written, their date range, the money in and out; that the file was read in the 8-bit
  fallback, or imported before; the rows skipped, folded, each with its row number and
  reason; "Import N likely duplicates anyway" (off by default) when there are any; Import
  (disabled with nothing to write); then every row (name, date, "Likely duplicate" where
  it is one, amount), each read by a screen reader as one summary.
- **The result.** How many were imported into which account and how many duplicates were
  skipped (and, when the record could not be saved, that the rows are in but cannot be
  undone from here), "View account" and "Import another file", above the imports.
- **Leaving.** Back is held while a file is read or written (the progress bar shows), and
  so is a second Undo while one runs. After every await the screen checks it is still
  there, so a read or a write that ends after it is gone is dropped (the write itself
  completes).
