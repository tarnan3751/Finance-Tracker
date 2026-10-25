// The merchant avatar: the letter on its color with black or white text, whichever
// contrasts more, at WCAG AA or better for every dictionary and palette color and a sweep
// of others; a logo URL through Image.network and stored bytes through Image.memory, the
// letter whenever either fails; decorative unless labelled.
import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_tracker/core/widgets/merchant_avatar.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/features/transactions/domain/merchant_dictionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double light = la > lb ? la : lb;
  final double dark = la > lb ? lb : la;
  return (light + 0.05) / (dark + 0.05);
}

Future<void> _pump(WidgetTester tester, Widget avatar) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: avatar)),
  ),
);

// A 1x1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  test('the letter has AA contrast on every color', () {
    final List<int> colors = [
      for (final MerchantEntry e in merchantDictionary) ?e.color,
      ...palette,
      for (int r = 0; r < 256; r += 17)
        for (int g = 0; g < 256; g += 17)
          for (int b = 0; b < 256; b += 17) 0xFF000000 | r << 16 | g << 8 | b,
    ];
    for (final int argb in colors) {
      final Color background = Color(argb);
      expect(
        _contrast(background, avatarForeground(background)),
        greaterThanOrEqualTo(4.5),
        reason: argb.toRadixString(16),
      );
    }
  });

  test('the letter is the first letter or digit, upper-cased', () {
    expect(avatarLetter('netflix'), 'N');
    expect(avatarLetter('7-Eleven'), '7');
    expect(avatarLetter("'Ambar"), 'A');
    expect(avatarLetter('***'), '?');
  });

  testWidgets('with no logo, the letter on the color', (tester) async {
    await _pump(
      tester,
      const MerchantAvatar(name: 'Netflix', color: 0xFFE50914),
    );
    final CircleAvatar circle = tester.widget(find.byType(CircleAvatar));
    expect(circle.backgroundColor, const Color(0xFFE50914));
    expect(circle.foregroundColor, avatarForeground(const Color(0xFFE50914)));
    expect(find.text('N'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets(
    'a logo URL loads through the network, the letter when it fails',
    (tester) async {
      final Uri url = Uri.parse('https://plaid-merchant-logos.plaid.com/n.png');
      await _pump(
        tester,
        MerchantAvatar(name: 'Netflix', color: 0xFFE50914, logoUrl: url),
      );
      final Image image = tester.widget(find.byType(Image));
      expect((image.image as NetworkImage).url, url.toString());
      // While it loads, the letter.
      expect(find.text('N'), findsOneWidget);
      // flutter_test answers every request 400: the letter stays.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(find.text('N'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stored logo bytes show through memory, on white', (
    tester,
  ) async {
    await _pump(
      tester,
      MerchantAvatar(name: 'Tartan Bank', color: 0xFF283593, logoBytes: _png),
    );
    expect(find.byType(Image), findsOneWidget);
    await tester.runAsync(() async {
      await precacheImage(
        MemoryImage(_png),
        tester.element(find.byType(MerchantAvatar)),
      );
    });
    await tester.pump();
    expect(find.text('T'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ClipOval),
        matching: find.byType(RawImage),
      ),
      findsOneWidget,
    );
  });

  testWidgets('bytes that are not an image fall back to the letter', (
    tester,
  ) async {
    await _pump(
      tester,
      MerchantAvatar(
        name: 'Tartan Bank',
        color: 0xFF283593,
        logoBytes: Uint8List.fromList([1, 2, 3]),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.text('T'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('decorative by default, labelled when asked', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await _pump(
        tester,
        const MerchantAvatar(name: 'Netflix', color: 0xFFE50914),
      );
      expect(find.bySemanticsLabel('N'), findsNothing);
      await _pump(
        tester,
        const MerchantAvatar(
          name: 'Tartan Bank',
          color: 0xFF283593,
          semanticsLabel: 'Tartan Bank',
        ),
      );
      expect(find.bySemanticsLabel('Tartan Bank'), findsOneWidget);
      expect(find.bySemanticsLabel('T'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });
}
