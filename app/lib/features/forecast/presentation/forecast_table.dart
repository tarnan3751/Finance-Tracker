/// The forecast as a table, the chart's equivalent: one row per day with the date, the
/// projected balance, the band's low and high edges and the day's events, each row one
/// semantics node read as a sentence.
library;

import 'package:finance_tracker/core/l10n/joins.dart';
import 'package:finance_tracker/features/forecast/domain/cash_flow_forecast.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_view.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The days of [series].
class ForecastTable extends StatelessWidget {
  const ForecastTable(this.series, {super.key});

  final ForecastSeries series;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final ForecastPoint point in series.points) ...[
        _DayRow(point),
        const Divider(height: 1),
      ],
    ],
  );
}

class _DayRow extends StatelessWidget {
  const _DayRow(this.point);

  final ForecastPoint point;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final DateTime day = point.date.toDateTime();
    final String date = DateFormat.MMMEd().format(day);
    final String balance = point.balance.format();
    final String low = point.lower.format();
    final String high = point.upper.format();
    final List<String> events = [
      for (final ForecastEvent e in point.events)
        forecastEventLabel(e, day, l10n),
    ];
    return Semantics(
      container: true,
      label: sentenceLine(l10n, [
        l10n.forecastDaySemantics(date, balance, low, high),
        ...events,
      ]),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(date, style: theme.textTheme.titleSmall),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    balance,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: point.balance.isNegative
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ),
                ],
              ),
              Text(
                l10n.forecastRange(low, high),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              for (final String e in events)
                Text(e, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
