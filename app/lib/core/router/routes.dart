/// The typed routes (go_router_builder): a stateful shell with one branch per tab, each
/// branch keeping its own navigation stack.
///
/// | Tab | Paths |
/// |---|---|
/// | Accounts | `/accounts`, `/accounts/new`, `/accounts/:id`, `/accounts/:id/edit` |
/// | Transactions | `/transactions`, `/transactions/new?account=<id>`, `/transactions/:id` |
/// | Settings | `/settings`, `/settings/categories`, `/settings/categories/new`, `/settings/categories/:id` |
///
/// Outside the shell, `/sign-in` and `/register` are the auth screens, where a signed-out
/// user is sent in dev and prod. `/` redirects to `/accounts` (`app_router.dart`). Detail and editor routes are
/// sub-routes of their branch, so each tab keeps its own stack; pushing a route of another
/// branch (a transaction from an account's detail, category management from the category
/// picker) opens it on top of the current tab's stack, and back returns there. Navigate
/// with the route classes, for example `const SettingsRoute().go(context)`, never with
/// path strings.
library;

import 'package:finance_tracker/core/router/app_shell.dart';
import 'package:finance_tracker/features/accounts/presentation/account_detail_screen.dart';
import 'package:finance_tracker/features/accounts/presentation/account_editor_screen.dart';
import 'package:finance_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:finance_tracker/features/auth/presentation/register_screen.dart';
import 'package:finance_tracker/features/auth/presentation/sign_in_screen.dart';
import 'package:finance_tracker/features/categories/presentation/categories_screen.dart';
import 'package:finance_tracker/features/categories/presentation/category_editor_screen.dart';
import 'package:finance_tracker/features/settings/presentation/settings_screen.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart';
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
        TypedGoRoute<TransactionsRoute>(
          path: '/transactions',
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<NewTransactionRoute>(path: 'new'),
            TypedGoRoute<TransactionRoute>(path: ':id'),
          ],
        ),
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

/// `/transactions/new`: the editor of a new transaction, on [account] when given.
class NewTransactionRoute extends GoRouteData with $NewTransactionRoute {
  const NewTransactionRoute({this.account});

  /// The id of the account the new transaction starts on.
  final String? account;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TransactionEditorScreen(initialAccountId: account);
}

/// `/transactions/:id`: an existing transaction, in the editor that is also its detail.
class TransactionRoute extends GoRouteData with $TransactionRoute {
  const TransactionRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TransactionEditorScreen(transactionId: id);
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

/// `/sign-in`: the sign-in screen, outside the shell.
@TypedGoRoute<SignInRoute>(path: '/sign-in')
class SignInRoute extends GoRouteData with $SignInRoute {
  const SignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SignInScreen();
}

/// `/register`: the registration screen, outside the shell.
@TypedGoRoute<RegisterRoute>(path: '/register')
class RegisterRoute extends GoRouteData with $RegisterRoute {
  const RegisterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RegisterScreen();
}
