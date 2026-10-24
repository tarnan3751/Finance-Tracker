/// An amount of `Money` as text: formatted in the device locale with its currency's symbol,
/// optionally colored by direction ([FinanceColors]), and read by a screen reader with
/// the sign spelled out ("minus $12.50"), since a hyphen is easily lost in speech.
library;

import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// [amount] formatted, in [style]; with [colored], outflows in `FinanceColors.outflow`
/// and inflows in `FinanceColors.inflow` (zero keeps the style's color).
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.style,
    this.colored = false,
    this.textAlign,
  });

  final Money amount;
  final TextStyle? style;
  final bool colored;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final FinanceColors colors = FinanceColors.of(context);
    final Color? color = !colored || amount.isZero
        ? null
        : amount.isNegative
        ? colors.outflow
        : colors.inflow;
    return Text(
      amount.format(),
      style: (style ?? const TextStyle()).copyWith(color: color),
      textAlign: textAlign,
      semanticsLabel: amountSemanticsLabel(
        AppLocalizations.of(context),
        amount,
      ),
    );
  }
}

/// What a screen reader says for [amount]: the formatted amount, with a negative one read
/// as the word for minus followed by its absolute value.
String amountSemanticsLabel(AppLocalizations l10n, Money amount) =>
    amount.isNegative
    ? l10n.amountNegative(amount.abs().format())
    : amount.format();
