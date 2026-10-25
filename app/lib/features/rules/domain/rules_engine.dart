/// The rules engine: which rule matches a transaction and what its actions change
/// (`docs/reference/rules.md`). Pure Dart, no Flutter, and deterministic: the result
/// depends only on the rules, the transaction, the categories and the fields the caller
/// says the user owns, never on the order the rules are given in, the device or the
/// clock.
///
/// The rules are taken in `position` order, ties by id in SQLite's `BINARY` order (as the
/// repositories list them), and **the first rule whose
/// conditions all match wins**: every one of its actions is applied, and no later rule is
/// looked at, even when its actions change nothing. A rule with no condition or no action
/// never matches. The conditions:
///
/// - `merchantContains`: the text, trimmed, is in the merchant name, else (when the
///   merchant name is null, empty or blank) the name, ignoring case (`toLowerCase` on
///   both, which does not depend on the device locale);
/// - `amountBetween`: the absolute amount is within the bounds, both inclusive and either
///   one absent; a bound in another currency than the transaction's never matches;
/// - `account`: the text is the account id;
/// - `plaidCategory`: the text is the primary or the detailed Plaid code.
///
/// The actions only ever fill what is unset, so applying the rules again changes nothing:
///
/// - `setCategory` sets `userCategoryId` when it is null, to a live category, on a
///   transaction without splits (a split one is already the user's categorization);
/// - `addTag` appends the tag when the transaction does not carry it;
/// - `rename` sets the name of a `manual` or `import` transaction (a bank's or the demo's
///   name is the bank's);
/// - `hide` is not applied: transactions have no hidden field until Phase 4.
///
/// A field in `ownedFields` (record field names: `user_category_id`, `tags`) is left as it
/// is: the caller's way of saying a person, or another device's rule, has already set it.
library;

import 'package:finance_tracker/core/util/binary_compare.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:shared_models/shared_models.dart';

/// Why an action of the matching rule changed nothing.
enum RuleSkip {
  /// The field already has a value (or the tag is already there).
  alreadySet,

  /// The field is the user's: the caller said so.
  ownedByUser,

  /// The transaction has splits, its own categorization.
  splitTransaction,

  /// The category is not a live one.
  unknownCategory,

  /// The action has no value.
  emptyValue,

  /// The name of a bank (or demo) transaction is not renamed.
  bankName,

  /// The action is not supported yet (`hide`).
  unsupported,
}

/// What the rules do to one transaction.
final class RuleOutcome {
  /// An outcome.
  const RuleOutcome({this.rule, this.changed, this.skipped = const []});

  /// No rule matched.
  static const RuleOutcome none = RuleOutcome();

  /// The rule that matched, or null when none did.
  final Rule? rule;

  /// The transaction with the matching rule's actions applied, or null when they change
  /// nothing (or no rule matched).
  final Transaction? changed;

  /// The matching rule's actions that changed nothing, with why, in the rule's order.
  final List<({RuleActionKind kind, RuleSkip reason})> skipped;
}

/// The record fields of a transaction a rule writes.
const String ruleCategoryField = 'user_category_id';

/// The record field of a transaction's tags.
const String ruleTagsField = 'tags';

/// Applies the first of [rules] that matches [transaction]; [lookup] holds the live
/// categories, and [ownedFields] the fields the rules must leave alone.
RuleOutcome applyRules(
  List<Rule> rules,
  Transaction transaction, {
  required CategoryLookup lookup,
  Set<String> ownedFields = const {},
}) {
  final List<Rule> ordered = [...rules]
    ..sort((a, b) {
      final int byPosition = a.position.compareTo(b.position);
      return byPosition != 0 ? byPosition : compareBinary(a.id, b.id);
    });
  for (final Rule rule in ordered) {
    if (!ruleMatches(rule, transaction)) continue;
    Transaction next = transaction;
    final List<({RuleActionKind kind, RuleSkip reason})> skipped = [];
    for (final RuleAction action in rule.actions) {
      final RuleSkip? skip;
      (next, skip) = _act(action, next, lookup, ownedFields);
      if (skip != null) skipped.add((kind: action.kind, reason: skip));
    }
    return RuleOutcome(
      rule: rule,
      changed: next == transaction ? null : next,
      skipped: skipped,
    );
  }
  return RuleOutcome.none;
}

/// Whether every condition of [rule] matches [transaction]; false for a rule with no
/// condition or no action.
bool ruleMatches(Rule rule, Transaction transaction) =>
    rule.conditions.isNotEmpty &&
    rule.actions.isNotEmpty &&
    rule.conditions.every((c) => conditionMatches(c, transaction));

/// Whether [condition] matches [transaction].
bool conditionMatches(RuleCondition condition, Transaction transaction) {
  final String? text = condition.text?.trim();
  switch (condition.kind) {
    case RuleConditionKind.merchantContains:
      if (text == null || text.isEmpty) return false;
      final String? merchant = transaction.merchantName;
      return (merchant == null || merchant.trim().isEmpty
              ? transaction.name
              : merchant)
          .toLowerCase()
          .contains(text.toLowerCase());
    case RuleConditionKind.amountBetween:
      final Money? min = condition.minAmount;
      final Money? max = condition.maxAmount;
      if (min == null && max == null) return false;
      final String currency = transaction.amount.currencyCode;
      if ((min != null && min.currencyCode != currency) ||
          (max != null && max.currencyCode != currency)) {
        return false;
      }
      final int amount = transaction.amount.abs().minorUnits;
      return (min == null || amount >= min.minorUnits) &&
          (max == null || amount <= max.minorUnits);
    case RuleConditionKind.account:
      return text != null && text.isNotEmpty && text == transaction.accountId;
    case RuleConditionKind.plaidCategory:
      return text != null &&
          text.isNotEmpty &&
          (text == transaction.plaidPrimaryCategory ||
              text == transaction.plaidDetailedCategory);
  }
}

(Transaction, RuleSkip?) _act(
  RuleAction action,
  Transaction t,
  CategoryLookup lookup,
  Set<String> ownedFields,
) {
  final String? value = action.value?.trim();
  switch (action.kind) {
    case RuleActionKind.setCategory:
      if (value == null || value.isEmpty) return (t, RuleSkip.emptyValue);
      if (!lookup.byId.containsKey(value)) {
        return (t, RuleSkip.unknownCategory);
      }
      if (ownedFields.contains(ruleCategoryField)) {
        return (t, RuleSkip.ownedByUser);
      }
      if (t.userCategoryId != null) return (t, RuleSkip.alreadySet);
      if (t.splits.isNotEmpty) return (t, RuleSkip.splitTransaction);
      return (t.copyWith(userCategoryId: value), null);
    case RuleActionKind.addTag:
      if (value == null || value.isEmpty) return (t, RuleSkip.emptyValue);
      if (ownedFields.contains(ruleTagsField)) {
        return (t, RuleSkip.ownedByUser);
      }
      if (t.tags.contains(value)) return (t, RuleSkip.alreadySet);
      return (t.copyWith(tags: [...t.tags, value]), null);
    case RuleActionKind.rename:
      if (value == null || value.isEmpty) return (t, RuleSkip.emptyValue);
      if (t.source != DataSource.manual && t.source != DataSource.import) {
        return (t, RuleSkip.bankName);
      }
      if (t.name == value) return (t, RuleSkip.alreadySet);
      return (t.copyWith(name: value), null);
    case RuleActionKind.hide:
      return (t, RuleSkip.unsupported);
  }
}
