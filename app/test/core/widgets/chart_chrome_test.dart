// The charts' chrome: the legend pill in ink with its label in labelSmall
// onSurfaceVariant, the chart and table switch as a SegmentedButton, the chart's card;
// and the dialogs' and sheets' chrome the theme gives: a destructive action in the
// money-out pink, the drag handle in outlineVariant.
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/widgets/brand_card.dart';
import 'package:finance_tracker/core/widgets/chart_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('a legend entry is an ink-outlined pill', (tester) async {
    await tester.pumpWidget(
      _app(
        const LegendPill(swatch: SizedBox.square(dimension: 12), label: 'In'),
      ),
    );
    final ShapeDecoration pill =
        tester
                .widget<DecoratedBox>(
                  find.ancestor(
                    of: find.text('In'),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as ShapeDecoration;
    expect(pill.shape, isA<StadiumBorder>());
    expect(
      (pill.shape as StadiumBorder).side.color,
      AppTheme.lightScheme.outline,
    );
    expect(
      tester.widget<Text>(find.text('In')).style?.color,
      AppTheme.lightScheme.onSurfaceVariant,
    );
  });

  testWidgets('the switch shows the chart or the table', (tester) async {
    bool? chosen;
    await tester.pumpWidget(
      _app(
        ChartTableToggle(
          table: false,
          onChanged: (table) => chosen = table,
          chartLabel: 'Chart',
          tableLabel: 'Table',
        ),
      ),
    );
    expect(find.byType(SegmentedButton<bool>), findsOneWidget);
    await tester.tap(find.text('Table'));
    expect(chosen, isTrue);
  });

  testWidgets('a chart sits on a brand card', (tester) async {
    await tester.pumpWidget(_app(const ChartCard(child: Text('Chart'))));
    expect(
      find.ancestor(of: find.text('Chart'), matching: find.byType(BrandCard)),
      findsOneWidget,
    );
  });

  test('a sheet\'s handle is outlineVariant, a dialog\'s title Syne', () {
    final ThemeData theme = AppTheme.light();
    expect(
      theme.bottomSheetTheme.dragHandleColor,
      AppTheme.lightScheme.outlineVariant,
    );
    expect(theme.textTheme.headlineSmall?.fontFamily, AppTheme.headingFont);
  });

  testWidgets('a destructive action prints in the money-out pink', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            style: AppTheme.destructive(context),
            onPressed: () {},
            child: const Text('Delete'),
          ),
        ),
      ),
    );
    final DefaultTextStyle style = DefaultTextStyle.of(
      tester.element(find.text('Delete')),
    );
    expect(style.style.color, FinanceColors.light.outflow);
  });
}
