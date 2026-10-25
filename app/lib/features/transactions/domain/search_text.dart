/// The transaction search's semantics in pure Dart (`docs/reference/transactions.md`,
/// **Search**): what FTS5 does with `TransactionQuery.text` over the `unicode61
/// remove_diacritics 2` index, so the in-memory repositories match as the Drift one does.
///
/// The text is split into terms on whitespace. Each term is tokenized as the index is
/// ([searchTokens]: runs of token characters, case and Latin diacritics folded by the
/// table generated from SQLite, `unicode61_table.dart`) and matches a field holding its
/// tokens in a row, the last one as a prefix: FTS5's `"<term>"*`. A term with no token
/// characters (only punctuation, say) matches nothing. Every term must match, each in
/// any of the fields.
library;

import 'package:finance_tracker/features/transactions/domain/unicode61_table.dart';

/// The whitespace-separated terms of [text]; empty when it has none.
List<String> searchTerms(String text) => [
  for (final String term in text.split(RegExp(r'\s+')))
    if (term.isNotEmpty) term,
];

/// The tokens the index makes of [text].
List<String> searchTokens(String text) {
  final List<String> tokens = [];
  final StringBuffer token = StringBuffer();
  for (int cp in text.runes) {
    // A lone surrogate reaches SQLite as U+FFFD (UTF-8 has no surrogates).
    if (cp >= 0xD800 && cp <= 0xDFFF) cp = 0xFFFD;
    if (_separates(cp)) {
      if (token.isNotEmpty) tokens.add(token.toString());
      token.clear();
      continue;
    }
    final int folded = unicode61Folds[cp] ?? cp;
    if (folded != 0) token.writeCharCode(folded);
  }
  if (token.isNotEmpty) tokens.add(token.toString());
  return tokens;
}

/// Whether every one of [terms] matches one of [fields] (null fields hold nothing). No
/// term matches nothing.
bool matchesSearch(List<String> terms, Iterable<String?> fields) {
  final List<List<String>> fieldTokens = [
    for (final String? field in fields)
      if (field != null) searchTokens(field),
  ];
  for (final String term in terms) {
    final List<String> phrase = searchTokens(term);
    if (phrase.isEmpty ||
        !fieldTokens.any((tokens) => _containsPhrase(tokens, phrase))) {
      return false;
    }
  }
  return terms.isNotEmpty;
}

// Whether [tokens] holds [phrase] in a row, its last token as a prefix.
bool _containsPhrase(List<String> tokens, List<String> phrase) {
  for (int i = 0; i + phrase.length <= tokens.length; i++) {
    int j = 0;
    while (j < phrase.length - 1 && tokens[i + j] == phrase[j]) {
      j++;
    }
    if (j == phrase.length - 1 && tokens[i + j].startsWith(phrase[j])) {
      return true;
    }
  }
  return false;
}

// Whether [cp] separates tokens: a binary search of the separator ranges.
bool _separates(int cp) {
  int low = 0;
  int high = unicode61Separators.length ~/ 2 - 1;
  while (low <= high) {
    final int mid = (low + high) >> 1;
    if (cp < unicode61Separators[2 * mid]) {
      high = mid - 1;
    } else if (cp > unicode61Separators[2 * mid + 1]) {
      low = mid + 1;
    } else {
      return true;
    }
  }
  return false;
}
