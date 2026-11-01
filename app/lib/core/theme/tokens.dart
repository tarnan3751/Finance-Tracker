/// The Spendthrift design tokens (`docs/reference/design.md`): the corner radii, the ink
/// line, the spacing scale and the misregistration offset of the "Riso" direction (two
/// inks on paper, `PLAN.md` §12 "Brand: Riso"). Elevation is zero everywhere, so there is
/// no elevation token.
library;

/// The constants the themes and the shared widgets are drawn with.
abstract final class SpendthriftTokens {
  /// The radius of cards, buttons and fields.
  static const double radius = 8;

  /// The radius of sheets and dialogs.
  static const double radiusLarge = 16;

  /// The radius of a pill: chips and the navigation indicator.
  static const double radiusPill = 999;

  /// The width of the ink line, the border of cards, fields, sheets and the bar.
  static const double inkLine = 1.5;

  /// The width of a focused field's border.
  static const double focusLine = 2;

  /// The spacing scale.
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;

  /// How far the pink copy under a hero card or the floating button is offset, down and
  /// to the end: the misregistration of a two-ink print.
  static const double misregistration = 5;

  /// The same offset for an icon's pink copy.
  static const double iconMisregistration = 3;

  /// The stroke of a chart's line.
  static const double chartStroke = 2.5;

  /// The radius of a bar's top corners.
  static const double barTopRadius = 4;

  /// The opacity of an ink's tint, for bands and fills.
  static const double tint = 0.20;
}
