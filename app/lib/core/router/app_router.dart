/// The app's `GoRouter`, built from the typed routes in `routes.dart`.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// The router the app runs on, created once and disposed with the container.
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final GoRouter router = createRouter();
  ref.onDispose(router.dispose);
  return router;
}

/// A router over the app's routes, opening at [initialLocation] (the Accounts tab by
/// default). `/` redirects to `/accounts`.
GoRouter createRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? const AccountsRoute().location,
  routes: $appRoutes,
  redirect: _redirectRoot,
);

String? _redirectRoot(BuildContext context, GoRouterState state) =>
    state.uri.path == '/' ? const AccountsRoute().location : null;
