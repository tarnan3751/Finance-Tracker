#!/usr/bin/env bash
# Tables from the performance records (docs/reference/performance.md, **Reporting**), in
# Markdown, the shape a delivery pastes:
#   tools/perf/report.sh                       the latest record of each script
#                                              (app/build/perf/<script>.json)
#   tools/perf/report.sh --against <baseline>  the latest records beside a baseline file
#                                              (docs/reference/perf-baselines/<commit>.json):
#                                              the baseline's median of its runs, now, the
#                                              change and the change in percent
#   tools/perf/report.sh --runs <baseline>     every run in a baseline file side by side,
#                                              with the spread (max - min) / median in percent
#   tools/perf/report.sh --collect [<commit>]  prints a baseline file: every run under
#                                              app/build/perf/runs/ recorded at <commit>
#                                              (default HEAD), grouped by script
# A metric's unit is its name's suffix: _ms, _s and _count print as numbers, _bytes as MB.
# Reads only; needs jq.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1
OUT="app/build/perf"
die() { echo "report: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die "jq is missing (brew install jq)"

FORMAT='
  def fmt($name): if . == null then "-"
    elif ($name | endswith("_bytes")) then (. / 1048576 * 100 | round / 100 | tostring) + " MB"
    else (. * 100 | round / 100 | tostring) end;
  def median: sort | length as $n
    | if $n == 0 then null elif $n % 2 == 1 then .[($n - 1) / 2]
      else (.[$n / 2 - 1] + .[$n / 2]) / 2 end;'

latest() {
  local files=()
  for f in "$OUT"/*.json; do
    [ -f "$f" ] && jq -e 'has("script") and has("metrics")' "$f" >/dev/null 2>&1 && files+=("$f")
  done
  [ ${#files[@]} -gt 0 ] || die "no records under $OUT; run a tools/perf/ script first"
  jq -s '.' "${files[@]}"
}

case "${1:-}" in
  "")
    latest | jq -r "$FORMAT"'
      "| Script | Metric | Value | Commit | Date |", "|---|---|---|---|---|",
      (.[] | . as $r | .metrics | to_entries[]
        | .key as $k | "| \($r.script) | \($k) | \(.value | fmt($k)) | \($r.commit) | \($r.date) |")'
    ;;
  --against)
    [ -f "${2:-}" ] || die "usage: tools/perf/report.sh --against <baseline.json>"
    latest | jq -r --slurpfile b "$2" "$FORMAT"'
      ($b[0]) as $base
      | "Against \($base.commit) (median of its runs):", "",
        "| Script | Metric | Baseline | Now | Change | % |", "|---|---|---|---|---|---|",
        (.[] | . as $r | .metrics | to_entries[] | .key as $k
          | ([$base.records[$r.script][]?.metrics[$k] | select(. != null)] | median) as $was
          | (if $was == null or .value == null then null else .value - $was end) as $d
          | "| \($r.script) | \($k) | \($was | fmt($k)) | \(.value | fmt($k)) | \(if $d == null then "-" elif $d > 0 then "+" + ($d | fmt($k)) else ($d | fmt($k)) end) | \(if $d == null or $was == 0 then "-" else ($d / $was * 1000 | round / 10 | tostring) + " %" end) |")'
    ;;
  --runs)
    [ -f "${2:-}" ] || die "usage: tools/perf/report.sh --runs <baseline.json>"
    jq -r "$FORMAT"'
      (.records | [.[] | length] | max) as $n
      | "| Script | Metric | " + ([range($n) | "Run \(. + 1)"] | join(" | ")) + " | Spread |",
        "|---|---|" + ([range($n) | "---|"] | join("")) + "---|",
        (.records | to_entries[] | .key as $s | .value as $runs
          | ($runs[0].metrics | keys_unsorted[]) as $k
          | [$runs[].metrics[$k]] as $v
          | ([$v[] | select(. != null)]) as $nums
          | ($nums | median) as $m
          | "| \($s) | \($k) | " + ([range($n) | $v[.] | fmt($k)] | join(" | ")) + " | "
            + (if ($nums | length) < 2 or $m == 0 or $m == null then "-"
               else ((($nums | max) - ($nums | min)) / $m * 1000 | round / 10 | tostring) + " %" end) + " |")' "$2"
    ;;
  --collect)
    commit="$(git rev-parse --short=7 "${2:-HEAD}")" || die "no commit '${2:-HEAD}'"
    files=()
    for f in "$OUT"/runs/*.json; do
      [ -f "$f" ] && [ "$(jq -r .commit "$f")" = "$commit" ] && files+=("$f")
    done
    [ ${#files[@]} -gt 0 ] || die "no runs recorded at $commit under $OUT/runs/"
    jq -s --arg commit "$commit" --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
      sort_by(.date)
      | {format: 1, commit: $commit, main_base: .[0].main_base, app_lib_tree: .[0].app_lib_tree,
         collected: $at, host: .[0].host,
         device: ([.[] | .device | select(. != null) | del(.serial)] | first),
         records: (group_by(.script) | map({key: .[0].script, value: .}) | from_entries)}' "${files[@]}"
    ;;
  *) die "unknown option '$1'; none, --against <baseline>, --runs <baseline> or --collect [<commit>]" ;;
esac
