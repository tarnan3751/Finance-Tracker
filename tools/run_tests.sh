#!/usr/bin/env bash
# Runs the test suite.
#   tools/run_tests.sh                   every package with a test/ directory
#   tools/run_tests.sh app               one package (app, server, packages/<name>, or . before Phase 0)
#   tools/run_tests.sh app "Money"       one package, tests whose name contains the text
# Each package's tests run under a ceiling of FT_TEST_TIMEOUT seconds (by default 1500 scaled
# by the one-minute load at the start, as the gate's, printed first; through
# tools/with_ceiling.sh); past it, the package's test processes are killed, the runner names
# the package (its output is above) and the package fails.
# Uses `fvm flutter`/`fvm dart` when .fvmrc exists and fvm is installed. Writes build/ and
# .dart_tool/ in the tree it runs in, so an agent runs it only in its clone. Never touches a
# device, the dev server, or Plaid Sandbox.
set -uo pipefail
cd "$(dirname "$0")/.."

if [ -f .fvmrc ] && command -v fvm >/dev/null 2>&1; then
  FLUTTER="fvm flutter"; DART="fvm dart"
else
  FLUTTER="flutter"; DART="dart"
fi

# The tests' ceiling: FT_TEST_TIMEOUT when set, else 1500 s scaled by the one-minute load
# read now, 1500 x max(1, min(2, load / 6)), so a gate on a busy machine is not killed for
# being slow (the load is 0 when it cannot be read).
load="$(if [ -r /proc/loadavg ]; then cut -d' ' -f1 /proc/loadavg
        else sysctl -n vm.loadavg 2>/dev/null | awk '{ print $2 }'; fi)"
[[ "$load" =~ ^[0-9]+([.][0-9]+)?$ ]] || load=0
if [ -n "${FT_TEST_TIMEOUT:-}" ]; then
  TEST_TIMEOUT="$FT_TEST_TIMEOUT"; ceiling="ceiling ${TEST_TIMEOUT}s from FT_TEST_TIMEOUT at load $load"
else
  TEST_TIMEOUT="$(awk -v l="$load" 'BEGIN { f = l / 6; if (f < 1) f = 1; if (f > 2) f = 2; printf "%d", 1500 * f + 0.5 }')"
  ceiling="ceiling ${TEST_TIMEOUT}s at load $load"
fi
if ! [[ "$TEST_TIMEOUT" =~ ^[0-9]+$ ]]; then
  echo "run_tests: FT_TEST_TIMEOUT must be a whole number of seconds, not '$TEST_TIMEOUT'" >&2
  exit 2
fi
CEILING="$(pwd)/tools/with_ceiling.sh"
echo "run_tests: $ceiling"

is_flutter() { grep -qE '^\s+flutter:\s*$|sdk:\s*flutter' "$1/pubspec.yaml"; }

run_one() {
  local p="$1" name="${2:-}"
  [ -f "$p/pubspec.yaml" ] || { echo "run_tests: no package at $p" >&2; return 2; }
  [ -d "$p/test" ] || { echo "run_tests: $p has no test/ directory" >&2; return 2; }
  echo "== $p"
  local status=0
  if is_flutter "$p"; then
    (cd "$p" && "$CEILING" "$TEST_TIMEOUT" $FLUTTER test ${name:+--name "$name"}) || status=$?
  else
    (cd "$p" && "$CEILING" "$TEST_TIMEOUT" $DART test ${name:+--name "$name"}) || status=$?
  fi
  [ $status -eq 124 ] && echo "run_tests: $p timed out after ${TEST_TIMEOUT}s (FT_TEST_TIMEOUT); its test processes were killed" >&2
  return $status
}

if [ -n "${1:-}" ]; then
  run_one "$1" "${2:-}"
  exit $?
fi

status=0
if [ -f app/pubspec.yaml ]; then
  for p in app server packages/* tools/persona_engine; do
    [ -f "$p/pubspec.yaml" ] && [ -d "$p/test" ] || continue
    run_one "$p" || status=1
  done
else
  run_one . || status=1
fi
exit $status
