/// The app's `GoRouter`, built from the typed routes in `routes.dart`, with the session
/// gate of dev and prod.
///
/// - `/` redirects to `/accounts`.
/// - In dev and prod a signed-out user is sent to `/sign-in` (or stays on `/register`),
///   and a signed-in user on either auth screen is sent to `/accounts`. The router
///   follows the session through `refreshListenable`, so a sign-in, a sign-out or a
///   session the server ends moves the app at once. While the session is still unknown
///   (only before `bootstrap` has read it), nothing is redirected.
/// - In dev and prod, while the restore offer is pending (`RestoreOffer`: signed in, an
///   empty database, the offer never answered), a signed-in user is held at `/restore`;
///   once it is answered, `/restore` is sent to `/accounts`.
/// - The demo flavor has no gate: it is always signed in as the demo user.
/// - A cold start at a launch link (a home screen widget's tap, `launch_links.dart`)
///   opens at its location ([LaunchLocation], set by `bootstrap` before the router is
///   built), behind the session gate and the lock like any other location; a link that
///   reaches the running app goes there ([openLaunchLink]).
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/launch_links.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// The router the app runs on, created once and disposed with the container, opening
/// at [LaunchLocation]'s location when the app was started at a launch link.
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) =>
    routerFor(ref, initialLocation: ref.read(launchLocationProvider));

/// The location of the launch link the app was started at, or null; read once, when the
/// router is built.
@Riverpod(keepAlive: true)
class LaunchLocation extends _$LaunchLocation {
  @override
  String? build() => null;

  /// Opens the router at [link]'s location, when it is a launch link the app knows.
  void startAt(Uri? link) =>
      state = link == null ? null : launchTargetOf(link)?.location;
}

/// Goes to [link]'s location in [router], when it is a launch link the app knows;
/// returns whether it did.
bool openLaunchLink(GoRouter router, Uri link) {
  final LaunchTarget? target = launchTargetOf(link);
  if (target == null) return false;
  router.go(target.location);
  return true;
}

/// The router for [ref]'s flavor, opening at [initialLocation]: gated on
/// `sessionControllerProvider` and `restoreOfferProvider` in dev and prod, ungated in
/// demo. Disposed with [ref].
GoRouter routerFor(Ref ref, {String? initialLocation}) {
  ValueNotifier<SessionState>? session;
  ValueNotifier<bool>? restoreOffer;
  if (ref.watch(appConfigProvider).flavor != Flavor.demo) {
    final ValueNotifier<SessionState> notifier = ValueNotifier(
      ref.read(sessionControllerProvider),
    );
    final ValueNotifier<bool> offer = ValueNotifier(
      ref.read(restoreOfferProvider).value ?? false,
    );
    ref
      ..listen(sessionControllerProvider, (_, next) => notifier.value = next)
      ..listen(
        restoreOfferProvider,
        (_, next) => offer.value = next.value ?? false,
      )
      ..onDispose(notifier.dispose)
      ..onDispose(offer.dispose);
    session = notifier;
    restoreOffer = offer;
  }
  final GoRouter router = createRouter(
    initialLocation: initialLocation,
    session: session,
    restoreOffer: restoreOffer,
  );
  ref.onDispose(router.dispose);
  return router;
}

/// A router over the app's routes, opening at [initialLocation] (the Accounts tab by
/// default), gated on [session] and [restoreOffer] when given.
GoRouter createRouter({
  String? initialLocation,
  ValueListenable<SessionState>? session,
  ValueListenable<bool>? restoreOffer,
}) => GoRouter(
  initialLocation: initialLocation ?? const AccountsRoute().location,
  routes: $appRoutes,
  refreshListenable: Listenable.merge([session, restoreOffer]),
  redirect: (context, state) => redirectFor(
    state.uri.path,
    session?.value,
    restoreOffer: restoreOffer?.value ?? false,
  ),
);

const Set<String> _authPaths = {'/sign-in', '/register'};

/// Where [path] redirects for [session] (null: no gate) and a pending [restoreOffer], or
/// null to stay.
@visibleForTesting
String? redirectFor(
  String path,
  SessionState? session, {
  bool restoreOffer = false,
}) {
  final String home = const AccountsRoute().location;
  final String offer = const RestoreOfferRoute().location;
  return switch (session) {
    SignedOut() =>
      _authPaths.contains(path) ? null : const SignInRoute().location,
    SignedIn() when restoreOffer => path == offer ? null : offer,
    SignedIn() when _authPaths.contains(path) || path == offer => home,
    _ => path == '/' ? home : null,
  };
}
