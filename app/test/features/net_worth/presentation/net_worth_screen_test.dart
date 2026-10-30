// The net worth screen on the net worth household (net_worth_seed.dart), as of 24
// October 2026: the headline and the chart's summary naming the estimated span, the
// table's rows equal to the series computed from the stored rows, the range control,
// the empty state, the liabilities' payoffs (a hidden account's captioned), a rate and a payment entered for the car
// loan (and a rate refused), the extra payment's difference, and the stored extra
// snapped to the slider's new steps when the payment changes.
import 'dart:convert';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/features/net_worth/domain/payoff.dart';
import 'package:finance_tracker/features/net_worth/domain/reconstruction.dart';
import 'package:finance_tracker/features/net_worth/presentation/liability_payoff_card.dart';
import 'package:finance_tracker/features/net_worth/presentation/net_worth_chart.dart';
import 'package:finance_tracker/features/net_worth/presentation/net_worth_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/net_worth_seed.dart';
import '../../../helpers/pump_app.dart';

Money usd(int cents) => Money(cents, 'USD');

/// The series the screen should show, computed here from the seed's rows.
List<NetWorthPoint> expectedSeries() => netWorthHistory(netWorthSnapshots(), {
  nwCheckingId: AccountType.depository,
  nwCardId: AccountType.credit,
  nwMortgageId: AccountType.loan,
  nwCarId: AccountType.loan,
  nw401kId: AccountType.investment,
}, netWorthTransactions())['USD']!;

Future<void> openTable(WidgetTester tester) async {
  await tester.tap(find.text('Table'));
  await tester.pumpAndSettle();
}

Future<void> scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('the headline and the chart, its estimated span named', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      overrides: netWorthOverrides(),
      router: netWorthRouter,
    );
    final List<NetWorthPoint> series = expectedSeries();
    final NetWorthPoint last = series.last;
    expect(find.widgetWithText(AppBar, 'Net worth'), findsOneWidget);
    expect(find.text('Net worth on Oct 24, 2026'), findsOneWidget);
    expect(find.text(last.netWorth.format()), findsOneWidget);
    // Thirty days back, 24 September, is estimated.
    final NetWorthPoint before = series.singleWhere(
      (p) => p.date == LocalDate(2026, 9, 24),
    );
    expect(before.derived, isTrue);
    expect(
      find.text(
        '${(last.netWorth - before.netWorth).format(showPlusSign: true)} over '
        '30 days, against an estimate',
      ),
      findsOneWidget,
    );
    expect(find.byType(NetWorthChart), findsOneWidget);
    expect(find.text('Dashed: estimated from transactions'), findsOneWidget);
    // The default range is a year, so the whole history from 1 August shows.
    expect(
      find.bySemanticsLabel(
        'Net worth from Aug 1, 2026 to Oct 24, 2026: '
        '${series.first.netWorth.format()} to ${last.netWorth.format()}. '
        'On Oct 24, 2026, assets ${last.assets.format()} and liabilities '
        '${last.liabilities.format()}. Before Oct 14, 2026, estimated from '
        'transactions.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the table shows exactly the series of the stored rows', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      overrides: netWorthOverrides(),
      router: netWorthRouter,
    );
    await openTable(tester);
    final List<NetWorthPoint> series = expectedSeries();
    final List<NetWorthPoint> shown = [];
    // The table is built lazily: scroll through it, collecting each row once.
    final Set<LocalDate> seen = {};
    for (int i = 0; i < 200 && seen.length < series.length; i++) {
      for (final NetWorthRow row in tester.widgetList<NetWorthRow>(
        find.byType(NetWorthRow),
      )) {
        if (seen.add(row.point.date)) shown.add(row.point);
      }
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pump();
    }
    expect(shown, series.reversed.toList());
    // Each row reads as a sentence, its flag included.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 100000));
    await tester.pumpAndSettle();
    final NetWorthPoint today = series.last;
    expect(
      find.bySemanticsLabel(
        'Sat, Oct 24, 2026: net worth ${today.netWorth.format()}, assets '
        '${today.assets.format()}, liabilities ${today.liabilities.format()}.',
      ),
      findsOneWidget,
    );
    final NetWorthPoint gap = series.singleWhere((p) => p.date == nwGap);
    expect(
      find.bySemanticsLabel(
        'Mon, Oct 19, 2026: net worth ${gap.netWorth.format()}, assets '
        '${gap.assets.format()}, liabilities ${gap.liabilities.format()}. No '
        "snapshot this day: the day before's values",
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('three months starts the chart three months back', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      overrides: netWorthOverrides(),
      router: netWorthRouter,
    );
    await tester.tap(find.text('3 m'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('^Net worth from Aug 1, 2026 to Oct 24')),
      findsOneWidget,
    );
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('^Net worth from Aug 1, 2026 to Oct 24')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('no snapshot, the empty state', (tester) async {
    await pumpApp(
      tester,
      overrides: netWorthOverrides(snapshots: const []),
      router: netWorthRouter,
    );
    expect(find.text('No net worth yet'), findsOneWidget);
  });

  testWidgets('each liability with its payoff', (tester) async {
    await pumpApp(
      tester,
      overrides: netWorthOverrides(),
      router: netWorthRouter,
    );
    await scrollTo(tester, find.text('Home Mortgage'));
    final PaidOff mortgage = projectPayoff(
      owed: usd(28500000),
      rateBasisPoints: 625,
      payment: usd(215000),
      today: testClock.today(),
    ) as PaidOff;
    expect(find.text(r'$285,000.00 owed'), findsOneWidget);
    expect(find.text('6.25 % a year'), findsOneWidget);
    expect(find.text(r'Monthly payment $2,150.00'), findsOneWidget);
    expect(
      find.text(
        'Paid off in ${mortgage.months} months, '
        '${DateFormat.yMMM().format(mortgage.date.toDateTime())}; '
        '${mortgage.totalInterest.format()} in interest',
      ),
      findsOneWidget,
    );
    expect(find.text('21.99 % a year'), findsOneWidget);
    expect(find.text(r'Minimum payment $35.00'), findsOneWidget);
    expect(find.text('No interest rate reported'), findsOneWidget);
    expect(find.text('No payment reported'), findsOneWidget);
    // The reported terms cannot be changed; the car loan's can be entered.
    expect(find.text('Enter rate'), findsOneWidget);
    expect(find.text('Enter payment'), findsOneWidget);
  });

  testWidgets('a hidden account\'s card says it is hidden', (tester) async {
    final InMemoryStore store = netWorthStore()
      ..upsertAccount(
        const Account(
          id: nwCarId,
          type: AccountType.loan,
          name: 'Car Loan',
          currencyCode: 'USD',
          isHidden: true,
          displayOrder: 3,
        ),
      );
    await pumpApp(
      tester,
      overrides: netWorthOverrides(store: store),
      router: netWorthRouter,
    );
    await scrollTo(tester, find.text('Car Loan'));
    expect(find.text('Hidden account'), findsOneWidget);
  });

  testWidgets('a rate and a payment entered for the car loan, kept', (
    tester,
  ) async {
    final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
    await pumpApp(
      tester,
      overrides: [
        ...netWorthOverrides(),
        appMetaStoreProvider.overrideWithValue(meta),
      ],
      router: netWorthRouter,
    );
    await scrollTo(tester, find.text('Enter rate'));
    await tester.tap(find.text('Enter rate'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '120');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a rate from 0 to 100, with up to two decimals'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), '4.89');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('4.89 % a year, entered'), findsOneWidget);

    await tester.tap(find.text('Enter payment'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount above zero'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '420.00');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text(r'Your payment $420.00'), findsOneWidget);
    final PaidOff car = projectPayoff(
      owed: usd(1840000),
      rateBasisPoints: 489,
      payment: usd(42000),
      today: testClock.today(),
    ) as PaidOff;
    expect(
      find.text(
        'Paid off in ${car.months} months, '
        '${DateFormat.yMMM().format(car.date.toDateTime())}; '
        '${car.totalInterest.format()} in interest',
      ),
      findsOneWidget,
    );
    expect(find.text('Change rate'), findsOneWidget);
    expect(
      await meta.read(AppMetaKeys.payoffEntries),
      contains('"rate_bp":489'),
    );
  });

  testWidgets('a new payment snaps the stored extra to the new steps', (
    tester,
  ) async {
    final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
    await meta.write(
      AppMetaKeys.payoffEntries,
      jsonEncode({
        nwCarId: {
          'payment': {'minor_units': 42000, 'currency': 'USD'},
          'rate_bp': 489,
          'extra': {'minor_units': 6300, 'currency': 'USD'},
        },
      }),
    );
    await pumpApp(
      tester,
      overrides: [
        ...netWorthOverrides(),
        appMetaStoreProvider.overrideWithValue(meta),
      ],
      router: netWorthRouter,
    );
    await scrollTo(tester, find.text('Change payment'));
    // $420.00 in steps of $21.00: $63.00 is three steps.
    expect(find.text(r'Extra a month: $63.00'), findsOneWidget);
    expect(find.textContaining(r'With $63.00 more a month'), findsOneWidget);

    await tester.tap(find.text('Change payment'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1000.00');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    // $1,000.00 in steps of $50.00: $63.00 snaps to one step, written back, and the
    // label and the result line both show it.
    expect(find.text(r'Extra a month: $50.00'), findsOneWidget);
    expect(find.textContaining(r'With $50.00 more a month'), findsOneWidget);
    final Map<String, Object?> stored = jsonDecode(
      (await meta.read(AppMetaKeys.payoffEntries))!,
    ) as Map<String, Object?>;
    expect((stored[nwCarId]! as Map<String, Object?>)['extra'], {
      'minor_units': 5000,
      'currency': 'USD',
    });
  });

  testWidgets('the extra payment and what it changes', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      overrides: netWorthOverrides(),
      router: netWorthRouter,
    );
    await scrollTo(tester, find.text('Home Mortgage'));
    final Finder slider = find.descendant(
      of: find.ancestor(
        of: find.text('Home Mortgage'),
        matching: find.byType(LiabilityPayoffCard),
      ),
      matching: find.byType(Slider),
    );
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    expect(find.text(r'Extra a month: $0.00'), findsWidgets);
    // Two steps: two twentieths of $2,150.00, rounded up to $108.00 each.
    final Rect box = tester.getRect(slider);
    await tester.tapAt(
      Offset(box.left + 24 + (box.width - 48) * 2 / extraSteps, box.center.dy),
    );
    await tester.pumpAndSettle();
    expect(extraAt(usd(215000), 2), usd(21600));
    final PaidOff base = projectPayoff(
      owed: usd(28500000),
      rateBasisPoints: 625,
      payment: usd(215000),
      today: testClock.today(),
    ) as PaidOff;
    final PaidOff more = projectPayoff(
      owed: usd(28500000),
      rateBasisPoints: 625,
      payment: usd(215000),
      extra: usd(21600),
      today: testClock.today(),
    ) as PaidOff;
    expect(find.text(r'Extra a month: $216.00'), findsOneWidget);
    expect(
      find.text(
        'With \$216.00 more a month: ${base.months - more.months} months sooner, '
        '${(base.totalInterest - more.totalInterest).format()} less interest',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
