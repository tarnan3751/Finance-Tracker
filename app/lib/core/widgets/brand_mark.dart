/// The brand's mark and wordmark (`docs/reference/design.md`, **The mark and the
/// wordmark**), as the brand board prints them: [BrandMark] is the duotone S of the
/// launcher icon (`res/drawable/ic_launcher_foreground.xml`), two stroked copies of one
/// path, the blue over the pink slipped off register, drawn with a `CustomPaint`;
/// [Wordmark] is the app's name in Syne 800 in the blue, over its pink copy offset down
/// and to the end. Both are decorative copies only where they double: the wordmark reads
/// its name once.
library;

import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// The duotone S, [size] logical pixels square. Decorative.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(
        blue: Theme.of(context).colorScheme.primary,
        pink: FinanceColors.of(context).accent,
      ),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.blue, required this.pink});

  final Color blue;
  final Color pink;

  /// The launcher icon's S, in its 108-unit viewport.
  static Path _s() => Path()
    ..moveTo(66, 38)
    ..cubicTo(63, 33, 58, 32, 54, 32)
    ..cubicTo(47, 32, 42, 36, 42, 42)
    ..cubicTo(42, 48, 48, 51, 54, 53)
    ..cubicTo(61, 55, 67, 58, 67, 65)
    ..cubicTo(67, 72, 61, 76, 54, 76)
    ..cubicTo(49, 76, 44, 74, 41, 69);

  /// The square of the viewport the two copies and their strokes fit in.
  static const double _from = 25;
  static const double _extent = 58;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / _extent;
    canvas
      ..save()
      ..scale(scale)
      ..translate(-_from, -_from);
    final Path s = _s();
    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas
      ..drawPath(
        s.shift(const Offset(-3, -3)),
        stroke(blue.withValues(alpha: 0.82)),
      )
      ..drawPath(
        s.shift(const Offset(3, 3)),
        stroke(pink.withValues(alpha: 0.92)),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.blue != blue || old.pink != pink;
}

/// [name] as the wordmark: Syne 800 in the blue over its pink copy, at the theme's
/// `displaySmall` size; read once, as a heading.
class Wordmark extends StatelessWidget {
  const Wordmark(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle style = (theme.textTheme.displaySmall ?? const TextStyle())
        .copyWith(
          fontFamily: AppTheme.headingFont,
          fontWeight: FontWeight.w800,
        );
    const double d = SpendthriftTokens.iconMisregistration;
    return Semantics(
      header: true,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: d, top: d),
            child: ExcludeSemantics(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: style.copyWith(color: FinanceColors.of(context).accent),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: d, bottom: d),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: style.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
