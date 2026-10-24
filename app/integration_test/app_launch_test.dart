// Launch smoke test on a device: the demo flavor starts the way main_demo.dart starts it and
// shows the app. Run on the harness's emulator with `tools/emulator_tests.sh integration`.
// It asserts the MaterialApp and its title rather than any screen's widgets, so it holds
// while the home screen changes.
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
}
