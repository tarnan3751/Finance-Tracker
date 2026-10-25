// The budget editor: what it refuses before saving, a new budget saved with its first
// period at the current one, an edit, the first period moving only earlier, and a
// delete with undo.
import 'package:finance_tracker/features/budgets/data/in_memory_budget_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/budget_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  // Made in each test's own zone, so its streams run on the test's fake time.
  late InMemoryBudgetRepository budgets;

  Future<void> open(WidgetTester tester, String location) => pumpApp(
    tester,
    initialLocation: location,
    overrides: [storeOverride(seededStore()), budgetsOverride(budgets)],
  );

  // The live budgets, read outside the test's fake time.
  Future<List<Budget>> live(WidgetTester tester) async =>
      (await tester.runAsync(() => budgets.watchAll().first))!;

  Future<void> seed() async {
    budgets = seededBudgets();
    addTearDown(budgets.close);
  }

  testWidgets('refuses to save without a category, an amount or a valid day', (
    tester,
  ) async {
    await seed();
    await open(tester, '/budgets/new');

    await tester.enterText(_field('Period starts on day'), '29');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a category'), findsNWidgets(2));
    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Enter a day from 1 to 28'), findsOneWidget);
    expect(await live(tester), hasLength(3));

    await tester.enterText(_field('Amount per period'), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount'), findsOneWidget);
  });

  testWidgets('saves a new budget from the current period', (tester) async {
    await seed();
    await open(tester, '/budgets/new');

    await tester.tap(find.text('Choose a category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Groceries');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Groceries').last);
    await tester.pumpAndSettle();
    await tester.enterText(_field('Amount per period'), '250.50');
    await tester.enterText(_field('Period starts on day'), '15');
    await tester.tap(find.text('Carry over'));
    await tester.pumpAndSettle();
    // The current period of a budget from the 15th, on 24 October.
    expect(find.text('Oct 15, 2026'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Budgets'), findsOneWidget);
    final Budget saved = (await live(tester))
        .singleWhere((b) => b.categoryId == 'plaid:FOOD_AND_DRINK_GROCERIES');
    expect(saved.amount, Money(25050, 'USD'));
    expect(saved.periodStartDay, 15);
    expect(saved.rollover, isTrue);
    expect(saved.startDate, LocalDate(2026, 10, 15));
    expect(saved.period, BudgetPeriodKind.monthly);
  });

  testWidgets('edits a budget and keeps its first period', (tester) async {
    await seed();
    await open(tester, '/budgets/budget-food');

    expect(find.widgetWithText(AppBar, 'Edit budget'), findsOneWidget);
    expect(find.text('Sep 1, 2026'), findsOneWidget);
    await tester.enterText(_field('Amount per period'), '9');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final Budget saved = (await live(tester))
        .singleWhere((b) => b.id == 'budget-food');
    expect(saved.amount, Money(900, 'USD'));
    expect(saved.startDate, LocalDate(2026, 9, 1));
  });

  testWidgets('the first period can move earlier, not later', (tester) async {
    await seed();
    await open(tester, '/budgets/budget-food');

    await tester.tap(find.text('Sep 1, 2026'));
    await tester.pumpAndSettle();
    final DatePickerDialog picker = tester.widget(
      find.byType(DatePickerDialog),
    );
    expect(picker.lastDate, DateTime(2026, 10, 1));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('deletes back to the list and undoes', (tester) async {
    await seed();
    await open(tester, '/budgets/budget-food');

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Budgets'), findsOneWidget);
    expect(find.text('Budget deleted'), findsOneWidget);
    expect(find.text('Food and drink'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Food and drink'), findsOneWidget);
  });

  testWidgets('a deleted budget is not found', (tester) async {
    await seed();
    await budgets.delete('budget-food');
    await open(tester, '/budgets/budget-food');

    expect(find.text('This budget no longer exists.'), findsOneWidget);
  });
}
