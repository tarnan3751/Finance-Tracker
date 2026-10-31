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
/// the transaction records sync held for a field this version now stores. Schema 7 adds
/// the duplicate pairs the user dismissed (`dismissed_pairs`), local to the device; its
/// migration creates the empty table. Schema 8 adds the transaction list's saved filters
/// (`saved_filters`, local to the device). Schema 9 adds the recurring streams
/// (`recurring_streams`, the server's and the detector's, never recorded), the user's
/// choices about them (`stream_overrides`, synced as the `recurring_stream` record) and
/// the liabilities (`liabilities`, server-authoritative); its migration materializes the
/// `recurring_stream` records sync held. Schema 10 adds the user's bills (`bills`, synced
/// as the `bill_reminder` record, the paid occurrences a field of it) and the bill
/// notifications this device raised (`bill_alerts`, local only); its migration
/// materializes the `bill_reminder` records sync held. Schema 11 adds the linked
/// investment accounts' securities, holdings and investment transactions (`securities`,
/// `holdings`, `investment_transactions`, server-authoritative) and the daily balance
/// snapshots this device observes (`balance_snapshots`, local only); its migration
/// creates the empty tables. Schema 12 adds the user's savings goals (`goals`, synced as the
/// `goal` record) and their contributions (`goal_contributions`, each synced as a
/// `goal_contribution` record of its own); its migration materializes the records of
/// both that sync held. The full-text index (`full_text_search.dart`)
/// is not part of a schema step: `beforeOpen` makes it match whether the bundled SQLite
/// has FTS5, at every open, and records that in [AppDatabase.fullTextSearch]. Every
/// schema change follows the procedure
/// in `data.md`, every step idempotent: Drift runs `onUpgrade` outside a transaction and
/// writes the new version only after it returns, so a step that fails or an app killed
/// mid-upgrade runs every step again at the old version on the next open. Tables are
/// created `IF NOT EXISTS`, indexes and columns only when missing, the backfill only
/// when its tables are, and releases find nothing the second time: bump [AppDatabase.schemaVersion], write the step in `onUpgrade`, dump the
/// schema, regenerate the test helpers, and add the migration test. How the file is found,
/// keyed and opened is `open_database.dart`; this file stays free of Flutter so the schema
/// dump can run it in the Dart VM.
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/full_text_search.dart';
import 'package:finance_tracker/core/db/sync_backfill.dart';
import 'package:finance_tracker/core/db/tables/accounts.dart';
import 'package:finance_tracker/core/db/tables/app_meta.dart';
import 'package:finance_tracker/core/db/tables/app_settings.dart';
import 'package:finance_tracker/core/db/tables/balance_snapshots.dart';
import 'package:finance_tracker/core/db/tables/bill_alerts.dart';
import 'package:finance_tracker/core/db/tables/bills.dart';
import 'package:finance_tracker/core/db/tables/budget_alerts.dart';
import 'package:finance_tracker/core/db/tables/budgets.dart';
import 'package:finance_tracker/core/db/tables/categories.dart';
import 'package:finance_tracker/core/db/tables/change_log.dart';
import 'package:finance_tracker/core/db/tables/conflicts.dart';
import 'package:finance_tracker/core/db/tables/dismissed_pairs.dart';
import 'package:finance_tracker/core/db/tables/goal_contributions.dart';
import 'package:finance_tracker/core/db/tables/goals.dart';
import 'package:finance_tracker/core/db/tables/held_records.dart';
import 'package:finance_tracker/core/db/tables/holdings.dart';
import 'package:finance_tracker/core/db/tables/investment_transactions.dart';
import 'package:finance_tracker/core/db/tables/items.dart';
import 'package:finance_tracker/core/db/tables/liabilities.dart';
import 'package:finance_tracker/core/db/tables/record_clocks.dart';
import 'package:finance_tracker/core/db/tables/recurring_streams.dart';
import 'package:finance_tracker/core/db/tables/rules.dart';
import 'package:finance_tracker/core/db/tables/saved_filters.dart';
import 'package:finance_tracker/core/db/tables/securities.dart';
import 'package:finance_tracker/core/db/tables/stream_overrides.dart';
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
/// (the system clock and `local-<uuid v4>` unless a test pins them). [allowFullTextSearch]
/// false opens as if SQLite had no FTS5, for the tests of that path only.
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
    DismissedPairs,
    SavedFilters,
    RecurringStreams,
    StreamOverrides,
    Liabilities,
    Bills,
    BillAlerts,
    Securities,
    Holdings,
    InvestmentTransactions,
    BalanceSnapshots,
    Goals,
    GoalContributions,
    Conflicts,
  ],
)
final class AppDatabase extends _$AppDatabase {
  /// A database over [executor].
  AppDatabase(
    super.executor, {
    this.logEncryption = false,
    this.wallMillis = _systemWallMillis,
    this.newNodeId = provisionalNodeId,
    this.allowFullTextSearch = true,
  });

  /// Whether `beforeOpen` logs the cipher in use.
  final bool logEncryption;

  /// The wall clock, UTC milliseconds, the migrations stamp with.
  final int Function() wallMillis;

  /// The provisional sync node of a database migrated from schema 1.
  final String Function() newNodeId;

  /// Whether the full-text index is used when SQLite has FTS5 (false in tests only).
  final bool allowFullTextSearch;

  final Completer<bool> _fullTextSearch = Completer<bool>();

  /// Whether `TransactionQuery.text` is matched through the FTS5 index (true) or by the
  /// LIKE fallback (false, when the bundled SQLite lacks FTS5), as checked at open; opens
  /// the database when it is not open yet.
  Future<bool> get fullTextSearch async {
    if (!_fullTextSearch.isCompleted) await verifyOpen();
    return _fullTextSearch.future;
  }

  @override
  int get schemaVersion => 13;

  /// Closes the database, its query streams first, through [closeAgainOnRace]. Drift's
  /// stream store iterates its streams while awaiting each one's close, and that
  /// iteration fails with a [ConcurrentModificationError] when the map changes under it:
  /// a stream whose last listener left just before the close is removed by Drift's own
  /// timer, and a read still in flight (a one-shot `.first` of a job the stopped app
  /// started) registers a stream; either lands while a paused listener holds the close
  /// back. The store is then shutting down and refuses new removals, so the close runs
  /// again over what is left until it completes, at most five times.
  @override
  Future<void> close() => closeAgainOnRace(super.close);

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
      if (from < 13 && !await _hasColumn('transactions', 'receipt_sha256')) {
        // Also first, for the same reason.
        await m.addColumn(transactions, transactions.receiptSha256);
      }
      if (from < 13) {
        // First too: every later step that writes a record through the sync store
        // settles that record's conflicts (`DriftSyncStore.write`).
        await m.createTable(conflicts);
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
      if (from < 7) {
        await m.createTable(dismissedPairs);
      }
      if (from < 8) {
        await m.createTable(savedFilters);
        await _createIndex(m, savedFiltersPosition);
      }
      if (from < 9) {
        // One transaction: the tables, and the overrides another device recorded before
        // this version could store them (held as unsupported_type), land together.
        await transaction(() async {
          await m.createTable(recurringStreams);
          await _createIndex(m, recurringStreamsAccount);
          await m.createTable(streamOverrides);
          await m.createTable(liabilities);
          await releaseHeldRecords(
            DriftSyncStore(this, _WallClock(wallMillis)),
            EntityType.recurringStream,
          );
        });
      }
      if (from < 10) {
        // One transaction: the tables, and the bills another device recorded before this
        // version could store them (held as unsupported_type), land together.
        await transaction(() async {
          await m.createTable(bills);
          await _createIndex(m, billsDueDate);
          await m.createTable(billAlerts);
          await releaseHeldRecords(
            DriftSyncStore(this, _WallClock(wallMillis)),
            EntityType.billReminder,
          );
        });
      }
      if (from < 11) {
        await transaction(() async {
          await m.createTable(securities);
          await m.createTable(holdings);
          await m.createTable(investmentTransactions);
          await _createIndex(m, investmentTransactionsAccountDate);
          await m.createTable(balanceSnapshots);
          await _createIndex(m, balanceSnapshotsDate);
        });
      }
      if (from < 12) {
        // One transaction: the tables, and the goals and contributions another device
        // recorded before this version could store them (held as unsupported_type), land
        // together.
        await transaction(() async {
          await m.createTable(goals);
          await m.createTable(goalContributions);
          await _createIndex(m, goalContributionsGoal);
          final DriftSyncStore store = DriftSyncStore(
            this,
            _WallClock(wallMillis),
          );
          await releaseHeldRecords(store, EntityType.goal);
          await releaseHeldRecords(store, EntityType.goalContribution);
        });
      }
      if (from < 13) {
        // The transactions a newer device recorded with a receipt hash before this
        // version could store it (held with unknown fields) land. Their hashes come from
        // the records; the hashes of this device's own older photos are filled after
        // open (`TransactionActions.fillReceiptHashes`).
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
      final bool fts =
          allowFullTextSearch && await fullTextSearchCompiled(this);
      await ensureFullTextSearch(this, available: fts);
      if (!_fullTextSearch.isCompleted) _fullTextSearch.complete(fts);
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

/// Runs [close] (Drift's close of a database) again after each
/// [ConcurrentModificationError] its stream store fails with ([AppDatabase.close]), each
/// retry logged by type; the fifth failure is rethrown, so a close that keeps being
/// raced fails visibly rather than holding the restoring screen.
Future<void> closeAgainOnRace(Future<void> Function() close) async {
  for (int pass = 1; ; pass++) {
    try {
      await close();
      return;
    } on ConcurrentModificationError catch (e) {
      if (pass == 5) rethrow;
      _log.warning(
        'closing the database raced, closing again: ${e.runtimeType}',
      );
    }
  }
}

/// Writes again every record of [type] that [store] holds, so the ones a new table can
/// now store (records pulled before this version had it, held as `unsupported_type`)
/// become rows and stop being held; the rest stay held, for the reason that applies now.
Future<void> releaseHeldRecords(DriftSyncStore store, EntityType type) async =>
    store.materializeHeld(type, await store.heldIds(type));

/// [releaseHeldRecords] for every type this build knows that has a held record, so a
/// record held under a type's raw name by a build that did not know the type lands once
/// a build that knows it opens the database, whether or not a schema step came with the
/// type. Runs at every open, after the migrations (`openLocalData`); one query when
/// nothing is held, and nothing the second time but the records still held for a reason.
Future<void> releaseKnownHeldRecords(DriftSyncStore store) async {
  for (final EntityType type in await store.heldTypes()) {
    await releaseHeldRecords(store, type);
  }
}

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
