// Goldens of the Reports segment on the report household (report_seed.dart), light and
// dark at text scale 1 and 2: the charts (the donut, the bars, the trend lines) and the
// tables, each down the whole report (a phone's width, as tall as the report), with the
// movers and "Worth a look" at the end.
// Tagged `golden`; see test/flutter_test_config.dart for where the files go and how to
// update them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/report_seed.dart';

Size _size(double scale) => Size(phoneSize.width, scale == 1 ? 3000 : 6000);

final Map<String, Future<void> Function(WidgetTester)?> _views = {
  'reports_charts': null,
  'reports_tables': (tester) async {
    await tester.tap(find.text('Tables'));
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
          constraints: BoxConstraints.tight(_size(scale)),
          textScaleFactor: scale,
          builder: () => SizedBox.fromSize(
            size: _size(scale),
            child: buildTestApp(
              brightness: brightness,
              overrides: reportOverrides(),
              initialLocation: '/reports',
            ),
          ),
          pumpBeforeTest: (tester) async {
            await tester.pumpAndSettle();
            await open?.call(tester);
          },
        );
      }
    }
  }
}
