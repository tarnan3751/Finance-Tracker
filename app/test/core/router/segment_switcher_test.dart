// The segment switcher on a 360 dp phone, measured in the bundled Work Sans (loaded
// here; the other tests draw text in the test font, whose every glyph is a square):
// at text scale 1 the Plan tab's three segments share the width without scrolling; the
// Insights tab's four, whose "Investments" is wider than a quarter of the row, scroll
// with a fade at the trailing edge and open with the segment shown in view; at text
// scale 2 both scroll, the segment shown in view, with no overflow; the fade shows only
// while there is more past the edge, and a text size that stops the row fitting while it
// is open brings the segment shown into view.
import 'package:finance_tracker/core/router/segment_switcher.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const List<(int, String)> _plan = [
  (0, 'Budgets'),
  (1, 'Bills'),
  (2, 'Forecast'),
];
const List<(int, String)> _insights = [
  (0, 'Reports'),
  (1, 'Net worth'),
  (2, 'Investments'),
  (3, 'Goals'),
];

Future<void> _pump(
  WidgetTester tester,
  List<(int, String)> segments,
  int selected, {
  double scale = 1,
}) async {
  tester.view.physicalSize =
      const Size(360, 640) * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(360, 640),
        textScaler: TextScaler.linear(scale),
      ),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentSwitcher<int>(
                segments: segments,
                selected: selected,
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _scroller() => find.descendant(
  of: find.byType(SegmentSwitcher<int>),
  matching: find.byType(SingleChildScrollView),
);

void _expectInView(WidgetTester tester, String label) {
  final Rect rect = tester.getRect(find.text(label));
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(360));
}

void main() {
  setUpAll(() async {
    final FontLoader workSans = FontLoader(AppTheme.bodyFont)
      ..addFont(rootBundle.load('assets/fonts/WorkSans-Medium.ttf'));
    await workSans.load();
  });

  testWidgets('at text scale 1 the Plan segments share the width', (
    tester,
  ) async {
    await _pump(tester, _plan, 2);
    expect(_scroller(), findsNothing);
    final SegmentedButton<int> button = tester.widget(
      find.byType(SegmentedButton<int>),
    );
    expect(button.expandedInsets, EdgeInsets.zero);
    expect(tester.getSize(find.byType(SegmentedButton<int>)).width, 360 - 32);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Insights segments scroll with a fade, Goals in view', (
    tester,
  ) async {
    await _pump(tester, _insights, 3);
    expect(_scroller(), findsOneWidget);
    _expectInView(tester, 'Goals');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the fade shows only while there is more past the edge', (
    tester,
  ) async {
    BlendMode mask() =>
        tester.widget<ShaderMask>(find.byType(ShaderMask)).blendMode;
    await _pump(tester, _insights, 0);
    expect(mask(), BlendMode.dstIn);
    // Scrolled to the end: nothing past it, no fade.
    await tester.drag(_scroller(), const Offset(-1000, 0));
    await tester.pumpAndSettle();
    expect(mask(), BlendMode.dst);
    // Back to the start: the fade again.
    await tester.drag(_scroller(), const Offset(1000, 0));
    await tester.pumpAndSettle();
    expect(mask(), BlendMode.dstIn);
  });

  testWidgets('a text size that stops the row fitting brings the segment shown '
      'into view', (tester) async {
    await _pump(tester, _plan, 2);
    expect(_scroller(), findsNothing);
    await _pump(tester, _plan, 2, scale: 2);
    expect(_scroller(), findsOneWidget);
    _expectInView(tester, 'Forecast');
  });

  for (final (String name, List<(int, String)> segments, int last) in [
    ('Plan', _plan, 2),
    ('Insights', _insights, 3),
  ]) {
    testWidgets('at text scale 2 the $name segments scroll, the one shown in '
        'view', (tester) async {
      await _pump(tester, segments, last, scale: 2);
      expect(_scroller(), findsOneWidget);
      _expectInView(tester, segments[last].$2);
      expect(tester.takeException(), isNull);
    });
  }
}
