/// The merchant enrichment fallback (`PLAN.md` §7.1 Tier B, §12): the name, logo and color
/// a transaction is shown with. Plaid's `merchantName` and `merchantLogoUrl` are used as
/// they are whenever present; only where Plaid returned none does the fallback name the
/// merchant, from the dictionary (`merchant_dictionary.dart`) or by cleaning the raw name.
/// Pure Dart.
///
/// Display-side only, like the effective category: nothing here writes a transaction, so
/// a fallback name never reaches the database, the change log or the server, and never
/// wears a Plaid field.
library;

import 'package:finance_tracker/features/transactions/domain/merchant_dictionary.dart';
import 'package:shared_models/shared_models.dart';

/// How a transaction's merchant is shown: [displayName], Plaid's [logoUrl] when it gave
/// one, and [color] (opaque ARGB) for the letter avatar drawn when there is no logo.
final class EnrichedMerchant {
  const EnrichedMerchant({
    required this.displayName,
    this.logoUrl,
    required this.color,
  });

  /// The merchant of [transaction]:
  ///
  /// - the name: Plaid's `merchantName` when present; else, for a `manual` transaction,
  ///   its description as the user typed it; else the dictionary's name for the raw
  ///   `name`; else the raw name cleaned ([cleanMerchantName]);
  /// - the logo: Plaid's `merchantLogoUrl`, untouched (null when Plaid gave none);
  /// - the color: the dictionary's brand color for Plaid's merchant name or the raw name,
  ///   else the palette color of the name shown ([paletteColor]).
  factory EnrichedMerchant.resolve(Transaction transaction) {
    final String? plaidName = transaction.merchantName;
    final MerchantEntry? byPlaidName = plaidName == null
        ? null
        : lookupMerchant(plaidName);
    final MerchantEntry? byRawName = lookupMerchant(transaction.name);
    final String displayName =
        plaidName ??
        (transaction.source == DataSource.manual
            ? transaction.name
            : byRawName?.name ?? cleanMerchantName(transaction.name));
    return EnrichedMerchant(
      displayName: displayName,
      logoUrl: transaction.merchantLogoUrl,
      color:
          byPlaidName?.color ?? byRawName?.color ?? paletteColor(displayName),
    );
  }

  final String displayName;
  final Uri? logoUrl;
  final int color;

  @override
  bool operator ==(Object other) =>
      other is EnrichedMerchant &&
      other.displayName == displayName &&
      other.logoUrl == logoUrl &&
      other.color == color;

  @override
  int get hashCode => Object.hash(displayName, logoUrl, color);

  @override
  String toString() => 'EnrichedMerchant($displayName, $logoUrl, $color)';
}

/// The avatar color of [institution]: Plaid's `primary_color` when present, else the
/// palette color of its name.
int institutionColor(Institution institution) =>
    institution.primaryColor ?? paletteColor(institution.name);

/// [text] as dictionary keys are compared: lower case, apostrophes dropped, every other
/// run of characters that are not ASCII letters or digits one space, trimmed.
String normalizeMerchantText(String text) => text
    .toLowerCase()
    .replaceAll(_apostrophes, '')
    .replaceAll(_nonWord, ' ')
    .trim();

/// The dictionary's merchant for the raw name [raw], or null: the longest key that is the
/// whole first words of [raw], after any leading noise (card-network and point-of-sale
/// words, processor prefixes such as `SQ *`, dates, reference numbers and masked digits)
/// is skipped. Each step of skipping is tried, so `7-ELEVEN` matches before its `7` would
/// be skipped as a number.
MerchantEntry? lookupMerchant(String raw) {
  final List<_Token> tokens = _tokens(raw);
  for (int i = 0; i < tokens.length;) {
    // A processor's prefix goes first: `PAYPAL *NETFLIX` is Netflix.
    final MerchantEntry? hit = _isProcessorAt(raw, tokens, i)
        ? null
        : _lookupAt(tokens, i);
    if (hit != null) return hit;
    final int noise = _noiseAt(raw, tokens, i);
    if (noise == 0) return null;
    i += noise;
  }
  return null;
}

/// The raw name [raw] cleaned for display: the leading noise skipped as in
/// [lookupMerchant], then the words up to the first that carries a digit or masked digits
/// or follows a `#`, a `*` or a spaced dash (store numbers, locations, references), in
/// title case when the raw name is all capitals (acronyms and company suffixes such as
/// ATM, LLC and IRS kept in capitals). [raw] collapsed when nothing is left.
String cleanMerchantName(String raw) {
  final List<_Token> tokens = _tokens(raw);
  int start = 0;
  while (start < tokens.length) {
    final int noise = _noiseAt(raw, tokens, start);
    if (noise == 0) break;
    start += noise;
  }
  if (start >= tokens.length) return _collapse(raw);
  int end = start + 1;
  while (end < tokens.length &&
      !_hasDigitOrMask(tokens[end].key) &&
      !_separates(raw.substring(tokens[end - 1].end, tokens[end].start))) {
    end++;
  }
  final String kept = _collapse(
    raw.substring(tokens[start].start, tokens[end - 1].end),
  );
  return kept == kept.toUpperCase() ? _titleCase(kept) : kept;
}

/// One of [_palette], chosen by a stable hash (32-bit FNV-1a) of [name] normalized, so a
/// name has the same color on every device and every run.
int paletteColor(String name) {
  int hash = 0x811C9DC5;
  for (final int unit in normalizeMerchantText(name).codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return palette[hash % palette.length];
}

/// The colors a name without a brand color is drawn in: Material's 800 shades, each with
/// enough contrast against white or black text (the avatar picks the better).
const List<int> palette = [
  0xFFC62828,
  0xFFAD1457,
  0xFF6A1B9A,
  0xFF4527A0,
  0xFF283593,
  0xFF1565C0,
  0xFF00838F,
  0xFF00695C,
  0xFF2E7D32,
  0xFF9E9D24,
  0xFFEF6C00,
  0xFF4E342E,
];

final RegExp _apostrophes = RegExp('[\'’]');
final RegExp _nonWord = RegExp('[^a-z0-9]+');
final RegExp _word = RegExp('[A-Za-z0-9]+(?:[\'’][A-Za-z0-9]+)*');
final RegExp _digit = RegExp('[0-9]');
final RegExp _mask = RegExp(r'^(?:x{2,}|x{3,}[a-z])$');
final RegExp _number = RegExp(
  r'^(?:[0-9x]*[0-9][0-9x]*[a-z]?|x{2,}|x{3,}[a-z])$',
);
final RegExp _whitespace = RegExp(r'\s+');

/// A word of a raw name: where it is, and its normalized [key].
typedef _Token = ({int start, int end, String key});

List<_Token> _tokens(String raw) => [
  for (final RegExpMatch m in _word.allMatches(raw))
    (start: m.start, end: m.end, key: normalizeMerchantText(m[0]!)),
];

/// The dictionary by normalized key, and the most words a key has.
final Map<String, MerchantEntry> _byKey = {
  for (final MerchantEntry entry in merchantDictionary)
    for (final String key in entry.keys) normalizeMerchantText(key): entry,
};
final int _maxKeyWords = _byKey.keys
    .map((k) => k.split(' ').length)
    .reduce((a, b) => a > b ? a : b);

MerchantEntry? _lookupAt(List<_Token> tokens, int i) {
  final int most = tokens.length - i < _maxKeyWords
      ? tokens.length - i
      : _maxKeyWords;
  for (int words = most; words > 0; words--) {
    final String key = [for (int j = i; j < i + words; j++) tokens[j].key]
        .join(' ');
    if (_byKey[key] case final MerchantEntry entry) return entry;
  }
  return null;
}

/// Leading words that say how a card was used, not where: matched longest first.
const List<List<String>> _noisePhrases = [
  ['purchase', 'authorized', 'on'],
  ['credit', 'card', 'purchase'],
  ['debit', 'card', 'purchase'],
  ['withdrawal', 'debit', 'card'],
  ['pos', 'purchase'],
  ['pos', 'pur'],
  ['purchase', 'sig'],
  ['card', 'purchase'],
  ['visa', 'purchase'],
  ['interac', 'purchase'],
  ['eft', 'debit'],
  ['consumer', 'debit'],
  ['debit', 'card'],
  ['sig', 'pur'],
  ['checkcard'],
  ['purchase'],
  ['withdrawal'],
  ['timestamp'],
  ['pos'],
];

/// Payment processors whose `*` precedes the merchant's own name (`SQ *BLUE BOTTLE`).
const Set<String> _processors = {
  'sq',
  'sqc',
  'tst',
  'sp',
  'dnh',
  'pp',
  'paypal',
  'py',
};

/// How many tokens of leading noise start at [i]: a number, masked digits, a processor
/// prefix, or one of [_noisePhrases]; 0 when token [i] is a word to keep.
int _noiseAt(String raw, List<_Token> tokens, int i) {
  final String key = tokens[i].key;
  if (_number.hasMatch(key)) return 1;
  if (_isProcessorAt(raw, tokens, i)) return 1;
  for (final List<String> phrase in _noisePhrases) {
    if (i + phrase.length > tokens.length) continue;
    bool matches = true;
    for (int j = 0; j < phrase.length && matches; j++) {
      matches = tokens[i + j].key == phrase[j];
    }
    if (matches) return phrase.length;
  }
  return 0;
}

bool _isProcessorAt(String raw, List<_Token> tokens, int i) =>
    _processors.contains(tokens[i].key) &&
    i + 1 < tokens.length &&
    raw.substring(tokens[i].end, tokens[i + 1].start).contains('*');

bool _hasDigitOrMask(String key) => key.contains(_digit) || _mask.hasMatch(key);

/// Whether the text between two words ends the merchant's name: a store number's `#`, a
/// processor's or reference's `*`, or a spaced dash before a location.
bool _separates(String gap) =>
    gap.contains('#') || gap.contains('*') || gap.contains(' - ');

String _collapse(String text) => text.trim().replaceAll(_whitespace, ' ');

String _titleCase(String text) => text
    .split(' ')
    .map(
      (w) => w.isEmpty || _keptUpper.contains(w.toUpperCase())
          ? w.toUpperCase()
          : w[0].toUpperCase() + w.substring(1).toLowerCase(),
    )
    .join(' ');

/// Words that stay in capitals when a name is title-cased: acronyms and company suffixes.
const Set<String> _keptUpper = {
  'ATM',
  'LLC',
  'INC',
  'LTD',
  'CO',
  'USA',
  'US',
  'UK',
  'DMV',
  'HOA',
  'IRS',
  'DBA',
};
