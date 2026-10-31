/// Amounts read from an export's text into minor units (`docs/reference/import.md`,
/// **Amounts**). Pure Dart, and no `double` anywhere: the digits become an integer as
/// written.
///
/// Currency symbols are stripped, and so is one currency word at the start or the end: an
/// ISO code the app knows (`Currency.isKnown`, `USD 12.34`) or `kr` (`12,50 kr`); any
/// other letter refuses the field (so `12.00 DR` or `12.00 DBT` is never read as a
/// credit). Whitespace (no-break spaces included)
/// goes too. Parentheses, or a minus in front or at the end (`-`, or U+2212), make an
/// amount negative; a `+` in front is allowed. The decimal separator is the one given;
/// the other one, and `'`, group thousands before it, in groups of exactly three digits
/// after the first group of one to three, so a field written with the other separator
/// (`12,50` read with a point, `-82.17` with a comma) is refused, never misread. The
/// fraction is padded to the currency's digits, or rounded half-even past them (`1.005`
/// dollars is 100 cents, `1.015` is 102).
library;

import 'package:shared_models/shared_models.dart';

/// Which character separates an amount's whole part from its fraction.
enum DecimalSeparator {
  /// `1,234.56`.
  point('.', ','),

  /// `1.234,56`.
  comma(',', '.');

  const DecimalSeparator(this.char, this.grouping);

  /// The separator.
  final String char;

  /// The other one, which groups thousands.
  final String grouping;
}

/// Why a field is not an amount.
enum AmountProblem {
  /// Nothing but whitespace and symbols.
  empty,

  /// Not a number in the separator's convention.
  notANumber,

  /// Beyond what `Money` holds.
  tooLarge,
}

/// A field that is not an amount.
final class AmountFormatException implements Exception {
  /// The exception for [problem].
  const AmountFormatException(this.problem);

  /// Why.
  final AmountProblem problem;

  @override
  String toString() => 'AmountFormatException(${problem.name})';
}

final RegExp _noise = RegExp(r'[\s\p{Sc}]', unicode: true);
final RegExp _leadingWord = RegExp(r'^\s*([A-Za-z]{2,3})(?![A-Za-z])');
final RegExp _trailingWord = RegExp(r'(?<![A-Za-z])([A-Za-z]{2,3})\s*$');
final RegExp _group = RegExp(r'^[0-9]{3}$');
final RegExp _firstGroup = RegExp(r'^[0-9]{1,3}$');
final RegExp _numeral = RegExp(r"^[0-9.,']+$");
final RegExp _digit = RegExp('[0-9]');
final BigInt _maxMinor = BigInt.parse('9223372036854775807');

/// [text] as minor units of a currency with [scale] digits, read with [separator]; a
/// [AmountFormatException] when it is not an amount.
int parseMinorUnits(
  String text, {
  required DecimalSeparator separator,
  required int scale,
}) {
  String s = text.replaceAll(RegExp(r'\p{Sc}', unicode: true), '').trim();
  // A word is a currency only beside a number: `ten` alone is not an amount.
  final String withoutWord =
      _withoutCurrencyWord(s, _leadingWord) ??
      _withoutCurrencyWord(s, _trailingWord) ??
      s;
  if (withoutWord.contains(_digit)) s = withoutWord;
  s = s.replaceAll(_noise, '');
  if (s.isEmpty) throw const AmountFormatException(AmountProblem.empty);
  int signs = 0;
  if (s.startsWith('(') && s.endsWith(')')) {
    s = s.substring(1, s.length - 1);
    signs++;
  }
  bool negative = signs > 0;
  if (s.startsWith('-') || s.startsWith('−')) {
    s = s.substring(1);
    negative = true;
    signs++;
  } else if (s.startsWith('+')) {
    s = s.substring(1);
  }
  if (s.endsWith('-') || s.endsWith('−')) {
    s = s.substring(0, s.length - 1);
    negative = true;
    signs++;
  }
  if (signs > 1 || !_numeral.hasMatch(s) || !s.contains(_digit)) {
    throw const AmountFormatException(AmountProblem.notANumber);
  }
  final List<String> parts = s.split(separator.char);
  if (parts.length > 2) {
    throw const AmountFormatException(AmountProblem.notANumber);
  }
  final List<String> groups = parts[0].split(
    RegExp('[${RegExp.escape(separator.grouping)}\']'),
  );
  if (groups.length > 1 &&
      (!_firstGroup.hasMatch(groups.first) ||
          !groups.skip(1).every(_group.hasMatch))) {
    throw const AmountFormatException(AmountProblem.notANumber);
  }
  final String whole = groups.join();
  final String fraction = parts.length == 2 ? parts[1] : '';
  if (fraction.contains(separator.grouping) || fraction.contains("'")) {
    throw const AmountFormatException(AmountProblem.notANumber);
  }
  final BigInt magnitude = _rounded(whole, fraction, scale);
  if (magnitude > _maxMinor) {
    throw const AmountFormatException(AmountProblem.tooLarge);
  }
  final int minor = magnitude.toInt();
  return negative ? -minor : minor;
}

// [s] without the word [word] matches, when that word is a known ISO code or `kr`.
String? _withoutCurrencyWord(String s, RegExp word) {
  final RegExpMatch? m = word.firstMatch(s);
  if (m == null) return null;
  final String w = m[1]!;
  final bool currency = w.length == 3
      ? Currency.isKnown(w.toUpperCase())
      : w.toLowerCase() == 'kr';
  return currency ? s.replaceRange(m.start, m.end, '') : null;
}

// [whole].[fraction] in units of 10^-[scale], rounded half-even.
BigInt _rounded(String whole, String fraction, int scale) {
  final String w = whole.isEmpty ? '0' : whole;
  if (fraction.length <= scale) {
    return BigInt.parse(w + fraction.padRight(scale, '0'));
  }
  final BigInt kept = BigInt.parse(w + fraction.substring(0, scale));
  final String rest = fraction.substring(scale);
  final int first = rest.codeUnitAt(0) - 0x30;
  final bool beyondHalf = rest.substring(1).contains(RegExp('[1-9]'));
  final bool up = first > 5 || (first == 5 && (beyondHalf || kept.isOdd));
  return up ? kept + BigInt.one : kept;
}

/// The decimal separator [samples] use, or null when they do not say. In each, the last
/// `.` or `,` is the decimal one, unless it appears more than once (it groups) or it is
/// the only separator with exactly three digits after it (`1,234` could be either), which
/// says nothing; the separator most samples say wins, null on a tie.
DecimalSeparator? detectDecimalSeparator(Iterable<String> samples) {
  int point = 0, comma = 0;
  for (final String sample in samples) {
    final String s = sample.replaceAll(RegExp(r'[^0-9.,]'), '');
    final int last = s.lastIndexOf(RegExp('[.,]'));
    if (last < 0) continue;
    final String c = s[last];
    final String other = c == '.' ? ',' : '.';
    final bool repeated = c.allMatches(s).length > 1;
    final DecimalSeparator? says;
    if (repeated) {
      says = c == '.' ? DecimalSeparator.comma : DecimalSeparator.point;
    } else if (!s.contains(other) && s.length - last - 1 == 3) {
      says = null;
    } else {
      says = c == '.' ? DecimalSeparator.point : DecimalSeparator.comma;
    }
    if (says == DecimalSeparator.point) point++;
    if (says == DecimalSeparator.comma) comma++;
  }
  if (point == comma) return null;
  return point > comma ? DecimalSeparator.point : DecimalSeparator.comma;
}
