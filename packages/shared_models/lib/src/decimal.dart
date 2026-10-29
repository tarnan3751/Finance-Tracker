/// `Decimal`: an exact decimal number, for what needs more precision than minor units and
/// is not an amount of money: per-unit prices and share quantities (`api/openapi.yaml`,
/// `Decimal`; `PLAN.md` §12, "Investments in the app").
///
/// It is kept as a sign, the digits as a [BigInt] and a scale (how many of the digits are
/// fractional), so `41.50` is the digits 4150 at scale 2 and prints back as `41.50`.
/// There is deliberately no arithmetic, no conversion to or from a floating-point number
/// and nothing that combines it with `Money`: a total is `Money`, reported by the
/// institution.
library;

import 'package:meta/meta.dart';

final RegExp _pattern = RegExp(r'^(-?)(0|[1-9][0-9]*)(?:\.([0-9]+))?$');

/// An exact decimal number. Two values are equal when they are the same number, whatever
/// their scales (`1.5` and `1.50`); [toString] keeps the scale it was given.
@immutable
final class Decimal implements Comparable<Decimal> {
  /// [unscaled] × 10^-[scale]: `Decimal(BigInt.from(-4150), 2)` is -41.50. [scale] must
  /// not be negative.
  Decimal(BigInt unscaled, this.scale)
    : _negative = unscaled.isNegative,
      _digits = unscaled.abs() {
    if (scale < 0) {
      throw ArgumentError.value(scale, 'scale', 'must not be negative');
    }
  }

  /// Reads the contract's form: an optional `-`, an integer part with no leading zero, and
  /// an optional `.` with at least one digit (`^-?(0|[1-9][0-9]*)(\.[0-9]+)?$`). Throws a
  /// [FormatException] for anything else (an exponent, a `+`, a bare `.5`).
  factory Decimal.parse(String source) {
    final RegExpMatch? match = _pattern.firstMatch(source);
    if (match == null) throw FormatException('not a Decimal', source);
    final String fraction = match[3] ?? '';
    final BigInt digits = BigInt.parse('${match[2]}$fraction');
    return Decimal(match[1] == '-' ? -digits : digits, fraction.length);
  }

  /// Reads the JSON form, the contract's string ([Decimal.parse]).
  factory Decimal.fromJson(String json) => Decimal.parse(json);

  /// Whether the number is below zero (never for zero, `-0` included).
  bool get isNegative => _negative && _digits != BigInt.zero;

  /// How many of the digits are fractional.
  final int scale;

  final bool _negative;
  final BigInt _digits;

  /// The number × 10^[scale], signed.
  BigInt get unscaled => isNegative ? -_digits : _digits;

  /// The number in the contract's form with [scale] fractional digits, no exponent: `0`,
  /// `-41.50`, `10.4234`. Zero has no sign.
  @override
  String toString() {
    final String digits = _digits.toString().padLeft(scale + 1, '0');
    final String whole = digits.substring(0, digits.length - scale);
    final String sign = isNegative ? '-' : '';
    return scale == 0
        ? '$sign$whole'
        : '$sign$whole.${digits.substring(digits.length - scale)}';
  }

  /// The JSON form, the contract's string ([toString]).
  String toJson() => toString();

  @override
  int compareTo(Decimal other) {
    final int scale = this.scale > other.scale ? this.scale : other.scale;
    return _at(scale).compareTo(other._at(scale));
  }

  // The signed digits at [scale], which is at least this one's.
  BigInt _at(int scale) => unscaled * BigInt.from(10).pow(scale - this.scale);

  @override
  bool operator ==(Object other) => other is Decimal && compareTo(other) == 0;

  @override
  int get hashCode {
    // The trailing-zero-free form, so equal numbers hash alike whatever their scales.
    BigInt digits = unscaled;
    int scale = this.scale;
    final BigInt ten = BigInt.from(10);
    while (scale > 0 && digits % ten == BigInt.zero) {
      digits ~/= ten;
      scale--;
    }
    return Object.hash(digits, scale);
  }
}
