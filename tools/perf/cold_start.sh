#!/usr/bin/env bash
# Cold start of the demo flavor's profile build on the harness's emulator
# (docs/reference/performance.md, **Cold start**):
#   tools/perf/cold_start.sh [<serial>] [<applicationId>]
# Runs itself through `tools/emulator_tests.sh run` (the machine-wide lock, the ft-lane AVD)
# unless it already runs there; <serial> defaults to the harness's and may not name another
# device, and <applicationId> defaults to dev.tarnan.spendthrift.demo, the only one it
# measures (the demo flavor needs no network). Builds `flutter build apk --profile --flavor
# demo -t lib/main_demo.dart`, installs it fresh, launches it once unrecorded as the first
# launch after an install (`first_launch_ms`), then FT_PERF_LAUNCHES (10) times with
# `am start -W -S` (each a force-stop and a cold process), and reports the median, minimum
# and maximum of `TotalTime`; then one `flutter run --profile --trace-startup` reads
# timeToFrameworkInitMicros, timeToFirstFrameMicros and timeToFirstFrameRasterizedMicros
# from app/build/start_up_info.json. Uninstalls the demo app on exit. Prints one summary
# line and writes app/build/perf/cold_start.json.
set -uo pipefail
# shellcheck source=tools/perf/lib.sh
source "$(dirname "$0")/lib.sh"
perf_init cold_start
perf_on_harness "$PERF_ROOT/tools/perf/cold_start.sh" "$@"

[ -z "${1:-}" ] || [ "$1" = "$SERIAL" ] || perf_die "the serial must be the harness's ($SERIAL), not '$1'"
PACKAGE="${2:-dev.tarnan.spendthrift.demo}"
[ "$PACKAGE" = dev.tarnan.spendthrift.demo ] || perf_die "only the demo flavor (dev.tarnan.spendthrift.demo) is measured, not '$PACKAGE'"
LAUNCHES="${FT_PERF_LAUNCHES:-10}"
[[ "$LAUNCHES" =~ ^[1-9][0-9]*$ ]] || perf_die "FT_PERF_LAUNCHES must be a positive whole number"

trap 'perf_adb uninstall "$PACKAGE" >/dev/null 2>&1' EXIT

perf_say "building the demo profile APK"
(cd app && $FLUTTER build apk --profile --flavor demo -t lib/main_demo.dart) >"$PERF_OUT/cold_start.build.log" 2>&1 \
  || { tail -30 "$PERF_OUT/cold_start.build.log"; perf_die "the profile build failed"; }
APK="$PERF_OUT/app-demo-profile.apk"
cp app/build/app/outputs/flutter-apk/app-demo-profile.apk "$APK" || perf_die "no profile APK"

perf_adb uninstall "$PACKAGE" >/dev/null 2>&1
perf_adb install "$APK" >/dev/null || perf_die "the install failed"
activity="$(perf_adb shell cmd package resolve-activity --brief -c android.intent.category.LAUNCHER "$PACKAGE" | tr -d '\r' | tail -1)"
[[ "$activity" == "$PACKAGE"/* ]] || perf_die "no launcher activity for $PACKAGE (got '$activity')"

# One `am start -W -S`: prints TotalTime in milliseconds, or fails with am's output on
# standard error (an answer without TotalTime is tried once more).
launch() {
  local out total attempt
  for attempt in 1 2; do
    out="$(perf_adb shell am start -W -S -n "$activity" | tr -d '\r')"
    total="$(printf '%s\n' "$out" | sed -n 's/^TotalTime: *\([0-9][0-9]*\).*/\1/p')"
    [ -n "$total" ] && { echo "$total"; return 0; }
    sleep 3
  done
  echo "$out" >&2
  return 1
}

first="$(launch)" || perf_die "no TotalTime from am start (above)"
sleep 5
times=()
for ((i = 1; i <= LAUNCHES; i++)); do
  t="$(launch)" || perf_die "no TotalTime from am start (above)"
  times+=("$t")
  sleep 3
done
perf_adb shell am force-stop "$PACKAGE"
stats="$(printf '%s\n' "${times[@]}" | perf_stats)"

perf_say "tracing one start with flutter run --profile --trace-startup"
rm -f app/build/start_up_info.json
(cd app && $FLUTTER run --profile --trace-startup --flavor demo -t lib/main_demo.dart -d "$SERIAL") \
  >"$PERF_OUT/cold_start.trace.log" 2>&1 \
  || { tail -30 "$PERF_OUT/cold_start.trace.log"; perf_die "flutter run --trace-startup failed"; }
[ -s app/build/start_up_info.json ] || perf_die "no app/build/start_up_info.json"
cp app/build/start_up_info.json "$PERF_OUT/start_up_info.json"

metrics="$(jq -n --argjson s "$stats" --argjson first "$first" --slurpfile up "$PERF_OUT/start_up_info.json" '
  ($up[0]) as $u
  | {total_time_median_ms: $s.median, total_time_min_ms: $s.min, total_time_max_ms: $s.max,
     first_launch_ms: $first,
     framework_init_ms: (($u.timeToFrameworkInitMicros // 0) / 1000 | round),
     first_frame_ms: (($u.timeToFirstFrameMicros // 0) / 1000 | round),
     first_frame_rasterized_ms: (($u.timeToFirstFrameRasterizedMicros // 0) / 1000 | round)}')"
detail="$(printf '%s\n' "${times[@]}" | jq -s --slurpfile up "$PERF_OUT/start_up_info.json" '{total_time_ms: ., start_up_info: $up[0]}')"
notes='["demo flavor, profile build, installed fresh; TotalTime from am start -W -S (process start to the first drawn frame of the activity window, which Android may count at the launch theme), the first launch after the install apart","the startup trace is one flutter run --profile --trace-startup; data on screen is the scroll script'"'"'s"]'
perf_record "$metrics" "$detail" "$notes"
echo "$metrics" | jq -r '"cold_start: TotalTime median \(.total_time_median_ms) ms (min \(.total_time_min_ms), max \(.total_time_max_ms), '"$LAUNCHES"' launches; first launch \(.first_launch_ms) ms); first frame \(.first_frame_ms) ms, rasterized \(.first_frame_rasterized_ms) ms"'
