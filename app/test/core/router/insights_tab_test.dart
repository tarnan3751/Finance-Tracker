// The Insights tab: it opens on Reports, `/insights` redirects there, the segment control
// switches between Reports, Net worth, Investments and Goals under the same "Insights"
// app bar, each segment's root opens inside the tab, and the control survives text
// scale 2 without overflow.
import 'package:finance_tracker/core/router/insights_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Finder _segment(String label) => find.descendant(
  of: find.byType(SegmentedButton<InsightsSegment>),
  matching: find.text(label),
);

// The control scrolls sideways on a phone, so a segment is brought into view first.
Future<void> _choose(WidgetTester tester, String label) async {
  await tester.ensureVisible(_segment(label));
  await tester.pumpAndSettle();
  await tester.tap(_segment(label));
  await tester.pumpAndSettle();
}

void _expectInsights(WidgetTester tester, InsightsSegment segment) {
  expect(find.widgetWithText(AppBar, 'Insights'), findsOneWidget);
  final SegmentedButton<InsightsSegment> control = tester.widget(
    find.byType(SegmentedButton<InsightsSegment>),
  );
  expect(control.selected, {segment});
  expect(
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
    3,
  );
}

void main() {
  testWidgets('the Insights tab opens on Reports', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Insights'));
    await tester.pumpAndSettle();
    _expectInsights(tester, InsightsSegment.reports);
  });

  testWidgets('/insights redirects to the Reports segment', (tester) async {
    await pumpApp(tester, initialLocation: '/insights');
    _expectInsights(tester, InsightsSegment.reports);
  });

  testWidgets('the control switches between the segments', (tester) async {
    await pumpApp(tester, initialLocation: '/reports');

    await _choose(tester, 'Net worth');
    _expectInsights(tester, InsightsSegment.netWorth);

    await _choose(tester, 'Investments');
    _expectInsights(tester, InsightsSegment.investments);

    await _choose(tester, 'Goals');
    _expectInsights(tester, InsightsSegment.goals);

    await _choose(tester, 'Reports');
    _expectInsights(tester, InsightsSegment.reports);
  });

  for (final (String location, InsightsSegment segment, String shown) in [
    ('/net-worth', InsightsSegment.netWorth, 'Coming soon'),
    ('/investments', InsightsSegment.investments, 'Coming soon'),
    ('/goals', InsightsSegment.goals, 'No savings goals yet'),
  ]) {
    testWidgets('$location opens inside the tab', (tester) async {
      await pumpApp(tester, initialLocation: location);
      _expectInsights(tester, segment);
      expect(find.text(shown), findsOneWidget);
    });
  }

  testWidgets('a segment off the screen\'s edge opens scrolled into view', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/goals');
    final Rect goals = tester.getRect(_segment('Goals'));
    expect(goals.right, lessThanOrEqualTo(412));
    expect(goals.left, greaterThanOrEqualTo(0));
  });

  testWidgets('the control fits at text scale 2', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, initialLocation: '/goals');

    expect(tester.takeException(), isNull);
    // The first segment can be scrolled to and chosen.
    await _choose(tester, 'Reports');
    _expectInsights(tester, InsightsSegment.reports);
  });
}
