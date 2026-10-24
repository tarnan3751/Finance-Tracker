/// The strip naming the flavor (DEV, DEMO) at the top of the whole app.
///
/// A full-width strip, [FlavorBanner.height] tall, on the theme's error-container color,
/// laid out between the status bar and the app: the strip's color fills the status bar
/// area too, and the app below gets the remaining height with the top system padding
/// removed, so the strip never covers an app bar or its actions. The label is scaled down
/// to fit the strip at any text size. Excluded from semantics: it marks the build, not
/// the content.
library;

import 'package:flutter/material.dart';

/// Draws [message] in a strip above [child].
class FlavorBanner extends StatelessWidget {
  const FlavorBanner({super.key, required this.message, required this.child});

  /// The strip's height below the status bar, in logical pixels.
  static const double height = 16;

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: ColoredBox(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: EdgeInsets.only(top: padding.top),
              child: SizedBox(
                height: height,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      message,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 10,
                        height: 1,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          // The strip takes the status bar's place; the app below has no top inset.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
