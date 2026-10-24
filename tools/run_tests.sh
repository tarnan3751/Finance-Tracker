#!/usr/bin/env bash
# Runs the test suite.
#   tools/run_tests.sh                   every package with a test/ directory
#   tools/run_tests.sh app               one package (app, server, packages/<name>, or . before Phase 0)
#   tools/run_tests.sh app "Money"       one package, tests whose name contains the text
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

is_flutter() { grep -qE '^\s+flutter:\s*$|sdk:\s*flutter' "$1/pubspec.yaml"; }

run_one() {
  local p="$1" name="${2:-}"
  [ -f "$p/pubspec.yaml" ] || { echo "run_tests: no package at $p" >&2; return 2; }
  [ -d "$p/test" ] || { echo "run_tests: $p has no test/ directory" >&2; return 2; }
  echo "== $p"
  if is_flutter "$p"; then
    (cd "$p" && $FLUTTER test ${name:+--name "$name"})
  else
    (cd "$p" && $DART test ${name:+--name "$name"})
  fi
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
