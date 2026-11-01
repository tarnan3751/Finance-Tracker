// The brand card: paper with the ink line at radius 8 and no shadow, its content inside
// the token padding, the title over the content with an action at the end, a tappable
// card read as one button node beside its trailing button, and a disabled card dimmed,
// read as disabled and not tapped.
import 'dart:ui' show Tristate;

import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/brand_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(
    body: Align(alignment: Alignment.topCenter, child: child),
  ),
);

void main() {
  testWidgets('paper, the ink line at radius 8, no shadow, token padding', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const BrandCard(child: Text('Body'))));
    const ColorScheme scheme = AppTheme.lightScheme;
    final Material material = tester.widget<Material>(
      find.descendant(of: find.byType(Card), matching: find.byType(Material)),
    );
    expect(material.color, scheme.surface);
    expect(material.elevation, 0);
    final RoundedRectangleBorder shape =
        material.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(SpendthriftTokens.radius));
    expect(shape.side.color, scheme.outline);
    expect(shape.side.width, SpendthriftTokens.inkLine);
    expect(
      tester.getTopLeft(find.text('Body')) -
          tester.getTopLeft(find.byType(Card)),
      const Offset(SpendthriftTokens.space16, SpendthriftTokens.space16),
    );
  });

  testWidgets('the title row carries its action at the end', (tester) async {
    await tester.pumpWidget(
      _app(
        BrandCard(
          title: 'Title',
          trailing: IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
          child: const Text('Body'),
        ),
      ),
    );
    expect(
      tester.getCenter(find.byTooltip('More')).dx,
      greaterThan(tester.getCenter(find.text('Title')).dx),
    );
    expect(
      tester.getTopLeft(find.text('Body')).dy,
      greaterThan(tester.getBottomLeft(find.text('Title')).dy),
    );
  });

  testWidgets('a tappable card reads as one node and taps', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    int taps = 0;
    await tester.pumpWidget(
      _app(
        BrandCard(
          onTap: () => taps++,
          child: const Column(children: [Text('Rent'), Text(r'$1,650.00')]),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Rent\n\$1,650.00'), findsOneWidget);
    await tester.tap(find.text('Rent'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('a trailing button stays its own node beside the card\'s', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        BrandCard(
          title: 'Renter',
          onTap: () {},
          trailing: IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
          child: const Text('One account, rent'),
        ),
      ),
    );
    final SemanticsNode card = tester.getSemantics(find.text('Renter'));
    final SemanticsNode button = tester.getSemantics(find.byTooltip('More'));
    expect(card, isNot(same(button)));
    expect(card.label, 'Renter\nOne account, rent');
    expect(card.getSemanticsData().flagsCollection.isButton, isTrue);
    expect(button.tooltip, 'More');
    semantics.dispose();
  });

  testWidgets('a disabled card is dimmed, read as disabled, not tapped', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    int taps = 0;
    await tester.pumpWidget(
      _app(
        BrandCard(
          enabled: false,
          onTap: () => taps++,
          trailing: const Icon(Icons.chevron_right),
          child: const Text('Renter'),
        ),
      ),
    );
    final SemanticsData data = tester
        .getSemantics(find.text('Renter'))
        .getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Renter'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
    // The trailing widget is dimmed with the rest of the face.
    expect(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Renter'));
    expect(taps, 0);
    semantics.dispose();
  });
}
