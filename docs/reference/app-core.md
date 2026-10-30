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
   `Money.parse` without a locale follow the device; a locale change while the app runs is
   not followed yet;
6. a `ProviderContainer` with `overridesFor(config)`;
7. in dev and prod, `openLocalData(container)`: the database opens (`data.md`,
   **Encryption and the key**), the held records of every type this build knows are
   released (`sync-app.md`, **Unknown types**; a failure is logged by type and leaves
   them held), `install_date` is recorded on the first launch, the system categories are
   seeded and the legacy importer runs once. Any failure to open is logged by type and
   `runApp(DatabaseErrorApp(failure: ...))` shows a plain error screen instead of the
   app, with a message for a missing cipher, a wrong key, a lost key, or anything else;
8. the stored session is read (`sessionControllerProvider`'s `restored()`, `auth.md`),
   so the first frame is already signed in or out; then the sync controller starts
   (`sync-app.md`, **The controller**) and, in every flavor, the budget alert watcher is
   listened to (`budgets.md`, **Alerts**);
9. `runApp(UncontrolledProviderScope(container: container, child: FinanceTrackerApp()))`;
10. after the first frame, in every flavor, the reminder watcher is listened to (the bill
    reminders are planned then and whenever their inputs change, `bills.md`,
    **Reminders**) and `reminderSchedulerProvider.openedBillIds` pushes `/bills/:id` for
    a tapped reminder;
11. in dev and prod, after the first frame, `sweepReceipts(container)`: the receipt files
    no live transaction references are deleted (`data.md`, **Receipts**), a failure
    logged by type only.

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
| `appNotifierProvider`, `inAppNotificationsProvider` | `core/platform/in_app_notifications.dart` | Where the app's notifications go (**Notifications**): the in-app list in every flavor |
| `plaidPullStoreProvider`, `arrivalProcessorProvider`, `plaidPullProvider` | `core/di/providers.dart` | The Plaid pull (`sync-app.md`, **The Plaid pull**): its cursors in memory by default and in `sync_meta` in dev and prod, the rules run on what it inserts (`RuleRunner`, `rules.md`), and the pull over the API into the repositories |
| `inMemorySyncStoreProvider`, `driftSyncStoreProvider`, `deviceClockProvider`, `changeRecorderProvider`, `recordingSyncStoreProvider` | `core/di/providers.dart` | The sync stores, the device clock, the recorder the repositories record through, and the store it records into (which the rules' owned-field guard reads, and in whose transaction a rule is applied to the existing transactions): in memory by default, Drift in dev and prod, none in demo (`sync-app.md`) |
| `syncDeviceIdProvider`, `syncRelayProvider`, `localDataSyncsProvider`, `syncDebounceProvider` | `core/di/providers.dart` | The session's device id and the API's relay as that device while signed in (null otherwise), whether the local data syncs (dev and prod), and the debounce after a local change |
| `syncControllerProvider` | `core/sync/sync_controller.dart` | The sync status and Sync now (`sync-app.md`) |
| `demoPersonaProvider`, `demoSeedProvider` | `core/di/providers.dart` | The persona the demo flavor shows and its demo seed (`data.md`, **The demo seed**) |
| `legacyImportResultProvider` | `core/di/providers.dart` | The legacy importer's `ImportSummary` at this launch, or null; `AppShell` shows it once and clears it |
| `todayProvider` | `core/time/today_provider.dart` | The clock's local date, kept current past midnight (**Time**) |
| `goRouterProvider` | `core/router/app_router.dart` | The app's `GoRouter` (`routerFor`), gated on the session in dev and prod, disposed with the container |
| `tokenStoreProvider`, `fakeServerProvider`, `financeApiProvider`, `appVersionProvider` | `core/api/api_providers.dart` | The API (**The API client**) |
| `sessionControllerProvider`, `deviceNameProvider` | `features/auth/application/` | The session and the device's name (`auth.md`) |
| `receiptStoreProvider` | `core/di/providers.dart` | Where receipt photos are kept: in memory by default and in demo, files in the support directory in dev and prod (`data.md`, **Receipts**) |
| `imageSourceProvider` | `core/platform/image_source_provider.dart` | The camera and gallery for receipt photos: `image_picker` by default, the fake in demo (**The image source**) |
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
scheduler, the demo ones for demo with the fake image source (and the fake scheduler), and the API's (`apiOverridesFor`: the in-app fake server, with the fake
Link launcher over it, for demo, and for dev under `FT_FAKE_SERVER`); later phases add
theirs there.

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

riverpod_lint runs as an analyzer plugin declared in the workspace root's
`analysis_options.yaml` and enabled for the app by including that file from
`app/analysis_options.yaml`. `dart analyze` reports its diagnostics and `flutter analyze` does
not, so the gate runs both (`testing-tools.md`).

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
  adapter is Dio's default with no `createHttpClient` or `validateCertificate`. A build
  with no server URL fails every request as a `NetworkError` (`notConfigured`). Timeouts
  are 10 s to connect and 30 s to receive; every request sends `User-Agent:
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
  only when none is in flight and the stored access token is still the one the request
  carried; otherwise the request is simply sent again with the newer token. A refused
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
| Transactions | `TransactionsRoute` | `/transactions` | `features/transactions/presentation/transactions_screen.dart` |
| | `NewTransactionRoute` | `/transactions/new?account=<id>` | `transaction_editor_screen.dart` |
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
| | `ReportsRoute` | `/reports` | the Reports segment: `ReportsView` (`features/reports/presentation/reports_view.dart`, `reports.md`) |
| | `WeeklySummaryRoute` | `/reports/weekly` | `weekly_summary_screen.dart` (`reports.md`, **The weekly summary**), opened from the Reports segment and from its in-app notice |
| | `NetWorthRoute` | `/net-worth` | the Net worth segment: a placeholder until net worth lands |
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

- The router opens at `/accounts`, and `/` redirects there (`createRouter` in
  `app_router.dart`; `routerFor(ref, initialLocation:)` builds the flavor's router, which
  tests use to open at another location).
- **The session gate.** Outside the shell, `SignInRoute` (`/sign-in`) and
  `RegisterRoute` (`/register`) are the auth screens. In dev and prod the router follows
  the session (`refreshListenable`): a signed-out user goes to `/sign-in`, a signed-in one
  on an auth screen to `/accounts` (`auth.md`, **The gate**). The demo flavor has no gate.
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
- `AppShell` (`core/router/app_shell.dart`) shows the selected branch above a Material 3
  `NavigationBar`; tapping the current tab again returns it to its first screen.
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
  reached through it; Investments shows the investments (`investments.md`, **The
  segment**); Goals shows the goals (`goals.md`) with New goal in its app bar, and
  every `/goals...` route opens inside the tab; a segment whose feature has not landed shows
  `InsightsPlaceholder` ("Coming soon"). The roots are `NoTransitionPage`s. Settings is
  the fifth tab.
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
- `MerchantAvatar` (`core/widgets/merchant_avatar.dart`) is the round avatar of a merchant
  or an institution: a logo URL through `Image.network` or stored bytes through
  `Image.memory`, shown on white once decoded, else (and while loading or when either
  fails) the name's first letter or digit on the given ARGB color, in black or white,
  whichever contrasts more (always above WCAG AA). Decorative unless given a
  `semanticsLabel`. Its colors come from the enrichment fallback (`transactions.md`,
  **Merchants**).

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
`reports.md`). `appNotifierProvider` is `InAppNotifier`, which
adds to `inAppNotificationsProvider`: newest first, one per key, at most 50, each with a read
flag (`markRead(key)`, `markAllRead()`), in memory, so a restart empties it. Android's
notification channels are Phase 8's implementation of the same interface. The Budgets
screen's bell shows the in-app list (`budgets.md`, **Screens**). Platform code
stays behind interfaces like this one (`CLAUDE.md`, **Security and platform**).

## Reminders

`core/platform/reminder_scheduler.dart` is the platform boundary for bill reminders, pure
Dart: `ReminderScheduler` with `ensurePermission({request})`, `replaceAll(reminders)` (the
pending set made exactly those, the rest cancelled by id, a shown notification kept),
`pending()`, `cancelAll()` (pending only), `openSettings()` and `openedBillIds`, over
`ScheduledReminder(id, billId, dueDate, at, title, body)`, whose payload carries the bill,
the due date and the instant. `local_notifications_scheduler.dart` implements it over
`flutter_local_notifications` in dev and prod (inexact, the one channel
`bill_reminders`, the small icon `ic_stat_bill`; `build.md` for the Android pieces), and
`fake_reminder_scheduler.dart` in the demo flavor and the tests. The instants and the
rescheduling rules are `bills.md`, **Reminders**.

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
| presentation | `presentation/settings_screen.dart` | Account (`features/auth/presentation/account_section.dart`, `auth.md`, with Linked banks), Sync (when the local data syncs: dev and prod, `sync_section.dart`, `sync-app.md`), Appearance (a `SegmentedButton` for the theme mode, a `SwitchListTile` for dynamic color), Data (Categories, opening category management, `categories.md`; Rules, `rules.md`), About (app name, version and build, flavor, time zone), Demo data (demo only, `demo_data_section.dart`: the persona the demo shows) and Developer (dev only, `features/developer/presentation/developer_section.dart`: diagnostics, Pull now and the Sandbox controls, `developer.md`); each section starts with a `SettingsSectionHeader` (`presentation/settings_section_header.dart`) |

The repository contract is `test/contract/settings_repository_contract.dart`,
`runSettingsRepositoryContract(create, {dispose})`; the three implementations each run it
(`data.md`, **Three implementations, one contract**).

## Tests

- **`test/helpers/pump_app.dart`.** `pumpApp(tester, {overrides, config, initialLocation,
  brightness, textScale, size, clock, signedIn, router})` pumps the real app at phone size (412 by 915) and settles.
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
  hide Flutter's DEBUG banner, which is not part of the app.
- **Test data.** `test/helpers/seed.dart`: `seededStore()` is an `InMemoryStore` on the test
  clock (or the `clock` passed) with the system categories and the test seed (`test/helpers/test_seed.dart`, the Phase 1 demo seed) dated to that
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
