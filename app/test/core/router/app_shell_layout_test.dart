// The shell's navigation per window size class: the bar on a compact window, the rail
// with labels on a medium one, the extended rail on an expanded one; the same five
// destinations in each, a window that changes class keeping each tab's place, and a
// screen reader going through the screen before the rail.
import 'package:finance_tracker/core/layout/window_size_class.dart';
import 'package:finance_tracker/core/router/plan_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('the classes break at 600 and 840 dp', () {
    expect(WindowSizeClass.fromWidth(599.9), WindowSizeClass.compact);
    expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(839.9), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
  });

  testWidgets('a compact window has the navigation bar', (tester) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('a medium window has the rail with its labels', (tester) async {
    await pumpApp(tester, size: mediumSize);

    expect(find.byType(NavigationBar), findsNothing);
    final NavigationRail rail = tester.widget(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
    expect(rail.destinations, hasLength(5));
    expect(rail.selectedIndex, 0);
  });

  testWidgets('an expanded window has the extended rail', (tester) async {
    await pumpApp(tester, size: expandedSize);

    final NavigationRail rail = tester.widget(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(rail.destinations, hasLength(5));
  });

  testWidgets('the rail switches tabs, and the Plan tab keeps its segments', (
    tester,
  ) async {
    await pumpApp(tester, size: mediumSize);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Plan'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Plan'), findsOneWidget);
    expect(find.byType(SegmentedButton<PlanSegment>), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      2,
    );
  });

  testWidgets('a window that changes class keeps the tab and its screen', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/settings/categories');
    expect(find.widgetWithText(AppBar, 'Categories'), findsOneWidget);

    tester.view.physicalSize = mediumSize * tester.view.devicePixelRatio;
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Categories'), findsOneWidget);

    tester.view.physicalSize = phoneSize * tester.view.devicePixelRatio;
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Categories'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  });

  for (final (String name, Size size) in [
    ('medium', mediumSize),
    ('expanded', expandedSize),
  ]) {
    testWidgets('on a $name window the screen is read before the rail', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await pumpApp(tester, size: size);

        final List<String> labels = [
          for (final SemanticsNode node
              in tester.semantics.simulatedAccessibilityTraversal())
            node.label,
        ];
        final int title = labels.indexOf('Accounts');
        final int settingsTab = labels.indexWhere(
          (l) => l.startsWith('Settings'),
        );
        expect(title, isNonNegative);
        expect(settingsTab, greaterThan(title));
        expect(
          labels.indexOf('No accounts yet'),
          lessThan(settingsTab),
          reason: 'the screen comes before the rail',
        );
        expect(
          labels.indexWhere((l) => l.startsWith('Transactions')),
          greaterThan(labels.indexOf('No accounts yet')),
          reason: 'the rail does not interleave with the screen',
        );
      } finally {
        semantics.dispose();
      }
    });
  }
}
