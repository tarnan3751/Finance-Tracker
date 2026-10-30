# Testing and tools

The scripts under `tools/`, what each does, when it runs and what it writes. Every script
uses `fvm flutter` and `fvm dart` when `.fvmrc` exists and FVM is installed, and the bare
`flutter` and `dart` otherwise. None of them touches Plaid Sandbox, only
`tools/run_server.sh` starts the dev server, and only `tools/emulator_tests.sh` touches a
device: the harness's own emulator, never another.

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
4. **analyze**: `flutter pub get`, `flutter analyze` and then `dart analyze --fatal-infos`
   for Flutter packages, because `flutter analyze` does not report analyzer-plugin
   diagnostics (riverpod_lint's, declared in the root `analysis_options.yaml`) and
   `dart analyze` does; `dart pub get` and `dart analyze --fatal-infos` for pure Dart ones.
   In the workspace, a `pub get` in any member resolves the whole workspace at the root.
5. **codegen**: for a Flutter package with an `l10n.yaml`, runs `flutter gen-l10n`; for a
   package that depends on `build_runner`, runs it; for a package with a `drift_schemas/`
   directory, dumps the schema of its one `@DriftDatabase` file into it and regenerates the
   migration test's helpers in `test/drift/generated/` (`data.md`, **Changing the
   schema**); then fails on any diff in the package and on any untracked file in it
   (`git status --porcelain`), so stale or newly generated localizations, `*.g.dart` or
   `*.freezed.dart` files, schema dumps or helpers that are not committed fail the gate.
6. **tests**: `flutter test` or `dart test` in every package with a `test/` directory; a
   package without one is skipped, and the gate fails if no package has tests. The
   summary line gives each package's duration in seconds, then the ceiling and the load
   (`gate tests ok (<n> package(s): app <s>s, server <s>s, ...) (ceiling <n>s at load
   <l>)`), so a timeout under load can be put down to the package that ran long (the
   convergence random run and the exhaustive tokenizer test are the slow ones). Each
   package's run has a ceiling (through `tools/with_ceiling.sh`, below), so a hung test
   cannot hold a lane for hours (a gate sat idle for 9 h 37 min on 2026-10-30): by default
   1500 s scaled by the one-minute load read at the gate's start, 1500 × max(1, min(2,
   load / 6)), so 1500 s up to a load of 6 and 3000 s from 12 on (the load is 0 when it
   cannot be read); an explicit `FT_TEST_TIMEOUT` (whole seconds) is used as given, and
   the line then reads `(ceiling <n>s from FT_TEST_TIMEOUT at load <l>)`. Past it, the
   package's test processes are killed, the step fails with `== <package> FAILED: timed out after <n>s`
   and the last 40 lines of its output, the summary line marks the package `(timed out)`,
   and the gate goes on to the next step.
7. **contract**: `tools/check_contract.sh` (below): the contract's structural check and
   the generated client's source hash.
8. **strings**: `dart run tools/check_strings.dart` (below): the strings check; its line
   gives each translated locale's untranslated count.
9. **commits**: `tools/check_commits.sh origin/main` (below), the commit-message lint, on
   the commits beyond `origin/main`, so a lane meets a bad message at its own gate. It is
   skipped on a detached `HEAD` (CI's pull-request checkout), when there is no
   `origin/main` (CI's branch checkout fetches only its own branch) or outside a git
   checkout, and passes with nothing to check when `HEAD` is `origin/main`.

It prints one line per gate, the failing gate's output in full, and exits non-zero when
any gate fails. It writes `build/` and `.dart_tool/` in the tree it runs in, so an agent
runs it only in its own clone.

## `tools/run_tests.sh`: the test runner

`tools/run_tests.sh` runs every package's tests; `tools/run_tests.sh app` runs one package
(`app`, `server`, `packages/<name>`); `tools/run_tests.sh app "Money"` runs that package's
tests whose name contains the text. It writes the same build output as the gate. Each
package runs under the gate's ceiling, computed the same way from the load at its start (or
`FT_TEST_TIMEOUT`) and printed first (`run_tests: ceiling <n>s at load <l>`); past it, its
test processes are killed and the runner says which package timed out (its output is
already above) and fails.

## `tools/with_ceiling.sh`: a run with a ceiling

`tools/with_ceiling.sh <seconds> <command...>` is `timeout(1)`, which macOS lacks. It runs
the command directly (never through a shell, even as one argument) in a process group of its
own, with standard input from `/dev/null`, and when the command is still running after
`<seconds>` it sends the whole group TERM, then KILL once the command has exited or 10 s have
passed, so no `flutter_tester` or other descendant is left behind, and exits 124. INT, TERM
and HUP sent to it stop the group the same way and exit 130, 143 or 129; its handlers are in
place before it forks, so a signal at any moment stops the group. A command that cannot be
run exits 127; otherwise it returns the command's own status. The gate and the test runner
use it for each package's tests, and refuse an `FT_TEST_TIMEOUT` that is not a whole number
of seconds (exit 2); it writes nothing.

## Test tags and seeds

Tags mark the measured and randomized suites so they can run alone; the gate runs every
one of them. They are declared in each package's `dart_test.yaml`.

| Tag | Package | What it marks |
|---|---|---|
| `golden` | `app` | the golden tests |
| `detector_harness` | `app` | the recurring detector measured against the persona engine |
| `anomaly_harness` | `app` | the anomaly flags measured against the persona engine |
| `chaos` | `packages/sync_engine` | the chaos simulation (`sync.md`, **Testing**) |

The sync engine's seeded suites take their seed and size from the environment, so a
failure replays exactly:

| Variable | Suite | Default |
|---|---|---|
| `SYNC_ENGINE_SEED` | the clock and merge property tests | 20261024 |
| `SYNC_SIM_SEED`, `SYNC_SIM_SCENARIOS` | the simulation | 20261024, 4000 |
| `SYNC_SIM_SCENARIO` | the simulation: the one scenario a failure names, with its trace | |
| `SYNC_CHAOS_SEED`, `SYNC_CHAOS_SCENARIOS` | the chaos simulation | 20261030, 400 |
| `SYNC_CHAOS_SCENARIO` | the chaos simulation: the one scenario a failure names, with its steps and trace | |

A chaos failure also prints the smallest failing step list its shrinker found.

## `tools/gen_api_client.sh`: the generated API client

`tools/gen_api_client.sh` regenerates `packages/api_client` from `api/openapi.yaml` with
openapi-generator 7.26.x (`dart-dio`, `built_value`), runs `dart pub get` at the root (which
can update `pubspec.lock` when the package's dependencies changed), runs `build_runner` and
`dart format` in the package, and writes the contract's SHA-256 to
`packages/api_client/.openapi-source.sha256`. It needs the `openapi-generator` command
(`brew install openapi-generator`) or `OPENAPI_GENERATOR` naming another, such as
`java -jar openapi-generator-cli-7.26.0.jar`, and refuses any other generator version.
`--check` generates into a temporary directory and diffs it against the committed client,
ignoring our own files and `*.g.dart` (whose freshness is the gate's codegen step); CI runs
it. Run it after every change to the contract and commit the result
(`docs/reference/api.md`). It writes `packages/api_client` and possibly `pubspec.lock`, or
with `--check` only a temporary directory.

## `tools/check_contract.sh`: the contract step

The gate's contract step, pure Dart, no Java. It runs `dart run
contract_test:check_openapi api/openapi.yaml` from `packages/contract_test`, the structural
check of `docs/reference/api.md`, and compares the SHA-256 of `api/openapi.yaml` with
`packages/api_client/.openapi-source.sha256`; a mismatch prints "the generated client is
stale: run tools/gen_api_client.sh". Each failure is printed and the script exits 1; on
success its last line, which the gate shows, counts the operations and schemas. Bodies are
validated against the contract by the server's and the fakes' tests, not here.

## `tools/check_strings.dart`: the strings step

The gate's strings step, pure Dart, run from the repository root. It fails, a line per
problem, on:

- a string literal in the app's presentation code (each feature's `presentation/`, and
  `core/router/`, `core/layout/`, `core/widgets/`, `core/l10n/`) that reads as prose (two letters or
  more, and a space or a leading capital) and is not an import, a comment, a key or an
  identifier, a log or an assertion message, or listed in
  `tools/check_strings_allowlist.txt` as `path|literal` under a comment saying why (an
  entry that matches nothing is a failure too);
- a literal that joins pieces in code: a ` · `, `, ` or ` ` separator passed to `join`,
  or interpolations separated only by ` · `, `, ` or spaces (`'$name ${amount}'`); the
  ARB's templates do that (`app-core.md`, **Localization**), and a join that is not
  text for a reader (the words of an identifier) goes on the allowlist, its literal
  JSON-quoted when it is or ends in a space (`path|" "`). An entry allows every
  occurrence of its literal in its file, so such a join lives in a file of its own
  (`core/l10n/title_case.dart`). It reads literals, so a string
  built with `+` gets past it;
- a key of `app/lib/l10n/app_en.arb` without an `@key` description, or a placeholder a
  message uses without a typed declaration;
- a key in another locale's ARB that the template lacks, or a translated message whose
  placeholders differ from the template's;
- the pseudo-locale, `app_en_XA.arb`, not exactly what `tools/pseudo_locale.dart` makes
  of the template (keys missing, extra or stale), with `dart run tools/pseudo_locale.dart`
  named as the fix.

It prints each translated locale's untranslated count (shown in English), which never
fails it. Android's XML strings are outside the check: the few the launcher reads
without the app (the home screen widgets' names, descriptions and set-up message,
`widgets.md`) live in `app/android/app/src/main/res/values/` with each translation
beside them in `res/values-<locale>/`.

## `tools/pseudo_locale.dart`: the pseudo-locale

`dart run tools/pseudo_locale.dart` writes `app/lib/l10n/app_en_XA.arb` from the template:
every message's text accented, lengthened by 40 percent (tildes in groups of five, so it
still wraps) and bracketed, its placeholders and its `plural` and `select` syntax intact.
Run it, then `flutter gen-l10n` in `app/`, after changing `app_en.arb`; the strings step
fails until it is current. The pseudo-locale is offered in dev and demo under
Settings → Appearance → Language (`app-core.md`, **Localization**), to find layouts that
would cut a longer translation off.

## `tools/check_commits.sh`: the commit-message lint

`tools/check_commits.sh <base> [<head>]` checks every commit in `<base>..<head>` (`HEAD` by
default) for the shape **Delivery and landing** in the map requires. The gate runs it on
the commits beyond `origin/main` and `tools/land_series.sh` on the series it lands, so the
two agree. A subject is `type(scope): Summary` or `type: Summary`, a `!` before the colon
allowed, where

- the type is one of `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`,
  `chore`, `style`, `revert`;
- the scope is one of `app`, `server`, `models`, `api`, `persona`, `tools`, `docs`, `ci`,
  `build`, a feature folder under `app/lib/features/` in `<head>`'s tree, or `sync` or
  `map`, which the history uses;
- the summary starts with a capital letter or a digit, does not end in a period, and its
  first word is not a past tense, an `-ing` form or a third person (`Added`, `Adding`,
  `Adds`; verbs that only look like one are let through: `Embed`, `Shed`, `Shred`, `Wed`,
  `Bring`, `Cling`, `Fling`, `Ping`, `Ring`, `Sing`, `Sling`, `Spring`, `Sting`, `String`,
  `Swing`, `Wring`, `Alias`, `Bias`, `Canvas`; words ending in `-eed`, `-ss` or `-us`
  pass the check anyway);
- the whole subject is at most 72 characters.

No message may carry a trailer: none that `git interpret-trailers --parse` finds, and no line
starting `Co-Authored-By:`, `Signed-off-by:`, `Generated-with:`, `Reviewed-by:`,
`Claude-Session:` or `Change-Id:`. A message line over 100 characters is noted, not refused.
It prints one line per problem and exits 1, or a count on its last line and exits 0; 2 on
a usage error. It only reads the repository.

## `tools/land_series.sh`: landing a series

`tools/land_series.sh <patch-dir> <base-commit> <tree-hash> [--dry-run]`, the coordinator's
landing step. It refuses a dirty tree or a HEAD other than the base on `main`; then applies
the `NNNN-*.patch` files with `git am`, runs `tools/check_commits.sh <base>` on the applied
commits (the series' own copy of the script), checks the final tree against the reported
hash, rolling back to the base when either fails, and runs the gate, leaving the commits in
place unpushed.
The gate's report is kept in `app/build/landing/<tree>.log` (gitignored), by the tree it
checked. When the gate fails the commits stay in place too, and the script prints the tail
of the failing step (each `gate <step> FAILED` line and the output under it, the last 60
lines), the report's path and the exact `git reset --hard <base>` that undoes the landing,
then exits 1. `--dry-run` stops after the tree check and resets to the base.

## `tools/run_server.sh`: the dev server

`tools/run_server.sh` starts the development server with one command
(`docs/reference/server.md`, **Running it**). On its first run it creates `server/.env`
from `server/.env.example`, filling `JWT_SECRET`, `TOKEN_ENCRYPTION_KEY` and
`SEED_USER_PASSWORD` with `openssl rand` values and setting the seed user
`dev@financetracker.test`. It says it did so but prints no secret. Then it runs
`dart run bin/server.dart` in `server/`, which migrates and seeds the database under
`server/data/` and serves on `127.0.0.1:8080` until Ctrl-C. It writes `server/.env` and
`server/data/`, both gitignored. The Plaid mode is `PLAID_MODE` in `server/.env`:
`fake` by default (no Plaid API is called); `sandbox` calls Plaid with the keys there,
which only the owner sets. It reads `server/.env`, so it is the owner's command; a lane
runs it only in its own clone, in fake mode, with no real keys (there are none in a
clone).

## The recorded Plaid fixtures

`server/test/fixtures/plaid/*.json` are the coordinator's sanitized captures from live
Sandbox (2026-10-24, `PLAN.md` §4), each `{status, body}` with every token replaced by
`*-REDACTED` and no key. They are the shapes the HTTP Plaid client is tested against.
`server/test/support/recorded_plaid_transport.dart` replays them as Plaid's HTTP answers
by path. Each path answers from a queue of scripted answers (a fixture name, a
synthesized body, or a function of the request), then from its default; a path with
neither fails the test. Each request is recorded with its raw and decoded body and
checked for `Plaid-Version` and the test keys (`test-client-id`, `test-plaid-secret`, not
Plaid's). Cases Sandbox did not show (a mutation during pagination, pending-to-posted,
investments paging, an unreadable answer) are synthesized in the tests, in Plaid's
documented shapes. `server/test/plaid_fixtures_scan_test.dart` scans every fixture and
fails on `access-sandbox-`, `public-sandbox-` or `link-sandbox-`, a `client_id`, `secret`
or `*_token` value that is not redacted, or any run of 24 or more hex digits, so a
capture added later is held to the same rule.

## The live Sandbox suite

`server/test/live/sandbox_live_test.dart` runs the server's real code against Plaid
Sandbox: one Item for `user_transactions_dynamic` at First Platypus Bank, linked (with a
repeated exchange), synced to completion, its data checked as `source: plaid`, balances
refreshed, an unknown webhook key asked for, reset to login-required, and removed. A second case links a `user_custom` with one 401(k) at Tartan Bank (`ins_109511`, products `transactions` and `investments`), an investment-only Item, and finds the account and its holding through the server's sync before removing it. A
failed step still removes the Item. It is skipped unless `PLAID_LIVE_TESTS=1`,
`PLAID_CLIENT_ID` and `PLAID_SECRET` are all in the environment, so the gate, CI and the
lanes never run it (`PLAN.md` §13: local only). The owner runs it from `server/` with the
keys exported:

```
PLAID_LIVE_TESTS=1 PLAID_CLIENT_ID=... PLAID_SECRET=... dart test test/live
```

It takes about a minute and makes about twenty Plaid calls.

## `tools/scripts/provision_persona.sh`: persona provisioning

`tools/scripts/provision_persona.sh <renter|family|student|small_business> [--seed N]
[--days D] [--server URL]` drives the dev server's provisioning job
(`docs/reference/server.md`, **Provisioning**). It signs in as the seed user
(`SEED_USER_EMAIL` and `SEED_USER_PASSWORD` from the environment, else from
`server/.env`), POSTs `/sandbox/provision`, and polls the job every 5 s, printing one
progress line (`running  items 1/4  batches 0/0  skipped 0`; the job injects nothing, so the batches stay 0), refreshing the access token
when it expires. It exits 0 when the job completes, 1 when it fails (with the job's
error) or a request fails or gets no answer (with a `provision_persona:` message), 2 on
a usage error. The server defaults to `http://localhost:8080/v1`.

It signs out only when the job has finished (`completed` or `failed`) or never started.
On Ctrl-C, and on any failure after the job started, the device stays signed in,
because the job links its Items through it; Ctrl-C stops the polling, not the job.

It never prints or traces a token or a password: it turns tracing off (`set +x`), and
the values reach `curl` and `jq` only through pipes and files in a private temporary
directory, never as an argument or a shell variable, so even a forced `bash -x` shows
neither. It needs `curl` and `jq`, and writes only that directory.

Against a sandbox-mode server it creates real Sandbox Items, which is the coordinator's
seat only. A lane points it at a fake-mode server started from its own clone (for example
`PORT=18080 tools/run_server.sh`, then `--server http://127.0.0.1:18080/v1`), where the
whole job runs against the fake client with `source: demo` data, paced in real time.

## `tools/scripts/background_doze_check.sh`: the background sync's job under Doze

`tools/emulator_tests.sh run tools/scripts/background_doze_check.sh`, only through the
harness, which exports the serial (`background.md`, **Testing**). It proves that
WorkManager keeps the periodic sync's job, that Doze defers it while the device is idle
and that it runs the dispatcher's engine in Doze's maintenance window. It does not prove a
sync under Doze: in the demo flavor the cycle returns at its first step ("background:
demo, nothing to sync"); a real sync against the dev server under Doze is the
coordinator's dev-flavor acceptance.

1. It unplugs the battery and sets it low, then runs
   `integration_test/background_sync_test.dart` in the demo flavor with `--no-uninstall`,
   so the periodic sync the test schedules afresh with the real plugin stays, its first
   run (no initial delay) held back by its battery-not-low constraint and so still due. A
   periodic sync that has just run cannot be run again: WorkManager refuses it before its
   period is due ("Delaying execution ... because it is being executed before schedule").
   The test's end stops the app, which drops its jobs, so the script sends WorkManager's
   diagnostics broadcast (`androidx.work.diagnostics.REQUEST_DIAGNOSTICS`, a debug
   build's, with `FLAG_INCLUDE_STOPPED_PACKAGES`), which starts the app's process in the
   background, where WorkManager registers them again.
2. It checks the sync has not run, then finds the registered job under "Registered <n>
   jobs:" in `dumpsys jobscheduler`: `JOB androidx.work.systemjobscheduler:u0a<app
   id>/<job id>: ...` (WorkManager's namespace on Android 14 and later; the id is
   assigned per device, so looked up each time, and the app's uid from
   `pm list packages -U` picks this install's).
3. It ends the app's background process (`am kill`, which keeps its jobs; Doze holds no
   running app's jobs back while it serves a receiver), refuses an app on Doze's
   permanent allowlist (`dumpsys deviceidle whitelist`) and waits, at most three
   minutes, until `dumpsys deviceidle tempwhitelist` no longer lists it (the shell's
   broadcast puts it on the temporary allowlist, under which its jobs run even while
   idle), then forces the device idle (`dumpsys deviceidle force-idle`, which must read
   `IDLE`) and sets the battery level back up, so only Doze can hold the job.
4. It reads the hold from JobScheduler: the job's entry must report `readyNotDozing:
   false`, not a timed absence of the task. That line alone is the evidence; the job's
   `CONNECTIVITY` constraint may read satisfied or not meanwhile.
5. It steps Doze to its maintenance window (`dumpsys deviceidle step deep`) and waits for
   the task's line in the log. Nothing forces the job: `cmd jobscheduler run -f` would
   override its constraints, so only the maintenance window's run counts.
6. On exit, whatever happened, it lets the device out of idle, resets the battery and
   uninstalls the demo app.

It exits 0 only on the maintenance window's run. Any other path says which step failed
(the task running while idle, JobScheduler never reporting the hold, the task not running
in the window) and prints the job's constraint lines, and the log when the task never ran.

## `tools/secrets_sweep.sh`: the secrets sweep

`tools/secrets_sweep.sh [<logcat-capture>]` checks the release hardening that files can
show (`PLAN.md` §12, "Release hardening"), reading files only:

- **manifest**: the main manifest sets `android:allowBackup="false"`,
  `android:fullBackupContent="false"` and
  `android:dataExtractionRules="@xml/data_extraction_rules"`, and no other source set's
  manifest sets `allowBackup` to true;
- **rules**: `data_extraction_rules.xml` excludes `domain="root" path="."` from
  `<cloud-backup>` and `<device-transfer>`, and has no `<cross-platform-transfer>`
  section (`build.md`, **Android**);
- **logcat**, given a capture of the app's log: no line holds a bearer token, a JWT, a
  Plaid access, public or link token (`access-`, `public-`, `link-` with `sandbox`,
  `development` or `production`), a refresh token or base64 key (a run of 40 or more
  base64url or base64 characters holding an uppercase letter, a lowercase letter and a
  digit, which a stack frame, an API path or a snake_case name does not), a hex database
  key (`x'` and 16 or more hex digits) or an email address. A hit prints the pattern's
  name and the line number, never the text.

`tools/secrets_sweep.sh --self-test` runs the logcat check on a clean capture (a stack
frame, an API path, a long snake_case name), which must pass, and on one dirty line per
pattern, each of which must fail.

It then prints the steps for the coordinator: capturing the app's log with `adb logcat -d
--pid`, `adb backup -noapk` of the app with the archive listed (no file of the app's
expected), and `dumpsys backup`. Agents run the file checks; a device is the
coordinator's. One line per check; exit 1 when any fails.

The prod flavor's in-memory log is held to the same rule in Dart: the sink keeps a
sanitised copy of each record (`app-core.md`, **Logging**), proven by
`app/test/core/logging/app_log_test.dart`. That test drives the wired prod sink under
`flutter test`, chosen by flavor (`setUpLogging(Flavor.prod)`) and not by `kReleaseMode`,
so it proves the sink, not a release-mode run; the release smoke is the coordinator's.

## `tools/emulator_tests.sh`: the emulator harness

Runs the app on one of the harness's own headless Android Virtual Devices, `ft-lane` unless
`FT_EMULATOR_AVD` names another (**Other AVDs**, below), under a machine-wide lock, so only
one emulator run happens on the machine at a time, whichever AVD it uses, and a second lane
waits its turn. It runs from the repository root wherever it is called from: a relative
screenshot path is relative to the root, and `run` runs its command there. It talks to an
emulator only after `adb -s <serial> emu avd name` has answered the AVD's name, so the owner's
`Pixel_*` and `Nexus_*` emulators and any physical device are never touched, and it fails
loudly otherwise.

A caller waits on a run with one bounded wait under its own timeout, never a second wait while
one is running, and kills any polling shell once the run it watched has finished.

| Command | What it does |
|---|---|
| `integration [-- <args>]` | The default. Boots the AVD, uninstalls the demo app a previous run left (below), then runs `flutter test integration_test --flavor demo -d <serial>` from `app/`, passing any extra arguments through; when the arguments name tests (a path relative to `app/` under `integration_test/`, or a `.dart` file or a directory that exists under `app/`), it runs only those instead of the whole `integration_test` directory (`tools/emulator_tests.sh integration -- integration_test/app_launch_test.dart`). An option's value is never taken for a test: an argument right after an option given without `=` (`--name test`, `--dart-define FOO=bar.dart`) is its value, so `integration -- --name test` runs the whole directory with that filter; give files before options. The tests run against the in-app fakes. Then it prints one line per test file from Flutter's JSON report (`--file-reporter`, kept at `app/build/emulator/integration.json`): its result, its tests and how many were skipped, and its duration from the start of its loading (the build and the install) to the end of its last test, so the slow file is named; a file the run never started (an interrupted run) is listed as "no events"; without `jq` it says so and prints none. |
| `demo [<screenshot>]` | Boots, builds the demo debug APK, installs it with `adb install -r`, launches the launcher activity of `dev.tarnan.financetracker.demo`, waits (up to 60 s) for it to take window focus plus a short settle for the first frame, and saves a screenshot of the active display (`screencap -d`, so a foldable's two displays do not spoil it), by default `app/build/emulator/demo.png`; prints the path. |
| `run <command...>` | Boots, then runs the command with `FT_EMULATOR_SERIAL` set to the emulator's serial: anything else against the AVD goes through this. |
| `posture <folded\|half\|unfolded\|list>` | Boots, then sets a foldable's posture through the emulator console (`adb emu posture` 1, 2 or 3) and prints the device state it led to; `list` prints the console's postures and the device states the system offers (`cmd device_state print-states`). Takes the lock like a run, so inside a `run` command call `adb -s "$FT_EMULATOR_SERIAL" emu posture <n>` directly. |
| `stop [--force]` | Shuts down the AVD's emulator and removes a stale lock. Refuses while a live run holds the lock, unless `--force`: then it prints the holder, kills the emulator and removes the lock whoever holds it. |
| `status` | Who holds the lock (pid, since when, command), and whether the AVD (named in the line) is running and on which serial. |

**The lock.** `integration`, `demo`, `run` and `posture` hold it for their whole run. It is the
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
run reuses it (after the checks of **Recycling**, below); `stop` shuts it down. The long
steps (`flutter`, `sdkmanager`, the `run` command) run as a background child the script
waits on, so `SIGTERM` or `SIGINT` takes
effect at once: the trap stops the child and its descendants (TERM, then KILL after 10 s),
releases the lock and exits 143 or 130, and no orphan is left driving the emulator. A run
killed with `SIGKILL` leaves its lock and its child behind, and the next run reclaims the
lock.

**The run ceiling.** Each of those children has a ceiling of `FT_EMULATOR_RUN_TIMEOUT`
seconds (default 1800), counted from its start, so a hung run cannot hold the lock for
hours (a Phase 7 integration run sat idle for 2 h 35 min). When it passes, the harness
prints the texts on the emulator's screen (a `uiautomator dump`: each node's text, else its
content description; a password field's text and any text holding an `@`, such as a typed
email, print as `[redacted]`) and the last 40 lines of the demo app's log (of the whole
emulator's when the app is not running), stops the child and its descendants (TERM, then
KILL after 10 s), releases the lock and exits 124. The ceiling bounds the run;
`FT_EMULATOR_LOCK_TIMEOUT` still bounds only the wait for the lock. Both are whole numbers of
seconds, and the harness refuses any other value before it starts rather than run without a
ceiling. `FT_EMULATOR_RUN_TIMEOUT=20 tools/emulator_tests.sh
run sleep 200` exercises it.

**The AVD.** Created on first use with `avdmanager create avd -n <name> -k <image> -d
<device>`, from `FT_AVD_IMAGE` (default `system-images;android-36;google_apis;arm64-v8a`,
installed with `sdkmanager --install`, licences accepted, when missing) and `FT_AVD_DEVICE`
(default `pixel_6`), then given `hw.keyboard=yes`, `disk.dataPartition.size=2G`, the
SwiftShader GPU and, for `pixel_6`, `hw.lcd.density=420` in its `config.ini`, replacing the
values `avdmanager` wrote; another device definition keeps its own density. The API 36 emulator raises
the data partition to 6 GB on first boot whatever the file says; the image is sparse, so it
takes far less on disk. It boots with `-no-window -no-audio -no-boot-anim -no-snapshot -gpu
swiftshader_indirect` on the first free even port from 5554 to 5584, so an emulator the
owner already has on 5554 is left alone; the boot waits
up to 240 s for `sys.boot_completed` and the package manager, then turns the window,
transition and animator animations off. A run that finds the AVD already running waits the
same way before using it, since an interrupted run can leave it offline or still booting. Its
log is `app/build/emulator/emulator-<name>.log`.

**Other AVDs.** `FT_EMULATOR_AVD` names the AVD a command is about (default `ft-lane`); it
must be a harness-owned name, `ft-` then letters, digits, `_` or `-`, and the harness refuses
any other, so it can never boot, stop or kill the owner's `Pixel_*` AVDs. An AVD that does not
exist is created from `FT_AVD_IMAGE` and `FT_AVD_DEVICE`; `avdmanager list device -c` names
the definitions, among them `pixel_fold`, `pixel_9_pro_fold`, `pixel_tablet` and
`medium_tablet`. The lock is the same for every AVD, so there is still one emulator run on the
machine at a time, and before a run boots or reuses its AVD it stops any other harness AVD
that is running (`stopping the harness AVD ft-fold on emulator-5554 before using ft-lane`), so
at most one harness emulator is up; the AVD a run used is left running for the next run, as
`ft-lane` always was. `status` is about the AVD `FT_EMULATOR_AVD` names. For layout work:

```
FT_EMULATOR_AVD=ft-fold FT_AVD_DEVICE=pixel_fold tools/emulator_tests.sh demo app/build/emulator/fold.png
FT_EMULATOR_AVD=ft-fold tools/emulator_tests.sh posture folded
FT_EMULATOR_AVD=ft-tablet FT_AVD_DEVICE=pixel_tablet tools/emulator_tests.sh demo app/build/emulator/tablet.png
```

`FT_AVD_DEVICE` matters only when the AVD is created. A `pixel_fold` AVD has two displays, the
inner 2208 x 1840 and the outer 1080 x 2092, and its `config.ini` lists the postures 1 to 3
(`hw.sensor.posture_list`); the console's `posture` usage names 1 closed, 2 half-opened,
3 opened, 4 flipped and 5 tent, of which the fold takes the first three, and the system offers
the device states `CLOSED` (0), `HALF_OPENED` (1), `OPENED` (2) and `REAR_DISPLAY_MODE` (3).
`posture folded`, `half` and `unfolded` move it to states 0, 1 and 2. Folding moves the
foreground to the outer display behind the keyguard (Android's default on fold), so a folded
screenshot shows the lock screen until it is dismissed; a non-foldable AVD refuses a posture
and the command fails.

**Recycling.** A long-lived `ft-lane` can wedge: twice on 2026-10-25, after hours under
several lanes, `system_server` restarted, the `package` service was gone (`pm path android`
answering "Can't find service: package") and binder reported "No space left on device";
every run then died in the boot wait, which never recovers. So before a run reuses a running
`ft-lane` it checks two things. When the emulator process has been up
`FT_EMULATOR_MAX_UPTIME` seconds or more (default 14400, four hours) the run recycles it;
otherwise it runs the health check, `sys.boot_completed` 1 and `pm path android` answering
`package:` within 30 s, and recycles an emulator that fails it, unless the emulator is
younger than the 240 s boot window, which an interrupted run can leave still booting and
which the run waits for as before. Recycling kills the emulator (`adb emu kill`, then
`SIGTERM`, then `SIGKILL`, each given 10 s, signalling only processes started with `-avd
ft-lane`) and boots a fresh one in the same run. `stop --force` is the way out when a run
holds the lock while stuck on a wedged emulator: it says who held the lock, kills the
emulator, then removes the lock (renamed away first, so a lock taken by another run in the
meantime is put back). It does not signal the holder: a run waiting on the emulator fails
once it is gone, and its exit leaves any newer lock in place.

To exercise these paths in a lane (the dry run; each takes the lock, so one at a time):

1. `tools/emulator_tests.sh run true` twice: the second says "reusing the running ft-lane
   emulator".
2. Wedge it the way the incident did, with the SDK's `platform-tools` on `PATH`:
   `tools/emulator_tests.sh run sh -c 'adb -s "$FT_EMULATOR_SERIAL" root && sleep 3 && adb
   -s "$FT_EMULATOR_SERIAL" shell stop'` (the `google_apis` image allows `adb root`; `stop`
   takes the framework down, so `pm path android` answers "Can't find service: package");
   the next `tools/emulator_tests.sh run true` says it is not healthy, recycles it and boots
   a fresh one.
3. `FT_EMULATOR_MAX_UPTIME=60 tools/emulator_tests.sh run true` on an emulator up more than a
   minute recycles it for its uptime.
4. In one shell `tools/emulator_tests.sh run sleep 600`; in another `tools/emulator_tests.sh
   stop` refuses, naming the holder, and `tools/emulator_tests.sh stop --force` kills the
   emulator and removes the lock; `status` then shows the lock free and `ft-lane` not running.
5. `tools/emulator_tests.sh integration` boots a fresh emulator and runs the suite.

The SDK comes from `ANDROID_HOME`,
else `ANDROID_SDK_ROOT`, else `~/Library/Android/sdk`; a missing `adb`, `emulator`,
`avdmanager` or `sdkmanager` fails with the fix.

**What it writes.** The AVD in `~/.android/avd/<name>.avd` (and its `.ini`), the system
image under the SDK on first use, the lock directory (with its short-lived `.new.*` and
`.stale.*` siblings), and `app/build/`: the APKs, the emulator, `sdkmanager` and
`avdmanager` logs, the integration run's JSON report and the screenshot under `app/build/emulator/`. Installs go onto the
harness's own AVDs only.

**The integration test app is moved aside.** `flutter test integration_test --flavor demo`
writes its test app to `app/build/app/outputs/flutter-apk/app-demo-debug.apk` and to Gradle's
`app/build/app/outputs/apk/demo/debug/app-demo-debug.apk`, the paths `flutter build apk
--debug --flavor demo` uses, and started standalone that app waits for its test host and never
draws a frame (the Phase 6 acceptance installed it by mistake and chased a "startup hang").
So when an `integration` run ends, on any exit (passed, failed, past its ceiling or
signalled), each file at those paths newer than the run's start (the marker
`app/build/emulator/integration.started`) is renamed `app-demo-debug.integration-test.apk`
beside it, and the run says so: a later `adb install` of either demo path finds a real build
or nothing. The `demo` command builds before it installs, as before. A
`flutter test integration_test` run outside the harness still leaves its test app there.

**The uninstall before the tests.** `integration` removes `dev.tarnan.financetracker.demo`
when it is installed, so Flutter's install starts clean. The emulator has answered `adb
uninstall` with `DELETE_FAILED_INTERNAL_ERROR` before the tests; then the harness clears the
app's data with `pm clear`, tries once more, and when that fails too says so and goes on,
since Flutter installs with `adb install -r`, which replaces the package.

**Integration tests** live in `app/integration_test/` and use
`IntegrationTestWidgetsFlutterBinding`; the `--flavor demo` build supplies the demo
application, and each test file's `main` is the entry point, so no `-t` is given.
`app_launch_test.dart` starts the app through `bootstrap(AppConfig.demo())`, as
`main_demo.dart` does, and checks that a `MaterialApp` titled with the demo app name is up
and that the Accounts tab shows the demo seed's accounts with their derived balances.
`auth_flow_test.dart` finds the demo signed in as the demo user, then, when the run is
given `--dart-define=FT_FAKE_SERVER=true` (`tools/emulator_tests.sh integration --
--dart-define=FT_FAKE_SERVER=true`; skipped without it), starts the dev flavor on the
in-app fake server and registers, signs out, signs in, makes a request after the access
token expired and signs out (`auth.md`). CI does not run them yet. The flows that wait on the app in real time (the Link flow
waits 5 s between sync requests) pump until a condition holds for up to 120 s of wall-clock
time, never a fixed count of pumps, and settle a link by waiting until no Item action runs,
since on an emulator loaded by several lanes a link has taken longer than 30 s. A flow that
saves an editor waits until the editor has closed before it navigates or reads back what
it saved (`saveEditor` in `integration_test/support/editor.dart`, which the flows share):
the editor closes only once its write lands, and only while it is still the top page, so
a page pushed before that would leave it open.
