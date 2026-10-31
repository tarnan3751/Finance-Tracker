# Finance Tracker

An Android personal finance app in Flutter, grown in place from a one-file manual
income-and-expense tracker. Real bank data from Plaid Sandbox through a development server in
this repository, an offline-first encrypted local database, budgets, bills, insights and net
worth, and a demo mode that runs with no server and no Plaid account. Solo developer with an
agent team.

This file is the **map**: what the project is, where each area lives, the commands, the
conventions and the workflow. The scope, the phases, the status, the risks, the verified Plaid
Sandbox facts and every recorded decision are in `PLAN.md`, which lives at the root of the main
tree (`/Users/tahseenarnan/Development/Finance-Tracker/PLAN.md`) and is **gitignored on purpose**,
so a clone does not carry it: read it from the main tree by that path. How each area works is in
its **reference file** under `docs/reference/`, written when the area lands. Read this file,
then `PLAN.md`'s sections for the phase in progress, then the reference file of every area a
task touches, then the header comments of the files involved. A section named in bold is a
heading of this file or of a doc.

## Status

**Phases 0 to 8 have landed and passed their gates; Phase 9 is next:** the app runs on its Riverpod
and go_router core with manual accounts, transactions and categories on the encrypted Drift database
(schema v13 with the change log, field clocks, Items, rules, budgets and their alerts, dismissed
duplicate pairs, saved filters, a full-text index, recurring streams and their overrides,
liabilities, bills and bill alerts, securities, holdings, investment transactions, daily balance
snapshots, goals and their contributions, the device-local conflicts and the transactions' receipt
hashes); it signs in against the development server through the API client, syncs user data between
devices through the sync engine (contract 0.7.0; a pulled record of a type this build does not know
is held, not failed; a received clock more than an hour ahead is clamped), links banks through Plaid
Link (real Sandbox Items through the server, which polls Plaid and verifies its webhooks), pulls
their accounts and transactions with reported balances and institution logos, applies the user's
rules on arrival and, on request, to the existing transactions; it budgets by category with periods,
rollover, projection and in-app alerts, hides and bulk-edits transactions, reviews likely
duplicates, searches by word prefixes, saves filters, splits transactions and attaches receipt
photos; it pulls Plaid's recurring streams and liabilities, detects recurring streams in every
transaction source with a measured detector and merges the two, classifies subscriptions and lists
them with annual totals, tracks bills with local reminders scheduled at the right wall-clock time
across DST and flags missed payments, and projects 30 and 90 days of cash flow with a confidence
band, all under a Plan tab with Budgets, Bills and Forecast segments; it pulls holdings and
investment transactions, records a balance snapshot per account per day and shows net worth over
time with pre-install history reconstructed from transactions and labelled as derived, reports
spending by category and merchant with comparisons, top movers and anomaly hints measured against
the persona seeds, raises a weekly summary, tracks savings goals with contributions and suggestions,
projects liability payoff, and exports a byte-identical PDF monthly report and a CSV, all under an
Insights tab with Reports, Net worth, Investments and Goals segments; it backs everything up into
one passphrase-encrypted file and restores it onto a fresh install or after a lost key, locks behind
the device's biometrics or screen lock with a privacy screen and screenshot blocking, deletes the
account or erases this device in an order a kill cannot leave half done, lists and removes the
account's devices, shows the losing side of two edits made within ten minutes so the person can keep
either, syncs receipt photos between devices through content-addressed blobs, survives a seeded
chaos simulation of partitions, restarts and clock skew in the gate, and keeps a scrubbed copy of
every log record in release builds; it syncs in the background on a battery-respecting hourly
WorkManager schedule that survives Doze, delegating to the app when it is alive so two isolates
never race the server's token rotation, and syncs again when a network returns; it owns its
notification channels, posts budget alerts, the weekly summary and sync problems to the tray beside
the in-app list, asks for the permission only when a notifying feature is turned on and has a
Notifications settings screen; it keeps three home screen widgets (balances, budgets, upcoming
bills) fresh within one background cycle and masked while the lock is on, and offers four app
shortcuts; it fits a tablet and a foldable with a navigation rail and two panes that split on the
hinge, passes the accessibility guidelines on every screen at two text scales, and carries a
generated pseudo-locale and a Spanish skeleton behind a strings check in the gate; and it runs the
demo flavor on the persona engine's seed against an in-process fake server with no network; the dev
flavor carries a developer menu for the Sandbox controls. The repository is the pub workspace of
**Folder layout**, Android only. The app runs in three flavors (`dev`, `demo`, `prod`) through
`app/lib/bootstrap.dart`; `server/` is the development server implementing the contract with a fake
Plaid client (`docs/reference/server.md`); `api/openapi.yaml` is the v1 contract, with
`packages/api_client` generated from it and `packages/contract_test` checking against it; the
Android build is Flutter 3.47's template with the package id, the flavors and the release hardening;
CI runs the gate, builds the APKs and proves the generated client current. `PLAN.md` §4 is the Plaid
architecture with the verified Sandbox facts, §7.1 the data-coverage and synthesis policy, §8 the
ten phases with sizes, §10 the process, §12 the decisions.

## Stack (pinned)

- **Flutter stable**, pinned by **FVM** through `.fvmrc` (Phase 0); Dart 3.x; **Material 3**;
  **Android only** (minSdk 26, compileSdk 36, package `dev.tarnan.financetracker`).
- **Riverpod** with code generation, **go_router**, **freezed** and json_serializable.
- **Drift** on SQLite with **SQLCipher**; the key in Android Keystore via flutter_secure_storage.
- **dio** with a client generated from `api/openapi.yaml` by openapi-generator's `dart-dio`.
- **plaid_flutter** (Plaid Link). **fl_chart**. **home_widget**, **workmanager**,
  **flutter_local_notifications**, **local_auth**, **intl**, **timezone**.
- **Server**: Dart with shelf and shelf_router, sqlite3, JWT, Argon2id. Never deployed.
- **Money is integer minor units plus a currency code.** Never a `double`.

Check before writing an API call. Flutter 2 and early-3 widgets, Riverpod 1.x syntax, the moor
name for Drift, and Plaid's legacy `/transactions/get` are the most common wrong answers here.
Look a signature up in the real package source under `~/.pub-cache/hosted/pub.dev/<package>-<version>/lib/`
or the Flutter SDK under `/opt/homebrew/share/flutter/packages/flutter/lib/`, and Plaid behaviour
in `PLAN.md` §4, which records what was verified against live Sandbox.

## Commands

`F` names the Flutter command: `fvm flutter` once `.fvmrc` exists, else `flutter`; the tools
scripts pick it the same way. Commands marked with a phase do not exist before it.

| What | Command |
|---|---|
| The gate (format, analyze, codegen freshness, tests, contract) | `tools/gates.sh` |
| Run all tests | `tools/run_tests.sh` |
| Run one package's tests, optionally filtered | `tools/run_tests.sh app "Money"` |
| Format | `dart format .` |
| Regenerate code (Phase 1) | `cd app && dart run build_runner build` |
| Regenerate the API client after a contract change (Phase 2) | `tools/gen_api_client.sh` |
| Run the app, demo flavor (safe anywhere; no network) | `F run --flavor demo -t lib/main_demo.dart` |
| Run the app, dev flavor (the owner only: the owner's emulator and the dev server) | `F run --flavor dev -t lib/main_dev.dart` |
| The dev server (the owner only: reads `server/.env`; Plaid is fake unless `PLAID_MODE=sandbox`) | `tools/run_server.sh` |
| Emulator integration tests, one run on the machine at a time (Phase 1) | `tools/emulator_tests.sh` |
| Provision a persona into Sandbox (the owner only) | `tools/scripts/provision_persona.sh <persona>` |
| Build a debug APK | `F build apk --debug --flavor dev -t lib/main_dev.dart` |
| Build the release APK (R8, obfuscated) | `F build apk --release --flavor prod -t lib/main_prod.dart --obfuscate --split-debug-info=build/symbols` |
| Land a delivered series | `tools/land_series.sh <patch-dir> <base-commit> <tree-hash>` |
| Lint the commits since a base (the gate runs it on `origin/main..HEAD`) | `tools/check_commits.sh <base>` |
| Stop the harness emulator, even past a live lock | `tools/emulator_tests.sh stop [--force]` |
| Run the sync chaos simulation with a seed and a budget | `SYNC_CHAOS_SEED=<n> SYNC_CHAOS_SCENARIOS=<k> dart test -t chaos` in `packages/sync_engine` |
| Sweep the manifest, the extraction rules and a logcat capture for secrets | `tools/secrets_sweep.sh <capture>` (`--self-test` checks the patterns) |
| Run one integration test file on the harness AVD | `tools/emulator_tests.sh integration -- integration_test/<file>.dart` |
| Run the harness on the foldable or the tablet, and set the posture | `FT_EMULATOR_AVD=ft-fold FT_AVD_DEVICE=pixel_fold tools/emulator_tests.sh demo`, then `tools/emulator_tests.sh posture folded\|unfolded`; `ft-tablet` with `pixel_tablet` |
| Check the background job is kept, deferred under Doze and run in its maintenance window | `tools/emulator_tests.sh run tools/scripts/background_doze_check.sh` |
| Regenerate the pseudo-locale after adding strings | `dart run tools/pseudo_locale.dart`, then `flutter gen-l10n` in `app/` |

**Any Flutter run writes files**: `build/` and `.dart_tool/` in the tree it runs in, and a `run`
or `install` writes the app and its data onto whatever emulator or device is attached. The dev
server writes its SQLite database under `server/data/` (gitignored) and reads the Plaid keys from
`server/.env` (gitignored; until `server/` exists they are in `notes/plaid-sandbox.env`, also
gitignored). Agents never install onto the owner's emulators or devices, never run the dev
server with the real keys, never read either env file, and never call Plaid Sandbox: Sandbox
rate limits are per Item and per client, Items are shared state, and the coordinator is the only
seat that touches them. Agents use the fakes and the demo flavor.

**Run the gate after every change.**

## Where things live

| Area | Code | Reference |
|---|---|---|
| Core: theme, routing, dependency injection, errors, utilities | `app/lib/core/` | `docs/reference/app-core.md` (Phase 1) |
| Shared domain: `Money`, `LocalDate`, entities, taxonomy | `packages/shared_models/` | `docs/reference/core.md` |
| Features, one folder each with `presentation/ application/ domain/ data/` | `app/lib/features/<feature>/` | `docs/reference/<feature>.md` as each lands |
| Local database: Drift schema, migrations, repositories in three implementations | `app/lib/features/*/data/`, `app/lib/core/db/` | `docs/reference/data.md` (Phase 1) |
| Sync engine (pure Dart, no Flutter): the merge, the session, the conflicts it reports, the chaos simulation under the `chaos` tag | `packages/sync_engine/` | `docs/reference/sync.md` |
| Sync in the app: the Drift sync store, recording, the controller, the relay, the receipt upload before a push | `app/lib/core/sync/`, `app/lib/core/db/` | `docs/reference/sync-app.md` |
| Background sync and notifications: the WorkManager seam and the cycle, the app and the worker in one process, the channels, the tray, Settings → Notifications | `app/lib/core/background/`, `app/lib/core/platform/`, `app/lib/features/settings/` | `docs/reference/background.md` |
| Widgets and shortcuts: the snapshot and its writer, the refresh runner, the Kotlin providers, the launch intent seam and the launch links | `app/lib/features/widgets/`, `app/android/app/src/main/kotlin/dev/tarnan/financetracker/widgets/`, `app/lib/core/platform/launch_intent.dart`, `app/lib/core/router/launch_links.dart` | `docs/reference/widgets.md` |
| Layout: window size classes, the rail, `TwoPane`, `openDetail`, the fold split | `app/lib/core/layout/` | `docs/reference/app-core.md` (Large screens and foldables) |
| Localization: the ARB files and the generated localizations, the pseudo-locale generator, the strings check, the joins and title-case helpers | `app/lib/l10n/`, `app/lib/core/l10n/`, `tools/pseudo_locale.dart`, `tools/check_strings.dart` | `docs/reference/app-core.md` (Localization) |
| Conflicts: the device-local table, the store, "Keep this device's value" and the Conflicts screen | `app/lib/features/conflicts/` | `docs/reference/sync-app.md` |
| Backup: the `FTBK` archive and its cipher, the canonical dump and tolerant import, the restore offer and flow, the restart | `app/lib/features/backup/`, `app/lib/core/platform/backup_picker.dart`, `app/lib/bootstrap.dart` | `docs/reference/backup.md` |
| The local wipe, account deletion, erasing this device, the devices list and the remote sign-out notice | `app/lib/core/db/local_wipe.dart`, `app/lib/features/auth/` | `docs/reference/auth.md`, `docs/reference/data.md` |
| Linked banks: Items, Plaid Link, repair, unlink, the Plaid pull and the arrival seam | `app/lib/features/items/`, `app/lib/core/plaid/` | `docs/reference/items.md` |
| Rules: the engine, the runner on arrival and on demand, the rules screens | `app/lib/features/rules/` | `docs/reference/rules.md` |
| Developer menu (dev flavor only): the Sandbox controls, provisioning, diagnostics | `app/lib/features/developer/` | `docs/reference/developer.md` |
| Budgets: periods, spending, rollover, projection, alerts, the Budgets segment of the Plan tab | `app/lib/features/budgets/`, `app/lib/core/platform/notifier.dart` | `docs/reference/budgets.md` |
| Duplicates: the detector, dismissed pairs, the review | `app/lib/features/duplicates/` | `docs/reference/duplicates.md` |
| Transactions: hidden, bulk edit, search and saved filters, splits, receipts | `app/lib/features/transactions/`, `app/lib/core/db/full_text_search.dart`, `app/lib/core/db/receipt_store.dart`, `app/lib/core/platform/image_source.dart` | `docs/reference/transactions.md`, `docs/reference/data.md` |
| Recurring: the pull of Plaid streams, the detector and its harness, subscriptions, the merge, the user's overrides, the Subscriptions screen | `app/lib/features/recurring/` | `docs/reference/recurring.md` |
| Liabilities: the pull and the repository | `app/lib/features/liabilities/` | `docs/reference/liabilities.md` |
| Investments: holdings, securities and investment transactions, the pull and the repositories, allocation and gains, the Investments segment | `app/lib/features/investments/` | `docs/reference/investments.md` |
| Net worth: the daily balance snapshots and their writer, the series and its reconstruction, payoff projections, the Net worth segment | `app/lib/features/net_worth/` | `docs/reference/net-worth.md` |
| Reports: transaction classification, periods, comparisons, movers, anomaly flags and their harness, the weekly summary, the Reports segment | `app/lib/features/reports/` | `docs/reference/reports.md` |
| Goals: the goal and contribution entities and their sync records, progress and suggestions, the Goals segment and its editors | `app/lib/features/goals/` | `docs/reference/goals.md` |
| Export: the PDF monthly report, the CSV, the `FileExporter` boundary, the export screen | `app/lib/features/export/`, `app/lib/core/platform/file_exporter.dart` | `docs/reference/export.md` |
| Lock: the app lock, its gate above the router, the Security settings, the screen-security and monotonic-clock seams | `app/lib/features/lock/`, `app/lib/core/platform/screen_security.dart`, `app/lib/core/platform/monotonic_clock.dart` | `docs/reference/lock.md` |
| Bills: schedule, status and the payment assignment, reminders behind the scheduler boundary, the list, calendar and editor | `app/lib/features/bills/`, `app/lib/core/platform/reminder_scheduler.dart`, `app/lib/core/time/` | `docs/reference/bills.md` |
| Forecast: the projection, its band and allowance, the screen and table | `app/lib/features/forecast/` | `docs/reference/forecast.md` |
| The Plan tab: the shell, `PlanScaffold`, the editors' `OwnPage` closer | `app/lib/core/router/` | `docs/reference/app-core.md` |
| The Insights tab: the shell, `InsightsScaffold`, the fifth destination | `app/lib/core/router/` | `docs/reference/app-core.md` |
| Export: the monthly report's PDF, the transactions' CSV, the file exporter | `app/lib/features/export/`, `app/lib/core/platform/file_exporter.dart` | `docs/reference/export.md` |
| API client, in-app fake server, session and auth | `app/lib/core/api/`, `app/lib/features/auth/` | `docs/reference/app-core.md` (the API client), `docs/reference/auth.md` |
| The generated API client | `packages/api_client/` | `docs/reference/api.md` (Phase 2) |
| The API contract | `api/openapi.yaml` | same |
| Development server: auth, sync, the Plaid client (fake or Sandbox), the poll, webhooks, provisioning, receipt blobs | `server/` | `docs/reference/server.md` |
| Persona engine: demo seed, Sandbox custom users and their manifest | `tools/persona_engine/` (Phase 2) | `docs/reference/persona.md` |
| Build: workspace, flavors, Android configuration, signing, R8 | `pubspec.yaml`, `app/android/`, `app/lib/core/config/` | `docs/reference/build.md` |
| Testing and tools: gate, test runner, emulator harness, landing, the secrets sweep, scripts | `*/test/`, `app/integration_test/`, `tools/` | `docs/reference/testing-tools.md` |

## Architecture rules

These keep the engine testable without a device, the data honest, and the app one iOS folder
away from a second platform. Treat them as hard rules.

### Money and time

- **`Money` is an integer of minor units plus an ISO currency code**, with its own arithmetic,
  allocation and formatting. No `double` touches an amount, a balance or a budget, in the app,
  the database, the API or the server.
- **Balances are derived, never stored as truth.** A displayed balance is computed from entries
  or reported by the institution; the two are labelled differently.
- **Dates are dates.** Transactions carry ISO dates; periods and "today" are computed in the
  device's zone with `timezone`; reminders are local wall-clock times rescheduled across DST;
  audit fields are UTC instants (`PLAN.md` §6.8).

### Layers and data

- **Feature-first, layered**: `presentation → application → domain ← data`. `domain` imports no
  Flutter. Screens never query the database; **repositories expose streams**, and every
  repository has three implementations (Drift, in-memory, demo seed) that pass one contract test
  suite.
- **The local database is the source of truth.** Network updates the store; the UI reacts.
- **One API contract.** `api/openapi.yaml` is implemented by the in-app fakes, the dev server
  and any future backend; contract tests enforce it; the generated client is committed and the
  gate checks it is current.
- **Plaid is never called from the app.** The server holds the keys; the app sees our API shape.
- **Synthesized data never masquerades as bank data** (`PLAN.md` §7.1). Synthesis lives upstream
  (the persona engine feeding Sandbox), downstream (labelled derivation) or in the demo flavor.
  Every transaction and snapshot carries `source`: `plaid`, `manual`, `import`, `derived` or
  `demo`, and the UI labels `derived` values. The dev and release pipelines never fabricate a
  Plaid-shaped record.
- **Sync** is a pure Dart engine: Plaid data server-authoritative, user data bidirectional
  through the change log with hybrid logical clocks, last-writer-wins per field, tombstones win
  over edits.
- **Generated files are committed** (`*.g.dart`, `*.freezed.dart`, the API client) and
  regenerated in the same series as the change that invalidates them.

### Security and platform

- **No secret in the APK, in logs or in a test fixture.** Tokens in secure storage; the database
  key in the Keystore; `allowBackup="false"`; release builds obfuscated with split debug info;
  release builds refuse plain HTTP.
- **One user per install.**
- **Platform-specific code stays behind interfaces**: widgets, background work, biometrics,
  notifications, so an iOS folder is a build matter, not a refactor.
- **Three entry points** (`main_dev.dart`, `main_demo.dart`, `main_prod.dart`) and matching
  flavors (`dev`, `demo`, `prod`); a feature that only works in one of them is a bug.
- **Accessibility is not optional**: every chart has a tabular equivalent, every control a
  semantics label, every layout survives font scaling.

## Folder layout

Phase 0 produced this layout; the folders a later phase adds arrive with that phase.

```
app/             the Flutter application: lib/core, lib/features/<feature>/{presentation,
                 application,domain,data}, lib/main_{dev,demo,prod}.dart, android/,
                 test/, integration_test/
server/          the Dart development server: bin/, lib/, test/, .env.example (.env gitignored)
packages/        shared_models, api_client (generated), contract_test, sync_engine
api/             openapi.yaml, the contract
tools/           gates.sh, run_tests.sh, land_series.sh, gen_api_client.sh,
                 check_contract.sh, check_commits.sh, emulator_tests.sh, with_ceiling.sh,
                 persona_engine/, scripts/
docs/            reference/ (one file per area, written as it lands)
notes/           gitignored: plaid-sandbox.env and private notes
.claude/agents/  scout, researcher, developer, reviewer
.github/         workflows (Phase 0)
PLAN.md          the plan: gitignored, read from the main tree
```

## Dart and Flutter gotchas for this project

- `jsonDecode` gives `num`; an amount from JSON is converted to `Money` at the boundary, never
  carried as `num` or `double` into the domain.
- A `BuildContext` used after an `await` is a bug; check `mounted` or restructure.
- Riverpod: providers are generated (`@riverpod`); a provider that holds a stream subscription
  disposes it; `ref.watch` in build, `ref.read` in callbacks, never the reverse.
- Drift: a schema change bumps `schemaVersion` with a migration step and a test that opens the
  previous version's database; generated files are regenerated and committed. Drift runs
  `onUpgrade` outside a transaction and writes `user_version` only after `beforeOpen`, so every
  step must be re-runnable at the old version (`IF NOT EXISTS`, a column or index added only
  when missing) and the "every step runs again at the old version" test group must cover it;
  a step that cannot run twice bricks the database when the app is killed mid-upgrade.
- The full-text objects are not in the Drift schema: `core/db/full_text_search.dart` creates
  them at open (keyed by a `fts_definition` version in `app_meta`); a change to their SQL bumps
  `ftsDefinitionVersion`, and a bumped SQLite reruns `app/tool/generate_unicode61_table.dart`.
- freezed and json_serializable: the `part` directive must name the generated file exactly;
  forgetting `build_runner` is the most common reason a clone does not compile.
- `intl` formats currency; never string-concatenate a currency symbol.
- `timezone` needs its database initialized once at startup; a date computed before that is in
  UTC and wrong.
- Plaid: `/transactions/sync` returns `NOT_READY` with empty arrays on a fresh Item; that is
  "retry", not "no transactions". Page with `count` 500 and keep both the run-start cursor and
  the latest one. Injected Sandbox transactions come back with `LOW` category confidence; never
  assert Plaid's category on them (`PLAN.md` §4).
- Flutter flavors: the Android `productFlavors` and the `-t` entry point must agree; a mismatch
  runs the wrong configuration silently.
- `const` constructors wherever possible; a rebuild of a large transaction list that is not
  `const`-friendly shows up as dropped frames on a mid-range phone.
- A `NavigationDestination`'s tooltip is excluded from semantics: a count the user must hear goes
  in a `Semantics(label:)` around the icon, not in the tooltip.
- An editor that awaits a write before closing takes `OwnPage.of(context)` before the await and
  calls its `close()`: `context.pop()` after an await pops whatever page is on top at that moment.
- `flutter_local_notifications` schedules inexact alarms (`inexactAllowWhileIdle`) and needs
  core-library desugaring; a reminder is a wall clock built with `tz.TZDateTime(loc, y, m, d, h,
  min)`, a time in a DST gap moves later by the gap, an ambiguous time takes its first occurrence.
- The detector's precision and recall harness runs under the `detector_harness` tag in the gate;
  a change to the detector or to the persona engine's recurring expectations must keep every
  persona at or above 0.9 both ways. The anomaly harness runs under `anomaly_harness` (seeds 1
  and 2); a change to the flags or to the planted anomalies must keep recall at or above 0.8 and
  precision above the floor in `docs/reference/reports.md`.
- A detected stream's id hashes its stable anchor (`L` for any day of the month of 28 or more),
  currency and direction; the user's overrides and bill links are keyed by it.
- `app_meta` holds device-local state (`reminders_zone`, `reminders_scheduled_at`,
  `forecast_selection`, `bill_suggestions_dismissed`, `snapshots_written_on`, `dismissed_anomalies`,
  `weekly_summary_raised`, `payoff_entries`, `lock_enabled`, `lock_timeout_seconds`,
  `secure_screen`, `app_language`, `background_sync_enabled`, `background_last_run`,
  `session_ended_in_background`, `notification_permission_asked`, `sync_problems_told`) and never
  syncs; `app_settings` syncs.
- A pulled change-log entry whose `entity_type` this build does not know is held under its raw
  type name and released, at a schema step or at any later open, by a build that knows it; a pull
  never fails on an unknown type (`docs/reference/sync-app.md`, Unknown types). The first build
  that holds them is v0.7.0, so every device moves to it together; a new entity type is additive
  from then on.
- `Decimal` (shared_models) is for quantities and prices only: exact and comparable, with no
  arithmetic against `Money`.
- The PDF report's bytes are a golden: `pdf` with no metadata, `compress: false` and the `/ID`
  fixed, so the file is identical on every device; a layout or string change moves the pinned
  hash, and the golden is regenerated on purpose.
- A backup is logical NDJSON under `FTBK` v1 (Argon2id, HKDF, XChaCha20-Poly1305 over 64 KiB frames
  with the header as authenticated data): the engine is SQLite3 Multiple Ciphers, not SQLCipher, so
  there is no `sqlcipher_export`; every instant in it is a UTC ISO string, nullable columns
  included; a restore ends in `substituteNode(provisionalNodeId())` because both relays reject
  entries naming a foreign device, and the restore offer holds sync until answered. Every schema
  change keeps `dumpDatabase` working (a REAL or `dateTime()` column, or a table without a primary
  key, breaks it and a host test says so), and `conflicts` and the lock keys never travel.
- `startApp(config, overrides)` and `stopApp()`: a restore or a wipe stops the app, works on a plain
  screen and starts it again; `stopApp` awaits the close the database provider started
  (`databaseClosing`), or the files are still open when they are replaced or deleted.
- The local wipe runs legacy keys → files → receipts → database key → session → install marker →
  reminders, under a `wipe_pending_v1` record that `startApp` finishes before anything local opens;
  the marker goes last so a cut-short wipe never leaves one account's data for another.
- Lock: `local_auth` 3.0.2 needs `FlutterFragmentActivity`, an AppCompat DayNight launch theme and
  `USE_BIOMETRIC`; the timeout reads `SystemClock.elapsedRealtime()` through a channel (a Dart
  `Stopwatch` stops in deep sleep); `inactive` is not background; the app is covered at `hidden`
  and uncovered only by the clock decision; while locked the gate gives Android pages a
  non-predictive transition so a back gesture cannot pop the route under the lock screen.
- `Hlc.maxDrift` is one hour: a received clock further ahead is clamped, never thrown, and a local
  edit is stamped after what it edits (`sendAfter`); a merge that overwrites a field whose clocks
  lie within ten minutes with a different non-null value is recorded on the device whose edit lost
  (schema v13 `conflicts`, swept after thirty days); tombstones still win without a conflict.
- Receipts: `receipt_sha256` syncs and `receipt_path` is the device-local file; the outbox entry
  that names a receipt waits for `PUT /receipts/{sha256}` (a 400 or 413 lets it through), and the
  view fetches a missing or mismatching file on first view.
- `flutter test integration_test --flavor demo` overwrites `app-demo-debug.apk` with the
  integration-test app, which waits for its host forever when installed standalone; copy a
  standalone demo APK right after building it.
- `adb backup` includes a debuggable build's data on API 31+ whatever `allowBackup` says; the
  empty-archive check belongs to the release build. Device-to-device transfer ignores
  `allowBackup` for target 31+ too, so the `<device-transfer>` exclusion in
  `data_extraction_rules.xml` is what protects the data.
- The database opens with `busy_timeout` 5 s and WAL on every connection: a second connection (the
  background isolate) waits instead of failing, and Drift streams never see its writes, so the app
  marks every table updated on resume when `background_last_run` moved.
- The background isolate never syncs beside a live app: `ft.background` is a lock it takes before
  asking the app through `ft.app`, the app registers `ft.app` before `startApp` waits on a worker's
  cycle, and a holder that stops answering is removed; the auth interceptor re-reads the stored
  session before a refresh because the server rotates refresh tokens with reuse detection. A
  periodic work never runs before its schedule, forced or not (WorkManager reschedules it), and a
  process ended by `am kill` or `am force-stop` counts as force-stopped, so the next job start
  reschedules instead of running: end a test process with `run-as <package> kill -9 <pid>`.
- `cancelByTag('ft.sync')`, never the plugin's `cancelAll` (the Plaid SDK has WorkManager work of
  its own); a created notification channel's importance can never change, so a different behaviour
  needs a new id.
- `MainActivity` keeps `singleTop`; shortcut and widget launches reach go_router through the
  `LaunchIntent` seam fed by `onNewIntent`, and Kotlin renders a widget only from the snapshot the
  app wrote (money formatted in Dart, never in Kotlin).
- The shell's size class comes from its own `LayoutBuilder` width; sub-screens open through
  `openDetail`; the pane floors are 320 dp, 560 dp beside the extended rail and 240 dp per side on a
  fold.
- After adding strings run `dart run tools/pseudo_locale.dart` and `flutter gen-l10n`: the gate's
  `strings` step fails on a stale `app_en_XA.arb`, on a prose literal in presentation code or on an
  undescribed key; `initializeDateFormatting()` runs at startup, and a date formatted before it is
  wrong in a non-English locale.
- The harness: `FT_EMULATOR_RUN_TIMEOUT` (1800 s) ends a hung run with the screen's texts (emails
  redacted) and frees the lock; `FT_TEST_TIMEOUT` (1500 s, scaled with the load) bounds each package
  in the gate; `integration -- <file>` runs one file; `FT_EMULATOR_AVD=ft-fold
  FT_AVD_DEVICE=pixel_fold` and `posture folded|unfolded` for the foldable, `ft-tablet` with
  `pixel_tablet` for the tablet; booting one stops any other `ft-*` AVD.

## Seeing the app

The coordinator runs the dev flavor on its own emulator with the dev server on the main tree and
drives Sandbox (`/transactions/refresh`, `reset_login`, persona provisioning) from the developer
menu. Agents see the app only through widget and golden tests and the emulator harness in their
own clones: `tools/emulator_tests.sh` boots a dedicated headless AVD (`ft-lane`, created by the
harness, never the owner's `Pixel_*` images), installs the demo flavor or runs the integration
tests against the in-app fakes, and holds the machine-wide lock while it does.

## Agent workflow

Work on this repository is split across a coordinator and four project subagents
(`.claude/agents/`). The split is by judgment required, and by how much context each seat can
afford to hold.

- **Coordinator** (the top-level session) — talks to the owner, makes product and design
  decisions within `PLAN.md` or escalates them, writes briefs (each naming its **tier**, below),
  approves plans where a plan is required, routes work and review findings, reads the real diff
  of every tier A change and of every fold, and lands series. It owns everything that touches
  Plaid Sandbox, the dev server's real configuration and the owner's emulators. It does not read
  large files itself (the scout does), and does not write feature code in the main tree: trivial
  edits only, when spawning an agent would cost more than the edit.
- **`developer`** (Opus) — works in a clone of its own (**Lanes**), implements the brief, runs
  `tools/gates.sh` at every commit, verifies behaviour through the tests and the emulator harness
  in its clone, updates the docs the change invalidates, and delivers a patch series on the
  current `main` with the tree it reproduces. Never writes to the main working tree. Plans first
  only when the brief asks (tier A) or when it meets an open decision. **Continue the same agent
  from plan to implementation** (`SendMessage`); respawning loses what it learned planning.
- **`reviewer`** (Opus) — independent review of the series, applied in a clone of its own: the
  full pass for tier A, the targeted pass for tier B (**Tiers**). Report-only; it is given the
  code and the brief, never the developer's conclusions.
- **`scout`** / **`researcher`** (Sonnet) — read-only codebase lookups (including package API
  shapes from the pub cache and the Flutter SDK source) and outside research (Flutter, Dart,
  Riverpod, Drift, Android and Plaid documentation and issues). Neither runs Flutter or Dart.
  A load-bearing research fact (a Plaid behaviour, a package API, an Android constraint) is
  verified by Opus or the coordinator before a decision rests on it; a Plaid fact is verified
  against Sandbox by the coordinator.

**Tiers.** Every brief names its tier, which sets the plan and the review:

- **A** — the domain model and `Money`; the Drift schema and migrations; the sync engine; the
  API contract (`api/openapi.yaml`) and the generated client; server authentication, tokens,
  the Plaid proxy, webhook verification; encryption and key handling; the persona engine's
  determinism; the synthesis-policy boundary (anything that produces a `source` value); and any
  change to a fixture's or golden test's expected output. A plan before code, approved by the
  coordinator, who escalates product decisions to the owner; then the implementation; then the
  full review: migrations opened from old databases, sync simulated across devices, every gate,
  the emulator harness driven.
- **B** — feature UI, charts, widgets, notifications, the enrichment dictionary, persona
  content, rules and detectors within their frameworks, tooling and CI. No plan round trip: the
  brief carries the decisions and the developer stops only at an open decision. The targeted
  review, about thirty minutes: the diff read, the gate run, the changed behaviour driven once.
- **C** — docs, comments, config. No reviewer: the gate and the coordinator's own read.

Small later-scope items are **batched** by area, up to about five a slice, one commit each, one
brief and one review.

**Briefs.** A brief is the whole of what an agent knows about the task, so it carries:

- **Title and tier.**
- **Goal** — what changes for the user or the tooling, in two or three sentences, and what is
  explicitly out of scope.
- **Decisions made** — every choice the coordinator has already settled (names, screens, which
  feature folder, which table, which endpoint, which persona), so the developer never has to
  guess; for tier A, the plan is where remaining choices surface. Decisions cite `PLAN.md` §12
  by row where one applies.
- **Read** — `CLAUDE.md`, the `PLAN.md` sections for the phase, the reference files of the
  areas touched, and any module or doc the task depends on; the scout's findings when there are
  any, as `path:line`.
- **Verification** — the tests expected (unit, contract, widget, golden, sync simulation), and
  what the emulator run must show when the change is visible.
- **Lane** — the clone to use, whether the lane holds the emulator lock, and the base commit the
  series must be built on.
- **Delivery** — the plan format (tier A) or the report format, as the agent definition states.

**Lanes.** Every Flutter run writes files in the tree it runs in (`build/`, `.dart_tool/`), and a
run or install writes onto the attached device, so the main working tree is the coordinator's and
stays at `HEAD`: no agent writes to it or its index. A developer or a reviewer works in a `git
clone` of its own under `~/.claude-finance-tracker/scratch/finance-tracker/lanes/` (never the
session scratchpad under `/private/tmp`, which a reboot empties); the first `tools/gates.sh` run
fetches packages and generates code. Two developers may run at once on disjoint areas, under three
rules: only one **emulator** run happens on the machine at a time, which `tools/emulator_tests.sh`
enforces with a machine-wide lock and its own AVD, so a lane just runs it and waits (the gate, the
tests and the demo flavor on that AVD run any time the lock is held); the second lane rebases its
series onto `main` before delivery; a device run is wrapped in a ceiling (this Mac has no
`timeout`; a `perl` `alarm` that sends SIGTERM does) so a hang never holds the lock; a lane's docs
changes stay within its area's reference file, the map only where a status line changes. A lane
never runs the dev flavor, the dev server with real keys, or anything against Plaid Sandbox: those
are the coordinator's, and the keys are not in a clone. At most two or three lanes and reviews run
gates at once, and every agent waits on a gate or a harness run with one bounded loop under its
tool's timeout, leaving no polling shell behind (the agent definitions say so).

**Review routing.** The reviewer's findings go back to the **same** developer (`SendMessage`),
which folds them into the series; the coordinator reads the fold's diff; then the reviewer
re-reviews. A FAIL loops until it passes; PASS WITH FIXES is folded and read, re-reviewed when
the fold touched tier A ground. Anything the developer did outside the brief (**Adjacent
changes**) is kept or vetoed by the coordinator, not the reviewer.

**Delivery and landing.** A series is `git format-patch` files on the current `main`, one logical
change per commit (refactors separate from features), each a **Conventional Commit**:
`type(scope): Summary`, with `type` one of `feat`, `fix`, `refactor`, `perf`, `test`, `docs`,
`build`, `ci`, `chore`, `style`, `revert`; `scope` one of `app`, `server`, `models`, `api`,
`persona`, `sync`, `map`, a feature folder name, `tools`, `docs`, `ci`, `build`
(`tools/check_commits.sh` enforces this at the gate and at landing); the summary an imperative
sentence in sentence case, no trailing period, at most 72 characters; a body of plain paragraphs
saying what and why; **no trailers**: no commit in this repository carries one, the
coordinator's own included. The series comes with the write-tree hash it reproduces and the
gate's tail per commit. Once the review's findings are folded and the fold's diff read, the
coordinator lands it with `tools/land_series.sh <patch-dir> <base-commit> <tree-hash>` (clean
tree and HEAD at the base required; `git am`; the messages checked; the tree checked, with a
rollback on mismatch; the gate run; the commits left in place). The coordinator pushes `main` to
`origin` after each landing. A series that passes its review lands promptly; delivered patches
are never held back for a companion series. The owner reviews at phase gates and whenever they choose.

Constraints:

- **Decisions come from `PLAN.md`** (§12 decisions, §4 Plaid facts, §6 architecture, §7.1
  synthesis policy). An agent that finds an open decision stops and reports; it does not guess.
- **The architecture rules above are not negotiable**, and neither are: `Money` everywhere,
  derived balances, the date policy, the three-implementation repository rule, the contract,
  provenance on every record, no Plaid call from the app, no secret anywhere an agent can read
  it, generated files committed, Conventional Commits, no trailers.
- **Temporary instrumentation is tagged `[verify]`** and gone before a report:
  `grep -rn "\[verify\]" app server packages tools` returns nothing.

## Release notes

- Release builds: `--obfuscate --split-debug-info=<dir>`, the symbol files attached to the
  GitHub release; R8 keep rules for the Plaid SDK and SQLCipher; signing from environment, the
  key never in the repository.
- Every phase's definition of done includes a release-mode smoke run on an emulator, so an R8
  or obfuscation regression is caught the phase it appears.
- `CHANGELOG.md` is generated from the Conventional Commit log per release; tags are `vX.Y.Z`.
