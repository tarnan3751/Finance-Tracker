# API

The one contract between the app and its server, the client generated from it, and the
tests that hold every implementation to it. Code: `api/openapi.yaml`,
`packages/api_client/` (generated), `packages/contract_test/`, `tools/gen_api_client.sh`,
`tools/check_contract.sh`. The in-app fakes, the development server and any future backend
implement the contract; none of them defines a shape of its own (`PLAN.md` §6.5, §12).

## The contract

OpenAPI **3.0.3**, `info.version` `0.3.0`, every path under `/v1`. The servers are the dev
server from the emulator (`http://10.0.2.2:8080/v1`) and from the machine
(`http://localhost:8080/v1`). Operations are grouped by tag: `auth`, `me`, `devices`,
`plaid`, `institutions`, `data`, `sync`, `webhooks`, `sandbox`, `health`; each has a camelCase `operationId`, which is
the generated client's method name, a summary and a description that states its behaviour.

**Security.** `bearerAuth` (HTTP bearer, a JWT access token) is declared for the whole
document; `register`, `login`, `refreshTokens`, `getHealth` and `receivePlaidWebhook`
override it with `security: []`. The webhook receiver takes the `Plaid-Verification` header
instead and answers `401` to a delivery it cannot verify.

**Conventions.**

- JSON throughout, snake_case properties, enums as their snake_case names. Two
  exceptions: `getInstitutionLogo` answers `image/png` bytes (`type: string, format:
  binary`), and `WebhookCode` keeps Plaid's spelling (`SYNC_UPDATES_AVAILABLE`), with
  `x-enum-varnames` giving the generated client camelCase constants.
- **`Money`** is `{minor_units: int64, currency: ^[A-Z]{3}$}`, `minor_units` at least
  `-(2^63 - 1)`. Every amount, balance, limit and total is `Money`; no amount is ever a JSON
  number. A nullable amount is `allOf: [$ref Money]` with `nullable: true`, because OAS 3.0
  ignores the siblings of a `$ref`.
- **`Decimal`** is an exact decimal string (`^-?(0|[1-9][0-9]*)(\.[0-9]+)?$`) for what needs
  more precision than minor units and is not a total: per-unit prices, share quantities,
  interest rates. Securities and holdings carry `currency_code` for their prices.
- **Dates** are `format: date` (`2026-10-24`). **Instants** are `format: date-time` with the
  pattern of a UTC millisecond instant, `2026-10-24T09:30:00.000Z`, as `shared_models`
  writes them (`docs/reference/core.md`).
- **`Hlc`** is the packed string `<15-digit wall>-<5-digit counter>-<node>`.
- Response schemas list every property as `required` and mark the ones that may be null
  `nullable: true`: the server writes every key, null included, as `shared_models` does.
  The one exception is `Problem` and `ValidationProblem`, whose RFC 9457 members `detail`
  and `instance` are optional and, when present, never null.
  Request bodies require only what the client must send and are closed
  (`additionalProperties: false`). `readOnly` marks server-assigned fields (`id`, `seq`,
  `sync_version`, `created_at`).
- The main schemas carry an `example`, and a test validates each against its schema.

**Schemas and `shared_models`.** Where an entity exists in `shared_models` the schema of the
same name is its JSON exactly: `Money`, `User`, `Device`, `Institution`, `Item`, `Account`,
`Transaction`, `TransactionSplit`, `RecurringStream`, `ChangeLogEntry` and the enums. The
documented differences: the API's `Item` embeds its `Institution` (`shared_models` keeps it
apart, by `institution_id`); `ChangeLogEntry` travels without `synced`, which is local
state; `PulledChangeLogEntry` is the same fields plus the server's `seq`. The two entry
schemas are flat rather than composed with `allOf`, because the generator makes a composed
parent uninstantiable. The liability, holding, security and investment-transaction
schemas exist only in the contract until Phase 3 adds their entities. Entities that
travel only inside change-log payloads (categories, budgets, rules, goals, bill reminders,
snapshots) have no schema: the payload is a free-form object.

**Paging by version.** `GET /transactions` and `GET /investments/transactions` take `since`
(the previous page's `next_since`, 0 at first) and `limit` (1 to 500, default 500), and
return the rows whose `sync_version` (the server's per-user change counter) is greater than
`since`, ascending, with `next_since` and `has_more`. A removed row comes back once more
with `deleted_at` set; a `since` greater than the user's current version is a `409`
(**Errors**). `GET /sync/pull` pages the change log the same way on `seq`, leaving
out the entries the calling device pushed itself (the token identifies the device) while
`next_since` still advances past them; a cursor beyond the server's log is a `409`
(**Errors**). `POST /sync/push` is idempotent on
`(device_id, hlc)`. Each refused entry comes back in `rejected` with a `code`, the sync
engine's `PushRejectionReason` in snake_case, which decides its fate on the device:
`clock_drift` (the entry's wall time is more than an hour ahead of the server's) is
transient and retried, `invalid` and `conflicting_duplicate` are permanent and leave the
outbox; `reason` is free text for logs. `/accounts`, `/transactions`, `/liabilities`, `/investments/*` and
`/recurring` carry Plaid-sourced data only; manual data syncs through the change log
(`PLAN.md` §6.4).

## Items and the Sandbox controls

- **`Item.error_code`** is Plaid's code while the Item is `login_required` or `error`
  (or the webhook code while it is `pending_expiration`), else null. `pending_expiration`
  and `error` come from Plaid's webhooks; a completed sync clears `error` but keeps
  `pending_expiration` until Plaid reports `LOGIN_REPAIRED` or the Item is exchanged again.
- **Exchanging again.** An exchange whose public token Plaid answers with an Item the
  caller already has answers that Item (`201`, refreshed status) rather than a new one;
  another user's is `400` on `public_token`.
- **`syncItem`** answers `not_ready` at once while Plaid prepares a new Item; the server's
  own background runs (the poll, webhooks, `refreshItem`) wait and ask again.
- **Refreshes.** `refreshItem` calls Plaid's `/transactions/refresh` and starts a sync run
  in the background, answering `202` `started`; `refreshBalances` answers the Item's
  accounts with the balances Plaid just reported.
- **Unlinking.** `DELETE /plaid/items/{item_id}?history=` takes `delete` (the default:
  the accounts and other rows go, the transactions become tombstones, the Item leaves
  the list and its accounts leave `GET /accounts`, whose absence is the signal) or `keep`
  (the data stays, and the Item stays listed with status `removed`). Every call that
  would reach Plaid for a `removed` Item (sync, refresh, balances, the Sandbox
  controls) is `409` `conflict`; its update-link token is `404`.
- **Logos.** `Institution.logo_url` is the absolute URL of `GET
  /institutions/{institution_id}/logo` (built from the request's own scheme and host)
  when the server holds the institution's logo, else null; the route is bearer-secured
  and answers the PNG, or `404` when the caller has no Item there with a logo.
  `primary_color` is ARGB, converted from Plaid's `#rrggbb`. The server fetches both from
  Plaid when an Item is linked (in sandbox mode; the fake's First Platypus Bank has
  neither) and refreshes them daily.
- **Webhooks.** `receivePlaidWebhook` answers `204` to every verified delivery, an unknown
  Item's included, `401` `webhook_unverified` to any other, and `400` to a verified body
  that is not an object (`server.md`, **Webhooks**).
- **Sandbox** (tag `sandbox`): `sandboxResetLogin`, `sandboxFireWebhook`,
  `sandboxCreateTransactions` (one to ten `SandboxTransaction`s, the amount in Plaid's
  sign, positive is money out; dates today or up to 730 days back), and the
  provisioning job `provisionPersona` and `getProvisionJob` (`ProvisionJob`, its
  `progress` counters and `error`). Each is `409` `conflict` on a server that cannot drive
  Sandbox, `404` for another user's Item or job.

## Errors

Every 4xx and 5xx answer is `application/problem+json` (RFC 9457): `type`
(`urn:finance-tracker:problem:<code>`), `title`, `status`, optional `detail` and
`instance` (absent rather than null when there is nothing to say), and `code`, the
machine-readable reason. `ValidationProblem` is always `status` 400 with `code`
`validation_failed`, and adds `errors: [{field, message}]`. The reusable responses:

| Response | Status | `code` |
|---|---|---|
| `ValidationFailed` | 400 | `validation_failed` (a malformed body or one outside the contract) |
| `Unauthorized` | 401 | `invalid_credentials`, `token_expired`, `token_revoked`; `webhook_unverified` for an unverified webhook |
| `NotFound` | 404 | `not_found` |
| `Conflict` | 409 | `email_taken`, `conflict` (a `removed` Item, a server that cannot drive Sandbox, a provisioning job already running), `item_login_required` |
| `RateLimited` | 429 | `rate_limited`, with `Retry-After` in seconds |
| `Internal` | 500 | `internal` |
| `PlaidError` | 502 | `plaid_error` |

`GET /sync/pull` also declares its own `409` with `code` `sync_cursor_invalid`: a `since`
beyond the server's last `seq` means the server's log was wiped or reset, and the client
resets its cursor to 0 and pulls again (merging entries it already applied is
idempotent). `GET /transactions` and `GET /investments/transactions` declare the same `409`
for a `since` beyond the user's current version, with the same recovery: reset to 0 and
read again, replacing stored rows by id. Every operation declares `500`, every authenticated one `401`, every one with
a body `400`. A client branches on `code`, never on `title` or `detail`.

## Versioning

The major version is the path, `/v1`. `info.version` versions the document: a minor bump
for an additive change, and while it is below 1.0 a breaking change is allowed if the
regenerated client, the fakes and the server change in the same series (the app and the
server ship together). `GET /health` reports the contract version the server implements,
so the app can tell a mismatch. Clients ignore response properties they do not know.
Enums are closed: the generated client has no unknown-value fallback, so the server maps
Plaid values it does not know before it answers (`unknown`, `other`), and an added enum
value is a contract change like any other.

## Changing the contract

1. Edit `api/openapi.yaml`, keeping the conventions above; if the change touches an entity
   in `shared_models`, change both in the same series.
2. Run `tools/gen_api_client.sh` and commit everything it changes in
   `packages/api_client`.
3. Update the fakes and the server in the same series, with their contract tests.
4. Run `tools/gates.sh`: the contract step fails on a structural violation and on a client
   generated from another version of the document; `test/models_conform_test.dart` fails
   when a mirrored schema and its entity disagree.

## The generated client

`packages/api_client` is generated by openapi-generator **7.26.x**, `dart-dio` with
`built_value` (`tools/gen_api_client.sh`; flags and modes in
`docs/reference/testing-tools.md`). Everything under `lib/` and `.openapi-generator/`,
`*.g.dart` included, is generated and committed; never edit it.
`.openapi-generator-ignore` keeps our `pubspec.yaml`, `analysis_options.yaml`,
`README.md` and `.gitignore`, and no tests or docs are generated. `.openapi-source.sha256`
records the contract it was generated from. The package's analysis options disable only
the rules the generated code breaks, each named in the file.

The generator's Java is Homebrew's (`brew install openapi-generator` brings `openjdk`);
Flutter and the Android build keep the configured Temurin 17. CI runs the Maven Central jar
on Temurin 17, and the two give byte-identical output.

Using it: `ApiClient(dio: ..., basePathOverride: ...)` and its `getAuthApi()`,
`getDataApi()`, `getSyncApi()`, `getInstitutionsApi()`, `getSandboxApi()` and the other
per-tag APIs, one method per `operationId`. `getInstitutionLogo` answers
`Response<Uint8List>`; its error body arrives as bytes too.
Models are built_value classes; `Date` is the generated calendar-date type. Names to know:
the generated `Money`, `Date`, `Transaction`, `Account` and the other models share names
with `shared_models`, so code that uses both imports one with a prefix and converts at the
boundary (the app's `core/api/http_finance_api.dart`); `Decimal` and `Hlc` are plain
`String`s; a property named `source` is `source_`. Only 2xx bodies are deserialized: an
error arrives as a `DioException` whose response body is the problem JSON. The generated
client does not enforce HTTPS; the rule that a `prod` build talks only to an HTTPS server
(`PLAN.md` §12) lives in the app's wrapper around it (`app-core.md`, **The API client**).
The generated `receivePlaidWebhook` cannot serialize its own body (its serializers have
no builder factory for `BuiltMap<String, JsonObject>`); nothing calls it, and the fakes'
contract test sends the webhook with raw Dio.

## Contract tests

`packages/contract_test` (pure Dart: `yaml`, `json_schema`) validates JSON against the
contract in any package's tests (the server's, and the in-app fake server's in
`app/test/core/api/fake_contract_test.dart`):

```dart
final contract = OpenApiDocument.load(File('../../api/openapi.yaml'));
expect(jsonDecode(response.body),
    conformsToResponse(contract, '/plaid/items/{item_id}/sync', 'post', 202));
expect(body, conformsToRequest(contract, '/sync/push', 'post'));
expect(entry.toJson(), conformsToSchema(contract, 'Account'));
```

Paths are the document's templates. A response declared without a body (a 204) matches
only null or an empty string, and an `image/png` one only non-empty bytes (a
`List<int>`). `OpenApiDocument` also answers `schema(name)`,
`requestSchema(path, method)`, `responseSchema(path, method, status)` and
`responseMediaType(path, method, status)`; `JsonValidator`
returns the errors as readable lines (`/current_balance: ...`).

The validator translates OAS 3.0 to JSON Schema draft 7 (the rules are in the header of
`lib/src/json_validator.dart`): `nullable` becomes a `null` type or an `anyOf` with null,
local references resolve within the document, `readOnly` properties are dropped from
request validation (so a closed body rejects them) and `writeOnly` ones from response
validation, OAS-only keywords are dropped, and `email` and `uri` formats are checked. Two
checks are stricter than draft 7, so that a value passes only when `shared_models` and the
generated client would both read it: `type: integer` accepts only a Dart `int` (draft 7
takes any whole number, so `1.0`, `1e3` and an integer past 2^63 - 1, which `jsonDecode`
returns as a double, would pass), and `format: date` and `format: date-time` accept only
real calendar dates and instants (`2026-02-30`, month 13, hour 24 and the basic form
`20261024` all fail), whatever pattern the document adds.

Validation is **strict** by default: an object schema that lists properties is closed, so a
server or fake that sends an undeclared field fails; `JsonValidator(document, strict:
false)` relaxes that. Composed object schemas (`allOf`
of object parts) would be closed part by part, which is one reason the contract defines
its objects flat.

`test/models_conform_test.dart` is the mirror test: every `shared_models` entity in the
contract, fully populated and with every nullable field null, conforms strictly to its
schema, and every enum has the same values on both sides.

## The structural check

`dart run contract_test:check_openapi <openapi.yaml>`, run by `tools/check_contract.sh` in
the gate, reports every violation and exits 1:

- the document parses and is OpenAPI 3.0.x; every path starts with `/`;
- every operation has a unique `operationId`, a summary and at least one 2xx response; a
  2xx response has an `application/json` schema or is only `image/png` bytes
  (`type: string, format: binary`), and a 204 has no body;
- every 4xx and 5xx response is `application/problem+json` with `Problem` or
  `ValidationProblem`;
- every `$ref` resolves, and every `required` name is a declared property;
- every property whose name ends in `amount`, `_balance`, `limit` or `target` references
  `Money`, and no schema anywhere has `type: number` (no double on the wire);
- `bearerAuth` is an HTTP bearer scheme, the five public operations declare
  `security: []`, every other operation requires `bearerAuth`, and the webhook receiver
  requires the `Plaid-Verification` header;
- every request body is closed, except the free-form webhook body.

CI adds what needs Java: `openapi-generator validate` and `tools/gen_api_client.sh
--check` (`.github/workflows/ci.yml`, job `contract`).
