/// The scaffold around the three tabs: the current branch's navigator above a Material 3
/// `NavigationBar`. Only the selected branch is shown; the others keep their state.
///
/// Each branch has its own `ScaffoldMessenger`, so a snack bar shown from a tab (Undo
/// after a delete, a save error) appears in that tab's screen `Scaffold`: above the
/// navigation bar, lifting the screen's floating button instead of covering it, and
/// carried over to the screen below when the one that showed it is popped.
library;

import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The tab shell built by `AppShellRoute`.
class AppShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int current = navigationShell.currentIndex;
    return Scaffold(
      body: IndexedStack(
        index: current,
        children: [
          for (int i = 0; i < children.length; i++)
            TickerMode(
              enabled: i == current,
              // Per branch, so a snack bar lands in the branch's own screens.
              child: ScaffoldMessenger(child: children[i]),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the current tab again returns it to its first screen.
          initialLocation: index == current,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.account_balance_outlined),
            selectedIcon: const Icon(Icons.account_balance),
            label: l10n.navAccounts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.navTransactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
