// The full-text index's oracle (data.md, **Full-text search**): the view, the key table
// and the FTS5 table agree both ways, column by column, and FTS5's integrity-check passes.
import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/full_text_search.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expects the index of [database] to hold exactly the view's rows, each at its key's
/// rowid, with one key per transaction.
Future<void> expectIndexMatchesView(AppDatabase database) async {
  Future<List<Map<String, Object?>>> rows(String sql) async => [
    for (final QueryRow row in await database.customSelect(sql).get()) row.data,
  ];
  final List<Map<String, Object?>> view = await rows(
    'SELECT id, name, merchant_name, notes, tags FROM $ftsSourceView ORDER BY id',
  );
  final List<Map<String, Object?>> keys = await rows(
    'SELECT transaction_id, fts_rowid FROM $ftsKeysTable ORDER BY transaction_id',
  );
  final List<Map<String, Object?>> indexed = await rows(
    'SELECT transaction_id AS id, name, merchant_name, notes, tags, rowid AS fts_rowid '
    'FROM $ftsTable ORDER BY transaction_id',
  );
  expect(
    [for (final k in keys) k['transaction_id']],
    [for (final v in view) v['id']],
    reason: 'one key per transaction, and no other',
  );
  expect(
    [
      for (final r in indexed) {...r}..remove('fts_rowid'),
    ],
    view,
    reason: 'the index holds the view, every column, both ways',
  );
  expect(
    [for (final r in indexed) r['fts_rowid']],
    [for (final k in keys) k['fts_rowid']],
    reason: "each row sits at its key's rowid",
  );
  await database.customStatement(
    "INSERT INTO $ftsTable($ftsTable, rank) VALUES ('integrity-check', 1)",
  );
}

/// The full-text objects of [database] as `sqlite_master` holds them, by name.
Future<Map<String, String>> fullTextObjects(AppDatabase database) async => {
  for (final QueryRow row
      in await database
          .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE name IN ('$ftsSourceView', "
            "'$ftsKeysTable', '$ftsTable', ${ftsTriggers.map((t) => "'$t'").join(', ')})",
          )
          .get())
    row.read<String>('name'): row.read<String>('sql'),
};
