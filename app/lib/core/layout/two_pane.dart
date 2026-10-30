/// A list beside its detail on an expanded window (`PLAN.md` §8, Phase 8).
///
/// The shell (`app_shell.dart`) shows the Accounts, Transactions and Settings tabs, and
/// the Plan tab on its Bills segment, as a [TwoPane] on an expanded window: the tab's
/// list in the start pane, outside the tab's navigator, and the navigator in the end
/// pane, where the tab's first page (`/accounts`, `/transactions`, `/bills`,
/// `/settings`) is a [DetailPlaceholder] ([ListPane] chooses) and every page pushed
/// over it (a detail, an editor, a sub-screen) opens beside the list. The URL stays the
/// source of truth: `/accounts/:id` is the list and the account side by side, and Back
/// closes the detail. On a compact or medium window the navigator alone fills the
/// tab, its first page is the list, and a detail is pushed over it.
///
/// A list opens its detail with [openDetail], which replaces the detail shown beside the
/// list instead of stacking a second one over it.
///
/// The list is one element whichever pane holds it: the shell and [ListPane] key it
/// with the same `GlobalKey` ([ListKeys]), so when the window changes class it moves
/// between the start pane and the navigator's first page with its state (its scroll,
/// its search field, its selection). The start pane has its own `ScaffoldMessenger`, so
/// a snack bar shows once, in the pane whose screen showed it.
///
/// On a foldable the panes split on the fold: when the window reports a vertical fold
/// or hinge ([verticalFold]) that is flat or half opened, the start pane ends where the
/// fold starts and the end pane starts where it ends, so no text sits across it; the
/// shell keeps its rail narrow then (`app_shell.dart`), so the list has the room left of
/// the fold. A folded foldable shows its outer display, a compact window, with no
/// fold and one pane. A horizontal fold (a foldable on its side, half open like a
/// laptop) leaves the panes as they are, side by side across it, and so does a fold
/// that would leave either pane narrower than [TwoPane.minFoldPaneWidth] (the rail's
/// labels at a large text size can take most of the room before it).
library;

import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Which pane of a [TwoPane] a widget is in.
enum PaneRole {
  /// The list's pane.
  start,

  /// The detail's pane.
  end,
}

/// The pane its descendants are in, set by [TwoPane].
class PaneScope extends InheritedWidget {
  const PaneScope({super.key, required this.role, required super.child});

  /// The pane.
  final PaneRole role;

  /// The pane [context] is in, or null when it is not in a [TwoPane].
  static PaneRole? roleOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaneScope>()?.role;

  @override
  bool updateShouldNotify(PaneScope oldWidget) => role != oldWidget.role;
}

/// The vertical fold or hinge of [context]'s window, flat or half opened, in window
/// coordinates, or null.
Rect? verticalFold(BuildContext context) {
  for (final DisplayFeature feature in MediaQuery.displayFeaturesOf(context)) {
    final bool separates =
        feature.type == DisplayFeatureType.fold ||
        feature.type == DisplayFeatureType.hinge;
    final bool open =
        feature.state == DisplayFeatureState.postureFlat ||
        feature.state == DisplayFeatureState.postureHalfOpened;
    if (separates && open && feature.bounds.height > feature.bounds.width) {
      return feature.bounds;
    }
  }
  return null;
}

/// [start] and [end] side by side: split on the window's [verticalFold] when it falls
/// inside the panes with room for a list on either side, else [start] taking two fifths of the width within
/// [minStartWidth] and [maxStartWidth], a divider between them.
///
/// Laid out flush with the window's end edge, as the shell's body is (the rail is at
/// the start), which places the fold in the panes' own coordinates.
class TwoPane extends StatelessWidget {
  const TwoPane({super.key, required this.start, required this.end});

  /// The narrowest room two panes are laid out in: a list and a detail of
  /// [minFoldPaneWidth]. The shell shows one pane in less.
  static const double minWidth = minStartWidth + minFoldPaneWidth;

  /// The narrowest the start pane gets.
  static const double minStartWidth = 320;

  /// The narrowest a pane split on a fold gets; a fold that would leave less keeps
  /// the usual split.
  static const double minFoldPaneWidth = 240;

  /// The widest the start pane gets.
  static const double maxStartWidth = 440;

  /// The list.
  final Widget start;

  /// The detail.
  final Widget end;

  @override
  Widget build(BuildContext context) {
    final Rect? fold = verticalFold(context);
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final TextDirection direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        double startWidth = (width * 0.4).clamp(minStartWidth, maxStartWidth);
        double gap = 1;
        if (fold != null) {
          // The fold's edges from the panes' start edge.
          final double origin = direction == TextDirection.ltr
              ? windowWidth - width
              : 0;
          final double left = fold.left - origin;
          final double right = fold.right - origin;
          final double before = direction == TextDirection.ltr
              ? left
              : width - right;
          final double after = width - before - (right - left);
          // Only where the fold leaves each pane room for a list: at a large text
          // size the rail's labels can take most of the room before the fold.
          if (before >= minFoldPaneWidth && after >= minFoldPaneWidth) {
            startWidth = before;
            gap = math.max(right - left, 1);
          }
        }
        return Row(
          children: [
            SizedBox(
              width: startWidth,
              // Each pane its own semantics container: the end pane's navigator
              // blocks the semantics of what is painted before it in its
              // container, which would hide the list from a screen reader.
              child: Semantics(
                container: true,
                child: PaneScope(
                  role: PaneRole.start,
                  // The list's floating button would share its hero tag with the
                  // detail's when a page on top of both comes and goes.
                  child: HeroMode(
                    enabled: false,
                    child: ScaffoldMessenger(child: start),
                  ),
                ),
              ),
            ),
            // On a fold the divider is as wide as the hinge, at least a line.
            VerticalDivider(width: gap),
            Expanded(
              child: Semantics(
                container: true,
                child: PaneScope(role: PaneRole.end, child: end),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The first page of a tab that shows its list beside its detail: [list] alone, or
/// [placeholder] in the end pane of a [TwoPane], where the list is beside it.
class ListPane extends StatelessWidget {
  const ListPane({super.key, required this.list, required this.placeholder});

  /// The list.
  final Widget list;

  /// What the end pane shows while no detail is open.
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    if (PaneScope.roleOf(context) == PaneRole.end) return placeholder;
    final ListKeys? keys = context.getInheritedWidgetOfExactType<ListKeys>();
    return keys == null ? list : keys.wrap(list);
  }
}

/// The `GlobalKey` of each list shown beside its detail, by the list's type, so the
/// shell's start pane and [ListPane] key the same list alike and it keeps its state
/// when it moves between them. Provided by the shell above its branches.
class ListKeys extends InheritedWidget {
  const ListKeys({super.key, required this.keys, required super.child});

  /// The keys, created as lists are first shown.
  final Map<Type, GlobalKey> keys;

  /// [list] under its key.
  Widget wrap(Widget list) => wrapIn(keys, list);

  /// [list] under its key in [keys], created when missing.
  static Widget wrapIn(Map<Type, GlobalKey> keys, Widget list) => KeyedSubtree(
    key: keys.putIfAbsent(list.runtimeType, GlobalKey.new),
    child: list,
  );

  @override
  bool updateShouldNotify(ListKeys oldWidget) => false;
}

/// The end pane while no detail is open: an icon and a line saying what to choose.
class DetailPlaceholder extends StatelessWidget {
  const DetailPlaceholder({super.key, required this.icon, required this.text});

  final IconData icon;

  /// What choosing in the list shows here.
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens [location] from the list [context] is in: in place of the page beside the
/// list when the list is in a [TwoPane]'s start pane, so Back closes it rather than
/// returning to the previous one; else pushed over the list. A page of another tab
/// (the linked banks from Settings) opens over this tab's list alone, so Back returns
/// to the list in this tab.
void openDetail(BuildContext context, String location) {
  final GoRouter router = GoRouter.of(context);
  final PaneScope? scope = context.getInheritedWidgetOfExactType<PaneScope>();
  if (scope?.role != PaneRole.start) {
    router.push<void>(location);
    return;
  }
  final String root = StatefulNavigationShell.of(context)
      .widget
      .shellRouteContext
      .match
      .matches
      .first
      .matchedLocation;
  if (location.startsWith('$root/')) {
    router.go(location);
  } else if (router.state.uri.path == root) {
    router.push<void>(location);
  } else {
    router.go(root);
    // Once: two activations in one frame schedule two pushes of the same page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (router.state.uri.path != Uri.parse(location).path) {
        router.push<void>(location);
      }
    });
  }
}
