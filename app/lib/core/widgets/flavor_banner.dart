/// The strip naming the flavor (DEV, DEMO) at the top of the whole app.
///
/// A full-width strip, [FlavorBanner.height] tall, in ink with paper text (the theme's
/// inverse surface, so it stands out on the night print too),
/// laid out between the status bar and the app: the strip's color fills the status bar
/// area too, and the app below gets the remaining height with the top system padding
/// removed, so the strip never covers an app bar or its actions. The label is scaled down
/// to fit the strip at any text size. The status bar's icons take the brightness that
/// reads on the strip. Excluded from semantics: it marks the build, not the content.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: statusBarStyleOn(theme.colorScheme.inverseSurface),
            child: ColoredBox(
              color: theme.colorScheme.inverseSurface,
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
                          color: theme.colorScheme.onInverseSurface,
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

/// The status bar's style over a strip of [color]: black or white icons, whichever has
/// the higher contrast ratio against it (the brand's pink, which Material rates as dark,
/// takes dark icons). Only the status bar's fields are set, as an app bar sets them, so the
/// navigation bar keeps its own.
SystemUiOverlayStyle statusBarStyleOn(Color color) {
  final double luminance = color.computeLuminance();
  final bool darkIcons = (luminance + 0.05) / 0.05 > 1.05 / (luminance + 0.05);
  return SystemUiOverlayStyle(
    statusBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
    // iOS names the bar's background instead.
    statusBarBrightness: darkIcons ? Brightness.light : Brightness.dark,
  );
}
