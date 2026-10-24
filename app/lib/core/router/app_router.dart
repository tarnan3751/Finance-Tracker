/// The app's `GoRouter`, built from the typed routes in `routes.dart`, with the session
/// gate of dev and prod.
///
/// - `/` redirects to `/accounts`.
/// - In dev and prod a signed-out user is sent to `/sign-in` (or stays on `/register`),
///   and a signed-in user on either auth screen is sent to `/accounts`. The router
///   follows the session through `refreshListenable`, so a sign-in, a sign-out or a
///   session the server ends moves the app at once. While the session is still unknown
///   (only before `bootstrap` has read it), nothing is redirected.
/// - The demo flavor has no gate: it is always signed in as the demo user.
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// The router the app runs on, created once and disposed with the container.
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) => routerFor(ref);

/// The router for [ref]'s flavor, opening at [initialLocation]: gated on
/// `sessionControllerProvider` in dev and prod, ungated in demo. Disposed with [ref].
GoRouter routerFor(Ref ref, {String? initialLocation}) {
  ValueNotifier<SessionState>? session;
  if (ref.watch(appConfigProvider).flavor != Flavor.demo) {
    final ValueNotifier<SessionState> notifier = ValueNotifier(
      ref.read(sessionControllerProvider),
    );
    ref
      ..listen(sessionControllerProvider, (_, next) => notifier.value = next)
      ..onDispose(notifier.dispose);
    session = notifier;
  }
  final GoRouter router = createRouter(
    initialLocation: initialLocation,
    session: session,
  );
  ref.onDispose(router.dispose);
  return router;
}

/// A router over the app's routes, opening at [initialLocation] (the Accounts tab by
/// default), gated on [session] when given.
GoRouter createRouter({
  String? initialLocation,
  ValueListenable<SessionState>? session,
}) => GoRouter(
  initialLocation: initialLocation ?? const AccountsRoute().location,
  routes: $appRoutes,
  refreshListenable: session,
  redirect: (context, state) => redirectFor(state.uri.path, session?.value),
);

const Set<String> _authPaths = {'/sign-in', '/register'};

/// Where [path] redirects for [session] (null: no gate), or null to stay.
@visibleForTesting
String? redirectFor(String path, SessionState? session) {
  final String home = const AccountsRoute().location;
  return switch (session) {
    SignedOut() =>
      _authPaths.contains(path) ? null : const SignInRoute().location,
    SignedIn() when _authPaths.contains(path) => home,
    _ => path == '/' ? home : null,
  };
}
