#!/usr/bin/env bash
# Generates packages/api_client from api/openapi.yaml (docs/reference/api.md, **The
# generated client**).
#   tools/gen_api_client.sh           regenerate the client in place
#   tools/gen_api_client.sh --check   generate into a temporary directory and diff it against
#                                     the committed client; exit 1 on any difference
# Needs openapi-generator 7.26.x: the Homebrew formula (`brew install openapi-generator`,
# which brings its own Java) or any command named by OPENAPI_GENERATOR, such as
# `java -jar openapi-generator-cli-7.26.0.jar` in CI. The dart-dio generator with built_value
# writes lib/ and .openapi-generator/; the files listed in
# packages/api_client/.openapi-generator-ignore (pubspec.yaml, analysis_options.yaml,
# README.md, .gitignore) are ours and never overwritten, and no tests or docs are generated.
# In place, the script first deletes the files the previous run generated (listed in
# .openapi-generator/FILES) and every lib/**/*.g.dart, so a removed schema leaves nothing
# behind; then generates, runs dart pub get, build_runner and dart format in the package,
# and writes the SHA-256 of api/openapi.yaml to packages/api_client/.openapi-source.sha256,
# which tools/check_contract.sh compares in the gate. --check compares the generator's own
# output and the hash only: *.g.dart freshness is the gate's codegen step. Writes the
# package and, through dart pub get, possibly pubspec.lock (with --check, only a temporary
# directory); never touches a device, the dev server or Plaid Sandbox.
set -euo pipefail

cd "$(dirname "$0")/.."

check=0
case "${1:-}" in
  "") ;;
  --check) check=1 ;;
  *) echo "usage: tools/gen_api_client.sh [--check]" >&2; exit 2 ;;
esac

if [ -f .fvmrc ] && command -v fvm >/dev/null 2>&1; then
  DART="fvm dart"
else
  DART="dart"
fi

read -r -a generator <<<"${OPENAPI_GENERATOR:-openapi-generator}"
if [ ${#generator[@]} -eq 0 ] || ! command -v "${generator[0]}" >/dev/null 2>&1; then
  echo "openapi-generator not found: brew install openapi-generator, or set OPENAPI_GENERATOR" >&2
  exit 2
fi
version="$("${generator[@]}" version 2>/dev/null | tail -1)"
case "$version" in
  7.26.*) ;;
  *) echo "openapi-generator 7.26.x required, found '${version}'" >&2; exit 2 ;;
esac

spec=api/openapi.yaml
package=packages/api_client
hash="$(shasum -a 256 "$spec" | cut -d' ' -f1)"

# generate <output-dir>
generate() {
  local log
  log="$(mktemp "${TMPDIR:-/tmp}/finance-tracker-openapi-generator.XXXXXX")"
  if ! "${generator[@]}" generate -g dart-dio -i "$spec" -o "$1" \
    --global-property=apiTests=false,modelTests=false,apiDocs=false,modelDocs=false \
    --additional-properties="pubName=api_client,pubLibrary=api_client,serializationLibrary=built_value,pubDescription=The Finance Tracker API client generated from api/openapi.yaml" \
    >"$log" 2>&1; then
    cat "$log" >&2; rm -f "$log"; exit 1
  fi
  rm -f "$log"
}

if [ $check -eq 1 ]; then
  scratch="$(mktemp -d "${TMPDIR:-/tmp}/finance-tracker-api-client.XXXXXX")"
  trap 'rm -rf "$scratch"' EXIT
  mkdir "$scratch/out"
  cp "$package/.openapi-generator-ignore" "$scratch/out/"
  generate "$scratch/out"
  # Outside the workspace dart format cannot read the package's language version.
  language="$(sed -nE 's/^  sdk: \^([0-9]+\.[0-9]+).*/\1/p' "$package/pubspec.yaml")"
  $DART format --language-version="$language" "$scratch/out" >/dev/null
  status=0
  diff -r -x .dart_tool -x build -x '*.g.dart' -x pubspec.yaml -x analysis_options.yaml \
    -x README.md -x .gitignore -x test -x .openapi-source.sha256 \
    "$scratch/out" "$package" || status=1
  if [ "$(cat "$package/.openapi-source.sha256" 2>/dev/null)" != "$hash" ]; then
    echo "$package/.openapi-source.sha256 does not match $spec" >&2
    status=1
  fi
  if [ $status -ne 0 ]; then
    echo "the generated client is stale: run tools/gen_api_client.sh" >&2
    exit 1
  fi
  echo "api_client current (openapi-generator $version)"
  exit 0
fi

if [ -f "$package/.openapi-generator/FILES" ]; then
  while IFS= read -r file; do
    [ -n "$file" ] && rm -f "$package/$file"
  done <"$package/.openapi-generator/FILES"
fi
find "$package/lib" -name '*.g.dart' -delete 2>/dev/null || true
generate "$package"
$DART pub get >/dev/null
(cd "$package" && $DART run build_runner build --delete-conflicting-outputs >/dev/null)
(cd "$package" && $DART format . >/dev/null)
echo "$hash" >"$package/.openapi-source.sha256"
echo "api_client generated from $spec (openapi-generator $version, sha256 ${hash:0:12})"
