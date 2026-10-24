# Core: the shared domain

`Money`, calendar dates and instants, provenance, the domain entities, the HLC value and
Plaid's category taxonomy. Code: `packages/shared_models/` (pure Dart, no Flutter), used by
the app, the server and the persona engine. The app's own core (theme, routing, dependency
injection) is `docs/reference/app-core.md`.

## Money

`Money(minorUnits, currencyCode)` is an `int` of minor units plus an ISO 4217 code:
`Money(-1234, 'USD')` is -12.34 dollars. There is no constructor from a floating-point
value and no conversion to one; an amount from JSON, CSV or user input becomes `Money` at
the boundary through `Money.fromJson` or `Money.parse`, never through `num`.

The range is symmetric, ±(2^63 - 1) minor units: the constructor rejects -2^63, so every
amount has a negation and an absolute value, and any operation whose result would leave
the range throws a `RangeError`.

- **Currency.** The code must be three uppercase letters. `Currency.minorUnitDigits` is
  ISO 4217 List One (SIX, published 2026-09-17): every active code with a numeric minor
  unit, funds codes included. A well-formed code outside the table is accepted at two
  digits; `Currency.isKnown` tells them apart. `money.scale` is the digit count.
- **Arithmetic.** `+`, `-`, unary `-`, `abs`, comparisons and `compareTo` require the same
  currency and throw `CurrencyMismatchException` otherwise. `* int` and `~/ int`
  (truncating) take an integer. Every operation is overflow-checked and throws a
  `RangeError` rather than wrapping; so do `multipliedBy`, `percent` and `allocate` when an
  intermediate product overflows.
- **Rounding.** Anything that divides names a `RoundingMode` (`halfEven` by default, also
  `halfUp`, `halfDown`, `up`, `down`, `ceiling`, `floor`): `multipliedBy(numerator,
  denominator)` and `percent(basisPoints)` (`percent(250)` is 2.5 %). The rounding is
  integer arithmetic; a zero denominator is an `ArgumentError`.
- **Allocation.** `allocate(weights)` splits by the largest-remainder method: the parts sum
  exactly to the whole and each is within one minor unit of its share; leftover units go to
  the largest remainders, ties to the earlier weight. A negative amount allocates its
  absolute value. `split(n)` is equal weights. Use these, not `~/`, whenever the remainder
  matters.
- **Sums.** `Money.sum(values, currencyCode:)`; the currency is the argument's or the first
  value's, and an empty list needs the argument.

### Formatting

`money.format(locale:, symbol:, showPlusSign:)` formats for display; a null `locale` uses
intl's default locale, which the app sets to the device's. intl's `NumberFormat` is exact
for an `int` but rounds fractions through floating point, so it is never given one:

1. The whole part (`|minorUnits| ~/ 10^scale`) is formatted as an `int` with the grouping of
   the locale's **currency** pattern (Indian grouping in `en_IN`, three-digit groups in
   `ml`, `mr` and `or`, whose decimal pattern differs), in the locale's digits.
2. The fraction is appended with the locale's decimal separator, zero-padded to the scale
   and mapped to the locale's digits.
3. The sign and the symbol are intl's own affixes for the locale's currency pattern
   (`NumberFormat.simpleCurrency`), or its plain-number affixes with `symbol: false`, so
   each locale's minus sign, bidi marks, spacing and parenthesised negatives come out as
   intl would print them.
4. `showPlusSign` puts the locale's plus sign on a positive amount where the minus sign goes
   on a negative one (before the symbol in `en_US`, after it in `nl`); zero has no sign.

Every minor-unit digit is shown: the display scale is the ISO scale, even where CLDR
displays fewer digits (HUF, IDR and the other codes listed in `test/currency_test.dart`
show two). Hiding minor units for those currencies is a later product choice, not a
formatting rule. `toDecimalString()` is the locale-independent CSV form (`-1234.56`), and
`toString()` the debugging form (`USD -12.34`).

### Parsing

`Money.parse(text, currencyCode, locale:)` reads decimal text in the locale's separators
and digits; a null `locale` uses intl's default locale, as `format` does, so a formatted
amount parses back under the same default. It accepts:

- the currency's own code or symbol only at either end of the text, before or after a
  leading sign (`$-12`, `-$12`, `12.30 USD`), never between digits (`1$2` is rejected);
- a leading sign (ASCII, U+2212 or the locale's), or parentheses for a negative;
- group separators only in the integer part and only where the locale groups: the last
  group has the locale's group size, every middle group its secondary size, and the first
  group 1 to secondary-size digits not starting with `0` (en_US `1,234,567`, en_IN
  `12,34,567`; `0,500` is a decimal typed in the wrong locale and is rejected). The sizes are
  read from intl's own formatting of a probe number. Where the locale groups with a space,
  any typed whitespace character counts as one separator.

It rejects another currency's symbol, a misplaced or doubled separator (`12,50`, `,5`,
`1,,000` in en_US), a sign inside parentheses, and more fraction digits than the scale
(`1.230` as USD): it never rounds. The separators are the locale's only, so `1.234` is
1.234 in `en_US` and 1234 in `de_DE`.

### JSON

`{"minor_units": -1234, "currency": "USD"}`. A `minor_units` that is not a JSON integer
(`12.0` included) or is -2^63, or a `currency` that is not three uppercase letters is a
`FormatException`; inside an entity it surfaces as a `CheckedFromJsonException` naming the
field. `MoneyConverter` is the same mapping as a `JsonConverter`.

## Dates and instants

`PLAN.md` §6.8 is the policy; this package gives it types.

- **`LocalDate`** is a calendar date with no time and no zone, years 1 to 9999. Use it for
  transaction dates, due dates, snapshot dates and anything a user thinks of as "a day".
  Arithmetic runs on a day count (`addDays`, `daysUntil`, `weekday`), and `addMonths`
  clamps to the last day of the target month. `LocalDate.parse` and `toIso` are exactly
  `yyyy-MM-dd`, which is also the JSON form.
- **Zones are the caller's.** The package has no zone logic. "Today" is
  `LocalDate.fromDateTime(now)` where `now` comes from the app's `timezone`-based clock;
  `fromDateTime` takes the fields of whatever `DateTime` it is given. `toDateTime()` is
  local midnight, for widgets only.
- **`LocalDateRange(start, end)`** is half-open, `[start, end)`; budget periods are these.
- **Audit instants** (`created_at`, `updated_at`, `deleted_at`, sync times) are UTC
  `DateTime`s written by `UtcInstantConverter` as `2026-10-24T15:04:05.123Z`. Writing a
  non-UTC `DateTime` throws, and reading a string with no `Z` or offset throws, because
  either would turn a device-local time into a wrong instant. Construct audit values with
  the app's clock, which is millisecond precision, or with
  `DateTime.now().toUtc().truncatedToMilliseconds()`. Audit instants are millisecond
  precision by contract: writing one with a nonzero microsecond part, or a year outside 1
  to 9999, throws too, so a value never changes on its way out and always equals itself
  after a round trip. Reading external input drops sub-millisecond digits and rejects an
  instant whose UTC year is outside 1 to 9999, which could not be written back.

## Provenance

`DataSource` is the `source` of every `Transaction`, `BalanceSnapshot` and
`NetWorthSnapshot`: `plaid` (reported by the institution through Plaid), `manual` (entered
by the user, including an opening balance), `import` (read from a file), `derived`
(reconstructed from transactions; the UI labels it) and `demo` (the demo flavor's seed).
`PLAN.md` §7.1 says which pipeline may produce which value; nothing but the server's Plaid
ingestion produces `plaid`. An unrecognized `source` in JSON is an error, never a guess.

## Entities

The entities are `PLAN.md` §6.2's, as freezed classes with `copyWith`, value equality and
snake_case JSON (`Account`, `Transaction`, `Category` and the rest, exported from
`package:shared_models/shared_models.dart`). Amounts are `Money`, calendar dates
`LocalDate`, audit fields UTC instants, URLs `Uri`, colours ARGB `int`s. Rules that are not
obvious from the field list:

- `Account` balances are the institution's reported figures and are null for a manual
  account, whose balance is always derived from its transactions.
- `Transaction.amount` is negative for an outflow. `name` is Plaid's raw name or the user's
  description and is always present; `merchantName` is Plaid's cleaned merchant or the
  enrichment fallback's normalized name, and the fallback only fills a null one.
- `Budget.periodStartDay` is 1 to 28; JSON outside that range is rejected in every
  build, not only by the debug-mode assertion.
- `Item.errorCode` is Plaid's error code (`ITEM_LOGIN_REQUIRED`, ...) while the status is
  `loginRequired` or `error`, else null; `ItemStatus.removed` is an Item unlinked with its
  history kept, whose accounts and transactions stay.
- Enums that mirror Plaid fall back instead of throwing on a new value: `ItemStatus` and
  `RecurringCadence` to `unknown`, `AccountType` to `other`. Account `subtype` is an open
  string.

## The HLC value

`Hlc(wallMillis, counter, nodeId)` is the change log's hybrid logical clock timestamp,
ordered by wall time, counter, then node id; `wall` is the UTC instant. Its packed form
`<wall>-<counter>-<node>` zero-pads the wall time to 15 digits and the counter to 5, so
packed strings sort exactly as the clocks do; it is the JSON form (`HlcConverter`). The
node id is one or more of `A-Z a-z 0-9 _ . : -`, so a UUID fits and whitespace never
does. The clock's send and receive rules belong to the sync engine
(`docs/reference/sync.md`).

## Plaid's category taxonomy

`plaidCategories` (each a `PlaidCategory`: `primary`, `detailed`, `description`) and
`plaidPrimaryCategories` are Plaid's personal-finance category taxonomy, version 2, the
version Sandbox returns. They are generated from `tool/plaid_taxonomy.csv`, Plaid's
published `pfc-taxonomy-all.csv` committed as downloaded; the CSV's version 1 mapping
columns are not generated. To refresh: download the CSV over the committed one, update
`downloadDate` in `tool/gen_taxonomy.dart`, and run `dart run tool/gen_taxonomy.dart` in
the package. `test/taxonomy_test.dart` fails while the generated file and the CSV disagree.

## Regenerating code

The freezed and json_serializable outputs (`*.freezed.dart`, `*.g.dart`) are committed.
After changing an entity, run `dart run build_runner build` in `packages/shared_models` and
commit the result; the gate fails on stale output. The generators are held
to the analyzer 13 band (freezed 4.0.1, build_runner 2.16.1, json_serializable 6.14.x,
source_helper below 1.4) because Flutter's pinned `flutter_test` fixes `test_api` 0.7.12,
which only `test` 1.31.1 accepts, and that `test` requires an analyzer below 14; a
generator release that needs analyzer 14 cannot resolve until the Flutter pin moves.

## Commands

| What | Command |
|---|---|
| Run the package's tests | `tools/run_tests.sh packages/shared_models` |
| Explore the property tests with another seed | `SHARED_MODELS_SEED=7 dart test test/money_property_test.dart` (in the package) |
| Regenerate the entities' code | `dart run build_runner build` (in the package) |
| Regenerate the taxonomy | `dart run tool/gen_taxonomy.dart` (in the package) |
