/// The segment control at the top of a tab with segments (`PlanScaffold`,
/// `InsightsScaffold`; `docs/reference/app-core.md`, **The segment switcher**): a
/// `SegmentedButton` of pills. When every label fits its share of the width (the usual
/// case at text scale 1, down to a 360 dp phone) the row fills the width and the segments
/// share it (`expandedInsets`); when one would not (a larger text size, a longer
/// translation) the row keeps its natural width and scrolls sideways, with a 16 dp fade at
/// the trailing edge while there is more past it, and opens scrolled to the segment shown.
library;

import 'dart:math' as math;

import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// The control's [segments] (each a value and its label), showing [selected].
class SegmentSwitcher<T extends Object> extends StatefulWidget {
  const SegmentSwitcher({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
  });

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  State<SegmentSwitcher<T>> createState() => _SegmentSwitcherState<T>();
}

class _SegmentSwitcherState<T extends Object>
    extends State<SegmentSwitcher<T>> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _selectedKey = GlobalKey();

  /// Whether more of the row lies past the trailing edge.
  bool _more = false;

  /// Whether the labels fitted at the last build; null before the first.
  bool? _fitted;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_measure);
  }

  /// Brings the segment shown into view once the scrolling row is laid out.
  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final BuildContext? selected = _selectedKey.currentContext;
    if (selected != null && _scroll.hasClients) {
      Scrollable.ensureVisible(selected, alignment: 0.5);
    }
    _measure();
  });

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _measure() {
    if (!_scroll.hasClients) return;
    final bool more = _scroll.position.extentAfter > 0;
    if (more != _more) setState(() => _more = more);
  }

  /// The widest label's width at the current text size, in the segments' style.
  double _widestLabel(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelLarge;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    double widest = 0;
    for (final (_, String label) in widget.segments) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textScaler: scaler,
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    return widest;
  }

  Widget _button({required bool expanded}) => SegmentedButton<T>(
    segments: [
      for (final (T value, String label) in widget.segments)
        ButtonSegment(
          value: value,
          label: Text(
            label,
            key: value == widget.selected ? _selectedKey : null,
            maxLines: 1,
          ),
        ),
    ],
    selected: {widget.selected},
    // The check would take width the labels need.
    showSelectedIcon: false,
    expandedInsets: expanded ? EdgeInsets.zero : null,
    onSelectionChanged: (selected) => widget.onSelected(selected.single),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const double sides = SpendthriftTokens.space16;
      final double width = constraints.maxWidth - 2 * sides;
      // A segment's natural width: its label, the theme's padding on both sides and the ink
      // line between segments, with a little room for rounding.
      final double segment =
          _widestLabel(context) +
          2 * SpendthriftTokens.space12 +
          2 * SpendthriftTokens.inkLine +
          2;
      final bool fits = segment * widget.segments.length <= width;
      // On the first build, and whenever the row turns from fitting to scrolling (the
      // text size changed while the screen is open), the segment shown is brought into
      // view.
      if (_fitted != fits) {
        _fitted = fits;
        if (!fits) _reveal();
      }
      const EdgeInsets padding = EdgeInsets.fromLTRB(
        sides,
        SpendthriftTokens.space8,
        sides,
        SpendthriftTokens.space8,
      );
      if (fits) {
        return Padding(padding: padding, child: _button(expanded: true));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _measure();
      });
      final Widget row = SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: _button(expanded: false),
      );
      // A fade at the trailing edge while there is more past it, so a cut label reads
      // as more to come. Always a mask, so the scroll view keeps its place in the tree;
      // with nothing past the edge it leaves the row as it is (`BlendMode.dst`).
      final bool rtl = Directionality.of(context) == TextDirection.rtl;
      return ShaderMask(
        blendMode: _more ? BlendMode.dstIn : BlendMode.dst,
        shaderCallback: (bounds) {
          final double stop = 1 - sides / bounds.width;
          return LinearGradient(
            begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
            end: rtl ? Alignment.centerLeft : Alignment.centerRight,
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [0, stop, 1],
          ).createShader(bounds);
        },
        child: row,
      );
    },
  );
}
