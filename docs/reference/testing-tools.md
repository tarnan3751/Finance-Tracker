# Testing and tools

The scripts under `tools/`, what each does, when it runs and what it writes. Every script
uses `fvm flutter` and `fvm dart` when `.fvmrc` exists and FVM is installed, and the bare
`flutter` and `dart` otherwise. None of them touches the dev server or Plaid Sandbox, and
only `tools/emulator_tests.sh` touches a device: the harness's own emulator, never another.

## `tools/gates.sh`: the gate

The definition of green. Run after every change, at every commit of a series, by
`tools/land_series.sh` after landing, and by CI on every push. For each workspace member
(`app`, `server`, `packages/*`, and `tools/persona_engine` once it exists), in order:

1. **layout**: `app`, `server`, `packages/shared_models` and `packages/api_client` each
   have a `pubspec.yaml`.
2. **resolve**: `dart pub get` at the root, so the package config is current before anything
   reads it. `dart format` takes each package's language version from the package config; a
   stale `.dart_tool/` left by an earlier layout made the format step fail at the Phase 0
   landing, which is why this step exists.
3. **format**: `dart format --output=none --set-exit-if-changed`.
4. **analyze**: `flutter pub get` and `flutter analyze` for Flutter packages; `dart pub get`
   and `dart analyze --fatal-infos` for pure Dart ones. In the workspace, a `pub get` in any
   member resolves the whole workspace at the root.
5. **codegen**: for a package that depends on `build_runner`, runs it and fails on any diff
   in the generated files.
6. **tests**: `flutter test` or `dart test` in every package with a `test/` directory; a
   package without one is skipped, and the gate fails if no package has tests.
7. **contract**: `tools/check_contract.sh` once it exists (Phase 2).

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

## `tools/emulator_tests.sh`: the emulator harness

Runs the app on the harness's own headless Android Virtual Device, `ft-lane`, under a
machine-wide lock, so only one emulator run happens on the machine at a time and a second
lane waits its turn. It runs from the repository root wherever it is called from: a relative
screenshot path is relative to the root, and `run` runs its command there. It talks to an
emulator only after `adb -s <serial> emu avd name` has answered `ft-lane`, so the owner's
`Pixel_*` and `Nexus_*` emulators and any physical device are never touched, and it fails
loudly otherwise.

| Command | What it does |
|---|---|
| `integration [-- <args>]` | The default. Boots `ft-lane`, then runs `flutter test integration_test --flavor demo -d <serial>` from `app/`, passing any extra arguments through; the tests run against the in-app fakes. |
| `demo [<screenshot>]` | Boots, builds the demo debug APK, installs it with `adb install -r`, launches the launcher activity of `dev.tarnan.financetracker.demo`, waits (up to 60 s) for it to take window focus plus a short settle for the first frame, and saves a screenshot, by default `app/build/emulator/demo.png`; prints the path. |
| `run <command...>` | Boots, then runs the command with `FT_EMULATOR_SERIAL` set to the emulator's serial: anything else against the AVD goes through this. |
| `stop` | Shuts down the `ft-lane` emulator and removes a stale lock. Refuses while a live run holds the lock. |
| `status` | Who holds the lock (pid, since when, command), and whether `ft-lane` is running and on which serial. |

**The lock.** `integration`, `demo` and `run` hold it for their whole run. It is the
directory `${TMPDIR:-/tmp}/finance-tracker-emulator.lock` holding the files `pid`, `started`
(UTC) and `command`. A run builds those in a private directory beside the lock and takes the
lock with one rename of that directory, which fails while a lock exists, so a lock is never
seen half-written (macOS has no `flock`). `TMPDIR` is per user on macOS, so every shell of
the owner's account sees the same lock; a caller that overrides `TMPDIR` would not. A waiter
polls every 5 s for up to `FT_EMULATOR_LOCK_TIMEOUT` seconds (default 1800), printing the
holder every 60 s. A lock is stale when its pid is dead, or when it has no `pid` file and is
older than 30 s (only a crash of an earlier version of the script leaves one); a waiter
reclaims it by renaming it away and removing it, so of several waiters only one wins. A trap
releases the lock on exit, failure or signal, but leaves the emulator running so the next
run reuses it; `stop` shuts it down. The long steps (`flutter`, `sdkmanager`, the `run`
command) run as a background child the script waits on, so `SIGTERM` or `SIGINT` takes
effect at once: the trap stops the child and its descendants (TERM, then KILL after 10 s),
releases the lock and exits 143 or 130, and no orphan is left driving the emulator. A run
killed with `SIGKILL` leaves its lock and its child behind, and the next run reclaims the
lock.

**The AVD.** Created on first use with `avdmanager create avd -n ft-lane -k <image> -d
pixel_6`, from `FT_AVD_IMAGE` (default `system-images;android-36;google_apis;arm64-v8a`,
installed with `sdkmanager --install`, licences accepted, when missing), then given
`hw.keyboard=yes`, `disk.dataPartition.size=2G`, `hw.lcd.density=420` and the SwiftShader
GPU in its `config.ini`, replacing the values `avdmanager` wrote. The API 36 emulator raises
the data partition to 6 GB on first boot whatever the file says; the image is sparse, so it
takes far less on disk. It boots with `-no-window -no-audio -no-boot-anim -no-snapshot -gpu
swiftshader_indirect` on the first free even port from 5554 to 5584, so an emulator the
owner already has on 5554 is left alone; the boot waits up to 240 s for `sys.boot_completed`
and the package manager, then turns the window, transition and animator animations off. A
run that finds `ft-lane` already running waits the same way before using it, since an
interrupted run can leave it offline or still booting. The SDK comes from `ANDROID_HOME`,
else `ANDROID_SDK_ROOT`, else `~/Library/Android/sdk`; a missing `adb`, `emulator`,
`avdmanager` or `sdkmanager` fails with the fix.

**What it writes.** The AVD in `~/.android/avd/ft-lane.avd` (and its `.ini`), the system
image under the SDK on first use, the lock directory (with its short-lived `.new.*` and
`.stale.*` siblings), and `app/build/`: the APKs, the emulator, `sdkmanager` and
`avdmanager` logs and the screenshot under `app/build/emulator/`. Installs go onto `ft-lane`
only.

**Integration tests** live in `app/integration_test/` and use
`IntegrationTestWidgetsFlutterBinding`; the `--flavor demo` build supplies the demo
application, and each test file's `main` is the entry point, so no `-t` is given.
`app_launch_test.dart` starts the app through `bootstrap(AppConfig.demo())`, as
`main_demo.dart` does, and checks that a `MaterialApp` titled with the demo app name is up.
CI does not run them yet.
