# Testing and tools

The scripts under `tools/`, what each does, when it runs and what it writes. Every script
uses `fvm flutter` and `fvm dart` when `.fvmrc` exists and FVM is installed, and the bare
`flutter` and `dart` otherwise. None of them touches a device, the dev server or Plaid
Sandbox.

## `tools/gates.sh`: the gate

The definition of green. Run after every change, at every commit of a series, by
`tools/land_series.sh` after landing, and by CI on every push. For each workspace member
(`app`, `server`, `packages/*`, and `tools/persona_engine` once it exists), in order:

1. **layout**: `app`, `server`, `packages/shared_models` and `packages/api_client` each
   have a `pubspec.yaml`.
2. **format**: `dart format --output=none --set-exit-if-changed`.
3. **analyze**: `flutter pub get` and `flutter analyze` for Flutter packages; `dart pub get`
   and `dart analyze --fatal-infos` for pure Dart ones. In the workspace, a `pub get` in any
   member resolves the whole workspace at the root.
4. **codegen**: for a package that depends on `build_runner`, runs it and fails on any diff
   in the generated files.
5. **tests**: `flutter test` or `dart test` in every package with a `test/` directory; a
   package without one is skipped, and the gate fails if no package has tests.
6. **contract**: `tools/check_contract.sh` once it exists (Phase 2).

It prints one line per gate, the failing gate's output in full, and exits non-zero when
any gate fails. It writes `build/` and `.dart_tool/` in the tree it runs in, so an agent
runs it only in its own clone.

## `tools/run_tests.sh`: the test runner

`tools/run_tests.sh` runs every package's tests; `tools/run_tests.sh app` runs one package
(`app`, `server`, `packages/<name>`); `tools/run_tests.sh app "Money"` runs that package's
tests whose name contains the text. It writes the same build output as the gate.

## `tools/land_series.sh`: landing a series

`tools/land_series.sh <patch-dir> <base-commit> <tree-hash> [--dry-run]`, the coordinator's
landing step. It refuses a dirty tree, a HEAD other than the base on `main`, a subject that
is not a Conventional Commit of at most 72 characters, and any trailer; then applies the
`NNNN-*.patch` files with `git am`, checks the final tree against the reported hash (rolling
back to the base on a mismatch), and runs the gate, leaving the commits in place unpushed.
`--dry-run` stops after the tree check and resets to the base.

## The emulator harness (Phase 1)

`tools/emulator_tests.sh` arrives in Phase 1: it boots its own headless AVD and holds a
machine-wide lock while it runs, so only one emulator run happens on the machine at a time
and a second lane waits for the lock.
