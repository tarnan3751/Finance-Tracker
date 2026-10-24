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
