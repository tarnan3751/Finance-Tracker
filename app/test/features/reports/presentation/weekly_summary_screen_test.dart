// The weekly summary on the report household (report_seed.dart), as of Saturday 24
// October 2026: last week (12 to 18 October) with its totals, biggest categories and
// merchant, this week so far, the new merchant worth a look, no bills and no budgets;
// the entry on the Reports segment; and the in-app notice in the alerts sheet opening
// the screen.
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/features/reports/presentation/weekly_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/report_seed.dart';

void main() {
  testWidgets('last week, this week and what is worth a look', (tester) async {
    await pumpApp(
      tester,
      overrides: reportOverrides(),
      initialLocation: '/reports/weekly',
    );

    expect(find.widgetWithText(AppBar, 'Weekly summary'), findsOneWidget);
    expect(find.text('Last week, Oct 12 – Oct 18'), findsOneWidget);
    expect(find.text('Spent \$486.00'), findsOneWidget);
    expect(find.text('Entertainment: \$389.00'), findsOneWidget);
    expect(find.text('Food and drink: \$97.00'), findsOneWidget);
    expect(find.text('Spent most at Guitar Center: \$389.00'), findsOneWidget);
    expect(find.text('This week so far'), findsOneWidget);
    expect(find.text('Spent \$82.00'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('No budgets yet.'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byTooltip('Dismiss Guitar Center'), findsOneWidget);
    expect(find.byTooltip('Dismiss Olive Garden'), findsNothing);
    expect(find.text('No bills due next week.'), findsOneWidget);
  });

  testWidgets('the Reports segment opens it', (tester) async {
    await pumpApp(
      tester,
      overrides: reportOverrides(),
      initialLocation: '/reports',
    );
    await tester.scrollUntilVisible(
      find.text('Weekly summary'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Weekly summary'));
    await tester.pumpAndSettle();
    expect(find.byType(WeeklySummaryScreen), findsOneWidget);
  });

  testWidgets('the notice in the alerts sheet opens it', (tester) async {
    await pumpApp(tester, initialLocation: '/budgets');
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    await container
        .read(appNotifierProvider)
        .notify(
          WeeklySummaryNotification(
            weekStart: LocalDate(2026, 10, 12),
            raisedAt: DateTime.utc(2026, 10, 19, 8),
          ),
        );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Alerts, 1 unread'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your weekly summary is ready'));
    await tester.pumpAndSettle();
    expect(find.byType(WeeklySummaryScreen), findsOneWidget);
    expect(container.read(inAppNotificationsProvider).single.read, isTrue);
  });
}
