// Net worth and payoff on a device, in the demo flavor. Run on the harness's emulator
// with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The demo starts as main_demo.dart does; the family persona is chosen, the snapshot
// writer writes today's rows, and the net worth history is today's observed point after
// a prefix reconstructed from the family's two years of transactions, every point of it
// derived; today's point is the sum of today's rows. Then the Insights tab's Net worth
// segment shows its headline, its chart naming the estimated span, its table, and the
// mortgage's payoff from the rate and the monthly payment the demo reports.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/net_worth/application/net_worth_providers.dart';
import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/features/net_worth/domain/payoff.dart';
import 'package:finance_tracker/features/net_worth/presentation/net_worth_chart.dart';
import 'package:finance_tracker/features/net_worth/presentation/net_worth_table.dart';
import 'package:finance_tracker/features/net_worth/presentation/net_worth_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_models/shared_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: the family\'s net worth and its mortgage payoff', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final LocalDate today = container.read(todayProvider);
    container.read(demoPersonaProvider.notifier).select(PersonaId.family);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => container.read(snapshotWriterRunnerProvider.notifier).settled(),
    );
    await tester.pumpAndSettle();

    final ProviderSubscription<AsyncValue<Map<String, List<NetWorthPoint>>>>
    series = container.listen(netWorthSeriesProvider, (_, _) {});
    addTearDown(series.close);
    final ProviderSubscription<AsyncValue<List<LiabilityPayoff>>> payoffs =
        container.listen(liabilityPayoffsProvider, (_, _) {});
    addTearDown(payoffs.close);
    await tester.pumpAndSettle();
    final List<NetWorthPoint> usd = series.read().requireValue['USD']!;
    final List<BalanceSnapshot> rows = (await tester.runAsync(
      () => container.read(balanceSnapshotRepositoryProvider).watchAll().first,
    ))!;
    expect(rows.every((r) => r.date == today), isTrue);
    expect(usd.last.date, today);
    expect(usd.last.derived, isFalse);
    expect(usd.last.netWorth, Money.sum([for (final r in rows) r.current]));
    final List<NetWorthPoint> prefix = usd.sublist(0, usd.length - 1);
    expect(prefix.length, greaterThan(600));
    expect(prefix.every((p) => p.derived && !p.carried), isTrue);
    expect(prefix.last.date, today.addDays(-1));

    final LiabilityPayoff mortgage = payoffs.read().requireValue.singleWhere(
      (p) => p.terms.paymentKind == PayoffPaymentKind.monthly,
    );
    final PaidOff paid = mortgage.projection! as PaidOff;
    expect(
      paid,
      projectPayoff(
        owed: mortgage.terms.owed,
        rateBasisPoints: mortgage.terms.rateBasisPoints!,
        payment: mortgage.terms.payment!,
        today: today,
      ),
    );

    container.read(goRouterProvider).go(const NetWorthRoute().location);
    await tester.pumpAndSettle();
    expect(find.text(usd.last.netWorth.format()), findsOneWidget);
    expect(find.byType(NetWorthChart), findsOneWidget);
    expect(find.text('Dashed: estimated from transactions'), findsOneWidget);
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.byType(NetWorthRow), findsWidgets);
    expect(find.text('Estimated from transactions'), findsWidgets);
    await tester.tap(find.text('Chart'));
    await tester.pumpAndSettle();
    final String payoffLine =
        'Paid off in ${paid.months} months, '
        '${DateFormat.yMMM().format(paid.date.toDateTime())}; '
        '${paid.totalInterest.format()} in interest';
    await tester.scrollUntilVisible(
      find.text(payoffLine),
      300,
      // The view's own scroll, not the segment control's sideways one.
      scrollable: find
          .descendant(
            of: find.byType(NetWorthView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text(mortgage.account.name), findsOneWidget);
  });
}
