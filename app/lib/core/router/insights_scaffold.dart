/// The screen frame of the Insights tab's four segments (`PLAN.md` §12 "Insights tab"),
/// as `PlanScaffold` is the Plan tab's: the "Insights" app bar with the segment's own
/// actions and the one menu, holding the segment's entries above the help, then the
/// Reports | Net worth | Investments | Goals control at the top of the body
/// (`SegmentSwitcher`: in the body, so it grows with the text size; the four share the
/// width when they fit, else the row scrolls sideways), then the segment's body. Choosing a segment goes to its root
/// (`/reports`, `/net-worth`, `/investments`, `/goals`), whose page has no transition.
///
/// [InsightsPlaceholder] is the body of a segment whose feature has not landed yet.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/router/segment_switcher.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/help/domain/help_section.dart';
import 'package:finance_tracker/features/help/presentation/help_menu.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The Insights tab's segments, in the control's order.
enum InsightsSegment { reports, netWorth, investments, goals }

/// An Insights segment's screen: [body] under the app bar with [actions] and the segment
/// control showing [segment].
class InsightsScaffold extends StatelessWidget {
  const InsightsScaffold({
    super.key,
    required this.segment,
    this.actions = const [],
    this.menuEntries = const [],
    this.floatingActionButton,
    required this.body,
  });

  /// The segment this screen shows.
  final InsightsSegment segment;

  /// The segment's app bar actions: buttons, never a menu of their own.
  final List<Widget> actions;

  /// The segment's menu entries, which the app bar's one menu shows above the help.
  final List<PopupMenuEntry<void>> menuEntries;

  /// The segment's floating button, if any.
  final Widget? floatingActionButton;

  /// The segment's content, under the control.
  final Widget body;

  void _select(BuildContext context, InsightsSegment selected) {
    if (selected == segment) return;
    switch (selected) {
      case InsightsSegment.reports:
        const ReportsRoute().go(context);
      case InsightsSegment.netWorth:
        const NetWorthRoute().go(context);
      case InsightsSegment.investments:
        const InvestmentsRoute().go(context);
      case InsightsSegment.goals:
        const GoalsRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navInsights),
        actions: [
          ...actions,
          HelpMenuButton(section: HelpSection.insights, entries: menuEntries),
        ],
        actionsPadding: const EdgeInsetsDirectional.only(end: 8),
      ),
      floatingActionButton: floatingActionButton,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentSwitcher<InsightsSegment>(
            segments: [
              (InsightsSegment.reports, l10n.insightsReports),
              (InsightsSegment.netWorth, l10n.insightsNetWorth),
              (InsightsSegment.investments, l10n.insightsInvestments),
              (InsightsSegment.goals, l10n.insightsGoals),
            ],
            selected: segment,
            onSelected: (selected) => _select(context, selected),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// The body of a segment whose content another part of the app will provide.
class InsightsPlaceholder extends StatelessWidget {
  const InsightsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.insights,
      headline: l10n.insightsComingHeadline,
      body: l10n.insightsComingBody,
    );
  }
}
