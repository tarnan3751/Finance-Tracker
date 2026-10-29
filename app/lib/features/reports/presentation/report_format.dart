/// Shared formatting for the reports screens: percents from basis points, signed changes,
/// category and period names.
library;

import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// [basisPoints] as a whole percent ("55 %"), truncated toward zero.
String percentLabel(AppLocalizations l10n, int basisPoints) =>
    l10n.reportsPercent(basisPoints ~/ 100);

/// [change] as "+$12.00 (+15 %)", or "+$5.00 (new)" on a zero base.
String changeLabel(AppLocalizations l10n, Change change) {
  final String amount = change.change.format(showPlusSign: true);
  return switch (change.percentBasisPoints) {
    null => l10n.reportsChangeNew(amount),
    final int bp => l10n.reportsChange(
      amount,
      bp > 0 ? l10n.reportsPercentUp(bp ~/ 100) : percentLabel(l10n, bp),
    ),
  };
}

/// The name of category [id] in [byId]; "Uncategorized" for null or a category gone.
String categoryName(
  AppLocalizations l10n,
  Map<String, Category> byId,
  String? id,
) => byId[id]?.name ?? l10n.uncategorized;

/// [range]'s short name for a chart axis: the month of its first day ("Oct").
String periodShortName(LocalDateRange range) =>
    DateFormat.MMM().format(range.start.toDateTime());

/// [range]'s name in a table: the month and year of its first day ("Oct 2026").
String periodName(LocalDateRange range) =>
    DateFormat.yMMM().format(range.start.toDateTime());
