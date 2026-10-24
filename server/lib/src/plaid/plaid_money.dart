/// Plaid's decimal numbers as `Money`, without a `double` (`docs/reference/server.md`,
/// **Money from Plaid**), and Plaid's `#rrggbb` colours as the contract's ARGB.
///
/// Plaid writes amounts as JSON numbers. The fake client's fixtures carry them as strings
/// or integers, and the Phase 3 client reads them through a number-preserving decode that
/// keeps each number's text, so this function only ever sees exact text or an `int`.
library;

import 'package:shared_models/shared_models.dart';

final _decimal = RegExp(r'^(-?)(0|[1-9][0-9]*)(?:\.([0-9]+))?$');

/// [value] (decimal text such as `"-12.5"`, or an `int`) in [currencyCode] at the
/// currency's scale. Fraction digits beyond the scale are accepted only when they are
/// zeros; anything else, including a `double`, is a [FormatException] or an
/// [ArgumentError]. Never rounds.
Money plaidMoney(Object value, String currencyCode) {
  final String text;
  if (value is int) {
    text = value.toString();
  } else if (value is String) {
    text = value;
  } else {
    throw ArgumentError.value(
      value,
      'value',
      'must be decimal text or an int, never a double',
    );
  }
  final match = _decimal.firstMatch(text);
  if (match == null) throw FormatException('Not a decimal amount', text);
  final scale = Currency.scaleOf(currencyCode);
  var fraction = match[3] ?? '';
  if (fraction.length > scale) {
    if (fraction.substring(scale).contains(RegExp('[1-9]'))) {
      throw FormatException(
        'More fraction digits than $currencyCode has',
        text,
      );
    }
    fraction = fraction.substring(0, scale);
  }
  final digits = '${match[2]}${fraction.padRight(scale, '0')}';
  final magnitude = int.tryParse(digits);
  if (magnitude == null) throw FormatException('Amount out of range', text);
  return Money(match[1] == '-' ? -magnitude : magnitude, currencyCode);
}

/// [plaidMoney] of a nullable value.
Money? optionalPlaidMoney(Object? value, String currencyCode) =>
    value == null ? null : plaidMoney(value, currencyCode);

/// [value] as the contract's `Decimal` string (`"10.42"`): decimal text passes through
/// after a check, an `int` is written out; anything else is a [FormatException].
String plaidDecimal(Object value) {
  final text = value is int ? value.toString() : value;
  if (text is! String || !_decimal.hasMatch(text)) {
    throw FormatException('Not a decimal', '$value');
  }
  return text;
}

final _hexColor = RegExp(r'^#([0-9A-Fa-f]{6})$');

/// Plaid's `primary_color` (`#0075a3`) as the contract's opaque ARGB integer
/// (`0xFF0075A3`); anything else is a [FormatException].
int plaidColor(String hex) {
  final match = _hexColor.firstMatch(hex);
  if (match == null) throw FormatException('Not a #rrggbb colour', hex);
  return 0xFF000000 | int.parse(match[1]!, radix: 16);
}
