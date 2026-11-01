// The section header: Syne in capitals at titleSmall, tracked, read as written and
// announced as a header, 24 above and 8 below; and the underlined group heading.
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Column(children: [child])),
);

void main() {
  testWidgets('Syne capitals, read as written, announced as a header', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const SectionHeader('Sync')));

    final Text text = tester.widget<Text>(find.text('SYNC'));
    expect(text.style?.fontFamily, AppTheme.headingFont);
    expect(text.style?.fontWeight, FontWeight.w700);
    expect(text.style?.letterSpacing, closeTo(0.08 * 14, 0.001));
    final SemanticsNode node = tester.getSemantics(find.text('SYNC'));
    expect(node.label, 'Sync');
    expect(node.getSemanticsData().flagsCollection.isHeader, isTrue);
    expect(
      tester.getTopLeft(find.text('SYNC')),
      const Offset(SpendthriftTokens.space16, SpendthriftTokens.space24),
    );
    semantics.dispose();
  });

  testWidgets('a group heading draws its ink line on paper', (tester) async {
    await tester.pumpWidget(
      _app(const SectionHeader('Today', underline: true)),
    );
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find.ancestor(
        of: find.text('TODAY'),
        matching: find.byType(DecoratedBox),
      ),
    );
    final BoxDecoration decoration = box.decoration as BoxDecoration;
    expect(decoration.color, AppTheme.lightScheme.surface);
    expect(
      (decoration.border! as Border).bottom,
      const BorderSide(
        color: Color(0xFF1F1F1F),
        width: SpendthriftTokens.inkLine,
      ),
    );
  });
}
