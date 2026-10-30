# Server

The development server (`PLAN.md` §6.5): authentication, devices, account deletion, the
sync relay, the Plaid proxy and the Plaid-sourced data endpoints, behind the v1 contract
in `api/openapi.yaml` (`docs/reference/api.md`). Code: `server/`. Dart with shelf and
shelf_router, `sqlite3`, `cryptography` (Argon2id, AES-256-GCM), `dart_jsonwebtoken`
(access tokens, and ES256 for Plaid's webhooks), `http`, `logging` and `uuid` (`PLAN.md`
§12). It is never deployed. Its Plaid client is the fake (`PLAID_MODE=fake`: canned data
stamped `source: demo`, no keys) or the HTTP client against Plaid (`PLAID_MODE=sandbox`),
behind one interface.

## Running it

`tools/run_server.sh` is the one command. On its first run it copies
`server/.env.example` to `server/.env` (gitignored), fills `JWT_SECRET`,
`TOKEN_ENCRYPTION_KEY` and `SEED_USER_PASSWORD` with random values and sets
`SEED_USER_EMAIL=dev@financetracker.test`, and says so without printing any secret. Then
it runs `dart run bin/server.dart` in `server/`, which:

1. reads `.env` and the environment (**Configuration**); a bad configuration exits with
   status 78 and a message naming the key;
2. opens the database at `DATABASE_PATH` (default `server/data/finance_tracker.db`,
   created with its directory) and applies the migrations;
3. seeds the seed user if it does not exist (an existing user, password included, is left
   alone), printing a line that names neither the email nor the password;
4. builds the Plaid client of `PLAID_MODE` (the HTTP one against `PLAID_ENV`'s base URL,
   with the keys, which are never printed);
5. serves `/v1` on `HOST:PORT` and prints the base URL and the Plaid mode (with the
   environment in sandbox mode), plus, in fake mode, a warning that Plaid data is
   synthetic and carries `source: demo`;
6. starts the poll (**The poll scheduler**) unless `PLAID_POLL_INTERVAL_SECONDS` is 0,
   and says which.

The emulator reaches the server at `http://10.0.2.2:8080/v1`. `HOST=0.0.0.0` is only for
a physical device on the LAN. Ctrl-C stops it: the poll first (the Item in flight gets up
to ten seconds), then the server and the database. Paths in `.env` are relative to
`server/`, which is why the server runs from there.

## Configuration

`server/lib/src/config.dart`. The `.env` reader is hand-written: `KEY=VALUE` lines, `#`
comments and blank lines, no quoting and no interpolation. A malformed line is an error
that names its line number but not its content. `Platform.environment` overrides the file
key by key. An empty value counts as unset.

| Key | Default | Notes |
|---|---|---|
| `PORT` | 8080 | 1 to 65535 |
| `HOST` | `127.0.0.1` | an IP address |
| `DATABASE_PATH` | `data/finance_tracker.db` | relative to `server/` |
| `JWT_SECRET` | required | base64, at least 32 bytes |
| `JWT_SECRET_PREVIOUS` | unset | base64, at least 32 bytes; still verifies during a rotation |
| `TOKEN_ENCRYPTION_KEY` | required | base64, exactly 32 bytes |
| `PLAID_MODE` | `fake` | `fake` or `sandbox` (the HTTP client) |
| `PLAID_CLIENT_ID`, `PLAID_SECRET` | unset | required in sandbox mode, unused in fake mode; never logged |
| `PLAID_ENV` | `sandbox` | `sandbox`, `development` or `production`: the HTTP client's base URL (`https://<env>.plaid.com`); the Sandbox controls and provisioning run only when it is `sandbox` (`canDriveSandbox`), else 409 `conflict` |
| `PLAID_WEBHOOK_URL` | unset | an absolute https URL (a tunnel to `/v1/webhooks/plaid`), named as `webhook` in the Link and Sandbox public tokens the HTTP client creates afterwards |
| `PLAID_POLL_INTERVAL_SECONDS` | 180 | 0 (no polling) or 60 to 86400 |
| `SEED_USER_EMAIL`, `SEED_USER_PASSWORD` | unset | both or neither; an email address; password at least 8 characters |
| `ARGON2_MEMORY_KIB`, `ARGON2_ITERATIONS`, `ARGON2_PARALLELISM` | 19456, 2, 1 | the OWASP baseline; memory at least 8 × parallelism |
| `LOG_FORMAT` | `json` | or `text` for a terminal |

A missing or malformed required key is a `ConfigException` that names the key and never
carries its value. No secret has a default.

## Layout

| Path | What it holds |
|---|---|
| `bin/server.dart` | startup |
| `lib/server.dart` | the public surface: `ServerApp`, the config, `AppDatabase`, the Plaid client types |
| `lib/src/app.dart` | `ServerApp`: the services, the route table and the pipeline |
| `lib/src/http/` | the route type (`api_route.dart`), the middleware (`pipeline.dart`), problems (`problem.dart`), body and query reading (`wire.dart`), the rate limiter |
| `lib/src/db/` | the connection and its mutex, the migrations |
| `lib/src/auth/` | Argon2id, access tokens, the auth flows and their routes |
| `lib/src/users/` | `/me`, `/devices`, account deletion |
| `lib/src/sync/` | the change-log relay and its routes |
| `lib/src/plaid/` | `PlaidClient`, the fake and its fixtures, the HTTP client, Plaid amounts as `Money` and colours as ARGB, the number-preserving JSON decoder, the token cipher, the Item service, the proxy routes, the webhook verifier and receiver, the poll scheduler, the Sandbox controls and the provisioning job |
| `lib/src/data/` | the per-user version counter and the data routes |
| `lib/src/contract_version.dart` | the contract version `GET /health` reports |

## Request pipeline

From the outermost layer in (`lib/src/app.dart`):

1. **`requestLog`** gives every request a `RequestContext` (a uuid request id, sent back as
   `X-Request-Id`) and logs one `request` line once it is answered: method, route template
   (`/plaid/items/{item_id}`, never the concrete path), status, duration, user id and
   device id.
2. **`problemMapper`** turns every `ProblemException` into its `Problem` and every
   `ValidationException` into a `ValidationProblem`. Any other error becomes a 500
   `internal` whose `instance` is the request id. The error and its stack go to the log
   only.
3. **The router.** One route per contract operation (**Routes**). An unknown path or
   method is 404 `not_found`.
4. **Per route**: the rate limiter where it applies, then bearer authentication on every
   route except the five public ones, then the handler. The handler reads its own body:
   1 MiB at most, or 4 MiB for `pushChanges`.

Every 4xx and 5xx answer is `application/problem+json`. A 401 also carries
`WWW-Authenticate: Bearer`.

**Validation** is hand-written per request (`ObjectReader` in `wire.dart`):

- objects are closed, so an unknown key is an error, and an explicit `null` is an error
  too, since no request field is nullable in the contract;
- it checks types, `minLength` and `maxLength` (in characters), the email shape, the
  package-name and `Hlc` patterns, and the enums;
- it collects every error before answering.

`FieldError.field` is the key (`password`), a path (`entries[3].hlc`), a query
parameter's name, or the empty string for the body as a whole (not JSON, a content type
other than `application/json`, over the size limit). An oversized body is a 400,
because the contract declares no 413. The runtime does not read `openapi.yaml`.
Agreement is proven in the tests instead (**Tests**).

## Routes

`ServerApp.routes` is the route table: one `ApiRoute(operationId, method, path,
handler, authenticated:, rateLimited:)` per contract operation, with the contract's path
template. The route-coverage test holds the table equal to the document's operations in
both directions and checks each route's security against the document.

## Storage

`lib/src/db/`. One `sqlite3` connection with `foreign_keys = ON`, `busy_timeout`, and
`journal_mode = WAL` for a file. Every access goes through a FIFO mutex, because sqlite3
is synchronous but handlers await hashing and encryption between statements:

- `transaction(body)` runs `BEGIN IMMEDIATE`, the body, then `COMMIT`, or `ROLLBACK` and
  rethrows;
- `read(body)` serves queries and single statements.

Neither may be called inside the other, and no Plaid call runs while either is open.

**Migrations** (`migrations.dart`) are an append-only list of SQL strings. Entry `i` takes
the schema to version `i + 1`, applied in its own transaction and recorded in
`schema_migrations`. A rerun applies nothing. A database recording a newer version than
the server knows is refused at startup. Tests open in-memory databases through the same
migrator.

Schema v4 (v1, v2 adding three `items` columns, v3 adding `items.investments_synced_at`, v4 adding `recurring_streams.plaid_transaction_ids`). Instants are INTEGER milliseconds UTC; dates are ISO TEXT; amounts are
`*_minor` INTEGER beside a currency code; `Decimal` values are TEXT. Every row a user owns
reaches `users` through `ON DELETE CASCADE`, which a test checks for every table.

| Table | Holds |
|---|---|
| `users` | id, email (lower-cased, unique), password_hash (PHC), display_name, created_at |
| `devices` | one signed-in installation each: id, user_id, name, created_at, last_seen_at, last_sync_at |
| `refresh_tokens` | id, device_id, token_hash (SHA-256, unique), family_id, created_at, expires_at, rotated_from, revoked_at |
| `items` | the Plaid Item: plaid_item_id, the institution (and from v2 its `institution_logo` PNG and `institution_primary_color` ARGB from `/institutions/get_by_id`), products, the sealed access token and its nonce, status (`removed` for an Item unlinked with its history kept), `error_code` (v2), `cursor` and `run_start_cursor`, last_successful_sync_at, `investments_synced_at` (v3: the last successful investment-transactions fetch), `plaid_removed_at` |
| `accounts` | Plaid accounts, keyed by (item_id, plaid_account_id), with the reported balances and `source` |
| `transactions` | Plaid transactions, keyed by (item_id, plaid_transaction_id), with `source`, `sync_version` and `deleted_at`; `item_id` has no foreign key, so tombstones outlive their Item. The user's overrides (category, notes, tags, splits, receipt, `hidden`) are not stored here: they travel through the change log, and `GET /transactions` serves them empty, `hidden` as `false` |
| `recurring_streams`, `liabilities` (the contract's JSON per account and kind), `securities`, `holdings`, `investment_transactions` | the other Plaid products, each with `source`; a stream's `plaid_transaction_ids` (v4) are Plaid's `transaction_ids`, a JSON array of Plaid's ids |
| `change_log` | the sync relay's entries: global `seq` (AUTOINCREMENT), user_id, device_id, hlc, entity, operation, payload JSON, received_at; unique per (user_id, device_id, hlc) |
| `user_versions` | the per-user change counter |

## Passwords

`lib/src/auth/password_hasher.dart`. Argon2id through `cryptography`, stored as PHC
strings:

```
$argon2id$v=19$m=<KiB>,t=<iterations>,p=<lanes>$<salt>$<hash>
```

The salt and the hash are unpadded standard base64; the salt is 16 random bytes and the
hash 32. Verification reads `m`, `t` and `p` from the stored string, so a change of
parameters keeps every old hash valid. After a successful login under other parameters,
the password is rehashed under the current ones. The comparison is constant-time. A login
for an unknown email still verifies against a dummy hash, so the time it takes does not
reveal whether the email exists. Tests use `m=64, t=1, p=1` through `ServerConfig`. A
known-answer test pins the implementation to RFC 9106 §5.3.

## Tokens

**Access tokens** (`access_tokens.dart`) are HS256 JWTs.

- The header carries `kid`, the first 16 hex digits of SHA-256 of the signing key, so
  `JWT_SECRET_PREVIOUS` verifies by its own `kid` during a rotation.
- The claims are `sub` (user id), `dev` (device id), `iat`, `exp` (15 minutes) and `jti`.
- The server's clock writes `iat` and `exp` and checks `exp`.
- As a defence in depth, a token whose `iat` is more than 60 s in the future, or whose
  `exp − iat` exceeds the 15-minute lifetime by more than 60 s, is refused.
- Before the signature is checked, the header must say `alg: HS256` and carry a known
  `kid`, so the token cannot choose its algorithm.

Errors: a missing, malformed, unsigned or foreign token, or one outside those bounds, is
401 `invalid_credentials`; an expired one is 401 `token_expired`.

**Refresh tokens and devices** (`auth_service.dart`):

- Registration and every login create a device and a new refresh-token family.
- A refresh token is 32 random bytes (base64url). Only its SHA-256 is stored. It is valid
  for 30 days from issue.
- **Rotation.** `POST /auth/refresh` revokes the presented token and issues a new one in
  the same family, with `rotated_from` naming the old one.
- **Reuse detection.** Presenting a revoked token revokes the whole family, logs a
  `refresh_token_reuse` warning, and answers 401 `token_revoked`. There is no grace
  window, so a client that loses a refresh response and retries loses its session. The
  app's client must refresh single-flight.
- An unknown token is `token_revoked`; an expired one is `token_expired`.
- `logout` takes the device's own refresh token (another device's is 401
  `token_revoked`), revokes its family and removes the device.
- `DELETE /devices/{id}` revokes every family of the device and removes it; the device
  may be the caller.

**The bearer check.** Every authenticated request verifies the access token, then
requires its device to belong to its user and to hold an unrevoked, unexpired refresh
token. Otherwise the answer is 401 `token_revoked`. So logout, reuse detection, device
removal and account deletion end a device's access tokens at once, not at their expiry.
`GET /devices` lists the devices that pass the same test. `last_seen_at` is updated at
most once a minute.

## Rate limiting

`rate_limiter.dart`. A token bucket per operation and client IP on `register`, `login`
and `refreshTokens`: 10 tokens, one back every six seconds. An empty bucket answers 429
`rate_limited` with `Retry-After` in whole seconds. The IP is the socket's
(`shelf.io.connection_info`); `X-Forwarded-For` is never trusted, because nothing proxies
the dev server. The server's other routes are not limited.

## Users and devices

`lib/src/users/user_routes.dart`. `GET /me`, `GET /devices`, `DELETE /devices/{id}` (404
for another user's device), and **`DELETE /me`**:

1. Every Item not yet removed at Plaid gets `/item/remove`, up to three attempts with
   waits of 0.5 s and 1 s between them. Each success sets the Item's `plaid_removed_at`;
   so does Plaid answering `ITEM_NOT_FOUND`, which means it is removed there already.
2. If an Item still fails, the answer is 502 `plaid_error` and no user data is deleted.
   Items already removed keep their marker: they are hidden from every Item and data
   route (404 on the Item routes), and a retried `DELETE /me` skips them, so the retry
   never calls `/item/remove` twice for one Item.
3. One transaction re-checks that no Item without the marker exists (one could have
   been exchanged during the retries), and if none does, deletes the user. The cascade
   removes every row the user owns, devices and refresh tokens included, which ends every
   session. The answer is 204. An exchange still at Plaid when this happens stores
   nothing: its insert transaction finds the user gone, removes the new Item at Plaid
   (best effort) and answers 401 `token_revoked`, so no Item of the deleted user is left
   live at Plaid.
4. If an Item appeared, nothing is deleted and the deletion goes round again from step 1,
   at most three rounds in all; an Item still appearing after that is 502 `plaid_error`,
   with nothing deleted.

The app's side of these routes, the deletion screen, the local wipe after the 204 and
the devices screen, is `auth.md`, **Deleting the account and erasing this device** and
**Devices**.

## The sync relay

`lib/src/sync/change_log_relay.dart`. These are the relay rules of
`docs/reference/sync.md`, the same as `InMemorySyncRelay`'s.

**Push** handles every entry in one transaction and checks each in this order:

1. **`invalid`** when:
   - its `device_id` is not the caller's device;
   - its clock's node is not its `device_id`;
   - its payload is empty;
   - it is a delete without a valid `deleted_at` instant;
   - or, as defence in depth, its payload says `source: plaid`. Plaid data never syncs
     through the change log.
2. **`clock_drift`** when its wall time is more than the clock bound, `Hlc.maxDrift` (one
   hour), ahead of the server's clock. It is the bound the devices' clocks use: a device
   never adopts a received time more than the bound ahead of its own, and the app keeps
   a refused entry queued and shows "Check your device's clock" (`sync.md`, **The clock
   bound**). An entry behind the server's clock is never refused.
3. **Duplicates.** A resend under a stored `(user, device, hlc)` is accepted again
   without a new `seq` when its entity, operation and payload are identical. Payloads
   compare as decoded JSON, the way the engine's `jsonEquality` does: maps by key in any
   order, numbers by value, so `1` and `1.0` are the same. Anything else is rejected
   `conflicting_duplicate`.
4. Otherwise the entry is stored under the next `seq`.

The answer lists `accepted` clocks and `rejected` entries, each with its `code` and a
`reason` for logs. A structurally invalid body (a bad clock, an unknown entity type) is a
400, not a rejection.

**Pull** returns the user's entries after `since` from devices other than the caller's,
up to `limit` of them, in `seq` order:

- while `has_more`, `next_since` is just before the next entry the caller will receive;
- otherwise `next_since` is the user's last `seq`;
- a `since` past the user's last `seq` is 409 `sync_cursor_invalid`.

`seq` is global, but every rule reads it per user, so gaps left by other users' entries
are harmless. Push and pull stamp the device's `last_sync_at`.

**Proof of equivalence.** `test/sync_convergence_test.dart` runs two of the engine's
`SyncSession`s against the server through an in-process `SyncRelay` adapter, which calls
the shelf handler with each device's token (`test/support/shelf_sync_relay.dart`). It
runs a scripted scenario and a seeded random one, and three with clocks hours apart: a
device three hours ahead refused for drift until its entry falls within the bound, a
device three hours behind clamping what it receives and its later edit winning without a
refusal, and a seeded script with one device ahead, the other behind and long stretches
in which one never syncs (hours passing refresh the devices' tokens). It asserts that the
devices converge, and that the same script run against `InMemorySyncRelay` ends in
byte-identical records with identical session reports.

## PlaidClient

`lib/src/plaid/plaid_client.dart` is the interface. It covers the Item calls
(`createLinkToken`, `createUpdateLinkToken`, `exchangePublicToken`, `getItem`,
`removeItem`), the data calls (`transactionsSync(accessToken, cursor, count:)`,
`accountsGet`, `accountsBalanceGet`, `liabilitiesGet`, `investmentsHoldingsGet`,
`investmentsTransactionsGet`, `transactionsRecurringGet(accessToken, currencyOf:)`,
`transactionsRefresh`), `webhookVerificationKeyGet`, `institutionsGetById` (a
`PlaidInstitution`: the name, the logo's PNG bytes and the colour as ARGB, a logo that is
not base64 of a PNG or a colour that is not `#rrggbb` counting as none), and the Sandbox
controls (`sandboxPublicTokenCreate`, which
takes `overrideUsername`, `overridePassword` and `daysRequested` for a custom user,
`sandboxItemResetLogin`, `sandboxTransactionsCreate`, whose `SandboxTransaction` carries
Plaid's `account_id` per transaction, and `sandboxItemFireWebhook`).

- **Types.** Requests and responses are the server's own records. Their `fromPlaidJson`
  factories read Plaid's JSON, so the fake's fixtures and the HTTP client share them; they
  take a `rounding` (none for the fake, half-even for the HTTP client, **Money from
  Plaid**). A transaction without a `logo_url` takes its first `merchant` counterparty's;
  an empty recurring `merchant_name` counts as none (the description is used).
- **Recurring currencies.** Sandbox's `average_amount` carries no currency code, so
  `transactionsRecurringGet` takes `currencyOf`, the currency of each of the Item's
  accounts (stored, or reported by the run's `/accounts/get` and pages); a stream of an
  account it does not know is left out.
- **`provenance`** is the `source` every stored row gets: `demo` for the fake, `plaid` for
  the real client.
- **`NOT_READY`.** `TransactionsSyncPage.notReady` is Plaid's `NOT_READY`: retry shortly;
  it never means "no transactions" (`PLAN.md` §4).
- **Errors.** A failure is a `PlaidException(errorType, errorCode, message, requestId)`;
  the `plaid_error` log line carries the `request_id`. `ITEM_LOGIN_REQUIRED`
  becomes 409 `item_login_required` on a sync; Plaid's rate limit becomes 429; anything
  else becomes 502 `plaid_error`.

**Money from Plaid** (`plaid_money.dart`). `plaidMoney` takes decimal text or an `int`,
never a `double`, and scales the value to the currency's minor units. Without a
`rounding` it is strict: extra fraction digits are accepted only when they are zeros,
and exponent forms are refused; the fake and its fixtures read this way. Sandbox writes
amounts finer than a cent (35 of `user_transactions_dynamic`'s 316 transactions, a
balance of `342.099285`) and recurring averages with binary noise
(`19.569999999999997`), so the HTTP client reads with `RoundingMode.halfEven` (`PLAN.md`
§12): an exponent form (`1e-07`) is first expanded exactly (`expandPlaidExponent`), then
the digits beyond the scale are rounded as text, never through a `double`. The rounding
applies to every amount the HTTP client reads: transactions, balances, recurring
averages, liabilities, holdings and investment transactions. `decodePlaidJson`
(`plaid_json.dart`) is the number-preserving pass: it decodes JSON with every number an
`int` when it is an integer that fits, else its text exactly as written, so no `double` is
ever built; the fake reads custom-user configurations through it and the HTTP client
reads Plaid's responses through it. `plaidDecimal` checks the contract's `Decimal`
strings (prices, quantities, rates), expanding exponent forms for the HTTP client.
`plaidColor` turns Plaid's `#rrggbb` into the contract's opaque ARGB integer.

**Signs.** The client's records carry Plaid's sign, and the server decides what it
stores. Liability and holding records keep Plaid's sign. Ingestion flips transaction
amounts, recurring averages and investment-transaction amounts into ours (negative is
money out). An account's current balance is stored in the app's sign (positive for money
the user holds, negative for money owed): Plaid reports what a `credit` or `loan`
account owes as positive, so `_upsertAccounts`, the one account path (the sync's
`/accounts/get` and pages, the balance refresh), negates `current` for those two types,
and an overpaid card comes out positive; available balances and credit limits are
stored as reported, never negated. The fake client and the persona engine's custom
users keep Plaid's sign; the server flips what it stores.

## The HTTP Plaid client

`lib/src/plaid/http_plaid_client.dart`, `HttpPlaidClient` over `package:http`, built by
`bin/server.dart` in sandbox mode. Plaid publishes no Dart server SDK (`PLAN.md` §12).

- **Every call** is a `POST` to `<base>/<path>` with `Content-Type: application/json`,
  `Plaid-Version: 2020-09-14`, `client_id` and `secret` in the body, and a 60 s timeout
  (`/transactions/refresh` can take 30 s). Bodies are written by `persona_engine`'s
  `writeJson`, amounts as `JsonDecimal` text (`Money.toDecimalString()`), so the wire
  number is never a `double`; answers are read through `decodePlaidJson`.
- **Logging.** One `plaid_call` line per call: the path, the status, the duration and
  Plaid's `request_id`. Never a body, a token or a key.
- **Errors.** A non-2xx answer with Plaid's error object is
  `PlaidException(error_type, error_code, error_message, request_id)`. Without one it is
  `API_ERROR`/`HTTP_<status>`, with a bare 429 counting as `RATE_LIMIT_EXCEEDED`. A
  timeout is `API_ERROR`/`TIMEOUT`, a network failure `API_ERROR`/`NETWORK_ERROR`, and a
  2xx answer that is not an object or that the records cannot read is
  `API_ERROR`/`INVALID_RESPONSE` (logged `plaid_response_unreadable` with its type). So
  every caller's existing path applies: 502, 409 login required, 429, a skipped
  secondary product.
- **`provenance`** is `plaid`. Every record comes from Plaid's answer alone.

| Method | Path | Body beyond the keys |
|---|---|---|
| `createLinkToken` | `/link/token/create` | `client_name: Finance Tracker`, `language: en`, `country_codes: [US]`, `user.client_user_id`, `android_package_name`, `products`, `transactions.days_requested` (730), `webhook` when configured |
| `createUpdateLinkToken` | `/link/token/create` | the same without `products` and `transactions`, plus `access_token` and `update.account_selection_enabled: false` |
| `exchangePublicToken` | `/item/public_token/exchange` | `public_token` |
| `getItem` | `/item/get` | `access_token`; reads `item.institution_name`, `products`, `error.error_code` |
| `removeItem` | `/item/remove` | `access_token` |
| `transactionsSync` | `/transactions/sync` | `access_token`, `cursor` (left out when empty), `count`, `options.personal_finance_category_version: v2`; `transactions_update_status: NOT_READY` is `notReady` |
| `accountsGet` | `/accounts/get` | `access_token`; read as `accountsBalanceGet` reads its answer |
| `accountsBalanceGet` | `/accounts/balance/get` | `access_token` (no `min_last_updated_datetime`) |
| `liabilitiesGet` | `/liabilities/get` | `access_token`; currencies from its `accounts`, a null `mortgage` tolerated |
| `investmentsHoldingsGet` | `/investments/holdings/get` | `access_token` |
| `investmentsTransactionsGet` | `/investments/transactions/get` | `access_token`, `start_date`, `end_date`, `options.count` 500 and `offset`, paged until `total_investment_transactions` |
| `transactionsRecurringGet` | `/transactions/recurring/get` | `access_token` |
| `webhookVerificationKeyGet` | `/webhook_verification_key/get` | `key_id`; answers `key` |
| `institutionsGetById` | `/institutions/get_by_id` | `institution_id`, `country_codes: [US]`, `options.include_optional_metadata: true` |
| `sandboxPublicTokenCreate` | `/sandbox/public_token/create` | `institution_id`, `initial_products`, `options` (`override_username`, `override_password`, `transactions.days_requested`, `webhook` when configured), left out when empty |
| `sandboxItemResetLogin` | `/sandbox/item/reset_login` | `access_token` |
| `sandboxTransactionsCreate` | `/sandbox/transactions/create` | `access_token`, `transactions[]` of `date_transacted`, `date_posted`, `amount`, `description`, `iso_currency_code`, `account_id` when named |
| `sandboxItemFireWebhook` | `/sandbox/item/fire_webhook` | `access_token`, `webhook_code`, `webhook_type` (`TRANSACTIONS` for the three transactions codes, `ITEM` for the rest) |
| `transactionsRefresh` | `/transactions/refresh` | `access_token` |

## The fake Plaid client

`lib/src/plaid/fake_plaid_client.dart`, with fixtures under
`lib/src/plaid/fake_fixtures/` (one JSON file per institution, shaped like Sandbox
responses, read through `Isolate.resolvePackageUri`). `ins_109508.json` is First
Platypus Bank: a checking, a savings, a credit-card and a 401(k) account, 12 transactions
(one pending), one monthly outflow stream, one credit liability, and the 401(k)'s three
holdings and 48 investment transactions (**Products** below).

- **Tokens are derivable**, so the fake keeps working across server restarts with no
  state of its own:
  - `sandboxPublicTokenCreate` mints `public-sandbox-fake-<institution>-<uuid>`, and a
    public token it did not mint maps to the default institution;
  - an access token is `access-sandbox-fake-<institution>-<uuid>`;
  - an Item's state is rebuilt from its fixture the first time its token is seen;
  - fixture ids are prefixed with the Item's id, so two Items never share an account or
    transaction id.
- **`transactionsSync`** answers `NOT_READY` on the first call with an empty cursor for an
  Item it has just seen, then pages the fixture's transactions by `count`, then answers
  empty pages. Each page lists the Item's accounts other than `investment` ones, as
  Sandbox lists only the accounts Transactions covers (`PLAN.md` §4, 2026-10-25);
  `accountsGet` lists every account. `sandboxTransactionsCreate` appends transactions;
  they live only as long as the process.
- **Products.** `liabilitiesGet` and `transactionsRecurringGet` serve the fixture.
  `investmentsHoldingsGet` serves the fixture's `investments` holdings and securities,
  and `investmentsTransactionsGet` its investment transactions dated within the
  requested `start` and `end`, as Plaid does, amounts in Plaid's sign (a contribution
  negative, a buy positive); a fixture without `investments` has none. First Platypus
  Bank's fixture has the `investments` product and a `401k` account (`Plaid 401k`,
  mask `4444`, reporting 5,547.63, its holdings' value: it holds no cash) with three ETFs
  (`sec_vti`, `sec_vxus`, `sec_bnd`), their holdings with cost basis priced 2026-10-23,
  and twelve months of payroll contributions of 450.00 each bought 60/30/10 into them on
  the 7th, 2025-11-07 to 2026-10-07 (48 rows); the account is listed by `accountsGet`
  and left out of the sync pages.
- **Custom users.** `sandboxPublicTokenCreate` with `overrideUsername: user_custom`
  builds the Item from the configuration in `overridePassword` (read with
  `decodePlaidJson`) instead of a fixture: its accounts from `override_accounts` (name,
  mask, type, subtype, `starting_balance` as the current balance, the limit), each
  account's transactions, at any of the persona engine's four institutions by name, with
  no liabilities, recurring streams or investments. A configuration it cannot read is
  `INVALID_FIELD`. Custom users live only as long as the process; everything still
  carries `source: demo`.
- **Created transactions** go to the named account (`INVALID_ACCOUNT_ID` for one the
  Item does not have), else its first account.
- **Institutions.** `institutionsGetById` answers a fixture's institution (with a logo and
  colour only when the fixture carries them; First Platypus Bank's carries neither) or a
  custom-user institution by name.
- **Test hooks** script what Sandbox would do: `failNext(method, error, times:)`,
  `modifyTransaction`, `removeTransaction`, `sandboxItemResetLogin`, `repairLogin`,
  `lateHistoryAfter` (an Item seen after it is set serves only that many transactions
  until a sync has paged to them, and the rest on the syncs after, as Sandbox delivers a
  large custom user's history), and `addWebhookKey(jwk)`, which
  `webhookVerificationKeyGet` then serves under its `kid`.

## Items

`lib/src/plaid/item_service.dart`. It depends only on `PlaidClient`, so the fake and the
HTTP client run the same code.

- **Link tokens.** A Link token requests 730 days and `transactions`. `update_item_id`, or
  the update-link-token route, gives an update-mode token for the user's Item (404
  otherwise).
- **The exchange** stores the Item with its institution. The access token is sealed by
  `TokenCipher`: AES-256-GCM with `TOKEN_ENCRYPTION_KEY`, a random 12-byte nonce, and the
  Item's id as associated data, so a ciphertext moved to another row fails
  authentication. A failed decryption is a 500 and is logged without the token. If
  `/item/get` fails after a successful exchange, the server calls `/item/remove` on the new
  access token (best effort, logged `orphan_item_remove_failed` when it fails) before
  answering 502, so no Item is left at Plaid that the server does not know about. The same
  removal runs when the insert transaction finds the caller's user or device gone (a
  `DELETE /me` or a device removal while Plaid was called), and the answer is 401
  `token_revoked`.
- **The same Item exchanged again.** Plaid can exchange a public token twice, answering
  the same `item_id` (`PLAN.md` §4). When the caller already has that Item (not removed
  at Plaid), the exchange reseals the access token Plaid just returned on that row,
  refreshes its status (`healthy` with the code cleared, or `login_required`), products
  and institution name from `/item/get`, logs `item_relinked`, and answers 201 with it:
  never a duplicate row. The existence check and the insert or reseal are one write
  transaction, so of two overlapping exchanges of one Item the second reseals the first's
  row. Only a genuinely new Item is removed at Plaid when something fails; one the caller
  already has never is. Another user's `item_id` (or one
  removed at Plaid) is 400 `validation_failed` on `public_token` ("cannot be exchanged by
  this user"), with nothing stored, nothing removed and `exchange_foreign_item` logged.
- **Institution metadata.** After an exchange, `/institutions/get_by_id` with the
  optional metadata. The logo (PNG bytes) and colour (ARGB) are written onto every
  visible Item at that institution. Plaid allows ten of these calls a minute per client,
  so the answer is kept in memory and fetched at most once a day per institution
  (`institutionMetadataMaxAge`); `refreshStaleInstitutions`, run by the poll, refetches
  what is older. A failed fetch is logged (`institution_metadata_skipped`) and never
  fails the exchange; nothing is cached, so the next exchange tries again. A restart
  forgets the cache.
- **Deleting an Item** removes it at Plaid (with the same three attempts, `ITEM_NOT_FOUND`
  counting as removed), then tombstones its transactions and investment transactions
  under new versions and deletes its other rows.

- **Visibility.** An Item marked `plaid_removed_at` is hidden from every route, unless
  its status is `removed` (unlinked with its history kept): that one stays listed and its
  data stays in the data endpoints. Every call that would reach Plaid for a `removed`
  Item (sync, refresh, balances, the Sandbox controls) is 409 `conflict`, and its
  update-mode link token is 404.
- **Unlinking** (`DELETE /plaid/items/{id}?history=`). `delete`, the default, is the
  deletion above. `keep` removes the Item at Plaid and, in the same statement that sets
  `plaid_removed_at`, sets its status `removed` and clears its error code; no row is
  touched. Unlinking a `removed` Item calls Plaid no more: `keep` changes nothing,
  `delete` drops the kept history. Another `history` is a 400.
- **`error_code`.** `ITEM_LOGIN_REQUIRED` from Plaid, on a sync, a refresh, a balance
  refresh or a Sandbox call, sets status `login_required` and the code and answers 409
  `item_login_required`; a completed sync clears both, except a `pending_expiration`
  (**Webhooks**), which only `LOGIN_REPAIRED`, an exchange or a login-required error
  replaces. The exchange stores `/item/get`'s.
  Every status write after the exchange is guarded by `plaid_removed_at IS NULL`, so a
  Plaid call that was in flight when the Item was unlinked cannot overwrite `removed`
  (or hide a kept history).
- **Refresh** (`POST /plaid/items/{id}/refresh`). `/transactions/refresh`, then a
  background sync run (it retries `NOT_READY`) behind the Item's lock, answered at once `202 started`;
  a failure of that run is logged (`item_refresh_sync_failed`), not answered.
- **Balances** (`POST /plaid/items/{id}/balances`). Behind the Item's lock:
  `/accounts/balance/get`, the accounts upserted (new ones inserted, current balances in
  the app's sign, **Signs**) with `balances_as_of` now, and the Item's accounts answered as `GET /accounts` writes them.
- **The logo** (`GET /institutions/{id}/logo`). The PNG stored on the caller's newest
  visible Item at that institution that has one, `image/png`; 404 otherwise. `itemJson`
  writes `logo_url` as that route's absolute URL under the request's own scheme and host
  only when a logo is stored, and `primary_color` from its column, both filled from the
  institution metadata.

**The sync run** (`POST /plaid/items/{id}/sync`). Runs are serialized per Item by an
in-process lock: a second run waits for the first and starts from the cursor it stored,
so no page is applied twice.

1. List the Item's accounts with `/accounts/get`, the canonical list: a
   `/transactions/sync` page lists only the accounts Transactions covers, none for an
   investment-only Item such as a 401(k) or a brokerage (`PLAN.md` §4). It is called once
   per attempt, a `NOT_READY` one included, and its failure is a failed page's (below).
   It is not the live balance call; `/accounts/balance/get` is, for the balance refresh.
2. Fetch every `/transactions/sync` page from the stored cursor, 500 per call.
   - `NOT_READY` changes nothing. A run a request asked for answers 202 `not_ready` at
     once (the app polls `syncItem` itself, with a 30 s receive timeout). A background
     run (the poll, a webhook, a refresh) asks again every 5 s (`syncNotReadyWait`), up
     to 12 times (`syncNotReadyRetries`), before it reports `not_ready`. Each attempt
     takes the Item's lock for its own calls and apply and releases it; the wait holds
     nothing, so a request's run or a balance refresh gets its turn between attempts.
   - `TRANSACTIONS_SYNC_MUTATION_DURING_PAGINATION` restarts from the cursor the run
     began with, at most three times.
3. Fetch recurring streams (for `transactions`), liabilities (for `liabilities`), and
   holdings and investment transactions (for `investments`): 730 days the first time,
   afterwards from 30 days before the previous successful fetch
   (`investmentsWindowStart`, never further back than 730 days). A secondary
   product that fails (`PRODUCT_NOT_READY` or any other Plaid error) is skipped: it is
   logged by name (`item_sync_product_skipped`), its stored rows are left as they were,
   and the run goes on.
4. Apply all of it in **one** transaction. If the Item or its user has gone meanwhile (a
   concurrent `DELETE /plaid/items/{id}` or `DELETE /me`), nothing is applied and the
   answer is 404 `not_found`. Otherwise: upsert accounts (current balances in the app's
   sign, **Signs**), those `/accounts/get` listed
   first and then each page's, the last report of an account winning (so a page's
   balance wins, and a new account takes its display order from `/accounts/get`);
   insert, update or tombstone transactions, each under a new version, with Plaid's
   `pending_transaction_id` mapped to ours; upsert recurring streams by Plaid's id (ids
   stay stable), with Plaid's member ids; replace liabilities,
   holdings and securities; upsert investment transactions (a new version only when one
   changed; rows outside the date window are left alone); store `cursor` and
   `run_start_cursor`; set the Item healthy (a `pending_expiration` stays) and
   `last_successful_sync_at`, and `investments_synced_at` when the investments fetch
   succeeded.
5. Answer 202 `completed` with the counts.

Nothing is persisted before the accounts, every page and every product have been
fetched. A failure of `/accounts/get` or `/transactions/sync` leaves the store and the
cursor as they were (`PLAN.md` §4): `ITEM_LOGIN_REQUIRED` marks the Item
`login_required` and answers 409, any other Plaid failure answers 502 `plaid_error`.

**Recurring alone** (`refreshRecurring`, for the webhook). Behind the Item's lock:
`/transactions/recurring/get` with the stored accounts' currencies, then the streams
replaced as a run replaces them; `ITEM_LOGIN_REQUIRED` marks the Item as a sync does.

## The poll scheduler

`lib/src/plaid/poll_scheduler.dart`, `ServerApp.poller`, started by `bin/server.dart`
unless `PLAID_POLL_INTERVAL_SECONDS` is 0 (`PLAN.md` §6.5).

- **The loop.** A tick, then the interval, measured from the end of the tick, so ticks
  never overlap.
- **A tick** reads every Item not removed at Plaid, not `removed`, not `login_required`
  and whose user exists, in link order. For each it runs a background sync
  (`retryNotReady`), one Item at a time, two seconds apart, skipping an Item whose run (a
  request's, a webhook's) is in flight (`ItemService.isSyncing`). Then
  `refreshStaleInstitutions`.
- **Failures.** An Item's failure is counted and logged (`poll_item_failed` with its
  code) and the tick goes on. A failure outside an Item (the database) is logged
  (`poll_failed`) and the loop lives on.
- **Logging.** One `poll_completed` line per tick: items, completed, not ready, skipped,
  failed, duration.
- **Load.** One sync per Item every three minutes is far inside Plaid's 50 a minute per
  Item.
- **Stopping.** `stop()` ends the wait at once and lets the Item in flight finish, for up
  to ten seconds.

## Webhooks

`POST /webhooks/plaid` (`plaid_routes.dart`, `webhook_service.dart`,
`webhook_verifier.dart`). The handler reads the body's exact bytes (1 MiB at most) and
verifies them before anything touches the database. Each check that fails rejects the
delivery with a reason class:

1. `Plaid-Verification` is present (`missing_header`) and is three base64url parts
   (`malformed`).
2. Its header says `alg: ES256` (`bad_alg`) and names a `kid` (`malformed`). This is
   checked before any key is fetched, so HS256 and `none` tokens are refused outright.
3. The key comes from a per-`kid` cache younger than an hour (`webhookKeyMaxAge`), else
   from `/webhook_verification_key/get`, with one fetch per `kid` in flight however many
   deliveries wait on it. Plaid's `INVALID_WEBHOOK_VERIFICATION_KEY_ID` is `unknown_kid`
   and is not cached; any other failure is `key_unavailable`.
4. The key must be EC P-256 (`bad_key`), and its `expired_at` must be null: Plaid sets
   it only once a key has expired, so any value, past or future, is `key_expired` (as
   Plaid's own sample verifier does).
5. The signature is 64 bytes and verifies with `dart_jsonwebtoken` (`bad_signature`).
6. `iat` is within five minutes of the server's clock, either way (`stale`).
7. `request_body_sha256` equals the SHA-256 of the exact bytes received, compared in
   constant time (`body_mismatch`).

An unverified delivery is 401 `webhook_unverified`, logged `webhook_rejected` with the
reason only (never the token or the body), and is never processed. A verified body that
is not a JSON object is a 400. Otherwise it is dispatched by `webhook_type` and
`webhook_code` on the Item with that `item_id`:

| Delivery | Effect |
|---|---|
| `TRANSACTIONS` `SYNC_UPDATES_AVAILABLE`, `DEFAULT_UPDATE` | a background sync |
| `TRANSACTIONS` `RECURRING_TRANSACTIONS_UPDATE` | `refreshRecurring` in the background |
| `ITEM` `ERROR` | `login_required` for `ITEM_LOGIN_REQUIRED`, else `error`, with `error.error_code` stored (none without an `error` object) |
| `ITEM` `LOGIN_REPAIRED` | `healthy`, the code cleared |
| `ITEM` `PENDING_EXPIRATION`, `PENDING_DISCONNECT` | `pending_expiration` with the webhook code stored |
| `ITEM` `USER_PERMISSION_REVOKED`, `USER_ACCOUNT_REVOKED` | `error` with the webhook code stored |
| anything else | logged `webhook_ignored` |

Every verified delivery is answered 204, including one for an unknown Item or an Item
removed at Plaid, which is logged `webhook_unknown_item`, so a sender cannot probe which
Item ids exist. Background work that fails is logged (`webhook_sync_failed`,
`webhook_recurring_failed`). Deliveries reach the server only through a tunnel set as
`PLAID_WEBHOOK_URL`; without one the poll does the work.

## Sandbox operations

`lib/src/plaid/sandbox_service.dart` and `sandbox_routes.dart`. `POST
/sandbox/items/{id}/reset-login`, `.../fire-webhook` (`webhook_code`, Plaid's codes) and
`.../transactions` (one to ten). Each checks, in order: the body (400), that the server
can drive Sandbox (`PLAID_ENV=sandbox`, else 409 `conflict`), the caller's Item (404),
that it is not `removed` (409 `conflict`); then calls Plaid through `ItemService.itemCall`,
so `ITEM_LOGIN_REQUIRED` marks the Item as a sync does. Create-transactions also checks
each date against Plaid's window, each `account_id` against the Item's accounts, and
each amount's currency against its account's (the Item's checking account, else its
first, when none is named, since Plaid then picks checking), with a 400 naming the field
("currency must be the account's": a mixed-currency account would break its derived
balance); then it sends Plaid's account ids. The window (`inPlaidWindow`) runs from
the UTC calendar date of the server's clock minus 729 (`plaidOldestDate`: Plaid measures
its past bound from the UTC date and refuses 730 back, verified 2026-10-25, `PLAN.md`
§4) to Plaid's "today", the calendar date at UTC−12 (`plaidToday`), never ahead of
Plaid's in any zone. In fake mode a webhook is a no-op that is
logged, and created transactions reach the next sync with `source: demo`.

## Provisioning

`lib/src/plaid/provisioning_service.dart`. `POST /sandbox/provision` (`persona`, `seed`
default 1, `days` 30 to 730, default 730) starts a job for the caller and answers 202
with it `queued`; `GET /sandbox/provision/{id}` reports it (404 for another user's or
an unknown one). Both are 409 `conflict` when the server cannot drive Sandbox, and the
POST is 409 `conflict` while another job of the user is `queued` or `running` (a
`completed` or `failed` one does not block). Jobs live in memory: a restart forgets them,
and the Items they linked stay.

The job, `queued` then `running`, then `completed` or `failed` (with `finished_at`):

1. Generates the persona with `persona_engine` at the engine's default as-of date
   (2026-10-24, the goldens'), so a provisioned persona is the committed `days730`
   fixtures, and computes **one** shift, Plaid's today minus that date. `items_total` is
   the persona's institutions. Each custom user carries the newest whole days of the
   persona's history that fit one request (`persona.md`, **What Sandbox receives**).
2. Per institution, in the persona's order: shifts the custom user's dates
   (`shiftSandboxUserDates`), drops any transaction outside Plaid's window at that
   moment (counted in `skipped`), creates the custom user (`user_custom`, the
   configuration written compact through `writeJson`, 730 days requested, `transactions` plus `liabilities` or
   `investments` when the accounts need them) and stores the Item for the caller through
   `ItemService.exchange` exactly as Link's exchange does (so the job's device must stay
   signed in). The two are one step and are retried together: an exchange whose
   `/item/get` is rate-limited removes the new Item at Plaid, so the retry needs a fresh
   public token. It then runs the first sync, retrying `not_ready` every 5 s up to 24
   times, and 5 s after it completes a second one (`lateHistoryWait`): Sandbox reports a
   large custom user's historical update complete while the rest of its rows is still
   arriving, and delivers them on a later sync even though the first answered
   `has_more: false` (verified 2026-10-25, `PLAN.md` §4), so the Item is whole when the
   job counts it. `item_ids` and `items_linked` grow as it goes. A 730-day persona's
   oldest day lands on Plaid's today minus 729, so when an Item carries it, a job that
   links that Item before 12:00 UTC (when the UTC date is a day past Plaid's today) skips it, as
   does one that links it after outlasting a UTC midnight.
3. Completes. The job injects nothing: Plaid serves an injected row only when it is dated
   its today (`PLAN.md` §4), so the history the engine leaves out of a custom user never
   reaches Sandbox, and `batches_total` and `batches_sent` stay 0. A family persona
   (four Items) takes a few minutes. The Sandbox route that injects a transaction stays
   for the developer menu (**Sandbox operations**).

A Plaid rate limit (or a 429 from a sync) is retried after its `Retry-After`, 60 s when
there is none, at most three times. Plaid failing on its side (`API_ERROR` with
`INTERNAL_SERVER_ERROR`, `HTTP_5xx`, `TIMEOUT` or `NETWORK_ERROR`, `isPlaidServerError`)
is retried 15 s apart at most three times, then fails the job with the step and the code
(for example `link gingham: INTERNAL_SERVER_ERROR`); a 4xx fails it at once. The retry
covers every step: the custom user's creation, which raises the `PlaidException` itself,
and the exchange, `/item/get` and the two syncs, which go through `ItemService` and
arrive as a 502 `plaid_error` whose `ProblemException.cause` is the `PlaidException`
(never written to the answer); a 502 whose cause is a 4xx still fails at once. A retried
link recreates the public token, so a failed `/item/get` still removes its Item at Plaid
first. Any other failure ends the job `failed` with
`"<step>: <code>"` (for example `link tartan: INVALID_INSTITUTION`), never a token.
Every record comes from Plaid's own answers with the client's provenance; the job
fabricates none. `tools/scripts/provision_persona.sh` drives it from the command line
(`testing-tools.md`).

## Data endpoints

`lib/src/data/data_routes.dart`.

- **The pages.** `GET /transactions` and `GET /investments/transactions` page by the
  per-user version counter (`versions.dart`, one counter for both). Every insert, change
  or tombstone takes the next value in its own write transaction. A page holds the rows
  with `sync_version > since`, ascending, up to `limit` (1 to 500, default 500).
  `next_since` is the last row's version, or `since` when the page is empty. A `since`
  past the user's current version is 409 `sync_cursor_invalid`: reset to 0 and read
  again.
- **The other endpoints.** `GET /accounts` (by display order), `GET /liabilities`,
  `GET /investments/holdings` (securities deduplicated by id) and `GET /recurring`
  (each stream's `transaction_ids` are the server's ids of the live transactions its
  Plaid member ids name in its Item, in Plaid's order; a member the server does not hold
  is left out).
- **JSON.** Accounts, transactions and recurring streams are written through
  `shared_models`' entities.
- **User-authored fields.** The user-authored fields of a Plaid transaction travel through
  the change log and are always empty here. `is_hidden` is always false.
- **Removed Items.** Rows of an Item marked `plaid_removed_at` (a deletion that stopped
  part-way) are hidden from every data endpoint, as the Item is, unless the Item is
  `removed` with its history kept, whose rows stay visible. Tombstones of an Item
  whose row is gone stay visible.
- **Provenance in fake mode.** Transactions, recurring streams, liabilities, holdings,
  securities and investment transactions are `source: demo` (the contract's
  `RecurringSource` has `demo` for this; `/liabilities` and `/investments/*` add each
  row's stored `source` to its object, the latter since contract 0.5.0). Accounts store
  `source` server-side but do not expose it. Exposing it is a later contract change.

## Logging

`lib/src/logging.dart`. Code logs a `LogEvent(event, fields)` on `package:logging`. The
root logger writes one JSON object per line (`time`, `level`, `logger`, `event`, the
fields), or a `key=value` line with `LOG_FORMAT=text`. Fields are ids, counts, codes and
durations. A request body, a token, a password, an email or an amount is never logged;
a test checks that for an auth flow. An error is never logged through its `toString()`,
which can carry SQL and its parameters: `errorFields` writes `error_type` and, for a
`SqliteException`, only `sqlite_result_code`, `sqlite_extended_result_code` and
`sqlite_message`. The events:

- `request`;
- the auth events: `user_registered`, `device_signed_in`, `password_rehashed`,
  `refresh_token_reuse`;
- the user and device events: `device_removed`, `user_deleted`;
- the Item events: `item_linked`, `item_synced`, `item_sync_not_ready`,
  `item_sync_restart`, `item_sync_product_skipped`, `item_refresh_started`,
  `item_refresh_sync_failed`, `item_balances_refreshed`, `item_unlinked_kept`,
  `item_removed`, `item_remove_failed`, `item_already_removed`,
  `orphan_item_remove_failed`, `item_relinked`, `exchange_foreign_item`,
  `institution_metadata_skipped`, `item_recurring_refreshed`, `plaid_error`;
- the HTTP client's `plaid_call` (path, status or failure code, duration, `request_id`) and
  `plaid_response_unreadable`;
- the poll's `poll_completed`, `poll_item_failed` and `poll_failed`;
- the webhook events: `webhook_rejected` (the reason), `webhook_received`,
  `webhook_unknown_item`, `webhook_ignored`, `webhook_sync_failed`,
  `webhook_recurring_failed`;
- the Sandbox events: `sandbox_reset_login`, `sandbox_webhook_fired`,
  `sandbox_transactions_created` (a count), and the provisioning events
  `provision_started`, `provision_item_linked`, `provision_rate_limited`,
  `provision_plaid_server_error`,
  `provision_completed`, `provision_failed`;
- `unhandled_error`, with the stack.

## Tests

`server/test/`, run by `dart test` in the gate. `test/support/test_server.dart` builds a
`ServerApp` with:

- an in-memory database;
- the fake client, or another a test gives (the HTTP client over
  `test/support/recorded_plaid_transport.dart`);
- a controllable clock;
- tiny Argon2 parameters;
- a test-set client IP;
- instant retry waits;
- no polling (`pollInterval` zero; tests run ticks themselves).

It calls the shelf handler with no socket. **Every call is checked against the
contract**: the request body with `conformsToRequest` (unless the test sends an invalid one
on purpose), and the response with `conformsToResponse` in strict mode for the matched
operation and status, plus its content type. A path outside the contract must be the
router's 404.

| Suite | What it proves |
|---|---|
| `unit/config_test.dart` | defaults, every key, missing and malformed keys named without their values, `sandbox` needing both keys, `PLAID_ENV`, `PLAID_WEBHOOK_URL` and the poll interval checked, the seed pair and the seed email's shape, the `.env` reader |
| `unit/password_hasher_test.dart` | the RFC 9106 vector, the PHC round trip, wrong and tampered passwords, the parameters read from the hash |
| `unit/access_tokens_test.dart` | claims and `kid`, expiry on the server clock, foreign and forged tokens, `HS512` and `none` refused, the `iat` and lifetime bounds, the previous key |
| `unit/token_cipher_test.dart` | the round trip, fresh nonces, tampered ciphertext, tag or nonce, another Item, another key |
| `unit/plaid_money_test.dart` | decimal text and ints to minor units, no double, no rounding when strict, malformed text; with a mode, sub-cent and float-noise text rounded (every mode, ties, the range edge) and exponent forms expanded; `#rrggbb` to ARGB |
| `unit/plaid_json_test.dart` | numbers as ints or their text, never a double; everything else as `jsonDecode`; malformed text |
| `unit/migrations_test.dart` | an empty database migrated, a v1 database with an Item migrated to v2, a v2 database with an Item migrated to v3, a v3 database with a stream migrated to v4, an idempotent rerun, a newer schema refused, a cascade on every table |
| `auth_test.dart` | register and login, every documented error, the rehash on login, rotation, reuse detection, expiry of both tokens, logout, device removal, the rate limit |
| `sync_relay_test.dart` | each rejection code, idempotent resends (`1` resent as `1.0` included), conflicting duplicates, own-entry filtering, paging, isolation between users, the 409, 400s |
| `sync_convergence_test.dart` | two engine sessions through the server converge, identically to the reference relay |
| `plaid_flow_test.dart` | link token, exchange, `NOT_READY`, a completed sync, then the data with `source: demo` and rising versions (the holdings, securities and investment transactions served with their source, the investment amounts in our sign); the holdings replaced on a later sync, the later investments window from 30 days before the last fetch, and a new version only for a changed row; created, modified and removed transactions; paging; all-or-nothing runs and the mutation restart; a skipped secondary product; two concurrent runs applying once; the Item or user removed during a run (404); login required and update mode; other users' Items; Plaid errors; a failed `/item/get` removing the new Item; an exchange whose device is removed meanwhile (401, no Item left); `ITEM_NOT_FOUND` counting as removed; Item deletion; removed Items hidden from every data endpoint; a null optional field; tokens encrypted at rest; the webhook 401 |
| `item_operations_test.dart` | refresh (Plaid called, `started`, the background run applied), login required on refresh and balances (409, `error_code`, cleared by a sync), balances stored and answered (the card's current negative, its available credit and limit as reported), unlinking with history kept (data visible, `removed`, 409s, no further Plaid call) and deleted, a login-required answer to a sync in flight not undoing a kept unlink, a bad `history`, account deletion after a kept unlink, the logo route and `logo_url`, other users' Items |
| `sandbox_test.dart` | reset-login then login required on sync, every webhook code and the refused ones, created transactions arriving `demo` in our sign on the named account, every refused body, date and currency, the window's edges (the UTC date minus 730 refused and minus 729 accepted, Plaid's today accepted and the day after refused, at 09:30 and at 13:00 UTC), a login-required Item, other users' Items 404, a removed Item 409, a server that cannot drive Sandbox 409 |
| `provisioning_test.dart` | on a clock the job's waits move: the queued answer, the counters (batches 0 of 0), every custom-user transaction arriving once with the one shift and nothing injected, the accounts by name and mask, the `NOT_READY` wait and the second sync's as the only waits; a 730-day family job carrying the newest history that fits, its left-out rows never sent; rate-limit retries and their limit; a history Sandbox delivers late stored by the second sync; Plaid 5xx retries 15 s apart and their limit on every step (custom user, exchange, `/item/get`, first and second sync), a 4xx on the exchange failing at once, and which failures count as one; a rate-limited `/item/get` retried with a fresh custom user, one Item kept; the family persona's investment-only Tartan Bank Item linked and the job completed; a failure recorded with no token logged; rows skipped from a later Item's custom user when the job stalls past Plaid's window; one job per user (finished and failed ones do not block); foreign and unknown jobs 404; bodies outside the contract 400; a server that cannot drive Sandbox 409; the fake refusing a custom user it cannot read |
| `account_deletion_test.dart` | every row gone and nobody else's touched, retries, a permanent failure deleting nothing, then a retry finishing; an Item linked during the retries removed too; Items that keep appearing giving 502; `ITEM_NOT_FOUND` not blocking; a sync whose user is deleted while Plaid is called (404); an exchange still at Plaid when the user is deleted (401, no Item left) |
| `contract_routes_test.dart` | one route per operation and none outside the contract, mounted with its security; the problem and rejection codes equal the contract's enums and the engine's reasons; every body the contract rejects is a 400; the contract's examples are accepted |
| `logging_test.dart` | request lines and no secrets; a 500 with the request id, and on a forced SQLite failure a log line with the error's type and codes but no SQL, parameters or operation; the text format |
| `http_plaid_client_test.dart` | over the recorded fixtures: every call's request (path, version header, keys, options) and mapping, every persona's 730-day custom user in a body under Plaid's 100,000 bytes, the errors (Plaid's, a non-JSON 500, a bare 429, unreadable answers, a timeout, a network failure), the 316-row page with no double (281 amounts round-tripping to Plaid's text, 35 sub-cent ones half-even), the accounts list, balances, liabilities, recurring currencies, investments paging, institutions, the Sandbox controls; through the server, every row of the seven Plaid tables `source: plaid`, a buy's amount stored and served in our sign, and a full flow (link token, exchange, update-mode token, sync) logging no key, secret or token |
| `plaid_fixtures_scan_test.dart` | every committed fixture free of live token prefixes, unredacted `client_id`, `secret` or token values, and hex runs of 24 or more |
| `institution_metadata_test.dart` | the logo and colour stored at exchange and served, one fetch a day with every Item at the institution updated, a failed fetch not failing the exchange |
| `sync_loop_test.dart` | `NOT_READY` answered at once to a request and retried 12 times by a background run, a request's sync and a balance refresh answered while a background run waits, the mutation restart and its limit, pending-to-posted, the same Item exchanged again (resealed with products and name refreshed; two overlapping exchanges making one row; a failed `/item/get` removing nothing; another user's 400), the investment-transactions window, `/accounts/get` (an investment-only Item's account, holdings and investment transactions stored; every listed account stored in its order with a page's balance winning; a failure 502 or 409 storing nothing and calling no page; one call per `NOT_READY` attempt), balance signs (the recorded card and loans stored negative and the checking account and every available amount and limit as reported, through a sync and through a balance refresh; an overpaid card stored positive) |
| `poll_scheduler_test.dart` | the Items a tick syncs, one at a time and staggered, as background runs; an Item in flight skipped; an Item's failure counted; a database failure logged with the loop alive; `stop` ending the wait |
| `webhook_test.dart` | with keys from fixed test scalars: each dispatch and status, a pending expiration kept by a sync, unknown and removed Items 204, a non-object body 400, the key cache and its hour; 401 for no header, a malformed token, a forged or short signature, a stale or future `iat`, a tampered body, an unknown `kid` fetched once in flight, HS256 and `none` before any fetch, a key with any `expired_at`, an unavailable key; no token in a log line |
| `live/sandbox_live_test.dart` | skipped unless `PLAID_LIVE_TESTS=1` and the keys are set (`testing-tools.md`, **The live Sandbox suite**): one real Item linked, synced, checked and removed; an investment-only `user_custom` Item at Tartan Bank whose 401(k) and holding the sync finds, then removed |
| `health_test.dart` | `GET /health`, and `contractVersion` equal to `info.version` |

## Commands

| What | Command |
|---|---|
| Run the server | `tools/run_server.sh` (at the root) |
| Run its tests | `tools/run_tests.sh server` (at the root) |
| One test file | `dart test test/plaid_flow_test.dart` (in `server/`) |
