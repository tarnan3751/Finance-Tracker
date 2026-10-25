// A test store with likely duplicates: the test seed plus two manual entries that repeat
// seed transactions, one on another account the day after (Blue Bottle Coffee) and one
// on the same card the day after (Netflix), so the review has two pairs.
//
//   await pumpApp(tester, overrides: [storeOverride(duplicateStore())]);
import 'package:finance_tracker/core/db/in_memory_store.dart';

import 'seed.dart';

/// [seededStore] with two manual entries that repeat seed transactions.
InMemoryStore duplicateStore() => seededStore()
  ..upsertTransaction(
    testTransaction('manual-coffee', cents: -575, name: 'Blue Bottle'),
  )
  ..upsertTransaction(
    testTransaction(
      'manual-netflix',
      accountId: cardId,
      cents: -1549,
      daysAgo: 25,
      name: 'Netflix',
    ),
  );
