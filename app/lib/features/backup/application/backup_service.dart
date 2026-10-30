/// Making and restoring backups in the app (`docs/reference/backup.md`, **In the app**):
/// [BackupService.export] reads the database in one transaction and the receipts it
/// references, then seals them in an isolate; [openBackupFile] opens and checks a
/// picked file in an isolate; [replaceDatabase] is the work a restore runs once the app
/// has stopped: it deletes the database files, creates a new key and restores into a
/// new database in an isolate. Progress comes back from the isolates through a port.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/backup/application/backup_worker.dart';
import 'package:finance_tracker/features/backup/data/database_dump.dart';
import 'package:finance_tracker/features/backup/domain/backup_archive.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:finance_tracker/features/backup/domain/backup_manifest.dart';
import 'package:path/path.dart' as p;

/// Reports a step's progress.
typedef ProgressReport = void Function(BackupProgress progress);

/// Runs [work] off the UI isolate, its progress reported through [report].
typedef BackupRunner = Future<T> Function<T>(
  Future<T> Function(ProgressReport report) work,
  ProgressReport report,
);

/// [BackupRunner] in an isolate of its own (`Isolate.run`), its progress sent back
/// through a port. [work] must capture only what an isolate message can carry.
Future<T> runInIsolate<T>(
  Future<T> Function(ProgressReport report) work,
  ProgressReport report,
) async {
  final ReceivePort port = ReceivePort();
  final StreamSubscription<Object?> progress = port.listen(
    (message) => report(message! as BackupProgress),
  );
  try {
    return await _spawn(work, port.sendPort);
  } finally {
    await progress.cancel();
    port.close();
  }
}

// Its own function, so the isolate's closure captures only [work] and [send].
Future<T> _spawn<T>(
  Future<T> Function(ProgressReport report) work,
  SendPort send,
) => Isolate.run(() => work(send.send));

/// [BackupRunner] on the calling isolate, for tests.
Future<T> runHere<T>(
  Future<T> Function(ProgressReport report) work,
  ProgressReport report,
) => work(report);

/// Makes backups of the dev and prod database.
final class BackupService {
  /// The service over [database], [receipts] and [tokens] (the install's user).
  BackupService({
    required this.database,
    required this.receipts,
    required this.tokens,
    required this.clock,
    required this.appVersion,
    this.kdf = KdfParameters.standard,
    this.runner = runInIsolate,
    Random? random,
  }) : _random = random ?? Random.secure();

  /// The local database.
  final AppDatabase database;

  /// The receipt files.
  final ReceiptStore receipts;

  /// Where the install's user is recorded.
  final TokenStore tokens;

  /// Where "now" comes from.
  final Clock clock;

  /// The app's version and build (`1.0.0+1`).
  final Future<String> Function() appVersion;

  /// Argon2id's cost for a new backup.
  final KdfParameters kdf;

  /// Where the heavy work runs.
  final BackupRunner runner;

  final Random _random;

  /// The backup file of everything the app holds, sealed with [passphrase].
  Future<Uint8List> export(String passphrase, ProgressReport report) async {
    report(const BackupProgress(BackupStage.reading));
    final List<BackupTable> tables = await dumpDatabase(database);
    final List<BackupReceipt> files = [
      for (final String path in referencedReceipts(tables))
        if (await receipts.read(path) case final Uint8List bytes)
          BackupReceipt(path, bytes),
    ];
    final SealRequest request = SealRequest(
      tables: tables,
      receipts: files,
      schemaVersion: database.schemaVersion,
      appVersion: await appVersion(),
      createdAt: clock.nowUtc(),
      userId: await tokens.readInstallUserId(),
      passphrase: passphrase,
      kdf: kdf,
      salt: _bytes(backupSaltLength),
      baseNonce: _bytes(backupNonceLength),
    );
    return _seal(runner, request, report);
  }

  Uint8List _bytes(int length) => Uint8List.fromList([
    for (int i = 0; i < length; i++) _random.nextInt(256),
  ]);
}

// Top-level, so each closure sent to an isolate captures only its own arguments.
Future<Uint8List> _seal(
  BackupRunner runner,
  SealRequest request,
  ProgressReport report,
) => runner((r) => sealBackup(request, r), report);

/// Opens [file] with [passphrase] through [runner], checked whole (`openBackup`).
Future<OpenedBackup> openBackupFile(
  BackupRunner runner,
  Uint8List file,
  String passphrase,
  ProgressReport report,
) => runner((r) => openBackup(file, passphrase, r), report);

Future<void> _restore(
  BackupRunner runner,
  RestoreRequest request,
  ProgressReport report,
) => runner((r) => restoreBackup(request, r), report);

/// Refuses [manifest] for an install whose user is [expectedUserId] (the signed-in
/// user, or the install's recorded one): a backup of a user ([BackupManifest.userId] not
/// null) restores only for that user. A backup of an install that never signed in
/// restores anywhere, as a new install's own edits do at its first sign-in.
void checkBackupAccount(BackupManifest manifest, String? expectedUserId) {
  final String? owner = manifest.userId;
  if (owner != null && expectedUserId != null && owner != expectedUserId) {
    throw const BackupOtherAccountException();
  }
}

/// The work of a restore, run once the app has stopped (its database closed): deletes
/// the database files under [directory] (the database, its `-wal`, `-shm` and
/// `-journal`), creates a new key in [keyStore], then restores [file] (opened with
/// [opened]'s frame key) into a new database there through [runner], the receipts
/// beside it.
Future<void> replaceDatabase({
  required Uint8List file,
  required OpenedBackup opened,
  required Directory directory,
  required DatabaseKeyStore keyStore,
  required ProgressReport report,
  required BackupRunner runner,
}) async {
  final String path = p.join(directory.path, databaseFileName);
  for (final String suffix in const ['', '-wal', '-shm', '-journal']) {
    final File f = File('$path$suffix');
    if (f.existsSync()) await f.delete();
  }
  final String hexKey = await keyStore.create();
  await _restore(
    runner,
    RestoreRequest(
      file: file,
      frameKey: opened.frameKey,
      databasePath: path,
      hexKey: hexKey,
      receiptsRoot: directory.path,
      newNodeId: provisionalNodeId(),
    ),
    report,
  );
}
