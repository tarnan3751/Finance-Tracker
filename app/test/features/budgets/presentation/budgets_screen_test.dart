// The Plan tab's Budgets segment over the test seed and its three budgets
// (budget_seed.dart): the empty state, each card's state (on pace with carry, projected
// over, over, nothing available), the period selector across a month boundary in
// America/New_York and with budgets on different start days, past and future periods,
// and the drill into a card.
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/budget_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Finder _card(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(BudgetCard));

Finder _inCard(String name, Finder finder) =>
    find.descendant(of: _card(name), matching: finder);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('with no budget, the empty state offers to add one', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/budgets');

    expect(find.text('No budgets yet'), findsOneWidget);
    await tester.tap(find.text('Add budget'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'New budget'), findsOneWidget);
  });

  testWidgets('each card shows its state, by category name', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/budgets',
      overrides: [
        storeOverride(seededStore()),
        budgetsOverride(seededBudgets()),
      ],
    );

    // One start day, so the selector carries the dates.
    expect(find.text('This period'), findsOneWidget);
    expect(find.text('Oct 1 – Oct 31, 2026'), findsOneWidget);
    final List<String> order = [
      for (final BudgetCard card in tester.widgetList<BudgetCard>(
        find.byType(BudgetCard),
      ))
        card.status.budget.id,
    ];
    expect(order, ['budget-food', 'budget-rent', 'budget-transport']);

    // Food and drink: $5.75 of $7.00, 82 %, projected over, past 80 %.
    expect(_inCard('Food and drink', find.text('82 %')), findsOneWidget);
    expect(_inCard('Food and drink', find.text(r'$1.25 left')), findsOneWidget);
    expect(
      _inCard('Food and drink', find.text(r'Projected over by $0.43')),
      findsOneWidget,
    );
    expect(
      _inCard('Food and drink', find.text('80 % reached')),
      findsOneWidget,
    );
    expect(
      _inCard('Food and drink', find.textContaining('Includes')),
      findsOneWidget,
    );

    // Rent and utilities: $1,450.00 of $1,200.00, over.
    expect(_inCard('Rent and utilities', find.text('120 %')), findsOneWidget);
    expect(
      _inCard('Rent and utilities', find.text(r'$250.00 over')),
      findsOneWidget,
    );
    expect(
      _inCard('Rent and utilities', find.text('100 % reached')),
      findsOneWidget,
    );

    // Transportation: $48.02 of $150.00 + $150.00 carried, on pace, no alert.
    expect(
      _inCard('Transportation', find.text(r'$150.00 + $150.00 carried')),
      findsOneWidget,
    );
    expect(_inCard('Transportation', find.text('16 %')), findsOneWidget);
    expect(
      _inCard('Transportation', find.text(r'On pace: about $62.03 by the end')),
      findsOneWidget,
    );
    expect(
      _inCard('Transportation', find.textContaining('reached')),
      findsNothing,
    );
  });

  testWidgets('the bar reads as one sentence', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await pumpApp(
        tester,
        initialLocation: '/budgets',
        overrides: [
          storeOverride(seededStore()),
          budgetsOverride(seededBudgets()),
        ],
      );

      expect(
        find.bySemanticsLabel(
          RegExp(r'Food and drink: 82 percent of \$7\.00 spent, \$1\.25 left'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Rent and utilities: 120 percent of \$1,200\.00 spent, '
            r'\$250\.00 over',
          ),
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('a budget with nothing available says so instead of a percent', (
    tester,
  ) async {
    // September spent $1,536.40 on rent and utilities against $500.00.
    await pumpApp(
      tester,
      initialLocation: '/budgets',
      overrides: [
        storeOverride(seededStore()),
        budgetsOverride(
          seededBudgets([
            testBudget(
              'budget-rent',
              'RENT_AND_UTILITIES',
              50000,
              rollover: true,
            ),
          ]),
        ),
      ],
    );

    expect(find.text(r'$500.00 − $1,036.40 carried'), findsOneWidget);
    expect(find.text('Nothing available'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text(r'$1,986.40 over'), findsOneWidget);
  });

  testWidgets('the selector moves across the month boundary in New York', (
    tester,
  ) async {
    final tz.Location newYork = tz.getLocation('America/New_York');
    // 23:30 on 31 October in New York, already 1 November in UTC.
    await pumpApp(
      tester,
      initialLocation: '/budgets',
      clock: FixedClock(DateTime.utc(2026, 11, 1, 3, 30), newYork),
      overrides: [
        storeOverride(seededStore()),
        budgetsOverride(seededBudgets()),
      ],
    );
    expect(find.text('Oct 1 – Oct 31, 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Next period'));
    await tester.pumpAndSettle();
    expect(find.text('Next period'), findsOneWidget);
    expect(find.text('Nov 1 – Nov 30, 2026'), findsOneWidget);
    // A future period: what will be available, no spending. Transportation carries
    // September's $150.00 and October's $101.98.
    expect(find.text(r'$401.98 available'), findsOneWidget);
    expect(find.textContaining('spent'), findsNothing);

    await tester.tap(find.byTooltip('Previous period'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous period'));
    await tester.pumpAndSettle();
    expect(find.text('Last period'), findsOneWidget);
    expect(find.text('Sep 1 – Sep 30, 2026'), findsOneWidget);
    // A past period: its own spending, no projection.
    expect(
      _inCard('Rent and utilities', find.text(r'$1,536.40 spent')),
      findsOneWidget,
    );
    expect(find.textContaining('On pace'), findsNothing);
    expect(find.textContaining('Projected'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'This period'));
    await tester.pumpAndSettle();
    expect(find.text('Oct 1 – Oct 31, 2026'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'This period'), findsNothing);
  });

  testWidgets('just past midnight in New York the period is November', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/budgets',
      clock: FixedClock(
        DateTime.utc(2026, 11, 1, 4, 30),
        tz.getLocation('America/New_York'),
      ),
      overrides: [
        storeOverride(seededStore()),
        budgetsOverride(seededBudgets()),
      ],
    );

    expect(find.text('Nov 1 – Nov 30, 2026'), findsOneWidget);
  });

  testWidgets('budgets on different start days show their own dates', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/budgets',
      overrides: [
        storeOverride(seededStore()),
        budgetsOverride(
          seededBudgets([
            testBudget('budget-food', 'FOOD_AND_DRINK', 700),
            testBudget(
              'budget-transport',
              'TRANSPORTATION',
              15000,
              periodStartDay: 15,
            ),
          ]),
        ),
      ],
    );

    expect(find.text('This period'), findsOneWidget);
    expect(
      _inCard('Food and drink', find.text('Oct 1 – Oct 31, 2026')),
      findsOneWidget,
    );
    expect(
      _inCard('Transportation', find.text('Oct 15 – Nov 14, 2026')),
      findsOneWidget,
    );
  });

  testWidgets('a card opens what it counts, a split by its own amount', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/budgets',
      overrides: [
        storeOverride(seededStore()),
        budgetsOverride(seededBudgets()),
      ],
    );

    await tester.tap(find.text('Food and drink'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Food and drink'), findsOneWidget);
    expect(find.text('Blue Bottle Coffee'), findsOneWidget);
    expect(find.text('Whole Foods Market'), findsNothing);

    // September: the Whole Foods transaction counts its $100.00 groceries split only.
    await tester.tap(find.byTooltip('Previous period'));
    await tester.pumpAndSettle();
    expect(find.text('Sep 1 – Sep 30, 2026'), findsOneWidget);
    expect(find.text('Whole Foods Market'), findsOneWidget);
    expect(find.text(r'-$100.00'), findsOneWidget);
    expect(find.textContaining('Groceries'), findsOneWidget);
    expect(find.text('Blue Bottle Coffee'), findsNothing);

    // Two periods back nothing counts.
    await tester.tap(find.byTooltip('Previous period'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing counted in this period'), findsOneWidget);
  });
}
