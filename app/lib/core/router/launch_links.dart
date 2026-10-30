/// The app's launch links (`docs/reference/app-core.md`, **Launch links**): the
/// `financetracker://` links a home screen widget's tap opens, and the router location
/// each one opens at. A link the app does not know opens nothing.
///
/// | Link | Location |
/// |---|---|
/// | `financetracker://accounts` | `/accounts` |
/// | `financetracker://insights/net-worth` | `/net-worth` |
/// | `financetracker://plan/budgets` | `/budgets` |
/// | `financetracker://plan/budgets/<id>` | `/budgets/<id>/transactions`, the budget's detail |
/// | `financetracker://plan/bills` | `/bills` |
/// | `financetracker://plan/bills/<id>` | `/bills/<id>` |
library;

import 'package:finance_tracker/core/router/routes.dart';

/// The scheme of every launch link.
const String launchScheme = 'financetracker';

/// Where a launch link opens: the router [location].
final class LaunchTarget {
  const LaunchTarget(this.location);

  final String location;

  @override
  bool operator ==(Object other) =>
      other is LaunchTarget && other.location == location;

  @override
  int get hashCode => location.hashCode;
}

/// Where [link] opens, or null when it is not a launch link the app knows.
LaunchTarget? launchTargetOf(Uri link) {
  if (link.scheme != launchScheme) return null;
  final List<String> path = [
    link.host,
    ...link.pathSegments,
  ].where((s) => s.isNotEmpty).toList();
  final String? location = switch (path) {
    ['accounts'] => const AccountsRoute().location,
    ['insights', 'net-worth'] => const NetWorthRoute().location,
    ['plan', 'budgets'] => const BudgetsRoute().location,
    ['plan', 'budgets', final String id] => BudgetTransactionsRoute(
      id,
    ).location,
    ['plan', 'bills'] => const BillsRoute().location,
    ['plan', 'bills', final String id] => EditBillRoute(id).location,
    _ => null,
  };
  return location == null ? null : LaunchTarget(location);
}
