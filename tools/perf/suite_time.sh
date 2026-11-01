#!/usr/bin/env bash
# How long the tests take (docs/reference/performance.md, **Suite time**):
#   tools/perf/suite_time.sh
# Runs `tools/gates.sh` once and reads each package's test duration from its tests line,
# with the gate's own wall time; then runs the app's suite again as `flutter test --no-pub
# --reporter json` and lists the twenty test files taking longest, each from the start of
# its loading to the end of its last test (files run concurrently, so these overlap and do
# not add up to the suite's time). The gate's other steps are not timed apart. No device;
# writes build/ and .dart_tool/ as the gate does, so it runs only in a lane's clone. Prints
# one summary line and writes app/build/perf/suite_time.json.
set -uo pipefail
# shellcheck source=tools/perf/lib.sh
source "$(dirname "$0")/lib.sh"
perf_init suite_time

load_start="$(perf_load)"
gate_log="$PERF_OUT/suite_time.gate.log"
perf_say "tools/gates.sh (log: $gate_log)"
started=$SECONDS
tools/gates.sh >"$gate_log" 2>&1
gate_status=$?
gate_s=$((SECONDS - started))
tests_line="$(grep -E '^gate tests ' "$gate_log" | head -1)"
[ -n "$tests_line" ] || { tail -30 "$gate_log"; perf_die "no tests line in $gate_log"; }
# "ok (7 package(s): app 300s, ...)" or "FAILED (1 of 7 packages; app 300s, ...)".
packages="$(printf '%s\n' "$tests_line" | sed -En 's/.*(package\(s\): |packages; )([^)]*)\).*/\2/p' | tr ',' '\n' \
  | sed -n 's/^ *\([^ ]*\) \([0-9][0-9]*\)s.*/\1\t\2/p' \
  | jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {key: .[0], value: (.[1] | tonumber)}) | from_entries')"

report="$PERF_OUT/suite_time.app.json"
perf_say "flutter test --reporter json in app/"
started=$SECONDS
(cd app && $FLUTTER test --no-pub --reporter json) >"$report" 2>"$PERF_OUT/suite_time.app.err"
app_status=$?
app_s=$((SECONDS - started))
slowest="$(grep '^{' "$report" | jq -s --arg app "$PERF_ROOT/app/" '
  [.[] | select(type == "object")] as $events
  | (map(select(.type == "testStart") | {key: (.test.id | tostring), value: .test.suiteID}) | from_entries) as $suite_of
  | [$events[] | select(.type == "suite") | .suite as $suite
      | [$events[] | select((.type == "testStart" and .test.suiteID == $suite.id)
          or (.type == "testDone" and $suite_of[.testID | tostring] == $suite.id)) | .time] as $times
      | select($times | length > 0)
      | {file: ($suite.path | ltrimstr($app)), seconds: ((($times | max) - ($times | min)) / 1000 | . * 10 | round / 10)}]
  | sort_by(-.seconds) | .[:20]' 2>/dev/null || echo '[]')"

metrics="$(jq -n --argjson p "$packages" --argjson gate "$gate_s" --argjson app "$app_s" '
  {gate_s: $gate, app_suite_json_run_s: $app}
  + ($p | with_entries(.key = "tests_\(.key | gsub("[/.]"; "_"))_s"))')"
detail="$(jq -n --argjson s "$slowest" --arg line "$tests_line" --argjson gs "$gate_status" --argjson as "$app_status" \
  '{gate_passed: ($gs == 0), app_suite_passed: ($as == 0), gate_tests_line: $line, slowest_app_files: $s}')"
notes="$(jq -n --arg l "$load_start" '["the gate at its default concurrency; the load at the start was \($l)", "the slowest files come from a second run of the app suite with --reporter json"]')"
perf_record "$metrics" "$detail" "$notes"
[ $gate_status -eq 0 ] || perf_say "the gate FAILED (exit $gate_status); its durations are recorded as they were"
[ $app_status -eq 0 ] || perf_say "the app suite FAILED in the JSON run (exit $app_status)"
echo "$metrics" | jq -r --argjson s "$slowest" '"suite_time: gate \(.gate_s) s; " + ([to_entries[] | select(.key | startswith("tests_")) | "\(.key | ltrimstr("tests_") | rtrimstr("_s")) \(.value) s"] | join(", ")) + "; slowest app file \($s[0].file // "?") \($s[0].seconds // 0) s"'
