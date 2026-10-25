/// What one rule would change in the existing transactions (`docs/reference/rules.md`,
/// **On the existing transactions**): the evaluation the editor's preview shows and
/// "Apply to existing transactions" writes, so the two never differ.
///
/// The rule goes through the engine (`applyRules`) on each transaction as arrival does,
/// with the same owned-field guard: a field of a `plaid` row that already has a sync clock
/// is left alone. The guard reads the sync store, so it is asked only about the rows the
/// rule would change without it; the guard only ever removes a change, so the result is
/// the same as asking about every row. The result depends only on the rule, the
/// transactions, the categories and the sync clocks.
library;

import 'package:finance_tracker/features/rules/domain/rules_engine.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:shared_models/shared_models.dart';

/// One transaction a rule changes: as it is, and as the rule leaves it.
typedef RuleChange = ({Transaction before, Transaction after});

/// What a rule changes in the existing transactions.
final class RulePreview {
  /// The preview of [changes] among [total] transactions.
  RulePreview({required this.total, required this.changes})
    : filed = changes.where(_filed).length,
      tagged = changes.where(_tagged).length,
      renamed = changes.where(_renamed).length,
      hidden = changes.where(_hidden).length;

  /// How many transactions the rule was tried on.
  final int total;

  /// The transactions it changes, in the order it was given them.
  final List<RuleChange> changes;

  /// How many of [changes] it gives a category.
  final int filed;

  /// How many of [changes] it adds a tag to.
  final int tagged;

  /// How many of [changes] it renames.
  final int renamed;

  /// How many of [changes] it hides.
  final int hidden;
}

bool _filed(RuleChange c) => c.before.userCategoryId != c.after.userCategoryId;

bool _tagged(RuleChange c) => c.before.tags.length != c.after.tags.length;

bool _renamed(RuleChange c) => c.before.name != c.after.name;

bool _hidden(RuleChange c) => c.before.hidden != c.after.hidden;

/// What [rule] changes in [transactions], live ones on live accounts, with [lookup]
/// holding the live categories; [ownedFields] gives a transaction's fields the rule must
/// leave alone (`ruleOwnedFields`).
Future<RulePreview> evaluateRuleOnHistory(
  Rule rule,
  List<Transaction> transactions, {
  required CategoryLookup lookup,
  required Future<Set<String>> Function(Transaction) ownedFields,
}) async {
  final List<Rule> rules = [rule];
  final List<RuleChange> changes = [];
  for (final Transaction t in transactions) {
    Transaction? after = applyRules(rules, t, lookup: lookup).changed;
    if (after == null) continue;
    final Set<String> owned = await ownedFields(t);
    if (owned.isNotEmpty) {
      after = applyRules(rules, t, lookup: lookup, ownedFields: owned).changed;
      if (after == null) continue;
    }
    changes.add((before: t, after: after));
  }
  return RulePreview(total: transactions.length, changes: changes);
}

/// The transactions of [transactions] whose account is among the live [accounts]: what
/// a rule is previewed on and applied to (a transaction synced before its account cannot
/// be written until the account arrives).
List<Transaction> onLiveAccounts(
  List<Transaction> transactions,
  List<Account> accounts,
) {
  final Set<String> live = {for (final Account a in accounts) a.id};
  return [
    for (final Transaction t in transactions)
      if (live.contains(t.accountId)) t,
  ];
}
