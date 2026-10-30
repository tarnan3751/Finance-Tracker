/// The local wipe (`docs/reference/data.md`, **The local wipe**): everything this install
/// keeps of its account, erased so the next start is a fresh install. Run by account
/// deletion and by "Sign out and erase this device" through `wipeLocalDataProvider`, which
/// `bootstrap` supplies: the app is stopped first (its container disposed, so sync, the
/// reminder planner and every watcher stop and the database is closed), then [LocalWipe]
/// runs, then the app starts again on a new container.
///
/// A wipe is pending from its first step to its last: [LocalWipe.wipe] records the reason
/// first (`wipe_pending_v1`) and removes it only once every step has run, and `startApp`
/// finishes a pending wipe before it opens any local data, so a process killed part way
/// never starts on what is left. The order, each step skipping what is already gone, so
/// a wipe runs again from the top:
///
/// 1. the original app's plaintext keys the legacy importer reads, first, so a cut later
///    on cannot import them again into a fresh database;
/// 2. the database files (`finance_tracker.db`, and the dev flavor's
///    `finance_tracker.plain.db`, each with its `-wal`, `-shm` and `-journal`);
/// 3. the receipts;
/// 4. the database key (`db_key_v1`), then the session (`session_v1`), then the install's
///    user (`install_user_v1`): the marker goes last, so even outside a pending wipe the
///    account's data is never left on the device without the rule that keeps another
///    account from syncing it;
/// 5. every pending reminder and every notification the app has shown;
///
/// then the pending record goes. No path, key or value is logged.
library;

import 'dart:io';

import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/legacy_import/legacy_importer.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Why the local data is wiped, which the confirmation says.
enum WipeReason {
  /// The account was deleted on the server first.
  accountDeleted,

  /// The user erased this device; the account stays.
  deviceErased,
}

/// Stops the app, wipes its local data with the running app's [LocalWipe], confirms, and
/// starts the app again (`bootstrap`). Never completes while the app it was read from
/// runs: the caller's widgets are gone by then.
typedef WipeLocalData = Future<void> Function(WipeReason reason);

/// Erases the install's local data. The database must be closed first.
abstract interface class LocalWipe {
  /// The reason of a wipe that started and did not finish, or null.
  Future<WipeReason?> pending();

  /// Records [reason] as pending, runs the wipe in this file's order and then clears the
  /// record; the first step that fails throws, leaving the wipe pending, and running it
  /// again is safe.
  Future<void> wipe(WipeReason reason);
}

/// The dev and prod flavors' wipe: the pending record and the legacy keys in
/// [preferences], the database files under [directory] (the application support
/// directory), then the stores.
final class DriftLocalWipe implements LocalWipe {
  /// A wipe of the files under [directory] and of the given stores.
  DriftLocalWipe({
    required this.directory,
    required this.receipts,
    required this.preferences,
    required this.keys,
    required this.tokens,
    required this.reminders,
  });

  /// The key of the pending record in [preferences], its value the [WipeReason]'s name.
  static const String pendingKey = 'wipe_pending_v1';

  /// Where the database files are.
  final Future<Directory> Function() directory;
  final ReceiptStore receipts;
  final Future<SharedPreferences> Function() preferences;
  final DatabaseKeyStore keys;
  final TokenStore tokens;
  final ReminderScheduler reminders;

  /// The suffixes of SQLite's files beside a database.
  static const List<String> databaseFileSuffixes = [
    '',
    '-wal',
    '-shm',
    '-journal',
  ];

  @override
  Future<WipeReason?> pending() async {
    final String? name = (await preferences()).getString(pendingKey);
    if (name == null) return null;
    // A value this build does not know still means a wipe to finish.
    return WipeReason.values.asNameMap()[name] ?? WipeReason.deviceErased;
  }

  @override
  Future<void> wipe(WipeReason reason) async {
    final SharedPreferences prefs = await preferences();
    await prefs.setString(pendingKey, reason.name);
    for (final String key in legacyKeys) {
      await prefs.remove(key);
    }
    final String base = (await directory()).path;
    for (final String name in [databaseFileName, plainDatabaseFileName]) {
      for (final String suffix in databaseFileSuffixes) {
        final File file = File(p.join(base, '$name$suffix'));
        if (file.existsSync()) await file.delete();
      }
    }
    await _wipeStores(receipts, keys, tokens, reminders);
    await prefs.remove(pendingKey);
  }
}

/// The wipe of the demo flavor and the tests: no files and no preferences, the same
/// stores in the same order, the pending record in memory. Counts its runs.
final class InMemoryLocalWipe implements LocalWipe {
  /// A wipe of the given stores.
  InMemoryLocalWipe({
    required this.receipts,
    required this.keys,
    required this.tokens,
    required this.reminders,
  });

  final ReceiptStore receipts;
  final DatabaseKeyStore keys;
  final TokenStore tokens;
  final ReminderScheduler reminders;

  /// The pending record.
  WipeReason? pendingReason;

  /// How many times [wipe] completed.
  int wipes = 0;

  @override
  Future<WipeReason?> pending() async => pendingReason;

  @override
  Future<void> wipe(WipeReason reason) async {
    pendingReason = reason;
    await _wipeStores(receipts, keys, tokens, reminders);
    pendingReason = null;
    wipes++;
  }
}

Future<void> _wipeStores(
  ReceiptStore receipts,
  DatabaseKeyStore keys,
  TokenStore tokens,
  ReminderScheduler reminders,
) async {
  await receipts.deleteAll();
  await keys.delete();
  await tokens.clear();
  await tokens.clearInstallUserId();
  await reminders.clearAll();
}
