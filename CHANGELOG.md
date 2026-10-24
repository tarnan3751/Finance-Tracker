# Changelog

Each release section is generated from the Conventional Commit log since the previous tag
(`PLAN.md` §10). Tags are `vX.Y.Z`; a phase ends with a `vX.Y.Z-phaseN` pre-release.

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
