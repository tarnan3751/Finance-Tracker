/// The Net worth segment's body (`docs/reference/net-worth.md`, **The screen**): the
/// hero card (the latest net worth and its change since the first day of the range shown,
/// green or pink), the range control
/// (3 m, 1 y, All) with the Table/Chart switch and, when the history holds more than one
/// currency, a chip per currency; then the chart (`net_worth_chart.dart`) or its table
/// (`net_worth_table.dart`); then the liabilities with their payoff projections
/// (`liability_payoff_card.dart`). The empty state when no snapshot is stored. No
/// Scaffold of its own: the Insights tab mounts it under its app bar, and
/// `NetWorthScreen` does for the tests.
library;

import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/amount_text.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/core/widgets/hero_card.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/net_worth/application/net_worth_providers.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/features/net_worth/presentation/liability_payoff_card.dart';
import 'package:finance_tracker/features/net_worth/presentation/net_worth_chart.dart';
import 'package:finance_tracker/features/net_worth/presentation/net_worth_table.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// The spans the history can be shown over.
enum NetWorthRange { threeMonths, year, all }

/// [points] (by date, not empty) within [range] of the latest point.
List<NetWorthPoint> pointsInRange(
  List<NetWorthPoint> points,
  NetWorthRange range,
) {
  final LocalDate last = points.last.date;
  final LocalDate? from = switch (range) {
    NetWorthRange.threeMonths => last.addMonths(-3),
    NetWorthRange.year => last.addMonths(-12),
    NetWorthRange.all => null,
  };
  if (from == null) return points;
  return [
    for (final NetWorthPoint p in points)
      if (!p.date.isBefore(from)) p,
  ];
}

/// The currency shown of [codes] (not empty): [chosen] when held, else the device's
/// default currency when held, else the first.
String currencyShown(Iterable<String> codes, String? chosen) {
  if (chosen != null && codes.contains(chosen)) return chosen;
  final String device = defaultCurrencyCode();
  return codes.contains(device) ? device : codes.first;
}

/// The net worth history and the liabilities' payoffs.
class NetWorthView extends ConsumerStatefulWidget {
  const NetWorthView({super.key});

  @override
  ConsumerState<NetWorthView> createState() => _NetWorthViewState();
}

class _NetWorthViewState extends ConsumerState<NetWorthView> {
  NetWorthRange _range = NetWorthRange.year;
  bool _table = false;
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Map<String, List<NetWorthPoint>>> history = ref.watch(
      netWorthSeriesProvider,
    );
    final List<LiabilityPayoff> payoffs =
        ref.watch(liabilityPayoffsProvider).value ?? const [];
    return switch (history) {
      AsyncValue(value: final Map<String, List<NetWorthPoint>> series)
          when series.isNotEmpty =>
        _history(context, l10n, series, payoffs),
      AsyncValue(hasValue: true) => EmptyState(
        icon: Icons.account_balance,
        headline: l10n.netWorthEmptyHeadline,
        body: l10n.netWorthEmptyBody,
      ),
      AsyncValue(hasError: true) => Center(child: Text(l10n.loadFailed)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _history(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, List<NetWorthPoint>> series,
    List<LiabilityPayoff> payoffs,
  ) {
    final ThemeData theme = Theme.of(context);
    final String currency = currencyShown(series.keys, _currency);
    final List<NetWorthPoint> all = series[currency]!;
    final List<NetWorthPoint> shown = pointsInRange(all, _range);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(SpendthriftTokens.space16),
            child: NetWorthHero(shown),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpendthriftTokens.space16,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SegmentedButton<NetWorthRange>(
                  segments: [
                    ButtonSegment(
                      value: NetWorthRange.threeMonths,
                      label: Text(l10n.netWorthRangeThreeMonths),
                    ),
                    ButtonSegment(
                      value: NetWorthRange.year,
                      label: Text(l10n.netWorthRangeYear),
                    ),
                    ButtonSegment(
                      value: NetWorthRange.all,
                      label: Text(l10n.netWorthRangeAll),
                    ),
                  ],
                  selected: {_range},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _range = s.single),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _table = !_table),
                  icon: Icon(_table ? Icons.show_chart : Icons.table_rows),
                  label: Text(
                    _table ? l10n.netWorthShowChart : l10n.netWorthShowTable,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (series.length > 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final String code in series.keys)
                    ChoiceChip(
                      label: Text(code),
                      selected: code == currency,
                      onSelected: (_) => setState(() => _currency = code),
                    ),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (_table)
          NetWorthTable(shown)
        else
          SliverToBoxAdapter(child: NetWorthChart(shown)),
        if (payoffs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.netWorthLiabilitiesHeading,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ),
          SliverList.list(
            children: [
              for (final LiabilityPayoff p in payoffs)
                LiabilityPayoffCard(p, key: ValueKey(p.account.id)),
            ],
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// The Net worth segment's hero card: the latest net worth of [points] (the range shown,
/// by date, not empty), captioned by its change since the range's first day in green or
/// pink, "against an estimate" when that day is reconstructed from transactions.
class NetWorthHero extends StatelessWidget {
  const NetWorthHero(this.points, {super.key});

  final List<NetWorthPoint> points;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateFormat date = DateFormat.yMMMd();
    final NetWorthPoint first = points.first;
    final NetWorthPoint last = points.last;
    final Money change = last.netWorth - first.netWorth;
    String caption(String amount) {
      final String since = l10n.netWorthHeroSince(
        amount,
        date.format(first.date.toDateTime()),
      );
      return first.derived ? l10n.netWorthHeroEstimate(since) : since;
    }

    final bool moved = points.length > 1;
    final String label = l10n.netWorthHeadlineLabel(
      date.format(last.date.toDateTime()),
    );
    return HeroCard(
      label: label,
      figure: AmountText(last.netWorth),
      caption: moved ? caption(change.format(showPlusSign: true)) : null,
      captionTone: !moved || change.isZero
          ? HeroTone.plain
          : change.isNegative
          ? HeroTone.outflow
          : HeroTone.inflow,
      semanticsLabel: heroSentence(
        l10n,
        label,
        amountSemanticsLabel(l10n, last.netWorth),
        // The sign spelled out when negative, the plus kept when positive.
        moved
            ? caption(
                change.isNegative
                    ? amountSemanticsLabel(l10n, change)
                    : change.format(showPlusSign: true),
              )
            : null,
      ),
    );
  }
}
