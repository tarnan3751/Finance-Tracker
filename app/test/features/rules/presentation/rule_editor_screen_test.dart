// The rule editor: a rule needs a name, a condition and an action, and each row its
// value; every condition and action kind round-trips, hide included; an edited rule keeps
// every action; the bank category picker offers only the built-in categories; delete
// offers an undo; the preview counts and lists what the rule as edited would change, once
// every row has a value; a saved, unchanged rule applies to the existing transactions
// behind a confirmation, once.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/features/rules/data/in_memory_rule_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/rule_seed.dart';
import '../../../helpers/seed.dart';

/// The editor at a height that lays out every row in the test font.
const Size _tall = Size(412, 2400);

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<InMemoryRuleRepository> _pump(
  WidgetTester tester,
  String location, {
  InMemoryStore? store,
  List<Rule>? initial,
}) async {
  final InMemoryRuleRepository rules = seededRules(rules: initial);
  await pumpApp(
    tester,
    initialLocation: location,
    overrides: [storeOverride(store ?? seededStore()), rulesOverride(rules)],
    size: _tall,
  );
  return rules;
}

Future<List<Rule>> _live(
  WidgetTester tester,
  InMemoryRuleRepository rules,
) async => (await tester.runAsync(() => rules.watchAll().first))!;

Future<void> _add(WidgetTester tester, String menu, String item) async {
  await tester.tap(find.byTooltip(menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Future<void> _pickCategory(
  WidgetTester tester,
  Finder field,
  String name,
) async {
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'Search categories'),
    name,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty rule does not save', (tester) async {
    final InMemoryRuleRepository rules = await _pump(
      tester,
      '/settings/rules/new',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('A rule needs at least one condition.'), findsOneWidget);
    expect(find.text('A rule needs at least one action.'), findsOneWidget);

    await tester.enterText(_field('Name'), 'Coffee');
    await _add(tester, 'Add condition', 'Merchant or description contains');
    await _add(tester, 'Add action', 'Add a tag');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter some text'), findsOneWidget);
    expect(find.text('Enter a tag'), findsOneWidget);
    expect(await _live(tester, rules), hasLength(2));
  });

  testWidgets('every kind of row saves, after the existing rules', (
    tester,
  ) async {
    final InMemoryRuleRepository rules = await _pump(
      tester,
      '/settings/rules/new',
    );
    await tester.enterText(_field('Name'), 'Card coffee');

    await _add(tester, 'Add condition', 'Merchant or description contains');
    await tester.enterText(_field('Text'), ' Blue Bottle ');
    await _add(tester, 'Add condition', 'Amount between');
    await tester.enterText(_field('At least'), '1');
    await tester.enterText(_field('At most'), '20.50');
    await _add(tester, 'Add condition', 'Account is');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rewards Card').last);
    await tester.pumpAndSettle();
    await _add(tester, 'Add condition', 'Bank category is');
    await _pickCategory(
      tester,
      find.widgetWithText(InputDecorator, 'Bank category is').last,
      'Coffee',
    );

    await _add(tester, 'Add action', 'Set the category');
    await _pickCategory(
      tester,
      find.widgetWithText(InputDecorator, 'Set the category').last,
      'Coffee',
    );
    await _add(tester, 'Add action', 'Add a tag');
    await tester.enterText(_field('Tag'), 'coffee');
    await _add(tester, 'Add action', 'Rename');
    await tester.enterText(_field('New description'), 'Coffee');
    expect(
      find.text(
        'Renames manual and imported transactions. Bank transactions keep the '
        'description your bank sends.',
      ),
      findsOneWidget,
    );
    await _add(tester, 'Add action', 'Hide');
    expect(
      find.text(
        'Hidden transactions leave the list, budgets and reports, and still '
        "count toward their account's balance.",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final Rule saved = (await _live(tester, rules)).last;
    expect(saved.name, 'Card coffee');
    expect(saved.position, 2);
    expect(saved.conditions, [
      const RuleCondition(
        kind: RuleConditionKind.merchantContains,
        text: 'Blue Bottle',
      ),
      RuleCondition(
        kind: RuleConditionKind.amountBetween,
        minAmount: Money(100, 'USD'),
        maxAmount: Money(2050, 'USD'),
      ),
      const RuleCondition(kind: RuleConditionKind.account, text: cardId),
      const RuleCondition(
        kind: RuleConditionKind.plaidCategory,
        text: 'FOOD_AND_DRINK_COFFEE',
      ),
    ]);
    expect(saved.actions, const [
      RuleAction(
        kind: RuleActionKind.setCategory,
        value: 'plaid:FOOD_AND_DRINK_COFFEE',
      ),
      RuleAction(kind: RuleActionKind.addTag, value: 'coffee'),
      RuleAction(kind: RuleActionKind.rename, value: 'Coffee'),
      RuleAction(kind: RuleActionKind.hide),
    ]);
  });

  testWidgets(
    'an amount range needs a bound, and its minimum below its maximum',
    (tester) async {
      await _pump(tester, '/settings/rules/new');
      await _add(tester, 'Add condition', 'Amount between');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter at least one amount'), findsOneWidget);
      await tester.enterText(_field('At least'), '30');
      await tester.enterText(_field('At most'), '20');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('The minimum is above the maximum'), findsOneWidget);
    },
  );

  testWidgets('an edit keeps the actions it shows, the hide action included', (
    tester,
  ) async {
    final InMemoryRuleRepository rules = await _pump(
      tester,
      '/settings/rules/${everyKindRule.id}',
    );
    expect(find.text('Edit rule'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Hide'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('Rewards Card'), findsOneWidget);
    expect(find.text('Coffee'), findsWidgets);
    await tester.enterText(_field('Name'), 'Coffee, card');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      (await _live(tester, rules)).first,
      everyKindRule.copyWith(name: 'Coffee, card'),
    );
  });

  testWidgets('the bank category picker offers only built-in categories', (
    tester,
  ) async {
    final InMemoryStore store = seededStore()
      ..upsertCategory(
        const Category(
          id: 'mine',
          name: 'Coffee beans',
          isSystem: false,
          icon: 'coffee',
          color: 1,
        ),
      );
    await _pump(tester, '/settings/rules/new', store: store);
    await _add(tester, 'Add condition', 'Bank category is');
    await tester.tap(
      find.widgetWithText(InputDecorator, 'Bank category is').last,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search categories'),
      'Coffee',
    );
    await tester.pumpAndSettle();
    expect(find.text('Coffee beans'), findsNothing);
    expect(find.text('Coffee'), findsWidgets);
  });

  testWidgets('delete closes the editor and offers an undo', (tester) async {
    final InMemoryRuleRepository rules = await _pump(tester, '/settings/rules');
    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Rule deleted'), findsOneWidget);
    expect(await _live(tester, rules), hasLength(1));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await _live(tester, rules), hasLength(2));
  });

  testWidgets('a rule that no longer exists says so', (tester) async {
    await _pump(tester, '/settings/rules/missing');
    expect(find.text('This rule no longer exists.'), findsOneWidget);
  });

  testWidgets('the preview counts and lists what the rule as edited would '
      'change', (tester) async {
    await _pump(tester, '/settings/rules/new');
    await _add(tester, 'Add condition', 'Merchant or description contains');
    await _add(tester, 'Add action', 'Add a tag');
    expect(
      find.text(
        'Finish the conditions and actions to see what this rule would '
        'change.',
      ),
      findsOneWidget,
    );

    await tester.enterText(_field('Text'), 'rent');
    await tester.enterText(_field('Tag'), 'home');
    await tester.pump(const Duration(milliseconds: 100));
    // Not yet: the preview waits for the edits to stop.
    expect(find.text('Would change 2 of 12 transactions'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Would change 2 of 12 transactions'), findsOneWidget);

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.text('What this rule would change'), findsOneWidget);
    expect(find.textContaining('Tag added: home'), findsNWidgets(2));

    // Nothing was written.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Text'), 'nothing matches this');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Would change 0 of 12 transactions'), findsOneWidget);
    final TextButton preview = tester.widget(
      find.widgetWithText(TextButton, 'Preview'),
    );
    expect(preview.onPressed, isNull);
  });

  testWidgets('a saved rule is previewed as it opens', (tester) async {
    await _pump(tester, '/settings/rules/rule-groceries');
    await tester.pumpAndSettle();
    expect(find.text('Would change 0 of 12 transactions'), findsOneWidget);
  });

  testWidgets('a saved, unchanged rule applies to the existing transactions '
      'once', (tester) async {
    final InMemoryStore store = seededStore();
    await _pump(
      tester,
      '/settings/rules/rule-rent',
      store: store,
      initial: [everyKindRule, groceriesRule, rentRule],
    );
    await tester.pumpAndSettle();
    expect(find.text('Would change 2 of 12 transactions'), findsOneWidget);

    Future<void> apply() async {
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply to existing transactions'));
      await tester.pumpAndSettle();
      expect(
        find.text('Apply “Rent” to existing transactions?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
    }

    await apply();
    expect(
      find.text(
        '2 transactions changed: 0 filed, 2 tagged, 0 renamed, 0 hidden',
      ),
      findsOneWidget,
    );
    expect(
      store.transactions(TransactionQuery(tags: const {'home'})),
      hasLength(2),
    );
    expect(find.text('Would change 0 of 12 transactions'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(Form)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await apply();
    expect(find.text('No transactions changed.'), findsOneWidget);
  });

  testWidgets('a rule with unsaved changes is not applied', (tester) async {
    await _pump(
      tester,
      '/settings/rules/rule-rent',
      initial: [everyKindRule, groceriesRule, rentRule],
    );
    await tester.enterText(_field('Name'), 'Rent and more');
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    expect(find.text('Save the rule first'), findsOneWidget);
    await tester.tap(find.text('Apply to existing transactions'));
    await tester.pumpAndSettle();
    expect(find.text('Apply “Rent” to existing transactions?'), findsNothing);
  });

  testWidgets('a new rule has no menu', (tester) async {
    await _pump(tester, '/settings/rules/new');
    expect(find.byTooltip('More options'), findsNothing);
  });
}
