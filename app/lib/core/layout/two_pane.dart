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
library;

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

/// [start] and [end] side by side, [start] taking two fifths of the width within
/// [minStartWidth] and [maxStartWidth], a divider between them.
class TwoPane extends StatelessWidget {
  const TwoPane({super.key, required this.start, required this.end});

  /// The narrowest the start pane gets.
  static const double minStartWidth = 320;

  /// The widest the start pane gets.
  static const double maxStartWidth = 440;

  /// The list.
  final Widget start;

  /// The detail.
  final Widget end;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double startWidth = (constraints.maxWidth * 0.4).clamp(
          minStartWidth,
          maxStartWidth,
        );
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
            const VerticalDivider(width: 1),
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
