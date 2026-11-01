/// The forecast's body (`docs/reference/forecast.md`, **The screen**): the 30 or 90-day
/// control with the Table/Chart switch beside it, the hero card (the lowest projected
/// balance and its day, or the first day below zero, in pink), then the chart (`forecast_chart.dart`) or
/// its table (`forecast_table.dart`); the empty state when no account is covered. No
/// Scaffold of its own: the Plan tab mounts it under its app bar with
/// [forecastAppBarActions], and `ForecastScreen` does for the tests.
library;

import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/amount_text.dart';
import 'package:finance_tracker/core/widgets/chart_chrome.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/core/widgets/hero_card.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/forecast/application/forecast_providers.dart';
import 'package:finance_tracker/features/forecast/domain/cash_flow_forecast.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_accounts_sheet.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_chart.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_table.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// The forecast's app bar actions: "Choose accounts", which opens the account sheet.
List<Widget> forecastAppBarActions(BuildContext context, WidgetRef ref) => [
  IconButton(
    tooltip: AppLocalizations.of(context).forecastChooseAccounts,
    icon: const Icon(Icons.account_balance_outlined),
    onPressed: () => showForecastAccountsSheet(context),
  ),
];

/// The forecast for the horizon chosen, as a chart or a table.
class ForecastView extends ConsumerStatefulWidget {
  const ForecastView({super.key});

  @override
  ConsumerState<ForecastView> createState() => _ForecastViewState();
}

class _ForecastViewState extends ConsumerState<ForecastView> {
  int _horizon = forecastHorizons.first;
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<ForecastSeries?> forecast = ref.watch(
      forecastProvider(_horizon),
    );
    return switch (forecast) {
      AsyncValue(value: final ForecastSeries series) => ListView(
        padding: const EdgeInsets.only(bottom: SpendthriftTokens.space24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SpendthriftTokens.space16,
              SpendthriftTokens.space8,
              SpendthriftTokens.space16,
              0,
            ),
            child: Wrap(
              spacing: SpendthriftTokens.space8,
              runSpacing: SpendthriftTokens.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SegmentedButton<int>(
                  segments: [
                    for (final int days in forecastHorizons)
                      ButtonSegment(
                        value: days,
                        label: Text(l10n.forecastHorizon(days)),
                      ),
                  ],
                  selected: {_horizon},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setState(() => _horizon = s.single),
                ),
                ChartTableToggle(
                  table: _table,
                  onChanged: (table) => setState(() => _table = table),
                  chartLabel: l10n.forecastShowChart,
                  tableLabel: l10n.forecastShowTable,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SpendthriftTokens.space16),
            child: ForecastHero(series),
          ),
          if (_table)
            ForecastTable(series)
          else
            ChartCard(child: ForecastChart(series)),
        ],
      ),
      AsyncValue(hasValue: true) => EmptyState(
        icon: Icons.show_chart,
        headline: l10n.forecastEmptyHeadline,
        body: l10n.forecastEmptyBody,
        action: FilledButton.icon(
          onPressed: () => showForecastAccountsSheet(context),
          icon: const Icon(Icons.account_balance_outlined),
          label: Text(l10n.forecastChooseAccounts),
        ),
      ),
      AsyncValue(hasError: true) => Center(child: Text(l10n.loadFailed)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// The forecast's hero card: the lowest balance [series] projects, captioned by its day,
/// or, when the balance goes below zero, by the first day it does, in pink.
class ForecastHero extends StatelessWidget {
  const ForecastHero(this.series, {super.key});

  final ForecastSeries series;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateFormat date = DateFormat.MMMd();
    final Money lowest = series.lowestPoint.balance;
    final LocalDate? negative = series.firstNegativeDate;
    final String caption = negative == null
        ? l10n.forecastHeroDate(
            date.format(series.lowestPoint.date.toDateTime()),
          )
        : l10n.forecastBelowZero(date.format(negative.toDateTime()));
    final String label = l10n.forecastHeroLabel;
    return HeroCard(
      label: label,
      figure: AmountText(lowest),
      caption: caption,
      captionTone: negative == null ? HeroTone.plain : HeroTone.outflow,
      semanticsLabel: heroSentence(
        l10n,
        label,
        amountSemanticsLabel(l10n, lowest),
        caption,
      ),
    );
  }
}

/// [event] as a day's events list it: "Rent −$1,650.00", the bill's name or "Bill" for
/// one with none, "…, due Oct 22" when it was overdue on [day].
String forecastEventLabel(
  ForecastEvent event,
  DateTime day,
  AppLocalizations l10n,
) {
  final String name = billName(event.name, l10n);
  final String named = event.due.toDateTime().isBefore(day)
      ? l10n.forecastOverdue(
          name,
          DateFormat.MMMd().format(event.due.toDateTime()),
        )
      : name;
  return switch (event.amount) {
    final amount? => l10n.forecastEventAmount(named, amount.format()),
    null => named,
  };
}
