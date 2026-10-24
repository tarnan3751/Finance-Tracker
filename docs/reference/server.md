# Server

The development server (`PLAN.md` §6.5): authentication, devices, account deletion, the
sync relay, the Plaid proxy and the Plaid-sourced data endpoints, behind the v1 contract
in `api/openapi.yaml` (`docs/reference/api.md`). Code: `server/`. Dart with shelf and
shelf_router, `sqlite3`, `cryptography` (Argon2id, AES-256-GCM), `dart_jsonwebtoken`,
`logging` and `uuid` (`PLAN.md` §12). It is never deployed. In Phase 2 its Plaid client is
a fake that serves canned data stamped `source: demo`; the real client arrives in Phase 3
behind the same interface.

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
4. serves `/v1` on `HOST:PORT` and prints the base URL and the Plaid mode, plus, in fake
   mode, a warning that Plaid data is synthetic and carries `source: demo`.

The emulator reaches the server at `http://10.0.2.2:8080/v1`. `HOST=0.0.0.0` is only for
a physical device on the LAN. Ctrl-C stops it. Paths in `.env` are relative to
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
| `PLAID_MODE` | `fake` | `sandbox` is refused until Phase 3 |
| `PLAID_CLIENT_ID`, `PLAID_SECRET` | unset | unused in fake mode |
| `PLAID_ENV` | `sandbox` | |
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
| `lib/src/plaid/` | `PlaidClient`, the fake and its fixtures, Plaid amounts as `Money`, the token cipher, the Item service, the proxy routes and the webhook receiver |
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

Schema v1. Instants are INTEGER milliseconds UTC; dates are ISO TEXT; amounts are
`*_minor` INTEGER beside a currency code; `Decimal` values are TEXT. Every row a user owns
reaches `users` through `ON DELETE CASCADE`, which a test checks for every table.

| Table | Holds |
|---|---|
| `users` | id, email (lower-cased, unique), password_hash (PHC), display_name, created_at |
| `devices` | one signed-in installation each: id, user_id, name, created_at, last_seen_at, last_sync_at |
| `refresh_tokens` | id, device_id, token_hash (SHA-256, unique), family_id, created_at, expires_at, rotated_from, revoked_at |
| `items` | the Plaid Item: plaid_item_id, the institution, products, the sealed access token and its nonce, status, `cursor` and `run_start_cursor`, last_successful_sync_at, `plaid_removed_at` |
| `accounts` | Plaid accounts, keyed by (item_id, plaid_account_id), with the reported balances and `source` |
| `transactions` | Plaid transactions, keyed by (item_id, plaid_transaction_id), with `source`, `sync_version` and `deleted_at`; `item_id` has no foreign key, so tombstones outlive their Item |
| `recurring_streams`, `liabilities` (the contract's JSON per account and kind), `securities`, `holdings`, `investment_transactions` | the other Plaid products, each with `source` |
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
2. **`clock_drift`** when its wall time is more than one hour ahead of the server's clock.
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
runs a scripted scenario and a seeded random one. It asserts that the devices converge,
and that the same script run against `InMemorySyncRelay` ends in byte-identical records
with identical session reports.

## PlaidClient

`lib/src/plaid/plaid_client.dart` is the interface. It covers the Item calls
(`createLinkToken`, `createUpdateLinkToken`, `exchangePublicToken`, `getItem`,
`removeItem`), the data calls (`transactionsSync(accessToken, cursor, count:)`,
`accountsBalanceGet`, `liabilitiesGet`, `investmentsHoldingsGet`,
`investmentsTransactionsGet`, `transactionsRecurringGet`, `transactionsRefresh`),
`webhookVerificationKeyGet`, and the Sandbox controls (`sandboxPublicTokenCreate`,
`sandboxItemResetLogin`, `sandboxTransactionsCreate`, `sandboxItemFireWebhook`).

- **Types.** Requests and responses are the server's own records. Their `fromPlaidJson`
  factories read Plaid's JSON, so the fake's fixtures and the Phase 3 client share them.
- **`provenance`** is the `source` every stored row gets: `demo` for the fake, `plaid` for
  the real client.
- **`NOT_READY`.** `TransactionsSyncPage.notReady` is Plaid's `NOT_READY`: retry shortly;
  it never means "no transactions" (`PLAN.md` §4).
- **Errors.** A failure is a `PlaidException(errorType, errorCode)`. `ITEM_LOGIN_REQUIRED`
  becomes 409 `item_login_required` on a sync; Plaid's rate limit becomes 429; anything
  else becomes 502 `plaid_error`.

**Money from Plaid** (`plaid_money.dart`). `plaidMoney` takes decimal text or an `int`,
never a `double`. It scales the value to the currency's minor units, accepts extra
fraction digits only when they are zeros, and never rounds. The fake's fixtures write
amounts as strings; the Phase 3 client must decode Plaid's JSON numbers with a
number-preserving pass and hand over their text. `plaidDecimal` checks the contract's
`Decimal` strings (prices, quantities, rates).

**Signs.** Records keep Plaid's sign. Ingestion flips transaction amounts, recurring
averages and investment-transaction amounts into ours (negative is money out). Balances,
limits, liability amounts and holding values are stored as the institution reported them.

## The fake Plaid client

`lib/src/plaid/fake_plaid_client.dart`, with fixtures under
`lib/src/plaid/fake_fixtures/` (one JSON file per institution, shaped like Sandbox
responses, read through `Isolate.resolvePackageUri`). `ins_109508.json` is First
Platypus Bank: a checking, a savings and a credit-card account, 12 transactions (one
pending), one monthly outflow stream and one credit liability.

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
  empty pages. `sandboxTransactionsCreate` appends transactions; they live only as long as
  the process.
- **Products.** `liabilitiesGet` and `transactionsRecurringGet` serve the fixture;
  investments are empty.
- **Test hooks** script what Sandbox would do: `failNext(method, error, times:)`,
  `modifyTransaction`, `removeTransaction`, `sandboxItemResetLogin` and `repairLogin`.

## Items

`lib/src/plaid/item_service.dart` is the code Phase 3 reuses unchanged with the real
client.

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
- **Deleting an Item** removes it at Plaid (with the same three attempts, `ITEM_NOT_FOUND`
  counting as removed), then tombstones its transactions and investment transactions
  under new versions and deletes its other rows.

**The sync run** (`POST /plaid/items/{id}/sync`). Runs are serialized per Item by an
in-process lock: a second run waits for the first and starts from the cursor it stored,
so no page is applied twice.

1. Fetch every `/transactions/sync` page from the stored cursor, 500 per call.
   - `NOT_READY` answers 202 `not_ready` and changes nothing.
   - `TRANSACTIONS_SYNC_MUTATION_DURING_PAGINATION` restarts from the cursor the run
     began with, at most three times.
2. Fetch recurring streams (for `transactions`), liabilities (for `liabilities`), and
   holdings and 730 days of investment transactions (for `investments`). A secondary
   product that fails (`PRODUCT_NOT_READY` or any other Plaid error) is skipped: it is
   logged by name (`item_sync_product_skipped`), its stored rows are left as they were,
   and the run goes on.
3. Apply all of it in **one** transaction. If the Item or its user has gone meanwhile (a
   concurrent `DELETE /plaid/items/{id}` or `DELETE /me`), nothing is applied and the
   answer is 404 `not_found`. Otherwise: upsert accounts; insert, update or tombstone
   transactions, each under a new version, with Plaid's `pending_transaction_id` mapped to
   ours; upsert recurring streams by Plaid's id (ids stay stable); replace liabilities,
   holdings and securities; upsert investment transactions (a new version only when one
   changed; rows outside the date window are left alone); store `cursor` and
   `run_start_cursor`; set the Item healthy and `last_successful_sync_at`.
4. Answer 202 `completed` with the counts.

Nothing is persisted before every page and every product has been fetched. A failure of
`/transactions/sync` leaves the store and the cursor as they were (`PLAN.md` §4).
`ITEM_LOGIN_REQUIRED` marks the Item `login_required` and answers 409.

**Webhooks.** `POST /webhooks/plaid` answers 401 `webhook_unverified` to every delivery
until Phase 3 verifies them through `/webhook_verification_key/get`.

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
  `GET /investments/holdings` (securities deduplicated by id) and `GET /recurring`.
- **JSON.** Accounts, transactions and recurring streams are written through
  `shared_models`' entities.
- **User-authored fields.** The user-authored fields of a Plaid transaction travel through
  the change log and are always empty here. `is_hidden` is always false.
- **Removed Items.** Rows of an Item marked `plaid_removed_at` (a deletion that stopped
  part-way) are hidden from every data endpoint, as the Item is. Tombstones of an Item
  whose row is gone stay visible.
- **Provenance in fake mode.** Transactions are `source: demo`, and recurring streams are
  `source: demo` (the contract's `RecurringSource` has `demo` for this). Accounts,
  liabilities, holdings, securities and investment transactions store `source`
  server-side but do not expose it. Exposing it is a later contract change.

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
  `item_sync_restart`, `item_sync_product_skipped`, `item_removed`,
  `item_remove_failed`, `item_already_removed`, `orphan_item_remove_failed`,
  `plaid_error`;
- `unhandled_error`, with the stack.

## Tests

`server/test/`, run by `dart test` in the gate. `test/support/test_server.dart` builds a
`ServerApp` with:

- an in-memory database;
- the fake client;
- a controllable clock;
- tiny Argon2 parameters;
- a test-set client IP;
- instant retry waits.

It calls the shelf handler with no socket. **Every call is checked against the
contract**: the request body with `conformsToRequest` (unless the test sends an invalid one
on purpose), and the response with `conformsToResponse` in strict mode for the matched
operation and status, plus its content type. A path outside the contract must be the
router's 404.

| Suite | What it proves |
|---|---|
| `unit/config_test.dart` | defaults, every key, missing and malformed keys named without their values, `sandbox` refused, the seed pair and the seed email's shape, the `.env` reader |
| `unit/password_hasher_test.dart` | the RFC 9106 vector, the PHC round trip, wrong and tampered passwords, the parameters read from the hash |
| `unit/access_tokens_test.dart` | claims and `kid`, expiry on the server clock, foreign and forged tokens, `HS512` and `none` refused, the `iat` and lifetime bounds, the previous key |
| `unit/token_cipher_test.dart` | the round trip, fresh nonces, tampered ciphertext, tag or nonce, another Item, another key |
| `unit/plaid_money_test.dart` | decimal text and ints to minor units, no double, no rounding, malformed text |
| `unit/migrations_test.dart` | an empty database migrated, an idempotent rerun, a newer schema refused, a cascade on every table |
| `auth_test.dart` | register and login, every documented error, the rehash on login, rotation, reuse detection, expiry of both tokens, logout, device removal, the rate limit |
| `sync_relay_test.dart` | each rejection code, idempotent resends (`1` resent as `1.0` included), conflicting duplicates, own-entry filtering, paging, isolation between users, the 409, 400s |
| `sync_convergence_test.dart` | two engine sessions through the server converge, identically to the reference relay |
| `plaid_flow_test.dart` | link token, exchange, `NOT_READY`, a completed sync, then the data with `source: demo` and rising versions; created, modified and removed transactions; paging; all-or-nothing runs and the mutation restart; a skipped secondary product; two concurrent runs applying once; the Item or user removed during a run (404); login required and update mode; other users' Items; Plaid errors; a failed `/item/get` removing the new Item; an exchange whose device is removed meanwhile (401, no Item left); `ITEM_NOT_FOUND` counting as removed; Item deletion; removed Items hidden from every data endpoint; a null optional field; tokens encrypted at rest; the webhook 401 |
| `account_deletion_test.dart` | every row gone and nobody else's touched, retries, a permanent failure deleting nothing, then a retry finishing; an Item linked during the retries removed too; Items that keep appearing giving 502; `ITEM_NOT_FOUND` not blocking; a sync whose user is deleted while Plaid is called (404); an exchange still at Plaid when the user is deleted (401, no Item left) |
| `contract_routes_test.dart` | one route per operation and none outside the contract, mounted with its security; the problem and rejection codes equal the contract's enums and the engine's reasons; every body the contract rejects is a 400; the contract's examples are accepted |
| `logging_test.dart` | request lines and no secrets; a 500 with the request id, and on a forced SQLite failure a log line with the error's type and codes but no SQL, parameters or operation; the text format |
| `health_test.dart` | `GET /health`, and `contractVersion` equal to `info.version` |

## Commands

| What | Command |
|---|---|
| Run the server | `tools/run_server.sh` (at the root) |
| Run its tests | `tools/run_tests.sh server` (at the root) |
| One test file | `dart test test/plaid_flow_test.dart` (in `server/`) |
