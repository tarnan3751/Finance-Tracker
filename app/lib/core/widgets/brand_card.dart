/// The card every screen builds its cards with (`docs/reference/design.md`, **Cards**):
/// paper, the ink line, radius 8 and no shadow (the card theme's), the content inside
/// token padding, an optional title over the content and an optional widget at the
/// end. A card with [BrandCard.onTap] inks its whole face and reads its title and content
/// as one button node, the trailing widget a node of its own; [BrandCard.enabled] false
/// dims it and reads it as disabled. Only the hero card has the
/// misregistration; a `BrandCard` is flat.
library;

import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// A flat ink-line card around [child], under [title], with [trailing] at the end.
class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    this.title,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.padding = const EdgeInsets.all(SpendthriftTokens.space16),
    required this.child,
  });

  /// The card's title, in the theme's `titleMedium`, or null for none.
  final String? title;

  /// A widget at the card's end, beside the title and the content (an action, a menu),
  /// or null.
  final Widget? trailing;

  /// What a tap on the card does, or null for a card that is not a button.
  final VoidCallback? onTap;

  /// Whether the card's tap is live: a disabled card dims its content, reads as disabled
  /// and does nothing when tapped.
  final bool enabled;

  /// The space between the ink line and the content.
  final EdgeInsetsGeometry padding;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String? title = this.title;
    final Widget? trailing = this.trailing;
    final VoidCallback? onTap = enabled ? this.onTap : null;
    Widget body = title == null
        ? child
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: SpendthriftTokens.space8),
              child,
            ],
          );
    if (this.onTap != null) {
      // The title and the content are one node, the card's button; the trailing widget
      // stays a node of its own, so a button there stays a button.
      body = MergeSemantics(
        child: Semantics(
          button: true,
          enabled: enabled,
          onTap: onTap,
          child: body,
        ),
      );
    }
    if (trailing != null) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: body),
          trailing,
        ],
      );
    }
    if (!enabled) {
      // The whole face, the trailing widget included.
      body = Opacity(opacity: _disabledOpacity, child: body);
    }
    body = Padding(padding: padding, child: body);
    if (this.onTap != null) {
      body = InkWell(
        onTap: onTap,
        // The semantics node above carries the tap.
        excludeFromSemantics: true,
        child: body,
      );
    }
    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}

/// How much of a disabled card's content shows, as Material dims a disabled control.
const double _disabledOpacity = 0.38;
