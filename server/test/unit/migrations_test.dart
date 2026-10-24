import 'package:finance_tracker_server/src/db/migrations.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('an empty database migrates to the current schema', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    migrate(db);
    final versions = db.select(
      'SELECT version FROM schema_migrations ORDER BY version',
    );
    expect(
      [for (final r in versions) r['version']],
      [for (var v = 1; v <= migrations.length; v++) v],
    );
    final tables = {
      for (final r in db.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        r['name'],
    };
    expect(
      tables,
      containsAll([
        'users',
        'devices',
        'refresh_tokens',
        'items',
        'accounts',
        'transactions',
        'recurring_streams',
        'securities',
        'holdings',
        'investment_transactions',
        'liabilities',
        'change_log',
        'user_versions',
      ]),
    );
  });

  test('a rerun applies nothing', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    migrate(db);
    db.execute("INSERT INTO users VALUES ('u', 'a@b.test', 'h', 'a', 0)");
    migrate(db);
    expect(
      db.select('SELECT COUNT(*) AS n FROM schema_migrations').first['n'],
      migrations.length,
    );
    expect(db.select('SELECT COUNT(*) AS n FROM users').first['n'], 1);
  });

  test('a database newer than the server is refused', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    migrate(db);
    db.execute('INSERT INTO schema_migrations VALUES (?, 0)', [
      migrations.length + 1,
    ]);
    expect(() => migrate(db), throwsA(isA<SchemaTooNewException>()));
  });

  test("every table's rows reach users through ON DELETE CASCADE", () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    migrate(db);
    final tables = [
      for (final r in db.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT IN ('users', 'schema_migrations', 'sqlite_sequence')",
      ))
        r['name'] as String,
    ];
    for (final table in tables) {
      final keys = db.select('PRAGMA foreign_key_list($table)');
      expect(
        keys.where((k) => k['on_delete'] == 'CASCADE'),
        isNotEmpty,
        reason: '$table has no cascading foreign key',
      );
    }
  });
}
