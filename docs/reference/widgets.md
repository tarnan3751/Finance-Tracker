# Widgets

The three home screen widgets, Balances, Budgets and Upcoming bills: a snapshot of what
the app's screens show, written by the app and rendered by Android, which opens the app at
the right screen when a widget is tapped. The decisions are `PLAN.md` §12 "Phase 8
go-ahead", "Phase 8 package pins and platform rulings" (`home_widget` 0.10.0 on the
RemoteViews path, `updatePeriodMillis` 0, on-demand redraws only), "Widgets and
shortcuts" and "8b as delivered". The app shortcuts and
the launch links both use are `app-core.md`, **Launch links**.

Code:
- `app/lib/features/widgets/domain/` (pure Dart):
  - `widget_data.dart`: `WidgetData` (the snapshot), `WidgetNetWorth`, `WidgetAccount`,
    `WidgetBudget`, `WidgetBill`, `widgetSnapshotKey`, `widgetSnapshotVersion`,
    `widgetRowLimit` (three);
  - `widget_writer.dart`: `WidgetWriter`, the platform boundary.
- `data/`: `home_widget_writer.dart` (`HomeWidgetWriter`, every flavor on a device;
  `widgetProviders`, the three providers' class names) and `fake_widget_writer.dart`
  (`FakeWidgetWriter`, the tests').
- `application/`: `widget_data_builder.dart` (`buildWidgetData`, `widgetUpdatedText`) and
  `widget_providers.dart` (**Providers**).
- Android: `app/android/app/src/main/kotlin/dev/tarnan/financetracker/widgets/`
  (`FinanceWidgetProvider.kt`, `BalancesWidgetProvider.kt`, `BudgetsWidgetProvider.kt`,
  `BillsWidgetProvider.kt`), `res/layout/widget_*.xml`, `res/xml/widget_*_info.xml`,
  `res/values*/widget_colors.xml`, `widget_dimens.xml`, `widget_strings.xml`,
  `res/drawable/widget_background.xml`, and the receivers in the manifest (`build.md`,
  **Android**).

Tests: `app/test/features/widgets/application/widget_data_builder_test.dart` (the snapshot
from fixed inputs, its ordering, the locale and the zone, its JSON), `widget_providers_test.dart`
(the runner), and `app/integration_test/widgets_test.dart` (the snapshot through the real
plugin on the harness's emulator after a transaction and a pull, and the shortcuts' links).

## The snapshot

`WidgetData` holds what the three widgets show, built by `buildWidgetData` from the values
the screens show, never from the database directly:

- **Net worth**: the latest point of the observed net worth series (`net-worth.md`, **The
  series**) of the currency the Net worth segment shows first (the device's when held,
  else the first in code order). The full history's last point is always that observed
  one, since the reconstruction only reaches back before the first snapshot, so it is
  read from the snapshots alone; `estimated` follows the point's `derived` flag ("From
  account balances" or "Estimated from transactions"). None until a snapshot is stored.
- **Accounts**: the visible live accounts, those in the device's currency first, with
  the largest balances as shown (`shownBalance`, `accounts.md`: reported by the bank,
  else from transactions) by absolute minor units, the display order breaking ties; then
  those in other currencies by name, since minor units of two currencies do not compare;
  each with "reported" or "from transactions", as the Accounts tab labels them.
- **Budgets**: every live budget's current period (`budgetStatusesProvider`), over-limit
  ones first (over, or something spent with nothing available), then by how full the
  bar is; the bar's fill, the percent, "left" or "over" and the spoken sentence are the
  budget card's (`budgets.md`, **Screens**).
- **Bills**: the active bills' occurrences a bill row shows (`billFocus`, `bills.md`),
  paid ones left out, missed ones first ("Missed, Due 5 days ago"), then by due date;
  the due date as the Bills segment says it within a week, else its month and day; the
  expected amount as a positive amount.
- At most three of each. Every amount is a `Money` beside the text `Money.format()` gave
  it in the device's locale (intl's default locale, set at startup), since RemoteViews
  cannot format money; every row carries the sentence a screen reader says for it; the
  strings come from the ARB in the device's language (`widgetLocalizationsProvider`).
- `updatedAt` (UTC) and "Updated 2:41 PM" in the clock's zone, stamped when written.
- While nobody is signed in (dev and prod), `WidgetData.signedOut`: nothing but the time.
  While the stored session has not been read yet (a fresh container, the background
  cycle's), the snapshot waits for the read: it is never written as signed out on a
  guess.
- **Locked.** While the app lock is enabled (`app_meta` `lock_enabled`, read by
  `widgetDataProvider` itself, so a background container whose lock controller has not
  restored never writes an unlocked snapshot), the snapshot is `locked` and every row's
  spoken sentence says its amount is hidden ("Checking, balance hidden while the app is
  locked"). The runner rewrites the snapshot when the setting changes. A locked snapshot
  holds no amount: each text is the mask `••••`, `minor` and `currency` are left out, a
  budget's percent and detail are left out and its fill is zero, so the preference file
  holds no balances. The widgets show the mask, empty bars and no error colour (a missed
  bill in the neutral colour), masking again as a fallback, and keep the names, the due
  dates, the bases and the footer; a tap still opens the app, behind the
  lock. The order says nothing of the amounts either: accounts and budgets by name, bills
  by due date alone (over-limit and missed first only when unlocked).

The snapshot is one JSON value (`toJson`, format version 1) under the key `snapshot` in
`home_widget`'s preferences file (`HomeWidgetPreferences`, app-private, excluded from
backups like everything else): one write, so the three widgets never show two different
moments. Amounts are written as `minor` and `currency` beside their text; the Kotlin side
reads only the texts, the flags (`signed_in`, `locked`, `estimated`, `reported`, `over`,
`overdue`), the bar's `fill_bp` (0 to 10000) and the ids. The snapshot holds account
names and amounts outside the encrypted database, in a preference file that is
app-private but not encrypted; with the lock on it holds names and dates only, and the
masking is what keeps the home screen quiet.

## The writer

`WidgetWriter.write(data)` replaces the snapshot and redraws every placed widget.
`HomeWidgetWriter` (every flavor: the demo's widgets show its seed, dev's and prod's the
database) calls `HomeWidget.saveWidgetData` and then `HomeWidget.updateWidget` with each
provider's full class name (the namespace stays `dev.tarnan.financetracker` while the demo's
application id has a suffix). `FakeWidgetWriter` records every write and can be made to
fail.

## Providers

| Provider (`application/widget_providers.dart`) | What |
|---|---|
| `widgetWriterProvider` | The writer: the fake by default, `HomeWidgetWriter` in every flavor (`overridesFor`) |
| `widgetLocalizationsProvider` | The ARB's strings in the device's locale |
| `widgetDataProvider` | The snapshot of what the screens show now, or the signed-out one; recomputed when any of it changes |
| `widgetDebounceProvider` | How long the runner waits after a change: two seconds |
| `widgetRefreshRunnerProvider` | `WidgetRefreshRunner`: its state is when it last wrote |
| `writeWidgetsNow(container)` | One write now, on a container nothing else listens to it in (the background cycle's hook) |

`WidgetRefreshRunner` writes the snapshot, stamped at the write, the debounce after the
last change to anything it reads (the repositories' streams behind it, the session,
today), and after every whole Plaid pull and every sync session even when nothing changed,
so the footer moves; one write at a time, a failure logged by type and never stopping the
next. It is not kept alive (it follows the screens' providers, which are not), so nothing
runs unless something listens: `bootstrap` does after the first frame, in every flavor.
`refresh()` writes at once and completes when written. `writeWidgetsNow(container)` is
the background cycle's hook (`(container) => writeWidgetsNow(container)`): it waits for
the stored session to be read, listens to the runner, refreshes, and releases it; it
reads the repositories' current values and writes one preference. A background isolate
prepares first what `bootstrap` prepares: the time zones (`setUpTimeZones`),
`Intl.defaultLocale` (`deviceLocale()`), the date symbols (`initializeDateFormatting()`)
and a container over the flavor's `overridesFor` with its local data open.

The local wipe clears the snapshot (`WidgetWriter.clear`: the key removed, every widget
redrawn) right after the receipts (`data.md`, **The local wipe**).

## The widgets

Each is an `AppWidgetProvider` extending `home_widget`'s `HomeWidgetProvider`
(`FinanceWidgetProvider`, which reads the snapshot and picks the layout), with RemoteViews
layouts only (no Glance or Compose in the app module). A redraw reads one preference and
parses it: no database, no network, well inside a receiver's ten seconds.

| Widget | Size | Shows | Tap |
|---|---|---|---|
| Balances | 2 by 2, resizable to 4 by 2 and wider | Net worth with its basis; from 250 dp across (4 cells), the three accounts with their balances and bases | Accounts; the net worth, the Net worth segment |
| Budgets | 4 by 2, resizable | The budgets, each with its name, "left" or "over", the percent and the bar, the error colour when over | The Budgets segment; a row, that budget's detail |
| Upcoming bills | 2 by 2, resizable to 4 by 2 and wider | The three bills with their due dates, missed ones in the error colour; from 4 cells, their amounts | The Bills segment; a row, that bill |

- **Sizes.** On Android 12 and later the launcher picks between the two layouts as the
  widget is resized (`RemoteViews(Map<SizeF, RemoteViews>)`); before, the width the
  launcher reports does, again on `onAppWidgetOptionsChanged`. The rows shown are those
  that fit the widget's portrait height (`OPTION_APPWIDGET_MAX_HEIGHT`) at the system's
  font scale, one to three: each widget declares its fixed height and a row's in sp and
  dp (measured on the harness's Pixel Launcher at scale 1: a title 19 dp, the footer 15
  dp, a two-line row 37 dp, a budget row 30 dp), so a large font drops the last row
  rather than clip the footer. The estimate scales text linearly, which overestimates
  Android 14's non-linear scaling. A font scale change takes effect at the next write.
- **States.** No snapshot yet (the widget may be placed before the app first runs), a
  snapshot of another version, signed out, or nothing to show (no accounts, budgets or
  bills): the widget's title and "Open Finance Tracker to set up" (`widget_setup.xml`),
  whose tap opens the app there. A widget with fewer than three rows hides the rest.
- **Colours.** `widget_colors.xml`: the app's Material 3 baseline, light and dark by the
  system's night mode; on Android 12 and later the launcher's dynamic palette
  (`@android:color/system_neutral1_*`, `system_neutral2_*`, `system_accent1_*`), the error
  colour staying the baseline's. A colour that changes with a value is two views styled
  alike and shown one at a time, so the night mode and the palette resolve in the
  launcher. The corner radius is the launcher's on Android 12 and later.
- **Text.** Sizes in `sp`, so the system's font scale applies; one line each, ellipsized.
  The fixed texts (the picker's names and descriptions, the titles, the set-up message)
  are Android string resources (`res/values/widget_strings.xml`, with the Spanish in
  `res/values-es/`), the only user-visible strings outside the ARB, because the launcher
  reads them without the app; everything else comes from the snapshot. Each row's content description is the snapshot's spoken
  sentence.
- **Taps** open `MainActivity` with `home_widget`'s launch action and the row's link
  (`launchLink`, each segment encoded), which reaches the router through the
  `LaunchIntent` seam (`app-core.md`, **Launch links**); under the lock the destination
  waits behind the gate.
- `updatePeriodMillis` is 0: nothing but the app's writer and the background cycle redraws
  a widget; there is no preview image (the picker shows the app's icon with the name and
  description).
