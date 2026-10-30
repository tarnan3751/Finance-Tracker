// Goldens of the net worth screen on the net worth household (net_worth_seed.dart), light
// and dark at phone size and at text scale 1 and 2: the chart (its estimated span
// dashed), its table, and the liabilities with their payoffs scrolled into view.
// Tagged `golden`; see test/flutter_test_config.dart for where the files go and how to
// update them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/net_worth_seed.dart';
import '../../../helpers/pump_app.dart';

Widget _app(Brightness brightness) => SizedBox.fromSize(
  size: phoneSize,
  child: buildTestApp(
    brightness: brightness,
    overrides: netWorthOverrides(),
    router: netWorthRouter,
  ),
);

final Map<String, Future<void> Function(WidgetTester)?> _views = {
  'net_worth_chart': null,
  'net_worth_table': (tester) async {
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
  },
  'net_worth_liabilities': (tester) async {
    await tester.scrollUntilVisible(
      find.text('Home Mortgage'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
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
    }
  }
}
