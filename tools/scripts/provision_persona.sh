#!/usr/bin/env bash
# Provisions one of the persona engine's personas into Plaid Sandbox through the
# development server's provisioning job (docs/reference/server.md, **Provisioning**):
#   tools/scripts/provision_persona.sh <renter|family|student|small_business>
#       [--seed N] [--days D] [--server URL]
# Signs in as the seed user (SEED_USER_EMAIL and SEED_USER_PASSWORD from the environment,
# else from server/.env, read here and nowhere else), POSTs /sandbox/provision, then
# polls the job every 5 s, printing its progress when it changes, and exits 0 when it
# completes, 1 when it fails (printing its error) or a request fails or gets no answer,
# 2 on a usage error. The server defaults to http://localhost:8080/v1. On the owner's
# machine the server runs in sandbox mode and this creates real Sandbox Items (the
# coordinator's seat only); in a lane, point it at a fake-mode server started with
# tools/run_server.sh, whose .env is generated. A full persona takes up to about 100
# minutes, paced by the server.
#
# The script signs out only when the job has finished (completed or failed) or never
# started. On Ctrl-C, and on any failure after the job started, the device stays signed
# in, because the job links its Items through it; Ctrl-C stops the polling, not the job.
#
# Never prints or traces a token or a password: tracing is off (set +x), and they reach
# curl and jq only through pipes and files in a private temporary directory, never as an
# argument or a shell variable. Needs curl and jq. Writes only that directory, removed
# on exit.
set -euo pipefail
set +x

usage() {
  echo "usage: tools/scripts/provision_persona.sh <renter|family|student|small_business> [--seed N] [--days D] [--server URL]" >&2
  exit 2
}

persona=""
seed=1
days=730
server="http://localhost:8080/v1"
while [ $# -gt 0 ]; do
  case "$1" in
    --seed) [ $# -ge 2 ] || usage; seed="$2"; shift 2 ;;
    --days) [ $# -ge 2 ] || usage; days="$2"; shift 2 ;;
    --server) [ $# -ge 2 ] || usage; server="${2%/}"; shift 2 ;;
    -h | --help) usage ;;
    -*) usage ;;
    *) [ -z "$persona" ] || usage; persona="$1"; shift ;;
  esac
done
case "$persona" in
  renter | family | student | small_business) ;;
  *) usage ;;
esac
case "$seed$days" in
  *[!0-9]*) usage ;;
esac

for tool in curl jq; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "provision_persona: $tool is required" >&2
    exit 1
  }
done

cd "$(dirname "$0")/../.."

env_value() {
  [ -f server/.env ] || return 0
  grep -E "^$1=" server/.env | tail -n 1 | cut -d= -f2- || true
}

# The seed user's password on stdout, from the environment or server/.env; it never
# passes through a shell variable or an argument, so nothing can trace it.
password() {
  if printenv SEED_USER_PASSWORD | grep -q .; then
    printenv SEED_USER_PASSWORD
  else
    env_value SEED_USER_PASSWORD
  fi
}

email="${SEED_USER_EMAIL:-$(env_value SEED_USER_EMAIL)}"
if [ -z "$email" ] || ! password | grep -q .; then
  echo "provision_persona: no seed user (SEED_USER_EMAIL and SEED_USER_PASSWORD, or server/.env)" >&2
  exit 1
fi

umask 077
work="$(mktemp -d)"
signed_in=0
finished=0
job_id=""
cleanup() {
  # Sign out only when the job has finished or never started: a running job links its
  # Items through this device.
  if [ "$signed_in" = 1 ] && { [ -z "$job_id" ] || [ "$finished" = 1 ]; }; then
    jq '{refresh_token: .refresh_token}' "$work/tokens.json" >"$work/request" || true
    curl -sS -o /dev/null -X POST -H @"$work/auth" -H 'content-type: application/json' \
      --data-binary @"$work/request" "$server/auth/logout" || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT
trap 'echo; echo "provision_persona: stopped polling; job ${job_id:-?} keeps running on the server" >&2; exit 130' INT

# Calls `method path`, with $work/request as the JSON body when [body] is given and the
# stored bearer token; leaves the answer in $work/body and its status in $status. No
# answer at all (curl failing) ends the script with exit 1.
call() {
  local method="$1" path="$2" data=()
  if [ "${3:-}" = body ]; then
    data=(--data-binary @"$work/request" -H 'content-type: application/json')
  fi
  status="$(curl -sS -o "$work/body" -w '%{http_code}' -X "$method" \
    ${data[@]+"${data[@]}"} -H @"$work/auth" "$server$path")" || {
    echo "provision_persona: no answer from $server for $method $path" >&2
    exit 1
  }
}

# A non-2xx answer: its problem code and detail (problem bodies carry no secrets).
fail_with() {
  echo "provision_persona: $1 answered $2: $(jq -r '[.code, .detail] | map(select(.)) | join(": ")' "$work/body" 2>/dev/null || echo '?')" >&2
  exit 1
}

# Keeps the token pair just answered and writes the bearer header from it, all inside jq.
store_tokens() {
  cp "$work/body" "$work/tokens.json"
  jq -r '"Authorization: Bearer \(.access_token)"' "$work/tokens.json" >"$work/auth"
}

: >"$work/auth"
password | jq -Rn --arg email "$email" \
  '{email: $email, password: input, device_name: "provision_persona.sh"}' >"$work/request"
call POST /auth/login body
rm -f "$work/request"
[ "$status" = 200 ] || fail_with "login" "$status"
store_tokens
signed_in=1

refresh() {
  jq '{refresh_token: .refresh_token}' "$work/tokens.json" >"$work/request"
  call POST /auth/refresh body
  [ "$status" = 200 ] || fail_with "refresh" "$status"
  store_tokens
}

jq -n --arg persona "$persona" --argjson seed "$seed" --argjson days "$days" \
  '{persona: $persona, seed: $seed, days: $days}' >"$work/request"
call POST /sandbox/provision body
[ "$status" = 202 ] || fail_with "provision" "$status"
job_id="$(jq -r .id "$work/body")"
echo "provision_persona: job $job_id: $persona, seed $seed, $days days"

while true; do
  call GET "/sandbox/provision/$job_id"
  if [ "$status" = 401 ] && [ "$(jq -r .code "$work/body")" = token_expired ]; then
    refresh
    continue
  fi
  [ "$status" = 200 ] || fail_with "job $job_id" "$status"
  line="$(jq -r '"\(.status)  items \(.progress.items_linked)/\(.progress.items_total)  batches \(.progress.batches_sent)/\(.progress.batches_total)  skipped \(.progress.skipped)"' "$work/body")"
  [ "$line" = "${last_line:-}" ] || echo "$line"
  last_line="$line"
  case "$(jq -r .status "$work/body")" in
    completed)
      finished=1
      echo "provision_persona: completed; Items $(jq -r '.item_ids | join(", ")' "$work/body")"
      exit 0
      ;;
    failed)
      finished=1
      echo "provision_persona: failed: $(jq -r .error "$work/body")" >&2
      exit 1
      ;;
  esac
  sleep 5
done
