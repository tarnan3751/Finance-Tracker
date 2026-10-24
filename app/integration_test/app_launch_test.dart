// Launch smoke tests on a device: the demo flavor starts the way main_demo.dart starts it
// and shows the app, then opens on the Accounts tab with the renter persona's accounts
// and their derived balances. Run on the harness's emulator with
// `tools/emulator_tests.sh integration`. The first test asserts only the MaterialApp and
// its title, so it holds while the home screen changes.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the demo flavor launches and shows the app', (tester) async {
    final AppConfig config = AppConfig.demo();
    await bootstrap(config);
    await tester.pumpAndSettle();

    final Finder app = find.byType(MaterialApp);
    expect(app, findsOneWidget);
    expect(tester.widget<MaterialApp>(app).title, config.appName);
  });

  testWidgets("the demo flavor shows the renter persona's accounts", (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();

    expect(find.text('Everyday Checking'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('Platypus Rewards Card'), findsOneWidget);
    expect(find.text('from transactions'), findsNWidgets(3));
  });
}
