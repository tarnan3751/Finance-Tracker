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
#                 l10n.yaml), build_runner build (packages with build_runner), and for a
#                 package with drift_schemas/ the Drift schema dump of its one
#                 @DriftDatabase file and the schema test helpers in test/drift/generated/
#                 (drift_dev schema dump, schema generate); then git diff --exit-code on the
#                 package, and no untracked file in it (git status --porcelain), so a newly
#                 generated file is caught too
#   6. tests      flutter test (Flutter packages) or dart test (pure Dart packages), each
#                 package under a ceiling of FT_TEST_TIMEOUT seconds (by default 1500 scaled
#                 by the one-minute load at the gate's start, 1500 x max(1, min(2, load / 6)),
#                 through tools/with_ceiling.sh): past it, the package's test processes are
#                 killed and the package fails as timed out; the summary line gives each
#                 package's duration, then the ceiling and the load
#   7. contract   tools/check_contract.sh, once it exists (Phase 2): the OpenAPI document
#                 passes the structural check and the generated client is current (the
#                 fakes and the server are checked against it by their own tests)
#   8. strings    dart run tools/check_strings.dart: no prose string literal in the app's
#                 presentation code outside the ARB and tools/check_strings_allowlist.txt,
#                 every template key described and its placeholders typed, no other locale
#                 with a key or a placeholder the template lacks, no join of text pieces
#                 in code, and the pseudo-locale current with the template; prints each
#                 translated locale's untranslated count, which never fails it
#   9. commits    tools/check_commits.sh origin/main: the messages of the commits beyond
#                 origin/main have the shape the map requires, as tools/land_series.sh
#                 checks at landing; skipped on a detached HEAD (CI's pull request
#                 checkout), with no origin/main, or outside a git checkout
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
  echo "gates: FT_TEST_TIMEOUT must be a whole number of seconds, not '$TEST_TIMEOUT'" >&2
  exit 2
fi
CEILING="$(pwd)/tools/with_ceiling.sh"
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
has_drift_schemas() { [ -d "$1/drift_schemas" ]; }

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
  has_build_runner "$p" || has_l10n "$p" || has_drift_schemas "$p" || continue
  gen=$((gen + 1))
  if has_l10n "$p"; then
    (cd "$p" && $FLUTTER gen-l10n) >"$scratch/codegen-one.txt" 2>&1 || { stale=$((stale + 1)); { echo "== $p (gen-l10n failed)"; cat "$scratch/codegen-one.txt"; } >>"$scratch/codegen.txt"; continue; }
  fi
  if has_build_runner "$p"; then
    (cd "$p" && $DART run build_runner build) >"$scratch/codegen-one.txt" 2>&1 || { stale=$((stale + 1)); { echo "== $p (build_runner failed)"; cat "$scratch/codegen-one.txt"; } >>"$scratch/codegen.txt"; continue; }
  fi
  if has_drift_schemas "$p"; then
    # The schema of the current schemaVersion, dumped from the package's one @DriftDatabase
    # file, and the migration test's helpers generated from every dump (data.md).
    databases="$(cd "$p" && grep -rl --include='*.dart' '^@DriftDatabase' lib)"
    if [ "$(printf '%s\n' "$databases" | grep -c .)" -ne 1 ]; then
      stale=$((stale + 1)); echo "== $p: drift_schemas/ needs exactly one @DriftDatabase file under lib/, found: ${databases:-none}" >>"$scratch/codegen.txt"; continue
    fi
    (cd "$p" && $DART run drift_dev schema dump "$databases" drift_schemas/ && $DART run drift_dev schema generate drift_schemas/ test/drift/generated/) >"$scratch/codegen-one.txt" 2>&1 || { stale=$((stale + 1)); { echo "== $p (drift schema dump or generate failed)"; cat "$scratch/codegen-one.txt"; } >>"$scratch/codegen.txt"; continue; }
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
# The report keeps the last 200 lines, so the packages that passed come first and the
# ones that failed last, each failed one led by its failing tests ("[E]" lines and the
# "Failing tests:" block), so a failure is never cut off by a later package's output.
# The summary line gives each package's duration, so a timeout under load is attributable.
# A package past FT_TEST_TIMEOUT has its test processes killed and fails as timed out.
: >"$scratch/tests-ok.txt"; : >"$scratch/tests-bad.txt"; bad=0; ran=0; durations=""
for p in "${packages[@]}"; do
  [ -d "$p/test" ] || continue
  ran=$((ran + 1)); one_status=0; one_started=$SECONDS
  if is_flutter "$p"; then
    (cd "$p" && "$CEILING" "$TEST_TIMEOUT" $FLUTTER test --no-pub) >"$scratch/tests-one.txt" 2>&1 || one_status=$?
  else
    (cd "$p" && "$CEILING" "$TEST_TIMEOUT" $DART test) >"$scratch/tests-one.txt" 2>&1 || one_status=$?
  fi
  durations="${durations:+$durations, }$p $((SECONDS - one_started))s"
  [ $one_status -eq 124 ] && durations="$durations (timed out)"
  if [ $one_status -eq 0 ]; then
    { echo "== $p"; tail -40 "$scratch/tests-one.txt"; } >>"$scratch/tests-ok.txt"
  else
    bad=$((bad + 1))
    {
      if [ $one_status -eq 124 ]; then
        echo "== $p FAILED: timed out after ${TEST_TIMEOUT}s (FT_TEST_TIMEOUT); its test processes were killed"
      else
        echo "== $p FAILED"
      fi
      # The compact reporter marks a failure "[E]"; the GitHub reporter CI gets with
      # GITHUB_ACTIONS set marks it with a cross and "::error" lines.
      { grep -E '\[E\]|^Failing tests:|^  /|Expected:|Actual:|TimeoutException|❌|::error' \
        "$scratch/tests-one.txt" || true; } | tail -60
      echo "-- last 40 lines"
      tail -40 "$scratch/tests-one.txt"
    } >>"$scratch/tests-bad.txt"
  fi
done
cat "$scratch/tests-ok.txt" "$scratch/tests-bad.txt" >"$scratch/tests.txt"
if [ $ran -eq 0 ]; then
  report tests FAILED "no package has a test/ directory" "$scratch/tests.txt"
elif [ $bad -eq 0 ]; then
  report tests ok "$ran package(s): $durations) ($ceiling"
else
  report tests FAILED "$bad of $ran packages; $durations) ($ceiling" "$scratch/tests.txt"
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

# 8. Strings ----------------------------------------------------------------------------
if [ -f tools/check_strings.dart ]; then
  if $DART run tools/check_strings.dart >"$scratch/strings.txt" 2>&1; then
    report strings ok "$(grep -E 'untranslated|current' "$scratch/strings.txt" | sed 's/^strings: app\/lib\/l10n\///; s/ keys untranslated (shown in English)/ untranslated/' | paste -sd ';' -)"
  else
    report strings FAILED "dart run tools/check_strings.dart" "$scratch/strings.txt"
  fi
else
  report strings ok "no strings checker yet"
fi

# 9. Commit messages ---------------------------------------------------------------------
if ! git symbolic-ref -q HEAD >/dev/null 2>&1 || ! git rev-parse -q --verify origin/main >/dev/null; then
  report commits ok "skipped: detached HEAD, no origin/main or no git checkout"
elif [ "$(git rev-list --count origin/main..HEAD)" -eq 0 ]; then
  report commits ok "no commits beyond origin/main"
elif tools/check_commits.sh origin/main >"$scratch/commits.txt" 2>&1; then
  report commits ok "$(tail -1 "$scratch/commits.txt")"
else
  report commits FAILED "tools/check_commits.sh origin/main" "$scratch/commits.txt"
fi

if [ $failed -eq 0 ]; then
  echo "gates: all passed"
else
  echo "gates: FAILED"
fi
exit $failed
