/// Finds, keys and opens the app's database file (`docs/reference/data.md`).
///
/// The file is `finance_tracker.db` under the application support directory, encrypted by
/// SQLite3 Multiple Ciphers (the `sqlite3` package's build hook, set in the workspace root
/// pubspec) with the raw 32-byte key from [DatabaseKeyStore]. The open sequence, run in
/// the database's background isolate by [databaseSetup]:
///
/// 1. `PRAGMA cipher` must return a row, or [EncryptionUnavailableException]: the app never
///    runs on plain SQLite in dev or prod;
/// 2. `PRAGMA key = "x'<64 hex>'"`, a raw key with no key derivation;
/// 3. `SELECT count(*) FROM sqlite_master`, where "file is not a database" means the key
///    is wrong: [DatabaseKeyMismatchException];
/// 4. `PRAGMA busy_timeout = 5000` (set right after the key, so the check above waits
///    too) and `PRAGMA journal_mode = WAL`, on every connection (both idempotent): the
///    background sync's own connection
///    (`docs/reference/background.md`) shares the file with the app's, so a write that
///    meets the other's write waits up to five seconds instead of failing with
///    `SQLITE_BUSY` at once, and readers never block the writer. The local wipe and the
///    restore already delete the `-wal` and `-shm` files with the database.
///
/// The sequence also runs once on the calling isolate, on a short-lived connection, before
/// the background one opens, so the caller gets these exceptions as themselves rather than
/// wrapped by Drift's isolate channel.
///
/// Before that, on the calling isolate: a database file without a stored key is a
/// [DatabaseKeyLostException] (the key is never recreated over existing data); no file and
/// no key creates the key first. The dev flavor's `--dart-define=FT_PLAIN_DB=true` opens
/// an unencrypted `finance_tracker.plain.db` instead, for debugging only; other flavors
/// ignore it.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

final Logger _log = Logger('db');

/// The encrypted database's file name.
const String databaseFileName = 'finance_tracker.db';

/// The dev escape hatch's unencrypted file name, so the two never mix.
const String plainDatabaseFileName = 'finance_tracker.plain.db';

const bool _plainDatabaseRequested = bool.fromEnvironment('FT_PLAIN_DB');

/// SQLite's result code for "file is not a database".
const int _sqliteNotADatabase = 26;

/// How long a connection waits for another's lock before failing.
const int busyTimeoutMillis = 5000;

final RegExp _hexKey = RegExp(r'^[0-9a-f]{64}$');

/// The app's database for [config], keyed from [keyStore]. Nothing is opened until the
/// first query; call [AppDatabase.verifyOpen] to open it at once.
AppDatabase openAppDatabase(AppConfig config, DatabaseKeyStore keyStore) {
  final bool plain = config.flavor == Flavor.dev && _plainDatabaseRequested;
  if (_plainDatabaseRequested && !plain) {
    _log.warning('FT_PLAIN_DB is honoured only in the dev flavor; ignored');
  }
  return AppDatabase(
    LazyDatabase(() async {
      final Directory directory = await getApplicationSupportDirectory();
      if (Platform.isAndroid) {
        // SQLite's default temporary directory is not writable on Android. This sets the
        // process-wide sqlite3_temp_directory, so the background isolate sees it too.
        sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
      }
      if (plain) _log.warning('opening the unencrypted debug database');
      return openDatabaseExecutor(
        File(
          p.join(
            directory.path,
            plain ? plainDatabaseFileName : databaseFileName,
          ),
        ),
        keyStore: plain ? null : keyStore,
      );
    }),
    logEncryption: config.flavor == Flavor.dev,
  );
}

/// The executor for [file]: encrypted with the key from [keyStore], or unencrypted when
/// [keyStore] is null (the dev escape hatch, and tests). Throws
/// [DatabaseKeyLostException] when [file] exists and the key does not.
Future<QueryExecutor> openDatabaseExecutor(
  File file, {
  required DatabaseKeyStore? keyStore,
}) async {
  String? hexKey;
  if (keyStore != null) {
    final bool exists = file.existsSync();
    hexKey = await keyStore.read();
    if (hexKey == null) {
      if (exists) throw const DatabaseKeyLostException();
      hexKey = await keyStore.create();
    }
    if (!_hexKey.hasMatch(hexKey)) throw const DatabaseKeyLostException();
  }
  final DatabaseSetup setup = databaseSetup(
    hexKey: hexKey,
    requireEncryption: keyStore != null,
  );
  final Database probe = sqlite3.open(file.path);
  try {
    setup(probe);
  } finally {
    probe.close();
  }
  return NativeDatabase.createInBackground(file, setup: setup);
}

/// The setup Drift runs on the raw connection before anything else (the open sequence in
/// this file's header). [hexKey] null opens without a key; [requireEncryption] false skips
/// the cipher check and is used only by tests and the dev escape hatch.
///
/// A top-level function, so the closure captures only its two sendable arguments: Drift
/// runs it in the database's background isolate.
DatabaseSetup databaseSetup({
  required String? hexKey,
  required bool requireEncryption,
}) {
  if (requireEncryption && hexKey == null) {
    throw ArgumentError.notNull('hexKey');
  }
  return (Database database) {
    if (requireEncryption && database.select('PRAGMA cipher;').isEmpty) {
      throw const EncryptionUnavailableException();
    }
    if (hexKey != null) {
      database.execute('PRAGMA key = "x\'$hexKey\'";');
    }
    database.execute('PRAGMA busy_timeout = $busyTimeoutMillis;');
    try {
      database.select('SELECT count(*) FROM sqlite_master;');
    } on SqliteException catch (e) {
      if (e.resultCode == _sqliteNotADatabase) {
        throw const DatabaseKeyMismatchException();
      }
      rethrow;
    }
    database.select('PRAGMA journal_mode = WAL;');
  };
}
