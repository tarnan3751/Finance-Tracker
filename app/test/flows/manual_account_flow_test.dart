// The manual-account flow end to end on the in-memory repositories: create an account
// with an opening balance, add an expense from its detail, watch the derived balance and
// the running balance move, delete the expense and undo the delete.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/seed.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('account, opening balance, expense, delete and undo', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: [storeOverride(seededStore(seed: const DemoSeed.empty()))],
      size: const Size(412, 1600),
    );

    // A new account with an opening balance.
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Name'), 'Checking');
    await tester.enterText(_field('Opening balance (optional)'), '1,000');
    // Dated the 1st, before the expense (the test clock never moves, so two transactions
    // on one day would tie on their creation time).
    await tester.tap(find.text('Opening balance date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text(r'$1,000.00'), findsOneWidget);

    // Its detail: the balance and the opening balance's running balance.
    await tester.tap(find.text('Checking'));
    await tester.pumpAndSettle();
    expect(find.text(r'$1,000.00'), findsWidgets);
    expect(find.text(r'Running balance $1,000.00'), findsOneWidget);

    // An expense from the detail, on this account.
    await tester.tap(find.text('Add transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Amount'), '25.50');
    await tester.enterText(_field('Description'), 'Groceries run');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Checking'), findsOneWidget);
    expect(find.text(r'$974.50'), findsOneWidget);
    expect(find.text(r'Running balance $974.50'), findsOneWidget);
    expect(find.text(r'Running balance $1,000.00'), findsOneWidget);

    // Delete it from its editor, then undo.
    await tester.tap(find.text('Groceries run'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries run'), findsNothing);
    expect(find.text(r'Running balance $974.50'), findsNothing);
    expect(find.text(r'$1,000.00'), findsWidgets);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries run'), findsOneWidget);
    expect(find.text(r'$974.50'), findsOneWidget);

    // And the list agrees.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(r'$974.50'), findsOneWidget);
  });
}
