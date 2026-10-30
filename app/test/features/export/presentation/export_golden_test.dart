// Goldens of the export on the report household (report_seed.dart), light and dark at
// text scale 1 and 2: the export screen down to its privacy note, and the Reports'
// export sheet over the Reports segment.
// Tagged `golden`; see test/flutter_test_config.dart for where the files go and how to
// update them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/report_seed.dart';

final Map<
  String,
  ({String location, Future<void> Function(WidgetTester)? open})
>
_views = {
  'export_screen': (location: '/settings/export', open: null),
  'export_report_sheet': (
    location: '/reports',
    open: (tester) async {
      await tester.tap(find.byTooltip('Show menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export this month as PDF'));
      await tester.pumpAndSettle();
    },
  ),
};

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    for (final double scale in [1.0, 2.0]) {
      final String suffix = scale == 1 ? '' : '_scale2';
      final Size size = Size(phoneSize.width, scale == 1 ? 1100 : 1900);
      for (final MapEntry(key: String name, value: view) in _views.entries) {
        goldenTest(
          'the $name, ${brightness.name}, text scale $scale',
          fileName: '$name${suffix}_${brightness.name}',
          constraints: BoxConstraints.tight(size),
          textScaleFactor: scale,
          builder: () => SizedBox.fromSize(
            size: size,
            child: buildTestApp(
              brightness: brightness,
              overrides: reportOverrides(),
              initialLocation: view.location,
            ),
          ),
          pumpBeforeTest: (tester) async {
            await tester.pumpAndSettle();
            await view.open?.call(tester);
          },
        );
      }
    }
  }
}
