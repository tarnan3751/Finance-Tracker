/// The corner banner naming the flavor (DEV, DEMO) over the whole app.
///
/// The banner is drawn below the status bar: it is laid out inside the top system
/// padding, so its text is never under the status bar, while the app itself still draws
/// edge to edge behind it. It ignores pointers and is excluded from semantics.
library;

import 'package:flutter/material.dart';

/// Draws [message] in a corner banner over [child].
class FlavorBanner extends StatelessWidget {
  const FlavorBanner({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: SafeArea(
                bottom: false,
                child: Banner(
                  message: message,
                  location: BannerLocation.topEnd,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
