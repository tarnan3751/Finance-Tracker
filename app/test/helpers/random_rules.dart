// Seeded random rules and transactions over small alphabets, so conditions often match
// and actions often collide: for the engine's property tests, the sync store's
// round-trips and the convergence runs.
import 'dart:math';

import 'package:shared_models/shared_models.dart';

/// Merchants, accounts, Plaid codes, categories and tags the random values draw from.
const List<String> randomMerchants = ['Starbucks', 'Uber', 'Costco', 'café'];
const List<String> randomAccounts = ['a1', 'a2'];
const List<String> randomPlaidCodes = [
  'FOOD_AND_DRINK',
  'FOOD_AND_DRINK_COFFEE',
  'TRANSPORTATION',
];
const List<String> randomCategories = ['c1', 'c2', 'missing'];
const List<String> randomTags = ['x', 'y', 'z'];

T _pick<T>(Random random, List<T> values) =>
    values[random.nextInt(values.length)];

/// A random condition; sometimes one that can never match (no text, no bounds, a bound
/// in another currency).
RuleCondition randomCondition(Random random) => switch (_pick(
  random,
  RuleConditionKind.values,
)) {
  RuleConditionKind.merchantContains => RuleCondition(
    kind: RuleConditionKind.merchantContains,
    text: random.nextInt(8) == 0
        ? null
        : _pick(random, randomMerchants).substring(0, 1 + random.nextInt(3)),
  ),
  RuleConditionKind.amountBetween => RuleCondition(
    kind: RuleConditionKind.amountBetween,
    minAmount: random.nextBool()
        ? null
        : Money(random.nextInt(3000), random.nextInt(8) == 0 ? 'EUR' : 'USD'),
    maxAmount: random.nextBool() ? null : Money(random.nextInt(6000), 'USD'),
  ),
  RuleConditionKind.account => RuleCondition(
    kind: RuleConditionKind.account,
    text: _pick(random, randomAccounts),
  ),
  RuleConditionKind.plaidCategory => RuleCondition(
    kind: RuleConditionKind.plaidCategory,
    text: _pick(random, randomPlaidCodes),
  ),
};

/// A random action.
RuleAction randomAction(Random random) =>
    switch (_pick(random, RuleActionKind.values)) {
      RuleActionKind.setCategory => RuleAction(
        kind: RuleActionKind.setCategory,
        value: _pick(random, randomCategories),
      ),
      RuleActionKind.addTag => RuleAction(
        kind: RuleActionKind.addTag,
        value: _pick(random, randomTags),
      ),
      RuleActionKind.rename => RuleAction(
        kind: RuleActionKind.rename,
        value: 'Renamed ${random.nextInt(3)}',
      ),
      RuleActionKind.hide => const RuleAction(kind: RuleActionKind.hide),
    };

/// A random rule [id]; positions collide on purpose.
Rule randomRule(Random random, String id) => Rule(
  id: id,
  name: 'Rule $id',
  position: random.nextInt(4),
  conditions: [
    for (
      int i = random.nextInt(3) + (random.nextInt(10) == 0 ? 0 : 1);
      i > 0;
      i--
    )
      randomCondition(random),
  ],
  actions: [
    for (
      int i = random.nextInt(3) + (random.nextInt(10) == 0 ? 0 : 1);
      i > 0;
      i--
    )
      randomAction(random),
  ],
);

/// A random transaction [id], of a random source.
Transaction randomTransaction(Random random, String id) {
  final String merchant = _pick(random, randomMerchants);
  return Transaction(
    id: id,
    accountId: _pick(random, randomAccounts),
    amount: Money(random.nextInt(8000) - 6000, 'USD'),
    date: LocalDate(2026, 10, 1 + random.nextInt(20)),
    pending: random.nextBool(),
    name: '${merchant.toUpperCase()} #${random.nextInt(99)}',
    merchantName: random.nextBool() ? merchant : null,
    plaidPrimaryCategory: random.nextBool() ? 'FOOD_AND_DRINK' : null,
    plaidDetailedCategory: random.nextBool()
        ? _pick(random, randomPlaidCodes)
        : null,
    userCategoryId: random.nextInt(4) == 0 ? 'c2' : null,
    tags: [
      for (int i = random.nextInt(3); i > 0; i--) _pick(random, randomTags),
    ],
    splits: random.nextInt(6) == 0
        ? [TransactionSplit(categoryId: 'c1', amount: Money(-1, 'USD'))]
        : const [],
    source: _pick(random, const [
      DataSource.manual,
      DataSource.import,
      DataSource.plaid,
      DataSource.demo,
    ]),
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
    syncVersion: 0,
  );
}
