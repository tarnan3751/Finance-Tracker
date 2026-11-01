# Shared by the tools/perf/ scripts (docs/reference/performance.md); sourced, never run.
# perf_init <script> moves to the repository root and picks the Flutter command;
# perf_on_harness re-runs the calling script through `tools/emulator_tests.sh run` unless it
# already runs there (FT_EMULATOR_SERIAL set), so a device measurement always holds the
# machine-wide lock on the harness's own AVD, and refuses a serial whose emulator is not an
# ft- AVD; perf_record <metrics> <detail> <notes> writes the run's JSON record, with the
# commit, the date, the host and the device, to app/build/perf/<script>.json (the latest)
# and app/build/perf/runs/<script>-<UTC stamp>.json (every run, which `report.sh --collect`
# gathers). Needs jq. Writes only under app/build/perf/.

perf_say() { echo "$PERF_SCRIPT: $*"; }
perf_die() { echo "$PERF_SCRIPT: $*" >&2; exit 1; }

perf_init() {
  PERF_SCRIPT="$1"
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
  PERF_ROOT="$(pwd)"
  PERF_OUT="$PERF_ROOT/app/build/perf"
  mkdir -p "$PERF_OUT/runs"
  command -v jq >/dev/null 2>&1 || perf_die "jq is missing (brew install jq)"
  if [ -f .fvmrc ] && command -v fvm >/dev/null 2>&1; then
    FLUTTER="fvm flutter"
  else
    FLUTTER="flutter"
  fi
  SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
  PERF_DEVICE='null'
}

# Re-executes "$@" (the script and its arguments) under the harness when it is not already
# there; afterwards SERIAL is the harness's emulator and PERF_DEVICE describes it.
perf_on_harness() {
  if [ -z "${FT_EMULATOR_SERIAL:-}" ]; then
    exec "$PERF_ROOT/tools/emulator_tests.sh" run "$@"
  fi
  SERIAL="$FT_EMULATOR_SERIAL"
  local avd
  avd="$("$SDK/platform-tools/adb" -s "$SERIAL" emu avd name 2>/dev/null | tr -d '\r' | head -1)"
  [[ "$avd" =~ ^ft-[A-Za-z0-9_-]+$ ]] || perf_die "$SERIAL is not a harness AVD (got '$avd'); run through tools/emulator_tests.sh run"
  PERF_DEVICE="$(jq -n --arg serial "$SERIAL" --arg avd "$avd" \
    --arg api "$(perf_adb shell getprop ro.build.version.sdk | tr -d '\r')" \
    --arg abi "$(perf_adb shell getprop ro.product.cpu.abi | tr -d '\r')" \
    '{serial: $serial, avd: $avd, api: ($api | tonumber? // $api), abi: $abi}')"
}

perf_adb() { "$SDK/platform-tools/adb" -s "$SERIAL" "$@"; }

perf_load() { sysctl -n vm.loadavg 2>/dev/null | awk '{ print $2 }'; }

# The median, minimum and maximum of the numbers on standard input, one per line, as JSON.
perf_stats() {
  jq -s 'sort | length as $n
    | {median: (if $n % 2 == 1 then .[($n - 1) / 2] else ((.[$n / 2 - 1] + .[$n / 2]) / 2) end),
       min: .[0], max: .[-1], n: $n}'
}

# Writes the record: <metrics> a flat JSON object of numbers (each name ends in its unit),
# <detail> any JSON, <notes> a JSON array of strings.
perf_record() {
  local metrics="$1" detail="${2:-null}" notes="${3:-[]}"
  local stamp latest run modified
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  latest="$PERF_OUT/$PERF_SCRIPT.json"
  run="$PERF_OUT/runs/$PERF_SCRIPT-$stamp.json"
  # The measured code's changes not yet committed (the scripts and tests are not counted).
  modified="$(git status --porcelain --untracked-files=no -- app/lib app/android app/assets packages server/lib pubspec.lock | wc -l | tr -d ' ')"
  jq -n \
    --arg script "$PERF_SCRIPT" \
    --arg commit "$(git rev-parse --short=7 HEAD)" \
    --arg base "$(git merge-base HEAD origin/main 2>/dev/null | cut -c1-7)" \
    --arg code "$(git rev-parse --short=12 HEAD:app/lib)" \
    --argjson modified "$modified" \
    --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg cpu "$(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m)" \
    --arg memory "$(($(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824))" \
    --arg os "$(sw_vers -productName 2>/dev/null || uname -s) $(sw_vers -productVersion 2>/dev/null || uname -r)" \
    --arg load "$(perf_load)" \
    --arg flutter "$($FLUTTER --version --machine 2>/dev/null | jq -r '.frameworkVersion // empty')" \
    --argjson device "$PERF_DEVICE" \
    --argjson metrics "$metrics" \
    --argjson detail "$detail" \
    --argjson notes "$notes" \
    '{script: $script, commit: $commit, main_base: $base, app_lib_tree: $code,
      uncommitted_code_changes: $modified, date: $date,
      host: {cpu: $cpu, memory_gb: ($memory | tonumber), os: $os, load_1m: ($load | tonumber? // null)},
      flutter: $flutter, device: $device, metrics: $metrics, notes: $notes, detail: $detail}' \
    >"$run" || perf_die "could not write the record"
  cp "$run" "$latest"
  perf_say "record: $run"
}
