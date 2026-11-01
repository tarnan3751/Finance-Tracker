/// The screen frame of the Plan tab's three segments (`PLAN.md` §12 "5e rulings"): the
/// "Plan" app bar with the segment's own actions and the one menu, holding the segment's
/// entries above its help, then the Budgets | Bills | Forecast control at the top of the
/// body (`SegmentSwitcher`: in the body, so it grows with the text size), then
/// the segment's body. Choosing a segment goes to its root (`/budgets`, `/bills`,
/// `/forecast`), whose page has no transition, so the control reads as one screen
/// changing its content.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/router/segment_switcher.dart';
import 'package:finance_tracker/features/help/domain/help_section.dart';
import 'package:finance_tracker/features/help/presentation/help_menu.dart';
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
    this.menuEntries = const [],
    this.floatingActionButton,
    required this.body,
  });

  /// The segment this screen shows.
  final PlanSegment segment;

  /// The segment's app bar actions: buttons, never a menu of their own.
  final List<Widget> actions;

  /// The segment's menu entries, which the app bar's one menu shows above the help.
  final List<PopupMenuEntry<void>> menuEntries;

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
        actions: [
          ...actions,
          HelpMenuButton(
            section: switch (segment) {
              PlanSegment.budgets => HelpSection.budgets,
              PlanSegment.bills => HelpSection.bills,
              PlanSegment.forecast => HelpSection.forecast,
            },
            entries: menuEntries,
          ),
        ],
        // Room for a badge, which extends past its button's end.
        actionsPadding: const EdgeInsetsDirectional.only(end: 8),
      ),
      floatingActionButton: floatingActionButton,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentSwitcher<PlanSegment>(
            segments: [
              (PlanSegment.budgets, l10n.planBudgets),
              (PlanSegment.bills, l10n.planBills),
              (PlanSegment.forecast, l10n.planForecast),
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
