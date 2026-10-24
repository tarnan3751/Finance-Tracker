/// `Money`: an amount as integer minor units plus an ISO 4217 currency code.
///
/// The project's rule (CLAUDE.md, **Money and time**; `PLAN.md` §2 principle 2): no
/// floating-point number ever touches an amount. There is no constructor from a floating
/// value and no conversion to one; arithmetic is integer arithmetic, overflow-checked
/// (`rounding.dart`), and every division names its [RoundingMode]. Parsing and formatting
/// live in `money_format.dart` and go through intl's locale data on the integer path only.
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:shared_models/src/money/currency.dart';
import 'package:shared_models/src/money/money_format.dart';
import 'package:shared_models/src/money/rounding.dart';

/// Thrown when an operation combines two amounts in different currencies.
final class CurrencyMismatchException implements Exception {
  /// An exception for an operation between [left] and [right].
  const CurrencyMismatchException(this.left, this.right);

  /// The currency code of the receiver (or the expected currency).
  final String left;

  /// The currency code of the other operand.
  final String right;

  @override
  String toString() => 'CurrencyMismatchException: $left and $right';
}

/// An amount of money: [minorUnits] of the currency [currencyCode].
///
/// `Money(-1234, 'USD')` is -12.34 US dollars. The currency's minor-unit digit count
/// ([scale]) comes from [Currency]; a code that is three uppercase letters but not in the
/// ISO table is accepted and treated as two digits ([Currency.isKnown] tells them apart).
///
/// [minorUnits] is any 64-bit integer except the most negative, -2^63, so that every
/// amount has a negation: the range is symmetric, ±(2^63 - 1). An operation whose result
/// falls outside it throws a [RangeError].
@immutable
final class Money implements Comparable<Money> {
  /// [minorUnits] of [currencyCode], which must be three uppercase ASCII letters;
  /// [minorUnits] must not be -2^63.
  Money(this.minorUnits, this.currencyCode) {
    if (minorUnits == _excludedMinimum) {
      throw ArgumentError.value(
        minorUnits,
        'minorUnits',
        'must be within ±(2^63 - 1)',
      );
    }
    if (!isValidCurrencyCode(currencyCode)) {
      throw ArgumentError.value(
        currencyCode,
        'currencyCode',
        'must be three uppercase letters (ISO 4217)',
      );
    }
  }

  /// Zero in [currencyCode].
  Money.zero(String currencyCode) : this(0, currencyCode);

  /// Parses decimal text such as `1234.56`, `-1,234.56`, `(1,234.56)`, `$1,234.56` or
  /// `1.234,56 €` into [currencyCode].
  ///
  /// Grouping and decimal separators, digits and signs come from intl's symbols for
  /// [locale] (intl's default locale when null, as for [format]). Group separators are
  /// accepted only in the integer part and only where the locale places them. The
  /// currency's own code and symbol are tolerated only at either end; any other symbol is
  /// an error. Parentheses mean negative. More fraction digits than the currency's [scale]
  /// is a [FormatException], never a round.
  factory Money.parse(String text, String currencyCode, {String? locale}) {
    final probe = Money.zero(currencyCode);
    return Money(
      parseMinorUnits(text, currencyCode, probe.scale, locale),
      currencyCode,
    );
  }

  /// Reads `{"minor_units": -1234, "currency": "USD"}`.
  ///
  /// A `minor_units` that is not a JSON integer or is -2^63, or a `currency` that is not
  /// three uppercase letters, is a [FormatException].
  factory Money.fromJson(Map<String, dynamic> json) {
    final minorUnits = json['minor_units'];
    final currency = json['currency'];
    if (minorUnits is! int) {
      throw FormatException(
        'Money minor_units must be an integer, got ${minorUnits.runtimeType}',
        json,
      );
    }
    if (minorUnits == _excludedMinimum) {
      throw FormatException('Money minor_units is out of range', json);
    }
    if (currency is! String || !isValidCurrencyCode(currency)) {
      throw FormatException(
        'Money currency must be three uppercase letters',
        json,
      );
    }
    return Money(minorUnits, currency);
  }

  /// The amount in the currency's minor units (cents for USD, yen for JPY).
  final int minorUnits;

  /// The ISO 4217 currency code.
  final String currencyCode;

  /// The number of minor-unit digits of [currencyCode].
  int get scale => Currency.scaleOf(currencyCode);

  /// Whether [code] has the shape of an ISO 4217 code.
  static bool isValidCurrencyCode(String code) => _codePattern.hasMatch(code);

  static final RegExp _codePattern = RegExp(r'^[A-Z]{3}$');

  static const int _excludedMinimum = -0x8000000000000000;

  /// The sum of [values]. The currency is [currencyCode] when given, else the first
  /// value's; an empty [values] without [currencyCode] is an [ArgumentError].
  static Money sum(Iterable<Money> values, {String? currencyCode}) {
    final iterator = values.iterator;
    if (!iterator.moveNext()) {
      if (currencyCode == null) {
        throw ArgumentError('Money.sum of no values needs a currencyCode');
      }
      return Money.zero(currencyCode);
    }
    var total = currencyCode == null
        ? iterator.current
        : Money.zero(currencyCode) + iterator.current;
    while (iterator.moveNext()) {
      total += iterator.current;
    }
    return total;
  }

  /// The smaller of [a] and [b] (which must share a currency).
  static Money min(Money a, Money b) => a <= b ? a : b;

  /// The larger of [a] and [b] (which must share a currency).
  static Money max(Money a, Money b) => a >= b ? a : b;

  /// Whether the amount is zero.
  bool get isZero => minorUnits == 0;

  /// Whether the amount is below zero.
  bool get isNegative => minorUnits < 0;

  /// Whether the amount is above zero.
  bool get isPositive => minorUnits > 0;

  /// -1, 0 or 1.
  int get sign => minorUnits.sign;

  /// The sum of two amounts in the same currency.
  Money operator +(Money other) =>
      Money(checkedAdd(minorUnits, _same(other).minorUnits), currencyCode);

  /// The difference of two amounts in the same currency.
  Money operator -(Money other) =>
      Money(checkedSubtract(minorUnits, _same(other).minorUnits), currencyCode);

  /// The negated amount.
  Money operator -() => Money(checkedNegate(minorUnits), currencyCode);

  /// The absolute amount.
  Money abs() => isNegative ? -this : this;

  /// The amount multiplied by [factor].
  Money operator *(int factor) =>
      Money(checkedMultiply(minorUnits, factor), currencyCode);

  /// The amount divided by [divisor], truncated toward zero. Use [multipliedBy] or
  /// [allocate] when the remainder matters.
  Money operator ~/(int divisor) {
    if (divisor == 0) {
      throw ArgumentError.value(divisor, 'divisor', 'must not be zero');
    }
    if (divisor == -1) return -this;
    return Money(minorUnits ~/ divisor, currencyCode);
  }

  /// The amount times [numerator] / [denominator], rounded by [mode]. Throws a
  /// [RangeError] when the intermediate product `minorUnits * numerator` overflows.
  Money multipliedBy(
    int numerator,
    int denominator, {
    RoundingMode mode = RoundingMode.halfEven,
  }) => Money(
    divideRounded(checkedMultiply(minorUnits, numerator), denominator, mode),
    currencyCode,
  );

  /// [basisPoints] hundredths of a percent of the amount (`percent(250)` is 2.5 %).
  /// Throws a [RangeError] when `minorUnits * basisPoints` overflows.
  Money percent(int basisPoints, {RoundingMode mode = RoundingMode.halfEven}) =>
      multipliedBy(basisPoints, 10000, mode: mode);

  /// Splits the amount in proportion to [weights] by the largest-remainder method.
  ///
  /// The parts sum exactly to this amount and each is within one minor unit of its exact
  /// proportional share; leftover units go to the largest remainders, ties to the earlier
  /// weight. A negative amount is allocated by its absolute value and the sign reapplied.
  /// [weights] must be non-empty, non-negative and not all zero. Throws a [RangeError]
  /// when the weights' sum or `|amount| * weight` overflows.
  List<Money> allocate(List<int> weights) {
    if (weights.isEmpty) {
      throw ArgumentError.value(weights, 'weights', 'must not be empty');
    }
    var total = 0;
    for (final weight in weights) {
      if (weight < 0) {
        throw ArgumentError.value(weights, 'weights', 'must not be negative');
      }
      total = checkedAdd(total, weight);
    }
    if (total == 0) {
      throw ArgumentError.value(weights, 'weights', 'must not all be zero');
    }
    final amount = isNegative ? checkedNegate(minorUnits) : minorUnits;
    final shares = List<int>.filled(weights.length, 0);
    final remainders = List<int>.filled(weights.length, 0);
    var allocated = 0;
    for (var i = 0; i < weights.length; i++) {
      final product = checkedMultiply(amount, weights[i]);
      shares[i] = product ~/ total;
      remainders[i] = product % total;
      allocated += shares[i];
    }
    final order = List<int>.generate(weights.length, (i) => i)
      ..sort((a, b) {
        final byRemainder = remainders[b].compareTo(remainders[a]);
        return byRemainder != 0 ? byRemainder : a.compareTo(b);
      });
    for (var k = 0; k < amount - allocated; k++) {
      shares[order[k]]++;
    }
    final signed = isNegative;
    return [
      for (final share in shares) Money(signed ? -share : share, currencyCode),
    ];
  }

  /// Splits the amount into [parts] near-equal parts (see [allocate]).
  List<Money> split(int parts) {
    if (parts <= 0) {
      throw ArgumentError.value(parts, 'parts', 'must be positive');
    }
    return allocate(List<int>.filled(parts, 1));
  }

  /// Whether this amount is less than [other] (same currency).
  bool operator <(Money other) => compareTo(other) < 0;

  /// Whether this amount is at most [other] (same currency).
  bool operator <=(Money other) => compareTo(other) <= 0;

  /// Whether this amount is greater than [other] (same currency).
  bool operator >(Money other) => compareTo(other) > 0;

  /// Whether this amount is at least [other] (same currency).
  bool operator >=(Money other) => compareTo(other) >= 0;

  /// Orders amounts of the same currency; a different currency is a
  /// [CurrencyMismatchException].
  @override
  int compareTo(Money other) => minorUnits.compareTo(_same(other).minorUnits);

  /// The fixed-scale decimal form: `-1234.56`, `.` as separator, no grouping, no symbol.
  /// This is the CSV form and is independent of locale.
  String toDecimalString() => formatDecimal(minorUnits, scale);

  /// The amount formatted for display in [locale] (intl's default locale when null).
  ///
  /// With [symbol] the currency symbol is placed as the locale's currency pattern places
  /// it; without, the plain number. [showPlusSign] puts the locale's plus sign on a
  /// positive amount where the minus sign would go on a negative one; zero has no sign.
  /// Every minor-unit digit is shown: the display scale is the ISO scale.
  String format({
    String? locale,
    bool symbol = true,
    bool showPlusSign = false,
  }) => formatMinorUnits(
    minorUnits,
    currencyCode,
    scale,
    locale: locale,
    symbol: symbol,
    showPlusSign: showPlusSign,
  );

  /// `{"minor_units": -1234, "currency": "USD"}`.
  Map<String, dynamic> toJson() => {
    'minor_units': minorUnits,
    'currency': currencyCode,
  };

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);

  /// A debugging form, `USD -12.34`, independent of locale.
  @override
  String toString() => '$currencyCode ${toDecimalString()}';

  Money _same(Money other) {
    if (other.currencyCode != currencyCode) {
      throw CurrencyMismatchException(currencyCode, other.currencyCode);
    }
    return other;
  }
}

/// Converts [Money] to and from its JSON object form, for annotated model fields.
final class MoneyConverter
    implements JsonConverter<Money, Map<String, dynamic>> {
  /// The converter.
  const MoneyConverter();

  @override
  Money fromJson(Map<String, dynamic> json) => Money.fromJson(json);

  @override
  Map<String, dynamic> toJson(Money object) => object.toJson();
}
