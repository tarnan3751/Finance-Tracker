/// The typed routes (go_router_builder): a stateful shell with one branch per tab, each
/// branch keeping its own navigation stack.
///
/// | Tab | Paths |
/// |---|---|
/// | Accounts | `/accounts`, `/accounts/new`, `/accounts/:id`, `/accounts/:id/edit` |
/// | Transactions | `/transactions` |
/// | Settings | `/settings`, `/settings/categories`, `/settings/categories/new`, `/settings/categories/:id` |
///
/// `/` redirects to `/accounts` (`app_router.dart`). Detail and editor routes are
/// sub-routes of their branch, so each tab keeps its own stack. Navigate with the route
/// classes, for example `const SettingsRoute().go(context)`, never with path strings.
library;

import 'package:finance_tracker/core/router/app_shell.dart';
import 'package:finance_tracker/features/accounts/presentation/account_detail_screen.dart';
import 'package:finance_tracker/features/accounts/presentation/account_editor_screen.dart';
import 'package:finance_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:finance_tracker/features/categories/presentation/categories_screen.dart';
import 'package:finance_tracker/features/categories/presentation/category_editor_screen.dart';
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
        TypedGoRoute<AccountsRoute>(
          path: '/accounts',
          routes: <TypedRoute<RouteData>>[
            // Before `:id`, so `/accounts/new` is not read as an account id.
            TypedGoRoute<NewAccountRoute>(path: 'new'),
            TypedGoRoute<AccountDetailRoute>(
              path: ':id',
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<EditAccountRoute>(path: 'edit'),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<TransactionsBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<TransactionsRoute>(path: '/transactions'),
      ],
    ),
    TypedStatefulShellBranch<SettingsBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SettingsRoute>(
          path: '/settings',
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<CategoriesRoute>(
              path: 'categories',
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<NewCategoryRoute>(path: 'new'),
                TypedGoRoute<EditCategoryRoute>(path: ':id'),
              ],
            ),
          ],
        ),
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

/// `/accounts/new`: the editor of a new account.
class NewAccountRoute extends GoRouteData with $NewAccountRoute {
  const NewAccountRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AccountEditorScreen();
}

/// `/accounts/:id`: an account's detail, with its transactions and running balance.
class AccountDetailRoute extends GoRouteData with $AccountDetailRoute {
  const AccountDetailRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AccountDetailScreen(accountId: id);
}

/// `/accounts/:id/edit`: the editor of an existing account.
class EditAccountRoute extends GoRouteData with $EditAccountRoute {
  const EditAccountRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AccountEditorScreen(accountId: id);
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

/// `/settings/categories`: the category hierarchy.
class CategoriesRoute extends GoRouteData with $CategoriesRoute {
  const CategoriesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CategoriesScreen();
}

/// `/settings/categories/new`: the editor of a new category.
class NewCategoryRoute extends GoRouteData with $NewCategoryRoute {
  const NewCategoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CategoryEditorScreen();
}

/// `/settings/categories/:id`: the editor of an existing category.
class EditCategoryRoute extends GoRouteData with $EditCategoryRoute {
  const EditCategoryRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CategoryEditorScreen(categoryId: id);
}
