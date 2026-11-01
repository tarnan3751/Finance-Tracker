# Contributing

Thank you for looking. This file says what the project is, how to set it up, and what a
change needs before it can land.

## What this project is

Spendthrift is a personal finance app for Android, written in Flutter, with a Dart
development server that proxies Plaid Sandbox. The server is never deployed: it runs on your
own machine for development, and the app's demo flavor needs nothing at all, no server, no
account and no network. It is not a hosted service, it handles no real bank credentials, and
it targets Android only.

## Before you start

Open an issue first for anything beyond a small fix, and ask before starting a large pull
request: a change that does not fit the plan is easier to talk through before it is written.
Security problems go to [`SECURITY.md`](SECURITY.md), never to a public issue.

The project has one maintainer, who reviews every pull request personally, so expect a reply
within days rather than hours, and some back and forth before a change lands.

## Setup

- Install [FVM](https://fvm.app/); the Flutter version is pinned in `.fvmrc`, and every script
  uses `fvm flutter` when FVM is installed and plain `flutter` otherwise. An Android SDK with
  JDK 17 builds the app.
- The repository is one pub workspace (the root `pubspec.yaml`): `app/`, `server/` and the
  packages under `packages/` resolve together.
- Generated code is committed. After changing a Drift table, a freezed or json_serializable
  class or a Riverpod provider, run `dart run build_runner build` in `app/`; after changing
  `app/lib/l10n/app_en.arb`, run `dart run tools/pseudo_locale.dart` and `flutter gen-l10n`
  in `app/`; after changing `api/openapi.yaml`, run `tools/gen_api_client.sh`.
- `tools/gates.sh` is the gate: formatting, analysis, generated code up to date, every test,
  the contract, the strings check and the commit messages. Its first run fetches the packages
  and generates the code.
- `flutter run --flavor demo -t lib/main_demo.dart` in `app/` runs the app on seeded data;
  `README.md` says how to run the development server for the dev flavor.

## What a change needs

- **The gate passes.** `tools/gates.sh` is what "green" means here, and CI runs the same
  script on every push.
- **The conventions hold.** `CLAUDE.md` lists them: money is integer minor units with a
  currency code, never a floating-point number; each feature is layered, with a domain that
  imports no Flutter; every record says where it came from. `docs/reference/` explains each
  area; read the file for the area you change, and update it when your change makes a
  statement in it false.
- **User-facing text lives in the ARB.** The gate's strings check (`tools/check_strings.dart`)
  fails on a prose string literal in presentation code: add the text to
  `app/lib/l10n/app_en.arb` with an `@key` description and regenerate as above.
- **Commits are Conventional Commits**, checked by `tools/check_commits.sh`:
  `type(scope): Summary`, where the type is one of `feat`, `fix`, `refactor`, `perf`, `test`,
  `docs`, `build`, `ci`, `chore`, `style`, `revert`, and the scope is one of `app`, `server`,
  `models`, `api`, `persona`, `sync`, `map`, `tools`, `docs`, `ci`, `build` or a feature
  folder under `app/lib/features/`. The summary is an imperative sentence in sentence case
  with no trailing period, at most 72 characters; the body is plain paragraphs saying what
  changed and why. No trailers of any kind (`Signed-off-by:`, `Co-Authored-By:` and the
  like). One logical change per commit, with refactors apart from features.

## Licence

Contributions are made under the MIT licence in [`LICENSE`](LICENSE), the project's own.
Taking part also means following the [code of conduct](CODE_OF_CONDUCT.md).
