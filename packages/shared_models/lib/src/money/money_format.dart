/// Locale-aware formatting and parsing of `Money`, on the integer path only.
///
/// intl's `NumberFormat.format` is exact for an `int` but its fraction handling goes
/// through floating point, so it is never given a fraction: the whole part is formatted as
/// an `int` by intl, the fraction digits are appended by hand, and the sign and currency
/// symbol come from the affixes intl derives from the locale's currency pattern
/// (`docs/reference/core.md`, **Formatting**). Used through `Money.format` and
/// `Money.parse`; not exported from the package.
library;

import 'package:intl/intl.dart';
import 'package:shared_models/src/money/rounding.dart';

/// [minorUnits] at [scale] as `-1234.56`: fixed scale, `.` separator, no grouping.
String formatDecimal(int minorUnits, int scale) {
  final (whole, fraction) = _splitScaled(minorUnits, scale);
  final sign = minorUnits < 0 ? '-' : '';
  if (scale == 0) return '$sign$whole';
  return '$sign$whole.${fraction.toString().padLeft(scale, '0')}';
}

/// [minorUnits] of [currencyCode] at [scale], formatted for [locale].
String formatMinorUnits(
  int minorUnits,
  String currencyCode,
  int scale, {
  required String? locale,
  required bool symbol,
  required bool showPlusSign,
}) {
  final (whole, fraction) = _splitScaled(minorUnits, scale);

  final digits = _groupedDigits(_groupingFormat(locale, currencyCode), whole);

  final affixes = symbol
      ? NumberFormat.simpleCurrency(locale: locale, name: currencyCode)
      : NumberFormat.decimalPattern(locale);
  final symbols = affixes.symbols;

  final buffer = StringBuffer(digits);
  if (scale > 0) {
    buffer
      ..write(symbols.DECIMAL_SEP)
      ..write(
        _localizeDigits(
          fraction.toString().padLeft(scale, '0'),
          symbols.ZERO_DIGIT,
        ),
      );
  }

  final String prefix;
  final String suffix;
  if (minorUnits < 0) {
    (prefix, suffix) = (affixes.negativePrefix, affixes.negativeSuffix);
  } else if (minorUnits > 0 && showPlusSign) {
    (prefix, suffix) = _plusAffixes(
      affixes,
      symbols.MINUS_SIGN,
      symbols.PLUS_SIGN,
    );
  } else {
    (prefix, suffix) = (affixes.positivePrefix, affixes.positiveSuffix);
  }
  return '$prefix$buffer$suffix';
}

/// The affixes for an explicitly signed positive amount: the negative affixes with the
/// minus sign swapped for the plus sign, or the plus sign before the positive prefix when
/// the negative form has no minus sign (a parenthesised pattern).
(String, String) _plusAffixes(NumberFormat format, String minus, String plus) {
  String? swap(String affix) {
    for (final candidate in [minus, '-']) {
      final at = affix.indexOf(candidate);
      if (at >= 0) return affix.replaceRange(at, at + candidate.length, plus);
    }
    return null;
  }

  final prefix = swap(format.negativePrefix);
  if (prefix != null) return (prefix, format.negativeSuffix);
  final suffix = swap(format.negativeSuffix);
  if (suffix != null) return (format.negativePrefix, suffix);
  return ('$plus${format.positivePrefix}', format.positiveSuffix);
}

/// Parses [text] as an amount of [currencyCode] at [scale] in [locale] (intl's default
/// locale when null; see `Money.parse`).
int parseMinorUnits(
  String text,
  String currencyCode,
  int scale,
  String? locale,
) {
  final format = NumberFormat.simpleCurrency(
    locale: locale,
    name: currencyCode,
  );
  final symbols = format.symbols;
  FormatException error(String why) => FormatException(
    'Not a $currencyCode amount in ${format.locale}: $why',
    text,
  );

  // The currency's code and symbol are accepted only at either end, before or after the
  // sign; never between digits.
  final marks = {currencyCode, format.currencySymbol}.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  String stripMarks(String value) {
    var result = value;
    for (final mark in marks) {
      if (mark.isNotEmpty && result.startsWith(mark)) {
        result = result.substring(mark.length).trim();
        break;
      }
    }
    for (final mark in marks) {
      if (mark.isNotEmpty && result.endsWith(mark)) {
        result = result.substring(0, result.length - mark.length).trim();
        break;
      }
    }
    return result;
  }

  var s = stripMarks(_asciiDigits(_stripBidi(text), symbols.ZERO_DIGIT).trim());

  var negative = false;
  var parenthesised = false;
  if (s.startsWith('(') && s.endsWith(')') && s.length >= 2) {
    negative = parenthesised = true;
    s = stripMarks(s.substring(1, s.length - 1).trim());
  }
  final minusSigns = {_stripBidi(symbols.MINUS_SIGN), '-', '\u2212'};
  final plusSigns = {_stripBidi(symbols.PLUS_SIGN), '+'};
  for (final (signs, isMinus) in [(minusSigns, true), (plusSigns, false)]) {
    final sign = signs.where(s.startsWith).firstOrNull;
    if (sign == null) continue;
    if (parenthesised) throw error('a sign inside parentheses');
    negative = isMinus;
    s = stripMarks(s.substring(sign.length).trim());
    break;
  }

  final parts = s.split(symbols.DECIMAL_SEP);
  if (parts.length > 2) throw error('more than one decimal separator');
  final fractionPart = parts.length == 2 ? parts[1] : null;

  // Group separators only in the integer part and only where the locale puts them; in a
  // locale that groups with a space, any typed whitespace character counts as one.
  final groupSeparator = symbols.GROUP_SEP;
  var integerText = parts[0];
  if (groupSeparator.trim().isEmpty) {
    integerText = integerText.replaceAll(_whitespace, groupSeparator);
  }
  var integerPart = integerText;
  if (integerText.contains(groupSeparator)) {
    final groups = integerText.split(groupSeparator);
    final sizes = _groupSizes(_groupingFormat(locale, currencyCode));
    if (sizes == null) throw error('this locale does not group digits');
    final (finalSize, secondarySize) = sizes;
    final valid =
        groups.last.length == finalSize &&
        groups.first.isNotEmpty &&
        groups.first.length <= secondarySize &&
        !groups.first.startsWith('0') &&
        groups
            .sublist(1, groups.length - 1)
            .every((group) => group.length == secondarySize);
    if (!valid) throw error('digit grouping does not match the locale');
    integerPart = groups.join();
  }

  if (!_digitsOnly.hasMatch(integerPart) ||
      (fractionPart != null && !_digitsOnly.hasMatch(fractionPart))) {
    throw error('unexpected characters');
  }
  if (fractionPart != null && fractionPart.isEmpty) {
    throw error('no digits after the decimal separator');
  }
  if (integerPart.isEmpty && fractionPart == null) throw error('no digits');
  if (fractionPart != null && fractionPart.length > scale) {
    throw error('more than $scale fraction digits');
  }

  final whole = integerPart.isEmpty ? 0 : int.tryParse(integerPart);
  if (whole == null) throw error('out of range');
  final fraction = scale == 0
      ? 0
      : int.parse((fractionPart ?? '').padRight(scale, '0'));
  final int magnitude;
  try {
    magnitude = checkedAdd(checkedMultiply(whole, _pow10(scale)), fraction);
  } on RangeError {
    throw error('out of range');
  }
  return negative ? -magnitude : magnitude;
}

/// The whole-number format whose grouping amounts use: the locale's currency pattern with
/// no symbol and no fraction digits.
NumberFormat _groupingFormat(String? locale, String currencyCode) =>
    NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: '',
      decimalDigits: 0,
    );

/// [whole] (non-negative) as grouped, localized digits with no affixes. A positive int
/// formats as positivePrefix + digits + positiveSuffix, so the digits are cut out by the
/// affixes' lengths.
String _groupedDigits(NumberFormat grouping, int whole) {
  final formatted = grouping.format(whole);
  return formatted.substring(
    grouping.positivePrefix.length,
    formatted.length - grouping.positiveSuffix.length,
  );
}

/// The locale's (final, secondary) group sizes, read from a formatted probe: 1234567 is
/// `1,234,567` in en_US (3, 3) and `12,34,567` in en_IN (3, 2). Null when the locale does
/// not group.
(int, int)? _groupSizes(NumberFormat grouping) {
  final groups = _groupedDigits(
    grouping,
    1234567,
  ).split(grouping.symbols.GROUP_SEP);
  if (groups.length < 2) return null;
  final finalSize = groups.last.length;
  final secondarySize = groups.length >= 3
      ? groups[groups.length - 2].length
      : finalSize;
  return (finalSize, secondarySize);
}

/// (|whole part|, |fraction part|) of [minorUnits] at [scale].
(int, int) _splitScaled(int minorUnits, int scale) {
  final divisor = _pow10(scale);
  return ((minorUnits ~/ divisor).abs(), minorUnits.remainder(divisor).abs());
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

String _localizeDigits(String asciiDigits, String zeroDigit) {
  final zero = zeroDigit.codeUnitAt(0);
  if (zero == 0x30) return asciiDigits;
  return String.fromCharCodes(
    asciiDigits.codeUnits.map((c) => c - 0x30 + zero),
  );
}

String _asciiDigits(String text, String zeroDigit) {
  final zero = zeroDigit.codeUnitAt(0);
  if (zero == 0x30) return text;
  return String.fromCharCodes(
    text.codeUnits.map((c) => c >= zero && c < zero + 10 ? c - zero + 0x30 : c),
  );
}

String _stripBidi(String text) => text.replaceAll(_bidiMarks, '');

final RegExp _bidiMarks = RegExp('[‎‏؜]');
final RegExp _whitespace = RegExp(r'\s');
final RegExp _digitsOnly = RegExp(r'^[0-9]*$');
