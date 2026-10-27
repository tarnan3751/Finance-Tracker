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

  test('a v1 database with an Item migrates to v2 and keeps it', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    db.execute(
      'CREATE TABLE schema_migrations ('
      'version INTEGER PRIMARY KEY, applied_at INTEGER NOT NULL)',
    );
    db.execute(migrations[0]);
    db.execute('INSERT INTO schema_migrations VALUES (1, 0)');
    db.execute("INSERT INTO users VALUES ('u', 'a@b.test', 'h', 'a', 0)");
    db.execute(
      'INSERT INTO items (id, user_id, plaid_item_id, institution_id, '
      'institution_name, products, access_token_ciphertext, access_token_nonce, '
      "status, created_at) VALUES ('i', 'u', 'p', 'ins_1', 'Bank', '[]', "
      "x'00', x'00', 'healthy', 0)",
    );
    migrate(db);
    final item = db.select('SELECT * FROM items').single;
    expect(item['id'], 'i');
    expect(item['status'], 'healthy');
    expect(item['error_code'], isNull);
    expect(item['institution_logo'], isNull);
    expect(item['institution_primary_color'], isNull);
    expect(
      db.select('SELECT MAX(version) AS v FROM schema_migrations').first['v'],
      migrations.length,
    );
  });

  test('a v2 database with an Item migrates to v3 and keeps it', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    db.execute(
      'CREATE TABLE schema_migrations ('
      'version INTEGER PRIMARY KEY, applied_at INTEGER NOT NULL)',
    );
    db.execute(migrations[0]);
    db.execute(migrations[1]);
    db.execute('INSERT INTO schema_migrations VALUES (1, 0), (2, 0)');
    db.execute("INSERT INTO users VALUES ('u', 'a@b.test', 'h', 'a', 0)");
    db.execute(
      'INSERT INTO items (id, user_id, plaid_item_id, institution_id, '
      'institution_name, products, access_token_ciphertext, access_token_nonce, '
      'status, error_code, institution_primary_color, cursor, created_at) '
      "VALUES ('i', 'u', 'p', 'ins_1', 'Bank', '[\"investments\"]', x'00', "
      "x'00', 'login_required', 'ITEM_LOGIN_REQUIRED', 4278220195, 'c1', 0)",
    );
    migrate(db);
    final item = db.select('SELECT * FROM items').single;
    expect(item['id'], 'i');
    expect(item['status'], 'login_required');
    expect(item['error_code'], 'ITEM_LOGIN_REQUIRED');
    expect(item['institution_primary_color'], 0xFF0075A3);
    expect(item['cursor'], 'c1');
    expect(item['investments_synced_at'], isNull);
    expect(
      db.select('SELECT MAX(version) AS v FROM schema_migrations').first['v'],
      migrations.length,
    );
  });

  test(
    'a v3 database with a recurring stream migrates to v4 with no members',
    () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      db.execute(
        'CREATE TABLE schema_migrations ('
        'version INTEGER PRIMARY KEY, applied_at INTEGER NOT NULL)',
      );
      for (var v = 0; v < 3; v++) {
        db.execute(migrations[v]);
      }
      db.execute('INSERT INTO schema_migrations VALUES (1, 0), (2, 0), (3, 0)');
      db.execute("INSERT INTO users VALUES ('u', 'a@b.test', 'h', 'a', 0)");
      db.execute(
        'INSERT INTO items (id, user_id, plaid_item_id, institution_id, '
        'institution_name, products, access_token_ciphertext, access_token_nonce, '
        "status, created_at) VALUES ('i', 'u', 'p', 'ins_1', 'Bank', '[]', "
        "x'00', x'00', 'healthy', 0)",
      );
      db.execute(
        'INSERT INTO recurring_streams (id, user_id, item_id, plaid_stream_id, '
        'account_id, merchant_name, cadence, average_amount_minor, currency, '
        'last_date, next_date, status, is_subscription, source) VALUES '
        "('s', 'u', 'i', 'ps', 'a', 'Netflix', 'monthly', -1549, 'USD', "
        "'2026-10-01', '2026-11-01', 'active', 0, 'demo')",
      );
      migrate(db);
      final stream = db.select('SELECT * FROM recurring_streams').single;
      expect(stream['merchant_name'], 'Netflix');
      expect(stream['plaid_transaction_ids'], '[]');
      expect(
        db.select('SELECT MAX(version) AS v FROM schema_migrations').first['v'],
        4,
      );
    },
  );

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
