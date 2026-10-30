/// The net worth history as a table, the chart's equivalent: one row per day, newest
/// first, with the date, the net worth, the assets and liabilities, and whether the day
/// is estimated from transactions or carries the day before's values; each row one
/// semantics node read as a sentence. A sliver, so a long history is built lazily.
library;

import 'package:finance_tracker/core/l10n/joins.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The days of [points] (by date), newest first.
class NetWorthTable extends StatelessWidget {
  const NetWorthTable(this.points, {super.key});

  final List<NetWorthPoint> points;

  @override
  Widget build(BuildContext context) => SliverList.separated(
    itemCount: points.length,
    itemBuilder: (context, i) => NetWorthRow(points[points.length - 1 - i]),
    separatorBuilder: (_, _) => const Divider(height: 1),
  );
}

/// One day of the table.
class NetWorthRow extends StatelessWidget {
  const NetWorthRow(this.point, {super.key});

  final NetWorthPoint point;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String date = DateFormat.yMMMEd().format(point.date.toDateTime());
    final String netWorth = point.netWorth.format();
    final String assets = point.assets.format();
    final String liabilities = point.liabilities.format();
    final String? flag = point.derived
        ? l10n.netWorthEstimated
        : point.carried
        ? l10n.netWorthCarried
        : null;
    final TextStyle? muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      container: true,
      label: sentenceLine(l10n, [
        l10n.netWorthRowSemantics(date, netWorth, assets, liabilities),
        ?flag,
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
                    netWorth,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: point.netWorth.isNegative
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ),
                ],
              ),
              Text(l10n.netWorthRowDetail(assets, liabilities), style: muted),
              if (flag != null)
                Text(flag, style: muted?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }
}
