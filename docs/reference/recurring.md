# Recurring streams

The streams of transactions that recur at a cadence (a salary, a bill, a subscription), the
user's choices about each one, and the subscriptions with their yearly cost. This file
covers the model, where streams come from, the overrides and how they sync, the
repository, the providers, the app's own detector, the subscription classifier and the
merge of the detected streams with the server's. The decisions are in `PLAN.md` §12,
"Recurring streams", "Phase 5 lanes" and "The detector".

Code:
- `app/lib/features/recurring/`: `domain/` (the repository interface, `StreamOverride`,
  `StreamView`, the subscriptions, the detector, the classifier, the merge), `data/`
  (Drift, in-memory and demo repositories, the override rows), `application/` (the
  providers and `StreamActions`, the merged list, the detector runner);
- the `recurring_streams` and `stream_overrides` tables (`data.md`), the
  `recurring_stream` sync record (`sync-app.md`), the pull's stream step
  (`core/plaid/plaid_pull.dart`), the demo mapping (`core/db/demo_seed.dart`).

Tests: `app/test/contract/recurring_stream_repository_contract.dart` (run by
`app/test/features/recurring/data/`), `app/test/features/recurring/application/`, the
recording contract's override case, `app/test/core/db/drift_sync_store_test.dart`, the
"schema 8 to 9" group of `app/test/drift/migration_test.dart`, the stream group of
`app/test/core/plaid/plaid_pull_test.dart`, the "stream overrides" group of
`app/test/sync/two_device_convergence_test.dart`, `app/test/core/api/fake_dataset_test.dart`, `app/test/features/recurring/domain/` (the
detector, the classifier, the merge and the harness), `app/integration_test/items_flow_test.dart`,
`app/integration_test/recurring_detector_test.dart`.

## The model

A stream is `shared_models`' `RecurringStream` (`core.md`): its account, merchant name,
cadence (`weekly`, `biweekly`, `semi_monthly`, `quarterly`, `monthly`, `annually`,
`unknown`; Plaid never reports `quarterly`), average amount in the app's sign (negative
is money out), the last and next expected dates (null when unknown), `active` or `ended`,
whether it is a subscription, its `source`, and `transactionIds`, its member
transactions as the app stores them.

| Source | Where it comes from | Written by |
|---|---|---|
| `plaid` | the server's `/transactions/recurring/get` rows per Item, through `GET /recurring` | the Plaid pull (`applyPlaid`), replaced whole on every pull |
| `demo` | the in-app fake (the persona's expectations, the sample's Netflix stream) or the dev server's fake Plaid client | the same pull, or the demo repository's seed |
| `detected` | the app's detector, on the device, never synced | `replaceDetected`, replaced whole on every run of the detector runner (**The detector**) |

Streams are never recorded for sync: the server's are server-authoritative and the
detector's are recomputed on each device with a deterministic id. A `plaid` stream's
members are the server's ids of the transactions Plaid named that it holds (`server.md`),
so a detected stream whose members overlap a pulled one can be dropped from the merged
list.

## Overrides

What the user chose about a stream is a `StreamOverride` (app-local, `domain/`): `muted`
(hidden from the lists), `isSubscription` (null: the stream's own classification stands)
and `displayName` (null: the merchant's). It is stored in `stream_overrides` by stream id,
with no foreign key: a stream the server stops reporting leaves its override behind, and an
override may arrive through sync before its stream, then applies when the stream lands.

A `StreamView` is a stream with its live override resolved: `muted`, `isSubscription`
(the override's, else the stream's) and `displayName` (the override's, else the
merchant's). A cleared override is no override.

**Sync.** Overrides sync as the `recurring_stream` record (fields `muted`,
`is_subscription`, `display_name`, `deleted_at`). The record is only ever updates, as the
settings' is: a write records against the stored override, or against the default when
there is none, so the first choices two devices make about one stream (a mute on one, a
name on the other) merge field by field rather than one overwriting the other. Clearing
an override writes its tombstone (a delete), which wins over another device's concurrent
edit; a later choice restores it from the default with that choice applied, an update
writing `deleted_at: null`.

## The repository

`RecurringStreamRepository` (`domain/recurring_stream_repository.dart`), in Drift,
in-memory and demo implementations under one contract suite:

| Method | What |
|---|---|
| `watchAll()` | every stored stream as a `StreamView`, by merchant name ignoring ASCII case, then id |
| `watchById(id)` | one, or null when the stream is not stored |
| `applyPlaid(streams)` | replaces every `plaid` and `demo` stream with the server's whole list in one write; the detected ones and the overrides stay; records nothing |
| `replaceDetected(streams)` | replaces every `detected` stream; records nothing |
| `setOverride(id, change)` | applies `change` to the current override (the live one, else the default) inside the write; records only the fields that changed; nothing when the result equals the current one |
| `clearOverride(id)` | the tombstone, recorded as a delete; nothing when there is no live override |

A stream of the wrong source for its method, or two with one id, is an `ArgumentError`
before anything is written. The demo repository starts from the persona's streams
(`demoRecurringStreams`) and records nothing.

## The demo

`demoRecurringStreams(seed)` (`core/db/demo_seed.dart`) turns each of the persona engine's
recurring expectations (`persona.md`) into a `demo` stream, `demo-stream-<key>`: the
schedule's cadence, the middle of the expectation's amount band in the app's sign as the
average, the schedule's last occurrence in the seed's window and its next after the as-of
date as the expected dates, `active`, the expectation's subscription flag, and as members
the seed's transactions on the expectation's account with its raw name (the engine's
recurrence tests hold that no other transaction there carries the name). The demo
repository and `FakeDataset.fromDemoSeed` both start from it, so a pull after a Link in the
demo changes nothing for the persona's Items.

## Providers

`application/recurring_providers.dart`, `merged_streams.dart` and `detector_runner.dart`:

| Provider | What |
|---|---|
| `recurringStreamsProvider` | `watchAll()`: every stored stream with its override, muted ones included |
| `subscriptionsProvider` | of `mergedStreamsProvider`'s list, the active, unmuted streams whose resolved `isSubscription` is true, each with its annual cost: the average's magnitude times 52 (weekly), 26 (biweekly), 24 (semi-monthly), 12 (monthly), 4 (quarterly) or 1 (annually), positive; null for an unknown cadence, which stays listed |
| `streamActionsProvider` | `StreamActions`: `mute(id, muted:)`, `setSubscription(id, bool?)`, `rename(id, name)` (trimmed; blank restores the merchant's) and `reset(id)` (clears every choice); each writes only its field |
| `mergedStreamsProvider` | (`merged_streams.dart`) the stored streams merged again and classified, the list the screens read (**Merging**) |
| `recurringLedgerProvider` | (`merged_streams.dart`) every live transaction, which the merged list and the runner read |
| `detectorRunnerProvider` | (`detector_runner.dart`) recomputes the detected streams while listened to (**The detector**) |

## The detector

`features/recurring/domain/recurring_detector.dart`, pure Dart: `detectStreams(transactions,
{today, lookup, merchantKey})` finds recurring streams on any account and returns them as
`RecurringStream`s with `source: detected`. The result depends only on the transactions, the
categories and `today` (never on input order or a clock), and every amount is integer
`Money`. The rules were measured against the persona engine before they were fixed
(`PLAN.md` §12, "The detector").

- **Input.** Live transactions that are not hidden, not pending, not `derived` and not zero.
  Rows whose effective category is an internal movement or an accrual are left out
  (`detectorExcludedCodes`: own-account and savings transfers both ways, card payments,
  interest earned and charged, and any inflow under `LOAN_PAYMENTS`, the receiving leg of a
  payment); a row the user recategorizes becomes eligible.
- **Groups.** By account, currency, direction and the merchant key,
  `recurringMerchantKey`: the enrichment fallback's display name (**Merchants** in
  `transactions.md`) normalized, so the detector and the dictionary never disagree. The
  whole group is tried as one stream first, which keeps a seasonal bill whole; only when it
  is not one is it split into amount clusters (sorted by magnitude, an amount joining the
  previous one's cluster within 15 % of it or 100 minor units, 25 % for inflows), which
  separates two streams at one merchant, such as two loans at one lender. A known limit:
  two streams at one merchant on one account whose amounts fall in one cluster (two
  Spotify plans billed on the 3rd and the 20th) fuse into one candidate, which reads as
  semimonthly, and the classifier then rejects it as pay-like; splitting a group by
  amount tier is later scope (`PLAN.md` §12, "5b review rulings").
- **Cadence.** The candidate's dates form maximal runs per cadence, each interval fitting
  once or, for one missed occurrence per run, twice:

  | Cadence | Interval | Anchor | Fewest occurrences |
  |---|---|---|---|
  | weekly | 7±2 days | the weekday | 4 |
  | biweekly | 14±3 | the fortnight's phase | 4 |
  | semimonthly | 10..20 | two days of the month 10+ apart, every date within 3 | 3 |
  | monthly | 24..35 | the most common day of the month, every date within 4, clamped to short months | 3 |
  | quarterly | 91±7 | the month in the quarter and the day | 3 |
  | annual | 365±10 | the month and day | 2 |

  For the semimonthly, monthly, quarterly and annual anchors a day of the month of 28 or
  more is one "last day" token, `L`, both when the most common day is chosen and in the id,
  so a bill on the month's end keeps one anchor and one id through months of 28, 30 and
  31 days, and its next date is the actual last day of the month. A stream truly on the
  28th is anchored to the last day too.

  A run is a stream only when no row of its candidate outside it shares its first or last
  date, when it holds at least two thirds of its candidate's rows (a chance weekly run among
  a café's visits is not a stream), when, quarterly or annual, its amounts are within 5 % of
  their median, and when, annual and seen only twice, it holds two thirds of its merchant
  group's rows. The longest run wins, then the one ending later, then the shorter cadence
  (semimonthly before biweekly).
- **The stream.** The id is `detected-` and 16 hex digits of the SHA-1 of
  `account|currency|direction|merchant key|cadence|anchor`, so it survives new rows and
  recomputation and the overrides and bill links keyed by it stay attached; of two streams
  with one id
  the one ending later is kept. `transactionIds` are the run's members, `lastExpected` the
  last one's date, `nextExpected` the first anchored date at least half a cadence later,
  `status` active while today is at most two cadence lengths (7, 14, 16, 31, 92, 366 days)
  after the last occurrence, `merchantName` the newest member's display name.
  `isSubscription` is left false for the classifier.
- **Amounts.** `StreamBand.of(members)` gives the expected amount (`averageAmount`) and the
  band, for a stream of any source, from its member transactions: the median (the lower
  middle by magnitude), minimum and maximum of the newest price step. The members' amount
  clusters that follow each other in time are a price change, and the newest is the step;
  clusters that interleave (a seasonal bill) or a single one make every member the step. No
  band is stored: the forecast computes it the same way.
- **The runner.** `application/detector_runner.dart`'s `detectorRunnerProvider` keeps the
  stored detected streams current: when the live transactions, the categories, the
  server's streams or today change, it runs `detectedStreamsFor` `detectorDebounceProvider`
  (2 s) after the last change, which detects, classifies every stream (**Subscriptions**)
  and drops those the server's streams cover (**Merging**), then writes the rest through
  `replaceDetected`. On a ledger of more than `detectorIsolateThresholdProvider` (2,000)
  rows the run goes to a background isolate (`compute`). One run happens at a time; a
  change during a run starts one more on the latest input, and the run's own write does
  not start another. `bootstrap` listens to it for the life of the app, in every flavor;
  nothing runs in a test that does not listen. A failure is logged by type only.
- **Measured.** `test/features/recurring/domain/detector_harness_test.dart` (tag
  `detector_harness`, run by the gate) runs the detector over each persona's full demo seed
  (seed 1, as of 2026-10-24) and matches the seed's `recurring` expectations one to one by
  account, merchant key and cadence; precision and recall must be at least 0.9 per persona.
  The test prints the figures, the misses and extras by name, the cadence agreement, the
  median next-date error and the classifier's agreement with the persona's flag. The small
  business's estimated tax (four irregular dates a year) has no cadence and stays a miss.

## Subscriptions

`features/recurring/domain/subscription_classifier.dart`, pure Dart: Plaid does not say
whether a stream is a subscription, so `isSubscription(stream, {effectiveCategory, band})`
classifies every stream, Plaid's, the demo's and the detector's alike. A stream is a
subscription when it is an outflow; its band is within 5 % of its median, or its source
already flags it; its cadence is weekly, monthly or annual (biweekly and semimonthly are
pay-like); and its category, `streamCategory(members, lookup)` (the most common effective
category of its members, a tie to the newest member's), is not under `RENT_AND_UTILITIES`,
`LOAN_PAYMENTS`, `TRANSFER_IN`, `TRANSFER_OUT`, `INCOME` or
`GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT`. A category with no Plaid code (the user's own) is
never excluded. A fixed-price monthly bill outside those categories, such as insurance or
childcare, classifies as a subscription; the user's override (`stream_overrides`) wins over
the classification.

## Merging

`features/recurring/domain/stream_merge.dart`, pure Dart: `mergeStreams(pulled, detected)`
keeps every pulled stream (`plaid` or `demo`) and appends the detected streams the bank does
not already report. A detected stream is dropped when any of its transaction ids is a pulled
stream's, or when a pulled stream that lists no transaction ids is on its account with its
merchant (names normalized as the enrichment fallback compares them), since the overlap
cannot be seen then. The list is sorted by merchant name, then id.

`application/merged_streams.dart`'s `mergedStreamsProvider` is the list the screens read,
in the repository's order (merchant name ignoring ASCII case, then id; `mergeStreams`'s
own order is not used): the stored streams (`watchAll()`) merged again when read, so a pull landing
between two detector runs never shows a stream twice, and each server stream classified
over its members in the ledger (`recurringLedgerProvider`, every live transaction): its
flag is set when its source flags it or the classifier says so, and `StreamView`'s
`isSubscription` lets the user's override win over both. Detected streams are kept as the
runner stored them, already classified.
