// The wordmark: Syne 800 in the blue over its pink copy, offset down and to the end,
// read once as a heading; and the mark, decorative.
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the wordmark prints blue over its pink copy, read once', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(children: [BrandMark(), Wordmark('Spendthrift')]),
        ),
      ),
    );
    final List<Text> texts = tester
        .widgetList<Text>(find.text('Spendthrift'))
        .toList();
    expect(texts.map((t) => t.style?.color), [
      FinanceColors.light.accent,
      AppTheme.lightScheme.primary,
    ]);
    expect(texts.first.style?.fontFamily, AppTheme.headingFont);
    expect(texts.first.style?.fontWeight, FontWeight.w800);
    final List<Offset> at = [
      for (final Element e in find.text('Spendthrift').evaluate())
        tester.getTopLeft(find.byWidget(e.widget)),
    ];
    expect(
      at.first - at.last,
      const Offset(
        SpendthriftTokens.iconMisregistration,
        SpendthriftTokens.iconMisregistration,
      ),
    );
    expect(find.bySemanticsLabel('Spendthrift'), findsOneWidget);
    semantics.dispose();
  });
}
