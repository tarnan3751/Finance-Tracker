// The rules engine: each condition and action, the first match, and, over seeded random
// rules and transactions, determinism (the same input twice, and in any order, gives the
// same outcome) and idempotence (applying to the result changes nothing).
import 'dart:convert';
import 'dart:math';

import 'package:finance_tracker/features/rules/domain/rules_engine.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/random_rules.dart';

final CategoryLookup _lookup = categoryLookup(const [
  Category(id: 'c1', name: 'Coffee', isSystem: false, icon: 'x', color: 0),
  Category(id: 'c2', name: 'Rides', isSystem: false, icon: 'x', color: 0),
]);

Transaction _t({
  String name = 'STARBUCKS STORE 08812',
  String? merchant = 'Starbucks',
  int minor = -450,
  String currency = 'USD',
  DataSource source = DataSource.plaid,
  String? category,
  List<String> tags = const [],
  List<TransactionSplit> splits = const [],
}) => Transaction(
  id: 't1',
  accountId: 'a1',
  amount: Money(minor, currency),
  date: LocalDate(2026, 10, 1),
  pending: false,
  name: name,
  merchantName: merchant,
  plaidPrimaryCategory: 'FOOD_AND_DRINK',
  plaidDetailedCategory: 'FOOD_AND_DRINK_COFFEE',
  userCategoryId: category,
  tags: tags,
  splits: splits,
  source: source,
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
  syncVersion: 0,
);

Rule _rule(
  String id,
  List<RuleCondition> conditions,
  List<RuleAction> actions, {
  int position = 0,
}) => Rule(
  id: id,
  name: id,
  position: position,
  conditions: conditions,
  actions: actions,
);

RuleCondition _text(RuleConditionKind kind, String? text) =>
    RuleCondition(kind: kind, text: text);

RuleCondition _amount(Money? min, Money? max) => RuleCondition(
  kind: RuleConditionKind.amountBetween,
  minAmount: min,
  maxAmount: max,
);

const RuleAction _category = RuleAction(
  kind: RuleActionKind.setCategory,
  value: 'c1',
);

bool _matches(RuleCondition condition, Transaction t) =>
    conditionMatches(condition, t);

void main() {
  group('conditions', () {
    test('merchant contains: the merchant name, else the name, any case', () {
      final RuleCondition star = _text(
        RuleConditionKind.merchantContains,
        ' starBUCKS ',
      );
      expect(_matches(star, _t()), isTrue);
      expect(_matches(star, _t(merchant: null)), isTrue);
      expect(_matches(star, _t(merchant: 'Blue Bottle')), isFalse);
      // An empty or blank merchant name counts as none: the name is matched.
      expect(_matches(star, _t(merchant: '')), isTrue);
      expect(_matches(star, _t(merchant: '  ')), isTrue);
      expect(_matches(star, _t(name: 'Lunch', merchant: ' ')), isFalse);
      expect(
        _matches(
          _text(RuleConditionKind.merchantContains, 'CAFÉ'),
          _t(merchant: 'Le café'),
        ),
        isTrue,
      );
      expect(
        _matches(_text(RuleConditionKind.merchantContains, ' '), _t()),
        isFalse,
      );
      expect(
        _matches(_text(RuleConditionKind.merchantContains, null), _t()),
        isFalse,
      );
    });

    test('amount between: inclusive bounds on the absolute amount', () {
      expect(
        _matches(_amount(Money(450, 'USD'), Money(450, 'USD')), _t()),
        isTrue,
      );
      expect(_matches(_amount(Money(451, 'USD'), null), _t()), isFalse);
      expect(_matches(_amount(null, Money(449, 'USD')), _t()), isFalse);
      expect(
        _matches(_amount(null, Money(500, 'USD')), _t(minor: 450)),
        isTrue,
      );
      expect(_matches(_amount(null, null), _t()), isFalse);
    });

    test('amount between: a bound in another currency never matches', () {
      expect(_matches(_amount(Money(1, 'EUR'), null), _t()), isFalse);
      expect(
        _matches(_amount(Money(1, 'USD'), Money(9999, 'EUR')), _t()),
        isFalse,
      );
      expect(
        _matches(_amount(Money(1, 'EUR'), null), _t(currency: 'EUR')),
        isTrue,
      );
    });

    test('account and Plaid category', () {
      expect(_matches(_text(RuleConditionKind.account, 'a1'), _t()), isTrue);
      expect(_matches(_text(RuleConditionKind.account, 'a2'), _t()), isFalse);
      for (final String code in ['FOOD_AND_DRINK', 'FOOD_AND_DRINK_COFFEE']) {
        expect(
          _matches(_text(RuleConditionKind.plaidCategory, code), _t()),
          isTrue,
        );
      }
      expect(
        _matches(_text(RuleConditionKind.plaidCategory, 'FOOD'), _t()),
        isFalse,
      );
    });

    test('every condition must match; no condition or action never does', () {
      final RuleCondition yes = _text(RuleConditionKind.account, 'a1');
      final RuleCondition no = _text(RuleConditionKind.account, 'a2');
      expect(ruleMatches(_rule('r', [yes, yes], [_category]), _t()), isTrue);
      expect(ruleMatches(_rule('r', [yes, no], [_category]), _t()), isFalse);
      expect(ruleMatches(_rule('r', [], [_category]), _t()), isFalse);
      expect(ruleMatches(_rule('r', [yes], []), _t()), isFalse);
    });
  });

  group('actions', () {
    final RuleCondition any = _text(RuleConditionKind.account, 'a1');

    RuleOutcome run(
      List<RuleAction> actions,
      Transaction t, {
      Set<String> owned = const {},
    }) => applyRules(
      [
        _rule('r1', [any], actions),
      ],
      t,
      lookup: _lookup,
      ownedFields: owned,
    );

    test('set category fills an unset category only', () {
      expect(run([_category], _t()).changed!.userCategoryId, 'c1');
      final RuleOutcome set = run([_category], _t(category: 'c2'));
      expect(set.changed, isNull);
      expect(set.skipped.single.reason, RuleSkip.alreadySet);
    });

    test('set category skips an unknown category, splits, an owned field', () {
      expect(
        run(const [
          RuleAction(kind: RuleActionKind.setCategory, value: 'gone'),
        ], _t()).skipped.single.reason,
        RuleSkip.unknownCategory,
      );
      expect(
        run(
          [_category],
          _t(
            splits: [
              TransactionSplit(categoryId: 'c2', amount: Money(-450, 'USD')),
            ],
          ),
        ).skipped.single.reason,
        RuleSkip.splitTransaction,
      );
      expect(
        run(
          [_category],
          _t(),
          owned: {ruleCategoryField},
        ).skipped.single.reason,
        RuleSkip.ownedByUser,
      );
    });

    test('add tag appends once, and leaves an owned field', () {
      const RuleAction tag = RuleAction(
        kind: RuleActionKind.addTag,
        value: 'coffee',
      );
      expect(run([tag], _t(tags: ['a'])).changed!.tags, ['a', 'coffee']);
      expect(run([tag], _t(tags: ['coffee'])).changed, isNull);
      expect(run([tag], _t(), owned: {ruleTagsField}).changed, isNull);
    });

    test('rename: manual and import rows only', () {
      const RuleAction rename = RuleAction(
        kind: RuleActionKind.rename,
        value: 'Coffee',
      );
      for (final DataSource source in [DataSource.manual, DataSource.import]) {
        expect(run([rename], _t(source: source)).changed!.name, 'Coffee');
      }
      for (final DataSource source in [DataSource.plaid, DataSource.demo]) {
        final RuleOutcome outcome = run([rename], _t(source: source));
        expect(outcome.changed, isNull);
        expect(outcome.skipped.single.reason, RuleSkip.bankName);
      }
    });

    test('hide is not applied; the other actions still are', () {
      final RuleOutcome outcome = run([
        const RuleAction(kind: RuleActionKind.hide),
        _category,
      ], _t());
      expect(outcome.changed!.userCategoryId, 'c1');
      expect(outcome.skipped, [
        (kind: RuleActionKind.hide, reason: RuleSkip.unsupported),
      ]);
    });

    test('an empty value is skipped', () {
      expect(
        run(const [
          RuleAction(kind: RuleActionKind.addTag, value: ' '),
        ], _t()).skipped.single.reason,
        RuleSkip.emptyValue,
      );
    });
  });

  group('the first match', () {
    final RuleCondition any = _text(RuleConditionKind.account, 'a1');

    test('rules run in position order, then id; the first match wins', () {
      final List<Rule> rules = [
        _rule('b', [any], [_category], position: 1),
        _rule('z', [any], [_category], position: 0),
        _rule('a', [any], [_category], position: 1),
      ];
      expect(applyRules(rules, _t(), lookup: _lookup).rule!.id, 'z');
      expect(
        applyRules(
          rules.sublist(0, 1) + rules.sublist(2),
          _t(),
          lookup: _lookup,
        ).rule!.id,
        'a',
      );
    });

    test('position ties break by id in UTF-8 byte order, as the repositories '
        'list them', () {
      // U+FFFD sorts before U+1F600 in UTF-16 code units, after it in UTF-8 bytes.
      final RuleCondition yes = _text(RuleConditionKind.account, 'a1');
      final List<Rule> rules = [
        _rule('\u{FFFD}', [yes], [_category]),
        _rule('\u{1F600}', [yes], [_category]),
      ];
      expect(applyRules(rules, _t(), lookup: _lookup).rule!.id, '\u{FFFD}');
    });

    test('a matching rule that changes nothing still stops the rest', () {
      final RuleOutcome outcome = applyRules(
        [
          _rule('first', [any], const [RuleAction(kind: RuleActionKind.hide)]),
          _rule('second', [any], [_category], position: 1),
        ],
        _t(),
        lookup: _lookup,
      );
      expect(outcome.rule!.id, 'first');
      expect(outcome.changed, isNull);
    });

    test('no match', () {
      final RuleOutcome outcome = applyRules(
        [
          _rule('r', [_text(RuleConditionKind.account, 'a2')], [_category]),
        ],
        _t(),
        lookup: _lookup,
      );
      expect(outcome.rule, isNull);
      expect(outcome.changed, isNull);
      expect(outcome.skipped, isEmpty);
    });
  });

  group('properties', () {
    // The outcome as text, so two runs compare field by field.
    String describe(RuleOutcome o) => jsonEncode({
      'rule': o.rule?.id,
      'changed': o.changed?.toJson(),
      'skipped': [for (final s in o.skipped) '${s.kind.name}:${s.reason.name}'],
    });

    test('the same rules over the same transactions give the same outcomes, '
        'in any order', () {
      final List<String> first = [];
      final List<String> second = [];
      for (int seed = 0; seed < 300; seed++) {
        final Random random = Random(seed);
        final List<Rule> rules = [
          for (int i = random.nextInt(6); i > 0; i--) randomRule(random, 'r$i'),
        ];
        final List<Transaction> transactions = [
          for (int i = 0; i < 10; i++) randomTransaction(random, 't$i'),
        ];
        for (final Transaction t in transactions) {
          first.add(describe(applyRules(rules, t, lookup: _lookup)));
          second.add(
            describe(
              applyRules(
                [...rules]..shuffle(Random(seed + 1)),
                t,
                lookup: _lookup,
              ),
            ),
          );
        }
      }
      expect(second, first);
    });

    test('applying the rules to their result changes nothing, unless a rename '
        'made another rule match', () {
      int changed = 0;
      for (int seed = 0; seed < 300; seed++) {
        final Random random = Random(seed);
        final List<Rule> rules = [
          for (int i = random.nextInt(6); i > 0; i--) randomRule(random, 'r$i'),
        ];
        for (int i = 0; i < 10; i++) {
          final Transaction t = randomTransaction(random, 't$i');
          final RuleOutcome once = applyRules(rules, t, lookup: _lookup);
          final Transaction? result = once.changed;
          if (result == null) continue;
          changed++;
          final RuleOutcome twice = applyRules(rules, result, lookup: _lookup);
          if (result.name != t.name && twice.rule != once.rule) continue;
          expect(twice.rule, once.rule, reason: 'seed $seed');
          expect(twice.changed, isNull, reason: 'seed $seed');
        }
      }
      expect(changed, greaterThan(100), reason: 'the inputs exercise changes');
    });

    test('a rename can make a later rule match on the next run', () {
      final Transaction manual = _t(merchant: null, source: DataSource.manual);
      final List<Rule> rules = [
        _rule(
          'rename',
          [_text(RuleConditionKind.merchantContains, 'starbucks')],
          const [RuleAction(kind: RuleActionKind.rename, value: 'Coffee')],
        ),
        _rule(
          'file',
          [_text(RuleConditionKind.merchantContains, 'coffee')],
          [_category],
          position: 1,
        ),
      ];
      final Transaction renamed = applyRules(
        rules,
        manual,
        lookup: _lookup,
      ).changed!;
      expect(renamed.name, 'Coffee');
      expect(renamed.userCategoryId, isNull);
      final RuleOutcome again = applyRules(rules, renamed, lookup: _lookup);
      expect(again.rule!.id, 'file');
      expect(again.changed!.userCategoryId, 'c1');
    });
  });
}
