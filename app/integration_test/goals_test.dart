// The savings goals on a device, in the demo flavor. Run on the harness's emulator with
//
//   tools/emulator_tests.sh integration -- --plain-name "demo: goals"
//
// The demo starts as main_demo.dart does, on the renter persona as of the device's today,
// with its two goals: the emergency fund on its savings account and the holiday, saved
// by six contributions of 125.00 and behind its plan. The goals screen is opened at
// /goals (the Insights tab's Goals segment), lists both, opens the holiday, and a
// contribution of 50.00 added through its editor raises the progress to 800.00.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: goals with a contribution added', (tester) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(goRouterProvider).go(const GoalsRoute().location);
    await tester.pumpAndSettle();

    expect(find.text('Emergency fund'), findsOneWidget);
    expect(find.text('Holiday'), findsOneWidget);
    expect(find.textContaining(r'$750.00 of $1,800.00'), findsOneWidget);
    expect(find.textContaining('Behind by'), findsOneWidget);
    expect(find.textContaining('Set aside'), findsNWidgets(2));

    await tester.tap(find.text('Holiday'));
    await tester.pumpAndSettle();
    expect(find.text(r'$125.00'), findsNWidgets(6));
    await tester.tap(find.text('Add contribution'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '50');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text(r'$800.00 of $1,800.00'), findsOneWidget);
    expect(find.text(r'$50.00'), findsOneWidget);
  });
}
