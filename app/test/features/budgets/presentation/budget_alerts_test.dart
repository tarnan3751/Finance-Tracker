// The budget alerts in the app: the bell's unread badge (on screen at text scale 2), the
// sheet's rows newest first with the day in the device zone, over the navigation bar,
// "Mark all read", and a row opening its budget in the period it was raised for.
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/budgets/presentation/budgets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Notifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/budget_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

/// A threshold alert of budget [budgetId] on [categoryId] for the period from
/// [periodStart], raised at [raisedAt].
BudgetThresholdNotification _alert(
  String budgetId,
  String categoryId,
  int thresholdBp,
  LocalDate periodStart,
  DateTime raisedAt,
  int availableCents,
) => BudgetThresholdNotification(
  budgetId: budgetId,
  categoryId: categoryId,
  periodStart: periodStart,
  thresholdBp: thresholdBp,
  spent: Money(availableCents, 'USD').percent(thresholdBp),
  available: Money(availableCents, 'USD'),
  raisedAt: raisedAt,
);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  Future<InAppNotifications> open(WidgetTester tester, {Clock? clock}) async {
    await pumpApp(
      tester,
      initialLocation: '/budgets',
      clock: clock,
      overrides: [
        storeOverride(seededStore()),
        budgetsOverride(seededBudgets()),
      ],
    );
    return ProviderScope.containerOf(tester.element(find.byType(BudgetsScreen)))
        .read(inAppNotificationsProvider.notifier);
  }

  testWidgets('with no alert the sheet says so', (tester) async {
    await open(tester);

    expect(find.byTooltip('Alerts'), findsOneWidget);
    await tester.tap(find.byTooltip('Alerts'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No alerts yet'), findsOneWidget);
  });

  testWidgets('the bell counts the unread alerts; the sheet lists them newest '
      'first and marks them all read', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final InAppNotifications alerts = await open(
      tester,
      clock: FixedClock(
        DateTime.utc(2026, 10, 24, 15),
        tz.getLocation('America/New_York'),
      ),
    );
    alerts
      ..add(
        _alert(
          'budget-rent',
          'plaid:RENT_AND_UTILITIES',
          10000,
          LocalDate(2026, 10, 1),
          DateTime.utc(2026, 10, 10, 18),
          120000,
        ),
      )
      // 22:00 on 20 October in New York.
      ..add(
        _alert(
          'budget-food',
          'plaid:FOOD_AND_DRINK',
          8000,
          LocalDate(2026, 10, 1),
          DateTime.utc(2026, 10, 21, 2),
          700,
        ),
      );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Alerts, 2 unread'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byTooltip('Alerts, 2 unread'));
    await tester.pumpAndSettle();
    const String food = r'Food and drink reached 80 % of $7.00 on Oct 20';
    const String rent =
        r'Rent and utilities reached 100 % of $1,200.00 on Oct 10';
    expect(
      tester.getTopLeft(find.text(food)).dy,
      lessThan(tester.getTopLeft(find.text(rent)).dy),
    );
    expect(find.bySemanticsLabel(RegExp(r'\bUnread$')), findsNWidgets(2));

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'\bUnread$')), findsNothing);
    expect(find.byTooltip('Alerts'), findsOneWidget);
    // Disposed here: flutter_test checks for live handles before tear-downs run.
    semantics.dispose();
  });

  testWidgets('an alert opens its budget in its period and is read', (
    tester,
  ) async {
    final InAppNotifications alerts = await open(tester);
    alerts.add(
      _alert(
        'budget-rent',
        'plaid:RENT_AND_UTILITIES',
        10000,
        LocalDate(2026, 9, 1),
        DateTime.utc(2026, 9, 24, 12),
        120000,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Alerts, 1 unread'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Rent and utilities reached'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Rent and utilities'), findsOneWidget);
    expect(find.text('Last period'), findsOneWidget);
    expect(find.text('Sep 1 – Sep 30, 2026'), findsOneWidget);
    expect(alerts.state.single.read, isTrue);
  });

  testWidgets('at text scale 2 the badge of the bell stays on screen', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/budgets',
      textScale: 2,
      overrides: [
        storeOverride(seededStore()),
        budgetsOverride(seededBudgets()),
      ],
    );
    await openTestAlerts(tester);
    Navigator.of(tester.element(find.text('Alerts'))).pop();
    await tester.pumpAndSettle();

    // The label, which the badge draws beyond the icon's end.
    final Rect label = tester.getRect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
    );
    expect(label.right, lessThanOrEqualTo(phoneSize.width));
  });

  testWidgets('the sheet covers the navigation bar', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/budgets',
      overrides: [
        storeOverride(seededStore()),
        budgetsOverride(seededBudgets()),
      ],
    );
    await openTestAlerts(tester);

    final Rect sheet = tester.getRect(find.byType(BottomSheet));
    final Rect bar = tester.getRect(find.byType(NavigationBar));
    expect(sheet.bottom, greaterThanOrEqualTo(bar.bottom));
  });
}
