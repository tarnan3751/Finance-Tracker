/// The Investments segment's rows (`docs/reference/investments.md`, **The segment**): a
/// holding (name, quantity at price, value, cost basis and gain or "cost basis
/// unavailable", the price's date) and an investment transaction (name, amount, date,
/// type, quantity at price, fees), each one semantics node read as its lines in order;
/// and the labels they share with the allocation.
///
/// A quantity or a price is shown as its `Decimal`'s canonical string, every scale digit
/// kept, a price with its currency code; every amount is its `Money` formatted through
/// intl.
library;

import 'package:finance_tracker/features/investments/domain/allocation.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// [key] (`allocationKey`) as the allocation names it: "Cash", "Other", "ETF", else
/// Plaid's type title-cased ("Mutual Fund").
String securityTypeLabel(String key, AppLocalizations l10n) => switch (key) {
  'cash' => l10n.investmentsTypeCash,
  'other' => l10n.investmentsTypeOther,
  'etf' => l10n.investmentsTypeEtf,
  _ => titleCase(key),
};

/// [text]'s words with their first letters in upper case, joined by single spaces
/// (`mutual fund` and `mutual_fund` give "Mutual Fund").
String titleCase(String text) => [
  for (final String word in text.trim().split(RegExp(r'[\s_]+')))
    if (word.isNotEmpty) word[0].toUpperCase() + word.substring(1),
].join(' ');

/// [basisPoints] as a whole percent ("55 %", "+5 %" with [plus]), truncated toward zero.
String percentLabel(
  AppLocalizations l10n,
  int basisPoints, {
  bool plus = false,
}) {
  final int percent = basisPoints ~/ 100;
  return plus && percent > 0
      ? l10n.investmentsPercentUp(percent)
      : l10n.investmentsPercent(percent);
}

/// "12.500 at 245.10 USD".
String _quantityAtPrice(
  AppLocalizations l10n,
  Decimal quantity,
  Decimal price,
  String currencyCode,
) => l10n.investmentsQuantityAtPrice(
  quantity.toString(),
  l10n.investmentsPrice(price.toString(), currencyCode),
);

/// One holding, titled by its security's name, else its ticker, else "Unknown
/// security".
class HoldingRow extends StatelessWidget {
  const HoldingRow(this.view, {super.key});

  final HoldingView view;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Holding holding = view.holding;
    final Security? security = view.security;
    final String? ticker = security?.tickerSymbol;
    final String name =
        security?.name ?? ticker ?? l10n.investmentsUnknownSecurity;
    final String value = holding.institutionValue.format();
    final Gain? gain = gainOf(holding);
    final List<String> details = [
      if (ticker != null && ticker != name) ticker,
      _quantityAtPrice(
        l10n,
        holding.quantity,
        holding.institutionPrice,
        holding.institutionValue.currencyCode,
      ),
      if ((holding.costBasis, gain) case (
        final Money cost?,
        final Gain gain?,
      )) ...[
        l10n.investmentsCostBasis(cost.format()),
        l10n.investmentsGain(switch (gain.basisPoints) {
          final int bp => l10n.investmentsChange(
            gain.amount.format(showPlusSign: true),
            percentLabel(l10n, bp, plus: true),
          ),
          null => gain.amount.format(showPlusSign: true),
        }),
      ] else
        l10n.investmentsCostBasisUnavailable,
      if (holding.institutionPriceAsOf case final LocalDate asOf)
        l10n.investmentsPriceAsOf(DateFormat.yMMMd().format(asOf.toDateTime())),
    ];
    final TextStyle? detailStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      container: true,
      label: [l10n.investmentsNameAmount(name, value), ...details].join(', '),
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
                    child: Text(name, style: theme.textTheme.titleSmall),
                  ),
                  const SizedBox(width: 8),
                  Text(value, style: theme.textTheme.titleSmall),
                ],
              ),
              for (final String line in details) Text(line, style: detailStyle),
            ],
          ),
        ),
      ),
    );
  }
}

/// One investment transaction; its subtype follows its type unless it says the same
/// ("Buy", not "Buy · Buy").
class InvestmentTransactionRow extends StatelessWidget {
  const InvestmentTransactionRow(this.transaction, {super.key});

  final InvestmentTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final InvestmentTransaction t = transaction;
    final String amount = t.amount.format();
    final String type = [
      titleCase(t.type),
      if (t.subtype case final String subtype
          when titleCase(subtype).isNotEmpty &&
              titleCase(subtype) != titleCase(t.type))
        titleCase(subtype),
    ].join(' · ');
    final List<String> details = [
      l10n.investmentsDateAndType(
        DateFormat.yMMMd().format(t.date.toDateTime()),
        type,
      ),
      if (t.securityId != null)
        _quantityAtPrice(l10n, t.quantity, t.price, t.amount.currencyCode),
      if (t.fees case final Money fees) l10n.investmentsFees(fees.format()),
    ];
    final TextStyle? detailStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      container: true,
      label: [
        l10n.investmentsNameAmount(t.name, amount),
        ...details,
      ].join(', '),
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
                    child: Text(t.name, style: theme.textTheme.titleSmall),
                  ),
                  const SizedBox(width: 8),
                  Text(amount, style: theme.textTheme.titleSmall),
                ],
              ),
              for (final String line in details) Text(line, style: detailStyle),
            ],
          ),
        ),
      ),
    );
  }
}
