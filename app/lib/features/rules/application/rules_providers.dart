/// What the rules screens show and do (`docs/reference/rules.md`): the rules, what a rule
/// would change in the existing transactions, and the writes; the runner the Plaid pull
/// applies the rules with is `arrivalProcessorProvider` (`core/di/providers.dart`).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/rules/application/rule_preview.dart';
import 'package:finance_tracker/features/rules/application/rule_support.dart';
import 'package:finance_tracker/features/rules/domain/rule_repository.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:uuid/uuid.dart';

part 'rules_providers.g.dart';

/// The live rules, in the order they are applied.
@riverpod
Stream<List<Rule>> rules(Ref ref) =>
    ref.watch(ruleRepositoryProvider).watchAll();

/// Every live transaction, newest first: what a rule is previewed on.
@riverpod
Stream<List<Transaction>> ruleHistory(Ref ref) =>
    ref.watch(transactionRepositoryProvider).watch(TransactionQuery());

/// What [rule], as the editor holds it, would change in the live transactions on live
/// accounts (`evaluateRuleOnHistory`), recomputed when they, the accounts or the
/// categories change.
@riverpod
Future<RulePreview> rulePreview(Ref ref, Rule rule) async {
  final List<Transaction> transactions = onLiveAccounts(
    await ref.watch(ruleHistoryProvider.future),
    await ref.watch(accountsProvider.future),
  );
  final CategoryLookup lookup = categoryLookup(
    await ref.watch(categoriesProvider.future),
  );
  final SyncStore? store = ref.watch(recordingSyncStoreProvider);
  return evaluateRuleOnHistory(
    rule,
    transactions,
    lookup: lookup,
    ownedFields: (t) => ruleOwnedFields(store, t),
  );
}

/// Whether a rule is being applied to the existing transactions: the rules screens show
/// progress and offer no other application until it finishes.
@Riverpod(keepAlive: true)
class RuleApplying extends _$RuleApplying {
  @override
  bool build() => false;

  /// Marks an application as started; false, changing nothing, when one already runs.
  bool start() {
    if (state) return false;
    state = true;
    return true;
  }

  /// Marks the application as finished.
  void finish() => state = false;
}

/// The writes of the rules screens.
@riverpod
RuleActions ruleActions(Ref ref) => RuleActions(
  ref.watch(ruleRepositoryProvider),
  transactions: ref.watch(transactionRepositoryProvider),
  accounts: ref.watch(accountRepositoryProvider),
  categories: ref.watch(categoryRepositoryProvider),
  syncStore: ref.watch(recordingSyncStoreProvider),
);

/// Creates, edits, deletes, restores and reorders rules, and applies one to the existing
/// transactions. The repository's `EntityDeletedException` reaches the caller, which
/// explains it.
final class RuleActions {
  RuleActions(
    this._rules, {
    required this._transactions,
    required this._accounts,
    required this._categories,
    required this._syncStore,
  });

  final RuleRepository _rules;
  final TransactionRepository _transactions;
  final AccountRepository _accounts;
  final CategoryRepository _categories;

  // The sync store the writes are recorded in: the guard reads it, and its transaction
  // (the database's in dev and prod) holds the whole application. Null in the demo.
  final SyncStore? _syncStore;

  static const Uuid _uuid = Uuid();

  /// Creates a rule after [live] (the live rules, in order) and returns it.
  Future<Rule> create({
    required List<Rule> live,
    required String name,
    required List<RuleCondition> conditions,
    required List<RuleAction> actions,
  }) async {
    final Rule rule = Rule(
      id: _uuid.v4(),
      name: name,
      position: live.isEmpty ? 0 : live.last.position + 1,
      conditions: conditions,
      actions: actions,
    );
    await _rules.upsert(rule);
    return rule;
  }

  /// Saves [rule] as edited.
  Future<void> update(Rule rule) => _rules.upsert(rule);

  /// Deletes rule [id].
  Future<void> delete(String id) => _rules.delete(id);

  /// Brings back deleted rule [id].
  Future<void> restore(String id) => _rules.restore(id);

  /// Puts the live rules in the order of [ids].
  Future<void> reorder(List<String> ids) => _rules.reorder(ids);

  /// Applies [rule] to the existing transactions, once, and returns what it changed: the
  /// changes `evaluateRuleOnHistory` gives on the live transactions on live accounts,
  /// read and written in one transaction of the recording sync store (the database's in
  /// dev and prod; the demo, which records nothing, has none) as one recorded batch
  /// (`TransactionRepository.upsertAll`, all or nothing), each row recorded like a
  /// user's edit (on a `plaid` row, the override fields only) and keeping its
  /// `updatedAt`, so the result depends only on the rule, the transactions, the
  /// categories and the sync clocks. Applying it again changes nothing.
  Future<RulePreview> applyToHistory(Rule rule) {
    final SyncStore? store = _syncStore;
    Future<RulePreview> apply() async {
      final RulePreview applied = await evaluateRuleOnHistory(
        rule,
        onLiveAccounts(
          await currentValue(_transactions.watch(TransactionQuery())),
          await currentValue(_accounts.watchAll()),
        ),
        lookup: categoryLookup(await currentValue(_categories.watchAll())),
        ownedFields: (t) => ruleOwnedFields(store, t),
      );
      await _transactions.upsertAll([
        for (final RuleChange c in applied.changes) c.after,
      ]);
      return applied;
    }

    return store == null ? apply() : store.transaction(apply);
  }
}
