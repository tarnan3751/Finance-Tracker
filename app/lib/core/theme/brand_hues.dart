/// The brand's eight hues for things that carry a color of their own
/// (`docs/reference/design.md`, **Category colors**): the four inks, then violet, teal,
/// orange and plum, each with its night print variant lifted as the inks are, and a
/// text-safe variant for a letter or an icon drawn on the hue's own tint ([hueTint]): the
/// same hue darkened on paper, lifted on the night print, until it reaches 4.8:1 on that
/// tint. A category's default color takes one of these.
library;

import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// The eight hues on paper: blue, pink, yellow, green, violet, teal, orange, plum.
const List<Color> brandHues = [
  Color(0xFF1F4FE0),
  Color(0xFFFF3EA5),
  Color(0xFFF2B705),
  Color(0xFF1E8A4A),
  Color(0xFF6B4FE0),
  Color(0xFF1E8A8A),
  Color(0xFFE0661F),
  Color(0xFF8A1E5C),
];

/// [brandHues] on the night print.
const List<Color> brandHuesDark = [
  Color(0xFF8FA8FF),
  Color(0xFFFF7AC3),
  Color(0xFFFFD24D),
  Color(0xFF5FD38B),
  Color(0xFFB0A0FF),
  Color(0xFF5FD3D3),
  Color(0xFFFFA266),
  Color(0xFFE07AB0),
];

/// [brandHues] for text on their tint on paper: at least 4.8:1 over [hueTint].
const List<Color> brandHueText = [
  Color(0xFF1B44C1),
  Color(0xFFA9005A),
  Color(0xFF785A02),
  Color(0xFF156235),
  Color(0xFF502EDA),
  Color(0xFF156060),
  Color(0xFF8F4114),
  Color(0xFF8A1E5C),
];

/// [brandHuesDark] for text on their tint on the night print.
const List<Color> brandHueTextDark = [
  Color(0xFF8FA8FF),
  Color(0xFFFF7AC3),
  Color(0xFFFFD24D),
  Color(0xFF5FD38B),
  Color(0xFFB0A0FF),
  Color(0xFF5FD3D3),
  Color(0xFFFFA266),
  Color(0xFFE388B9),
];

/// Hue [i] (`0` to `7`) in [brightness]'s theme.
Color brandHue(int i, Brightness brightness) =>
    (brightness == Brightness.dark ? brandHuesDark : brandHues)[i];

/// Hue [i]'s text-safe variant in [brightness]'s theme.
Color brandHueTextOn(int i, Brightness brightness) =>
    (brightness == Brightness.dark ? brandHueTextDark : brandHueText)[i];

/// [color]'s disc: its tint over [scheme]'s `surfaceContainer`.
Color hueTint(Color color, ColorScheme scheme) => Color.alphaBlend(
  color.withValues(alpha: SpendthriftTokens.tint),
  scheme.surfaceContainer,
);
