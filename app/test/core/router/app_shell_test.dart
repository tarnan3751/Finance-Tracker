// The three-tab shell: where it opens, the root redirect, switching tabs, and the flavor
// banner (shown in dev and demo below the status bar, absent in prod).
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/router/app_shell.dart';
import 'package:finance_tracker/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Finder _bannerWithMessage(String message) => find.byWidgetPredicate(
  (widget) => widget is Banner && widget.message == message,
);

void main() {
  testWidgets('opens on the Accounts tab with its empty state', (tester) async {
    await pumpApp(tester);

    expect(find.widgetWithText(AppBar, 'Accounts'), findsOneWidget);
    expect(find.text('No accounts yet'), findsOneWidget);
    final NavigationBar bar = tester.widget(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
  });

  testWidgets('/ redirects to the Accounts tab', (tester) async {
    await pumpApp(tester, initialLocation: '/');

    expect(find.widgetWithText(AppBar, 'Accounts'), findsOneWidget);
  });

  testWidgets('the navigation bar switches between the three tabs', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(
      find.widgetWithText(NavigationDestination, 'Transactions'),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Transactions'), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'Accounts'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Accounts'), findsOneWidget);
  });

  testWidgets('a deep link opens its tab', (tester) async {
    await pumpApp(tester, initialLocation: '/transactions');

    expect(find.widgetWithText(AppBar, 'Transactions'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });

  testWidgets('demo and dev draw their banner below the status bar', (
    tester,
  ) async {
    const double statusBar = 24;
    tester.view.padding = FakeViewPadding(
      top: statusBar * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetPadding);

    await pumpApp(tester, config: AppConfig.demo());
    expect(_bannerWithMessage('DEMO'), findsOneWidget);
    expect(tester.getTopLeft(_bannerWithMessage('DEMO')).dy, statusBar);
    expect(tester.getTopRight(_bannerWithMessage('DEMO')).dx, phoneSize.width);
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, isFalse);

    await pumpApp(tester, config: AppConfig.dev());
    expect(_bannerWithMessage('DEV'), findsOneWidget);
  });

  testWidgets('prod draws no flavor banner', (tester) async {
    await pumpApp(tester, config: AppConfig.prod());

    expect(_bannerWithMessage('PROD'), findsNothing);
    expect(_bannerWithMessage('DEMO'), findsNothing);
    expect(_bannerWithMessage('DEV'), findsNothing);
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, isTrue);
  });

  testWidgets('the title is the flavor app name', (tester) async {
    await pumpApp(tester, config: AppConfig.demo());

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'Finance Tracker Demo');
  });

  testWidgets("a tab's snack bar sits in the tab, above the navigation bar", (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/settings');

    final BuildContext screen = tester.element(find.byType(SettingsScreen));
    final BuildContext root = tester.element(find.byType(AppShell));
    expect(
      ScaffoldMessenger.of(screen),
      isNot(same(ScaffoldMessenger.of(root))),
      reason: 'each tab has its own messenger',
    );
    ScaffoldMessenger.of(screen)
        .showSnackBar(const SnackBar(content: Text('Saved')));
    await tester.pumpAndSettle();

    expect(
      tester.getBottomLeft(find.byType(SnackBar)).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
    );
  });
}
