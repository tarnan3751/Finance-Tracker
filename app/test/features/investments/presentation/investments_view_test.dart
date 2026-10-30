// The Investments segment on the test investments (investment_seed.dart), as of 24
// October 2026: the allocation's donut summary and table, the accounts' headings, the
// holdings with their gains or "cost basis unavailable", the value chart's summary and
// its table, the investment transactions a page at a time, the empty sections of an
// account with nothing in it, the empty state, and text scale 2.
import 'dart:async';

import 'package:finance_tracker/features/investments/application/investments_providers.dart';
import 'package:finance_tracker/features/investments/presentation/allocation_chart.dart';
import 'package:finance_tracker/features/investments/presentation/investment_rows.dart';
import 'package:finance_tracker/features/investments/presentation/value_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/investment_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Future<void> _pump(WidgetTester tester, {double textScale = 1}) => pumpApp(
  tester,
  overrides: investmentOverrides(),
  router: investmentsRouter,
  textScale: textScale,
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('the allocation: the donut\'s summary and its table', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(tester);
    expect(find.widgetWithText(AppBar, 'Investments'), findsOneWidget);
    expect(find.text('Allocation'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        r'Holdings worth $7,265.83 in 4 security types. The largest is ETF at 62 %.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AllocationTable), findsOneWidget);
    for (final String row in [
      r'ETF: $4,511.75, 62 %',
      r'Equity: $1,500.00, 20 %',
      r'Cash: $1,222.81, 16 %',
      r'Other: $31.27, 0 %',
    ]) {
      expect(find.bySemanticsLabel(row), findsOneWidget, reason: row);
    }
    semantics.dispose();
  });

  testWidgets('each account\'s heading, with its balance labelled', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(tester);
    expect(
      find.bySemanticsLabel(r'Retirement 401k, $15,234.56, reported'),
      findsOneWidget,
    );
    await _scrollTo(tester, find.text('Brokerage'));
    expect(
      find.bySemanticsLabel(r'Brokerage, $0.00, from transactions'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the holdings: quantity at price, value, cost basis and gain', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(tester);
    await _scrollTo(tester, find.text('Mystery Fund'));
    expect(find.byType(HoldingRow), findsNWidgets(5));
    for (final String label in [
      r'Vanguard Total Stock Market ETF: $3,063.75, VTI, 12.500 at 245.10 USD, '
          r'Cost basis $2,900.00, Gain +$163.75 (+5 %), Price as of Oct 23, 2026',
      r'Vanguard Total Bond Market ETF: $1,448.00, BND, 20 at 72.40 USD, '
          'Cost basis unavailable, Price as of Oct 23, 2026',
      r'Acme Corp: $1,500.00, ACME, 10 at 150.00 USD, '
          r'Cost basis $1,650.00, Gain -$150.00 (-9 %), Price as of Oct 23, 2026',
      r'US Dollar: $1,222.81, CUR:USD, 1222.81 at 1.00 USD, '
          r'Cost basis $1,222.81, Gain $0.00 (0 %), Price as of Oct 23, 2026',
      r'Mystery Fund: $31.27, 3 at 10.4234 USD, Cost basis unavailable',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    semantics.dispose();
  });

  testWidgets('the value over time: the chart\'s summary, then its table', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(tester);
    await _scrollTo(tester, find.byType(ValueHistoryChart));
    expect(
      find.text('From install day: recorded on this device since Oct 20, 2026'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        r'Value $15,000.00 on Oct 20, $15,234.56 on Oct 24.',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Table'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.byType(ValueHistoryTable), findsOneWidget);
    expect(find.byType(ValueHistoryChart), findsNothing);
    final List<String> rows = [
      r'Sat, Oct 24, 2026: $15,234.56',
      r'Fri, Oct 23, 2026: $15,180.25',
      r'Wed, Oct 21, 2026: $15,100.00',
      r'Tue, Oct 20, 2026: $15,000.00',
    ];
    for (final String row in rows) {
      expect(find.bySemanticsLabel(row), findsOneWidget, reason: row);
    }
    // Newest first.
    final List<double> tops = [
      for (final String row in rows)
        tester.getTopLeft(find.bySemanticsLabel(row)).dy,
    ];
    expect(tops, [...tops]..sort());
    await tester.ensureVisible(find.text('Chart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chart'));
    await tester.pumpAndSettle();
    expect(find.byType(ValueHistoryChart), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the investment transactions, newest first, a page at a time', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(tester);
    await _scrollTo(tester, find.text('Show more (4 left)'));
    expect(find.byType(InvestmentTransactionRow), findsNWidgets(10));
    final Finder newest = find.bySemanticsLabel(
      r'BUY VTI: -$450.00, Oct 22, 2026 · Buy, 1.836 at 245.10 USD, '
      r'Fees $1.50',
    );
    expect(newest, findsOneWidget);
    expect(
      find.bySemanticsLabel(
        r'Payroll contribution: $450.00, Oct 22, 2026 · Cash · Contribution',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Show more (4 left)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show more (4 left)'));
    await tester.pumpAndSettle();
    expect(find.byType(InvestmentTransactionRow), findsNWidgets(14));
    expect(find.textContaining('Show more'), findsNothing);
    await _scrollTo(tester, find.text('Sep 10, 2026 · Cash · Contribution'));
    semantics.dispose();
  });

  testWidgets('an investment account with nothing in it yet', (tester) async {
    await _pump(tester);
    await _scrollTo(tester, find.text('No investment transactions'));
    expect(find.text('No values recorded yet'), findsOneWidget);
    expect(find.text('No holdings reported'), findsOneWidget);
  });

  testWidgets('a holding whose security is not listed is an unknown security', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: investmentOverrides(
        holdings: [investmentHoldings.first.copyWith(securityId: 'sec-gone')],
      ),
      router: investmentsRouter,
    );
    await _scrollTo(tester, find.text('Unknown security'));
    expect(find.text('sec-gone'), findsNothing);
    expect(find.text('Other'), findsOneWidget);
  });

  testWidgets('a list that failed to load says so, not that it is empty', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: [
        ...investmentOverrides(),
        investmentTransactionsProvider(retirementId).overrideWith(
          (ref) => Stream<List<InvestmentTransaction>>.error(
            Exception('the read failed'),
          ),
        ),
        investmentValueHistoryProvider(retirementId).overrideWith(
          (ref) =>
              Stream<List<BalanceSnapshot>>.error(Exception('the read failed')),
        ),
      ],
      router: investmentsRouter,
    );
    await _scrollTo(tester, find.text('Investment transactions'));
    expect(
      find.text('Something went wrong loading this. Try again later.'),
      findsNWidgets(2),
    );
    expect(find.text('No investment transactions'), findsNothing);
    expect(find.text('No values recorded yet'), findsNothing);
  });

  testWidgets('a list still loading shows a progress indicator', (
    tester,
  ) async {
    tester.view.physicalSize = phoneSize * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    // Streams that never emit: both lists stay loading.
    final StreamController<List<BalanceSnapshot>> never =
        StreamController<List<BalanceSnapshot>>();
    final StreamController<List<InvestmentTransaction>> neverRows =
        StreamController<List<InvestmentTransaction>>();
    addTearDown(never.close);
    addTearDown(neverRows.close);
    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          ...investmentOverrides(),
          investmentValueHistoryProvider(retirementId)
              .overrideWith((ref) => never.stream),
          investmentTransactionsProvider(retirementId)
              .overrideWith((ref) => neverRows.stream),
        ],
        router: investmentsRouter,
      ),
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Value over time'), findsOneWidget);
    expect(find.text('No values recorded yet'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the empty state with no investment account', (tester) async {
    await pumpApp(
      tester,
      overrides: [storeOverride(seededStore())],
      router: investmentsRouter,
    );
    expect(find.text('No investment accounts'), findsOneWidget);
    expect(find.byType(AllocationDonut), findsNothing);
  });

  testWidgets('text scale 2 lays out every section', (tester) async {
    await _pump(tester, textScale: 2);
    await _scrollTo(tester, find.text('No investment transactions'));
    expect(tester.takeException(), isNull);
  });
}
