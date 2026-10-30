// The Reports segment on the report household (report_seed.dart), as of 24 October
// 2026: the headline and the savings rate, the comparisons' same-day note, the donut's
// summary, the tables with a drill into a group and back, the previous period, and
// "Worth a look" with a tap to the transaction, Dismiss and Undo, whose snackbar lasts
// the undo window and goes when the segment is left.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/report_seed.dart';

Future<void> _open(WidgetTester tester, {InMemoryStore? store}) => pumpApp(
  tester,
  overrides: reportOverrides(store: store),
  initialLocation: '/reports',
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the headline, the savings rate and the comparisons', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('This period'), findsOneWidget);
    expect(find.text('Spent \$2,526.50'), findsOneWidget);
    expect(find.text('Income \$4,300.00'), findsOneWidget);
    // (4,300.00 - 2,526.50) / 4,300.00 = 41.2 %.
    expect(find.text('Kept 41 % of income'), findsOneWidget);
    expect(
      find.text('Compared over the first 24 days of each period'),
      findsOneWidget,
    );
    // No next period: nothing is ahead of today.
    expect(find.byTooltip('Next period'), findsNothing);
  });

  testWidgets('the donut is one summary for a screen reader', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _open(tester);

    expect(
      find.bySemanticsLabel(
        'Spending by category: \$2,526.50 in all. The largest is Rent and '
        'utilities, \$1,650.00.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the tables drill into a group and back', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Tables'));
    await tester.pumpAndSettle();

    expect(find.text('Charts'), findsOneWidget);
    await tester.tap(find.text('Food and drink'));
    await tester.pumpAndSettle();
    expect(find.text('All categories'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Restaurant'), findsOneWidget);

    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsNothing);
    expect(find.text('Food and drink'), findsOneWidget);
  });

  testWidgets('a screen reader drills into a group through the table', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _open(tester);
    await tester.tap(find.text('Tables'));
    await tester.pumpAndSettle();

    // The row's own tap action, as TalkBack sends it, not a tap on its pixels.
    tester.semantics.tap(find.semantics.byLabel(RegExp(r'^Food and drink: ')));
    await tester.pumpAndSettle();
    expect(find.text('All categories'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the donut names the largest slice, the group itself included', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final InMemoryStore store = reportStore()
      ..upsertTransaction(
        Transaction(
          id: 'catering',
          accountId: reportCheckingId,
          amount: Money(-50000, 'USD'),
          date: LocalDate(2026, 10, 20),
          pending: false,
          name: 'Catering',
          userCategoryId: 'plaid:FOOD_AND_DRINK',
          source: DataSource.manual,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          syncVersion: 0,
        ),
      );
    await _open(tester, store: store);
    await tester.tap(find.text('Tables'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food and drink'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Charts'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        'Food and drink by category: \$987.50 in all. The largest is Food and '
        'drink itself, \$500.00.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('income by category', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Tables'));
    await tester.pumpAndSettle();
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Income: \$4,300.00, 100 % of the total'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the period before', (tester) async {
    await _open(tester);
    await tester.tap(find.byTooltip('Previous period'));
    await tester.pumpAndSettle();

    expect(find.text('Last period'), findsOneWidget);
    expect(find.text('Sep 1 – Sep 30, 2026'), findsOneWidget);
    expect(find.byTooltip('Next period'), findsOneWidget);
    expect(
      find.text('Compared over the first 24 days of each period'),
      findsNothing,
    );
  });

  testWidgets('worth a look: open, dismiss and undo', (tester) async {
    await _open(tester);
    await _scrollTo(tester, find.byTooltip('Dismiss Guitar Center'));

    expect(find.text('Olive Garden'), findsWidgets);
    expect(
      find.textContaining('New: not seen in the last six months'),
      findsOneWidget,
    );
    expect(find.textContaining('Usually about \$45'), findsOneWidget);

    await tester.tap(find.textContaining('New: not seen'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionEditorScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Dismiss Guitar Center'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Dismiss Guitar Center'), findsNothing);
    expect(
      find.text('Dismissed. It won\'t be flagged again on this device.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Dismiss Guitar Center'), findsOneWidget);
  });

  testWidgets('Undo still works after leaving the tab and coming back', (
    tester,
  ) async {
    await _open(tester);
    await _scrollTo(tester, find.byTooltip('Dismiss Guitar Center'));
    await tester.tap(find.byTooltip('Dismiss Guitar Center'));
    await tester.pump();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Accounts'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(NavigationDestination, 'Insights'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _scrollTo(tester, find.byTooltip('Dismiss Guitar Center'));
    expect(find.byTooltip('Dismiss Guitar Center'), findsOneWidget);
  });
  testWidgets('the dismissal snackbar lasts the undo window', (tester) async {
    await _open(tester);
    await _scrollTo(tester, find.byTooltip('Dismiss Guitar Center'));
    await tester.tap(find.byTooltip('Dismiss Guitar Center'));
    await tester.pumpAndSettle();
    expect(find.text(_dismissed), findsOneWidget);

    await tester.pump(undoDuration);
    await tester.pumpAndSettle();
    expect(find.text(_dismissed), findsNothing);
    expect(find.byTooltip('Dismiss Guitar Center'), findsNothing);
  });

  testWidgets('the dismissal snackbar goes when the segment is left', (
    tester,
  ) async {
    await _open(tester);
    await _scrollTo(tester, find.byTooltip('Dismiss Guitar Center'));
    await tester.tap(find.byTooltip('Dismiss Guitar Center'));
    await tester.pump();
    expect(find.text(_dismissed), findsOneWidget);

    await tester.tap(find.text('Net worth'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text(_dismissed), findsNothing);
  });
}

const String _dismissed =
    'Dismissed. It won\'t be flagged again on this device.';
