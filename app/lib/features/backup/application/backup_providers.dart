/// The backup feature's providers (`docs/reference/backup.md`, **In the app**): the
/// service, the restart a restore runs under, and the restore offer of a fresh install.
library;

import 'dart:io';

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/backup/application/backup_service.dart';
import 'package:finance_tracker/features/backup/data/database_dump.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_providers.g.dart';

/// Stops the app (its database closed, sync stopped), runs [work] on a plain screen
/// showing its progress, then starts the app again; a failure of [work] is shown there
/// before the app starts. What a restore runs under.
typedef AppRestart = Future<void> Function(
  Future<void> Function(ProgressReport report) work,
);

/// The app's restart: `bootstrap` supplies it; anywhere else (the tests) it is
/// unavailable unless overridden.
@Riverpod(keepAlive: true)
AppRestart appRestart(Ref ref) =>
    (_) => throw UnsupportedError('the app restart is supplied by bootstrap');

/// Where a backup's heavy work runs, and the directory the database and the receipts are
/// in: an isolate and the application support directory in the app, the calling
/// isolate and a temporary directory in the tests.
final class BackupEnvironment {
  /// The environment.
  const BackupEnvironment({
    this.runner = runInIsolate,
    this.directory = getApplicationSupportDirectory,
  });

  /// Where the heavy work runs.
  final BackupRunner runner;

  /// The directory of the database file and the receipts folder.
  final Future<Directory> Function() directory;
}

/// The backup environment.
@Riverpod(keepAlive: true)
BackupEnvironment backupEnvironment(Ref ref) => const BackupEnvironment();

/// The backup service over the dev and prod database (the demo flavor has none).
@Riverpod(keepAlive: true)
BackupService backupService(Ref ref) => BackupService(
  database: ref.watch(databaseProvider),
  receipts: ref.watch(receiptStoreProvider),
  tokens: ref.watch(tokenStoreProvider),
  clock: ref.watch(clockProvider),
  appVersion: () => ref.read(appVersionProvider.future),
  runner: ref.watch(backupEnvironmentProvider).runner,
);

/// Whether the restore offer is pending: in dev and prod (the data that syncs), when
/// someone is signed in, the local database holds nothing (`hasLocalData`), and the
/// offer has not been answered on this install (`restore_offer_answered` in
/// `app_meta`). While it is pending the router shows the offer at `/restore` and sync
/// runs no session; [answer] ("Start fresh") records the answer and lets both go on.
@Riverpod(keepAlive: true)
class RestoreOffer extends _$RestoreOffer {
  @override
  Future<bool> build() async {
    if (!ref.watch(localDataSyncsProvider)) return false;
    if (ref.watch(sessionControllerProvider) is! SignedIn) return false;
    final AppMetaStore meta = ref.read(appMetaStoreProvider);
    if (await meta.read(AppMetaKeys.restoreOfferAnswered) != null) return false;
    return !await hasLocalData(ref.read(databaseProvider));
  }

  /// Records that the offer was answered on this install, and ends it.
  Future<void> answer() async {
    await ref
        .read(appMetaStoreProvider)
        .write(
          AppMetaKeys.restoreOfferAnswered,
          ref.read(clockProvider).nowUtc().toIso8601String(),
        );
    state = const AsyncData(false);
  }
}
