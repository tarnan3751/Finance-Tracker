# Changelog

Each release section is generated from the Conventional Commit log since the previous tag
(`PLAN.md` §10). Tags are `vX.Y.Z`; a phase ends with a `vX.Y.Z-phaseN` pre-release.

## v0.6.0-phase5 — 2026-10-29

Phase 5 lands recurring streams, subscriptions, bills with reminders and a cash-flow forecast,
under a Plan tab that holds Budgets, Bills and Forecast. The app pulls Plaid's recurring streams
and liabilities (contract 0.4.0, with each stream's member transactions mapped to the server's
own ids), detects recurring streams in every transaction source with a measured detector
(precision and recall at or above 0.94 on every persona, run by the gate), merges the two with
the user's mutes, renames and reclassifications synced as a per-field record, and classifies
subscriptions with annual totals. Bills follow a schedule of any cadence, re-anchor on a
liability's due date, are matched to payments by one assignment across every bill, show as due,
paid or missed, and raise local reminders scheduled at the right wall-clock time across DST
through inexact alarms that survive a reboot. The forecast projects 30 and 90 days of balance
from streams, bills and an everyday-spending allowance with a confidence band from each stream's
price range, as integer money throughout, with a per-day table beside the chart. The local
schema moves from v8 to v10, every editor now closes only its own page after a save, and the
integration suite reports each file's duration.

### Features

- models: Add the liability entity (bea2d5b)
- api: Serve stream transaction ids and liability sources (f9f45f2)
- app: Add schema v9 with recurring streams and liabilities (b4e5329)
- recurring: Pull and store recurring streams with their overrides (17c4bd2)
- liabilities: Pull and store liabilities (24f9a00)
- app: Serve the persona's streams and liabilities in demo (7747f7e)
- recurring: Detect recurring streams from transactions (630a0d0)
- recurring: Classify subscriptions and merge streams (299296d)
- recurring: Recompute detected streams when transactions change (d04f3db)
- models: Extend the bill reminder entity (126e13a)
- bills: Compute occurrences, status and suggestions (82dd96d)
- app: Schedule reminders behind a platform boundary (82ed175)
- app: Add schema v10 with bills and bill alerts (6ba3d69)
- bills: Plan and reschedule reminders (da1bbfb)
- bills: Add the bill editor (2a36b7c)
- app: Make the third tab Plan with three segments (e60ca9c)
- recurring: Add the subscriptions screen (d036c77)
- bills: Add the bills list and calendar (2d5c5c0)
- tools: Print each integration test file's duration (6da4b25)
- forecast: Project cash flow with confidence bands (da68169)
- forecast: Provide the forecast from streams and balances (f15e59c)
- forecast: Add the forecast screen and its table (073b01e)
- forecast: Count bills and keep the account selection (3d6ce8f)
- app: Mount the forecast in the Plan tab (23a821e)

### Fixes

- app: Pop only the editor's own route after a save (54894b7)

### Tests

- app: Converge stream overrides across devices (63a391b)
- recurring: Measure the detector against the persona expectations (397b9ec)
- app: Converge bills across devices (787f4c7)
- app: Wait for the rule editor to close before navigating (109189a)
- app: Give the slow and the debounced tests room under load (dc59292)
- app: Wait for editors to close in the remaining integration flows (3c682f4)
- app: Show the demo forecast on a device (460e63a)

### Build and tooling

- app: Add local notifications with desugaring and the receivers (f4cc89e)
- app: Add fl_chart for the forecast chart (058f7cf)

### Documentation

- Describe recurring streams and liabilities (6bd440f)
- recurring: Describe the detector, subscriptions and merging (4fb2443)
- Describe bills, reminders and schema 10 (3addfc2)
- forecast: Describe the cash-flow forecast (7436cb0)

## v0.5.0-phase4 — 2026-10-25

Phase 4 lands budgets and rounds out working with transactions. Budgets have monthly periods
starting on a chosen day, rollover of the signed remainder, progress and a linear projection,
and 80 % and 100 % alerts raised once per period into an in-app list behind a bell on the new
Budgets tab; the budget math is integer `Money` throughout and is property-tested across month
ends, leap days and DST transitions in four zones. Transactions gain a `hidden` override that
keeps them in balances but out of budgets, reports and the default list; a selection mode with
bulk category, tag, hide and delete through recorded batch writes; a rule editor that previews
what a rule would change and applies it to history once, atomically; a duplicate review that
pairs likely duplicates by signed amount and date and lets the user hide one or dismiss the
pair; full-text search over name, merchant, notes and tags through an FTS5 index with prefix
matching and accent folding, plus saved filters; and splits edited in the editor with receipt
photos captured through the camera or gallery, stored privately with their metadata stripped.
The local schema moves from v4 to v8, every migration step is now re-runnable at the old
version (a kill mid-upgrade can no longer brick a database), and the contract gains
`Transaction.hidden` without a version change.

### Features

- server: Provision without injecting history (d56e57d)
- persona: Fit a persona's Sandbox history under the request budget (2780bf1)
- api: Describe provisioning and the injection window as they are (b1d4d37)
- models: Give a budget its start date (a5e1df4)
- app: Add schema v5 with budgets and their alerts (5531235)
- budgets: Compute periods, spending, rollover and projection (fe33369)
- budgets: Add the repositories and the sync record (d79fbb0)
- budgets: Raise budget alerts once per period through a notifier (61ccbc4)
- budgets: Add the budgets tab, editor and detail (3731704)
- budgets: Show budget alerts in the app (0b34a58)
- models: Add the hidden override to a transaction (4c824d9)
- app: Add schema v6 with the hidden column (9c867a7)
- transactions: Record batch writes through upsertAll (f29c8bc)
- rules: Support the hide action (1b79e77)
- transactions: Hide rows and edit them in bulk (3ec1c03)
- budgets: Leave hidden transactions out of a budget's spending (db1cebc)
- rules: Preview a rule's effect on existing transactions (bb8bcf8)
- rules: Apply a rule to existing transactions once (a5574e8)
- duplicates: Detect likely duplicate transactions (c5a6e68)
- app: Add schema v7 with dismissed duplicate pairs (47ec579)
- duplicates: Review duplicate candidates (78f0021)
- app: Add schema v8 with full-text search (5047c41)
- transactions: Search words and prefixes across four text fields (d15e58e)
- transactions: Save and reapply filters (ca4697e)
- transactions: Edit splits in the editor (9e8d9cb)
- app: Capture and show receipts behind an image source boundary (48c34d8)

### Fixes

- transactions: Keep the receipt goldens platform-independent (45932f6)
- transactions: Draw the receipt goldens' image without a codec (0e5052c)

### Refactoring

- app: Share the one-shot read of a repository stream (3d33c7a)
- rules: Share the owned-field guard with the runner (77f485c)

### Tests

- app: Converge budgets across devices (9bb0815)
- app: Converge hidden overrides and drive bulk edit on a device (1925de0)
- app: Converge rules applied to history (4c87800)
- app: Apply a rule to history on a device (6c673f4)
- app: Split and attach a receipt on a device (227e4fb)
- app: Wait up to 120 s of wall-clock time in the device flows (a6d5917)
- transactions: Match the trigger's refusal in the rollback test (83d3a82)

### Build and tooling

- tools: Recycle a wedged or long-lived harness emulator (59c0c46)
- tools: Uninstall the demo app before the harness's tests (db222ae)
- tools: Give each package's test duration in the gate summary (b8c7746)
- tools: Keep the landing gate's report and show its failure (ebc14a1)
- tools: Lint commit messages at the gate and at landing (6ca8ece)

### Documentation

- Describe the Sandbox history budget (eed0d25)
- Add the budgets reference file (f1c02c8)
- Describe the budgets screens and the alerts entry (2bd7cb8)
- Describe rules on history and the duplicate review (ab9835e)
- Describe full-text search and saved filters (3984422)
- Describe splits, receipts and the image source (eb146a6)

## v0.4.0-phase3 — 2026-10-25

Phase 3, Plaid Sandbox through the development server, completed: the contract at 0.3.0 with
Item refresh, balance refresh, unlink with the history kept or deleted, institution logos, the
Sandbox controls and a persona provisioning job; the server's real Plaid client (half-even
rounding of Sandbox's sub-cent amounts, institution metadata, the transactions sync loop with
`/accounts/get` so investment-only Items keep their accounts, balances stored in the app's
sign, a poll on a schedule, verified webhooks, a local-only live suite); the app's linked banks
(schema v3 with Items, Plaid Link through `plaid_flutter` behind a launcher boundary with a
fake for the demo and the tests, repair through update mode, unlink with Delete history, the
Plaid pull with its arrival seam, institution logos, a Room keep rule for the release build);
rules (schema v4, a deterministic engine run on arrival inside the pull's page transaction and
on demand from the editor, synced as user data, the rules screens, two demo rules per persona);
reported balances with the institution header and running balances anchored to them, the
merchant enrichment fallback with letter avatars; the developer menu for the dev flavor; the
persona engine's Sandbox custom users fixed for what Sandbox grants each institution; the
gate's failure report; and the CI goldens made font-independent. Accepted on the owner's
Pixel 6 emulator against real Sandbox: real Link with `user_good`, reset-login and repair,
rules on injected transactions, unlink both ways, and the obfuscated release build.

Known limitation, found during the acceptance and recorded in `PLAN.md` §4: Plaid Sandbox serves
transactions injected with `/sandbox/transactions/create` only when they are dated its current day, and
a custom user's configuration is capped at 100,000 bytes per request, so the provisioning job's history
phase delivers nothing beyond the custom user's own rows; the next change makes personas carry the
history that fits and drops that phase.


### Features

- api: Add Item refresh, balance refresh, unlink history and logos (95ac909)
- api: Add the Sandbox control operations (33203ed)
- server: Add the persona provisioning job (e8574ab)
- server: Round Plaid's sub-cent amounts at the boundary (92951b5)
- server: Add the HTTP Plaid client over recorded fixtures (d086e53)
- server: Select the Plaid mode from the configuration (9e3c491)
- server: Fetch and serve institution metadata (cc7fae4)
- server: Run the transactions sync loop against Plaid (5e7585b)
- server: Poll every Item on a schedule (41a6ed7)
- server: Verify and process Plaid webhooks (c8ece20)
- api: State the sign of a balance and fix the exchange description (8e8cb43)
- app: Add schema v3 with the items table (ac8e574)
- app: Keep bank data from being deleted on the device (3687112)
- app: Apply Plaid accounts and transactions without recording (ab1b28f)
- app: Pull Items, accounts and transactions from the server (041338f)
- app: Fetch the institution logos in the Plaid pull (e56011f)
- items: Add the Link launcher boundary and the fake launcher (e09d5a0)
- items: Add the linked banks screen with link, repair and unlink (91299c5)
- app: Offer the demo a bank to link (9e04b50)
- app: Add the rules table and the rule entity's sync codec (168c415)
- rules: Add the repositories and the engine (ffb90e3)
- rules: Apply rules on arrival and on demand (10b0844)
- rules: Add the rules screens (cec58fe)
- transactions: Add the merchant enrichment fallback and avatars (58f1b8c)
- accounts: Show reported balances and the institution (13fe2e5)
- items: Draw the linked banks' logos with the shared avatar (e19dbc0)
- developer: Add the developer menu for the dev flavor (ebe56b0)

### Fixes

- persona: Emit liability blocks only for cards and student loans (2a92ca4)
- persona: Move family 401(k) to Tartan, mortgage to Tattersall (d1f50d5)
- server: Retry a Plaid 5xx in the provisioning job (927a22f)
- server: List every account of an Item through /accounts/get (6baf9d7)
- server: Store credit and loan balances in the app's sign (88345b5)
- app: Defer the sync controller's device change off the build phase (a52afc4)
- tools: Keep a failing package's tests in the gate's report (3bbc6b3)
- tools: Keep the GitHub reporter's failures in the gate's report (7c6ddac)
- app: Format times with a no-break space the test fonts carry (064b816)
- server: Measure the injection window's past bound from the UTC date (6e7d6ab)
- developer: Cap injected dates at 728 days back (c7829e7)

### Build

- tools: Add the persona provisioning script (a1f44f2)

### CI

- Upload golden failure images (27eaa7f)

### Tests

- server: Add the optional live Sandbox suite (f6896e3)
- server: Add the live investment-only Item case (87d00ae)
- app: Let the two-device test run under the fake-server define (8b1382d)
- app: Link and unlink through the fake server on the emulator (aa32f05)
- app: Converge rules across devices (a0da629)
- app: Run rules through the screens on the emulator (7ab5a74)

### Documentation

- Describe contract 0.3.0, the Sandbox operations and provisioning (9b1a835)
- Describe the real Plaid client, the poll and webhooks (cb3664f)
- Note the live suite's investment-only Item case (3858310)
- models: State the balance sign and the merchant name's source (ca3e5eb)
- Describe the linked banks, the Plaid pull and schema 3 (7526612)
- Add the rules reference file (3e51140)
- Describe reported balances, merchants and the shared avatar (21b63e6)
- Describe the developer menu (7b2768b)
- Map the linked banks, rules and developer areas (72d4582)

## v0.3.0-phase2 — 2026-10-24

Phase 2, API contract, development server, fakes and demo mode, completed in the app: the API
client over the generated contract client (HTTPS rule, bearer and single-flight refresh,
typed problems, tokens in secure storage, one user per install), sign-in and registration
gating the shell in dev and prod, an in-process fake server implementing the whole contract
behind Dio and validated against it; schema v2 with the change log, field clocks, sync
metadata and held records, the Drift sync store, recording of user-authored changes with the
synthesis-policy filter, the sync controller and its Settings section, the HTTP relay; the
demo flavor on the persona engine's seed with opening-balance transactions, served by the
same fake; the effective category resolved from a transaction's Plaid code; a two-device
convergence suite and a two-instance integration test. Verified on two emulators against the
development server: register, sign out, sign in, refresh after expiry; manual data syncing
both ways with concurrent edits of different fields both kept, the later write winning a
same-field conflict, and a delete beating a concurrent edit; the demo running with the
network off.

### Features

- transactions: Resolve the category from the Plaid code (7fc36f6)
- transactions: Filter by the effective category (1c5fb7a)
- app: Add the API client, token store and problem mapping (60755a0)
- app: Add the in-app fake server (3283bcc)
- auth: Add the session controller and flavor wiring (a71703a)
- auth: Add sign-in and registration (7ed8528)
- app: Add schema v2 with the change log and field clocks (64da720)
- app: Add the Drift sync store (6833b5d)
- app: Record user-authored changes (5ee1e61)
- app: Run sync sessions and show their status (d30a3fd)
- app: Load the persona engine's demo seed (127d29f)
- app: Add the HTTP sync relay (f22fe80)
- app: Sync through the API while signed in (588de82)
- app: Serve the persona's household from the demo fake server (d596a1d)

### Fixes

- transactions: Show a transaction whose account is gone (8a3676f)

### Refactoring

- app: Share the row mapping of the Drift repositories (c228d3d)

### Tests

- app: Validate the fake server against the contract (4c013e6)
- app: Converge two devices through the relay (06cb238)
- app: Sync two app instances through the fake server (c67b927)

### Documentation

- Add the auth reference file and the API section (8da5140)
- Describe the app's sync wiring and schema 2 (d181445)
- map: Record Phases 1 and 2 and the new reference files (ba12258)

## v0.2.0-phase1 — 2026-10-24

Phase 1, domain and local data: `packages/shared_models` with `Money` (integer minor units,
never a double), `LocalDate`, the domain entities and Plaid's category taxonomy; the app core
(Riverpod, typed go_router shell, Material 3 with dynamic color, localization scaffolding,
widget, golden and accessibility test infrastructure, the settings feature); the encrypted
Drift database (SQLite3 Multiple Ciphers, key in the Keystore) with repositories in three
implementations under one contract suite and the importer of the original app's data; the
manual-account experience (accounts with derived balances, transactions with search and
filters, category management); the emulator harness. Also landed ahead of Phase 2's gate, on
disjoint paths: the API contract (0.2.1) with the generated client and contract tests, the
sync engine with its multi-device simulation, the persona engine, and the development server
with a fake Plaid client.

### Features

- models: Add the Money value type (56ead18)
- models: Add LocalDate and the UTC instant converter (221edf8)
- models: Add the domain entities (ec264e1)
- models: Add the Plaid category taxonomy (b956cc4)
- app: Add the Riverpod bootstrap, clock, logging and time zones (b139eb1)
- settings: Add the settings model, repository and controller (e506dee)
- app: Add the router, theme, shell and settings screen (516183f)
- api: Write the v1 contract (cb447bb)
- api: Add the contract test package (2d8053c)
- sync: Add the hybrid logical clock (fad0ba9)
- sync: Add field-level merge and the change diff (6d5c74f)
- sync: Add the store, relay and session (358f45f)
- persona: Add the seeded generator and household model (40c8b58)
- persona: Add the four personas (5263b9f)
- persona: Add the demo seed, Sandbox user and injection outputs (8131f52)
- app: Add Clock.today (025180c)
- app: Add the schema v1 and the encrypted database (ed1437e)
- app: Add repository interfaces, in-memory and demo implementations (fbda5fd)
- app: Add the Drift repositories (32e80b4)
- app: Import the original app's data on first launch (9e28faf)
- api: Amend the contract to 0.2.1 for the development server (146a5ec)
- server: Add configuration, storage and migrations (aa9debf)
- server: Add authentication, devices and the request pipeline (ce0db3f)
- server: Add the sync relay (d203afb)
- server: Add the Plaid proxy and data endpoints with a fake client (bae4fe8)
- server: Add account deletion end to end (99e24d6)
- app: Add account creation and transaction usage to repositories (db34898)
- app: Give each tab its own snack bar messenger (d2132e2)
- categories: Add category management (3067782)
- accounts: Add the accounts list, detail and editor (1ea08eb)
- transactions: Add the transactions list with search and filters (dcc03d0)
- transactions: Add the transaction editor with undoable delete (483adfb)
- app: Surface the legacy import (2bd2fdc)
- app: Draw the flavor banner as a strip above the app (a43f311)

### Fixes

- tools: Check the full subject of a folded patch header (944d0a5)

### Refactoring

- app: Remove the legacy one-file UI (9671ad2)
- settings: Move the settings repository interface to the domain (afbbadf)

### Build

- tools: Add the emulator harness (72f357e)
- app: Add the Phase 1 core dependencies (f5985f2)
- tools: Report riverpod_lint diagnostics in the gate (541243e)
- tools: Check generated localizations in the gate (95af066)
- tools: Generate the API client from the contract (1f17af3)
- tools: Add the contract check to the gate (2a1ccb4)
- app: Add Drift, SQLite3 Multiple Ciphers and secure storage (29d784e)
- tools: Check the schema dump in the gate (41923c2)
- tools: Add the server run script (124a486)

### CI

- Validate the contract and the generated client (d7cef48)

### Tests

- app: Add the demo launch integration test (395f413)
- app: Add the widget, golden and accessibility test helpers (578f093)
- sync: Add the multi-device simulation (7f4c24b)
- persona: Add balance, recurrence and determinism tests (3552d3c)
- server: Validate every route against the contract (60c531d)
- app: Add the Phase 1 goldens and flow tests (41df23c)

### Documentation

- Describe the emulator harness (3ac3692)
- Add the core reference file (bb60707)
- map: Give the API client its own row now that shared_models landed (dba8e78)
- Add the app core reference file (4711e0a)
- Name lane clones after their lane in the agent definitions (2510403)
- Add the API reference file (a209cb8)
- Add the sync reference file (56956e3)
- Add the persona reference file (4cdaf80)
- Add the data reference file (be96f9b)
- Add the server reference file (108b805)
- Add the accounts, transactions and categories reference files (abc22fa)

### Chores

- build: Ignore the Kotlin daemon session directory (4d449fb)


## v0.1.0-phase0 — 2026-10-24

Phase 0, restructure and foundations: the repository becomes a pub workspace with the Flutter
app in `app/`, a development-server skeleton, the shared package placeholders and the API
contract placeholder; the original one-file app runs unchanged in the `dev`, `demo` and `prod`
flavors on Flutter 3.47.8's Android template with the project's package id, release hardening
and R8; strict lints, a real smoke test, CI and the rewritten README. No feature changes.

### Features

- app: Add the flavor config, bootstrap and three entry points (c151da9)
- app: Add the dev, demo and prod Android flavors (54d9805)

### Refactoring

- Move the app into app/ and make the repository a workspace (124607a)

### Build

- tools: Add the gate, test runner and landing scripts (e940284)
- app: Enforce strict lints and fix the legacy findings (b2fd9be)
- app: Adopt the Flutter 3.47 Android template with the package id (c1d9e71)
- app: Harden the release build: backup, network, signing and R8 (b85f847)
- app: Replace the launcher PNGs with a placeholder adaptive icon (f274453)
- tools: Resolve packages before the format gate (af54634)

### CI

- Run the gate and build the demo and prod APKs on every push (ae61791)

### Tests

- app: Replace the commented-out widget test with a smoke test (e297e07)

### Documentation

- Add the project map and agent definitions (c8f641e)
- Rewrite the README and add the build and tools references (4069357)
- map: Record Phase 0 in the map (2cfe24c)

### Style

- app: Format the legacy code with dart format (f3e3e36)

### Chores

- Ignore server secrets, local state and release artifacts (fcf975b)
- build: Record the Flutter 3.47 migrator and pub get changes (fdf69c0)

### Other

- Add files via upload (e360f30)
- Update README.md (5253a6d)
- Delete .metadata (9ad98aa)
- Delete .gitignore (9eb5da8)
- Delete analysis_options.yaml (dce4a69)
- Delete flutter_finance_tracker.iml (e1a5749)
- Delete pubspec.lock (c7cf0f5)
- Delete pubspec.yaml (afcc4aa)
- Add files via upload (4142166)
- Update README.md (4397c76)
- Update README.md (c744e3a)
- Add files via upload (5ba332d)
- Update README.md (53ab250)
- Add files via upload (7566519)
- Add files via upload (f8cf5ca)
- Added necessary flutter files (7cdc1ae)
- Update README.md (e2716c1)
- Ignore private planning notes (d46a362)
