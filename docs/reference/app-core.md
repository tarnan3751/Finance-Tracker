# App core

How the Flutter app is put together around its features: startup, dependency injection,
routing and the shell, the theme, time, logging, localization, the settings feature, and the
test helpers every screen's tests use. The database and the repositories are `data.md`. Code: `app/lib/bootstrap.dart`, `app/lib/app.dart`,
`app/lib/core/`, `app/lib/features/settings/`, `app/lib/l10n/`, `app/test/helpers/`,
`app/test/flutter_test_config.dart`. The flavors and the Android build are in `build.md`.

## Startup

Each entry point (`main_dev.dart`, `main_demo.dart`, `main_prod.dart`) builds an
`AppConfig` and calls `bootstrap(config)`, which in order:

1. refuses a prod server URL that is not `https` (a `StateError` before anything runs);
2. `WidgetsFlutterBinding.ensureInitialized()`;
3. `setUpLogging(config.flavor)` and `forwardUncaughtErrors()` (**Logging**);
4. `setUpTimeZones()` (**Time**);
5. `Intl.defaultLocale` set to the device locale (`deviceLocale()`: the platform locale,
   canonicalized, or `en_US` when intl has no data for it), so `Money.format` and
   `Money.parse` without a locale follow the device; a locale change while the app runs is
   not followed yet;
6. a `ProviderContainer` with `overridesFor(config)`;
7. in dev and prod, `openLocalData(container)`: the database opens (`data.md`,
   **Encryption and the key**), `install_date` is recorded on the first launch, the system
   categories are seeded and the legacy importer runs once. Any failure to open is
   logged by type and `runApp(DatabaseErrorApp(failure: ...))` shows a plain error screen
   instead of the app, with a message for a missing cipher, a wrong key, a lost key, or
   anything else;
8. `runApp(UncontrolledProviderScope(container: container, child: FinanceTrackerApp()))`.

`FinanceTrackerApp` (`app.dart`) is a `ConsumerWidget` returning `MaterialApp.router` with
the router, both themes inside a `DynamicColorBuilder`, the theme mode from settings, the
localization delegates and supported locales, the title from `AppConfig.appName`, and, in
dev and demo, the flavor banner from its `builder`.

## Dependency injection

Riverpod 3 with code generation: providers are `@riverpod` / `@Riverpod(keepAlive: true)`
functions taking a `Ref`, or classes extending `_$Name`; generated `*.g.dart` files are
committed. `StateProvider` and the other `legacy.dart` providers are not used. Riverpod 3
pauses a provider that nobody listens to, and retries a failing build with backoff unless
the scope's `retry` says otherwise (the tests turn it off).

| Provider | Where | What |
|---|---|---|
| `appConfigProvider` | `core/di/providers.dart` | The flavor's `AppConfig`; throws unless overridden, and `overridesFor(config)` overrides it |
| `clockProvider` | `core/di/providers.dart` | `SystemClock` (**Time**) |
| `databaseKeyStoreProvider` | `core/di/providers.dart` | `SecureDatabaseKeyStore` (`data.md`) |
| `databaseProvider` | `core/di/providers.dart` | The encrypted `AppDatabase` of dev and prod, closed with the container; a `StateError` in demo |
| `inMemoryStoreProvider` | `core/di/providers.dart` | The `InMemoryStore` behind the in-memory and demo repositories; the demo flavor's holds the system categories and the demo seed |
| `accountRepositoryProvider`, `transactionRepositoryProvider`, `categoryRepositoryProvider`, `settingsRepositoryProvider` | `core/di/providers.dart` | In memory by default; Drift in dev and prod and demo in demo, through `overridesFor` |
| `legacyImportResultProvider` | `core/di/providers.dart` | The legacy importer's `ImportSummary` at this launch, or null; `AppShell` shows it once and clears it |
| `todayProvider` | `core/time/today_provider.dart` | The clock's local date, kept current past midnight (**Time**) |
| `goRouterProvider` | `core/router/app_router.dart` | The app's `GoRouter`, disposed with the container |
| `settingsControllerProvider` | `features/settings/application/settings_controller.dart` | The settings as `AsyncValue<Settings>`, with `setThemeMode` and `setUseDynamicColor` |
| `packageInfoProvider` | `features/settings/application/package_info.dart` | `PackageInfo.fromPlatform()` for About |

Each feature's own providers (the screens' streams, derived values and writes) are in its
`application/` folder and its reference file (`accounts.md`, `transactions.md`,
`categories.md`).

`overridesFor(AppConfig)` is the one place a flavor's wiring is decided: the Drift
repositories for dev and prod, the demo ones for demo; later phases add theirs (the fakes)
there.

riverpod_lint runs as an analyzer plugin declared in the workspace root's
`analysis_options.yaml` and enabled for the app by including that file from
`app/analysis_options.yaml`. `dart analyze` reports its diagnostics and `flutter analyze` does
not, so the gate runs both (`testing-tools.md`).

## Routing and the shell

Typed routes through `go_router_builder` (`core/router/routes.dart`, generated
`routes.g.dart`): a `TypedStatefulShellRoute<AppShellRoute>` with three branches, each
keeping its own navigation stack.

| Tab | Route class | Path | Screen |
|---|---|---|---|
| Accounts | `AccountsRoute` | `/accounts` | `features/accounts/presentation/accounts_screen.dart` |
| | `NewAccountRoute` | `/accounts/new` | `account_editor_screen.dart` |
| | `AccountDetailRoute` | `/accounts/:id` | `account_detail_screen.dart` |
| | `EditAccountRoute` | `/accounts/:id/edit` | `account_editor_screen.dart` |
| Transactions | `TransactionsRoute` | `/transactions` | `features/transactions/presentation/transactions_screen.dart` |
| | `NewTransactionRoute` | `/transactions/new?account=<id>` | `transaction_editor_screen.dart` |
| | `TransactionRoute` | `/transactions/:id` | `transaction_editor_screen.dart` |
| Settings | `SettingsRoute` | `/settings` | `features/settings/presentation/settings_screen.dart` |
| | `CategoriesRoute` | `/settings/categories` | `features/categories/presentation/categories_screen.dart` |
| | `NewCategoryRoute` | `/settings/categories/new` | `category_editor_screen.dart` |
| | `EditCategoryRoute` | `/settings/categories/:id` | `category_editor_screen.dart` |

- The router opens at `/accounts`, and `/` redirects there (`createRouter` in
  `app_router.dart`, which tests use to open at another location).
- Navigate with the route classes (`const SettingsRoute().go(context)`,
  `AccountDetailRoute(id).push(context)`), never with path strings. Detail and editor
  routes are sub-routes of their branch, so each tab keeps its own stack. `/accounts/new`
  is declared before `/accounts/:id` so it is not read as an id.
- Pushing a route of another branch (a transaction from an account's detail, category
  management from the category picker) puts it on top of the current tab's stack: the
  selected tab does not change, and back returns where the user was.
- `AppShell` (`core/router/app_shell.dart`) shows the selected branch above a Material 3
  `NavigationBar`; tapping the current tab again returns it to its first screen.
- **Snack bars.** Each branch has its own `ScaffoldMessenger`, so a snack bar shown from a
  tab (`ScaffoldMessenger.of(context)` in any of its screens) appears in that tab's screen
  `Scaffold`: above the navigation bar, lifting the screen's floating button rather than
  covering it, and still shown by the screen below when the one that showed it is popped
  (the transaction editor's Undo).
- **The legacy import.** On its first frame `AppShell` reads `legacyImportResultProvider`:
  when the legacy importer brought anything in at this launch, a snack bar in the current
  tab says how many entries went into "Imported" and their total (and how many could not
  be read), and the summary is cleared, so it is shown once.
- `EmptyState` (`core/widgets/empty_state.dart`) is the body of an empty list: an icon, a
  headline, a line of text and an optional action button.

## Theme

`AppTheme` (`core/theme/app_theme.dart`): Material 3 light and dark `ThemeData` from
`ColorScheme.fromSeed(seedColor: Color(0xFF6750A4))`, the baseline purple. When the device
supplies dynamic color schemes (Android 12 and later) and `Settings.useDynamicColor` is on,
those schemes are used instead. Both themes carry `FinanceColors`
(`core/theme/finance_colors.dart`), a `ThemeExtension` with `outflow` (red) and `inflow`
(green), each meeting text contrast on the light or dark surfaces; read it with
`FinanceColors.of(context)`. `AmountText` (`core/widgets/amount_text.dart`) draws a `Money`
through `Money.format()` in the device locale, colored by direction when asked, with a
semantics label that reads a negative amount as "minus" and its absolute value. The theme
mode is `Settings.themeMode`. Text scale is never clamped. Everything imports
`package:flutter/material.dart`; nothing uses `material_ui` (`PLAN.md` §12).

## Time

`Clock` (`core/time/clock.dart`) is where "now" and "today" come from (`PLAN.md` §6.8):
`nowUtc()` for audit instants, in UTC and truncated to milliseconds (audit fields are
millisecond precision, and their JSON converter refuses microseconds);
`today()` for the local date in `location`, the zone, as a `shared_models` `LocalDate`;
`todayLocalMidnight()` for the instant that day starts, for callers that need a
`DateTime`. `SystemClock` uses `tz.local`; `FixedClock(utc, location)` pins both in tests.
The importer and the demo seed use `today()`. The UI reads `todayProvider`
(`core/time/today_provider.dart`): `clock.today()`, re-read by a timer at the next local
midnight in the clock's zone (rescheduled each time it fires) and whenever the app
resumes, so a screen left open over midnight moves on. A new transaction's default date,
the date headers, the date filter presets and the "today" the date pickers mark come from
it.

`setUpTimeZones()` (`core/time/time_zone_setup.dart`) loads the full `latest` time zone
database (not `latest_10y`, `PLAN.md` §12) and sets `tz.local` from
`FlutterTimezone.getLocalTimezone()`'s identifier. A failing platform call, or an identifier
the database does not know, logs a warning and leaves `tz.local` at UTC, so startup goes
on; the settings About section shows the active zone, so the fallback is visible.

## Logging

`core/logging/app_log.dart`, on `package:logging`. Each area logs through its own
`Logger('<area>')`. dev and demo print every record with `debugPrint`; prod keeps the last
500 records in memory (`recentLogRecords()`), for the local crash log Phase 7 exports at the
user's request. `forwardUncaughtErrors()` sends `FlutterError.onError` and
`PlatformDispatcher.instance.onError` to the `app` logger. **Never log an amount, a
merchant, a description or a token** (`PLAN.md` §6.6).

## Localization

Every user-visible string is in `app/lib/l10n/app_en.arb` with a description;
`app/l10n.yaml` generates `AppLocalizations` (`nullable-getter: false`) into `app/lib/l10n/`,
committed. Read strings with `AppLocalizations.of(context)`. `flutter pub get`, `run`,
`test` and `build` regenerate it (`generate: true`); after editing the ARB run
`flutter gen-l10n` and commit the output, which the gate's codegen step checks. English is
the only locale.

## Settings

| Layer | File | What |
|---|---|---|
| domain | `domain/settings.dart` | `Settings`: `themeMode` (`AppThemeMode.system`, `light`, `dark`) and `useDynamicColor`; `Settings.defaults()` is system and on |
| domain | `domain/settings_repository.dart` | `SettingsRepository`: `watch()` (current value first, then each save), `read()`, `save()` |
| data | `data/drift_settings_repository.dart` | The Drift implementation (dev and prod): one `app_settings` row per field |
| data | `data/in_memory_settings_repository.dart`, `data/demo_settings_repository.dart` | The in-memory implementation (tests) and the demo one (the demo flavor) |
| application | `application/settings_controller.dart` | `SettingsController`, following `watch()`; each change reads, changes and saves, and changes run one after another so two issued together both land |
| presentation | `presentation/settings_screen.dart` | Appearance (a `SegmentedButton` for the theme mode, a `SwitchListTile` for dynamic color), Data (Categories, opening category management, `categories.md`) and About (app name, version and build, flavor, time zone) |

The repository contract is `test/contract/settings_repository_contract.dart`,
`runSettingsRepositoryContract(create, {dispose})`; the three implementations each run it
(`data.md`, **Three implementations, one contract**).

## Tests

- **`test/helpers/pump_app.dart`.** `pumpApp(tester, {overrides, config, initialLocation,
  brightness, textScale, size, clock})` pumps the real app at phone size (412 by 915) and settles.
  `buildTestApp` is the same app as a widget, for goldens; `testOverrides` is its override
  list: the flavor (prod by default) as `appConfigProvider` only, not the flavor's
  `overridesFor` wiring, so every test runs on the in-memory repositories; the `clock`
  passed, else `testClock` (24 October 2026, 15:00 UTC, in UTC); `testPackageInfo` (1.0.0, build 1); settings whose
  theme mode gives `brightness`; and a router at `initialLocation`; then the test's own
  overrides, which win. Riverpod's retry is off so a failing provider fails at once.
- **Goldens** use `alchemist`. `test/flutter_test_config.dart` runs every test with CI
  goldens on (Ahem, text drawn as blocks, identical on every OS; written to `goldens/ci/`
  next to the test, committed, compared by the gate and CI). Platform goldens (real fonts,
  `goldens/<os>/`, gitignored) are a local aid: written only by `--update-goldens` when the
  `CI` environment variable is unset, and never compared, since a fresh clone has none.
  Golden tests are tagged `golden` (`app/dart_test.yaml`). Update them with
  `flutter test --update-goldens --tags golden` and look at the platform images before
  committing the CI ones. The shell's goldens (`test/core/router/app_shell_golden_test.dart`)
  hide Flutter's DEBUG banner, which is not part of the app.
- **Test data.** `test/helpers/seed.dart`: `seededStore()` is an `InMemoryStore` on the test
  clock (or the `clock` passed) with the system categories and the demo seed dated to that
  clock's today (or a seed the test passes), and `storeOverride(store)` puts the in-memory repositories on it;
  the test keeps the store to read back what a screen wrote. `testTransaction(...)` builds a
  manual transaction relative to the test clock. Widget tests whose rows must all be laid
  out pump a taller `size`: the test font draws every character as a square, so rows are
  taller than on a device.
- **Accessibility.** `test/accessibility_test.dart` checks every screen, light and dark,
  against `androidTapTargetGuideline`, `labeledTapTargetGuideline` and
  `textContrastGuideline`, and lays each out at text scale 2.0 expecting no exception: the
  shell's tabs empty, and every screen, the filter sheet and the category picker on the demo
  seed. A new screen joins the list. Focus order follows reading order; nothing custom.
