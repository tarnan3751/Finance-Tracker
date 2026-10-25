// Test data for screen tests: the in-memory store with the system categories and the
// test seed (test_seed.dart) dated to testClock's today (two USD accounts, twelve transactions), or with
// whatever seed a test builds; testBanks are three linked banks, one per status the
// linked banks screen shows; linkedStore adds two linked accounts at those banks (one
// with reported balances, one never synced) and Plaid transactions with raw names.
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

/// The linked checking account at First Platypus Bank, `linked-checking`.
const String linkedCheckingId = 'linked-checking';

/// The linked card at Tartan Bank, `linked-card`.
const String linkedCardId = 'linked-card';

/// Two linked accounts: Platypus Checking at First Platypus Bank, with the balances the
/// bank reported an hour before [testClock]'s now, and Tartan Card at Tartan Bank, never
/// synced, so with no reported balance.
final List<Account> testLinkedAccounts = [
  Account(
    id: linkedCheckingId,
    itemId: 'bank-platypus',
    type: AccountType.depository,
    subtype: 'checking',
    name: 'Platypus Checking',
    officialName: 'Plaid Gold Standard 0% Interest Checking',
    mask: '0000',
    currencyCode: 'USD',
    currentBalance: Money(110000, 'USD'),
    availableBalance: Money(100000, 'USD'),
    balancesAsOf: DateTime.utc(2026, 10, 24, 14),
    isHidden: false,
    displayOrder: 2,
  ),
  const Account(
    id: linkedCardId,
    itemId: 'bank-tartan',
    type: AccountType.credit,
    subtype: 'credit card',
    name: 'Tartan Card',
    mask: '3333',
    currencyCode: 'USD',
    isHidden: false,
    displayOrder: 3,
  ),
];

/// Bank transactions on [linkedCheckingId] as Plaid sends them: a merchant Plaid named
/// with its logo, raw names the dictionary knows and does not know, and a pending ride.
final List<Transaction> testLinkedTransactions = [
  _plaid(
    'plaid-1',
    'Starbucks',
    -575,
    daysAgo: 0,
    merchant: 'Starbucks',
    logo: Uri.parse('https://plaid-merchant-logos.plaid.com/starbucks_956.png'),
  ),
  _plaid(
    'plaid-2',
    'UBER 588639690 RIDE 05/12',
    -1820,
    daysAgo: 0,
    pending: true,
  ),
  _plaid('plaid-3', 'NETFLIX.COM', -1549, daysAgo: 2),
  _plaid('plaid-4', 'TST*TACO ROCK - LORTON', -2311, daysAgo: 3),
  _plaid('plaid-5', 'Sweetgreen inc payroll ppd id', 250000, daysAgo: 5),
];

Transaction _plaid(
  String id,
  String name,
  int cents, {
  required int daysAgo,
  String? merchant,
  Uri? logo,
  bool pending = false,
}) {
  final DateTime at = testClock.nowUtc();
  return Transaction(
    id: id,
    accountId: linkedCheckingId,
    amount: Money(cents, 'USD'),
    date: testClock.today().addDays(-daysAgo),
    pending: pending,
    name: name,
    merchantName: merchant,
    merchantLogoUrl: logo,
    source: DataSource.plaid,
    createdAt: at,
    updatedAt: at,
    syncVersion: 1,
  );
}

/// A store with the system categories, the test banks, [testLinkedAccounts] and
/// [testLinkedTransactions], and, with [manual], the test seed's manual accounts and
/// transactions too.
InMemoryStore linkedStore({bool manual = false}) {
  final InMemoryStore store = seededStore(
    seed: manual ? null : const DemoSeed.empty(),
  );
  store
    ..applyPlaidItems(testBanks, testClock.nowUtc())
    ..applyPlaidAccounts(testLinkedAccounts)
    ..applyPlaidTransactions(testLinkedTransactions);
  return store;
}
