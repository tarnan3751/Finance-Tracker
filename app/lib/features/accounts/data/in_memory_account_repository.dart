/// An [AccountRepository] over an [InMemoryStore]: what tests use.
library;

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Accounts held in [store], shared with the store's transaction repository. Every write
/// records the account, and each transaction a delete or restore changes, through
/// [recorder] after the store's synchronous write.
base class InMemoryAccountRepository implements AccountRepository {
  /// The repository over [store], recording through [recorder].
  InMemoryAccountRepository(this.store, {required this.recorder});

  /// The state shared with the transaction and category repositories.
  final InMemoryStore store;

  /// Where the writes are recorded.
  final ChangeRecorder recorder;

  @override
  Stream<List<Account>> watchAll() =>
      store.watch(store.accounts, same: sameList);

  @override
  Stream<Account?> watchById(String id) => store.watch(() => store.account(id));

  @override
  Future<void> upsert(Account account) async {
    final Map<String, Object?>? before = store.accountRecord(account.id);
    store.upsertAccount(account);
    await recorder.record(
      EntityType.account,
      account.id,
      before,
      store.accountRecord(account.id)!,
    );
  }

  @override
  Future<void> create(Account account, {Transaction? openingBalance}) async {
    final Map<String, Object?>? before = store.accountRecord(account.id);
    final Map<String, Object?>? openingBefore = openingBalance == null
        ? null
        : store.transactionRecord(openingBalance.id);
    store.createAccount(account, openingBalance);
    await recorder.record(
      EntityType.account,
      account.id,
      before,
      store.accountRecord(account.id)!,
    );
    if (openingBalance != null) {
      await recorder.record(
        EntityType.transaction,
        openingBalance.id,
        openingBefore,
        store.transactionRecord(openingBalance.id)!,
      );
    }
  }

  @override
  Future<void> applyPlaid(List<Account> accounts) async =>
      store.applyPlaidAccounts(accounts);

  @override
  Future<void> delete(String id) =>
      _recorded(id, () => store.deleteAccount(id));

  @override
  Future<void> restore(String id) =>
      _recorded(id, () => store.restoreAccount(id));

  // Runs [write] on account [id] and records the account and each of its transactions
  // it changed.
  Future<void> _recorded(String id, void Function() write) async {
    final Map<String, Object?>? before = store.accountRecord(id);
    final Map<String, Map<String, Object?>> transactions = store
        .transactionRecordsOf(id);
    write();
    final Map<String, Object?>? after = store.accountRecord(id);
    if (after == null) return;
    await recordEach(recorder, EntityType.account, {id: ?before}, {id: after});
    await recordEach(
      recorder,
      EntityType.transaction,
      transactions,
      store.transactionRecordsOf(id),
    );
  }

  @override
  Stream<Money?> watchDerivedBalance(String id) =>
      store.watch(() => store.derivedBalance(id));

  @override
  Stream<Map<String, Money?>> watchDerivedBalances() =>
      store.watch(store.derivedBalances, same: sameMap);
}
