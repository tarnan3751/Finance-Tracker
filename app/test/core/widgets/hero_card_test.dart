// The hero card: its label in capitals but read as written, the figure in paper Work Sans
// 700 with tabular figures, the pink copy offset by the misregistration, and the trailing
// widget at the end; with its goldens, light and dark. Tagged `golden` for the goldens;
// see test/flutter_test_config.dart for where the files go and how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';

Widget _card(Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
  home: const Scaffold(
    body: Padding(
      padding: EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: HeroCard(
          label: 'Totals',
          figure: Text(r'$4,920.16'),
          caption: 'from transactions',
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('the hero card prints the figure in paper on blue over its pink '
      'copy', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(_card(Brightness.light));
    const ColorScheme scheme = AppTheme.lightScheme;

    expect(find.text('TOTALS'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Totals\n\$4,920\.16\nfrom transactions$'),
      ),
      findsOneWidget,
    );

    final TextStyle figure = DefaultTextStyle.of(
      tester.element(find.text(r'$4,920.16')),
    ).style;
    expect(figure.fontFamily, AppTheme.bodyFont);
    expect(figure.fontWeight, FontWeight.w700);
    expect(figure.fontFeatures, AppTheme.tabularFigures);
    expect(figure.color, scheme.surface);

    Finder box(Color color) => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == color,
    );
    final Rect block = tester.getRect(box(scheme.primary));
    final Rect copy = tester.getRect(box(FinanceColors.light.accent));
    expect(copy.size, block.size);
    expect(
      copy.topLeft - block.topLeft,
      const Offset(
        SpendthriftTokens.misregistration,
        SpendthriftTokens.misregistration,
      ),
    );
    expect(
      tester.getCenter(find.byIcon(Icons.chevron_right)).dx,
      greaterThan(tester.getCenter(find.text('TOTALS')).dx),
    );
    semantics.dispose();
  });

  testWidgets('a button at the end stays its own node beside the merged card', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: HeroCard(
            label: 'Totals',
            figure: const Text(r'$4,920.16'),
            trailing: IconButton(
              tooltip: 'Details',
              onPressed: () {},
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ),
    );
    final SemanticsNode card = tester.getSemantics(find.text('TOTALS'));
    final SemanticsNode button = tester.getSemantics(find.byType(IconButton));
    expect(card, isNot(same(button)));
    expect(card.label, 'Totals\n\$4,920.16');
    expect(card.flagsCollection.isButton, isFalse);
    expect(button.flagsCollection.isButton, isTrue);
    expect(button.tooltip, 'Details');
    semantics.dispose();
  });

  for (final Brightness brightness in Brightness.values) {
    goldenTest(
      'the hero card, ${brightness.name}',
      fileName: 'hero_card_${brightness.name}',
      constraints: BoxConstraints.tight(const Size(412, 200)),
      builder: () =>
          SizedBox(width: 412, height: 200, child: _card(brightness)),
    );
  }
}
