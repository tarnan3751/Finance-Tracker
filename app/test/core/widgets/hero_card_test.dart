// The hero card: its label in capitals but read as written, the figure in paper Work Sans
// 700 with tabular figures, the pink copy offset by the misregistration, and the trailing
// widget at the end; a toned caption on a paper pill in the text pink, and the sentence a
// screen gives it; with its goldens, light and dark. Tagged `golden` for the goldens;
// see test/flutter_test_config.dart for where the files go and how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/hero_card.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

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

  testWidgets(
    'a toned caption prints on a paper pill in the text pink, and the '
    'card reads its sentence',
    (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: HeroCard(
              label: 'Due in 7 days',
              figure: Text(r'$130.86'),
              caption: r'$1,234.57 overdue',
              captionTone: HeroTone.outflow,
              semanticsLabel: r'Due in 7 days: $130.86, $1,234.57 overdue.',
            ),
          ),
        ),
      );

      final Finder caption = find.text(r'$1,234.57 overdue');
      expect(
        tester.widget<Text>(caption).style?.color,
        FinanceColors.light.outflow,
      );
      final DecoratedBox pill = tester.widget<DecoratedBox>(
        find.ancestor(of: caption, matching: find.byType(DecoratedBox)).first,
      );
      expect(
        (pill.decoration as BoxDecoration).color,
        AppTheme.lightScheme.surface,
      );
      expect(
        find.bySemanticsLabel(r'Due in 7 days: $130.86, $1,234.57 overdue.'),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    },
  );

  testWidgets('each currency is toned on its own', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: HeroCard(
            label: 'Spent',
            figure: HeroAmounts(
              [Money(12000, 'USD'), Money(3000, 'EUR')],
              tones: const [HeroTone.outflow, HeroTone.plain],
            ),
          ),
        ),
      ),
    );
    // The color the text is drawn in, its own or the one it inherits.
    Color? color(Money m) => tester
        .renderObject<RenderParagraph>(
          find.descendant(
            of: find.text(m.format()),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style
        ?.color;
    expect(color(Money(12000, 'USD')), FinanceColors.light.outflow);
    expect(color(Money(3000, 'EUR')), AppTheme.lightScheme.surface);
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
