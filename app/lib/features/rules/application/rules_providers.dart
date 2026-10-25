/// What the rules screens show and do (`docs/reference/rules.md`): the rules, what a rule
/// would change in the existing transactions, and the writes; the runner the Plaid pull
/// applies the rules with is `arrivalProcessorProvider` (`core/di/providers.dart`).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/rules/application/rule_preview.dart';
import 'package:finance_tracker/features/rules/application/rule_support.dart';
import 'package:finance_tracker/features/rules/domain/rule_repository.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
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

/// The writes of the rules screens.
@riverpod
RuleActions ruleActions(Ref ref) =>
    RuleActions(ref.watch(ruleRepositoryProvider));

/// Creates, edits, deletes, restores and reorders rules. The repository's
/// `EntityDeletedException` reaches the caller, which explains it.
final class RuleActions {
  RuleActions(this._rules);

  final RuleRepository _rules;

  static const Uuid _uuid = Uuid();

  /// Creates a rule after [live] (the live rules, in order) and returns its id.
  Future<String> create({
    required List<Rule> live,
    required String name,
    required List<RuleCondition> conditions,
    required List<RuleAction> actions,
  }) async {
    final String id = _uuid.v4();
    await _rules.upsert(
      Rule(
        id: id,
        name: name,
        position: live.isEmpty ? 0 : live.last.position + 1,
        conditions: conditions,
        actions: actions,
      ),
    );
    return id;
  }

  /// Saves [rule] as edited.
  Future<void> update(Rule rule) => _rules.upsert(rule);

  /// Deletes rule [id].
  Future<void> delete(String id) => _rules.delete(id);

  /// Brings back deleted rule [id].
  Future<void> restore(String id) => _rules.restore(id);

  /// Puts the live rules in the order of [ids].
  Future<void> reorder(List<String> ids) => _rules.reorder(ids);
}
