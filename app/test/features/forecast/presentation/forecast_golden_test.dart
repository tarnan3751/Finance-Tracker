// Goldens of the forecast on the test household (forecast_seed.dart), light and dark at
// phone size and at text scale 1 and 2: the 30-day chart (the payroll's band visible),
// its table, and the account sheet's content (a hidden account off, two currencies) on a
// page of its own, since the modal sheet opens on the root navigator, which in a golden
// is the harness's, outside the app.
// Tagged `golden`; see test/flutter_test_config.dart for where the files go and how to
// update them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/forecast_seed.dart';
import '../../../helpers/pump_app.dart';

Widget _app(Brightness brightness, {bool sheet = false}) => SizedBox.fromSize(
  size: phoneSize,
  child: buildTestApp(
    brightness: brightness,
    overrides: forecastOverrides(),
    router: sheet ? forecastSheetRouter : forecastRouter,
  ),
);

final Map<String, Future<void> Function(WidgetTester)?> _views = {
  'forecast_chart': null,
  'forecast_table': (tester) async {
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
  },
};

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    for (final double scale in [1.0, 2.0]) {
      final String suffix = scale == 1 ? '' : '_scale2';
      for (final MapEntry(key: String name, value: open) in _views.entries) {
        goldenTest(
          'the $name view, ${brightness.name}, text scale $scale',
          fileName: '$name${suffix}_${brightness.name}',
          constraints: BoxConstraints.tight(phoneSize),
          textScaleFactor: scale,
          builder: () => _app(brightness),
          pumpBeforeTest: (tester) async {
            await tester.pumpAndSettle();
            await open?.call(tester);
          },
        );
      }
      goldenTest(
        'the account sheet, ${brightness.name}, text scale $scale',
        fileName: 'forecast_accounts${suffix}_${brightness.name}',
        constraints: BoxConstraints.tight(phoneSize),
        textScaleFactor: scale,
        builder: () => _app(brightness, sheet: true),
      );
    }
  }
}
