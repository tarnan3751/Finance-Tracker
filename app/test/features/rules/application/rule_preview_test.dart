// What one rule would change in the existing transactions: the changed rows and the
// counts per action; the owned-field guard on plaid rows, asked only about the rows the
// rule would change and giving what asking about every row gives; rename on manual and
// imported rows only; and the rows on live accounts.
import 'package:finance_tracker/features/rules/application/rule_preview.dart';
import 'package:finance_tracker/features/rules/domain/rules_engine.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../contract/repository_fixture.dart';

const Category _coffeeCategory = Category(
  id: 'u1',
  name: 'Coffee',
  isSystem: false,
  icon: 'coffee',
  color: 1,
);

final CategoryLookup _lookup = categoryLookup(const [_coffeeCategory]);

const Rule _coffee = Rule(
  id: 'r-coffee',
  name: 'Coffee',
  position: 0,
  conditions: [
    RuleCondition(kind: RuleConditionKind.merchantContains, text: 'coffee'),
  ],
  actions: [
    RuleAction(kind: RuleActionKind.setCategory, value: 'u1'),
    RuleAction(kind: RuleActionKind.addTag, value: 'coffee'),
    RuleAction(kind: RuleActionKind.rename, value: 'Coffee'),
  ],
);

Transaction _plaid(String id, {String name = 'BLUE BOTTLE COFFEE'}) =>
    testTransaction(
      id,
      'a1',
      -450,
      name: name,
    ).copyWith(source: DataSource.plaid);

Future<Set<String>> _none(Transaction _) async => const {};

void main() {
  final List<Transaction> ledger = [
    testTransaction('m1', 'a1', -450, name: 'Corner coffee'),
    testTransaction(
      'm2',
      'a1',
      -450,
      name: 'Coffee',
      tags: const ['coffee'],
      userCategoryId: 'u1',
    ),
    testTransaction('m3', 'a1', -1200, name: 'Groceries'),
    testTransaction(
      'm4',
      'a1',
      -450,
      name: 'coffee cart',
      userCategoryId: 'u1',
    ),
    _plaid('p1'),
    _plaid('p2'),
  ];

  test('lists the changed rows in order with the counts per action', () async {
    final RulePreview preview = await evaluateRuleOnHistory(
      _coffee,
      ledger,
      lookup: _lookup,
      ownedFields: _none,
    );
    expect(preview.total, 6);
    expect(
      [for (final RuleChange c in preview.changes) c.before.id],
      ['m1', 'm4', 'p1', 'p2'],
    );
    // m2 already has everything; m4 keeps its category; bank rows keep their names.
    expect(preview.filed, 3);
    expect(preview.tagged, 4);
    expect(preview.renamed, 2);
    final RuleChange p1 = preview.changes[2];
    expect(p1.after.name, 'BLUE BOTTLE COFFEE');
    expect(p1.after.userCategoryId, 'u1');
    expect(p1.after.tags, ['coffee']);
    expect(p1.after.updatedAt, p1.before.updatedAt);
  });

  test('the guard leaves owned fields alone and is asked only about rows the '
      'rule would change', () async {
    final List<String> asked = [];
    Future<Set<String>> owned(Transaction t) async {
      asked.add(t.id);
      return t.id == 'p1' ? const {ruleCategoryField} : const {};
    }

    final RulePreview preview = await evaluateRuleOnHistory(
      _coffee,
      ledger,
      lookup: _lookup,
      ownedFields: owned,
    );
    expect(asked, ['m1', 'm4', 'p1', 'p2']);
    final RuleChange p1 = preview.changes.firstWhere(
      (c) => c.before.id == 'p1',
    );
    expect(p1.after.userCategoryId, isNull);
    expect(p1.after.tags, ['coffee']);
    expect(preview.filed, 2);

    // A row whose every changed field is owned drops out.
    final RulePreview allOwned = await evaluateRuleOnHistory(
      _coffee,
      [_plaid('p1')],
      lookup: _lookup,
      ownedFields: (_) async => const {ruleCategoryField, ruleTagsField},
    );
    expect(allOwned.changes, isEmpty);
    expect(allOwned.total, 1);
  });

  test('asking only about changed rows gives what asking about every row '
      'gives', () async {
    Future<Set<String>> owned(Transaction t) async => switch (t.id) {
      'p1' => const {ruleCategoryField},
      'p2' => const {ruleCategoryField, ruleTagsField},
      _ => const {},
    };
    final RulePreview preview = await evaluateRuleOnHistory(
      _coffee,
      ledger,
      lookup: _lookup,
      ownedFields: owned,
    );
    final List<(String, Transaction)> everyRow = [];
    for (final Transaction t in ledger) {
      final Transaction? after = applyRules(
        [_coffee],
        t,
        lookup: _lookup,
        ownedFields: await owned(t),
      ).changed;
      if (after != null) everyRow.add((t.id, after));
    }
    expect([
      for (final RuleChange c in preview.changes) (c.before.id, c.after),
    ], everyRow);
  });

  test('a hide is counted, on bank rows too', () async {
    const Rule hide = Rule(
      id: 'r-hide',
      name: 'Hide coffee',
      position: 0,
      conditions: [
        RuleCondition(kind: RuleConditionKind.merchantContains, text: 'coffee'),
      ],
      actions: [RuleAction(kind: RuleActionKind.hide)],
    );
    final RulePreview preview = await evaluateRuleOnHistory(
      hide,
      [...ledger, _plaid('p3').copyWith(hidden: true)],
      lookup: _lookup,
      ownedFields: (t) async =>
          t.id == 'p2' ? const {ruleHiddenField} : const {},
    );
    expect(
      [for (final RuleChange c in preview.changes) c.before.id],
      ['m1', 'm2', 'm4', 'p1'],
    );
    expect(preview.hidden, 4);
    expect(preview.filed + preview.tagged + preview.renamed, 0);
  });

  test('applying the result again changes nothing', () async {
    final RulePreview first = await evaluateRuleOnHistory(
      _coffee,
      ledger,
      lookup: _lookup,
      ownedFields: _none,
    );
    final Map<String, Transaction> after = {
      for (final Transaction t in ledger) t.id: t,
      for (final RuleChange c in first.changes) c.before.id: c.after,
    };
    final RulePreview second = await evaluateRuleOnHistory(
      _coffee,
      after.values.toList(),
      lookup: _lookup,
      ownedFields: _none,
    );
    expect(second.changes, isEmpty);
  });

  test('only the rows on live accounts are kept', () {
    expect(
      onLiveAccounts(
        [
          testTransaction('t1', 'a1', -1),
          testTransaction('t2', 'gone', -1),
          testTransaction('t3', 'a2', -1),
        ],
        [testAccount('a1'), testAccount('a2')],
      ).map((t) => t.id),
      ['t1', 't3'],
    );
  });
}
