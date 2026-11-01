#!/usr/bin/env bash
# The local write path timed on the host (docs/reference/performance.md, **Write path**):
#   tools/perf/write_path.sh
# Runs `flutter test test/perf/write_path_test.dart --reporter expanded` in app/ with
# FT_PERF_RUNS (default 3) runs of each measurement: upsertAll of 1,000 and 10,000
# generated transactions, a sync pull of 5,000 entries through the Drift sync store, and
# the CSV import's read and review of 10,000 rows, on the dev wiring over an encrypted
# temporary-file database. Prints the test's per-measurement lines and writes
# app/build/perf/write_path.json from its `perf-record:` line. No device; writes build/.
set -uo pipefail
# shellcheck source=tools/perf/lib.sh
source "$(dirname "$0")/lib.sh"
perf_init write_path
RUNS="${FT_PERF_RUNS:-3}"
[[ "$RUNS" =~ ^[1-9][0-9]*$ ]] || perf_die "FT_PERF_RUNS must be a positive whole number"

log="$PERF_OUT/write_path.log"
(cd app && FT_PERF_RUNS="$RUNS" $FLUTTER test test/perf/write_path_test.dart --reporter expanded) >"$log" 2>&1
status=$?
grep '^perf: ' "$log"
[ $status -eq 0 ] || { tail -40 "$log"; perf_die "the test failed (log: $log)"; }
line="$(sed -n 's/^perf-record: //p' "$log" | tail -1)"
[ -n "$line" ] || perf_die "no perf-record line in $log"
metrics="$(echo "$line" | jq '.results | to_entries | map(
  (.key) as $k | .value | to_entries | map({key: "\($k)_\(.key)", value: .value})) | add | from_entries')"
perf_record "$metrics" "$line" "[\"host test, dev wiring, encrypted temporary-file database with WAL and FTS, $RUNS run(s) of each\"]"
echo "$line" | jq -r '.results | to_entries | map("\(.key) \(.value.median_ms) ms") | "write_path: medians " + join(", ")'
