/// The scaffold around the five tabs: the current branch's navigator above a Material 3
/// `NavigationBar`. Only the selected branch is shown; the others keep their state.
///
/// Each branch has its own `ScaffoldMessenger`, so a snack bar shown from a tab (Undo
/// after a delete, a save error) appears in that tab's screen `Scaffold`: above the
/// navigation bar, lifting the screen's floating button instead of covering it, and
/// carried over to the screen below when the one that showed it is popped.
///
/// The Plan tab's icon carries a badge with the number of active bills whose last
/// occurrence was missed (`billStatusesProvider`), read by screen readers in words.
///
/// On its first frame the shell tells the user, once, what the legacy importer brought
/// in at this launch (`legacyImportResultProvider`), then clears it.
library;

import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final StatefulNavigationShell navigationShell = widget.navigationShell;
    final int current = navigationShell.currentIndex;
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
    return Scaffold(
      body: IndexedStack(
        index: current,
        children: [
          for (int i = 0; i < widget.children.length; i++)
            TickerMode(
              enabled: i == current,
              child: ScaffoldMessenger(
                key: _messengers[i],
                child: widget.children[i],
              ),
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
            icon: badged(Icons.event_note_outlined),
            selectedIcon: badged(Icons.event_note),
            label: l10n.navPlan,
            tooltip: missed > 0 ? l10n.navPlanMissed(missed) : null,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.navInsights,
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
