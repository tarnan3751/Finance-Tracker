/// How transaction dates read: "Today", "Yesterday", the weekday within the last week, and
/// the full date before that (or after today), in the device locale through intl.
/// "Today" is the clock's, in the device zone (`PLAN.md` §6.8).
library;

import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// The label of [date] when today is [today].
String transactionDateLabel(
  AppLocalizations l10n,
  LocalDate date,
  LocalDate today,
) {
  final int daysAgo = date.daysUntil(today);
  return switch (daysAgo) {
    0 => l10n.dateToday,
    1 => l10n.dateYesterday,
    > 1 && < 7 => DateFormat.EEEE().format(date.toDateTime()),
    _ => fullDateLabel(date),
  };
}

/// [date] in full, as the device locale writes it ("October 24, 2026" in en_US).
String fullDateLabel(LocalDate date) =>
    DateFormat.yMMMMd().format(date.toDateTime());

/// [date] short, as the device locale writes it ("Oct 24, 2026" in en_US), for fields.
String shortDateLabel(LocalDate date) =>
    DateFormat.yMMMd().format(date.toDateTime());
