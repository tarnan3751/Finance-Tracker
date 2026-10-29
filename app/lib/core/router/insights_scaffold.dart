/// The screen frame of the Insights tab's four segments (`PLAN.md` §12 "Insights tab"),
/// as `PlanScaffold` is the Plan tab's: the "Insights" app bar with the segment's own
/// actions, then the Reports | Net worth | Investments | Goals control at the top of the
/// body (in the body, so it grows with the text size; it scrolls sideways when four
/// labels do not fit, which on a phone is the usual case, and opens scrolled to the
/// segment shown), then the segment's body. Choosing a segment goes to its root
/// (`/reports`, `/net-worth`, `/investments`, `/goals`), whose page has no transition.
///
/// [InsightsPlaceholder] is the body of a segment whose feature has not landed yet.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The Insights tab's segments, in the control's order.
enum InsightsSegment { reports, netWorth, investments, goals }

/// An Insights segment's screen: [body] under the app bar with [actions] and the segment
/// control showing [segment].
class InsightsScaffold extends StatefulWidget {
  const InsightsScaffold({
    super.key,
    required this.segment,
    this.actions = const [],
    this.floatingActionButton,
    required this.body,
  });

  /// The segment this screen shows.
  final InsightsSegment segment;

  /// The segment's app bar actions.
  final List<Widget> actions;

  /// The segment's floating button, if any.
  final Widget? floatingActionButton;

  /// The segment's content, under the control.
  final Widget body;

  @override
  State<InsightsScaffold> createState() => _InsightsScaffoldState();
}

class _InsightsScaffoldState extends State<InsightsScaffold> {
  final GlobalKey _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? selected = _selectedKey.currentContext;
      if (selected != null) {
        Scrollable.ensureVisible(selected, alignment: 0.5);
      }
    });
  }

  // [segment]'s label, keyed when it is the one shown so the control can scroll to it.
  Widget _label(InsightsSegment segment, String text) =>
      Text(text, key: segment == widget.segment ? _selectedKey : null);

  void _select(BuildContext context, InsightsSegment selected) {
    if (selected == widget.segment) return;
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
        actions: widget.actions,
        actionsPadding: const EdgeInsetsDirectional.only(end: 8),
      ),
      floatingActionButton: widget.floatingActionButton,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth - 32,
                ),
                child: SegmentedButton<InsightsSegment>(
                  segments: [
                    ButtonSegment(
                      value: InsightsSegment.reports,
                      label: _label(
                        InsightsSegment.reports,
                        l10n.insightsReports,
                      ),
                    ),
                    ButtonSegment(
                      value: InsightsSegment.netWorth,
                      label: _label(
                        InsightsSegment.netWorth,
                        l10n.insightsNetWorth,
                      ),
                    ),
                    ButtonSegment(
                      value: InsightsSegment.investments,
                      label: _label(
                        InsightsSegment.investments,
                        l10n.insightsInvestments,
                      ),
                    ),
                    ButtonSegment(
                      value: InsightsSegment.goals,
                      label: _label(InsightsSegment.goals, l10n.insightsGoals),
                    ),
                  ],
                  selected: {widget.segment},
                  // The check would take width the labels need.
                  showSelectedIcon: false,
                  onSelectionChanged: (selected) =>
                      _select(context, selected.single),
                ),
              ),
            ),
          ),
          Expanded(child: widget.body),
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
