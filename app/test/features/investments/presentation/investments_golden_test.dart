// Goldens of the Investments segment on the test investments (investment_seed.dart),
// light and dark at phone size and at text scale 1 and 2: the allocation's donut and
// table at the top, the retirement account's holdings, its value table, its investment
// transactions, and the empty state with no investment account.
// Tagged `golden`; see test/flutter_test_config.dart for where the files go and how to
// update them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/investment_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Widget _app(Brightness brightness, List<Override> overrides) =>
    SizedBox.fromSize(
      size: phoneSize,
      child: buildTestApp(
        brightness: brightness,
        overrides: overrides,
        router: investmentsRouter,
      ),
    );

/// Scrolls the segment until the first [text] is at the top.
Future<void> _scrollToTop(WidgetTester tester, String text) async {
  await Scrollable.ensureVisible(tester.element(find.text(text).first));
  await tester.pumpAndSettle();
}

final Map<String, Future<void> Function(WidgetTester)?> _views = {
  'investments_allocation': null,
  'investments_holdings': (tester) => _scrollToTop(tester, 'Holdings'),
  'investments_value_table': (tester) async {
    await _scrollToTop(tester, 'Value over time');
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
  },
  'investments_transactions': (tester) =>
      _scrollToTop(tester, 'Investment transactions'),
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
          builder: () => _app(brightness, investmentOverrides()),
          pumpBeforeTest: (tester) async {
            await tester.pumpAndSettle();
            await open?.call(tester);
          },
        );
      }
      goldenTest(
        'the empty state, ${brightness.name}, text scale $scale',
        fileName: 'investments_empty${suffix}_${brightness.name}',
        constraints: BoxConstraints.tight(phoneSize),
        textScaleFactor: scale,
        builder: () => _app(brightness, [storeOverride(seededStore())]),
      );
    }
  }
}
