// The merchant avatar: the letter in one of the brand's eight hues, chosen by the name's
// hash and the same on every build, on the hue's tint over surfaceContainer, the letter at
// 4.8:1 or better on that tint for every hue in both themes; a logo URL through Image.network and stored bytes through Image.memory, the
// letter whenever either fails; decorative unless labelled.
import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/brand_hues.dart';
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

Future<void> _pump(
  WidgetTester tester,
  Widget avatar, {
  Brightness brightness = Brightness.light,
}) => tester.pumpWidget(
  MaterialApp(
    // A new app each time, so the theme does not animate from the last one.
    key: UniqueKey(),
    theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
    home: Scaffold(body: Center(child: avatar)),
  ),
);

// A 1x1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  test('a name takes one of the eight hues, the same every time', () {
    final Set<int> hues = {
      for (final MerchantEntry e in merchantDictionary) avatarHue(e.name),
    };
    expect(hues, {for (int i = 0; i < avatarHueCount; i++) i});
    expect(avatarHueCount, brandHues.length);
    expect(avatarHue('SAFEWAY #1234'), avatarHue('Safeway 1234'));
    expect(avatarHue('Safeway'), nameHash('safeway') % avatarHueCount);
  });

  for (final Brightness brightness in Brightness.values) {
    test('the letter reaches 4.8:1 on every tint, ${brightness.name}', () {
      final ColorScheme scheme = brightness == Brightness.light
          ? AppTheme.lightScheme
          : AppTheme.darkScheme;
      for (int i = 0; i < brandHues.length; i++) {
        expect(
          _contrast(
            brandHueTextOn(i, brightness),
            hueTint(brandHue(i, brightness), scheme),
          ),
          greaterThanOrEqualTo(4.8),
          reason: 'hue $i',
        );
      }
    });
  }

  test('the letter is the first letter or digit, upper-cased', () {
    expect(avatarLetter('netflix'), 'N');
    expect(avatarLetter('7-Eleven'), '7');
    expect(avatarLetter("'Ambar"), 'A');
    expect(avatarLetter('***'), '?');
  });

  for (final Brightness brightness in Brightness.values) {
    testWidgets('with no logo, the letter on its hue\'s tint, '
        '${brightness.name}', (tester) async {
      await _pump(
        tester,
        const MerchantAvatar(name: 'Netflix', hue: 6),
        brightness: brightness,
      );
      final CircleAvatar circle = tester.widget(find.byType(CircleAvatar));
      final ColorScheme scheme = brightness == Brightness.light
          ? AppTheme.lightScheme
          : AppTheme.darkScheme;
      expect(circle.backgroundColor, hueTint(brandHue(6, brightness), scheme));
      expect(circle.foregroundColor, brandHueTextOn(6, brightness));
      expect(find.text('N'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  }

  testWidgets('a merchant keeps its hue across rebuilds', (tester) async {
    Color? background() =>
        tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundColor;
    final int hue = avatarHue('Blue Bottle Coffee');
    await _pump(tester, MerchantAvatar(name: 'Blue Bottle Coffee', hue: hue));
    final Color? first = background();
    await _pump(
      tester,
      MerchantAvatar(
        name: 'Blue Bottle Coffee',
        hue: avatarHue('BLUE BOTTLE COFFEE'),
      ),
    );
    expect(background(), first);
  });

  testWidgets(
    'a logo URL loads through the network, the letter when it fails',
    (tester) async {
      final Uri url = Uri.parse('https://plaid-merchant-logos.plaid.com/n.png');
      await _pump(
        tester,
        MerchantAvatar(name: 'Netflix', hue: 1, logoUrl: url),
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
      MerchantAvatar(name: 'Tartan Bank', hue: 0, logoBytes: _png),
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
        hue: 0,
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
      await _pump(tester, const MerchantAvatar(name: 'Netflix', hue: 1));
      expect(find.bySemanticsLabel('N'), findsNothing);
      await _pump(
        tester,
        const MerchantAvatar(
          name: 'Tartan Bank',
          hue: 0,
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
