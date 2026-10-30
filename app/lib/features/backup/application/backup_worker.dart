/// The heavy work of a backup, each step a function the app runs in an isolate of its
/// own (`docs/reference/backup.md`, **In the app**), reporting [BackupProgress] as it
/// goes:
///
/// - [sealBackup]: the dump, the manifest, the key and the frames: the file's bytes;
/// - [openBackup]: the header, the key, every frame authenticated, the content read
///   back whole and checked (`decodePlaintext`), the schema version, and a trial import
///   into a database in memory, so a backup that cannot be restored is refused before
///   anything on the device is touched; it returns the manifest and the frame key;
/// - [restoreBackup]: the frames again under that key, the receipts written, then the
///   tables imported into a database just created at [RestoreRequest.databasePath].
///
/// Pure Dart, no Flutter import: everything here runs off the UI isolate.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/features/backup/data/database_dump.dart';
import 'package:finance_tracker/features/backup/domain/backup_archive.dart';
import 'package:finance_tracker/features/backup/domain/backup_cipher.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:finance_tracker/features/backup/domain/backup_manifest.dart';

/// Where a backup step is.
enum BackupStage {
  /// Reading the database and the receipts.
  reading,

  /// Deriving the key from the passphrase (no measure of progress).
  deriving,

  /// Encrypting the frames.
  encrypting,

  /// Authenticating the frames and checking the content.
  checking,

  /// Writing the receipts and the tables.
  restoring,
}

/// A step's progress: its [stage], and [done] of [total] when it can be counted.
final class BackupProgress {
  /// The progress.
  const BackupProgress(this.stage, [this.done = 0, this.total = 0]);

  /// The stage.
  final BackupStage stage;

  /// Units done.
  final int done;

  /// Units in all, 0 when the stage has no measure.
  final int total;

  /// The fraction done, null when the stage has no measure.
  double? get fraction => total == 0 ? null : done / total;

  @override
  String toString() => 'BackupProgress($stage, $done/$total)';
}

/// What [sealBackup] seals.
final class SealRequest {
  /// The request.
  const SealRequest({
    required this.tables,
    required this.receipts,
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.userId,
    required this.passphrase,
    required this.kdf,
    required this.salt,
    required this.baseNonce,
  });

  /// The dumped tables (`dumpDatabase`).
  final List<BackupTable> tables;

  /// The receipt files the tables reference that exist.
  final List<BackupReceipt> receipts;

  /// The database's schema version.
  final int schemaVersion;

  /// The app's version and build.
  final String appVersion;

  /// When the backup is made, UTC.
  final DateTime createdAt;

  /// The install's user, null when it never signed in.
  final String? userId;

  /// The passphrase, as typed.
  final String passphrase;

  /// Argon2id's cost.
  final KdfParameters kdf;

  /// 16 random bytes.
  final Uint8List salt;

  /// 24 random bytes.
  final Uint8List baseNonce;
}

/// The backup file of [request].
Future<Uint8List> sealBackup(
  SealRequest request,
  void Function(BackupProgress) report,
) async {
  final Uint8List dump = encodeDump(request.tables);
  final BackupManifest manifest = BackupManifest(
    schemaVersion: request.schemaVersion,
    appVersion: request.appVersion,
    createdAt: request.createdAt,
    userId: request.userId,
    deviceId: syncMetaIn(request.tables, 'device_id'),
    tables: {for (final BackupTable t in request.tables) t.name: t.rows.length},
    receipts: request.receipts.length,
    dumpSha256: sha256Hex(dump),
  );
  final Uint8List plaintext = encodePlaintext(manifest, dump, request.receipts);
  final BackupHeader header = BackupHeader(
    kdf: request.kdf,
    salt: request.salt,
    baseNonce: request.baseNonce,
  );
  report(const BackupProgress(BackupStage.deriving));
  final Uint8List key = await deriveFrameKey(request.passphrase, header);
  return sealFrames(
    plaintext,
    key,
    header,
    onFrame: (done, total) =>
        report(BackupProgress(BackupStage.encrypting, done, total)),
  );
}

/// An opened backup: its manifest and the frame key that opens it again.
final class OpenedBackup {
  /// The backup.
  const OpenedBackup(this.manifest, this.frameKey);

  /// The manifest.
  final BackupManifest manifest;

  /// The frame key (32 bytes).
  final Uint8List frameKey;
}

/// Opens [file] with [passphrase] and checks it can be restored into this build's
/// schema ([schemaVersion] is `AppDatabase.schemaVersion`, a parameter for the tests).
/// Throws a [BackupException]: [NotABackupException], [BackupTooNewException] (a later
/// format or schema), [UnsafeBackupException], [WrongPassphraseException],
/// [BackupDamagedException] or [BackupImportFailedException].
Future<OpenedBackup> openBackup(
  Uint8List file,
  String passphrase,
  void Function(BackupProgress) report, {
  int? schemaVersion,
}) async {
  final BackupHeader header = BackupHeader.read(file);
  report(const BackupProgress(BackupStage.deriving));
  final Uint8List key = await deriveFrameKey(passphrase, header);
  final BackupContent content = _open(file, key, header, report);
  final AppDatabase trial = AppDatabase(
    NativeDatabase.memory(),
    allowFullTextSearch: false,
  );
  try {
    if (content.manifest.schemaVersion >
        (schemaVersion ?? trial.schemaVersion)) {
      throw const BackupTooNewException();
    }
    for (final BackupReceipt r in content.receipts) {
      if (!isReceiptPath(r.path)) throw const BackupDamagedException();
    }
    await trial.verifyOpen();
    await importTables(trial, content.tables, newNodeId: provisionalNodeId());
  } finally {
    await trial.close();
  }
  return OpenedBackup(content.manifest, key);
}

/// What [restoreBackup] restores, and where.
final class RestoreRequest {
  /// The request.
  const RestoreRequest({
    required this.file,
    required this.frameKey,
    required this.databasePath,
    required this.hexKey,
    required this.receiptsRoot,
    required this.newNodeId,
  });

  /// The backup file.
  final Uint8List file;

  /// The frame key [openBackup] returned.
  final Uint8List frameKey;

  /// The database file to create; it must not exist.
  final String databasePath;

  /// The new database's key (64 hex digits), null for an unencrypted one (tests).
  final String? hexKey;

  /// The directory the receipts folder is in (the application support directory).
  final String receiptsRoot;

  /// The restored install's provisional sync node.
  final String newNodeId;
}

/// Restores [request]: the receipts, then the database, created at the current schema
/// and imported (`importTables`), then closed. The receipts are committed first, so an
/// interrupted restore leaves at most files the next launch's sweep removes.
Future<void> restoreBackup(
  RestoreRequest request,
  void Function(BackupProgress) report,
) async {
  final BackupContent content = _open(
    request.file,
    request.frameKey,
    BackupHeader.read(request.file),
    report,
  );
  final int total = content.manifest.rowCount + content.receipts.length;
  int done = 0;
  report(BackupProgress(BackupStage.restoring, done, total));
  final ReceiptStore receipts = FileReceiptStore(
    () async => Directory(request.receiptsRoot),
  );
  for (final BackupReceipt r in content.receipts) {
    final String id = r.path.substring(
      receiptFolder.length + 1,
      r.path.length - '.jpg'.length,
    );
    await receipts.commit(await receipts.stage(id, r.bytes));
    report(BackupProgress(BackupStage.restoring, ++done, total));
  }
  final File file = File(request.databasePath);
  if (file.existsSync()) throw StateError('the database file exists');
  final AppDatabase database = AppDatabase(
    NativeDatabase(
      file,
      setup: databaseSetup(
        hexKey: request.hexKey,
        requireEncryption: request.hexKey != null,
      ),
    ),
    allowFullTextSearch: false,
  );
  try {
    await database.verifyOpen();
    final int receiptsDone = done;
    await importTables(
      database,
      content.tables,
      newNodeId: request.newNodeId,
      onRows: (rows) => report(
        BackupProgress(BackupStage.restoring, receiptsDone + rows, total),
      ),
    );
  } finally {
    await database.close();
  }
}

BackupContent _open(
  Uint8List file,
  Uint8List key,
  BackupHeader header,
  void Function(BackupProgress) report,
) => decodePlaintext(
  openFrames(
    file,
    key,
    header,
    onFrame: (done, total) =>
        report(BackupProgress(BackupStage.checking, done, total)),
  ),
);
