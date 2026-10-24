// Test data for screen tests: the in-memory store with the system categories and the
// test seed (test_seed.dart) dated to testClock's today (two USD accounts, twelve transactions), or with
// whatever seed a test builds; testBanks are three linked banks, one per status the
// linked banks screen shows.
//
//   final InMemoryStore store = seededStore();
//   await pumpApp(tester, overrides: [storeOverride(store)]);
//
// The test keeps the store, so it can read back what the screen wrote.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/items/domain/item_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_models/shared_models.dart';

import 'pump_app.dart';
import 'test_seed.dart';

/// A store on [clock] ([testClock] by default) holding the system categories and [seed]
/// (the test seed dated to the clock's today by default).
InMemoryStore seededStore({
  DemoSeed? seed,
  bool categories = true,
  Clock? clock,
}) {
  final Clock storeClock = clock ?? testClock;
  final InMemoryStore store = InMemoryStore(storeClock);
  if (categories) store.seedSystemCategories();
  loadDemoSeed(store, seed ?? buildDemoSeed(storeClock.today()));
  return store;
}

/// The override that puts the in-memory repositories on [store].
Override storeOverride(InMemoryStore store) =>
    inMemoryStoreProvider.overrideWithValue(store);

/// The test seed's checking account, `demo-checking`.
const String checkingId = 'demo-checking';

/// The test seed's credit card, `demo-card`.
const String cardId = 'demo-card';

/// A manual transaction on [accountId] of [cents] minor units in [currency], dated
/// [daysAgo] days before the test clock's today.
Transaction testTransaction(
  String id, {
  String accountId = checkingId,
  int cents = -1000,
  String currency = 'USD',
  int daysAgo = 0,
  String name = 'Test',
  String? categoryId,
  List<String> tags = const [],
  int createdOffsetMs = 0,
}) {
  final DateTime at = testClock.nowUtc().add(
    Duration(milliseconds: createdOffsetMs),
  );
  return Transaction(
    id: id,
    accountId: accountId,
    amount: Money(cents, currency),
    date: testClock.today().addDays(-daysAgo),
    pending: false,
    name: name,
    userCategoryId: categoryId,
    tags: tags,
    source: DataSource.manual,
    createdAt: at,
    updatedAt: at,
    syncVersion: 0,
  );
}

/// Three linked banks: First Platypus Bank connected and synced an hour before
/// [testClock]'s now, Tartan Bank needing its login repaired, and Houndstooth Bank in
/// error and never synced.
final List<ServerItem> testBanks = [
  (
    item: Item(
      id: 'bank-platypus',
      institutionId: 'ins_109508',
      status: ItemStatus.healthy,
      lastSuccessfulSyncAt: DateTime.utc(2026, 10, 24, 14),
    ),
    institution: const Institution(
      id: 'ins_109508',
      name: 'First Platypus Bank',
    ),
  ),
  (
    item: Item(
      id: 'bank-tartan',
      institutionId: 'ins_109509',
      status: ItemStatus.loginRequired,
      lastSuccessfulSyncAt: DateTime.utc(2026, 10, 20, 9, 30),
    ),
    institution: const Institution(id: 'ins_109509', name: 'Tartan Bank'),
  ),
  (
    item: const Item(
      id: 'bank-houndstooth',
      institutionId: 'ins_109512',
      status: ItemStatus.error,
    ),
    institution: const Institution(id: 'ins_109512', name: 'Houndstooth Bank'),
  ),
];
