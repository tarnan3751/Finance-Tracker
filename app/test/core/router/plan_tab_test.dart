// The Plan tab: it opens on Budgets, `/plan` redirects there, the segment control
// switches between Budgets, Bills and Forecast under the same "Plan" app bar, `/bills`
// and `/forecast` open inside the tab, and tapping the tab again after a budget deep
// link returns to the Budgets segment.
import 'package:finance_tracker/core/router/plan_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Finder _segment(String label) => find.descendant(
  of: find.byType(SegmentedButton<PlanSegment>),
  matching: find.text(label),
);

void _expectPlan(WidgetTester tester, PlanSegment segment) {
  expect(find.widgetWithText(AppBar, 'Plan'), findsOneWidget);
  final SegmentedButton<PlanSegment> control = tester.widget(
    find.byType(SegmentedButton<PlanSegment>),
  );
  expect(control.selected, {segment});
  expect(
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
    2,
  );
}

void main() {
  testWidgets('the Plan tab opens on Budgets', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Plan'));
    await tester.pumpAndSettle();
    _expectPlan(tester, PlanSegment.budgets);
    expect(find.text('No budgets yet'), findsOneWidget);
  });

  testWidgets('/plan redirects to the Budgets segment', (tester) async {
    await pumpApp(tester, initialLocation: '/plan');

    _expectPlan(tester, PlanSegment.budgets);
    expect(find.text('No budgets yet'), findsOneWidget);
  });

  testWidgets('the control switches between the segments', (tester) async {
    await pumpApp(tester, initialLocation: '/budgets');

    await tester.tap(_segment('Bills'));
    await tester.pumpAndSettle();
    _expectPlan(tester, PlanSegment.bills);
    expect(find.text('No budgets yet'), findsNothing);

    await tester.tap(_segment('Forecast'));
    await tester.pumpAndSettle();
    _expectPlan(tester, PlanSegment.forecast);

    await tester.tap(_segment('Budgets'));
    await tester.pumpAndSettle();
    _expectPlan(tester, PlanSegment.budgets);
    expect(find.text('No budgets yet'), findsOneWidget);
    // The bell stays on the Budgets segment.
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  testWidgets('/bills opens inside the tab', (tester) async {
    await pumpApp(tester, initialLocation: '/bills');
    _expectPlan(tester, PlanSegment.bills);
  });

  testWidgets('/forecast opens inside the tab', (tester) async {
    await pumpApp(tester, initialLocation: '/forecast');
    _expectPlan(tester, PlanSegment.forecast);
  });

  testWidgets('tapping the tab after a budget deep link returns to Budgets', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/budgets/new');
    expect(find.widgetWithText(AppBar, 'New budget'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'Plan'));
    await tester.pumpAndSettle();
    _expectPlan(tester, PlanSegment.budgets);
    expect(find.text('No budgets yet'), findsOneWidget);
  });
}
