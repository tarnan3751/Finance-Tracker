# Finance Tracker

A personal finance app for Android, built with Flutter. It links real bank accounts, syncs
transactions automatically, and turns them into budgets, bills, insights and net worth.
It is offline-first and encrypted at rest, and it has a demo mode that runs with no server
and no Plaid account, so anyone can install the APK and see it work. Bank data comes from
Plaid Sandbox through a development server in this repository; the app never talks to
Plaid directly.

## Status

Phase 2 is done: the app signs in against the development server, syncs user data
between devices (schema v2 with a change log and field clocks, a pure Dart sync engine with
per-field last-writer-wins and tombstones), runs the demo flavor on the persona engine's seed
against an in-process fake server with no network, and validates that fake and the server
against the one OpenAPI contract. Phase 1's manual-account tracker (encrypted local
database, accounts with derived balances, transactions with search and filters, categories
seeded from Plaid's taxonomy) is underneath; a transaction without a category of your own
shows the one its Plaid code maps to. Bank data through Plaid Sandbox follows in Phase 3.

## Architecture

```
app/        the Flutter app (Android only): lib/core, lib/features/<feature>, three entry points
server/     the Dart development server (shelf): auth, sync, the Plaid proxy; never deployed
packages/   shared_models (shared by app and server), api_client (generated from the contract)
api/        openapi.yaml, the one API contract the server, the fakes and the client implement
tools/      the gate, the test runner, the landing script
docs/       reference/, one file per area
```

- Money is integer minor units plus a currency code, never a floating-point number.
- Feature-first layers: presentation, application, domain, data; the domain has no Flutter.
- The local database is the source of truth; repositories expose streams to the UI.
- Plaid keys live only on the server; every record carries its source, and synthesized data
  is never presented as bank data.
- The original one-file UI was replaced in Phase 1; its stored data is what the legacy
  importer reads.

`CLAUDE.md` is the map of the project: the conventions, the commands and where every area
lives. `docs/reference/` explains each area in detail, starting with `build.md`.

## Running

The app has three flavors, each with its own entry point. Run them from `app/`:

```sh
cd app
# Demo: no server and no network; the persona engine's seed, signed in against an in-process fake.
flutter run --flavor demo -t lib/main_demo.dart
# Dev: talks to the development server at http://10.0.2.2:8080 (the host, from the emulator).
flutter run --flavor dev -t lib/main_dev.dart
# Point dev at a server on another machine, e.g. from a physical device on the LAN:
flutter run --flavor dev -t lib/main_dev.dart --dart-define=FT_SERVER_URL=http://192.168.1.20:8080
```

On an emulator the host machine is `10.0.2.2`; `localhost` on the device is the device
itself, and reaches the host only after `adb reverse tcp:8080 tcp:8080`.

The development server, for the dev flavor (auth, devices, sync, and a fake Plaid client
until Phase 3). The first run writes `server/.env` with random secrets and a seed user:

```sh
tools/run_server.sh               # listens on 127.0.0.1:8080; PLAID_MODE=fake
curl localhost:8080/v1/health     # {"status":"ok"}
```

From Phase 2 the server reads its configuration from `server/.env` (copy `.env.example`);
that file holds the Plaid Sandbox keys and is never committed.

## Building

```sh
cd app
flutter build apk --debug --flavor demo -t lib/main_demo.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart
flutter build apk --release --flavor prod -t lib/main_prod.dart \
  --obfuscate --split-debug-info=build/symbols
```

APKs land in `app/build/app/outputs/flutter-apk/`. A release build is signed with the key
named by `FT_RELEASE_KEYSTORE` and its companion variables, or with the debug key when that
is unset; `docs/reference/build.md` has the details.

## Tests and the gate

```sh
tools/gates.sh          # format, analyze, generated code, every test, the contract
tools/run_tests.sh      # every package's tests
tools/run_tests.sh app  # one package
```

The gate is the definition of green: every change passes it, and CI runs the same script on
every push. The Flutter version is pinned in `.fvmrc`; the tools use FVM when it is
installed and the bare `flutter` otherwise.

## Credits

Finance Tracker began as a one-file Flutter app by its author,
[tarnan3751](https://github.com/tarnan3751): a manual list of incomes and expenses with a
running total, their first personal project in Dart. That app is the seed of this one; its
stored data is what the Phase 1 importer reads, and its history remains in this repository.
