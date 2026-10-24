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

**Phase 0 has landed; Phase 1 is in progress:** the app runs on its Riverpod and go_router
core with the settings feature; `packages/shared_models` holds the domain model; the emulator
harness exists; manual accounts and the encrypted database follow.
The repository is the pub workspace of **Folder layout**, Android only. The app runs in
three flavors (`dev`, `demo`, `prod`) through `app/lib/bootstrap.dart`; `server/` is a
skeleton answering `GET /v1/health`; `api/openapi.yaml` is the v1 contract, with
`packages/api_client` generated from it and `packages/contract_test` checking against it;
the Android build is Flutter 3.47's template with the package id, the flavors and the
release hardening; CI runs the gate, builds the APKs and proves the generated client
current. `PLAN.md` §4 is the Plaid architecture with the verified Sandbox facts, §7.1 the
data-coverage and synthesis policy, §8 the ten phases with sizes, §10 the process, §12 the
decisions.

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
| Regenerate code (Phase 1) | `cd app && dart run build_runner build --delete-conflicting-outputs` |
| Regenerate the API client after a contract change (Phase 2) | `tools/gen_api_client.sh` |
| Run the app, demo flavor (safe anywhere; no network) | `F run --flavor demo -t lib/main_demo.dart` |
| Run the app, dev flavor (the owner only: the owner's emulator and the dev server) | `F run --flavor dev -t lib/main_dev.dart` |
| The dev server (the owner only: reads the Plaid keys) (Phase 2) | `cd server && dart run bin/server.dart` |
| Emulator integration tests, one run on the machine at a time (Phase 1) | `tools/emulator_tests.sh` |
| Provision a persona into Sandbox (the owner only) (Phase 3) | `tools/scripts/provision_persona.sh <persona>` |
| Build a debug APK | `F build apk --debug --flavor dev -t lib/main_dev.dart` |
| Build the release APK (R8, obfuscated) | `F build apk --release --flavor prod -t lib/main_prod.dart --obfuscate --split-debug-info=build/symbols` |
| Land a delivered series | `tools/land_series.sh <patch-dir> <base-commit> <tree-hash>` |

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
| Sync engine (pure Dart, no Flutter) | `packages/sync_engine/` (Phase 2) | `docs/reference/sync.md` |
| The generated API client | `packages/api_client/` | `docs/reference/api.md` (Phase 2) |
| The API contract | `api/openapi.yaml` | same |
| Development server: auth, sync, Plaid proxy, webhook receiver | `server/` | `docs/reference/server.md` (Phase 2) |
| Persona engine: demo seed, Sandbox custom users, injection batches | `tools/persona_engine/` (Phase 2) | `docs/reference/persona.md` |
| Build: workspace, flavors, Android configuration, signing, R8 | `pubspec.yaml`, `app/android/`, `app/lib/core/config/` | `docs/reference/build.md` |
| Testing and tools: gate, test runner, emulator harness, landing, scripts | `*/test/`, `app/integration_test/`, `tools/` | `docs/reference/testing-tools.md` (Phase 0) |

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
                 check_contract.sh; emulator_tests.sh, persona_engine/, scripts/ as they land
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
  previous version's database; generated files are regenerated and committed.
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

**Lanes.** Every Flutter run writes files in the tree it runs in (`build/`, `.dart_tool/`), and
a run or install writes onto the attached device, so the main working tree is the coordinator's
and stays at `HEAD`: no agent writes to it or its index. A developer or a reviewer works in a
`git clone` of its own under its scratch directory; the first `tools/gates.sh` run fetches
packages and generates code. Two developers may run at once on disjoint areas, under three
rules: only one **emulator** run happens on the machine at a time, which `tools/emulator_tests.sh`
enforces with a machine-wide lock and its own AVD, so a lane just runs it and waits (the gate,
the tests and the demo flavor on that AVD run any time the lock is held); the second lane rebases
its series onto `main` before delivery; a lane's docs changes stay within its area's reference
file, the map only where a status line changes. A lane never runs the dev flavor, the dev server
with real keys, or anything against Plaid Sandbox: those are the coordinator's, and the keys are
not in a clone.

**Review routing.** The reviewer's findings go back to the **same** developer (`SendMessage`),
which folds them into the series; the coordinator reads the fold's diff; then the reviewer
re-reviews. A FAIL loops until it passes; PASS WITH FIXES is folded and read, re-reviewed when
the fold touched tier A ground. Anything the developer did outside the brief (**Adjacent
changes**) is kept or vetoed by the coordinator, not the reviewer.

**Delivery and landing.** A series is `git format-patch` files on the current `main`, one logical
change per commit (refactors separate from features), each a **Conventional Commit**:
`type(scope): Summary`, with `type` one of `feat`, `fix`, `refactor`, `perf`, `test`, `docs`,
`build`, `ci`, `chore`, `style`, `revert`; `scope` one of `app`, `server`, `models`, `api`,
`persona`, a feature folder name, `tools`, `docs`, `ci`, `build`; the summary an imperative
sentence in sentence case, no trailing period, at most 72 characters; a body of plain paragraphs
saying what and why; **no trailers**: no commit in this repository carries one, the
coordinator's own included. The series comes with the write-tree hash it reproduces and the
gate's tail per commit. Once the review's findings are folded and the fold's diff read, the
coordinator lands it with `tools/land_series.sh <patch-dir> <base-commit> <tree-hash>` (clean
tree and HEAD at the base required; `git am`; the messages checked; the tree checked, with a
rollback on mismatch; the gate run; the commits left in place). The coordinator pushes `main` to
`origin` after each landing. The owner reviews at phase gates and whenever they choose.

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
