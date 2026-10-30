// The reports on a device, in the demo flavor. Run on the harness's emulator with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The demo starts as main_demo.dart does, on the renter persona as of the device's
// today. The Insights tab opens on Reports with the current period's headline; the
// report of the last period has spending and income; over the seed's two years the
// anomaly flags include at least one of the anomalies the persona engine planted; and
// the period holding the newest flagged one lists it under "Worth a look".
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/reports/application/anomaly_providers.dart';
import 'package:finance_tracker/features/reports/application/reports_providers.dart';
import 'package:finance_tracker/features/reports/domain/anomalies.dart';
import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/reports/presentation/reports_view.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:persona_engine/persona_engine.dart' hide AnomalyKind;
import 'package:shared_models/shared_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: the renter\'s reports and a planted anomaly', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final LocalDate today = container.read(todayProvider);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Insights'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReportsView), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Spent ')), findsOneWidget);

    final ProviderSubscription<AsyncValue<Report>> reportSub = container.listen(
      reportProvider(-1),
      (_, _) {},
    );
    addTearDown(reportSub.close);
    final Report last = await container.read(reportProvider(-1).future);
    expect(last.current.spend.isPositive, isTrue);
    expect(last.current.income.isPositive, isTrue);

    final LocalDateRange window = LocalDateRange(
      today.addDays(-730),
      today.addDays(1),
    );
    final ProviderSubscription<AsyncValue<List<AnomalyFlag>>> flagSub =
        container.listen(anomaliesProvider(window), (_, _) {});
    addTearDown(flagSub.close);
    final List<AnomalyFlag> flags = await container.read(
      anomaliesProvider(window).future,
    );
    final Set<String> planted = {
      for (final Anomaly a in demoSeedFor(
        PersonaId.renter,
        today,
      ).household.anomalies)
        a.transactionId,
    };
    final List<AnomalyFlag> found = [
      for (final AnomalyFlag f in flags)
        if (planted.contains(f.transactionId)) f,
    ];
    expect(found, isNotEmpty);

    // The period holding the newest planted anomaly flagged.
    final AnomalyFlag newest = found.last;
    final int startDay = await container.read(reportStartDayProvider.future);
    final LocalDate current = periodContaining(today, startDay).start;
    final LocalDate shown = periodContaining(
      newest.transaction.date,
      startDay,
    ).start;
    int offset = (shown.year - current.year) * 12 + shown.month - current.month;
    for (; offset < 0; offset++) {
      await tester.tap(find.byTooltip('Previous period'));
      await tester.pumpAndSettle();
    }
    final String name = EnrichedMerchant.resolve(newest.transaction)
        .displayName;
    await tester.scrollUntilVisible(
      find.byTooltip('Dismiss $name'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byTooltip('Dismiss $name'), findsOneWidget);
  });
}
