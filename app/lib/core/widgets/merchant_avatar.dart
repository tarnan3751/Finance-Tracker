/// A round avatar for a merchant or an institution: its logo when there is one (a URL
/// Plaid gave, loaded with `Image.network`, or bytes the device stored, with
/// `Image.memory`), else, and whenever the logo fails or is still loading, the name's
/// first letter or digit drawn as a category's icon is (`docs/reference/design.md`,
/// **Avatars**): on a disc of one of the brand's eight hues ([MerchantAvatar.hue], which
/// the name's hash chooses, `avatarHue`) at its tint over `surfaceContainer`, the letter in
/// the hue's text-safe variant (at least 4.8:1 on that tint in both themes). Decorative
/// unless given a [MerchantAvatar.semanticsLabel]: the name it stands for is usually
/// written beside it.
library;

import 'dart:typed_data';

import 'package:finance_tracker/core/theme/brand_hues.dart';
import 'package:flutter/material.dart';

/// An avatar of [name] in brand hue [hue], showing [logoUrl] or [logoBytes] when given.
class MerchantAvatar extends StatelessWidget {
  const MerchantAvatar({
    super.key,
    required this.name,
    required this.hue,
    this.logoUrl,
    this.logoBytes,
    this.radius = 20,
    this.semanticsLabel,
  });

  final String name;

  /// The brand hue (`0` to `7`, `brand_hues.dart`) the letter is drawn in.
  final int hue;
  final Uri? logoUrl;
  final Uint8List? logoBytes;
  final double radius;

  /// What a screen reader says; null leaves the avatar out of the semantics tree.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget letter = CircleAvatar(
      radius: radius,
      backgroundColor: hueTint(
        brandHue(hue, theme.brightness),
        theme.colorScheme,
      ),
      foregroundColor: brandHueTextOn(hue, theme.brightness),
      child: Text(avatarLetter(name)),
    );
    // Shown once its first frame is decoded, on white, which logos are drawn for.
    Widget loaded(BuildContext context, Widget child, int? frame, bool _) =>
        frame == null
        ? letter
        : ClipOval(
            child: ColoredBox(color: _logoBacking, child: child),
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

/// The backing of a logo: white, which logos are drawn for, in both themes.
const Color _logoBacking = Color(0xFFFFFFFF);
