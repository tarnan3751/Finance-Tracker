#!/usr/bin/env bash
# The gate's contract step (tools/gates.sh, step 7; docs/reference/api.md, **The structural
# check**). Two checks, both without Java:
#   1. structure  dart run contract_test:check_openapi api/openapi.yaml: the document
#                 parses, is OpenAPI 3.0.x, every operation has a unique operationId, a
#                 summary and a success response, errors are problem details, every $ref
#                 resolves, every amount is Money, security and closed request bodies are
#                 as decided
#   2. client     the SHA-256 of api/openapi.yaml equals
#                 packages/api_client/.openapi-source.sha256, the hash
#                 tools/gen_api_client.sh recorded when it last generated the client
# Request and response bodies are checked against the contract by the server's and the
# fakes' own tests through packages/contract_test, not here. Prints each failure and exits
# non-zero; on success the last line is the summary the gate prints. Uses `fvm dart` when
# .fvmrc exists and fvm is installed. Writes .dart_tool/ like any dart run; never touches a
# device, the dev server or Plaid Sandbox.
set -uo pipefail

cd "$(dirname "$0")/.."

if [ -f .fvmrc ] && command -v fvm >/dev/null 2>&1; then
  DART="fvm dart"
else
  DART="dart"
fi

spec=api/openapi.yaml
recorded=packages/api_client/.openapi-source.sha256
failed=0

if ! structure="$(cd packages/contract_test && $DART run contract_test:check_openapi "../../$spec" 2>&1)"; then
  echo "$structure"
  failed=1
fi

actual="$(shasum -a 256 "$spec" | cut -d' ' -f1)"
if [ "$(cat "$recorded" 2>/dev/null)" != "$actual" ]; then
  echo "the generated client is stale: run tools/gen_api_client.sh"
  failed=1
fi

if [ $failed -ne 0 ]; then
  exit 1
fi
summary="$(echo "$structure" | tail -1)"
echo "contract ok: ${summary#openapi ok: }, client current"
