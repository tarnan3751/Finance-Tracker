/// The Spendthrift light and dark themes (`docs/reference/design.md`).
///
/// Both are built by hand from the brand's palette ([AppTheme.lightScheme], paper and ink,
/// and [AppTheme.darkScheme], the night print) unless the device supplies dynamic color
/// schemes and the user has dynamic color on, in which case those schemes are used
/// (`SpendthriftApp` decides). Each carries the matching [FinanceColors], harmonized
/// with a dynamic scheme's primary color. Surfaces carry no tint.
///
/// The type is Syne for the display and headline styles and `titleLarge` (800 for
/// display, 700 otherwise, tracked at -0.02 em) and Work Sans for everything else, with
/// tabular figures so columns of amounts line up; the sizes are Material 3's. Text scale
/// is never clamped.
library;

import 'dart:ui' show lerpDouble;

import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// The app's themes.
abstract final class AppTheme {
  /// The heading face, bundled under `assets/fonts/`.
  static const String headingFont = 'Syne';

  /// The body face, for text, lists and every number.
  static const String bodyFont = 'WorkSans';

  /// Digits of one width, so amounts line up.
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// [base] as a money figure: Work Sans 700 with tabular figures, at [base]'s size.
  static TextStyle figure(TextStyle? base) =>
      (base ?? const TextStyle()).copyWith(
        fontFamily: bodyFont,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        fontFeatures: tabularFigures,
      );

  /// The light scheme: ink on paper, blue, pink and yellow inks.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    surface: Color(0xFFF7F3EA),
    onSurface: Color(0xFF1F1F1F),
    onSurfaceVariant: Color(0xFF5C574C),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3EEE3),
    surfaceContainer: Color(0xFFEFE9DC),
    surfaceContainerHigh: Color(0xFFE9E2D3),
    surfaceContainerHighest: Color(0xFFE2DAC8),
    primary: Color(0xFF1F4FE0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD6E0FF),
    onPrimaryContainer: Color(0xFF0E1E60),
    secondary: Color(0xFFFF3EA5),
    onSecondary: Color(0xFF1F1F1F),
    secondaryContainer: Color(0xFFFFD6EC),
    onSecondaryContainer: Color(0xFF4A0A2B),
    tertiary: Color(0xFFF2B705),
    onTertiary: Color(0xFF1F1F1F),
    tertiaryContainer: Color(0xFFFFF0B8),
    onTertiaryContainer: Color(0xFF3A2D00),
    error: Color(0xFFC32237),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD9),
    onErrorContainer: Color(0xFF410006),
    outline: Color(0xFF1F1F1F),
    outlineVariant: Color(0xFFB9B2A3),
    inverseSurface: Color(0xFF1F1F1F),
    onInverseSurface: Color(0xFFF7F3EA),
    inversePrimary: Color(0xFF8FA8FF),
    surfaceTint: Colors.transparent,
  );

  /// The dark scheme, the night print: light ink on night paper.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    surface: Color(0xFF16151C),
    onSurface: Color(0xFFF1ECE1),
    onSurfaceVariant: Color(0xFFB5AFA3),
    surfaceContainerLowest: Color(0xFF0F0E13),
    surfaceContainerLow: Color(0xFF1B1A21),
    surfaceContainer: Color(0xFF1F1E27),
    surfaceContainerHigh: Color(0xFF27262F),
    surfaceContainerHighest: Color(0xFF302F39),
    primary: Color(0xFF8FA8FF),
    onPrimary: Color(0xFF0E1230),
    primaryContainer: Color(0xFF2A3F8F),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFFFF7AC3),
    onSecondary: Color(0xFF2A0A1C),
    secondaryContainer: Color(0xFF6E1F4A),
    onSecondaryContainer: Color(0xFFFFDCEE),
    tertiary: Color(0xFFFFD24D),
    onTertiary: Color(0xFF2A2000),
    tertiaryContainer: Color(0xFF5E4A00),
    onTertiaryContainer: Color(0xFFFFF0B8),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF3A0000),
    errorContainer: Color(0xFF7A1C1C),
    onErrorContainer: Color(0xFFFFDAD9),
    // The ink line identifies a field: 3:1 against the surfaces it sits on.
    outline: Color(0xFF73727F),
    outlineVariant: Color(0xFF3A3944),
    inverseSurface: Color(0xFFF1ECE1),
    onInverseSurface: Color(0xFF16151C),
    inversePrimary: Color(0xFF1F4FE0),
    surfaceTint: Colors.transparent,
  );

  /// The light theme, from [dynamicScheme] when given, else from [lightScheme].
  static ThemeData light([ColorScheme? dynamicScheme]) =>
      _theme(dynamicScheme ?? lightScheme, switch (dynamicScheme) {
        final ColorScheme scheme => FinanceColors.light.harmonized(
          scheme.primary,
        ),
        null => FinanceColors.light,
      });

  /// The dark theme, from [dynamicScheme] when given, else from [darkScheme].
  static ThemeData dark([ColorScheme? dynamicScheme]) => _theme(
    dynamicScheme ?? darkScheme,
    switch (dynamicScheme) {
      final ColorScheme scheme => FinanceColors.dark.harmonized(scheme.primary),
      null => FinanceColors.dark,
    },
  );

  static ThemeData _theme(ColorScheme scheme, FinanceColors finance) {
    final ThemeData base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: bodyFont,
      extensions: [finance],
    );
    final TextTheme textTheme = _textTheme(base.textTheme);
    return base.copyWith(
      textTheme: textTheme,
      // The component themes below take whole text styles, which `Theme` does not size:
      // they carry Material 3's English sizes under the theme's faces and colors.
      appBarTheme: _appBar(scheme),
      navigationBarTheme: _navigationBar(scheme, _sized(textTheme)),
      navigationRailTheme: _navigationRail(scheme, _sized(textTheme)),
      cardTheme: _card(scheme),
      listTileTheme: _listTile(scheme, _sized(textTheme)),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: _rounded()),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: _rounded(), side: _ink(scheme)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: _rounded()),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(elevation: 0, shape: _rounded()),
      ),
      segmentedButtonTheme: _segmentedButton(scheme),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: _ink(scheme),
        elevation: 0,
        pressElevation: 0,
      ),
      inputDecorationTheme: _inputDecoration(scheme),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: _rounded(SpendthriftTokens.radiusLarge, _ink(scheme)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: scheme.outlineVariant,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(SpendthriftTokens.radiusLarge),
          ),
          side: _ink(scheme),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        // The pink action: the accent on ink, and on the night print's paper-light
        // inverse surface the light theme's text pink, which reads on paper.
        actionTextColor: scheme.brightness == Brightness.light
            ? finance.accent
            : FinanceColors.light.outflow,
        elevation: 0,
        shape: _rounded(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: scheme.outlineVariant,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: _MisregisteredBorder(color: finance.accent),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: _rounded(SpendthriftTokens.radius, _ink(scheme)),
      ),
      menuTheme: MenuThemeData(style: _menu(scheme)),
      dropdownMenuTheme: DropdownMenuThemeData(menuStyle: _menu(scheme)),
    );
  }

  /// A destructive action's text button style in [context]'s theme: the money-out pink,
  /// never the error red, which is for errors only.
  static ButtonStyle destructive(BuildContext context) =>
      TextButton.styleFrom(foregroundColor: FinanceColors.of(context).outflow);

  /// [t] with Material 3's English sizes.
  static TextTheme _sized(TextTheme t) =>
      Typography.material2021().englishLike.merge(t);

  /// The ink line in [scheme]'s outline color.
  static BorderSide _ink(ColorScheme scheme) =>
      BorderSide(color: scheme.outline, width: SpendthriftTokens.inkLine);

  /// A rounded rectangle of [radius], with [side].
  static RoundedRectangleBorder _rounded([
    double radius = SpendthriftTokens.radius,
    BorderSide side = BorderSide.none,
  ]) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: side,
  );

  static AppBarThemeData _appBar(ColorScheme scheme) => AppBarThemeData(
    backgroundColor: scheme.surface,
    foregroundColor: scheme.onSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
  );

  static NavigationBarThemeData _navigationBar(
    ColorScheme scheme,
    TextTheme text,
  ) => NavigationBarThemeData(
    backgroundColor: scheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    indicatorColor: scheme.primaryContainer,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        size: 24,
        color: states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.onSurfaceVariant,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => text.labelMedium!.copyWith(
        color: states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.onSurfaceVariant,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w600
            : FontWeight.w500,
      ),
    ),
  );

  static NavigationRailThemeData _navigationRail(
    ColorScheme scheme,
    TextTheme text,
  ) => NavigationRailThemeData(
    backgroundColor: scheme.surface,
    elevation: 0,
    indicatorColor: scheme.primaryContainer,
    selectedIconTheme: IconThemeData(size: 24, color: scheme.primary),
    unselectedIconTheme: IconThemeData(
      size: 24,
      color: scheme.onSurfaceVariant,
    ),
    selectedLabelTextStyle: text.labelMedium!.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelTextStyle: text.labelMedium!.copyWith(
      color: scheme.onSurfaceVariant,
    ),
  );

  static CardThemeData _card(ColorScheme scheme) => CardThemeData(
    color: scheme.surface,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    // The screens space their cards.
    margin: EdgeInsets.zero,
    shape: _rounded(SpendthriftTokens.radius, _ink(scheme)),
  );

  static ListTileThemeData _listTile(ColorScheme scheme, TextTheme text) =>
      ListTileThemeData(
        visualDensity: const VisualDensity(vertical: -1),
        titleTextStyle: text.bodyLarge!.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      );

  static SegmentedButtonThemeData _segmentedButton(ColorScheme scheme) =>
      SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          // 12 at the sides, so the Plan and Insights switchers fit a 360 dp phone at
          // text scale 1 (`segment_switcher.dart`).
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: SpendthriftTokens.space12),
          ),
          side: WidgetStatePropertyAll(_ink(scheme)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
        ),
      );

  static InputDecorationThemeData _inputDecoration(ColorScheme scheme) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(SpendthriftTokens.radius),
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecorationThemeData(
      border: border(scheme.outline, SpendthriftTokens.inkLine),
      enabledBorder: border(scheme.outline, SpendthriftTokens.inkLine),
      focusedBorder: border(scheme.primary, SpendthriftTokens.focusLine),
      disabledBorder: border(scheme.outlineVariant, SpendthriftTokens.inkLine),
      errorBorder: border(scheme.error, SpendthriftTokens.inkLine),
      focusedErrorBorder: border(scheme.error, SpendthriftTokens.focusLine),
    );
  }

  static MenuStyle _menu(ColorScheme scheme) => MenuStyle(
    backgroundColor: WidgetStatePropertyAll(scheme.surface),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(0),
    shape: WidgetStatePropertyAll(_rounded()),
    side: WidgetStatePropertyAll(_ink(scheme)),
  );

  /// [t], Material 3's scale in Work Sans, with the headings in Syne and tabular figures
  /// in the rest.
  static TextTheme _textTheme(TextTheme t) {
    // The theme's text styles carry no sizes: `Theme` merges in the script's geometry,
    // whose sizes for English are Material 3's.
    final TextTheme geometry = Typography.material2021().englishLike;
    TextStyle heading(TextStyle? style, TextStyle? sized, FontWeight weight) =>
        style!.copyWith(
          fontFamily: headingFont,
          fontWeight: weight,
          letterSpacing: -0.02 * sized!.fontSize!,
        );
    TextStyle body(TextStyle? style) =>
        style!.copyWith(fontFeatures: tabularFigures);
    return t.copyWith(
      displayLarge: heading(
        t.displayLarge,
        geometry.displayLarge,
        FontWeight.w800,
      ),
      displayMedium: heading(
        t.displayMedium,
        geometry.displayMedium,
        FontWeight.w800,
      ),
      displaySmall: heading(
        t.displaySmall,
        geometry.displaySmall,
        FontWeight.w800,
      ),
      headlineLarge: heading(
        t.headlineLarge,
        geometry.headlineLarge,
        FontWeight.w700,
      ),
      headlineMedium: heading(
        t.headlineMedium,
        geometry.headlineMedium,
        FontWeight.w700,
      ),
      headlineSmall: heading(
        t.headlineSmall,
        geometry.headlineSmall,
        FontWeight.w700,
      ),
      titleLarge: heading(t.titleLarge, geometry.titleLarge, FontWeight.w700),
      titleMedium: body(t.titleMedium),
      titleSmall: body(t.titleSmall),
      bodyLarge: body(t.bodyLarge),
      bodyMedium: body(t.bodyMedium),
      bodySmall: body(t.bodySmall),
      labelLarge: body(t.labelLarge),
      labelMedium: body(t.labelMedium),
      labelSmall: body(t.labelSmall),
    );
  }
}

/// The floating button's shape: a rectangle of the brand's radius with its pink copy
/// offset down and to the end by the misregistration, painted where the copy shows past
/// the button (the copy less the button), so it never covers the button's ink. The one
/// place the offset copy appears outside the hero card. It lerps (the offset, the color
/// and the rounded border), so a theme animation keeps the copy throughout.
class _MisregisteredBorder extends RoundedRectangleBorder {
  const _MisregisteredBorder({
    required this.color,
    this.offset = SpendthriftTokens.misregistration,
    super.side,
    super.borderRadius = const BorderRadius.all(
      Radius.circular(SpendthriftTokens.radius),
    ),
  });

  /// The copy's color, the accent.
  final Color color;

  /// How far the copy sits down and to the end.
  final double offset;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Offset shift = Offset(
      textDirection == TextDirection.rtl ? -offset : offset,
      offset,
    );
    final Path button = getOuterPath(rect, textDirection: textDirection);
    canvas.drawPath(
      Path.combine(PathOperation.difference, button.shift(shift), button),
      Paint()..color = color,
    );
    super.paint(canvas, rect, textDirection: textDirection);
  }

  /// This border at [t] of the way from [a], a plain rounded border when [a] has no
  /// copy (its copy then grows from nothing).
  _MisregisteredBorder? _from(ShapeBorder? a, double t) => switch (a) {
    final _MisregisteredBorder a => _MisregisteredBorder(
      color: Color.lerp(a.color, color, t)!,
      offset: lerpDouble(a.offset, offset, t)!,
      side: BorderSide.lerp(a.side, side, t),
      borderRadius: BorderRadiusGeometry.lerp(a.borderRadius, borderRadius, t)!,
    ),
    final RoundedRectangleBorder a => _MisregisteredBorder(
      color: Color.lerp(color.withValues(alpha: 0), color, t)!,
      offset: offset * t,
      side: BorderSide.lerp(a.side, side, t),
      borderRadius: BorderRadiusGeometry.lerp(a.borderRadius, borderRadius, t)!,
    ),
    _ => null,
  };

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      _from(a, t) ?? super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => switch (b) {
    final _MisregisteredBorder b => b._from(this, t),
    _ => super.lerpTo(b, t),
  };

  @override
  RoundedRectangleBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => _MisregisteredBorder(
    color: color,
    offset: offset,
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  ShapeBorder scale(double t) => _MisregisteredBorder(
    color: color,
    offset: offset * t,
    side: side.scale(t),
    borderRadius: borderRadius * t,
  );

  @override
  bool operator ==(Object other) =>
      other is _MisregisteredBorder &&
      other.color == color &&
      other.offset == offset &&
      other.side == side &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(color, offset, side, borderRadius);
}
