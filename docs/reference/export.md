# Export

The monthly report as a PDF whose bytes are the same on any device, and the transactions
as a CSV, each saved through the system's "Save as" dialog or shared. The decisions are
in `PLAN.md` §12: "Export" and "6f plan rulings". CSV import is Phase 9's; the encrypted
backup is Phase 7's.

Code:
- `app/lib/features/export/domain/` (pure Dart, integer `Money` only):
  - `transactions_csv.dart`: the CSV;
  - `monthly_report.dart`: what the PDF is drawn from;
  - `monthly_report_pdf.dart`: the PDF and its texts.
- `application/export_providers.dart`: the report's data for a period, the fonts, the
  texts from the ARB, the file names and the CSV's bytes.
- `presentation/`:
  - `export_screen.dart`: the screen;
  - `report_export_menu.dart`: the Reports segment's menu and sheet;
  - `export_runner.dart`: one export run, the buttons and the privacy note.
- The platform boundary is `core/platform/file_exporter.dart` (`app-core.md`, **The file
  exporter**). The packages and the fonts are in `build.md`.

Tests:
- `app/test/features/export/domain/`: the CSV's golden and its edge cases, the PDF's
  hash golden, its determinism and its metadata;
- `application/`: the report's data over the in-memory repositories;
- `presentation/`: the screen, the Reports menu, and their goldens, light and dark at text
  scale 1 and 2;
- the Export and Reports export sheet entries of `app/test/accessibility_test.dart`;
- `app/test/core/platform/file_exporter_test.dart`: the boundary;
- on the harness, `app/integration_test/export_test.dart`: the fixture's PDF hashed on the
  device against the host's hash, and Share from Settings in the demo flavor.

## The CSV

`transactionsCsv(transactions, {accounts, lookup, range, accountIds})` writes one record
per live transaction dated in the range on the chosen accounts, sorted by date, then id.
- **Rows.** Deleted rows are left out. Hidden and pending rows are written, with their
  flags. A transaction with splits is one record under its own effective category; its
  splits are not written.
- **Format.** RFC 4180: fields separated by commas, every record ended by CRLF (the last
  one too). A field is quoted only when it holds a comma, a double quote, a CR or an LF,
  and its double quotes are doubled. UTF-8 with no byte order mark.
- **Fields as stored.** Nothing is localized or rewritten, so the Phase 9 import reads
  them back, with one known limit: the tags are joined by `;` without escaping, so a tag
  that itself holds `;` reads back as two (the Phase 9 import defines the escaping). A
  text field that starts with `=`, `+`, `-` or `@` is written as it
  is, by ruling: a spreadsheet may read such a field as a formula, and opening the file
  in one is the user's choice.

| Column | What |
|---|---|
| `date` | The ISO date |
| `account` | The account's name; empty for an account that is gone |
| `merchant` | The stored merchant name (not the enriched display name); empty when none |
| `name` | The stored name |
| `amount` | `Money.toDecimalString()`, in the app's sign (an outflow is negative): `-1234.56`, `-1500` for yen, `-12.345` for dinars |
| `currency` | The ISO code |
| `category`, `parent_category` | The effective category's name and its live parent's (`transactions.md`); empty when uncategorized |
| `pending`, `hidden` | `true` or `false` |
| `tags` | Joined by `;` |
| `notes` | The notes; empty when none |
| `source` | The provenance: `plaid`, `manual`, `import`, `derived` or `demo` |
| `id` | The transaction's id |

Over 2000 transactions (`csvIsolateThreshold`), the app writes the file on another
isolate (`transactionsCsvFile`, through `compute`); the bytes are the same either way.

The golden is `app/test/features/export/goldens/transactions.csv`, marked binary in git
(its `.gitattributes`), so its line ends survive a patch.

## The PDF

`buildMonthlyReportPdf(data, strings, {fonts, locale})` draws a `MonthlyReportData`:
- the period's `Report` (`reports.md`);
- the category names;
- the flags in the period, the dismissed ones left out;
- the active bills' occurrences due in the period;
- the budgets in their period of the same offset.

The texts are a `MonthlyReportStrings`, filled from the ARB by
`monthlyReportStrings(l10n)`. Amounts and dates are formatted in `locale` (intl's current
locale in the app).

**Layout.** A4 portrait, 40 pt margins, at most 200 pages (`reportMaxPages`; the
package's default of 20 would refuse a long bill list), Roboto Regular and Bold embedded from the app's
assets. From the top:
1. the title, the period ("Oct 1, 2026 – Oct 31, 2026"), "Amounts in USD", and "Counted
   through …" while the period runs;
2. the headline: spent, income, net and the share of income kept (or "No income in this
   period"), then spending and income against the period before and a year before;
3. **By category**: a bar per top-level group, the first ten, then one "Other" bar for
   the rest. Each bar is drawn with `pw.CustomPaint`, its length the group's ratio to the
   largest bar in minor units, a `double` used for placement only. Then the table: each
   group in bold with its share and amount, its children indented under it, and the
   group's own rows as "<group> itself";
4. **Top merchants**: the first ten, with the purchase count;
5. **Income and spending**: the last six periods, newest first;
6. **Top movers**: categories, then merchants, with before, now and the change;
7. **Worth a look**: the date, the merchant, the amount and why;
8. **Bills**: each occurrence with its due date, expected amount and state (paid, due,
   missed in red, upcoming). States are as the Bills calendar reads them
   (`occurrenceState` over `billPaymentsProvider`), so they share its limit: an
   occurrence older than the payments' lookback is paid only by a mark;
9. **Budgets**: each budget's period, spending, available and what is left (negative and
   red when over).

"Page x of y" is at the foot. A section with nothing to show says so ("Nothing in this
period.", "No bills due in this period."). A heading stays on its page with its table
when the table has at most 14 rows; a longer table keeps its heading with its first three
rows, and the rest follows across pages.

**Determinism.** The bytes depend only on the inputs:
- nothing comes from the clock or the device: every date is in the data, every amount is
  a `Money`, and the page size is fixed;
- `pw.Document(compress: false)` with no title, author or metadata, so there is no
  `/Info` and no creation date;
- after `save()`, `fixDocumentId` replaces the trailer's `/ID[<64 hex><64 hex>]` with
  zeros of the same length, so the cross-reference offsets stay right. The `pdf` package
  draws that id from the clock and a random source and has no setter. Anything other
  than exactly one id is a `StateError`.

`pdf` is pinned exactly (`build.md`). A new release, a new font file, a change to the
drawing or to its texts changes the bytes.

**The hash golden.** `test/helpers/monthly_report_fixture.dart` is a synthetic household:
- October 2026 seen on 5 November;
- twelve spending groups, so the bars end in "Other";
- a group with children and rows of its own;
- a merchant outside ASCII ("Café Olé");
- three flags built by hand, so a change to the anomaly rule does not move the hash;
- three bill occurrences and two budgets.

Drawn in English and `en_US`, it hashes to `monthlyReportFixtureSha256`.
`monthly_report_pdf_test.dart` checks the hash. On a match it caches the bytes under
`app/build/export/`. On a mismatch it fails, printing:
- the new hash;
- the path of the new PDF;
- the first byte that differs from the cached copy, with the text around it.

A deliberate change sets the constant to the new hash; never change it just to make the
test pass. `integration_test/export_test.dart` draws the same fixture on the device, with
the fonts from the APK, and expects the same hash: identical bytes render identically on
any screen, which is the acceptance's "the same on two emulator sizes".

## Providers

| Provider | What |
|---|---|
| `monthlyReportDataProvider(offset)` | The `MonthlyReportData` of the period `offset` periods after today's, the Reports segment's periods (`reportProvider`) |
| `reportFontsProvider` | Roboto Regular and Bold from the assets, loaded once |

The functions:
- `monthlyReportStrings(l10n)`, `monthlyReportPdf(data, l10n, fonts)`;
- `monthlyReportFileName(range)`: `report-2026-10.pdf`, or `report-2026-10-15.pdf` for a
  period that starts on another day;
- `transactionsFileName(range)`: `transactions-2026-01-01-to-2026-10-24.csv`;
- `transactionsCsvBytes(...)`.

## Screens

**Export** (`/settings/export`, `ExportRoute`) opens from Settings, under Data. From the
top:
- **Monthly report (PDF):** the period selector (`budget_period_selector.dart`, its own
  offset, nothing after the current period), Save as… and Share…, enabled once the
  period's data is ready;
- **Transactions (CSV):**
  - the dates, every transaction's by default: from the oldest live one's through the
    later of today and the newest live one's (a manual row may be dated ahead); a tap
    opens the date range picker;
  - the accounts as chips, all chosen by default;
  - the count of transactions the file will hold;
  - Save as… and Share…, disabled when the count is zero;
- the privacy note: "A file you save or share leaves the app's encrypted storage. Anyone
  who has the file can read it." In the demo, where the exporter is the fake, it adds "In
  the demo, nothing is saved or shared."

**The Reports menu.** The Reports segment's app bar has a menu after the alerts bell.
"Export this month as PDF" opens a sheet for the period shown, with Save as…, Share… and
the privacy note. A button runs the export: the sheet shows a progress bar with its
buttons off until the run is done, then closes.

**A run** (`runExport`):
- makes the file and hands it to the exporter;
- a save shows "Saved <file name>";
- a cancel or a share shows nothing, since the share sheet is its own answer;
- any failure, making the file (a font asset, the document id, the page cap) or handing
  it over (`ExportFailedException`), shows "The file could not be exported. Try again."
  and is logged by its type.

Each run's temporary file is in a directory of its own (`app-core.md`, **The file
exporter**), so two runs for one period never share a file.

While a run is going, the screen shows a progress bar and disables the buttons. Each
button is read as what it does ("Share the monthly report as a PDF").
