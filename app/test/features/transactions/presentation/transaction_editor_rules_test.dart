// "Run rules on this transaction" in the editor's menu: the rules apply to the values in
// the form (a new transaction's too), a snack bar names the rule or says none matched,
// and only Save writes what they changed.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/rule_seed.dart';
import '../../../helpers/seed.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

const Rule _coffee = Rule(
  id: 'rule-coffee',
  name: 'Coffee runs',
  position: 0,
  conditions: [
    RuleCondition(kind: RuleConditionKind.merchantContains, text: 'coffee'),
  ],
  actions: [
    RuleAction(
      kind: RuleActionKind.setCategory,
      value: 'plaid:FOOD_AND_DRINK_COFFEE',
    ),
    RuleAction(kind: RuleActionKind.addTag, value: 'coffee'),
  ],
);

Future<void> _runRules(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More options'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Run rules on this transaction'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new transaction: the rule fills the form, Save keeps it', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await pumpApp(
      tester,
      initialLocation: '/transactions/new?account=$checkingId',
      overrides: [
        storeOverride(store),
        rulesOverride(seededRules(rules: const [_coffee])),
      ],
      size: const Size(412, 1600),
    );
    await tester.enterText(_field('Amount'), '4.50');
    await tester.enterText(_field('Description'), 'Corner Coffee');
    await _runRules(tester);

    expect(
      find.text('Applied the rule “Coffee runs”. Save to keep it.'),
      findsOneWidget,
    );
    expect(find.text('Coffee'), findsWidgets);
    expect(find.text('#coffee'), findsOneWidget);
    expect(
      store.transactions(TransactionQuery(text: 'Corner')),
      isEmpty,
      reason: 'nothing is written before Save',
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final Transaction saved = store
        .transactions(TransactionQuery(text: 'Corner'))
        .single;
    expect(saved.userCategoryId, 'plaid:FOOD_AND_DRINK_COFFEE');
    expect(saved.tags, ['coffee']);
    expect(saved.source, DataSource.manual);
  });

  testWidgets('no match, and a match with nothing to change', (tester) async {
    final InMemoryStore store = seededStore();
    await pumpApp(
      tester,
      initialLocation: '/transactions/new?account=$checkingId',
      overrides: [
        storeOverride(store),
        rulesOverride(seededRules(rules: const [_coffee])),
      ],
      size: const Size(412, 1600),
    );
    await tester.enterText(_field('Amount'), '4.50');
    await tester.enterText(_field('Description'), 'Lunch');
    await _runRules(tester);
    expect(find.text('No rule matches this transaction.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    // The rule fills the form; run again, it has nothing left to change.
    await tester.enterText(_field('Description'), 'Coffee');
    await _runRules(tester);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    await _runRules(tester);
    expect(
      find.text('The rule “Coffee runs” matches, but has nothing to change.'),
      findsOneWidget,
    );
  });

  testWidgets('an invalid form runs no rule', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/transactions/new?account=$checkingId',
      overrides: [
        storeOverride(seededStore()),
        rulesOverride(seededRules(rules: const [_coffee])),
      ],
      size: const Size(412, 1600),
    );
    await _runRules(tester);
    expect(find.textContaining('rule'), findsNothing);
  });
}
