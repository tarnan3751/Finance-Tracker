// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $appShellRoute,
  $signInRoute,
  $registerRoute,
];

RouteBase get $appShellRoute => StatefulShellRouteData.$route(
  navigatorContainerBuilder: AppShellRoute.$navigatorContainerBuilder,
  factory: $AppShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/accounts',
          hasOverriddenOnExit: false,
          factory: $AccountsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              hasOverriddenOnExit: false,
              factory: $NewAccountRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'linked-banks',
              hasOverriddenOnExit: false,
              factory: $ItemsRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':id',
              hasOverriddenOnExit: false,
              factory: $AccountDetailRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'edit',
                  hasOverriddenOnExit: false,
                  factory: $EditAccountRoute._fromState,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/transactions',
          hasOverriddenOnExit: false,
          factory: $TransactionsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              hasOverriddenOnExit: false,
              factory: $NewTransactionRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'duplicates',
              hasOverriddenOnExit: false,
              factory: $DuplicatesRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':id',
              hasOverriddenOnExit: false,
              factory: $TransactionRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/plan',
          hasOverriddenOnExit: false,
          factory: $PlanRoute._fromState,
        ),
        GoRouteData.$route(
          path: '/budgets',
          hasOverriddenOnExit: false,
          factory: $BudgetsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              hasOverriddenOnExit: false,
              factory: $NewBudgetRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':id',
              hasOverriddenOnExit: false,
              factory: $EditBudgetRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'transactions',
                  hasOverriddenOnExit: false,
                  factory: $BudgetTransactionsRoute._fromState,
                ),
              ],
            ),
          ],
        ),
        GoRouteData.$route(
          path: '/bills',
          hasOverriddenOnExit: false,
          factory: $BillsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              hasOverriddenOnExit: false,
              factory: $NewBillRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'subscriptions',
              hasOverriddenOnExit: false,
              factory: $SubscriptionsRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':id',
              hasOverriddenOnExit: false,
              factory: $EditBillRoute._fromState,
            ),
          ],
        ),
        GoRouteData.$route(
          path: '/forecast',
          hasOverriddenOnExit: false,
          factory: $ForecastRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/insights',
          hasOverriddenOnExit: false,
          factory: $InsightsRoute._fromState,
        ),
        GoRouteData.$route(
          path: '/reports',
          hasOverriddenOnExit: false,
          factory: $ReportsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'weekly',
              hasOverriddenOnExit: false,
              factory: $WeeklySummaryRoute._fromState,
            ),
          ],
        ),
        GoRouteData.$route(
          path: '/net-worth',
          hasOverriddenOnExit: false,
          factory: $NetWorthRoute._fromState,
        ),
        GoRouteData.$route(
          path: '/investments',
          hasOverriddenOnExit: false,
          factory: $InvestmentsRoute._fromState,
        ),
        GoRouteData.$route(
          path: '/goals',
          hasOverriddenOnExit: false,
          factory: $GoalsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              hasOverriddenOnExit: false,
              factory: $NewGoalRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':id',
              hasOverriddenOnExit: false,
              factory: $GoalDetailRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'edit',
                  hasOverriddenOnExit: false,
                  factory: $EditGoalRoute._fromState,
                ),
                GoRouteData.$route(
                  path: 'contribute',
                  hasOverriddenOnExit: false,
                  factory: $NewContributionRoute._fromState,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/settings',
          hasOverriddenOnExit: false,
          factory: $SettingsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'categories',
              hasOverriddenOnExit: false,
              factory: $CategoriesRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'new',
                  hasOverriddenOnExit: false,
                  factory: $NewCategoryRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':id',
                  hasOverriddenOnExit: false,
                  factory: $EditCategoryRoute._fromState,
                ),
              ],
            ),
            GoRouteData.$route(
              path: 'rules',
              hasOverriddenOnExit: false,
              factory: $RulesRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'new',
                  hasOverriddenOnExit: false,
                  factory: $NewRuleRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':id',
                  hasOverriddenOnExit: false,
                  factory: $EditRuleRoute._fromState,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $AccountsRoute on GoRouteData {
  static AccountsRoute _fromState(GoRouterState state) => const AccountsRoute();

  @override
  String get location => GoRouteData.$location('/accounts');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NewAccountRoute on GoRouteData {
  static NewAccountRoute _fromState(GoRouterState state) =>
      const NewAccountRoute();

  @override
  String get location => GoRouteData.$location('/accounts/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ItemsRoute on GoRouteData {
  static ItemsRoute _fromState(GoRouterState state) => const ItemsRoute();

  @override
  String get location => GoRouteData.$location('/accounts/linked-banks');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountDetailRoute on GoRouteData {
  static AccountDetailRoute _fromState(GoRouterState state) =>
      AccountDetailRoute(state.pathParameters['id']!);

  AccountDetailRoute get _self => this as AccountDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/accounts/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $EditAccountRoute on GoRouteData {
  static EditAccountRoute _fromState(GoRouterState state) =>
      EditAccountRoute(state.pathParameters['id']!);

  EditAccountRoute get _self => this as EditAccountRoute;

  @override
  String get location =>
      GoRouteData.$location('/accounts/${Uri.encodeComponent(_self.id)}/edit');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $TransactionsRoute on GoRouteData {
  static TransactionsRoute _fromState(GoRouterState state) =>
      const TransactionsRoute();

  @override
  String get location => GoRouteData.$location('/transactions');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NewTransactionRoute on GoRouteData {
  static NewTransactionRoute _fromState(GoRouterState state) =>
      NewTransactionRoute(account: state.uri.queryParameters['account']);

  NewTransactionRoute get _self => this as NewTransactionRoute;

  @override
  String get location => GoRouteData.$location(
    '/transactions/new',
    queryParams: {if (_self.account != null) 'account': _self.account},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DuplicatesRoute on GoRouteData {
  static DuplicatesRoute _fromState(GoRouterState state) =>
      const DuplicatesRoute();

  @override
  String get location => GoRouteData.$location('/transactions/duplicates');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $TransactionRoute on GoRouteData {
  static TransactionRoute _fromState(GoRouterState state) =>
      TransactionRoute(state.pathParameters['id']!);

  TransactionRoute get _self => this as TransactionRoute;

  @override
  String get location =>
      GoRouteData.$location('/transactions/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PlanRoute on GoRouteData {
  static PlanRoute _fromState(GoRouterState state) => const PlanRoute();

  @override
  String get location => GoRouteData.$location('/plan');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BudgetsRoute on GoRouteData {
  static BudgetsRoute _fromState(GoRouterState state) => const BudgetsRoute();

  @override
  String get location => GoRouteData.$location('/budgets');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NewBudgetRoute on GoRouteData {
  static NewBudgetRoute _fromState(GoRouterState state) =>
      const NewBudgetRoute();

  @override
  String get location => GoRouteData.$location('/budgets/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $EditBudgetRoute on GoRouteData {
  static EditBudgetRoute _fromState(GoRouterState state) =>
      EditBudgetRoute(state.pathParameters['id']!);

  EditBudgetRoute get _self => this as EditBudgetRoute;

  @override
  String get location =>
      GoRouteData.$location('/budgets/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BudgetTransactionsRoute on GoRouteData {
  static BudgetTransactionsRoute _fromState(GoRouterState state) =>
      BudgetTransactionsRoute(state.pathParameters['id']!);

  BudgetTransactionsRoute get _self => this as BudgetTransactionsRoute;

  @override
  String get location => GoRouteData.$location(
    '/budgets/${Uri.encodeComponent(_self.id)}/transactions',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BillsRoute on GoRouteData {
  static BillsRoute _fromState(GoRouterState state) => const BillsRoute();

  @override
  String get location => GoRouteData.$location('/bills');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NewBillRoute on GoRouteData {
  static NewBillRoute _fromState(GoRouterState state) => NewBillRoute(
    streamId: state.uri.queryParameters['stream-id'],
    liabilityAccountId: state.uri.queryParameters['liability-account-id'],
  );

  NewBillRoute get _self => this as NewBillRoute;

  @override
  String get location => GoRouteData.$location(
    '/bills/new',
    queryParams: {
      if (_self.streamId != null) 'stream-id': _self.streamId,
      if (_self.liabilityAccountId != null)
        'liability-account-id': _self.liabilityAccountId,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SubscriptionsRoute on GoRouteData {
  static SubscriptionsRoute _fromState(GoRouterState state) =>
      const SubscriptionsRoute();

  @override
  String get location => GoRouteData.$location('/bills/subscriptions');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $EditBillRoute on GoRouteData {
  static EditBillRoute _fromState(GoRouterState state) =>
      EditBillRoute(state.pathParameters['id']!);

  EditBillRoute get _self => this as EditBillRoute;

  @override
  String get location =>
      GoRouteData.$location('/bills/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ForecastRoute on GoRouteData {
  static ForecastRoute _fromState(GoRouterState state) => const ForecastRoute();

  @override
  String get location => GoRouteData.$location('/forecast');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $InsightsRoute on GoRouteData {
  static InsightsRoute _fromState(GoRouterState state) => const InsightsRoute();

  @override
  String get location => GoRouteData.$location('/insights');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ReportsRoute on GoRouteData {
  static ReportsRoute _fromState(GoRouterState state) => const ReportsRoute();

  @override
  String get location => GoRouteData.$location('/reports');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $WeeklySummaryRoute on GoRouteData {
  static WeeklySummaryRoute _fromState(GoRouterState state) =>
      const WeeklySummaryRoute();

  @override
  String get location => GoRouteData.$location('/reports/weekly');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NetWorthRoute on GoRouteData {
  static NetWorthRoute _fromState(GoRouterState state) => const NetWorthRoute();

  @override
  String get location => GoRouteData.$location('/net-worth');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $InvestmentsRoute on GoRouteData {
  static InvestmentsRoute _fromState(GoRouterState state) =>
      const InvestmentsRoute();

  @override
  String get location => GoRouteData.$location('/investments');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $GoalsRoute on GoRouteData {
  static GoalsRoute _fromState(GoRouterState state) => const GoalsRoute();

  @override
  String get location => GoRouteData.$location('/goals');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NewGoalRoute on GoRouteData {
  static NewGoalRoute _fromState(GoRouterState state) => const NewGoalRoute();

  @override
  String get location => GoRouteData.$location('/goals/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $GoalDetailRoute on GoRouteData {
  static GoalDetailRoute _fromState(GoRouterState state) =>
      GoalDetailRoute(state.pathParameters['id']!);

  GoalDetailRoute get _self => this as GoalDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/goals/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $EditGoalRoute on GoRouteData {
  static EditGoalRoute _fromState(GoRouterState state) =>
      EditGoalRoute(state.pathParameters['id']!);

  EditGoalRoute get _self => this as EditGoalRoute;

  @override
  String get location =>
      GoRouteData.$location('/goals/${Uri.encodeComponent(_self.id)}/edit');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NewContributionRoute on GoRouteData {
  static NewContributionRoute _fromState(GoRouterState state) =>
      NewContributionRoute(state.pathParameters['id']!);

  NewContributionRoute get _self => this as NewContributionRoute;

  @override
  String get location => GoRouteData.$location(
    '/goals/${Uri.encodeComponent(_self.id)}/contribute',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CategoriesRoute on GoRouteData {
  static CategoriesRoute _fromState(GoRouterState state) =>
      const CategoriesRoute();

  @override
  String get location => GoRouteData.$location('/settings/categories');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NewCategoryRoute on GoRouteData {
  static NewCategoryRoute _fromState(GoRouterState state) =>
      const NewCategoryRoute();

  @override
  String get location => GoRouteData.$location('/settings/categories/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $EditCategoryRoute on GoRouteData {
  static EditCategoryRoute _fromState(GoRouterState state) =>
      EditCategoryRoute(state.pathParameters['id']!);

  EditCategoryRoute get _self => this as EditCategoryRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/categories/${Uri.encodeComponent(_self.id)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RulesRoute on GoRouteData {
  static RulesRoute _fromState(GoRouterState state) => const RulesRoute();

  @override
  String get location => GoRouteData.$location('/settings/rules');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NewRuleRoute on GoRouteData {
  static NewRuleRoute _fromState(GoRouterState state) => const NewRuleRoute();

  @override
  String get location => GoRouteData.$location('/settings/rules/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $EditRuleRoute on GoRouteData {
  static EditRuleRoute _fromState(GoRouterState state) =>
      EditRuleRoute(state.pathParameters['id']!);

  EditRuleRoute get _self => this as EditRuleRoute;

  @override
  String get location =>
      GoRouteData.$location('/settings/rules/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $signInRoute => GoRouteData.$route(
  path: '/sign-in',
  hasOverriddenOnExit: false,
  factory: $SignInRoute._fromState,
);

mixin $SignInRoute on GoRouteData {
  static SignInRoute _fromState(GoRouterState state) => const SignInRoute();

  @override
  String get location => GoRouteData.$location('/sign-in');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $registerRoute => GoRouteData.$route(
  path: '/register',
  hasOverriddenOnExit: false,
  factory: $RegisterRoute._fromState,
);

mixin $RegisterRoute on GoRouteData {
  static RegisterRoute _fromState(GoRouterState state) => const RegisterRoute();

  @override
  String get location => GoRouteData.$location('/register');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
