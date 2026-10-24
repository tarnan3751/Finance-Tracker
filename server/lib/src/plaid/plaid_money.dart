/// Plaid's decimal numbers as `Money`, without a `double` (`docs/reference/server.md`,
/// **Money from Plaid**), and Plaid's `#rrggbb` colours as the contract's ARGB.
///
/// Plaid writes amounts as JSON numbers. The fake client's fixtures carry them as strings
/// or integers, and the real client reads them through a number-preserving decode that
/// keeps each number's text, so this function only ever sees exact text or an `int`.
///
/// Sandbox writes some amounts finer than the currency's scale (`10.021521`, a balance of
/// `342.099285`) and some with binary noise (`19.569999999999997`). The real client reads
/// with a [RoundingMode] (half-even, `PLAN.md` §12): the text is rounded to the scale as
/// text, never through a `double`, and exponent forms (`1e-07`) are expanded exactly. The
/// fake reads strictly, with no mode: anything beyond the scale that is not zeros is an
/// error.
library;

import 'package:shared_models/shared_models.dart';

final _decimal = RegExp(r'^(-?)(0|[1-9][0-9]*)(?:\.([0-9]+))?$');

/// [value] (decimal text such as `"-12.5"`, or an `int`) in [currencyCode] at the
/// currency's scale. Without [rounding], fraction digits beyond the scale are accepted only
/// when they are zeros, and exponent forms are refused. With [rounding], exponent forms are
/// expanded and the extra digits are rounded by that mode. Anything else, including a
/// `double`, is a [FormatException] or an [ArgumentError].
Money plaidMoney(Object value, String currencyCode, {RoundingMode? rounding}) {
  String text;
  if (value is int) {
    text = value.toString();
  } else if (value is String) {
    text = rounding == null ? value : expandPlaidExponent(value);
  } else {
    throw ArgumentError.value(
      value,
      'value',
      'must be decimal text or an int, never a double',
    );
  }
  final match = _decimal.firstMatch(text);
  if (match == null) throw FormatException('Not a decimal amount', text);
  final negative = match[1] == '-';
  final scale = Currency.scaleOf(currencyCode);
  var fraction = match[3] ?? '';
  var bump = false;
  if (fraction.length > scale) {
    final rest = fraction.substring(scale);
    fraction = fraction.substring(0, scale);
    if (rest.contains(RegExp('[1-9]'))) {
      if (rounding == null) {
        throw FormatException(
          'More fraction digits than $currencyCode has',
          text,
        );
      }
      final kept = '${match[2]}$fraction';
      bump = _roundsAway(
        rounding,
        negative: negative,
        odd: kept.codeUnitAt(kept.length - 1).isOdd,
        rest: rest,
      );
    }
  }
  final digits = '${match[2]}${fraction.padRight(scale, '0')}';
  var magnitude = int.tryParse(digits);
  if (magnitude != null && bump) {
    magnitude = magnitude == _maxInt ? null : magnitude + 1;
  }
  if (magnitude == null) throw FormatException('Amount out of range', text);
  return Money(negative ? -magnitude : magnitude, currencyCode);
}

const _maxInt = 0x7FFFFFFFFFFFFFFF;

/// Whether a magnitude whose dropped digits are [rest] (not all zeros) moves one minor
/// unit away from zero under [mode]; [odd] is the parity of its last kept digit.
bool _roundsAway(
  RoundingMode mode, {
  required bool negative,
  required bool odd,
  required String rest,
}) {
  final first = rest.codeUnitAt(0) - 0x30;
  final tie = first == 5 && !rest.substring(1).contains(RegExp('[1-9]'));
  final above = first > 5 || (first == 5 && !tie);
  return switch (mode) {
    RoundingMode.halfEven => above || (tie && odd),
    RoundingMode.halfUp => above || tie,
    RoundingMode.halfDown => above,
    RoundingMode.up => true,
    RoundingMode.down => false,
    RoundingMode.ceiling => !negative,
    RoundingMode.floor => negative,
  };
}

final _exponent = RegExp(r'^(-?)([0-9]+)(?:\.([0-9]+))?[eE]([+-]?[0-9]{1,3})$');

/// [text] with an exponent (`1.5e-07`, as Plaid may write a tiny number) rewritten as the
/// same plain decimal (`0.00000015`), exactly; text without one is returned as it is.
String expandPlaidExponent(String text) {
  final match = _exponent.firstMatch(text);
  if (match == null) return text;
  final whole = match[2]!;
  final digits = '$whole${match[3] ?? ''}';
  final point = whole.length + int.parse(match[4]!);
  final String plain;
  if (point <= 0) {
    plain = '0.${'0' * -point}$digits';
  } else if (point >= digits.length) {
    plain = digits.padRight(point, '0');
  } else {
    plain = '${digits.substring(0, point)}.${digits.substring(point)}';
  }
  final dot = plain.indexOf('.');
  var integer = dot < 0 ? plain : plain.substring(0, dot);
  integer = integer.replaceFirst(RegExp('^0+(?=[0-9])'), '');
  return '${match[1]}$integer${dot < 0 ? '' : plain.substring(dot)}';
}

/// [plaidMoney] of a nullable value.
Money? optionalPlaidMoney(
  Object? value,
  String currencyCode, {
  RoundingMode? rounding,
}) =>
    value == null ? null : plaidMoney(value, currencyCode, rounding: rounding);

/// [value] as the contract's `Decimal` string (`"10.42"`): decimal text passes through
/// after a check, an `int` is written out; anything else is a [FormatException]. With
/// [exponents], an exponent form is first expanded ([expandPlaidExponent]).
String plaidDecimal(Object value, {bool exponents = false}) {
  var text = value is int ? value.toString() : value;
  if (exponents && text is String) text = expandPlaidExponent(text);
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
