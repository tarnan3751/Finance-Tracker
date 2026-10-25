/// Rules applied to the transactions the Plaid pull brings in (`docs/reference/rules.md`,
/// **On arrival**): the pull's [ArrivalProcessor].
///
/// It runs inside each page's store transaction, on the rows the page inserted as stored
/// (with the overrides other devices recorded already laid over them), so it never
/// throws: a failure is logged by rule id and that transaction is left as it arrived. Each
/// change is an ordinary `TransactionRepository.upsert`, recorded like a user's edit (on a
/// `plaid` row only the override fields), so other devices receive the result. The row
/// keeps the `updatedAt` the server sent, so every device holds the same row.
///
/// On a `plaid` row, a field that already has a sync clock (set by a person, or by a rule
/// on another device) is left alone, read through [syncStore] (null in the demo, which
/// never syncs). Logs carry rule ids, counts and exception types only: never a merchant,
/// a name or an amount.
library;

import 'package:finance_tracker/core/plaid/plaid_pull.dart'
    show ArrivalProcessor;
import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/rules/domain/rule_repository.dart';
import 'package:finance_tracker/features/rules/domain/rules_engine.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

final Logger _log = Logger('rules');

/// The rules, run on arriving transactions.
final class RuleRunner implements ArrivalProcessor {
  /// A runner over the repositories.
  RuleRunner({
    required this.rules,
    required this.categories,
    required this.transactions,
    this.syncStore,
  });

  final RuleRepository rules;
  final CategoryRepository categories;
  final TransactionRepository transactions;

  /// Where the device's sync records are, or null when its data never syncs.
  final SyncStore? syncStore;

  @override
  Future<void> onArrived(List<Transaction> added) async {
    if (added.isEmpty) return;
    final List<Rule> live;
    final CategoryLookup lookup;
    try {
      live = await currentValue(rules.watchAll());
      if (live.isEmpty) return;
      lookup = categoryLookup(await currentValue(categories.watchAll()));
    } on Object catch (e) {
      _log.warning('rules not read: ${e.runtimeType}');
      return;
    }
    int applied = 0;
    final Map<(String, RuleSkip), int> skipped = {};
    for (final Transaction t in added) {
      String? ruleId;
      try {
        final RuleOutcome outcome = applyRules(
          live,
          t,
          lookup: lookup,
          ownedFields: await _ownedFields(t),
        );
        ruleId = outcome.rule?.id;
        for (final s in outcome.skipped) {
          if (s.reason == RuleSkip.alreadySet) continue;
          skipped.update((ruleId!, s.reason), (n) => n + 1, ifAbsent: () => 1);
        }
        final Transaction? changed = outcome.changed;
        if (changed == null) continue;
        await transactions.upsert(changed);
        applied++;
      } on Object catch (e) {
        _log.warning(
          'rule ${ruleId ?? '(none)'} not applied to a transaction: '
          '${e.runtimeType}',
        );
      }
    }
    for (final MapEntry(key: (String id, RuleSkip reason), value: int n)
        in skipped.entries) {
      _log.info('rule $id: ${reason.name} on $n transaction(s)');
    }
    if (applied > 0) _log.info('rules changed $applied of ${added.length}');
  }

  // The override fields of [t] a sync clock already covers, on a `plaid` row.
  Future<Set<String>> _ownedFields(Transaction t) async {
    final SyncStore? store = syncStore;
    if (store == null || t.source != DataSource.plaid) return const {};
    final EntityRecord? record = await store.read(EntityType.transaction, t.id);
    if (record == null) return const {};
    return {
      for (final String f in const [
        ruleCategoryField,
        ruleTagsField,
        ruleHiddenField,
      ])
        if (record.fieldClocks.containsKey(f)) f,
    };
  }
}
