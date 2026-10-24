// Smoke test of the original UI as the three entry points run it: the home screen renders,
// the real form adds an expense and an income, and the flavor banner shows only where it
// should.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/legacy/legacy_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _flavorBanner(String message) => find.byWidgetPredicate(
  (widget) => widget is Banner && widget.message == message,
);

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
    await tester.pumpWidget(LegacyFinanceTrackerApp(config: AppConfig.demo()));
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

  testWidgets('the DEMO banner shows in demo and not in prod', (tester) async {
    await tester.pumpWidget(LegacyFinanceTrackerApp(config: AppConfig.demo()));
    await tester.pumpAndSettle();
    expect(_flavorBanner('DEMO'), findsOneWidget);

    await tester.pumpWidget(LegacyFinanceTrackerApp(config: AppConfig.prod()));
    await tester.pumpAndSettle();
    expect(_flavorBanner('DEMO'), findsNothing);
    expect(_flavorBanner('DEV'), findsNothing);
  });
}
