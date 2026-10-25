/// The full-text index over transactions (`docs/reference/data.md`, **Full-text
/// search**): an FTS5 table of each transaction's name, merchant name, notes and tags,
/// kept current by triggers. Free of Flutter, like `app_database.dart`.
///
/// The objects are created with SQL, not declared to Drift, because they exist only when
/// the bundled SQLite has FTS5 (checked at every open, [fullTextSearchCompiled]):
///
/// - `transactions_fts_source`, a view of each transaction's text by `id`, the tags
///   joined by spaces in list order;
/// - `transactions_fts_keys`, each transaction's FTS rowid, an explicit INTEGER PRIMARY
///   KEY, so `VACUUM` keeps it (the implicit rowid of `transactions` it may renumber);
/// - `transactions_fts`, a standalone FTS5 table (`unicode61 remove_diacritics 2`) of the
///   four columns and `transaction_id UNINDEXED`, each row at its key's rowid;
/// - AFTER triggers by id on `transactions` (insert, update of the three text columns,
///   delete) and on `transaction_tags` (insert, delete), which delete the transaction's
///   FTS row through its key and insert it again from the view.
///
/// [ensureFullTextSearch] runs in `beforeOpen`: with FTS5, when an object is missing or
/// `app_meta.fts_definition` is not [ftsDefinitionVersion], it drops the objects, creates
/// them and rebuilds the index from the view, in one transaction; without it, it drops
/// the triggers a build with FTS5 left (writes would fail with "no such module: fts5").
/// Changing any statement here means bumping [ftsDefinitionVersion], so databases built
/// with the old definition are rebuilt with the new one at their next open.
library;

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('db');

/// The FTS5 table's name.
const String ftsTable = 'transactions_fts';

/// The view of each transaction's text.
const String ftsSourceView = 'transactions_fts_source';

/// The version of the statements below; bump it with any change to them.
const int ftsDefinitionVersion = 1;

/// The `app_meta` key holding the [ftsDefinitionVersion] the index was built with.
const String ftsDefinitionKey = 'fts_definition';

/// The table of each transaction's FTS rowid.
const String ftsKeysTable = 'transactions_fts_keys';

/// The triggers that keep the index current, by name.
const List<String> ftsTriggers = [
  'transactions_fts_insert',
  'transactions_fts_update',
  'transactions_fts_delete',
  'transaction_tags_fts_insert',
  'transaction_tags_fts_delete',
];

// The FTS row of transaction [id] (an SQL expression), deleted and inserted from the view.
String _deleteRow(String id) =>
    'DELETE FROM $ftsTable WHERE rowid = '
    '(SELECT fts_rowid FROM $ftsKeysTable WHERE transaction_id = $id);';

String _insertRow(String id) =>
    'INSERT INTO $ftsTable(rowid, name, merchant_name, notes, tags, transaction_id) '
    'SELECT k.fts_rowid, s.name, s.merchant_name, s.notes, s.tags, s.id '
    'FROM $ftsSourceView s JOIN $ftsKeysTable k ON k.transaction_id = s.id '
    'WHERE s.id = $id;';

/// The statements that create the objects, in order.
final List<String> ftsCreateStatements = [
  'CREATE VIEW $ftsSourceView AS SELECT t.id AS id, t.name AS name, '
      't.merchant_name AS merchant_name, t.notes AS notes, '
      "(SELECT group_concat(g.tag, ' ' ORDER BY g.position) FROM transaction_tags g "
      'WHERE g.transaction_id = t.id) AS tags FROM transactions t',
  'CREATE TABLE $ftsKeysTable (fts_rowid INTEGER PRIMARY KEY, '
      'transaction_id TEXT NOT NULL UNIQUE)',
  'CREATE VIRTUAL TABLE $ftsTable USING fts5(name, merchant_name, notes, tags, '
      "transaction_id UNINDEXED, tokenize = 'unicode61 remove_diacritics 2')",
  'CREATE TRIGGER transactions_fts_insert AFTER INSERT ON transactions BEGIN '
      'INSERT INTO $ftsKeysTable(transaction_id) VALUES (new.id) '
      'ON CONFLICT DO NOTHING; ${_insertRow('new.id')} END',
  'CREATE TRIGGER transactions_fts_update '
      'AFTER UPDATE OF name, merchant_name, notes ON transactions BEGIN '
      '${_deleteRow('old.id')} ${_insertRow('new.id')} END',
  'CREATE TRIGGER transactions_fts_delete AFTER DELETE ON transactions BEGIN '
      '${_deleteRow('old.id')} '
      'DELETE FROM $ftsKeysTable WHERE transaction_id = old.id; END',
  'CREATE TRIGGER transaction_tags_fts_insert AFTER INSERT ON transaction_tags BEGIN '
      '${_deleteRow('new.transaction_id')} ${_insertRow('new.transaction_id')} END',
  'CREATE TRIGGER transaction_tags_fts_delete AFTER DELETE ON transaction_tags BEGIN '
      '${_deleteRow('old.transaction_id')} ${_insertRow('old.transaction_id')} END',
];

/// Whether the SQLite under [db] has FTS5 compiled in.
Future<bool> fullTextSearchCompiled(DatabaseConnectionUser db) async =>
    (await db
            .customSelect(
              "SELECT sqlite_compileoption_used('ENABLE_FTS5') AS fts5",
            )
            .getSingle())
        .read<int>('fts5') ==
    1;

/// Makes the index match [available]. With FTS5: when any object is missing or the stored
/// definition version is not [ftsDefinitionVersion], drops the rest and creates them all,
/// rebuilds the index ([rebuildFullTextSearch]) and stores the version, in one
/// transaction. Without it: drops the triggers, leaving the table inert.
Future<void> ensureFullTextSearch(
  DatabaseConnectionUser db, {
  required bool available,
}) async {
  final Set<String> present = {
    for (final QueryRow row
        in await db
            .customSelect(
              'SELECT name FROM sqlite_master WHERE name IN '
              '(${List.filled(ftsTriggers.length + 3, '?').join(', ')})',
              variables: [
                for (final String name in [
                  ftsSourceView,
                  ftsKeysTable,
                  ftsTable,
                  ...ftsTriggers,
                ])
                  Variable.withString(name),
              ],
            )
            .get())
      row.read<String>('name'),
  };
  if (!available) {
    if (!ftsTriggers.any(present.contains)) return;
    for (final String trigger in ftsTriggers) {
      await db.customStatement('DROP TRIGGER IF EXISTS $trigger');
    }
    _log.warning('SQLite has no FTS5: the full-text triggers are dropped');
    return;
  }
  final QueryRow? stored = await db
      .customSelect(
        'SELECT value FROM app_meta WHERE key = ?',
        variables: [Variable.withString(ftsDefinitionKey)],
      )
      .getSingleOrNull();
  if (present.length == ftsTriggers.length + 3 &&
      stored?.read<String>('value') == '$ftsDefinitionVersion') {
    return;
  }
  await db.transaction(() async {
    for (final String trigger in ftsTriggers) {
      await db.customStatement('DROP TRIGGER IF EXISTS $trigger');
    }
    await db.customStatement('DROP TABLE IF EXISTS $ftsTable');
    await db.customStatement('DROP TABLE IF EXISTS $ftsKeysTable');
    await db.customStatement('DROP VIEW IF EXISTS $ftsSourceView');
    for (final String statement in ftsCreateStatements) {
      await db.customStatement(statement);
    }
    await rebuildFullTextSearch(db);
    await db.customStatement(
      'INSERT INTO app_meta (key, value) VALUES (?, ?) '
      'ON CONFLICT (key) DO UPDATE SET value = excluded.value',
      [ftsDefinitionKey, '$ftsDefinitionVersion'],
    );
  });
}

/// Empties the key table and the index and fills both again from the view, inside the
/// caller's transaction.
Future<void> rebuildFullTextSearch(DatabaseConnectionUser db) async {
  await db.customStatement('DELETE FROM $ftsTable');
  await db.customStatement('DELETE FROM $ftsKeysTable');
  await db.customStatement(
    'INSERT INTO $ftsKeysTable(transaction_id) SELECT id FROM transactions',
  );
  await db.customStatement(
    'INSERT INTO $ftsTable(rowid, name, merchant_name, notes, tags, transaction_id) '
    'SELECT k.fts_rowid, s.name, s.merchant_name, s.notes, s.tags, s.id '
    'FROM $ftsSourceView s JOIN $ftsKeysTable k ON k.transaction_id = s.id',
  );
}
