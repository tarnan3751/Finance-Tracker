// The cash-flow forecast on a device, in the demo flavor. Run on the harness's emulator
// with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The demo starts as main_demo.dart does, on the renter persona as of the device's
// today. Its 90-day series covers the checking account, with 91 points from today and
// the projected streams' occurrences among its events (the renter's income is gig pay,
// which no stream projects); the rent bill, which follows the rent stream, is not
// counted a second time. Then the forecast screen is pushed and shows its headline and
// its chart, and its table.
import 'dart:async';

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/forecast/application/forecast_providers.dart';
import 'package:finance_tracker/features/forecast/domain/cash_flow_forecast.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_chart.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_screen.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: the renter\'s 90-day forecast', (tester) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final LocalDate today = container.read(todayProvider);
    final ProviderSubscription<AsyncValue<ForecastSeries?>> sub = container
        .listen(forecastProvider(90), (_, _) {});
    addTearDown(sub.close);
    final ForecastSeries series = (await container.read(
      forecastProvider(90).future,
    ))!;
    expect(series.points, hasLength(91));
    expect(series.points.first.date, today);
    expect(series.points.last.date, today.addDays(90));

    final List<ForecastEvent> events = [
      for (final ForecastPoint p in series.points) ...p.events,
    ];
    final List<BillReminder> bills = await container
        .read(billRepositoryProvider)
        .watchAll()
        .first;
    final BillReminder rent = bills.singleWhere(
      (b) => b.streamId == 'demo-stream-rent',
    );
    final List<ForecastEvent> rentStream = [
      for (final ForecastEvent e in events)
        if (e.id == 'demo-stream-rent') e,
    ];
    // Monthly over 90 days: three occurrences, give or take a month end.
    expect(rentStream.length, inInclusiveRange(2, 4));
    expect(rentStream.every((e) => e.amount!.isNegative), isTrue);
    expect(events.where((e) => e.id == rent.id), isEmpty);
    // Every occurrence lands on its own date, or tomorrow when it was overdue.
    for (final ForecastPoint p in series.points.skip(1)) {
      for (final ForecastEvent e in p.events) {
        expect(e.due == p.date || p.date == today.addDays(1), isTrue);
      }
    }

    final GlobalKey<NavigatorState> root = container
        .read(goRouterProvider)
        .routerDelegate
        .navigatorKey;
    unawaited(
      root.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const ForecastScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Forecast'), findsOneWidget);
    expect(find.byType(ForecastChart), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^(Lowest point .* on |Below zero on )')),
      findsOneWidget,
    );
    await tester.tap(find.text('90 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.byType(ForecastTable), findsOneWidget);
  });
}
