/// The local database: the Drift schema, its version and its migrations
/// (`docs/reference/data.md`).
///
/// Schema 1 has the accounts, transactions (with their tags and splits) and categories,
/// the app settings and the install's metadata. Every schema change follows the procedure
/// in `data.md`: bump [AppDatabase.schemaVersion], write the step in `onUpgrade`, dump the
/// schema, regenerate the test helpers, and add the migration test. How the file is found,
/// keyed and opened is `open_database.dart`; this file stays free of Flutter so the schema
/// dump can run it in the Dart VM.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:finance_tracker/core/db/tables/accounts.dart';
import 'package:finance_tracker/core/db/tables/app_meta.dart';
import 'package:finance_tracker/core/db/tables/app_settings.dart';
import 'package:finance_tracker/core/db/tables/categories.dart';
import 'package:finance_tracker/core/db/tables/transaction_splits.dart';
import 'package:finance_tracker/core/db/tables/transaction_tags.dart';
import 'package:finance_tracker/core/db/tables/transactions.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';

part 'app_database.g.dart';

final Logger _log = Logger('db');

/// The app's database over [executor]. [logEncryption] (dev only) logs the cipher and the
/// SQLite3 Multiple Ciphers version once the database is open.
@DriftDatabase(
  tables: [
    Accounts,
    Transactions,
    TransactionTags,
    TransactionSplits,
    Categories,
    AppSettings,
    AppMeta,
  ],
)
final class AppDatabase extends _$AppDatabase {
  /// A database over [executor].
  AppDatabase(super.executor, {this.logEncryption = false});

  /// Whether `beforeOpen` logs the cipher in use.
  final bool logEncryption;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Schema 1 is the first; each later version adds its step here (data.md).
      throw StateError('No migration from schema $from to $to');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (logEncryption) {
        // Two statements: sqlite3mc's PRAGMA cipher has no table-valued form.
        final QueryRow? cipher = await customSelect('PRAGMA cipher')
            .getSingleOrNull();
        final QueryRow version = await customSelect(
          'SELECT sqlite3mc_version() AS version',
        ).getSingle();
        _log.info(
          'database cipher ${cipher?.data.values.single}, '
          '${version.read<String>('version')}',
        );
      }
    },
  );

  /// Opens the database now (running the open sequence and any migration), so a failure
  /// to open surfaces here rather than in the first screen's query.
  Future<void> verifyOpen() => customSelect('SELECT 1').get();
}
