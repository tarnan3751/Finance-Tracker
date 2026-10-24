/// Integer-only rounding and overflow-checked arithmetic for `Money`.
///
/// Every operation here works on `int` and never converts to a floating-point number. Dart's
/// native `int` wraps silently on 64-bit overflow, so the money arithmetic goes through the
/// checked helpers below, which throw a [RangeError] instead. Their range is symmetric,
/// ±(2^63 - 1): a result of -2^63 also counts as overflow, because `Money` excludes it.
library;

/// How a division that does not come out exact is rounded to a whole minor unit.
enum RoundingMode {
  /// To the nearest; a tie goes to the even neighbour (banker's rounding).
  halfEven,

  /// To the nearest; a tie goes away from zero.
  halfUp,

  /// To the nearest; a tie goes toward zero.
  halfDown,

  /// Away from zero.
  up,

  /// Toward zero (truncation).
  down,

  /// Toward positive infinity.
  ceiling,

  /// Toward negative infinity.
  floor,
}

/// [numerator] / [denominator] rounded to an integer by [mode].
///
/// Throws an [ArgumentError] when [denominator] is zero.
int divideRounded(int numerator, int denominator, RoundingMode mode) {
  if (denominator == 0) {
    throw ArgumentError.value(denominator, 'denominator', 'must not be zero');
  }
  var n = numerator;
  var d = denominator;
  if (d < 0) {
    n = checkedNegate(n);
    d = checkedNegate(d);
  }
  final quotient = n ~/ d; // truncates toward zero
  final remainder = n.remainder(d).abs(); // 0 <= remainder < d
  if (remainder == 0) return quotient;

  // Compare the remainder with half the divisor without computing 2 * remainder.
  final rest = d - remainder;
  final aboveHalf = remainder > rest;
  final atHalf = remainder == rest;
  final bool awayFromZero;
  switch (mode) {
    case RoundingMode.up:
      awayFromZero = true;
    case RoundingMode.down:
      awayFromZero = false;
    case RoundingMode.ceiling:
      awayFromZero = n > 0;
    case RoundingMode.floor:
      awayFromZero = n < 0;
    case RoundingMode.halfUp:
      awayFromZero = aboveHalf || atHalf;
    case RoundingMode.halfDown:
      awayFromZero = aboveHalf;
    case RoundingMode.halfEven:
      awayFromZero = aboveHalf || (atHalf && quotient.isOdd);
  }
  return awayFromZero ? quotient + n.sign : quotient;
}

/// [a] + [b], throwing a [RangeError] on 64-bit overflow.
int checkedAdd(int a, int b) {
  final result = a + b;
  if (((a ^ result) & (b ^ result)) < 0 || result == _minInt) {
    throw _overflow('$a + $b');
  }
  return result;
}

/// [a] - [b], throwing a [RangeError] on 64-bit overflow.
int checkedSubtract(int a, int b) {
  final result = a - b;
  if (((a ^ b) & (a ^ result)) < 0 || result == _minInt) {
    throw _overflow('$a - $b');
  }
  return result;
}

/// [a] * [b], throwing a [RangeError] on 64-bit overflow.
int checkedMultiply(int a, int b) {
  if (a == 0 || b == 0) return 0;
  final result = a * b;
  if ((a == -1 && b == _minInt) ||
      (b == -1 && a == _minInt) ||
      result ~/ b != a ||
      result == _minInt) {
    throw _overflow('$a * $b');
  }
  return result;
}

/// -[a], throwing a [RangeError] when [a] is the most negative 64-bit integer.
int checkedNegate(int a) {
  if (a == _minInt) throw _overflow('-($a)');
  return -a;
}

const int _minInt = -0x8000000000000000;

RangeError _overflow(String expression) =>
    RangeError('64-bit integer overflow in $expression');
