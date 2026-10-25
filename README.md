# Finance Tracker

A personal finance app for Android, written in Flutter. It links bank accounts, keeps their
transactions up to date, and turns them into budgets and a clear picture of where the money
goes. Data lives on the device in an encrypted database and syncs between a user's devices;
the app works offline and catches up later. Bank data comes from Plaid Sandbox through a
small development server in this repository, so the app itself never holds a Plaid key. A
demo flavor runs with no server and no account at all.

## Status

The app is usable for day-to-day tracking. It signs in, links banks and pulls their accounts
and transactions, shows the balance each institution reports, and syncs manual changes
between devices. Budgets follow a category for a monthly period with optional rollover,
show progress and a projection, and raise alerts at 80 % and 100 %. Transactions can be
searched by the first letters of any word, filtered and saved as named filters, hidden,
edited in bulk, split across categories, tagged automatically by rules, checked for
duplicates, and given a receipt photo. Recurring transactions, bills, reports and net worth
are not built yet.

## Layout

```
app/        the Flutter app: lib/core, lib/features/<feature>, one entry point per flavor
server/     the Dart development server: auth, sync and the Plaid proxy; never deployed
packages/   shared_models (app and server), api_client (generated from the contract)
api/        openapi.yaml, the contract the server, the in-app fakes and the client share
tools/      the gate, the test runner, the emulator harness, the landing script
docs/       reference/, one file per area
```

A few rules hold everywhere:

- Money is an integer number of minor units with a currency code. Nothing uses floating point.
- Each feature is layered: presentation, application, domain, data. The domain has no Flutter
  in it, and screens never query the database directly; repositories expose streams.
- The local database is the source of truth. The network updates it and the UI reacts.
- Every transaction records where it came from, and nothing synthesized is ever shown as
  bank data.

`CLAUDE.md` describes the conventions, the commands and where each area lives.
`docs/reference/` explains every area in detail; `build.md` there is the place to start.

## Running

The app has three flavors, each with its own entry point. Run them from `app/`:

```sh
cd app
# Demo: no server and no network. Seeded data, signed in against an in-process fake.
flutter run --flavor demo -t lib/main_demo.dart
# Dev: talks to the development server on the host (10.0.2.2 from an emulator).
flutter run --flavor dev -t lib/main_dev.dart
# Dev against a server elsewhere, for example from a phone on the same network:
flutter run --flavor dev -t lib/main_dev.dart --dart-define=FT_SERVER_URL=http://192.168.1.20:8080
```

From an emulator, `10.0.2.2` is the host machine. `localhost` on the device is the device
itself and reaches the host only after `adb reverse tcp:8080 tcp:8080`.

The dev flavor needs the development server. Its first run writes `server/.env` with random
secrets and a seed user; the Plaid client is a fake unless `PLAID_MODE=sandbox` and the
Sandbox keys are set in that file, which is never committed:

```sh
tools/run_server.sh               # listens on 127.0.0.1:8080
curl localhost:8080/v1/health     # {"status":"ok"}
```

## Building

```sh
cd app
flutter build apk --debug --flavor demo -t lib/main_demo.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart
flutter build apk --release --flavor prod -t lib/main_prod.dart \
  --obfuscate --split-debug-info=build/symbols
```

APKs land in `app/build/app/outputs/flutter-apk/`. A release build is signed with the key
named by `FT_RELEASE_KEYSTORE` and its companion variables, or with the debug key when they
are unset. `docs/reference/build.md` has the details.

## Tests

```sh
tools/gates.sh          # format, analysis, generated code, every test, the contract
tools/run_tests.sh      # every package's tests
tools/run_tests.sh app  # one package
```

The gate is what "green" means here: every change passes it locally, and CI runs the same
script on every push. The Flutter version is pinned in `.fvmrc`; the scripts use FVM when it
is installed and plain `flutter` otherwise.
