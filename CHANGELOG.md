# Changelog

Each release section is generated from the Conventional Commit log since the previous tag
(`PLAN.md` §10). Tags are `vX.Y.Z`; a phase ends with a `vX.Y.Z-phaseN` pre-release.

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
