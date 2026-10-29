/// The page an editor is on, for closing it once its awaited write has landed
/// (`app-core.md`, **Routing and the shell**).
///
/// go_router's `context.pop()` pops whatever page is on top when it is called, so an
/// editor that popped after an awaited write closed a page opened meanwhile instead of
/// itself. [OwnPage.of], taken before the write, captures the router and the editor's
/// page; [OwnPage.close] pops only while that page is still the router's top page, and
/// otherwise does nothing: the editor stays where it is (under the page pushed over it,
/// or on the tab the user left, whose stack only that tab can change), its write done.
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The page a widget is on, captured from its context.
final class OwnPage {
  /// The page [context] is on.
  OwnPage.of(BuildContext context)
    : _router = GoRouter.of(context),
      _page = GoRouterState.of(context).pageKey;

  final GoRouter _router;
  final ValueKey<String> _page;

  /// Whether the page is still the router's top page, the one the user sees.
  bool get isTop => _router.state.pageKey == _page;

  /// Closes the page while it is the top page; otherwise does nothing.
  void close() {
    if (isTop) _router.pop();
  }
}
