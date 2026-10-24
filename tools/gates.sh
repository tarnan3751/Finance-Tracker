#!/usr/bin/env bash
# The gate: everything a change must pass before it is reported, reviewed or landed
# (CLAUDE.md, **Agent workflow**). For every Dart package in the workspace, in order:
#   1. layout     the packages the map names exist once Phase 0 has landed (app, server,
#                 packages/*); before that, the original app at the repository root
#   2. resolve    dart pub get at the root, so the package config is current: dart format
#                 reads each package's language version from it, and a stale .dart_tool left
#                 by an earlier layout would format in an older style and fail the next gate
#   3. format     dart format --output=none --set-exit-if-changed
#   4. analyze    flutter analyze then dart analyze --fatal-infos (Flutter packages: flutter
#                 analyze does not report analyzer-plugin diagnostics such as riverpod_lint's),
#                 or dart analyze --fatal-infos (pure Dart packages)
#   5. codegen    generated files are current: flutter gen-l10n (Flutter packages with an
#                 l10n.yaml) and build_runner build (packages with build_runner), then
#                 git diff --exit-code on the package, and no untracked file in it
#                 (git status --porcelain), so a newly generated file is caught too
#   6. tests      flutter test (Flutter packages) or dart test (pure Dart packages)
#   7. contract   tools/check_contract.sh, once it exists (Phase 2): the OpenAPI document
#                 validates and the fakes and the server agree with it
# Prints one line per gate, the failing gate's output in full, and exits non-zero when any
# gate fails. Uses `fvm flutter`/`fvm dart` when .fvmrc exists and fvm is installed, else the
# bare commands. Every Flutter or Dart run writes build/ and .dart_tool/ in the tree it runs
# in, which is why the gate runs only in a lane's clone, never in the coordinator's main tree
# by an agent. The gate never touches a device, the dev server, or Plaid Sandbox.
set -uo pipefail

cd "$(dirname "$0")/.."

if [ -f .fvmrc ] && command -v fvm >/dev/null 2>&1; then
  FLUTTER="fvm flutter"; DART="fvm dart"
else
  FLUTTER="flutter"; DART="dart"
fi
if ! command -v "${FLUTTER%% *}" >/dev/null 2>&1; then
  echo "Flutter not found. Install Flutter (brew install --cask flutter) or fvm." >&2
  exit 2
fi

scratch="$(mktemp -d "${TMPDIR:-/tmp}/finance-tracker-gates.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
failed=0

# report <name> <status> <detail> [<output-file>]
report() {
  local name="$1" status="$2" detail="$3" output="${4:-}"
  printf 'gate %-9s %s%s\n' "$name" "$status" "${detail:+ ($detail)}"
  if [ "$status" != "ok" ]; then
    failed=1
    if [ -n "$output" ] && [ -s "$output" ]; then
      sed 's/^/    /' "$output" | tail -200
    fi
  fi
}

# Which packages exist. Before Phase 0 the app is the repository root.
packages=()
if [ -f app/pubspec.yaml ]; then
  packages+=(app)
  [ -f server/pubspec.yaml ] && packages+=(server)
  for p in packages/*/pubspec.yaml; do [ -f "$p" ] && packages+=("$(dirname "$p")"); done
  [ -f tools/persona_engine/pubspec.yaml ] && packages+=(tools/persona_engine)
  layout_detail="${packages[*]}"
  layout_status=ok
  for required in app server packages/shared_models packages/api_client; do
    [ -f "$required/pubspec.yaml" ] || { layout_status=FAILED; layout_detail="missing $required"; }
  done
  echo "$layout_detail" >"$scratch/layout.txt"
  report layout "$layout_status" "$layout_detail" "$scratch/layout.txt"
elif [ -f pubspec.yaml ]; then
  packages+=(.)
  report layout ok "original app at the root (Phase 0 has not landed)"
else
  echo "no pubspec.yaml at the root or under app/" >"$scratch/layout.txt"
  report layout FAILED "no Dart package found" "$scratch/layout.txt"
  echo "gates: FAILED"; exit 1
fi

is_flutter() { grep -qE '^\s+flutter:\s*$|sdk:\s*flutter' "$1/pubspec.yaml"; }
has_build_runner() { grep -qE '^\s+build_runner:' "$1/pubspec.yaml"; }
has_l10n() { [ -f "$1/l10n.yaml" ] && is_flutter "$1"; }

# 2. Resolve -------------------------------------------------------------------------
if $DART pub get >"$scratch/resolve.txt" 2>&1; then
  report resolve ok ""
else
  report resolve FAILED "dart pub get at the root" "$scratch/resolve.txt"
fi

# 3. Format --------------------------------------------------------------------------
: >"$scratch/format.txt"
for p in "${packages[@]}"; do
  (cd "$p" && $DART format --output=none --set-exit-if-changed . ) >>"$scratch/format.txt" 2>&1 || echo "== $p" >>"$scratch/format.txt"
done
if ! grep -q '^== ' "$scratch/format.txt"; then
  report format ok ""
else
  report format FAILED "run dart format ." "$scratch/format.txt"
fi

# 4. Analyze -------------------------------------------------------------------------
: >"$scratch/analyze.txt"; bad=0
for p in "${packages[@]}"; do
  if is_flutter "$p"; then
    (cd "$p" && $FLUTTER pub get >/dev/null 2>&1; $FLUTTER analyze --no-pub && $DART analyze --fatal-infos) >"$scratch/analyze-one.txt" 2>&1 || bad=$((bad + 1))
  else
    (cd "$p" && $DART pub get >/dev/null 2>&1; $DART analyze --fatal-infos) >"$scratch/analyze-one.txt" 2>&1 || bad=$((bad + 1))
  fi
  { echo "== $p"; cat "$scratch/analyze-one.txt"; } >>"$scratch/analyze.txt"
done
if [ $bad -eq 0 ]; then
  report analyze ok "${#packages[@]} package(s)"
else
  report analyze FAILED "$bad of ${#packages[@]} packages" "$scratch/analyze.txt"
fi

# 5. Generated code is current ----------------------------------------------------------
: >"$scratch/codegen.txt"; gen=0; stale=0
for p in "${packages[@]}"; do
  has_build_runner "$p" || has_l10n "$p" || continue
  gen=$((gen + 1))
  if has_l10n "$p"; then
    (cd "$p" && $FLUTTER gen-l10n) >"$scratch/codegen-one.txt" 2>&1 || { stale=$((stale + 1)); { echo "== $p (gen-l10n failed)"; cat "$scratch/codegen-one.txt"; } >>"$scratch/codegen.txt"; continue; }
  fi
  if has_build_runner "$p"; then
    (cd "$p" && $DART run build_runner build --delete-conflicting-outputs) >"$scratch/codegen-one.txt" 2>&1 || { stale=$((stale + 1)); { echo "== $p (build_runner failed)"; cat "$scratch/codegen-one.txt"; } >>"$scratch/codegen.txt"; continue; }
  fi
  untracked="$(git status --porcelain --untracked-files=all -- "$p" | grep '^??')"
  if ! git diff --exit-code --stat -- "$p" >>"$scratch/codegen.txt" 2>&1; then
    stale=$((stale + 1)); echo "== $p has stale generated files (diff above)" >>"$scratch/codegen.txt"
  elif [ -n "$untracked" ]; then
    stale=$((stale + 1)); { echo "$untracked"; echo "== $p has untracked files (above): generated files not committed"; } >>"$scratch/codegen.txt"
  fi
done
if [ $gen -eq 0 ]; then
  report codegen ok "no package generates code yet"
elif [ $stale -eq 0 ]; then
  report codegen ok "$gen package(s) current"
else
  report codegen FAILED "$stale of $gen packages stale" "$scratch/codegen.txt"
fi

# 6. Tests ---------------------------------------------------------------------------
: >"$scratch/tests.txt"; bad=0; ran=0
for p in "${packages[@]}"; do
  [ -d "$p/test" ] || continue
  ran=$((ran + 1))
  if is_flutter "$p"; then
    (cd "$p" && $FLUTTER test --no-pub) >"$scratch/tests-one.txt" 2>&1 || bad=$((bad + 1))
  else
    (cd "$p" && $DART test) >"$scratch/tests-one.txt" 2>&1 || bad=$((bad + 1))
  fi
  { echo "== $p"; tail -40 "$scratch/tests-one.txt"; } >>"$scratch/tests.txt"
done
if [ $ran -eq 0 ]; then
  report tests FAILED "no package has a test/ directory" "$scratch/tests.txt"
elif [ $bad -eq 0 ]; then
  report tests ok "$ran package(s)"
else
  report tests FAILED "$bad of $ran packages" "$scratch/tests.txt"
fi

# 7. Contract (Phase 2) -----------------------------------------------------------------
if [ -x tools/check_contract.sh ]; then
  if tools/check_contract.sh >"$scratch/contract.txt" 2>&1; then
    report contract ok "$(tail -1 "$scratch/contract.txt")"
  else
    report contract FAILED "" "$scratch/contract.txt"
  fi
else
  report contract ok "no contract checker yet"
fi

if [ $failed -eq 0 ]; then
  echo "gates: all passed"
else
  echo "gates: FAILED"
fi
exit $failed
