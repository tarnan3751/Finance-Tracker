// Rules for screen tests, over the test seed's accounts and the system categories: one
// with a row of every condition and action kind,
// and a plain one after it.
//
//   final InMemoryRuleRepository rules = seededRules();
//   await pumpApp(tester, overrides: [storeOverride(seededStore()), rulesOverride(rules)]);
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/rules/data/in_memory_rule_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_models/shared_models.dart';

import 'pump_app.dart';
import 'seed.dart';

/// The rule with every kind of row.
final Rule everyKindRule = Rule(
  id: 'rule-every',
  name: 'Coffee on the card',
  position: 0,
  conditions: [
    const RuleCondition(
      kind: RuleConditionKind.merchantContains,
      text: 'Coffee',
    ),
    RuleCondition(
      kind: RuleConditionKind.amountBetween,
      minAmount: Money(100, 'USD'),
      maxAmount: Money(2500, 'USD'),
    ),
    const RuleCondition(kind: RuleConditionKind.account, text: cardId),
    const RuleCondition(
      kind: RuleConditionKind.plaidCategory,
      text: 'FOOD_AND_DRINK_COFFEE',
    ),
  ],
  actions: const [
    RuleAction(
      kind: RuleActionKind.setCategory,
      value: 'plaid:FOOD_AND_DRINK_COFFEE',
    ),
    RuleAction(kind: RuleActionKind.addTag, value: 'coffee'),
    RuleAction(kind: RuleActionKind.rename, value: 'Coffee'),
    RuleAction(kind: RuleActionKind.hide),
  ],
);

/// A plain rule after [everyKindRule].
const Rule groceriesRule = Rule(
  id: 'rule-groceries',
  name: 'Groceries',
  position: 1,
  conditions: [
    RuleCondition(kind: RuleConditionKind.merchantContains, text: 'Market'),
  ],
  actions: [
    RuleAction(
      kind: RuleActionKind.setCategory,
      value: 'plaid:FOOD_AND_DRINK_GROCERIES',
    ),
  ],
);

/// An in-memory rule repository on [testClock] holding [rules] ([everyKindRule] and
/// [groceriesRule] by default), recording nothing.
InMemoryRuleRepository seededRules({List<Rule>? rules}) =>
    InMemoryRuleRepository(
      testClock,
      recorder: const NoChangeRecorder(),
      initial: rules ?? [everyKindRule, groceriesRule],
    );

/// The override that makes [rules] the app's rule repository.
Override rulesOverride(InMemoryRuleRepository rules) =>
    ruleRepositoryProvider.overrideWithValue(rules);
