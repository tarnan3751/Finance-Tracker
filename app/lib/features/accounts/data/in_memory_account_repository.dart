/// An [AccountRepository] over an [InMemoryStore]: what tests use.
library;

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Accounts held in [store], shared with the store's transaction repository.
base class InMemoryAccountRepository implements AccountRepository {
  /// The repository over [store].
  InMemoryAccountRepository(this.store);

  /// The state shared with the transaction and category repositories.
  final InMemoryStore store;

  @override
  Stream<List<Account>> watchAll() =>
      store.watch(store.accounts, same: sameList);

  @override
  Stream<Account?> watchById(String id) => store.watch(() => store.account(id));

  @override
  Future<void> upsert(Account account) async => store.upsertAccount(account);

  @override
  Future<void> delete(String id) async => store.deleteAccount(id);

  @override
  Future<void> restore(String id) async => store.restoreAccount(id);

  @override
  Stream<Money?> watchDerivedBalance(String id) =>
      store.watch(() => store.derivedBalance(id));

  @override
  Stream<Map<String, Money?>> watchDerivedBalances() =>
      store.watch(store.derivedBalances, same: sameMap);
}
