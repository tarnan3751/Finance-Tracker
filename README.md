# Finance Tracker

A personal finance app for Android, built with Flutter. It links real bank accounts, syncs
transactions automatically, and turns them into budgets, bills, insights and net worth.
It is offline-first and encrypted at rest, and it has a demo mode that runs with no server
and no Plaid account, so anyone can install the APK and see it work. Bank data comes from
Plaid Sandbox through a development server in this repository; the app never talks to
Plaid directly.

## Status

Phase 4 is done: budgets per category (a parent budgets its group) with monthly periods from a
chosen start day, rollover of the signed remainder, progress, a linear projection and 80 % and
100 % alerts raised once per period into an in-app list behind a bell on the Budgets tab, the
math integer money throughout and property-tested across month ends, leap days and time zones.
Transactions can be hidden (kept in balances, left out of budgets, reports and the default
list), selected and edited in bulk through recorded batch writes, searched by word prefixes
across name, merchant, notes and tags through a full-text index, filtered by saved filters,
split across categories in the editor, and given a receipt photo from the camera or the gallery,
stored privately with its camera metadata stripped. A rule previews what it would change and
applies to the existing transactions once, atomically; a duplicate review pairs likely
duplicates by signed amount and date and lets the user hide one or dismiss the pair. The local
schema moved from v4 to v8 and every migration step is re-runnable, so a kill mid-upgrade
cannot leave a database that will not open. Phase 3's linked banks, Phase 2's sign-in, sync and
demo mode, and Phase 1's manual tracker are underneath. Recurring transactions and bills follow
in Phase 5.

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

The development server, for the dev flavor (auth, devices, sync, and the Plaid proxy: a fake
Plaid client by default, Sandbox with `PLAID_MODE=sandbox` and the keys in `server/.env`). The first run writes `server/.env` with random secrets and a seed user:

```sh
tools/run_server.sh               # listens on 127.0.0.1:8080; PLAID_MODE=fake unless .env says sandbox
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
