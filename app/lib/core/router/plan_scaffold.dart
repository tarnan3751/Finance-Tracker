/// The screen frame of the Plan tab's three segments (`PLAN.md` §12 "5e rulings"): the
/// "Plan" app bar with the segment's own actions, then the Budgets | Bills | Forecast
/// control at the top of the body (in the body, so it grows with the text size), then
/// the segment's body. Choosing a segment goes to its root (`/budgets`, `/bills`,
/// `/forecast`), whose page has no transition, so the control reads as one screen
/// changing its content.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The Plan tab's segments, in the control's order.
enum PlanSegment { budgets, bills, forecast }

/// A Plan segment's screen: [body] under the app bar with [actions] and the segment
/// control showing [segment].
class PlanScaffold extends StatelessWidget {
  const PlanScaffold({
    super.key,
    required this.segment,
    this.actions = const [],
    this.floatingActionButton,
    required this.body,
  });

  /// The segment this screen shows.
  final PlanSegment segment;

  /// The segment's app bar actions.
  final List<Widget> actions;

  /// The segment's floating button, if any.
  final Widget? floatingActionButton;

  /// The segment's content, under the control.
  final Widget body;

  void _select(BuildContext context, PlanSegment selected) {
    if (selected == segment) return;
    switch (selected) {
      case PlanSegment.budgets:
        const BudgetsRoute().go(context);
      case PlanSegment.bills:
        const BillsRoute().go(context);
      case PlanSegment.forecast:
        const ForecastRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPlan),
        actions: actions,
        // Room for a badge, which extends past its button's end.
        actionsPadding: const EdgeInsetsDirectional.only(end: 8),
      ),
      floatingActionButton: floatingActionButton,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<PlanSegment>(
              segments: [
                ButtonSegment(
                  value: PlanSegment.budgets,
                  label: Text(l10n.planBudgets),
                ),
                ButtonSegment(
                  value: PlanSegment.bills,
                  label: Text(l10n.planBills),
                ),
                ButtonSegment(
                  value: PlanSegment.forecast,
                  label: Text(l10n.planForecast),
                ),
              ],
              selected: {segment},
              // The check would take width the labels need at large text sizes.
              showSelectedIcon: false,
              onSelectionChanged: (selected) =>
                  _select(context, selected.single),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
