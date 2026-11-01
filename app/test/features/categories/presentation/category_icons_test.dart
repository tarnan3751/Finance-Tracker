// The categories' colors as drawn: every system category in its default taxonomy color
// takes a hue of the brand's eight, lifted on the night print, with neighbouring
// top-level categories apart in Plaid's order and by name; a color the user chose stays
// as chosen (lightened in the dark theme, harmonized with the primary); and the icon's
// disc is the color's tint over surfaceContainer, the icon on it at 3:1 or better.
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/brand_hues.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/categories/presentation/category_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

/// [category]'s color as drawn in the [brightness] theme.
Future<Color> _drawn(
  WidgetTester tester,
  Category category,
  Brightness brightness,
) async {
  late Color color;
  await tester.pumpWidget(
    MaterialApp(
      // A new app each time, so the theme does not animate from the last one.
      key: UniqueKey(),
      theme: brightness == Brightness.light
          ? AppTheme.light()
          : AppTheme.dark(),
      home: Builder(
        builder: (context) {
          color = categoryColorOf(context, category);
          return const SizedBox();
        },
      ),
    ),
  );
  return color;
}

Category _custom(int color) => Category(
  id: 'mine',
  name: 'Mine',
  isSystem: false,
  icon: 'savings',
  color: color,
);

void main() {
  testWidgets('every system category takes a brand hue, lifted in the dark', (
    tester,
  ) async {
    for (final Category c in systemCategories) {
      final Color light = await _drawn(tester, c, Brightness.light);
      final Color dark = await _drawn(tester, c, Brightness.dark);
      final int hue = brandHues.indexOf(light);
      expect(hue, isNonNegative, reason: c.id);
      expect(dark, brandHuesDark[hue], reason: c.id);
    }
  });

  testWidgets('neighbouring top-level categories differ, in Plaid order and '
      'by name', (tester) async {
    final List<Category> top = [
      for (final Category c in systemCategories)
        if (c.parentId == null) c,
    ];
    final List<Category> byName = [...top]
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final List<Category> order in [top, byName]) {
      for (int i = 1; i < order.length; i++) {
        expect(
          await _drawn(tester, order[i], Brightness.light),
          isNot(await _drawn(tester, order[i - 1], Brightness.light)),
          reason: '${order[i - 1].name} and ${order[i].name}',
        );
      }
    }
  });

  testWidgets('a detailed category reads as its primary', (tester) async {
    final Category groceries = systemCategories.singleWhere(
      (c) => c.id == systemCategoryId('FOOD_AND_DRINK_GROCERIES'),
    );
    final Category food = systemCategories.singleWhere(
      (c) => c.id == systemCategoryId('FOOD_AND_DRINK'),
    );
    expect(
      await _drawn(tester, groceries, Brightness.light),
      await _drawn(tester, food, Brightness.light),
    );
  });

  testWidgets('a color the user chose stays as chosen', (tester) async {
    // The editor's orange, which the taxonomy's Food and drink also wears.
    final Category mine = _custom(0xFFEF6C00);
    expect(
      await _drawn(tester, mine, Brightness.light),
      FinanceColors.light.custom(const Color(0xFFEF6C00)),
    );
    expect(
      await _drawn(tester, mine, Brightness.dark),
      FinanceColors.dark.custom(
        Color.lerp(const Color(0xFFEF6C00), Colors.white, 0.45)!,
      ),
    );
  });

  testWidgets('the disc is the tint over surfaceContainer, the icon the '
      'hue\'s text-safe variant', (tester) async {
    final Category food = systemCategories.singleWhere(
      (c) => c.id == systemCategoryId('FOOD_AND_DRINK'),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: CategoryIconDisc(food)),
      ),
    );
    final BoxDecoration disc =
        tester
                .widget<DecoratedBox>(
                  find.ancestor(
                    of: find.byIcon(Icons.restaurant),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(disc.color, hueTint(brandHues[6], AppTheme.lightScheme));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.restaurant)).color,
      brandHueText[6],
    );
  });

  for (final Brightness brightness in Brightness.values) {
    test('every hue\'s icon reaches 3:1 on its disc, ${brightness.name}', () {
      final ColorScheme scheme = brightness == Brightness.light
          ? AppTheme.lightScheme
          : AppTheme.darkScheme;
      for (int i = 0; i < brandHues.length; i++) {
        expect(
          _contrast(
            brandHueTextOn(i, brightness),
            hueTint(brandHue(i, brightness), scheme),
          ),
          greaterThanOrEqualTo(3),
          reason: 'hue $i',
        );
      }
    });
  }

  test('a color the user chose is moved until it reaches 3:1', () {
    const Color yellow = Color(0xFFF2B705);
    final Color disc = hueTint(yellow, AppTheme.lightScheme);
    expect(
      _contrast(readableOn(yellow, disc, Brightness.light), disc),
      greaterThanOrEqualTo(3),
    );
  });
}

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}
