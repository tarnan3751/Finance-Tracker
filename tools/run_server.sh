#!/usr/bin/env bash
# Starts the development server with one command (docs/reference/server.md, **Running
# it**). The first run creates server/.env from server/.env.example with a random
# JWT_SECRET, TOKEN_ENCRYPTION_KEY and SEED_USER_PASSWORD and the seed user
# dev@financetracker.test, and says so; it never prints a secret. Then it runs
# `dart run bin/server.dart` in server/, which reads server/.env, migrates and seeds the
# database under server/data/ and serves on 127.0.0.1:8080. Stop it with Ctrl-C.
# Writes server/.env (gitignored) and server/data/ (gitignored); never touches a device.
# The server's Plaid mode is fake in Phase 2: it calls no Plaid API.
set -euo pipefail

cd "$(dirname "$0")/../server"

if [ -f ../.fvmrc ] && command -v fvm >/dev/null 2>&1; then
  DART="fvm dart"
else
  DART="dart"
fi

if [ ! -f .env ]; then
  random() { openssl rand -base64 "$1" | tr -d '\n'; }
  umask 077
  sed \
    -e "s|^JWT_SECRET=$|JWT_SECRET=$(random 32)|" \
    -e "s|^TOKEN_ENCRYPTION_KEY=$|TOKEN_ENCRYPTION_KEY=$(random 32)|" \
    -e "s|^SEED_USER_EMAIL=$|SEED_USER_EMAIL=dev@financetracker.test|" \
    -e "s|^SEED_USER_PASSWORD=$|SEED_USER_PASSWORD=$(random 18 | tr '+/' '-_')|" \
    .env.example >.env
  echo "Created server/.env with a random JWT_SECRET, TOKEN_ENCRYPTION_KEY and seed-user"
  echo "password (dev@financetracker.test; the password is SEED_USER_PASSWORD in server/.env)."
fi

exec $DART run bin/server.dart
