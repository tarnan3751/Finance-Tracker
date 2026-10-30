/// The scaffold around the five tabs: the current branch's navigator beside or above
/// the navigation for the window's size class (`core/layout/window_size_class.dart`): a
/// Material 3 `NavigationBar` under it on a compact window, a `NavigationRail` with
/// labels at its start on a medium one, and the extended rail on an expanded one. The
/// destinations and their branches are the same in all three. Only the selected branch
/// is shown; the others keep their state, also when the window changes class (a
/// foldable unfolded, a tablet turned). Screen readers go through the screen before the
/// rail, as they do before the bar, though the rail comes first on the screen.
///
/// On an expanded window the Accounts, Transactions and Settings tabs, and the Plan tab
/// on its Bills segment, show their list beside the tab's navigator (`TwoPane`,
/// `core/layout/two_pane.dart`), chosen by the first location of the tab's stack.
///
/// Each branch has its own `ScaffoldMessenger`, so a snack bar shown from a tab (Undo
/// after a delete, a save error) appears in that tab's screen `Scaffold`: above the
/// navigation bar, lifting the screen's floating button instead of covering it, and
/// carried over to the screen below when the one that showed it is popped. Beside a
/// detail, the list has a messenger of its own (`TwoPane`), so a snack bar shows once,
/// in the pane whose screen showed it.
///
/// The list beside a detail and the list as the navigator's first page are one element
/// under one key (`ListKeys`), so it keeps its state when the window changes class.
///
/// The Plan tab's icon carries a badge with the number of active bills whose last
/// occurrence was missed (`billStatusesProvider`), read by screen readers in words.
///
/// On its first frame the shell tells the user, once, what the legacy importer brought
/// in at this launch (`legacyImportResultProvider`), then clears it.
library;

import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/layout/two_pane.dart';
import 'package:finance_tracker/core/layout/window_size_class.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/bills/presentation/bills_screen.dart';
import 'package:finance_tracker/features/settings/presentation/settings_screen.dart';
import 'package:finance_tracker/features/transactions/presentation/transactions_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The tab shell built by `AppShellRoute`.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  /// The shell's state: the current branch index and `goBranch`.
  final StatefulNavigationShell navigationShell;

  /// One navigator per branch, in branch order.
  final List<Widget> children;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // One messenger per branch, so a snack bar lands in the branch's own screens.
  late final List<GlobalKey<ScaffoldMessengerState>> _messengers = [
    for (int i = 0; i < widget.children.length; i++)
      GlobalKey<ScaffoldMessengerState>(),
  ];

  // One key per branch navigator, so a navigator keeps its state when the window
  // changes class and it moves into or out of a two-pane layout.
  late final List<GlobalKey> _navigators = [
    for (int i = 0; i < widget.children.length; i++) GlobalKey(),
  ];

  // The first location of each branch's stack, as of the last time it was shown.
  final Map<int, String> _roots = {};

  // The key of each list shown beside its detail (`ListKeys`).
  final Map<Type, GlobalKey> _lists = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportImport());
  }

  /// Shows what `bootstrap`'s legacy import did, once, in the current tab.
  void _reportImport() {
    final ImportSummary? summary = ref.read(legacyImportResultProvider);
    if (summary == null || !mounted) return;
    final ScaffoldMessengerState? messenger =
        _messengers[widget.navigationShell.currentIndex].currentState;
    if (messenger == null) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String message = [
      if (summary.transactions > 0)
        l10n.legacyImported(summary.transactions, summary.total.format()),
      if (summary.skipped > 0) l10n.legacyImportSkipped(summary.skipped),
    ].join(' ');
    ref.read(legacyImportResultProvider.notifier).record(null);
    if (message.isEmpty) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  // The shell fills the window, so its width is the window's.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        _build(context, WindowSizeClass.fromWidth(constraints.maxWidth)),
  );

  Widget _build(BuildContext context, WindowSizeClass size) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final StatefulNavigationShell navigationShell = widget.navigationShell;
    final int current = navigationShell.currentIndex;
    _roots[current] =
        navigationShell.shellRouteContext.match.matches.first.matchedLocation;
    final int missed = [
      for (final BillStatus s in ref.watch(billStatusesProvider).value ?? [])
        if (s.bill.active && s.state == BillState.missed) s,
    ].length;
    // The destination's tooltip is left out of semantics, so the count is read from
    // here, in words; the badge's digits would read as a bare number.
    Widget badged(IconData icon) => Semantics(
      label: missed > 0 ? l10n.billsMissedCount(missed) : null,
      child: Badge(
        isLabelVisible: missed > 0,
        label: ExcludeSemantics(
          child: Text(NumberFormat.decimalPattern().format(missed)),
        ),
        child: Icon(icon),
      ),
    );
    final List<_Destination> destinations = [
      (
        icon: const Icon(Icons.account_balance_outlined),
        selectedIcon: const Icon(Icons.account_balance),
        label: l10n.navAccounts,
        tooltip: null,
      ),
      (
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long),
        label: l10n.navTransactions,
        tooltip: null,
      ),
      (
        icon: badged(Icons.event_note_outlined),
        selectedIcon: badged(Icons.event_note),
        label: l10n.navPlan,
        tooltip: missed > 0 ? l10n.navPlanMissed(missed) : null,
      ),
      (
        icon: const Icon(Icons.insights_outlined),
        selectedIcon: const Icon(Icons.insights),
        label: l10n.navInsights,
        tooltip: null,
      ),
      (
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: l10n.navSettings,
        tooltip: null,
      ),
    ];
    void select(int index) => navigationShell.goBranch(
      index,
      // Tapping the current tab again returns it to its first screen.
      initialLocation: index == current,
    );
    final Widget branches = IndexedStack(
      index: current,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          TickerMode(
            enabled: i == current,
            child: ScaffoldMessenger(
              key: _messengers[i],
              child: ListKeys(keys: _lists, child: _branch(i, size)),
            ),
          ),
      ],
    );
    if (size == WindowSizeClass.compact) {
      return Scaffold(
        body: branches,
        bottomNavigationBar: NavigationBar(
          selectedIndex: current,
          onDestinationSelected: select,
          destinations: [
            for (final _Destination d in destinations)
              NavigationDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: d.label,
                tooltip: d.tooltip,
              ),
          ],
        ),
      );
    }
    // On a fold the extended rail would leave the list little room before the fold.
    final bool extended =
        size == WindowSizeClass.expanded && verticalFold(context) == null;
    return Scaffold(
      body: Row(
        children: [
          // After the screen in the reading order, as the bar is.
          Semantics(
            container: true,
            sortKey: const OrdinalSortKey(1),
            child: NavigationRail(
              selectedIndex: current,
              onDestinationSelected: select,
              extended: extended,
              labelType: extended ? null : NavigationRailLabelType.all,
              // Five destinations at a large text size outgrow a phone on its side.
              scrollable: true,
              destinations: [
                for (final _Destination d in destinations)
                  NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Semantics(
              container: true,
              sortKey: const OrdinalSortKey(0),
              child: branches,
            ),
          ),
        ],
      ),
    );
  }

  /// Branch [i]'s navigator, beside the branch's list when [size] is expanded and the
  /// branch's stack starts at a list that has a detail.
  Widget _branch(int i, WindowSizeClass size) {
    final Widget navigator = KeyedSubtree(
      key: _navigators[i],
      child: widget.children[i],
    );
    final Widget? list = size == WindowSizeClass.expanded
        ? _listBesideDetail(_roots[i])
        : null;
    if (list == null) return navigator;
    return TwoPane(start: ListKeys.wrapIn(_lists, list), end: navigator);
  }
}

/// The list shown beside the pages of a stack that starts at [root], or null.
Widget? _listBesideDetail(String? root) {
  if (root == const AccountsRoute().location) return const AccountsScreen();
  if (root == const TransactionsRoute().location) {
    return const TransactionsScreen();
  }
  if (root == const BillsRoute().location) return const BillsScreen();
  if (root == const SettingsRoute().location) return const SettingsScreen();
  return null;
}

/// A navigation destination, drawn by the bar or the rail.
typedef _Destination = ({
  Widget icon,
  Widget selectedIcon,
  String label,
  String? tooltip,
});
