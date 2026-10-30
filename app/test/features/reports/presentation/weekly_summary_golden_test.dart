// Goldens of the weekly summary on the report household (report_seed.dart), light and
// dark at text scale 1 and 2, down the whole screen.
// Tagged `golden`; see test/flutter_test_config.dart for where the files go and how to
// update them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/report_seed.dart';

Size _size(double scale) => Size(phoneSize.width, scale == 1 ? 1400 : 2800);

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    for (final double scale in [1.0, 2.0]) {
      final String suffix = scale == 1 ? '' : '_scale2';
      goldenTest(
        'the weekly summary, ${brightness.name}, text scale $scale',
        fileName: 'weekly_summary${suffix}_${brightness.name}',
        constraints: BoxConstraints.tight(_size(scale)),
        textScaleFactor: scale,
        builder: () => SizedBox.fromSize(
          size: _size(scale),
          child: buildTestApp(
            brightness: brightness,
            overrides: reportOverrides(),
            initialLocation: '/reports/weekly',
          ),
        ),
      );
    }
  }
}
