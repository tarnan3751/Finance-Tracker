/// The typed routes (go_router_builder): a stateful shell with one branch per tab, each
/// branch keeping its own navigation stack.
///
/// | Tab | Paths |
/// |---|---|
/// | Accounts | `/accounts`, `/accounts/new`, `/accounts/linked-banks`, `/accounts/:id`, `/accounts/:id/edit` |
/// | Transactions | `/transactions`, `/transactions/new?account=<id>`, `/transactions/duplicates`, `/transactions/:id` |
/// | Plan | `/plan` (redirects to `/budgets`); `/budgets`, `/budgets/new`, `/budgets/:id`, `/budgets/:id/transactions`; `/bills`, `/bills/new`, `/bills/:id`; `/forecast` |
/// | Settings | `/settings`, `/settings/categories`, `/settings/categories/new`, `/settings/categories/:id`, `/settings/rules`, `/settings/rules/new`, `/settings/rules/:id` |
///
/// Outside the shell, `/sign-in` and `/register` are the auth screens, where a signed-out
/// user is sent in dev and prod. `/` redirects to `/accounts` (`app_router.dart`). Detail and editor routes are
/// sub-routes of their branch, so each tab keeps its own stack; pushing a route of another
/// branch (a transaction from an account's detail, category management from the category
/// picker) opens it on top of the current tab's stack, and back returns there. Navigate
/// with the route classes, for example `const SettingsRoute().go(context)`, never with
/// path strings.
///
/// The Plan tab's branch has three roots, one per segment (`/budgets`, `/bills`,
/// `/forecast`), each a `PlanScaffold` (`plan_scaffold.dart`) built without a page
/// transition; `/plan` comes first, so the tab opens on Budgets and returns there when
/// tapped again.
library;

import 'package:finance_tracker/core/router/app_shell.dart';
import 'package:finance_tracker/core/router/plan_scaffold.dart';
import 'package:finance_tracker/features/accounts/presentation/account_detail_screen.dart';
import 'package:finance_tracker/features/accounts/presentation/account_editor_screen.dart';
import 'package:finance_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:finance_tracker/features/auth/presentation/register_screen.dart';
import 'package:finance_tracker/features/auth/presentation/sign_in_screen.dart';
import 'package:finance_tracker/features/bills/presentation/bill_editor_screen.dart';
import 'package:finance_tracker/features/bills/presentation/bills_screen.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_detail_screen.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_editor_screen.dart';
import 'package:finance_tracker/features/budgets/presentation/budgets_screen.dart';
import 'package:finance_tracker/features/categories/presentation/categories_screen.dart';
import 'package:finance_tracker/features/categories/presentation/category_editor_screen.dart';
import 'package:finance_tracker/features/duplicates/presentation/duplicate_review_screen.dart';
import 'package:finance_tracker/features/items/presentation/items_screen.dart';
import 'package:finance_tracker/features/rules/presentation/rule_editor_screen.dart';
import 'package:finance_tracker/features/rules/presentation/rules_screen.dart';
import 'package:finance_tracker/features/settings/presentation/settings_screen.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart';
import 'package:finance_tracker/features/transactions/presentation/transactions_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'routes.g.dart';

/// The shell around the four tabs.
@TypedStatefulShellRoute<AppShellRoute>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<AccountsBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<AccountsRoute>(
          path: '/accounts',
          routes: <TypedRoute<RouteData>>[
            // Before `:id`, so neither is read as an account id.
            TypedGoRoute<NewAccountRoute>(path: 'new'),
            TypedGoRoute<ItemsRoute>(path: 'linked-banks'),
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
            // Before `:id`, so neither is read as a transaction id.
            TypedGoRoute<NewTransactionRoute>(path: 'new'),
            TypedGoRoute<DuplicatesRoute>(path: 'duplicates'),
            TypedGoRoute<TransactionRoute>(path: ':id'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<PlanBranch>(
      routes: <TypedRoute<RouteData>>[
        // First, so it is the branch's first location: the tab opens on Budgets.
        TypedGoRoute<PlanRoute>(path: '/plan'),
        TypedGoRoute<BudgetsRoute>(
          path: '/budgets',
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<NewBudgetRoute>(path: 'new'),
            TypedGoRoute<EditBudgetRoute>(
              path: ':id',
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<BudgetTransactionsRoute>(path: 'transactions'),
              ],
            ),
          ],
        ),
        TypedGoRoute<BillsRoute>(
          path: '/bills',
          routes: <TypedRoute<RouteData>>[
            // Before `:id`, so it is not read as a bill id.
            TypedGoRoute<NewBillRoute>(path: 'new'),
            TypedGoRoute<EditBillRoute>(path: ':id'),
          ],
        ),
        TypedGoRoute<ForecastRoute>(path: '/forecast'),
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
            TypedGoRoute<RulesRoute>(
              path: 'rules',
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<NewRuleRoute>(path: 'new'),
                TypedGoRoute<EditRuleRoute>(path: ':id'),
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

/// The Plan tab's branch: budgets, bills and the forecast.
class PlanBranch extends StatefulShellBranchData {
  const PlanBranch();
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

/// `/accounts/linked-banks`: the linked banks, opened from the Accounts app bar and from
/// Settings.
class ItemsRoute extends GoRouteData with $ItemsRoute {
  const ItemsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ItemsScreen();
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

/// `/transactions/duplicates`: the review of the likely duplicate transactions.
class DuplicatesRoute extends GoRouteData with $DuplicatesRoute {
  const DuplicatesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DuplicateReviewScreen();
}

/// `/transactions/:id`: an existing transaction, in the editor that is also its detail.
class TransactionRoute extends GoRouteData with $TransactionRoute {
  const TransactionRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TransactionEditorScreen(transactionId: id);
}

/// `/plan`: the Plan tab, which opens on its Budgets segment.
class PlanRoute extends GoRouteData with $PlanRoute {
  const PlanRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      const BudgetsRoute().location;
}

/// `/budgets`: the Plan tab's Budgets segment, the budgets of the selected period.
class BudgetsRoute extends GoRouteData with $BudgetsRoute {
  const BudgetsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: BudgetsScreen());
}

/// `/budgets/new`: the editor of a new budget.
class NewBudgetRoute extends GoRouteData with $NewBudgetRoute {
  const NewBudgetRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BudgetEditorScreen();
}

/// `/budgets/:id`: the editor of an existing budget.
class EditBudgetRoute extends GoRouteData with $EditBudgetRoute {
  const EditBudgetRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      BudgetEditorScreen(budgetId: id);
}

/// `/budgets/:id/transactions`: what a budget counts in the selected period.
class BudgetTransactionsRoute extends GoRouteData
    with $BudgetTransactionsRoute {
  const BudgetTransactionsRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      BudgetDetailScreen(budgetId: id);
}

/// `/bills`: the Plan tab's Bills segment, the bills with their status.
class BillsRoute extends GoRouteData with $BillsRoute {
  const BillsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: BillsScreen());
}

/// `/bills/new`: the editor of a new bill.
class NewBillRoute extends GoRouteData with $NewBillRoute {
  const NewBillRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BillEditorScreen();
}

/// `/bills/:id`: the editor of an existing bill, where a reminder's tap opens it.
class EditBillRoute extends GoRouteData with $EditBillRoute {
  const EditBillRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      BillEditorScreen(billId: id);
}

/// `/forecast`: the Plan tab's Forecast segment.
class ForecastRoute extends GoRouteData with $ForecastRoute {
  const ForecastRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      NoTransitionPage(
        child: PlanScaffold(
          segment: PlanSegment.forecast,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context).planForecastPending,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
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

/// `/settings/rules`: the rules, in the order they are tried.
class RulesRoute extends GoRouteData with $RulesRoute {
  const RulesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RulesScreen();
}

/// `/settings/rules/new`: the editor of a new rule.
class NewRuleRoute extends GoRouteData with $NewRuleRoute {
  const NewRuleRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RuleEditorScreen();
}

/// `/settings/rules/:id`: the editor of an existing rule.
class EditRuleRoute extends GoRouteData with $EditRuleRoute {
  const EditRuleRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      RuleEditorScreen(ruleId: id);
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
