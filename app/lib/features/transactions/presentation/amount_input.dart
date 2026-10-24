/// Reading an amount the user typed: `Money.parse` in the device locale (intl's default
/// locale) for the currency it is in, so the locale's separators apply, and input with
/// more decimals than the currency has is an error, never rounded.
library;

import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:shared_models/shared_models.dart';

/// [text] as an amount in [currencyCode], or null when it does not parse.
Money? parseAmountInput(String text, String currencyCode) {
  try {
    return Money.parse(text.trim(), currencyCode);
  } on FormatException {
    return null;
  }
}

/// The error to show under an amount field holding [text] in [currencyCode], or null
/// when it is acceptable. An empty field is an error only when [required]; a negative
/// amount only when [signed] is false; zero only when [nonZero].
String? amountInputError(
  AppLocalizations l10n,
  String text,
  String currencyCode, {
  bool required = false,
  bool signed = true,
  bool nonZero = false,
}) {
  if (text.trim().isEmpty) return required ? l10n.amountRequired : null;
  final Money? amount = parseAmountInput(text, currencyCode);
  if (amount == null) {
    // An example in the currency's own precision: 1,234.56, 1,235 or 1,234.567.
    final int scale = Money.zero(currencyCode).scale;
    int example = 1234;
    for (int i = 0; i < scale; i++) {
      example = example * 10 + (5 + i) % 10;
    }
    return l10n.amountInvalid(
      Money(example, currencyCode).format(symbol: false),
    );
  }
  if (!signed && amount.isNegative) return l10n.amountUnsigned;
  if (nonZero && amount.isZero) return l10n.amountRequired;
  return null;
}
