// The pure-Dart search (search_text.dart): its tokenizer equals the bundled SQLite's FTS5
// `unicode61 remove_diacritics 2` on every code point, and its terms match as FTS5's
// quoted prefix phrases. A failure of the first test after a sqlite3 upgrade means the
// table is stale: rerun `dart run tool/generate_unicode61_table.dart` in app/.
import 'package:finance_tracker/features/transactions/domain/search_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('tokenizes every code point as the bundled FTS5 does', () {
    final Database db = sqlite3.openInMemory();
    addTearDown(db.close);
    db.execute(
      "CREATE VIRTUAL TABLE f USING fts5(x, tokenize = 'unicode61 remove_diacritics 2')",
    );
    db.execute("CREATE VIRTUAL TABLE v USING fts5vocab(f, 'instance')");
    db.execute('BEGIN');
    final PreparedStatement insert = db.prepare(
      'INSERT INTO f(rowid, x) VALUES (?, ?)',
    );
    for (int cp = 1; cp <= 0x10FFFF; cp++) {
      if (cp >= 0xD800 && cp <= 0xDFFF) continue;
      insert.execute([cp, 'q${String.fromCharCode(cp)}z']);
    }
    insert.close();
    db.execute('COMMIT');
    final Map<int, List<String>> sqlite = {};
    for (final Row row in db.select(
      'SELECT doc, term FROM v ORDER BY doc, "offset"',
    )) {
      (sqlite[row['doc'] as int] ??= []).add(row['term'] as String);
    }
    final List<String> differences = [];
    for (int cp = 1; cp <= 0x10FFFF; cp++) {
      if (cp >= 0xD800 && cp <= 0xDFFF) continue;
      final List<String> dart = searchTokens('q${String.fromCharCode(cp)}z');
      if (!_same(dart, sqlite[cp]!)) {
        differences.add('U+${cp.toRadixString(16)}: $dart, FTS5 ${sqlite[cp]}');
      }
    }
    expect(differences.take(20), isEmpty);
  });

  test('splits terms on whitespace', () {
    expect(searchTerms('  corner\tgrocer \n'), ['corner', 'grocer']);
    expect(searchTerms('   '), isEmpty);
  });

  test('folds case and Latin diacritics, and only those', () {
    expect(searchTokens("Crème Brûlée, Zoë's"), [
      'creme',
      'brulee',
      'zoe',
      's',
    ]);
    expect(searchTokens('İstanbul ΆΘΗΝΑ Straße'), [
      'istanbul',
      'άθηνα',
      'straße',
    ]);
    expect(searchTokens('café'), ['cafe']);
  });

  test('a term is a phrase of its tokens, the last a prefix', () {
    bool matches(String text, String field) =>
        matchesSearch(searchTerms(text), [field]);
    expect(matches("o'bri", "Dinner at O'Brien's"), isTrue);
    expect(matches("o'bri", 'Brien O Dinner'), isFalse);
    expect(matches('rien', "O'Brien"), isFalse);
    expect(matches('corner groc', 'Grocer on the corner'), isTrue);
    expect(matches('--', 'anything --'), isFalse);
  });

  test('a phrase never spans two fields', () {
    expect(matchesSearch(['corner-grocer'], ['corner', 'grocer']), isFalse);
    expect(matchesSearch(['corner', 'grocer'], ['corner', 'grocer']), isTrue);
  });
}

bool _same(List<String> a, List<String> b) =>
    a.length == b.length &&
    [for (int i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);
