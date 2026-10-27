# Recurring streams

The streams of transactions that recur at a cadence (a salary, a bill, a subscription), the
user's choices about each one, and the subscriptions with their yearly cost. This file
covers the model, where streams come from, the overrides and how they sync, the
repository and the providers. The decisions are in `PLAN.md` §12, "Recurring streams" and
"Phase 5 lanes"; the app's own detector, its classifier and the merge with Plaid's
streams are the next lane's and land in this file with it.

Code:
- `app/lib/features/recurring/`: `domain/` (the repository interface, `StreamOverride`,
  `StreamView`, the subscriptions), `data/` (Drift, in-memory and demo repositories, the
  override rows), `application/` (the providers and `StreamActions`);
- the `recurring_streams` and `stream_overrides` tables (`data.md`), the
  `recurring_stream` sync record (`sync-app.md`), the pull's stream step
  (`core/plaid/plaid_pull.dart`), the demo mapping (`core/db/demo_seed.dart`).

Tests: `app/test/contract/recurring_stream_repository_contract.dart` (run by
`app/test/features/recurring/data/`), `app/test/features/recurring/application/`, the
recording contract's override case, `app/test/core/db/drift_sync_store_test.dart`, the
"schema 8 to 9" group of `app/test/drift/migration_test.dart`, the stream group of
`app/test/core/plaid/plaid_pull_test.dart`, the "stream overrides" group of
`app/test/sync/two_device_convergence_test.dart`, `app/test/core/api/fake_dataset_test.dart`,
`app/integration_test/items_flow_test.dart`.

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
| `detected` | the app's detector, on the device, never synced | `replaceDetected`, replaced whole on every run (next lane) |

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

`application/recurring_providers.dart`:

| Provider | What |
|---|---|
| `recurringStreamsProvider` | `watchAll()`: every stored stream with its override, muted ones included |
| `subscriptionsProvider` | the active, unmuted streams whose resolved `isSubscription` is true, each with its annual cost: the average's magnitude times 52 (weekly), 26 (biweekly), 24 (semi-monthly), 12 (monthly), 4 (quarterly) or 1 (annually), positive; null for an unknown cadence, which stays listed |
| `streamActionsProvider` | `StreamActions`: `mute(id, muted:)`, `setSubscription(id, bool?)`, `rename(id, name)` (trimmed; blank restores the merchant's) and `reset(id)` (clears every choice); each writes only its field |
