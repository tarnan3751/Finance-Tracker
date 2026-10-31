/// The app's launch links (`docs/reference/app-core.md`, **Launch links**): the
/// `financetracker://` links a home screen widget's tap or an app shortcut opens, the
/// router location each one opens at, and the four app shortcuts ([appShortcutsFor]). A
/// link the app does not know opens nothing.
///
/// | Link | Location |
/// |---|---|
/// | `financetracker://accounts` | `/accounts` |
/// | `financetracker://insights/net-worth` | `/net-worth` |
/// | `financetracker://plan/budgets` | `/budgets` |
/// | `financetracker://plan/budgets/<id>` | `/budgets/<id>/transactions`, the budget's detail |
/// | `financetracker://plan/bills` | `/bills` |
/// | `financetracker://plan/bills/<id>` | `/bills/<id>` |
/// | `financetracker://transactions/new` | `/transactions/new` |
/// | `financetracker://transactions/new?receipt=camera` | `/transactions/new?receipt=camera`, the camera opened for the receipt |
/// | `financetracker://search` | `/transactions?search=true`, searching |
/// | `financetracker://sync` | `/settings`, with a sync session started ([LaunchTarget.syncs]) |
library;

import 'package:finance_tracker/core/platform/app_shortcuts.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';

/// The scheme of every launch link.
const String launchScheme = 'financetracker';

/// Where a launch link opens: the router [location], and whether it asks for a sync
/// session ([syncs]: Settings shows the Sync section first in dev and prod; the demo,
/// which never syncs, just opens Settings).
final class LaunchTarget {
  const LaunchTarget(this.location, {this.syncs = false});

  final String location;
  final bool syncs;

  @override
  bool operator ==(Object other) =>
      other is LaunchTarget &&
      other.location == location &&
      other.syncs == syncs;

  @override
  int get hashCode => Object.hash(location, syncs);
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
    ['transactions', 'new'] => NewTransactionRoute(
      receipt:
          link.queryParameters['receipt'] == NewTransactionRoute.receiptCamera
          ? NewTransactionRoute.receiptCamera
          : null,
    ).location,
    ['search'] => const TransactionsRoute(search: true).location,
    ['sync'] => const SettingsRoute().location,
    _ => null,
  };
  if (location == null) return null;
  return LaunchTarget(
    location,
    syncs: path.length == 1 && path.single == 'sync',
  );
}

/// The link of Add transaction.
final Uri addTransactionLink = Uri.parse('$launchScheme://transactions/new');

/// The link of Scan receipt.
final Uri scanReceiptLink = Uri.parse(
  '$launchScheme://transactions/new?receipt=${NewTransactionRoute.receiptCamera}',
);

/// The link of Search transactions.
final Uri searchLink = Uri.parse('$launchScheme://search');

/// The link of Sync now.
final Uri syncLink = Uri.parse('$launchScheme://sync');

/// The four app shortcuts, titled in [l10n], each icon an adaptive icon resource
/// (`res/drawable/ic_shortcut_*.xml`), in every flavor.
List<AppShortcut> appShortcutsFor(AppLocalizations l10n) => [
  AppShortcut(
    link: addTransactionLink,
    title: l10n.shortcutAddTransaction,
    icon: 'ic_shortcut_add',
  ),
  AppShortcut(
    link: scanReceiptLink,
    title: l10n.shortcutScanReceipt,
    icon: 'ic_shortcut_receipt',
  ),
  AppShortcut(
    link: searchLink,
    title: l10n.shortcutSearch,
    icon: 'ic_shortcut_search',
  ),
  AppShortcut(
    link: syncLink,
    title: l10n.shortcutSync,
    icon: 'ic_shortcut_sync',
  ),
];
