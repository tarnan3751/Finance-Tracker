/// The date formats an import reads, and which of them a file's dates are in
/// (`docs/reference/import.md`, **The mapping**). Pure Dart.
///
/// A date is parsed strictly: the separators of its format, one- or two-digit days and
/// months, a four-digit year, and a date that exists. A time after the date (`2026-03-01
/// 10:22:00`, `2026-03-01T10:22`) is ignored: a transaction has a date, not an instant
/// (`PLAN.md` §6.8).
library;

import 'package:shared_models/shared_models.dart';

/// A date format of a bank export.
enum ImportDateFormat {
  /// `yyyy-MM-dd`.
  iso('yyyy-MM-dd', r'^(\d{4})-(\d{1,2})-(\d{1,2})', _Order.ymd),

  /// `MM/dd/yyyy`.
  us('MM/dd/yyyy', r'^(\d{1,2})/(\d{1,2})/(\d{4})', _Order.mdy),

  /// `dd/MM/yyyy`.
  day('dd/MM/yyyy', r'^(\d{1,2})/(\d{1,2})/(\d{4})', _Order.dmy),

  /// `dd.MM.yyyy`.
  dotted('dd.MM.yyyy', r'^(\d{1,2})\.(\d{1,2})\.(\d{4})', _Order.dmy),

  /// `yyyy/MM/dd`.
  slashedIso('yyyy/MM/dd', r'^(\d{4})/(\d{1,2})/(\d{1,2})', _Order.ymd);

  const ImportDateFormat(this.pattern, this._expression, this._order);

  /// How the format is written, `yyyy-MM-dd` and so on: what the mapping shows.
  final String pattern;

  final String _expression;
  final _Order _order;

  RegExp get _regExp => RegExp('$_expression(?:[ T].*)?\$');

  /// [text] as a date in this format, or null when it is not one.
  LocalDate? parse(String text) {
    final RegExpMatch? m = _regExp.firstMatch(text.trim());
    if (m == null) return null;
    final int a = int.parse(m[1]!), b = int.parse(m[2]!), c = int.parse(m[3]!);
    final (int y, int mo, int d) = switch (_order) {
      _Order.ymd => (a, b, c),
      _Order.mdy => (c, a, b),
      _Order.dmy => (c, b, a),
    };
    if (y < 1 || mo < 1 || mo > 12 || d < 1) return null;
    if (d > LocalDate.daysInMonth(y, mo)) return null;
    return LocalDate(y, mo, d);
  }
}

enum _Order { ymd, mdy, dmy }

/// The formats that read the most of [samples] (blank ones aside), in declaration order:
/// none when no format reads any, more than one when the order of day and month is
/// ambiguous (every date's day 12 or less). The most, not all, so one stray row does not
/// hide the file's format.
List<ImportDateFormat> detectDateFormats(Iterable<String> samples) {
  final List<String> filled = [
    for (final String s in samples)
      if (s.trim().isNotEmpty) s,
  ];
  int most = 0;
  final Map<ImportDateFormat, int> read = {};
  for (final ImportDateFormat f in ImportDateFormat.values) {
    final int n = filled.where((s) => f.parse(s) != null).length;
    read[f] = n;
    if (n > most) most = n;
  }
  if (most == 0) return const [];
  return [
    for (final ImportDateFormat f in ImportDateFormat.values)
      if (read[f] == most) f,
  ];
}
