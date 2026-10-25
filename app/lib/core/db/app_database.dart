/// The local database: the Drift schema, its version and its migrations
/// (`docs/reference/data.md`).
///
/// Schema 1 has the accounts, transactions (with their tags and splits) and categories,
/// the app settings and the install's metadata. Schema 2 adds the sync state: the
/// outbox (`change_log`), the field clocks (`record_clocks`), the device's sync facts
/// (`sync_meta`) and the records the entity tables cannot hold yet (`held_records`); its
/// migration backfills the change log from the existing rows (`sync_backfill.dart`).
/// Schema 3 adds the user's Plaid Items (`items`), which the Plaid pull fills; its
/// migration creates the empty table. Schema 4 adds the user's rules (`rules`); its
/// migration also materializes the rule records sync held before this version could
/// store them. Schema 5 adds the user's budgets (`budgets`) and the alerts this device
/// raised for them (`budget_alerts`, local only); its migration materializes the budget
/// records sync held. Schema 6 adds `transactions.hidden`, the user's hidden override; its
/// column is added before every other step, so the schema 2 backfill and the later steps
/// read the transactions as this version declares them, and its migration materializes
/// the transaction records sync held for a field this version now stores. Every schema
/// change follows the procedure
/// in `data.md`, every step idempotent: Drift runs `onUpgrade` outside a transaction and
/// writes the new version only after it returns, so a step that fails or an app killed
/// mid-upgrade runs every step again at the old version on the next open. Tables are
/// created `IF NOT EXISTS`, indexes and columns only when missing, the backfill only
/// when its tables are, and releases find nothing the second time: bump [AppDatabase.schemaVersion], write the step in `onUpgrade`, dump the
/// schema, regenerate the test helpers, and add the migration test. How the file is found,
/// keyed and opened is `open_database.dart`; this file stays free of Flutter so the schema
/// dump can run it in the Dart VM.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/sync_backfill.dart';
import 'package:finance_tracker/core/db/tables/accounts.dart';
import 'package:finance_tracker/core/db/tables/app_meta.dart';
import 'package:finance_tracker/core/db/tables/app_settings.dart';
import 'package:finance_tracker/core/db/tables/budget_alerts.dart';
import 'package:finance_tracker/core/db/tables/budgets.dart';
import 'package:finance_tracker/core/db/tables/categories.dart';
import 'package:finance_tracker/core/db/tables/change_log.dart';
import 'package:finance_tracker/core/db/tables/held_records.dart';
import 'package:finance_tracker/core/db/tables/items.dart';
import 'package:finance_tracker/core/db/tables/record_clocks.dart';
import 'package:finance_tracker/core/db/tables/rules.dart';
import 'package:finance_tracker/core/db/tables/sync_meta.dart';
import 'package:finance_tracker/core/db/tables/transaction_splits.dart';
import 'package:finance_tracker/core/db/tables/transaction_tags.dart';
import 'package:finance_tracker/core/db/tables/transactions.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

final Logger _log = Logger('db');

/// The app's database over [executor]. [logEncryption] (dev only) logs the cipher and the
/// SQLite3 Multiple Ciphers version once the database is open. [wallMillis] and
/// [newNodeId] are the wall clock and the provisional sync node of the schema 2 backfill
/// (the system clock and `local-<uuid v4>` unless a test pins them).
@DriftDatabase(
  tables: [
    Accounts,
    Transactions,
    TransactionTags,
    TransactionSplits,
    Categories,
    AppSettings,
    AppMeta,
    ChangeLog,
    RecordClocks,
    SyncMeta,
    HeldRecords,
    Items,
    Rules,
    Budgets,
    BudgetAlerts,
  ],
)
final class AppDatabase extends _$AppDatabase {
  /// A database over [executor].
  AppDatabase(
    super.executor, {
    this.logEncryption = false,
    this.wallMillis = _systemWallMillis,
    this.newNodeId = provisionalNodeId,
  });

  /// Whether `beforeOpen` logs the cipher in use.
  final bool logEncryption;

  /// The wall clock, UTC milliseconds, the migrations stamp with.
  final int Function() wallMillis;

  /// The provisional sync node of a database migrated from schema 1.
  final String Function() newNodeId;

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from > to) {
        throw StateError('No migration from schema $from to $to');
      }
      if (from < 6 && !await _hasColumn('transactions', 'hidden')) {
        // First: every later step (the schema 2 backfill included) reads transactions
        // through this version's table, which has the column.
        await m.addColumn(transactions, transactions.hidden);
      }
      // The change log's presence means this step committed: its tables and the
      // backfill land in one transaction, and the backfill must not run twice.
      if (from < 2 && !await _exists('table', 'change_log')) {
        // One transaction: the tables and the backfill land together or not at all.
        await transaction(() async {
          await m.createTable(changeLog);
          await m.createTable(recordClocks);
          await m.createTable(syncMeta);
          await m.createTable(heldRecords);
          await _createIndex(m, changeLogOutbox);
          await _createIndex(m, recordClocksHlc);
          await backfillChangeLog(
            this,
            nodeId: newNodeId(),
            wallMillis: wallMillis,
          );
        });
      }
      if (from < 3) {
        await m.createTable(items);
      }
      if (from < 4) {
        await transaction(() async {
          await m.createTable(rules);
          await _createIndex(m, rulesPosition);
          await releaseHeldRecords(
            DriftSyncStore(this, _WallClock(wallMillis)),
            EntityType.rule,
          );
        });
      }
      if (from < 5) {
        await transaction(() async {
          await m.createTable(budgets);
          await _createIndex(m, budgetsCategory);
          await m.createTable(budgetAlerts);
          await releaseHeldRecords(
            DriftSyncStore(this, _WallClock(wallMillis)),
            EntityType.budget,
          );
        });
      }
      if (from < 6) {
        // A newer device's hidden override was held as an unknown field; it now lands.
        await transaction(
          () => releaseHeldRecords(
            DriftSyncStore(this, _WallClock(wallMillis)),
            EntityType.transaction,
          ),
        );
      }
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

  // Whether the schema has the [type] (`table`, `index`) named [name].
  Future<bool> _exists(String type, String name) async => (await customSelect(
    'SELECT 1 FROM sqlite_master WHERE type = ? AND name = ?',
    variables: [Variable.withString(type), Variable.withString(name)],
  ).get()).isNotEmpty;

  // Whether [table] has [column].
  Future<bool> _hasColumn(String table, String column) async =>
      (await customSelect(
        'PRAGMA table_info($table)',
      ).get()).any((row) => row.read<String>('name') == column);

  // Creates [index] unless a run of the migration that did not finish already did.
  Future<void> _createIndex(Migrator m, Index index) async {
    if (!await _exists('index', index.entityName)) await m.createIndex(index);
  }

  /// Opens the database now (running the open sequence and any migration), so a failure
  /// to open surfaces here rather than in the first screen's query.
  Future<void> verifyOpen() => customSelect('SELECT 1').get();
}

/// A provisional sync node, `local-<uuid v4>`, until the server's device id replaces it
/// (`docs/reference/sync-app.md`, **The device's node**).
String provisionalNodeId() => 'local-${const Uuid().v4()}';

int _systemWallMillis() => DateTime.now().millisecondsSinceEpoch;

/// Writes again every record of [type] that [store] holds, so the ones a new table can
/// now store (records pulled before this version had it, held as `unsupported_type`)
/// become rows and stop being held; the rest stay held, for the reason that applies now.
Future<void> releaseHeldRecords(DriftSyncStore store, EntityType type) async =>
    store.materializeHeld(type, await store.heldIds(type));

// The migrations' clock: only "now", from the database's wall clock.
final class _WallClock implements Clock {
  _WallClock(this._wallMillis);

  final int Function() _wallMillis;

  @override
  DateTime nowUtc() =>
      DateTime.fromMillisecondsSinceEpoch(_wallMillis(), isUtc: true);

  @override
  DateTime todayLocalMidnight() => throw UnsupportedError('no zone here');

  @override
  LocalDate today() => throw UnsupportedError('no zone here');

  @override
  tz.Location get location => throw UnsupportedError('no zone here');
}
