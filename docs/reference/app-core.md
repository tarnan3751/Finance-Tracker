# App core

How the Flutter app is put together around its features: startup, dependency injection,
the API client and the in-app fake server, routing and the shell, the theme, time,
logging, localization, the settings feature, and the test helpers every screen's tests
use. Signing in and the session are `auth.md`. The database and the repositories are `data.md`. Code: `app/lib/bootstrap.dart`, `app/lib/app.dart`,
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
   `Money.parse` without a locale follow the device, and the date symbols of every locale
   loaded (`initializeDateFormatting`); a locale change while the app runs is not followed
   yet, except the language chosen in Settings (**Localization**);
6. in dev and prod, the process's `ft.app` port is registered once, through which the
   background sync's worker asks the running app to sync instead of running its own
   session (`background.md`, **One session at a time**);
7. `startApp(config)`, the rest, which can run again in the same process: in dev and
   prod it first waits, at most 45 s, for a cycle the worker runs on its own to end, then
   builds a `ProviderContainer` with `overridesFor(config)` (or the overrides a test
   gives);
8. in dev and prod, `openLocalData(container)`: the database opens (`data.md`,
   **Encryption and the key**), the held records of every type this build knows are
   released (`sync-app.md`, **Unknown types**; a failure is logged by type and leaves
   them held), `install_date` is recorded on the first launch, the system categories are
   seeded and the legacy importer runs once. Any failure to open is logged by type and
   `runApp(DatabaseErrorApp(failure: ...))` shows a plain error screen instead of the
   app, with a message for a missing cipher, a wrong key, a lost key, or anything else;
   for a lost key it also offers "Restore from a backup" (`backup.md`);
9. the stored session is read (`sessionControllerProvider`'s `restored()`, `auth.md`),
   so the first frame is already signed in or out (a session the background sync found
   ended becomes the sign-in screen's notice, `auth.md`); the lock's settings are read
   (`lockControllerProvider`'s `restored()`, `lock.md`), so with the lock on the first
   frame is the lock screen and the window is secure before anything is drawn; the
   launch link the app was started at, if any, is read (**Launch links**), so the router
   opens at its location; then the sync controller starts
   (`sync-app.md`, **The controller**), the background sync's watcher keeps the periodic
   sync scheduled while someone is signed in (`background.md`, **Scheduling**) and, in
   every flavor, the budget alert watcher is listened to (`budgets.md`, **Alerts**);
10. `runApp(UncontrolledProviderScope(container: container, child: FinanceTrackerApp()))`;
11. after the first frame, in every flavor, the reminder watcher is listened to (the bill
    reminders are planned then and whenever their inputs change, `bills.md`,
    **Reminders**) and `reminderSchedulerProvider.openedBillIds` pushes `/bills/:id` for
    a tapped reminder; the home screen widgets' runner is listened to (`widgets.md`), the
    launch links that reach the running app go to their locations and the app shortcuts
    are set (**Launch links**); the notification channels are created, named in the
    device's locale, and in dev and prod `LocalNotifications.routes` pushes a tapped
    system notification's route (`background.md`, **Notifications**);
12. in dev and prod, after the first frame, `sweepReceipts(container)`: the receipt files
    no live transaction references are deleted (`data.md`, **Receipts**), a failure
    logged by type only.

**Starting again.** `startApp` gives its container `appRestartProvider`, the restart a
restore runs under (`backup.md`, **Restore**): `runApp` of the plain restoring screen,
two frames (`runApp` attaches the new tree on a timer, so only after the second is the
old one unmounted and its streams cancelled), then `stopApp()` (the reminder and notification taps and the launch links cancelled, the container disposed, and the close its
`databaseProvider` started awaited through `databaseClosing`, so the files are free),
then the restore's work with its progress on that screen (a failure shown with a
Continue button), then `startApp` again with the same configuration and overrides, so
the app opens the new database exactly as at launch. It gives it `wipeLocalDataProvider`
too, the local wipe (`data.md`, **The local wipe**) that account deletion and erasing the
device run (`auth.md`): `runApp` of the plain erasing screen (`ErasingApp`), the same
two frames and `stopApp()`, then the running container's `LocalWipe` until it succeeds (a failure shown
with Try again, never the app on half-wiped data), then the confirmation for the reason
and, on Done, `startApp` again, which finds no database and no key and creates both.
Before it opens anything local, `startApp` reads the wipe's pending record and, when a
wipe was cut short, finishes it the same way first (`data.md`, **The local wipe**).

`FinanceTrackerApp` (`app.dart`) is a `ConsumerWidget` returning `MaterialApp.router` with
the router, both themes inside a `DynamicColorBuilder`, the theme mode from settings, the
localization delegates, the supported locales and the language chosen on this device
(**Localization**), the title from `AppConfig.appName`, and a
`builder` that puts the lock's gate (`LockGate`, `lock.md`, **The gate**) above
everything, around the flavor banner in dev and demo and the router, so the lock screen
covers every route and dialog.

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
| `accountRepositoryProvider`, `transactionRepositoryProvider`, `categoryRepositoryProvider`, `itemRepositoryProvider`, `ruleRepositoryProvider`, `budgetRepositoryProvider`, `settingsRepositoryProvider` | `core/di/providers.dart` | In memory by default; Drift in dev and prod and demo in demo, through `overridesFor` |
| `recurringStreamRepositoryProvider`, `liabilityRepositoryProvider` | `core/di/providers.dart` | The recurring streams with their overrides and the liabilities (`recurring.md`, `liabilities.md`): in memory by default, Drift in dev and prod, demo in demo (the persona's, rebuilt with it) |
| `goalRepositoryProvider` | `core/di/providers.dart` | The goals and their contributions (`goals.md`): in memory by default, Drift in dev and prod, demo in demo (the persona's two goals, rebuilt with it) |
| `goalEntriesProvider`, `goalViewsProvider`, `goalViewByIdProvider`, `goalActionsProvider` | `features/goals/application/goals_providers.dart` | The goals with their contributions; each as the screens show it today (progress, suggestion, status); one of them; the writes (`goals.md`) |
| `recurringStreamsProvider`, `subscriptionsProvider`, `streamActionsProvider`; `liabilitiesProvider` | `features/recurring/application/`; `features/liabilities/application/` | The streams with their overrides, the subscriptions with their annual cost, the actions on a stream; the liabilities |
| `holdingRepositoryProvider`, `investmentTransactionRepositoryProvider` | `core/di/providers.dart` | The holdings with their securities and the investment transactions (`investments.md`): in memory by default, Drift in dev and prod, demo in demo (the persona's brokerage, rebuilt with it) |
| `holdingsProvider`, `investmentTransactionsProvider(accountId)`, `investmentAccountsProvider`, `investmentValueHistoryProvider(accountId)` | `features/investments/application/investments_providers.dart` | Every holding with its security; one account's live investment transactions, newest first; the investment accounts the Investments segment shows; one account's balance snapshots, its value over time (`investments.md`) |
| `balanceSnapshotRepositoryProvider`, `snapshotWriterRunnerProvider` | `core/di/providers.dart`; `features/net_worth/application/snapshot_writer.dart` | The daily balance snapshots (`net-worth.md`): in memory by default, `balance_snapshots` in dev and prod, empty at launch in demo (rebuilt with the in-memory store); and the writer that keeps today's written while listened to (`bootstrap` does, after the first frame, in every flavor) |
| `forecastSelectionControllerProvider`, `forecastPlanProvider`, `forecastProvider` | `features/forecast/application/forecast_providers.dart` | The forecast's account selection (kept in `app_meta`), the plan of the series shown, and the series for 30 or 90 days (`forecast.md`) |
| `budgetAlertStoreProvider` | `core/di/providers.dart` | Which budget alerts this device raised (`budgets.md`): in memory by default and in demo, `budget_alerts` in dev and prod |
| `billRepositoryProvider`, `billAlertStoreProvider` | `core/di/providers.dart` | The bills (in memory by default, Drift in dev and prod, the persona's two in demo) and which bill notifications this device raised (in memory, `bill_alerts` in dev and prod; `bills.md`) |
| `appMetaStoreProvider` | `core/di/providers.dart` | Facts about the install (`app_meta`): in memory by default and in demo, the database's in dev and prod; the reminders' zone and time, the dismissed bill suggestions, the forecast's account selection and the last day the balance snapshots were written among them |
| `reminderSchedulerProvider` | `core/platform/reminder_scheduler_provider.dart` | The bill reminders' scheduler (**Reminders**): the fake by default and in demo, `flutter_local_notifications` in dev and prod |
| `dismissedPairStoreProvider` | `core/di/providers.dart` | The duplicate pairs the user dismissed, on the device only: in memory by default and in demo (rebuilt with the in-memory store), `dismissed_pairs` in dev and prod (`duplicates.md`) |
| `appNotifierProvider`, `inAppNotificationsProvider` | `core/platform/in_app_notifications.dart` | Where the app's notifications go (**Notifications**): the in-app list by default and in demo, the list and the tray in dev and prod |
| `localNotificationsProvider` | `core/platform/local_notifications_provider.dart` | The one `flutter_local_notifications` instance and its taps, read only by the dev and prod implementations |
| `notificationChannelsProvider`, `systemSettingsProvider`, `channelTextsProvider`, `systemNoticeTextProvider`, `notificationPermissionProvider` | `core/platform/notification_providers.dart` | The channels and Android's settings screens (the fakes by default and in demo, the platform's in dev and prod), the channels' names and each kind's tray text in the device's locale, and the one-time permission request (`background.md`, **Notifications**) |
| `backgroundWorkProvider`, `connectivityProvider` | `core/platform/background_work_provider.dart`, `connectivity_provider.dart` | The background sync's scheduling and whether a network is up: the fakes by default and in demo, `workmanager` and `connectivity_plus` in dev and prod (`background.md`) |
| `backgroundSyncWatcherProvider`, `backgroundCycleHooksProvider` | `core/background/` | The periodic sync kept scheduled while signed in (with the device's switch) and the steps a background cycle runs after its sync (`background.md`) |
| `plaidPullStoreProvider`, `arrivalProcessorProvider`, `plaidPullProvider` | `core/di/providers.dart` | The Plaid pull (`sync-app.md`, **The Plaid pull**): its cursors in memory by default and in `sync_meta` in dev and prod, the rules run on what it inserts (`RuleRunner`, `rules.md`), and the pull over the API into the repositories |
| `inMemorySyncStoreProvider`, `driftSyncStoreProvider`, `deviceClockProvider`, `changeRecorderProvider`, `recordingSyncStoreProvider` | `core/di/providers.dart` | The sync stores, the device clock, the recorder the repositories record through, and the store it records into (which the rules' owned-field guard reads, and in whose transaction a rule is applied to the existing transactions): in memory by default, Drift in dev and prod, none in demo (`sync-app.md`) |
| `syncDeviceIdProvider`, `syncRelayProvider`, `localDataSyncsProvider`, `syncDebounceProvider`, `syncBackoffProvider` | `core/di/providers.dart` | The session's device id and the API's relay as that device while signed in (null otherwise), whether the local data syncs (dev and prod), the debounce after a local change, and the controller's backoff after a failed session |
| `syncControllerProvider` | `core/sync/sync_controller.dart` | The sync status and Sync now (`sync-app.md`) |
| `demoPersonaProvider`, `demoSeedProvider` | `core/di/providers.dart` | The persona the demo flavor shows and its demo seed (`data.md`, **The demo seed**) |
| `legacyImportResultProvider` | `core/di/providers.dart` | The legacy importer's `ImportSummary` at this launch, or null; `AppShell` shows it once and clears it |
| `todayProvider` | `core/time/today_provider.dart` | The clock's local date, kept current past midnight (**Time**) |
| `goRouterProvider`, `launchLocationProvider` | `core/router/app_router.dart` | The app's `GoRouter` (`routerFor`), gated on the session in dev and prod, opening at the start link's location when there is one, disposed with the container; that location (**Launch links**) |
| `launchIntentProvider`, `appShortcutsProvider` | `core/platform/launch_intent_provider.dart`, `app_shortcuts_provider.dart` | The links the app is opened at and the launcher's shortcuts (**Launch links**): the fakes by default, `home_widget` and `quick_actions` in every flavor |
| `widgetWriterProvider`, `widgetDataProvider`, `widgetRefreshRunnerProvider` | `features/widgets/application/widget_providers.dart` | The home screen widgets' writer (the fake by default, `home_widget` in every flavor), their snapshot and the runner that keeps them current (`widgets.md`) |
| `tokenStoreProvider`, `fakeServerProvider`, `financeApiProvider`, `appVersionProvider`, `httpConnectionsProvider` | `core/api/api_providers.dart` | The API (**The API client**) and its network connections, which Sync now and a returning network drop |
| `sessionControllerProvider`, `deviceNameProvider`, `installUserProvider` | `features/auth/application/` | The session, the device's name and the install's user (`auth.md`) |
| `receiptStoreProvider` | `core/di/providers.dart` | Where receipt photos are kept: in memory by default and in demo, files in the support directory in dev and prod (`data.md`, **Receipts**) |
| `localWipeProvider`, `wipeLocalDataProvider` | `core/di/providers.dart` | The local wipe (`data.md`, **The local wipe**): the stores only by default, the database files too in dev and prod; and the stop, wipe, confirm and start again that `startApp` supplies (unavailable elsewhere unless overridden) |
| `imageSourceProvider` | `core/platform/image_source_provider.dart` | The camera and gallery for receipt photos: `image_picker` by default, the fake in demo (**The image source**) |
| `fileExporterProvider` | `core/platform/file_exporter_provider.dart` | Where exported files go (**The file exporter**): the fake by default and in demo, the "Save as" dialog and the share sheet in dev and prod |
| `screenSecurityProvider`, `monotonicClockProvider` | `core/platform/screen_security_provider.dart`, `monotonic_clock_provider.dart` | The window's secure flag and the clock the lock measures the time away with (**Screen security**, **The monotonic clock**): the fakes by default, `MainActivity`'s channels in every flavor |
| `lockControllerProvider`, `lockHoldProvider`, `deviceAuthProvider`, `deviceAuthSupportedProvider` | `features/lock/application/` | The app lock, its settings and the secure flag; the count of external activities that keeps it open; the device's check (the fake by default, `local_auth` in every flavor); whether the device can check (`lock.md`) |
| `linkLauncherProvider`, `linkControllerProvider`, `linkPollIntervalProvider`, `linkedBanksProvider` | `features/items/application/` | Plaid Link (plaid_flutter by default, the fake launcher wherever the fake server runs), the Item actions and their state, and the stored Items (`items.md`) |
| `settingsControllerProvider` | `features/settings/application/settings_controller.dart` | The settings as `AsyncValue<Settings>`, with `setThemeMode` and `setUseDynamicColor` |
| `packageInfoProvider` | `features/settings/application/package_info.dart` | `PackageInfo.fromPlatform()` for About |

Each feature's own providers (the screens' streams, derived values and writes) are in its
`application/` folder and its reference file (`accounts.md`, `transactions.md`,
`categories.md`, `rules.md`, `duplicates.md`, `developer.md`, `budgets.md`: the budget
statuses and the alert watcher, which `bootstrap` listens to in every flavor; `bills.md`:
the bill statuses and the reminder watcher, which it listens to from the first frame).

`overridesFor(AppConfig)` is the one place a flavor's wiring is decided (it is
`localDataOverridesFor(config)`, the flavor and its local data, then `apiOverridesFor`;
a test that brings its own API, such as the two-device integration test sharing one fake
server, takes the first alone): the Drift repositories and the Plaid pull's `sync_meta`
store for dev and prod with the receipt files and the notification plugin's reminder
scheduler, the demo ones for demo with the fake image source (and the fake scheduler),
the API's (`apiOverridesFor`: the in-app fake server, with the fake
Link launcher over it, for demo, and for dev under `FT_FAKE_SERVER`), the system's
file dialogs (`filePickerOverridesFor`: the platform file exporter and backup picker in
dev and prod, the fakes otherwise, so a test on the dev wiring through
`localDataOverridesFor` keeps the fakes), and in every flavor the platform seams that
behave the same in all three (the secure flag and the monotonic clock through
`MainActivity`'s channels, the device's check through `local_auth`, the home screen
widgets' writer and the launch links through `home_widget`, the shortcuts through
`quick_actions`); later phases add theirs there.

## The image source

`core/platform/image_source.dart` is the platform boundary for receipt photos, pure
Dart: an `ImageSource` has `pickFromCamera()` and `pickFromGallery()`, each completing
with a `PickedImage` (its bytes) or null when the user took or chose nothing, or throwing
`NoCameraException` (no camera app) or `ImagePickFailedException` (the picker failed,
or the image is malformed or in a format whose metadata cannot be stripped), which the
editor explains in a snack bar ("That image can't be used").

- **`ImagePickerSource`** (`image_picker_source.dart`, dev and prod): `image_picker`'s
  `pickImage` with `maxWidth: 1600` and `imageQuality: 85` (the plugin re-encodes as
  JPEG, or PNG for an image with transparency, copying the original's EXIF into either;
  an original it cannot decode it returns untouched). It reads the picked file from the
  cache and deletes it, maps the plugin's `no_available_camera` code to
  `NoCameraException` and any other to `ImagePickFailedException` (logging the code
  alone), and strips the bytes' metadata: a JPEG's or a PNG's, as below. Anything else (a
  WebP, a HEIC, a file that is neither) is refused with `ImagePickFailedException`.
- **Metadata** (`jpeg_metadata.dart`, `stripJpegMetadata`): a walker over the JPEG
  segments up to the start of scan drops every APP1 to APP15 segment (EXIF with its GPS
  position, device and timestamps, XMP, ICC profiles) and writes the EXIF orientation
  alone back, when it is not the default, as a minimal big-endian APP1 after the SOI and
  any JFIF APP0, so a portrait still displays upright. The image data is copied
  untouched; a JPEG cut short is a `FormatException`. `png_metadata.dart`
  (`stripPngMetadata`) walks a PNG's chunks, checking each one's length and CRC, and
  keeps the critical chunks and the display ones (gAMA, cHRM, sRGB, iCCP, pHYs, tRNS)
  up to IEND, dropping every other ancillary chunk (eXIf, tEXt, iTXt, zTXt, tIME); a
  PNG has no orientation to keep, the plugin having applied it when re-encoding. A
  malformed PNG is a `FormatException`, and the source refuses the image.
- **`FakeImageSource`** (`fake_image_source.dart`, the demo flavor and the tests): every
  pick completes with what its `next` gives and is counted. The demo's,
  `FakeImageSource.demo()`, gives `assets/demo/receipt.jpg`, a synthetic "DEMO RECEIPT"
  photo declared as an asset of the demo flavor only (`build.md`). Tests give a fixture
  from `test/fixtures/receipts/`.

## The file exporter

`core/platform/file_exporter.dart` is the platform boundary for the files the app makes
(`export.md`), pure Dart: a `FileExporter` has `saveAs(bytes, fileName, mimeType)`,
completing with `SaveOutcome.saved` or `SaveOutcome.cancelled`, and `share(bytes,
fileName, mimeType)`; both throw `ExportFailedException` when the file cannot be written
or the platform fails.

- **`PlatformFileExporter`** (`platform_file_exporter.dart`, dev and prod): writes the
  bytes to `<fileName>` in a directory of the call's own under `<temporary
  directory>/export/` (so two calls for one name never share a file), hands that path to
  `flutter_file_dialog`'s `saveFile` (the Storage Access Framework's "Save as"; a null
  answer is a cancel) or to `share_plus`'s share sheet (which copies the file into its own
  `cache/share_plus/` first), and deletes the temporary directory when the call returns,
  whatever the outcome. A platform error is logged by its code alone.
- **`FakeFileExporter`** (`fake_file_exporter.dart`, the demo flavor and the tests):
  nothing leaves the app; every call is recorded as an `ExportCall` (kind, bytes, name,
  type), "Save as" answers its `outcome` (saved by default), and a set `failure` is
  thrown after the call is recorded.

## Screen security

`core/platform/screen_security.dart` is the platform boundary for the window's secure
flag, pure Dart: `ScreenSecurity.set(bool secure)`. While it is set Android blanks the app
in screenshots, screen recordings and the task switcher's thumbnail (`FLAG_SECURE`; an
OEM may differ, and a thumbnail taken before the flag was set stays). The lock controller
sets it whenever the lock is enabled or "Block screenshots" is on (`lock.md`).

- **`ChannelScreenSecurity`** (`channel_screen_security.dart`, every flavor): the
  `dev.tarnan.financetracker/screen_security` channel's `setSecure(bool)`, which
  `MainActivity` answers by adding or clearing `WindowManager.LayoutParams.FLAG_SECURE`
  on its window. Plaid Link and the other activities the app starts have windows of
  their own, which the flag does not reach.
- **`FakeScreenSecurity`** (`fake_screen_security.dart`, the tests): records every call.

## The monotonic clock

`core/platform/monotonic_clock.dart`, pure Dart: `MonotonicClock.elapsed()`, time since
a fixed point that never goes back and that the user cannot change. The lock measures the
time in the background with it (`lock.md`).

- **`ChannelMonotonicClock`** (`channel_monotonic_clock.dart`, every flavor): the
  `dev.tarnan.financetracker/clock` channel's `elapsedRealtime`, which `MainActivity`
  answers with `SystemClock.elapsedRealtime()` in milliseconds. That clock counts deep
  sleep; a Dart `Stopwatch` (`CLOCK_MONOTONIC`) stops in it and would undercount a phone
  that slept in a pocket.
- **`FakeMonotonicClock`** (the same file, the tests): stands still until `advance`.

riverpod_lint runs as an analyzer plugin declared in the workspace root's
`analysis_options.yaml` and enabled for the app by including that file from
`app/analysis_options.yaml`. `dart analyze` reports its diagnostics and `flutter analyze` does
not, so the gate runs both (`testing-tools.md`).

## The backup picker

`core/platform/backup_picker.dart` is the platform boundary for opening a backup file
(`backup.md`), pure Dart: a `BackupPicker` has `pick()`, a `PickedFile` for the file the
user chose (its `length`, its bytes by `read(start, end)`, and `close()`) or null when
they chose none, so a caller can look at a file's start and refuse it before reading it
whole; the dialog failing, or a file that cannot be read, is a
`BackupPickFailedException`.

- **`PlatformBackupPicker`** (`platform_backup_picker.dart`, dev and prod):
  `flutter_file_dialog`'s `pickFile`, the Storage Access Framework's "open document" (no
  permission), with no MIME filter (the system does not know `.ftbk`; the header's magic
  tells a backup from any other file). The plugin copies the file into
  `<cache>/file_dialog-<uuid>/`; the copy is read in the ranges asked for and its
  directory deleted on `close`. A platform error is logged by its code alone.
- **`FakeBackupPicker`** (`fake_backup_picker.dart`, the demo flavor and the tests):
  answers its `file` (none by default) with an optional `length` to report, throws a
  set `failure`, records the ranges read and counts the calls and closes.

## The API client

`app/lib/core/api/`: the app's only way to the server (`PLAN.md` §6.5), over the generated
client (`api.md`), which nothing outside this folder imports.

| File | What |
|---|---|
| `finance_api.dart` | `FinanceApi`: one method per contract operation (the webhook receiver aside), taking and returning `shared_models` values, the sync engine's `PushResult` and `PullPage`, and `api_models.dart`'s values; and `sessionEnded`, fired when the client ended the session itself |
| `api_models.dart` | The values in the contract's own shapes: `AuthResult`, `LinkToken`, `LinkedItem` (an `Item` with its `Institution`), `SyncRun`, `VersionPage<T>`, `Health`, the liability values with their `source` (read into `shared_models`' `Liability` by `Liabilities.toEntities`, the rates in basis points through `basisPointsOf`), and the holding, security and investment-transaction values with their `source` (`Money` amounts, `LocalDate` dates, `Decimal` strings; read into `shared_models`' entities of the same names, the `Decimal`s parsed, by `Holdings.toEntities` and `InvestmentTransaction.toEntity`), each with the contract's JSON |
| `http_finance_api.dart` | `HttpFinanceApi`: the implementation over the generated client |
| `api_config.dart` | `buildDio(config, {adapter, baseUrl, version})`, `apiBaseUrl`, `contractVersion` |
| `auth_interceptor.dart` | Bearer tokens and the single-flight refresh |
| `problems.dart` | `ApiException` and its subtypes |
| `token_store.dart` | `TokenStore`, `Session`, `SecureTokenStore`, `InMemoryTokenStore` (`auth.md`) |
| `api_providers.dart` | The providers and `apiOverridesFor(config)` |
| `fake/` | The in-app fake server |

- **The boundary.** `HttpFinanceApi` converts through the contract's JSON: a generated
  model is serialized back and read with the `shared_models` entity's (or
  `api_models`') `fromJson`, a request is the entity's JSON deserialized into the
  generated model. So the generated `source_` comes back as `source`, `minor_units` stays
  an `int`, `Decimal` values stay strings, `Date` becomes `LocalDate` and instants stay
  UTC milliseconds. Pushed entries travel without `synced`; pulled ones come back
  `synced: true`, without `seq`, their payload plain JSON. A refused push entry's `code`
  becomes the engine's `PushRejectionReason`.
- **`buildDio`.** The base URL is the flavor's server URL plus `/v1` (dev:
  `http://10.0.2.2:8080/v1`). In prod a non-`https` URL is a `StateError` before any
  request (`PLAN.md` §12: Dart's `HttpClient` ignores Android's network security config,
  so the rule holds here and in `bootstrap`). Certificate checks are never relaxed: the
  adapter is Dio's default with no `createHttpClient` or `validateCertificate`, wrapped in
  `ResettableHttpClientAdapter` (`httpConnectionsProvider`), whose `reset()` closes the
  pool without force and opens a new one (Sync now and a returning network call it,
  `sync-app.md`). A build
  with no server URL fails every request as a `NetworkError` (`notConfigured`). Timeouts
  are 10 s to connect, 30 s to send a body and 30 s to receive; every request sends `User-Agent:
  finance-tracker/<version> (<flavor>)`. In dev only, `DevLogInterceptor` logs one line
  per answer on the `api` logger: method, path template, status, duration and the
  server's `X-Request-Id`, never a body, a query or a token.
- **Bytes.** `getInstitutionLogo` returns the PNG as `Uint8List`. `Institution.logoUrl`
  points at that bearer-secured route, so the app fetches logos through this method,
  never by loading the URL. A problem answered to the bytes route arrives as bytes and
  is decoded like any other.
- **Signs.** `SandboxTransaction.amount` is in the app's sign (negative is money out);
  `HttpFinanceApi` negates it into the contract's Plaid sign.
- **Errors.** Every failure is an `ApiException`: `InvalidCredentials`, `EmailTaken`,
  `TokenExpired`, `TokenRevoked`, `NotFound`, `Conflict`, `ItemLoginRequired`,
  `PlaidError`, `RateLimited(retryAfter)`, `SyncCursorInvalid(since)`,
  `ValidationFailed(errors)`, `ServerError` (`internal`, `webhook_unverified`, a code
  this build does not know, an answer it cannot read: any failure converting a 2xx body,
  and a push rejection or sync status this build does not know) and `NetworkError(kind)`
  (no answer: connection, timeout, cancelled, bad certificate, not configured). A caller
  branches on the type. `toString` names only the type, status and code; nothing that
  carries a token (`Session`, `AuthResult`, `LinkToken`) prints it.
- **Tokens and refresh** (`auth_interceptor.dart`). Every operation the contract secures
  gets `Authorization: Bearer` with the stored access token (or a token the call names,
  while signing in). On 401 `token_expired` the request waits for one refresh shared by
  every request that needs it, then is sent again, once: the server rotates refresh tokens
  with reuse detection and no grace window (`server.md`, **Tokens**), so a refresh starts
  only when none is in flight and the stored access token, read again from storage
  (`TokenStore.reload`: the background sync's isolate may have refreshed it), is still
  the one the request carried; otherwise the request is simply sent again with the newer
  token. A refused
  refresh (any 401) or a 401 `token_revoked` clears the stored session, but only while it
  still holds the tokens the failing call used, and fires `sessionEnded`. Refreshed tokens
  are written, and sessions cleared, through `TokenStore.update`, so the check and the
  write are one step. A refresh that
  fails any other way keeps the session and is not retried (if only its answer was lost,
  a retry would present a revoked token). Nothing is retried after a network error.
  Logout and calls with their own token are never refreshed.

**The fake server** (`fake/`). `FakeServer` implements every contract operation in
process behind a Dio adapter (`FakeHttpAdapter`), so the generated client, the wrapper
and the interceptor run unchanged with no network. Its header lists the dev server's
rules it follows: unique lower-cased emails; a device and a refresh-token family per
sign-in; opaque access tokens valid 15 minutes on its clock; rotation with reuse detection;
the live-family bearer check; logout, device removal and account deletion; passwords as
salted SHA-256 (the fake only); one `InMemorySyncRelay` per user behind the server's two
extra `invalid` checks, with 409 `sync_cursor_invalid`; and the Plaid proxy and data
endpoints over a `FakeDataset` (`fake_dataset.dart`). A dataset's transactions,
streams, liabilities, holdings, securities and investment transactions must be `demo`; the fake keeps its ids and assigns only each user's
`sync_version`s, in a fixed order, when an Item's first sync completes (`not_ready`
first, as Plaid). It remembers each link token's user and update Item, so
`completeLink(linkToken)` can play Plaid's side of Link for the fake launcher
(`items.md`). `FakeDataset.sample(today)` is one Item, three accounts and a dozen
transactions, a Netflix stream and the card's liability; `FakeDataset.fromDemoSeed(seed)`
is the persona engine's household (its Items, accounts and transactions, its recurring
expectations as `demo` streams, its card, mortgage and student-loan liabilities, and its
brokerage's holdings, securities and investment transactions, as the demo repositories
hold them, `recurring.md`, `liabilities.md`, `investments.md`);
`FakeDataset.empty()` has none; a `FakeItemData` may carry `institutionLogo` bytes, which
the logo route serves and `logo_url` then points at. The fake also mirrors contract 0.3.0's
Item operations: a refresh answers `started` and makes the next sync re-apply the Item's
rows as modified; the balance refresh answers its accounts; unlinking with
`history=keep` lists the Item `removed` with its data and refuses every call that would
reach Plaid with 409 `conflict`. Its Sandbox controls: reset-login makes the Item
`login_required` until an update-mode link token is created and
`public-demo-update-<item id>` is exchanged, or the fake Link launcher completes an
update-mode Link for it (`completeLink`, which plays Plaid's re-authentication: the app
never exchanges an update-mode token); fire-webhook is a no-op; created
transactions are `demo` rows added at once under new versions, refused with a 400 when
an amount's currency is not its account's (the checking account when none is named); a
provisioning job is queued and completes on the first `getProvisionJob` after the clock
moves, linking the persona's demo Items (no injection) generated at the device's date
(`FakeServer.localDate`, which `fakeApiOverrides` sets from the clock's zone, as the demo
store does). It does not mirror the server's rate limiter. Test hooks: `failNext`,
`failNextNetwork`, `latency`, `advanceClock`, `calls`, `notReadyItems` (Items whose sync
stays `not_ready`), `seededSyncVersionOf` (the version a user's data had reached when `seedLinkedItems`
applied it), `seedUser`, `seedSession`, `seedLinkedItems` (all the dataset's Items,
or the ones named). `test/core/api/fake_contract_test.dart` drives every operation
through the generated client against it and checks every request and answer with
`contract_test` in strict mode.

**Flavors.** `apiOverridesFor(config)`: dev and prod use `HttpFinanceApi` on the network
with `SecureTokenStore`. Demo uses the fake server over the persona's household the demo shows
(`demoSeedProvider`, `data.md`, **The demo seed**) followed by Houndstooth Bank
(`demoLinkableBank`), with the demo user `demo@financetracker.test` seeded, the household's
Items linked and synced (Houndstooth Bank is left for the demo to link), and its session in an `InMemoryTokenStore`, so the demo starts signed in and
makes no network call. The dev flavor built with `--dart-define=FT_FAKE_SERVER=true`
uses the same fake over the sample dataset, empty and signed out, with the session in
memory; the define is ignored in demo and prod. The fake is new in each process, so a
relaunch under the define re-applies its rows over local edits of those `demo` rows.

## Routing and the shell

Typed routes through `go_router_builder` (`core/router/routes.dart`, generated
`routes.g.dart`): a `TypedStatefulShellRoute<AppShellRoute>` with five branches, each
keeping its own navigation stack.

| Tab | Route class | Path | Screen |
|---|---|---|---|
| Accounts | `AccountsRoute` | `/accounts` | `features/accounts/presentation/accounts_screen.dart` |
| | `NewAccountRoute` | `/accounts/new` | `account_editor_screen.dart` |
| | `ItemsRoute` | `/accounts/linked-banks` | `features/items/presentation/items_screen.dart` (`items.md`) |
| | `AccountDetailRoute` | `/accounts/:id` | `account_detail_screen.dart` |
| | `EditAccountRoute` | `/accounts/:id/edit` | `account_editor_screen.dart` |
| Transactions | `TransactionsRoute` | `/transactions`, `/transactions?search=true` | `features/transactions/presentation/transactions_screen.dart`; with `search=true` (Search transactions) it starts searching, and closing that search goes to `/transactions` |
| | `NewTransactionRoute` | `/transactions/new?account=<id>`, `/transactions/new?receipt=camera` | `transaction_editor_screen.dart`; with `receipt=camera` (Scan receipt) the camera opens for the receipt photo, under the lock once unlocked |
| | `DuplicatesRoute` | `/transactions/duplicates` | `features/duplicates/presentation/duplicate_review_screen.dart` (`duplicates.md`) |
| | `TransactionRoute` | `/transactions/:id` | `transaction_editor_screen.dart` |
| Plan | `PlanRoute` | `/plan` | redirects to `/budgets` |
| | `BudgetsRoute` | `/budgets` | `features/budgets/presentation/budgets_screen.dart` (`budgets.md`), the Budgets segment |
| | `NewBudgetRoute` | `/budgets/new` | `budget_editor_screen.dart` |
| | `EditBudgetRoute` | `/budgets/:id` | `budget_editor_screen.dart` |
| | `BudgetTransactionsRoute` | `/budgets/:id/transactions` | `budget_detail_screen.dart` |
| | `BillsRoute` | `/bills` | `features/bills/presentation/bills_screen.dart` (`bills.md`), the Bills segment |
| | `NewBillRoute` | `/bills/new?stream-id=<id>`, `/bills/new?liability-account-id=<id>` | `bill_editor_screen.dart`, prefilled from the stream's or the liability's suggestion when given |
| | `SubscriptionsRoute` | `/bills/subscriptions` | `features/recurring/presentation/subscriptions_screen.dart` (`recurring.md`) |
| | `EditBillRoute` | `/bills/:id` | `bill_editor_screen.dart`, where a tapped reminder opens it |
| | `ForecastRoute` | `/forecast` | the Forecast segment: `ForecastView` (`features/forecast/presentation/forecast_view.dart`, `forecast.md`) with its Choose accounts action |
| Insights | `InsightsRoute` | `/insights` | redirects to `/reports` |
| | `ReportsRoute` | `/reports` | the Reports segment: `ReportsView` (`features/reports/presentation/reports_view.dart`, `reports.md`), with the alerts bell and the export menu (`export.md`) |
| | `WeeklySummaryRoute` | `/reports/weekly` | `weekly_summary_screen.dart` (`reports.md`, **The weekly summary**), opened from the Reports segment and from its in-app notice |
| | `NetWorthRoute` | `/net-worth` | the Net worth segment: `NetWorthView` (`features/net_worth/presentation/net_worth_view.dart`, `net-worth.md`) |
| | `InvestmentsRoute` | `/investments` | the Investments segment: `InvestmentsView` (`features/investments/presentation/investments_view.dart`, `investments.md`) |
| | `GoalsRoute` | `/goals` | the Goals segment: `GoalsScreen` (`features/goals/presentation/goals_screen.dart`, `goals.md`) with its New goal action |
| | `NewGoalRoute` | `/goals/new` | `goal_editor_screen.dart` |
| | `GoalDetailRoute` | `/goals/:id` | `goal_detail_screen.dart` |
| | `EditGoalRoute` | `/goals/:id/edit` | `goal_editor_screen.dart` |
| | `NewContributionRoute` | `/goals/:id/contribute` | `contribution_editor_screen.dart` |
| Settings | `SettingsRoute` | `/settings` | `features/settings/presentation/settings_screen.dart` |
| | `CategoriesRoute` | `/settings/categories` | `features/categories/presentation/categories_screen.dart` |
| | `NewCategoryRoute` | `/settings/categories/new` | `category_editor_screen.dart` |
| | `EditCategoryRoute` | `/settings/categories/:id` | `category_editor_screen.dart` |
| | `RulesRoute` | `/settings/rules` | `features/rules/presentation/rules_screen.dart` |
| | `NewRuleRoute` | `/settings/rules/new` | `rule_editor_screen.dart` |
| | `EditRuleRoute` | `/settings/rules/:id` | `rule_editor_screen.dart` |
| | `ExportRoute` | `/settings/export` | `features/export/presentation/export_screen.dart` (`export.md`): the monthly report as a PDF, the transactions as a CSV |
| | `BackupRoute` | `/settings/backup` | `features/backup/presentation/backup_screen.dart` (`backup.md`): export a backup, restore one |

- The router opens at `/accounts`, and `/` redirects there (`createRouter` in
  `app_router.dart`; `routerFor(ref, initialLocation:)` builds the flavor's router, which
  tests use to open at another location).
- **The session gate.** Outside the shell, `SignInRoute` (`/sign-in`) and
  `RegisterRoute` (`/register`) are the auth screens. In dev and prod the router follows
  the session (`refreshListenable`): a signed-out user goes to `/sign-in`, a signed-in one
  on an auth screen to `/accounts` (`auth.md`, **The gate**). The demo flavor has no gate.
- **The restore offer.** Outside the shell, `RestoreOfferRoute` (`/restore`) is the fresh
  install's offer (`backup.md`, **Restore**). In dev and prod the router also follows
  `restoreOfferProvider`: while it is pending a signed-in user is held at `/restore`;
  once it is answered `/restore` goes to `/accounts`.
- Navigate with the route classes (`const SettingsRoute().go(context)`,
  `AccountDetailRoute(id).push(context)`), never with path strings. Detail and editor
  routes are sub-routes of their branch, so each tab keeps its own stack. `/accounts/new`
  and `/accounts/linked-banks` are declared before `/accounts/:id`, and
  `/transactions/new` and `/transactions/duplicates` before `/transactions/:id`, and
  `/bills/new` and `/bills/subscriptions` before `/bills/:id`, and `/goals/new` before
  `/goals/:id`, so none is read as an id.
- Pushing a route of another branch (a transaction from an account's detail or a
  budget's, category management from the category picker) puts it on top of the current tab's stack: the
  selected tab does not change, and back returns where the user was.
- **Editors close their own page.** A screen that closes after an await (the account,
  transaction, budget, bill, goal, contribution, category and rule editors' Save, the category editor's and
  the account detail's Delete) takes its page with `OwnPage.of` (`core/router/own_page.dart`)
  before the await: `close()` pops only while that page is still the router's top page
  (`isTop`), and otherwise does nothing, so a page opened meanwhile (on another tab, or
  pushed over the editor) is never the one closed. An editor left open that way stays
  where it was with its write done, and edits what it saved from then on (a new entity
  keeps its id, its title and menu become the edit ones), so a second Save rewrites it
  rather than creating another.
- `AppShell` (`core/router/app_shell.dart`) shows the selected branch with the navigation
  of the window's size class (**Large screens and foldables**): a Material 3
  `NavigationBar` under it on a compact window, a `NavigationRail` beside it on a medium
  or expanded one; tapping the current tab again returns it to its first screen.
- **The Plan tab** (`PLAN.md` §12 "Navigation: the Plan tab", "5e rulings"). The third
  tab's branch (`PlanBranch`) has three roots, one per segment: `/budgets`, `/bills` and
  `/forecast`. Its first route, `/plan`, redirects to `/budgets`, so the tab opens on
  Budgets and tapping it again returns there. Each segment's screen is a `PlanScaffold`
  (`core/router/plan_scaffold.dart`): the "Plan" app bar with that segment's actions (the
  alerts bell on Budgets, Subscriptions and Add bill on Bills, Choose accounts on
  Forecast), then the Budgets | Bills | Forecast `SegmentedButton` at the top
  of the body, where it grows with the text size (the selected check hidden to save
  width), then the segment's body. Choosing a segment goes to its root; the roots are
  `NoTransitionPage`s, so the switch reads as one screen changing its content. Every
  `/budgets...` and `/bills...` route opens inside the tab. The tab's icon carries a
  badge with the number of missed bills (`bills.md`, **Screens**).
- **The Insights tab** (`PLAN.md` §12 "Insights tab"). The fourth tab's branch
  (`InsightsBranch`) has four roots, one per segment: `/reports`, `/net-worth`,
  `/investments` and `/goals`. Its first route, `/insights`, redirects to `/reports`.
  Each segment's screen is an `InsightsScaffold` (`core/router/insights_scaffold.dart`),
  laid out as `PlanScaffold` is: the "Insights" app bar with the segment's actions, then
  the Reports | Net worth | Investments | Goals `SegmentedButton` at the top of the body.
  Four labels do not fit a phone's width, so the control scrolls sideways and opens
  scrolled to the segment shown. Reports shows the reports (`reports.md`), with the
  alerts bell (`BudgetAlertsButton`) in its app bar, since the weekly summary's notice is
  reached through it; Net worth shows the history and the payoffs (`net-worth.md`);
  Investments shows the investments (`investments.md`, **The segment**); Goals shows the
  goals (`goals.md`) with New goal in its app bar, and every `/goals...` route opens
  inside the tab; a segment whose feature has not landed shows
  `InsightsPlaceholder` ("Coming soon"). The roots are `NoTransitionPage`s. Settings is
  the fifth tab.
- **Snack bars.** Each branch has its own `ScaffoldMessenger`, so a snack bar shown from a
  tab (`ScaffoldMessenger.of(context)` in any of its screens) appears in that tab's screen
  `Scaffold`: above the navigation bar, lifting the screen's floating button rather than
  covering it, and still shown by the screen below when the one that showed it is popped
  (the transaction editor's Undo). Beside a detail the list has a messenger of its own
  (`TwoPane`), so a snack bar shows once, in the pane whose screen showed it.
- **The legacy import.** On its first frame `AppShell` reads `legacyImportResultProvider`:
  when the legacy importer brought anything in at this launch, a snack bar in the current
  tab says how many entries went into "Imported" and their total (and how many could not
  be read), and the summary is cleared, so it is shown once.
- `EmptyState` (`core/widgets/empty_state.dart`) is the body of an empty list: an icon, a
  headline, a line of text and an optional action button.
- `MerchantAvatar` (`core/widgets/merchant_avatar.dart`) is the round avatar of a merchant
  or an institution: a logo URL through `Image.network` or stored bytes through
  `Image.memory`, shown on white once decoded, else (and while loading or when either
  fails) the name's first letter or digit on the given ARGB color, in black or white,
  whichever contrasts more (always above WCAG AA). Decorative unless given a
  `semanticsLabel`. Its colors come from the enrichment fallback (`transactions.md`,
  **Merchants**).

## Large screens and foldables

`PLAN.md` §8, Phase 8. Code: `core/layout/`, `core/router/app_shell.dart`.

- **Window size classes** (`core/layout/window_size_class.dart`), by width as the Material
  3 and Android guidance draws them: compact below 600 dp, medium from 600 to 839 dp,
  expanded from 840 dp. The shell computes the class once, from its own width (a
  `LayoutBuilder`; the shell fills the window, so on a device that is the window's), and
  nothing else reads the window's size to choose a layout. Not from
  `MediaQuery.sizeOf`: many goldens pump a phone-sized box inside the larger default
  test window, where the window's width would put a rail in every one of them. Compact: the
  `NavigationBar`. Medium: a `NavigationRail` with labels. Expanded: the extended rail,
  its destinations padded to 48 dp. The rail scrolls when five labels at a large text
  size outgrow the window's height. The five destinations, the Plan badge and the
  branches are the same in all three, and each branch's navigator keeps its state when
  the window changes class (a `GlobalKey` per navigator). `PlanScaffold` and
  `InsightsScaffold` keep their segment controls in every class.
- **Reading order.** The rail is first on the screen but last in the reading order, as
  the bar is: the body and the rail are semantics containers sorted with
  `OrdinalSortKey`, so a screen reader goes through the screen before the destinations.
- **Two panes** (`core/layout/two_pane.dart`). On an expanded window the Accounts,
  Transactions and Settings tabs, and the Plan tab while its stack starts at `/bills`,
  show `TwoPane`: the tab's list (`AccountsScreen`, `TransactionsScreen`, `BillsScreen`,
  `SettingsScreen`) in the start pane, outside the tab's navigator, and the navigator in
  the end pane. The shell chooses by the first location of the branch's stack, so a
  page pushed from another tab (a transaction from an account) opens beside the list of
  the tab it was pushed in. The list's own route (`/accounts`, `/transactions`,
  `/bills`, `/settings`) builds `ListPane`: the list on a compact or medium window, a
  `DetailPlaceholder` ("Choose an account to see it here") in the end pane. The URL stays
  the source of truth: `/accounts/:id` is the list and the account side by side on an
  expanded window and the account pushed over the list on a smaller one; Back pops the
  end pane's navigator, closing the detail. A list opens every page it opens (a detail,
  a new one, the linked banks, duplicates, subscriptions, each settings screen) with
  `openDetail(context, location)`: from a start pane `go`, so the page replaces the one
  beside the list rather than stacking, and for another tab's page (the linked banks
  from Settings) `go` back to the list and then `push`, so Back returns to the list in
  this tab; `push` otherwise. Editors and sub-screens pushed from a detail open in the
  end pane too. The list is one element wherever it is shown: the shell's start pane and
  `ListPane` key it with the same `GlobalKey` (`ListKeys`, one per list type, owned by
  the shell), so a tablet turned or a foldable folded keeps its scroll, its search field
  and its selection. With a list and a detail each showing a floating button on an
  expanded window, both stay, each its own pane's action. The start pane is two fifths of the
  room, within 320 and 440 dp; the shell shows one pane when the room beside the rail is
  under `TwoPane.minWidth` (560 dp: the extended rail's labels grow with the text size).
  Each pane is its own semantics container (the end pane's navigator would otherwise
  hide the list from a screen reader), and the start pane's heroes are off (its floating
  button would share the detail's hero tag).
- **Folds.** `verticalFold(context)` is the window's vertical fold or hinge
  (`MediaQuery.displayFeatures`, type fold or hinge, state `postureFlat` or
  `postureHalfOpened`). `TwoPane` splits on it, the start pane ending where the fold
  starts and the end pane starting where it ends, in either text direction, when each
  pane keeps at least 240 dp; it places the fold in its own coordinates by sitting flush
  with the window's end edge, as the shell's body does. The shell shows the narrow rail
  (labels, not extended) on such a window, so the list has the room before the fold. A
  horizontal fold, a fold outside the panes or one of unknown posture leaves the usual
  split; a folded foldable shows its outer display, compact, with one pane. An account
  card narrower than a phone's puts its balance under the name. On the harness's Pixel
  Fold AVD (`ft-fold`) the engine reports the fold: unfolded (841 by 701 dp) a `fold` at
  x 420.6, `postureFlat`, or `postureHalfOpened` at `posture half`; folded, the outer
  display (411 by 797 dp) reports only its camera cutout.
- **Tests.** `test/core/router/app_shell_layout_test.dart` (the classes, the bar and the
  rails, the reading order, a window changing class), `test/core/layout/two_pane_test.dart`
  (each list and its detail, `openDetail`, Back, deep links, another tab's page, the
  compact and medium windows), `test/core/layout/two_pane_fold_test.dart` (the fold
  split with injected display features). Goldens and their device sizes: **Tests**.

## Launch links

A home screen widget's tap and an app shortcut open the app at a `financetracker://`
link; `core/router/launch_links.dart` maps each to a router location (`launchTargetOf`),
and a link it does not know opens nothing (logged without the link).

| Link | Location |
|---|---|
| `financetracker://accounts` | `/accounts` |
| `financetracker://insights/net-worth` | `/net-worth` |
| `financetracker://plan/budgets`, `…/plan/budgets/<id>` | `/budgets`, `/budgets/<id>/transactions` |
| `financetracker://plan/bills`, `…/plan/bills/<id>` | `/bills`, `/bills/<id>` |
| `financetracker://transactions/new`, `…?receipt=camera` | `/transactions/new`, `/transactions/new?receipt=camera` |
| `financetracker://search` | `/transactions?search=true` |
| `financetracker://sync` | `/settings`, and a sync session (`SyncController.syncNow`, which does nothing in demo) when the app was already running; a cold start syncs anyway |

- **The seam.** `core/platform/launch_intent.dart`, pure Dart: `LaunchIntent.initial()`,
  the link of a cold start, and `opened`, the links that reach the running app.
  `PlatformLaunchIntent` (every flavor, one instance for the process, so a restart in the
  process does not reopen the first link) reads a widget's link from `home_widget`
  (`initiallyLaunchedFromHomeWidget`, `widgetClicked`) and a shortcut's from
  `quick_actions` (its type is the link; `initialize`'s handler); both plugins hear
  `MainActivity`'s `onNewIntent`, so a second tap or shortcut after backgrounding reaches
  the router, and `MainActivity` makes each new intent its own (`setIntent`). When
  Android recreates the activity (after the process died, from Recents:
  `savedInstanceState` is set) or relaunches it from history
  (`FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY`), `MainActivity.onCreate` clears the intent's
  link and the shortcut's extra before the plugins read them, so the destination (the
  camera, for Scan receipt) is not reopened unasked.
  `FakeLaunchIntent` starts at a given link and delivers others with `open`.
- **Routing.** `bootstrap` reads `initial()` before `runApp` and sets
  `launchLocationProvider`, which `goRouterProvider` opens at; after the first frame it
  sends every `opened` link through `openLaunchLink` (`router.go`, and `syncNow` for Sync
  now). The session gate, the restore offer and the lock apply as to any location: under
  the lock the destination is built behind the gate. Being a `go` to the destination's
  URL, a link lands as the two-pane shell draws that URL (**Large screens and
  foldables**): on an expanded window `…/plan/bills/<id>` is the bills list beside the
  bill, and `…/search` the transactions searching beside their placeholder (the shell
  passes `search` to the list it shows in the start pane). The embedding's own deep linking is
  off (`flutter_deeplinking_enabled` false in the manifest, `build.md`), so an intent's
  data never reaches the router as a raw route.
- **Shortcuts.** `core/platform/app_shortcuts.dart`, pure Dart: `AppShortcuts.set(list)`
  of `AppShortcut(link, title, icon)`. `QuickActionsAppShortcuts` (every flavor) sets them
  as `quick_actions`' dynamic shortcuts; `FakeAppShortcuts` records. `appShortcutsFor`
  (`launch_links.dart`) is the list, in the ARB's words for the device's language: Add
  transaction, Scan receipt, Search transactions and Sync now, with the adaptive icons
  `res/drawable/ic_shortcut_{add,receipt,search,sync}.xml`. `bootstrap` sets them after the
  first frame, in every flavor (Sync now opens Settings in demo).

## Theme

`AppTheme` (`core/theme/app_theme.dart`): Material 3 light and dark `ThemeData` from
`ColorScheme.fromSeed(seedColor: Color(0xFF6750A4))`, the baseline purple. When the device
supplies dynamic color schemes (Android 12 and later) and `Settings.useDynamicColor` is on,
those schemes are used instead. Both themes carry `FinanceColors`
(`core/theme/finance_colors.dart`), a `ThemeExtension` with `outflow` (red) and `inflow`
(green), each meeting text contrast on the light or dark surfaces; read it with
`FinanceColors.of(context)`. With a dynamic scheme both are harmonized with the scheme's
primary (`FinanceColors.harmonized`, dynamic_color's `harmonizeWith`: the hue moves
toward the primary's by at most 15 degrees, the tone stays, so the contrast holds), and a
color the user chose that a chart draws (a category's slice in the Reports donut) goes
through `FinanceColors.custom`, harmonized the same way; every other chart color comes
from the `ColorScheme`. With the baseline scheme nothing is harmonized. `AmountText` (`core/widgets/amount_text.dart`) draws a `Money`
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

An instant shown as a date and a time goes through `formatDateTime(instant, location)`
(`core/time/date_time_format.dart`): intl's `yMMMd().add_jm()` in the clock's zone, with the
narrow no-break space intl puts before AM and PM (U+202F) replaced by a no-break space
(U+00A0), which the test fonts carry (**Tests**, goldens).

`setUpTimeZones()` (`core/time/time_zone_setup.dart`) loads the full `latest` time zone
database (not `latest_10y`, `PLAN.md` §12) and sets `tz.local` from `deviceZoneName()`,
`FlutterTimezone.getLocalTimezone()`'s identifier, which the bill reminders also read on
resume (`bills.md`). A failing platform call, or an identifier
the database does not know, logs a warning and leaves `tz.local` at UTC, so startup goes
on; the settings About section shows the active zone, so the fallback is visible.

## Notifications

`core/platform/notifier.dart` is the boundary between what the app tells the user and how
the platform shows it: `Notifier.notify(AppNotification)`, where an `AppNotification` is a
sealed class of typed data, never text, so whoever shows it localizes it (`BudgetThresholdNotification`, `budgets.md`; `BillDueNotification`, a bill due today
or tomorrow, `bills.md`; `WeeklySummaryNotification`, the weekly summary of the week just ended,
`reports.md`; `SyncProblemNotification`, sync failing for a day, a session the server
ended or a bank that needs its sign-in, `background.md`). `appNotifierProvider` is
`InAppNotifier` by default and in demo, which
adds to `inAppNotificationsProvider`: newest first, one per key, at most 50, each with a read
flag (`markRead(key)`, `markAllRead()`), in memory, so a restart empties it. In dev and
prod it is a `CompositeNotifier` of the in-app list and the `SystemNotifier`, which posts
each kind (a bill due excepted) to its Android notification channel (`background.md`,
**Notifications**). The Budgets
screen's bell shows the in-app list (`budgets.md`, **Screens**). Platform code
stays behind interfaces like this one (`CLAUDE.md`, **Security and platform**).

## Reminders

`core/platform/reminder_scheduler.dart` is the platform boundary for bill reminders, pure
Dart: `ReminderScheduler` with `ensurePermission({request})`, `replaceAll(reminders)` (the
pending set made exactly those, the rest cancelled by id, a shown notification kept),
`pending()`, `cancelAll()` (pending only), `clearAll()` (pending and shown, every kind:
the local wipe's), `openSettings()` and `openedBillIds`, over
`ScheduledReminder(id, billId, dueDate, at, title, body)`, whose payload carries the bill,
the due date and the instant. `local_notifications_scheduler.dart` implements it over
`flutter_local_notifications` in dev and prod (inexact, the channel `bill_reminders`,
through the app's one plugin initialization, `local_notifications.dart`, with the small
icon `ic_stat_bill`; `build.md` for the Android pieces), and
`fake_reminder_scheduler.dart` in the demo flavor and the tests. The instants and the
rescheduling rules are `bills.md`, **Reminders**.

## Logging

`core/logging/app_log.dart`, on `package:logging`. Each area logs through its own
`Logger('<area>')`. dev and demo print every record with `debugPrint`; prod keeps a
sanitised copy of the last 500 records in memory (`recentLogRecords()`), for the local crash
log Phase 7 exports at the user's request. `forwardUncaughtErrors()` sends
`FlutterError.onError` and `PlatformDispatcher.instance.onError` to the `app` logger.
**Never log an amount, a merchant, a description or a token** (`PLAN.md` §6.6).

The prod sink is the second line of defence (`sanitizedRecord`, `PLAN.md` §12): the copy
keeps the level, the logger, the zone and the stack trace; its message has every bearer
token, JWT (padded or not), Plaid `access-*`, `public-*` and `link-*` token, email address
(Unicode letters included), `x'` hex key literal, run of 32 or more hex digits and run of
40 or more base64url or base64 characters holding an uppercase letter, a lowercase letter
and a digit (the server's refresh tokens, base64 keys; a stack frame, a path or a
snake_case name lacks one and is kept) replaced by `[redacted]` (`scrubLogText`), and a
message that was a logged object's `toString` becomes that object's type; its error is
reduced to the error's runtime type (an exception's text can carry an amount or a
merchant, which no pattern can find); it carries no object. A merchant or an amount written into a message by hand is not caught:
the call-site rule above is the defence there. The mixed-run rule has a residual too: a
run of 40 or more with no digit or no uppercase letter is kept, which is about 1 in 1,400
random base64url refresh tokens; it is accepted because the call-site rule is the first
defence and a looser rule redacts paths. `app/test/core/logging/app_log_test.dart`
feeds the sink a token, an email and a key in messages and errors and an amount and a
merchant through an exception's text, and checks that none is kept while the stack trace
is. The dev sink prints records unchanged.

## Localization

Every user-visible string is in `app/lib/l10n/app_en.arb` with a description;
`app/l10n.yaml` generates `AppLocalizations` (`nullable-getter: false`) into `app/lib/l10n/`,
committed. Read strings with `AppLocalizations.of(context)`. `flutter pub get`, `run`,
`test` and `build` regenerate it (`generate: true`); after editing the ARB run
`flutter gen-l10n` and commit the output, which the gate's codegen step checks.

- **Locales.** English (`app_en.arb`, the template: every key with an `@key`
  description, every placeholder typed, `plural` or `select` wherever a count or a kind
  changes the wording); Spanish (`app_es.arb`, a skeleton of the most visible strings: the
  tabs and segments, the common actions, the empty states, Settings, the account and
  transaction basics, the two-pane placeholders; the rest falls back to English); and the
  pseudo-locale `en_XA` (`app_en_XA.arb`, Android's own name for one: gen-l10n accepts
  no made-up language code), generated by `tools/pseudo_locale.dart`
  (`testing-tools.md`) with every string accented, lengthened by 40 percent and
  bracketed. After changing `app_en.arb`, run `dart run tools/pseudo_locale.dart` and
  `flutter gen-l10n`: the gate's strings step fails while the pseudo-locale is out of
  step with the template, and prints how far Spanish is behind.
  Resolution is gen-l10n's: the device's exact locale, then its language, then English.
- **The language choice.** In dev and demo, Settings → Appearance → Language offers
  System, English and Pseudo (`features/settings/domain/app_language.dart`,
  `application/app_language_controller.dart`), kept in `app_meta` under `app_language`
  and never synced; `FinanceTrackerApp` passes it as `MaterialApp.locale`. Prod offers no
  choice and leaves `en_XA` out of `supportedLocales`.
- **Formatting.** Amounts (`Money.format`, `Money.parse`) and dates (`DateFormat`)
  format in intl's default locale, which `bootstrap` sets to the device's locale (en_US
  when intl has no data for it), with the date symbols of every locale loaded
  (`initializeDateFormatting`); choosing English or Pseudo sets it to en_US (intl has no
  data for `en_XA`), choosing System sets the device's again. What the user reads passes
  no locale of its own; the legacy importer reads the original app's amounts in en_US,
  and the PDF report formats in the locale it is given (`export.md`).
- **Joins.** Text shown as one line from several pieces goes through a template, never
  a separator in code: `captionLine` (`captionPair`, "{first} · {second}"), `listLine`
  (`listPair`, "{first}, {second}") and `sentenceLine` (`sentencePair`, "{first}
  {second}", for sentences and semantics summaries) in `core/l10n/joins.dart`, or a
  message of its own with placeholders (`forecastEventAmount`).
- **The check.** `tools/check_strings.dart`, run by the gate (`testing-tools.md`): no
  string literal that reads as prose in the presentation code outside the ARB and
  `tools/check_strings_allowlist.txt`, no ` · `, `, ` or ` ` separator passed to `join` and no
  interpolations joined only by a separator or spaces; and the pseudo-locale current
  with the template. A string built with `+` gets past it; review catches those.
- **Tests.** `test/l10n/localization_test.dart` (the Spanish skeleton on a Spanish device,
  Spanish amounts, dates and plurals, the language choice and its absence in prod, a
  two-pane screen laid out right to left); `test/accessibility_test.dart` lays every
  screen that opens without a tap out in the pseudo-locale.

## Settings

| Layer | File | What |
|---|---|---|
| domain | `domain/settings.dart` | `Settings`: `themeMode` (`AppThemeMode.system`, `light`, `dark`) and `useDynamicColor`; `Settings.defaults()` is system and on |
| domain | `domain/settings_repository.dart` | `SettingsRepository`: `watch()` (current value first, then each save), `read()`, `save()` |
| data | `data/drift_settings_repository.dart` | The Drift implementation (dev and prod): one `app_settings` row per field |
| data | `data/in_memory_settings_repository.dart`, `data/demo_settings_repository.dart` | The in-memory implementation (tests) and the demo one (the demo flavor) |
| application | `application/settings_controller.dart` | `SettingsController`, following `watch()`; each change reads, changes and saves, and changes run one after another so two issued together both land |
| domain, application | `domain/app_language.dart`, `application/app_language_controller.dart` | `AppLanguage` (`system`, `english`, `pseudo`) and `AppLanguageController`, kept in `app_meta` (`app_language`), device-local (**Localization**) |
| presentation | `presentation/settings_screen.dart` | Account (`features/auth/presentation/account_section.dart`, `auth.md`, with Linked banks), Sync (when the local data syncs: dev and prod, `sync_section.dart`, `sync-app.md`), Appearance (a `SegmentedButton` for the theme mode, a `SwitchListTile` for dynamic color, and in dev and demo a `SegmentedButton` for the language), Security (`features/lock/presentation/security_section.dart`: Require unlock, Lock after and Block screenshots, kept in `app_meta`, `lock.md`), Notifications (the row opening `notifications_screen.dart`, Settings → Notifications, `background.md`), Data (Categories, opening category management, `categories.md`; Rules, `rules.md`; Export, `export.md`; Backup, `backup.md`, which in the demo flavor only says that the demo's data is not kept or backed up), About (app name, version and build, flavor, time zone), Demo data (demo only, `demo_data_section.dart`: the persona the demo shows) and Developer (dev only, `features/developer/presentation/developer_section.dart`: diagnostics, Pull now and the Sandbox controls, `developer.md`); each section starts with a `SettingsSectionHeader` (`presentation/settings_section_header.dart`) |

The repository contract is `test/contract/settings_repository_contract.dart`,
`runSettingsRepositoryContract(create, {dispose})`; the three implementations each run it
(`data.md`, **Three implementations, one contract**).

## Tests

- **`test/helpers/pump_app.dart`.** `pumpApp(tester, {overrides, config, initialLocation,
  brightness, textScale, size, clock, signedIn, router})` pumps the real app at phone size (412 by 915) and settles.
  The other sizes it names: `tabletSize` (1024 by 768, expanded), `mediumSize` (701 by
  841, a Pixel Fold's inner display upright), `expandedSize` (1280 by 800, a Pixel Tablet
  on its side) and `foldSize` (841 by 701, the Pixel Fold's inner display on its side,
  with `foldBounds` down its middle at 420.5).
  `buildTestApp` is the same app as a widget, for goldens; `testOverrides` is its override
  list: the flavor (prod by default) as `appConfigProvider` only, not the flavor's
  `overridesFor` wiring, so every test runs on the in-memory repositories; the `clock`
  passed, else `testClock` (24 October 2026, 15:00 UTC, in UTC); `testPackageInfo` (1.0.0, build 1); settings whose
  theme mode gives `brightness`; the API on the in-app fake server
  (`fakeApiOverrides`), with the demo user signed in unless `signedIn: false`, the device
  named "Pixel 6" and the app version pinned; and the flavor's router (`routerFor`, so dev
  and prod go through the session gate) at `initialLocation`, or `router` instead for a
  screen with no route of its own (the forecast's); then the test's own
  overrides, which win. Riverpod's retry is off so a failing provider fails at once. A
  widget test reads the fake server with `ProviderScope.containerOf(...)` and
  `fakeServerProvider`; it must not `await` a client call itself (the client's Dio steps
  run on zero-length timers, which only `pump` advances), but start it and
  `pumpAndSettle`.
- **Goldens** use `alchemist`. `test/flutter_test_config.dart` runs every test with CI
  goldens on (Ahem, text drawn as blocks, identical on every OS; written to `goldens/ci/`
  next to the test, committed, compared by the gate and CI). A character neither Ahem nor
  FlutterTest carries is borrowed from the host's fonts, so its width differs between macOS
  and Linux: intl's U+202F before AM and PM did this, which is why times go through
  `formatDateTime` (**Time**); text in a CI golden must avoid such characters. Platform goldens (real fonts,
  `goldens/<os>/`, gitignored) are a local aid: written only by `--update-goldens` when the
  `CI` environment variable is unset, and never compared, since a fresh clone has none.
  Golden tests are tagged `golden` (`app/dart_test.yaml`). Update them with
  `flutter test --update-goldens --tags golden` and look at the platform images before
  committing the CI ones. The shell's goldens (`test/core/router/app_shell_golden_test.dart`)
  hide Flutter's DEBUG banner, which is not part of the app; they include the Accounts
  tab in each size class (`shell_accounts_{compact,medium,expanded}_light` at
  `phoneSize`, `mediumSize`, `expandedSize`), a transaction beside the transactions
  (`shell_transactions_two_pane_expanded_light`), an account beside the accounts split on
  a fold (`shell_accounts_fold_light` at `foldSize`) and Settings at `tabletSize`.
- **Test data.** `test/helpers/seed.dart`: `seededStore()` is an `InMemoryStore` on the test
  clock (or the `clock` passed) with the system categories and the test seed (`test/helpers/test_seed.dart`, the Phase 1 demo seed) dated to that
  clock's today (or a seed the test passes), and `storeOverride(store)` puts the in-memory repositories on it;
  the test keeps the store to read back what a screen wrote. `testTransaction(...)` builds a
  manual transaction relative to the test clock. Widget tests whose rows must all be laid
  out pump a taller `size`: the test font draws every character as a square, so rows are
  taller than on a device.
- **Accessibility.** `test/accessibility_test.dart` checks every screen, light and dark,
  at text scales 1 and 2, against `androidTapTargetGuideline`, `labeledTapTargetGuideline`
  and `textContrastGuideline`, and lays each out at text scale 2.0 and, when it opens
  without a tap, in the pseudo-locale, expecting no exception: the shell's tabs empty, and
  every screen, the filter sheet and the category picker on the demo seed; the
  large-screen layouts (a list beside its detail on an expanded window, the rail on a
  medium one, the panes split on a fold) are checked the same way. A new screen joins the
  list. Focus order follows reading order, except the shell's rail, which reads after the
  screen (**Large screens and foldables**). A value that changes under the user is a live
  region (the sync status in Settings, the backup's progress, the lock's message).
