/// Title case for the names Plaid gives in English and the app has no translation of
/// (a security type such as `mutual_fund`), in a file of its own so the strings check's
/// allowlist names only this join of words (`tools/check_strings_allowlist.txt`).
library;

/// [text]'s words with their first letters in upper case, joined by single spaces
/// (`mutual fund` and `mutual_fund` give "Mutual Fund").
String titleCase(String text) => [
  for (final String word in text.trim().split(RegExp(r'[\s_]+')))
    if (word.isNotEmpty) word[0].toUpperCase() + word.substring(1),
].join(' ');
