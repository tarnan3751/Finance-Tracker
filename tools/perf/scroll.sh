#!/usr/bin/env bash
# Frames while scrolling a ten-thousand-row ledger, and the time to data on screen, in the
# demo flavor's profile build on the harness's emulator (docs/reference/performance.md,
# **Scroll and data on screen**):
#   tools/perf/scroll.sh
# Runs itself through `tools/emulator_tests.sh run` (the machine-wide lock, the ft-lane AVD)
# unless it already runs there, then `flutter drive --profile --flavor demo
# --driver=test_driver/perf_driver.dart --target=integration_test/perf/scroll_test.dart
# --no-dds --dart-define=FT_PERF=true` in app/. The test seeds the demo with 10,000 more
# transactions, traces the start to the Accounts list's first row and five flings down the
# Transactions list; the driver writes app/build/perf/start.timeline_summary.json,
# scroll.timeline_summary.json and perf_drive.json. Uninstalls the demo app on exit. Prints
# one summary line and writes app/build/perf/scroll.json.
set -uo pipefail
# shellcheck source=tools/perf/lib.sh
source "$(dirname "$0")/lib.sh"
perf_init scroll
perf_on_harness "$PERF_ROOT/tools/perf/scroll.sh" "$@"
PACKAGE="dev.tarnan.spendthrift.demo"
trap 'perf_adb uninstall "$PACKAGE" >/dev/null 2>&1' EXIT

rm -f "$PERF_OUT/start.timeline_summary.json" "$PERF_OUT/scroll.timeline_summary.json" "$PERF_OUT/perf_drive.json"
perf_adb uninstall "$PACKAGE" >/dev/null 2>&1
log="$PERF_OUT/scroll.drive.log"
perf_say "flutter drive --profile (the build takes a few minutes; log: $log)"
(cd app && $FLUTTER drive --profile --flavor demo --driver=test_driver/perf_driver.dart \
  --target=integration_test/perf/scroll_test.dart --no-dds --dart-define=FT_PERF=true \
  -d "$SERIAL") >"$log" 2>&1 \
  || { tail -40 "$log"; perf_die "flutter drive failed (log: $log)"; }
for f in start.timeline_summary.json scroll.timeline_summary.json perf_drive.json; do
  [ -s "$PERF_OUT/$f" ] || { tail -40 "$log"; perf_die "the driver wrote no $f"; }
done

metrics="$(jq -n --slurpfile s "$PERF_OUT/scroll.timeline_summary.json" \
  --slurpfile t "$PERF_OUT/start.timeline_summary.json" --slurpfile d "$PERF_OUT/perf_drive.json" '
  def r: . * 100 | round / 100;
  ($s[0]) as $s | ($t[0]) as $t | ($d[0]) as $d
  | {data_on_screen_ms: $d.data_on_screen_ms,
     start_frame_count: $t.frame_count,
     start_worst_frame_build_ms: ($t.worst_frame_build_time_millis | r),
     scroll_offset_px: $d.scroll_offset_px,
     scroll_span_ms: (($s.frame_begin_times[-1] // 0) / 1000 | round),
     scroll_frame_count: $s.frame_count,
     scroll_average_frame_build_ms: ($s.average_frame_build_time_millis | r),
     scroll_p90_frame_build_ms: ($s["90th_percentile_frame_build_time_millis"] | r),
     scroll_p99_frame_build_ms: ($s["99th_percentile_frame_build_time_millis"] | r),
     scroll_worst_frame_build_ms: ($s.worst_frame_build_time_millis | r),
     scroll_missed_build_budget_count: $s.missed_frame_build_budget_count,
     scroll_average_frame_raster_ms: ($s.average_frame_rasterizer_time_millis | r),
     scroll_p90_frame_raster_ms: ($s["90th_percentile_frame_rasterizer_time_millis"] | r),
     scroll_p99_frame_raster_ms: ($s["99th_percentile_frame_rasterizer_time_millis"] | r),
     scroll_worst_frame_raster_ms: ($s.worst_frame_rasterizer_time_millis | r),
     scroll_missed_raster_budget_count: $s.missed_frame_rasterizer_budget_count}')"
detail="$(jq -s '{drive: .[0]}' "$PERF_OUT/perf_drive.json")"
notes='["demo flavor, profile build through flutter drive, the persona seed plus 10,000 demo transactions on one more account","data on screen: startApp (after the process setup) to the Accounts list showing Everyday Checking; scroll: five flings of 1500 px at 5000 px/s down the Transactions list, each settled and, when it reached the loaded end, the next page waited for; scroll_offset_px is how far the list got, scroll_span_ms the time from the first frame to the last"]'
perf_record "$metrics" "$detail" "$notes"
echo "$metrics" | jq -r '"scroll: data on screen \(.data_on_screen_ms) ms; \(.scroll_frame_count) frames, build avg \(.scroll_average_frame_build_ms) ms p99 \(.scroll_p99_frame_build_ms) ms, raster avg \(.scroll_average_frame_raster_ms) ms p99 \(.scroll_p99_frame_raster_ms) ms, missed budgets build \(.scroll_missed_build_budget_count) raster \(.scroll_missed_raster_budget_count)"'
