#!/usr/bin/env bash
# Checks that an APK is signed with the release key (docs/reference/testing-tools.md,
# **Cutting a release**): `apksigner verify --print-certs` must succeed and report exactly
# one signer whose certificate SHA-256 equals tools/release/expected_cert_sha256.txt. The
# release workflow runs it before publishing, so a build that fell back to the debug key
# (a missing secret) can never be released; it runs locally too.
#   tools/release/check_signature.sh <apk>
# apksigner is the newest under $ANDROID_HOME/build-tools (or $ANDROID_SDK_ROOT, or
# ~/Library/Android/sdk). Prints the fingerprint it found; exits 1 on a mismatch, 2 on a
# usage or setup error. Reads files only.
set -uo pipefail
[ $# -eq 1 ] || { echo "usage: tools/release/check_signature.sh <apk>" >&2; exit 2; }
apk="$1"
[ -f "$apk" ] || { echo "check_signature: no such file: $apk" >&2; exit 2; }
expected="$(tr -d '[:space:]' <"$(dirname "$0")/expected_cert_sha256.txt")"

sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
# The newest stable build-tools; a release-candidate directory only when nothing else exists.
version="$(ls "$sdk/build-tools" 2>/dev/null | grep -vi 'rc' | sort -V | tail -1)"
[ -n "$version" ] || version="$(ls "$sdk/build-tools" 2>/dev/null | sort -V | tail -1)"
apksigner="$sdk/build-tools/$version/apksigner"
[ -n "$version" ] && [ -x "$apksigner" ] ||
  { echo "check_signature: no apksigner under $sdk/build-tools" >&2; exit 2; }

if ! out="$("$apksigner" verify --print-certs "$apk" 2>&1)"; then
  echo "check_signature: apksigner rejected $apk:" >&2
  echo "$out" >&2
  exit 1
fi
# apksigner prints the digest as lower-case hex without separators; the expected value is
# colon-separated upper case. The signer line reads "Signer #1 certificate SHA-256 digest:" on
# most builds and "Signer (minSdkVersion=…) certificate SHA-256 digest:" on some, so match
# the digest wherever the line puts it, and count distinct certificates. On a failure print
# what apksigner said (names and digests only), so a run elsewhere can be diagnosed.
digests="$(tr -d '\r' <<<"$out" | sed -nE 's/^.*certificate SHA-256 digest:[[:space:]]*([0-9a-fA-F]{64}).*$/\1/p' | tr '[:upper:]' '[:lower:]' | sort -u)"
count="$(grep -c . <<<"$digests")"
if [ "$count" -ne 1 ]; then
  echo "check_signature FAILED: $apk has $count distinct signer certificates, expected one; apksigner said:" >&2
  echo "$out" >&2
  exit 1
fi
found="$(tr '[:lower:]' '[:upper:]' <<<"$digests" | sed 's/../&:/g; s/:$//')"
echo "signer certificate SHA-256: $found"
if [ "$found" != "$expected" ]; then
  echo "check_signature FAILED: expected $expected" >&2
  exit 1
fi
echo "check_signature ok"
