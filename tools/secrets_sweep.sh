#!/usr/bin/env bash
# The release-hardening sweep (docs/reference/testing-tools.md, **The secrets sweep**;
# PLAN.md §12 "Release hardening"). Reads files only: it never touches a device.
#
#   tools/secrets_sweep.sh [<logcat-capture>]
#   tools/secrets_sweep.sh --self-test
#
# --self-test runs the logcat check on two captures it writes to a temporary directory:
# a clean one (a Dart stack frame, an API path, a long snake_case name, a count) must
# pass, and each line of a dirty one (one per pattern) must fail; exits 1 otherwise.
#
# 1. manifest   app/android/app/src/main/AndroidManifest.xml sets android:allowBackup="false",
#               android:fullBackupContent="false" and
#               android:dataExtractionRules="@xml/data_extraction_rules", and no other
#               source set's manifest (debug, profile, a flavor's) sets allowBackup to true
# 2. rules      res/xml/data_extraction_rules.xml excludes domain="root" path="." from
#               <cloud-backup> and <device-transfer>, and has no <cross-platform-transfer>
#               (an opt-in to transfers with a named iOS app, which this app has none of)
# 3. logcat     with a capture file (`adb logcat -d` of the app's process), no line holds a
#               bearer token, a JWT (`eyJ...` with a dot after it), a Plaid access, public or
#               link token (`access-`, `public-`, `link-` with sandbox, development or
#               production), a refresh token or base64 key (a run of 40 or more base64url or
#               base64 characters holding an uppercase letter, a lowercase letter and a
#               digit), a hex database key (`x'` and 16 or more hex digits) or an email
#               address; a hit prints its pattern's name and line number, never the text
# Then prints the `adb backup` steps for the coordinator, who runs them on the harness AVD
# (agents never attach devices). Prints one line per check and exits 1 when any fails.
set -uo pipefail

cd "$(dirname "$0")/.."

if [ "${1:-}" = "--self-test" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  cat >"$tmp/clean.txt" <<'CLEAN'
I flutter: #3 package:finance_tracker/core/sync/sync_controller.dart:120:7
I flutter: INFO api: GET /v1/transactions/recurring-streams/overrides 200
I flutter: INFO sync: held 2 records of recurring_stream_override_with_a_long_entity_name_v2
I flutter: INFO sync: pushed 3 changes, pulled 12 in 2 pages
CLEAN
  cat >"$tmp/dirty.txt" <<'DIRTY'
I flutter: Authorization: Bearer abc.def
I flutter: token eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1In0.c2ln
I flutter: item access-sandbox-de3ce8ef-33f8-452c-a685-8671031fc0f6
I flutter: public-sandbox-0b2f6a3c-1d2e-4f5a-8b9c-0d1e2f3a4b5c
I flutter: refresh Zm9vYmFyYmF6cXV4MTIzNDU2Nzg5MGFiY2RlZmdoaWpr_-AB
I flutter: key n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=
I flutter: PRAGMA key = "x'9f86d081884c7d659a2feaa0c55ad015'"
I flutter: signed in as a.b@example.com
DIRTY
  rc=0
  # The output is read whole: grep -q would end the pipe early under pipefail.
  if ! grep -q '^sweep logcat ok$' <<<"$("$0" "$tmp/clean.txt")"; then
    echo "self-test FAILED: the clean capture did not pass"
    rc=1
  fi
  for line in 1 2 3 4 5 6 7 8; do
    sed -n "${line}p" "$tmp/dirty.txt" >"$tmp/one.txt"
    if grep -q '^sweep logcat ok$' <<<"$("$0" "$tmp/one.txt")"; then
      echo "self-test FAILED: dirty line $line passed"
      rc=1
    fi
  done
  [ $rc -eq 0 ] && echo "self-test: all passed"
  exit $rc
fi

main_dir="app/android/app/src/main"
manifest="$main_dir/AndroidManifest.xml"
rules="$main_dir/res/xml/data_extraction_rules.xml"
failed=0

ok() { echo "sweep $1 ok"; }
fail() { echo "sweep $1 FAILED: $2"; failed=1; }

# 1. The manifest attributes.
problems=""
for attr in 'android:allowBackup="false"' 'android:fullBackupContent="false"' \
  'android:dataExtractionRules="@xml/data_extraction_rules"'; do
  grep -qF "$attr" "$manifest" || problems="$problems; missing $attr"
done
for other in app/android/app/src/*/AndroidManifest.xml; do
  [ "$other" = "$manifest" ] && continue
  if grep -q 'android:allowBackup="true"' "$other"; then
    problems="$problems; $other sets allowBackup true"
  fi
done
if [ -z "$problems" ]; then ok manifest; else fail manifest "${problems#; }"; fi

# 2. The exclude rules, each section read on one line.
flat="$(tr -s '[:space:]' ' ' < "$rules")"
problems=""
for section in 'cloud-backup' 'device-transfer'; do
  if ! printf '%s' "$flat" |
    grep -qE "<$section> ?<exclude domain=\"root\" path=\"\.\" ?/> ?</$section>"; then
    problems="$problems; <$section> does not exclude everything"
  fi
done
if printf '%s' "$flat" | grep -q '<cross-platform-transfer'; then
  problems="$problems; <cross-platform-transfer> is present"
fi
if [ -z "$problems" ]; then ok rules; else fail rules "${problems#; }"; fi

# 3. The logcat capture.
if [ $# -ge 1 ]; then
  capture="$1"
  if [ ! -r "$capture" ]; then
    fail logcat "cannot read $capture"
  else
    hits=""
    check() {
      local name="$1" pattern="$2" lines
      lines="$(grep -nE -- "$pattern" "$capture" | cut -d: -f1 | head -20 | tr '\n' ' ')"
      [ -n "$lines" ] && hits="$hits; $name at line(s) ${lines% }"
    }
    check bearer '[Bb]earer[[:space:]]+[^[:space:]]'
    check jwt 'eyJ[A-Za-z0-9_=-]{8,}\.[A-Za-z0-9_=-]'
    check plaid-token '(access|public|link)-(sandbox|development|production)-'
    check hex-key "x'[0-9A-Fa-f]{16,}"
    check email '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
    # A run of 40 or more base64url or base64 characters counts only when it holds an
    # uppercase letter, a lowercase letter and a digit, as a random token or key does and
    # a stack frame, an API path or a snake_case name does not.
    lines="$(grep -noE -- '[A-Za-z0-9_-]{40,}|[A-Za-z0-9+/]{40,}' "$capture" |
      awk -F: '$2 ~ /[A-Z]/ && $2 ~ /[a-z]/ && $2 ~ /[0-9]/ { print $1 }' |
      sort -un | head -20 | tr '\n' ' ')"
    [ -n "$lines" ] && hits="$hits; refresh-token-or-base64-key at line(s) ${lines% }"
    if [ -z "$hits" ]; then ok logcat; else fail logcat "${hits#; }"; fi
  fi
else
  echo "sweep logcat skipped (no capture file given)"
fi

cat <<'STEPS'

For the coordinator, on the harness AVD (agents never attach devices):
  1. Install a debug build and use it (sign in, link a bank, sync, unlock), then capture
     the app's own log while it runs:
       adb -s <serial> logcat -d --pid="$(adb -s <serial> shell pidof -s <package>)" > capture.txt
       tools/secrets_sweep.sh capture.txt
  2. Back the app up and list the archive; expect no file of the app's in it:
       adb -s <serial> backup -noapk <package> -f app.ab     (confirm on the device)
       dd if=app.ab bs=24 skip=1 2>/dev/null | python3 -c 'import sys,zlib; sys.stdout.buffer.write(zlib.decompress(sys.stdin.buffer.read()))' | tar -tv
  3. adb -s <serial> shell dumpsys backup | grep -i <package>   (expect no backup data)
STEPS

if [ "$failed" -ne 0 ]; then
  echo "secrets sweep: FAILED"
  exit 1
fi
echo "secrets sweep: all passed"
