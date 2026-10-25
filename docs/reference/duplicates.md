# Duplicates

Likely duplicate transactions surfaced for the user to resolve, never merged or deleted
(`PLAN.md` §12: ingestion performs no deduplication, and a heuristic never destroys
user-authored data). Code: `app/lib/features/duplicates/` (`domain/duplicate_detector.dart`,
the detector; `domain/dismissed_pair_store.dart` and `data/`, the dismissed pairs;
`application/duplicates_providers.dart`; `presentation/duplicate_review_screen.dart`, the
review). Tests: `app/test/features/duplicates/`,
`app/test/contract/dismissed_pair_store_contract.dart`.

## The detector

`findDuplicates(transactions, dismissed:)` is pure Dart and deterministic: the result
depends only on the transactions and the dismissed pairs, never on their order. Two
transactions are a candidate pair when:

- both are live, neither is hidden (the user has already set it aside) and neither is
  `derived` (a value the app computed, not a record);
- their dates are at most three calendar days apart (`duplicateWindowDays`, inclusive);
- their amounts are equal, sign and currency included: an outflow's duplicate is an
  outflow, so the two legs of a transfer or a card payment never pair;
- they are on different accounts, whatever their sources; or, on one account, one is bank
  data (`plaid`, or `demo` in the demo flavor, which stands in for the bank) and the other
  was entered (`manual` or `import`). Two bank rows of one account never pair: the bank
  already deduplicates its own feed. Two entered rows of one account do not pair either.

Each pair is reported once as a `DuplicateCandidate` whose `first` and `second` are in
SQLite's `BINARY` id order, keyed by a `PairKey` of the two ids in that order whichever way
round it was found; a dismissed pair is left out. The pairs are ranked by the days between
them, then by how alike their names are (`nameSimilarity`: the name and merchant name as
lowercase words of letters and digits, the words both have over the words either has, kept
as an integer fraction and compared by cross-multiplying, so no `double` decides an order),
then the newer pair first, then by key.

The work is one sort by currency, amount, date and id, and a scan of each amount's rows
within the window: O(n log n), plus the pairs found. A seeded property test (seeds from
1000; `DUPLICATES_SEED` starts elsewhere) checks it on random ledgers against a brute-force
reading of the rules over every pair, in shuffled order, with random dismissals.

## Dismissed pairs

"Not duplicates" remembers the pair on this device: `DismissedPairStore` (`watch`,
`dismiss`, `restore` for the undo), over the `dismissed_pairs` table in dev and prod
(`data.md`, schema 7: the two ids in order, a CHECK keeping them so, and `dismissed_at`)
and in memory in the tests and the demo flavor (beside the in-memory store, so a new demo
persona starts it afresh). It is never recorded or synced: another device may show the pair
again. A pair whose transactions are gone stays in the table, harmless. Both
implementations pass `runDismissedPairStoreContract`.

## The review

`duplicateCandidatesProvider` runs the detector over every live transaction
(`duplicateSourceProvider`) and the dismissed pairs (`dismissedPairsProvider`), and
recomputes when either changes; `duplicateActionsProvider` dismisses and restores.

- **The entry.** The transaction list's app bar menu (`transactions.md`; the normal app
  bar, not selection mode's) has "Review duplicates", with the number of pairs; the menu button carries a badge with it while
  there are any, and its tooltip says how many.
- **The screen** (`/transactions/duplicates`). A note that nothing is merged or deleted,
  then one card per pair, best first: how many days apart, both transactions as list rows
  (merchant, account and date, amount; tapping one opens it), "Hide this one" under each,
  and "Not duplicates". "Hide this one" sets that transaction's hidden override through
  bulk edit's path (`TransactionActions.setHidden`: one recorded batch through
  `upsertAll`, stamped now; on a bank row an override like the category), which ends its
  pairs, with a five-second Undo that shows it again; "Not duplicates" dismisses the pair,
  also with an undo. With no pair, an empty state says what makes one.
