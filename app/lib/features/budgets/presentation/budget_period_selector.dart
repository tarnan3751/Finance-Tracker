/// The period selector of the budgets screens: the previous and next periods, the shown
/// period's name ("This period", "Last period", "3 periods ago", "Next period") and,
/// when the screen has one, its dates in the device zone; "This period" returns to the
/// current period.
library;

import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// [period]'s first and last days, the first without its year when both share it
/// ("Oct 15 – Nov 14, 2026").
String budgetPeriodLabel(AppLocalizations l10n, LocalDateRange period) {
  final LocalDate last = period.end.addDays(-1);
  final DateFormat start = period.start.year == last.year
      ? DateFormat.MMMd()
      : DateFormat.yMMMd();
  return l10n.budgetPeriodRange(
    start.format(period.start.toDateTime()),
    DateFormat.yMMMd().format(last.toDateTime()),
  );
}

/// The selector at [offset] periods from the current one, showing [dates] under the
/// period's name when given; [onSelected] gets the offset chosen.
class BudgetPeriodSelector extends StatelessWidget {
  const BudgetPeriodSelector({
    super.key,
    required this.offset,
    required this.dates,
    required this.onSelected,
  });

  final int offset;
  final String? dates;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String name = switch (offset) {
      0 => l10n.budgetPeriodCurrent,
      < 0 => l10n.budgetPeriodsAgo(-offset),
      _ => l10n.budgetPeriodsAhead(offset),
    };
    final String? shownDates = dates;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.budgetPeriodPrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onSelected(offset - 1),
              ),
              Expanded(
                child: Semantics(
                  label: l10n.budgetPeriodShown(
                    shownDates == null
                        ? name
                        : l10n.captionPair(name, shownDates),
                  ),
                  liveRegion: true,
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (shownDates != null)
                        Text(
                          shownDates,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.budgetPeriodNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onSelected(offset + 1),
              ),
            ],
          ),
          if (offset != 0)
            TextButton(
              onPressed: () => onSelected(0),
              child: Text(l10n.budgetPeriodCurrent),
            ),
        ],
      ),
    );
  }
}
