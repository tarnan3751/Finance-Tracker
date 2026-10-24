// Smoke test of the original UI: the home screen renders and the real form adds an expense
// and an income.
import 'package:finance_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _submit(
  WidgetTester tester, {
  required String amount,
  required String description,
  required String button,
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), amount);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Description'),
    description,
  );
  await tester.tap(find.widgetWithText(ElevatedButton, button));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('adding an expense and an income moves the total balance', (
    tester,
  ) async {
    await tester.pumpWidget(const FinanceTrackerApp());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Finance Tracker'), findsOneWidget);
    expect(find.text(r'Total Balance: $0.00'), findsOneWidget);

    await _submit(
      tester,
      amount: '12.50',
      description: 'Coffee',
      button: 'Add Transaction',
    );
    expect(find.text(r'Total Balance: $-12.50'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text(r'-$12.50'), findsOneWidget);

    await _submit(
      tester,
      amount: '100',
      description: 'Salary',
      button: 'Add Income',
    );
    expect(find.text(r'Total Balance: $87.50'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text(r'+$100.00'), findsOneWidget);
  });
}
