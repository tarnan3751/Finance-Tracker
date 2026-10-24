/// The typed routes (go_router_builder): a stateful shell with one branch per tab, each
/// branch keeping its own navigation stack.
///
/// | Tab | Path |
/// |---|---|
/// | Accounts | `/accounts` |
/// | Transactions | `/transactions` |
/// | Settings | `/settings` |
///
/// `/` redirects to `/accounts` (`app_router.dart`). Detail and editor routes
/// (`/accounts/:id`, `/transactions/:id`, `/transactions/new`) arrive with Phase 1d as
/// sub-routes of their branch. Navigate with the route classes, for example
/// `const SettingsRoute().go(context)`, never with path strings.
library;

import 'package:finance_tracker/core/router/app_shell.dart';
import 'package:finance_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:finance_tracker/features/settings/presentation/settings_screen.dart';
import 'package:finance_tracker/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'routes.g.dart';

/// The shell around the three tabs.
@TypedStatefulShellRoute<AppShellRoute>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<AccountsBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<AccountsRoute>(path: '/accounts'),
      ],
    ),
    TypedStatefulShellBranch<TransactionsBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<TransactionsRoute>(path: '/transactions'),
      ],
    ),
    TypedStatefulShellBranch<SettingsBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SettingsRoute>(path: '/settings'),
      ],
    ),
  ],
)
class AppShellRoute extends StatefulShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => navigationShell;

  /// Lays the branch navigators out under the navigation bar.
  static Widget $navigatorContainerBuilder(
    BuildContext context,
    StatefulNavigationShell navigationShell,
    List<Widget> children,
  ) => AppShell(navigationShell: navigationShell, children: children);
}

/// The Accounts tab's branch.
class AccountsBranch extends StatefulShellBranchData {
  const AccountsBranch();
}

/// The Transactions tab's branch.
class TransactionsBranch extends StatefulShellBranchData {
  const TransactionsBranch();
}

/// The Settings tab's branch.
class SettingsBranch extends StatefulShellBranchData {
  const SettingsBranch();
}

/// `/accounts`: the account list.
class AccountsRoute extends GoRouteData with $AccountsRoute {
  const AccountsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AccountsScreen();
}

/// `/transactions`: the transaction list.
class TransactionsRoute extends GoRouteData with $TransactionsRoute {
  const TransactionsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const TransactionsScreen();
}

/// `/settings`: the settings screen.
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}
