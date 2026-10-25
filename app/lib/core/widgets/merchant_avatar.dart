/// A round avatar for a merchant or an institution: its logo when there is one (a URL
/// Plaid gave, loaded with `Image.network`, or bytes the device stored, with
/// `Image.memory`), else, and whenever the logo fails or is still loading, the name's
/// first letter or digit on [MerchantAvatar.color] in black or white, whichever contrasts
/// more (always at least 4.58:1, above WCAG AA's 4.5:1). Decorative unless given a
/// [MerchantAvatar.semanticsLabel]: the name it stands for is usually written beside it.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

/// An avatar of [name] in [color] (opaque ARGB), showing [logoUrl] or [logoBytes] when
/// given.
class MerchantAvatar extends StatelessWidget {
  const MerchantAvatar({
    super.key,
    required this.name,
    required this.color,
    this.logoUrl,
    this.logoBytes,
    this.radius = 20,
    this.semanticsLabel,
  });

  final String name;
  final int color;
  final Uri? logoUrl;
  final Uint8List? logoBytes;
  final double radius;

  /// What a screen reader says; null leaves the avatar out of the semantics tree.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final Color background = Color(color);
    final Widget letter = CircleAvatar(
      radius: radius,
      backgroundColor: background,
      foregroundColor: avatarForeground(background),
      child: Text(avatarLetter(name)),
    );
    // Shown once its first frame is decoded, on white, which logos are drawn for.
    Widget loaded(BuildContext context, Widget child, int? frame, bool _) =>
        frame == null
        ? letter
        : ClipOval(
            child: ColoredBox(color: Colors.white, child: child),
          );
    Widget failed(BuildContext context, Object error, StackTrace? stack) =>
        letter;
    final double size = radius * 2;
    final Widget avatar = switch ((logoBytes, logoUrl)) {
      (final Uint8List bytes, _) => Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        frameBuilder: loaded,
        errorBuilder: failed,
      ),
      (null, final Uri url) => Image.network(
        url.toString(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        frameBuilder: loaded,
        errorBuilder: failed,
      ),
      (null, null) => letter,
    };
    final Widget sized = SizedBox.square(dimension: size, child: avatar);
    return switch (semanticsLabel) {
      null => ExcludeSemantics(child: sized),
      final String label => Semantics(
        label: label,
        image: true,
        excludeSemantics: true,
        child: sized,
      ),
    };
  }
}

/// The first letter or digit of [name], upper-cased; `?` when it has none.
String avatarLetter(String name) {
  for (final String c in name.characters) {
    if (_letterOrDigit.hasMatch(c)) return c.toUpperCase();
  }
  return '?';
}

final RegExp _letterOrDigit = RegExp(r'^[\p{L}\p{N}]', unicode: true);

/// Black or white, whichever has the higher contrast ratio against [background].
Color avatarForeground(Color background) {
  final double luminance = background.computeLuminance();
  final double onBlack = (luminance + 0.05) / 0.05;
  final double onWhite = 1.05 / (luminance + 0.05);
  return onBlack > onWhite ? Colors.black : Colors.white;
}
