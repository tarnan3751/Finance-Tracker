# Import

Transactions brought in from a bank's CSV export (`PLAN.md` §12, "CSV import design"):
the file is read and parsed, its columns mapped once and the mapping remembered for that
header, and its rows land on one account as `source: import`, a user-entered source that
syncs like a manual one (`PLAN.md` §7.1). Code: `app/lib/features/import/` (`domain/`, pure
Dart). Tests: `app/test/features/import/`, with the fixtures under `fixtures/` (the shapes of
a Chase checking export, a Bank of America export with its summary preamble, a Monzo export,
a European export with `;` and decimal commas, a UTF-16 and a Windows-1252 file, and the
app's own export; every name in them is fictional).

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
  instant), the file's name and SHA-256, the account, the count, the transaction ids, and
  when it was undone.

A stored value that does not decode is an `ImportRecordsFormatException`, which the caller
logs by type and reads as an empty list.
