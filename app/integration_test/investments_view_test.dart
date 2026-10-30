// The Investments segment on a device, in the demo flavor. Run on the harness's emulator
// with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The demo starts as main_demo.dart does, on the renter persona, which has no investment
// account: the Insights tab's Investments segment (`/investments`) shows the empty
// state. Choosing the family persona brings its 401k: the allocation's donut and table
// (its three ETFs), the account's value over time from today's snapshot, its three
// holdings with their quantities and prices, and its investment transactions newest
// first, a page at a time.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/investments/presentation/allocation_chart.dart';
import 'package:finance_tracker/features/investments/presentation/investment_rows.dart';
import 'package:finance_tracker/features/investments/presentation/investments_view.dart';
import 'package:finance_tracker/features/investments/presentation/value_history.dart';
import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: the renter\'s empty state, then the family\'s 401k', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(goRouterProvider).go(const InvestmentsRoute().location);
    await tester.pumpAndSettle();
    expect(find.text('No investment accounts'), findsOneWidget);

    container.read(demoPersonaProvider.notifier).select(PersonaId.family);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => container.read(snapshotWriterRunnerProvider.notifier).settled(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AllocationDonut), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^ETF: \$')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Holdings worth \$[0-9,.]+ in one security type\.'),
      ),
      findsOneWidget,
    );
    // The segment's list, not the segment control above it, which scrolls sideways.
    final Finder scrollable = find
        .descendant(
          of: find.byType(InvestmentsView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byType(ValueHistoryChart),
      300,
      scrollable: scrollable,
    );
    expect(
      find.textContaining('From install day: recorded on this device since'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Investment transactions'),
      300,
      scrollable: scrollable,
    );
    expect(find.byType(HoldingRow), findsNWidgets(3));
    for (final String ticker in ['VTI', 'VXUS', 'BND']) {
      expect(
        find.bySemanticsLabel(RegExp('$ticker, [0-9]+\\.[0-9]{3} at ')),
        findsOneWidget,
        reason: ticker,
      );
    }
    expect(
      find.byType(InvestmentTransactionRow),
      findsNWidgets(investmentTransactionsPage),
    );
    await tester.scrollUntilVisible(
      find.textContaining('Show more'),
      300,
      scrollable: scrollable,
    );
    await Scrollable.ensureVisible(
      tester.element(find.textContaining('Show more')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Show more'));
    await tester.pumpAndSettle();
    expect(
      find.byType(InvestmentTransactionRow),
      findsAtLeastNWidgets(investmentTransactionsPage + 1),
    );
  });
}
