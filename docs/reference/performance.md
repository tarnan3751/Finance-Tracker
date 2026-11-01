# Performance

How the app's speed and size are measured, so that a change is proved against a number
rather than an impression (`PLAN.md` §12, "Phase 11 go-ahead"). One script per
measurement under `tools/perf/`; each prints a one-line summary and writes a JSON record
under `app/build/perf/` (gitignored with the rest of `app/build/`). A baseline is a set of
those records committed under `docs/reference/perf-baselines/<commit>.json`; the table
below is the current one.

## The rules

- **Profile or release builds only.** A debug build's frame and start times measure the
  JIT, not the app. Cold start and the scroll run the demo flavor's profile build, size
  the prod flavor's release builds; the host tests run on the Dart VM as `flutter test`
  runs them.
- **The same AVD.** Device numbers come from the harness's `ft-lane` AVD (the
  `system-images;android-36;google_apis;arm64-v8a` image on `pixel_6`, SwiftShader GPU),
  through `tools/emulator_tests.sh run`, which holds the machine-wide lock. They are
  emulator numbers on the owner's Mac: compared only with each other, never with a phone.
  The device scripts run themselves through the harness when called directly, and refuse a
  serial whose emulator is not an `ft-` AVD.
- **The demo flavor on the device.** It needs no network and its seed is fixed, so two
  runs start from the same data.
- **Median of n, with the spread.** Each script reports the median with the minimum and
  maximum (or, for the frame figures, the percentiles flutter_driver computes). A baseline
  holds two runs of every script; a change is real when it moves the number by more than
  the two runs differ (the **Noise** column).
- **Record the commit and the load.** Every record carries the commit (`commit`), the
  commit of `main` it is based on (`main_base`), the tree hash of `app/lib`
  (`app_lib_tree`, which shows two records measured the same app code), how many measured
  files had uncommitted changes, the date (UTC), the host (CPU, memory, macOS version, the
  one-minute load at the end of the run), the Flutter version and the device (AVD, API
  level, ABI). Run a measurement with the load under 8, one at a time: two builds or two
  suites at once slow each other.
- **Nothing asserts a number tightly.** The owner's machine is shared by several lanes, and
  a gate that failed on a busy minute would lie. The write-path test asserts ceilings
  several times the measured figures; the scripts assert nothing.

## The scripts

| Script | Where | What it measures |
|---|---|---|
| `tools/perf/cold_start.sh [<serial>] [<applicationId>]` | harness | Launch to first frame of the demo profile build |
| `tools/perf/scroll.sh` | harness | Frames while flinging a ten-thousand-row list; start to data on screen |
| `tools/perf/write_path.sh` | host | `upsertAll`, a sync pull and the import's review on the dev wiring |
| `tools/perf/size.sh` | host | The prod APKs, their native libraries, dex, resources and assets |
| `tools/perf/suite_time.sh` | host | The gate's per-package test time; the twenty slowest app test files |
| `tools/perf/report.sh` | host | Tables from the records, against a baseline |

They share `tools/perf/lib.sh` (the record, the harness hand-off) and need `jq`. A record
is written twice: `app/build/perf/<script>.json` (the latest) and
`app/build/perf/runs/<script>-<UTC stamp>.json` (every run, which `report.sh --collect`
gathers into a baseline). Each metric's name ends in its unit: `_ms`, `_s`, `_bytes`,
`_count`.

### Cold start

`tools/perf/cold_start.sh` builds `flutter build apk --profile --flavor demo -t
lib/main_demo.dart`, installs it on a clean slate (the demo app uninstalled first) and
launches it once unrecorded (`first_launch_ms`: the first launch after an install also
creates the app's data directory and runs the ART verifier's first pass). Then
`FT_PERF_LAUNCHES` (10) launches with `adb shell am start -W -S -n <activity>`, each
force-stopping the app first, so every launch is a cold process; the record keeps the
median, minimum and maximum of Android's `TotalTime` (from the process start to the first
frame of the activity's window being drawn; Android may count that frame at the launch
theme's splash, before Flutter's first frame). Then one `flutter run --profile
--trace-startup` reads `app/build/start_up_info.json`: `framework_init_ms`
(`timeToFrameworkInitMicros`, from the engine's entry to the framework's), `first_frame_ms`
(`timeToFirstFrameMicros`, to Flutter's first frame built) and `first_frame_rasterized_ms`
(`timeToFirstFrameRasterizedMicros`, to that frame on the screen), all from the engine's
entry. "Data on screen" is not a startup-trace figure; the scroll script measures it. The
demo app is uninstalled when the script ends.

### Scroll and data on screen

`tools/perf/scroll.sh` runs `flutter drive --profile --flavor demo
--driver=test_driver/perf_driver.dart --target=integration_test/perf/scroll_test.dart
--no-dds --dart-define=FT_PERF=true` in `app/`. The test seeds the demo's store with one
more account, "Perf ledger", holding 10,000 `demo` transactions from a fixed seed (about
nine a day back from today), beside the persona's seed, with the frame policy
`fullyLive`, and traces twice with `IntegrationTestWidgetsFlutterBinding.traceAction`:

1. `start`: from `startApp` (after the process setup `bootstrap` does once: the time zones,
   the locale, the date symbols) until the Accounts list shows its first row ("Everyday
   Checking", the renter's), pumping a frame every 8 ms: `data_on_screen_ms`. The startup
   of a process is cold start's; this is the app's own start on the seeded ledger, with
   the launch-time watchers (the recurring detector, the budget alerts, the weekly summary)
   running over it.
2. `scroll`: the app started again the same way, the Transactions tab opened, its list
   flung five times toward its end (1,500 px at 5,000 px/s, each fling left to settle).
   The list loads 50 rows a page, so a fling runs into the loaded end; the test then waits
   for the next page, as a person would, before the next fling. `scroll_offset_px` is how
   far the list got, `scroll_span_ms` the time from the trace's first frame to its last.

The driver summarises each timeline with flutter_driver's `TimelineSummary` into
`app/build/perf/start.timeline_summary.json` and `scroll.timeline_summary.json`, and writes
the test's other figures to `perf_drive.json`. The record keeps, for the scroll: the frame
count, the average, 90th and 99th percentile and worst build and raster times in ms, and the
missed build and raster budgets (frames over 16 ms); for the start, its frame count and its
worst frame build. Outside `flutter drive` (the harness's whole-directory integration run)
the test is skipped: it asks for `FT_PERF`.

### Write path

`tools/perf/write_path.sh` runs `flutter test test/perf/write_path_test.dart --reporter
expanded` with `FT_PERF_RUNS=3`. The test uses the dev flavor's wiring
(`test/helpers/dev_wiring.dart`: the Drift repositories and the real change recorder) over
an encrypted database in a temporary file opened by the app's own open path (SQLite3
Multiple Ciphers with a key, WAL, the busy handler, the full-text index, which it asserts is
on), a fresh file for every run:

| Metric | What is timed |
|---|---|
| `upsert_all_1000_*`, `upsert_all_10000_*` | `TransactionRepository.upsertAll` of that many generated manual transactions into an empty account, recorded for sync |
| `sync_pull_5000_*` | A device with no data adopting its id and running a `SyncSession` that pulls another device's 5,001 entries (the account and 5,000 transactions, recorded and pushed by that device into an in-memory relay first, not timed) and applies them through the Drift sync store |
| `import_review_10000_*` | The CSV import's `read` and `review` of a 10,000-row file against an empty account (the duplicates check included, the write not) |

Each prints its median, minimum and maximum in ms; the last line, `perf-record: {...}`, is
the JSON the script records. The test is tagged `perf` and **runs in the gate** too, once
(`FT_PERF_RUNS` unset), at full size, with generous ceilings (48 ms a row for `upsertAll`, four minutes for the pull, one for the review),
so it cannot rot; at this baseline it takes about twenty seconds of the app's tests.

### Size

`tools/perf/size.sh` builds the prod flavor's release APK three ways, signed with whatever
key the Gradle configuration finds (the debug key when the `FT_RELEASE_*` variables are
absent; signing does not change the sizes that matter here):

1. `--target-platform android-arm64 --analyze-size`: the flag refuses `--obfuscate` and
   `--split-debug-info`, so this build is neither, and its figures (`analyze_arm64_*`) are
   its own. Its JSON (written under `~/.flutter-devtools/`) is copied to
   `app/build/perf/analyze-size.arm64.json`, which stays out of the repository; the record
   keeps the Dart AOT snapshot's size and its twelve largest packages.
2. The shipped build, `--obfuscate --split-debug-info=build/perf/symbols`, universal
   (`universal_*`, and `symbols_bytes`, the split debug info's size).
3. The same with `--split-per-abi` (`arm64_*`, `armeabi_v7a_*`, `x86_64_*`).

For each APK of 2 and 3: its bytes, `apkanalyzer apk download-size` (the compressed size a
download would be, where the SDK has `apkanalyzer`), and from `unzip -l` the uncompressed
sizes of `libapp.so`, `libflutter.so` and `libsqlite3mc.so` per ABI, the dex files,
`resources.arsc`, the bundled fonts and the Flutter assets. The record's metrics hold the
universal APK's and the arm64 split's; its detail holds every APK's.

### Suite time

`tools/perf/suite_time.sh` runs `tools/gates.sh` once and reads each package's test
duration from the gate's tests line (`tests_<package>_s`), with the gate's whole wall time
(`gate_s`); then runs the app's suite again with `flutter test --no-pub --reporter json`
(`app_suite_json_run_s`) and lists the twenty test files that took longest, each from the
start of its loading to the end of its last test. Test files run concurrently, so those
durations overlap and do not add up to the suite's.

### Reporting

`tools/perf/report.sh` prints Markdown:

- with no argument, the latest record of each script;
- `--against docs/reference/perf-baselines/<commit>.json`, the latest records beside the
  baseline's median of its runs, with the change and the change in percent: the table a
  Phase 11 delivery pastes;
- `--runs <baseline>`, every run of a baseline side by side with its spread
  ((max − min) / median), the noise;
- `--collect [<commit>]`, a new baseline file from every run recorded at the commit
  (HEAD by default), grouped by script, printed for redirecting into
  `docs/reference/perf-baselines/`.

A later lane measures its change with the same scripts on the same AVD, under the same
load rule, and pastes `report.sh --against` the current baseline.

## Baseline

`docs/reference/perf-baselines/a38fe96.json`: the Phase 10 close plus lane 11a's batched
write path, measured on `ft-lane` (API 36, arm64-v8a) on an Apple M5 with 24 GB under
macOS 26.5.1, Flutter 3.47.8, on 2026-11-01. The runs were made on the series that adds
these scripts on top of `a38fe96`, whose `app/lib` tree (`a891dc04b750`, in every record)
is `a38fe96`'s and `17c5766`'s. Two runs of each script except the suite time (one). The
machine was shared with other lanes: the one-minute load at the end of the runs was 4.8
to 29, above the rule's 8 for most of them, so the device figures here are slow and noisy
(an earlier cold start at a load of 3 had a median `TotalTime` of 843 ms, against 4.5 to
5.3 s here). Compare a change with a run on a quiet machine, or with the Noise column in
mind; the sizes are exact.

| Script | Metric | Run 1 | Run 2 | Noise |
|---|---|---|---|---|
| cold_start | `total_time_median_ms` (10 launches) | 5264 | 4541.5 | 15 % |
| cold_start | `first_launch_ms` | 12785 | 10273 | 22 % |
| cold_start | `first_frame_ms` (startup trace) | 2633 | 6233 | 81 % |
| cold_start | `first_frame_rasterized_ms` | 2796 | 6426 | 79 % |
| scroll | `data_on_screen_ms` | 545 | 1076 | 66 % |
| scroll | `scroll_frame_count` | 53 | 53 | 0 % |
| scroll | `scroll_average_frame_build_ms` | 4.31 | 7.2 | 50 % |
| scroll | `scroll_p99_frame_build_ms` | 18.41 | 23.04 | 22 % |
| scroll | `scroll_missed_build_budget_count` | 3 | 7 | |
| scroll | `scroll_average_frame_raster_ms` (SwiftShader) | 37.43 | 49.22 | 27 % |
| scroll | `scroll_p99_frame_raster_ms` | 55.74 | 104.26 | 61 % |
| write_path | `upsert_all_1000_median_ms` | 272 | 371 | 31 % |
| write_path | `upsert_all_10000_median_ms` | 2046 | 5024 | 84 % |
| write_path | `sync_pull_5000_median_ms` | 3512 | 7529 | 73 % |
| write_path | `import_review_10000_median_ms` | 113 | 171 | 41 % |
| size | `universal_apk_bytes` | 85.76 MB | 85.76 MB | 0 % |
| size | `universal_download_bytes` | 38.31 MB | 38.31 MB | 0 % |
| size | `arm64_apk_bytes` (split) | 31.73 MB | 31.73 MB | 0 % |
| size | `arm64_download_bytes` | 15.3 MB | 15.3 MB | 0 % |
| size | `armeabi_v7a_apk_bytes`, `x86_64_apk_bytes` | 30.06 MB, 33.51 MB | same | 0 % |
| size | `arm64_libapp_bytes`, `arm64_libflutter_bytes`, `arm64_libsqlite3mc_bytes` | 13.63 MB, 11.22 MB, 1.93 MB | same | 0 % |
| size | `dex_bytes`, `resources_arsc_bytes`, `font_bytes`, `flutter_assets_bytes` | 6.83 MB, 0.79 MB, 0.89 MB, 1.08 MB | same | 0 % |
| size | `symbols_bytes` | 21.1 MB | 21.1 MB | 0 % |
| size | `analyze_arm64_libapp_bytes` (unobfuscated) | 16.13 MB | 16.13 MB | 0 % |
| suite_time | `gate_s` | 521 | | |
| suite_time | `tests_app_s`, `tests_tools_persona_engine_s`, `tests_packages_sync_engine_s` | 281, 36, 16 | | |

The Dart AOT snapshot's largest packages (`--analyze-size`, arm64): `package:flutter`
4.1 MB, `package:finance_tracker` 3.4 MB, unattributed 1.5 MB, `package:image` 0.8 MB,
mixin deduplication 0.6 MB, shared 0.5 MB, `package:flutter_localizations` 0.5 MB,
`package:api_client` 0.4 MB. The slowest app test files: `test/sync/two_device_convergence_test.dart`
(115 s), `test/accessibility_test.dart` (88 s), the transaction editor screen's (22 s),
`test/perf/write_path_test.dart` (19 s), the bulk-edit screen's (18 s).

The file also holds, under `before_11a`, two `write_path` runs over `970c7db`'s app code
(before lane 11a), at loads of 3.7 and 5.8: `upsert_all_1000` 1557 and 3191 ms,
`upsert_all_10000` 14699 and 22461 ms, `sync_pull_5000` 3799 and 3998 ms,
`import_review_10000` 86 and 90 ms.
