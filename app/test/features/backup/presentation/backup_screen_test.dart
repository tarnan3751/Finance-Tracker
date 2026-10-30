// The backup screens: the export's passphrase rule, strength hint, progress and
// hand-over; the restore's refusals, each with its own message (data on the install,
// not a backup, too new, unsafe, a wrong passphrase, damage, another account), its
// progress, its confirmation and the restart it runs under; the demo's Settings entry;
// the fresh install's offer; the restoring screen; and the lost-key screen's way in.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/backup_picker_provider.dart';
import 'package:finance_tracker/core/platform/fake_backup_picker.dart';
import 'package:finance_tracker/core/platform/fake_file_exporter.dart';
import 'package:finance_tracker/core/platform/file_exporter_provider.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:finance_tracker/features/backup/application/backup_service.dart';
import 'package:finance_tracker/features/backup/application/backup_worker.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:finance_tracker/features/backup/domain/backup_manifest.dart';
import 'package:finance_tracker/features/backup/presentation/backup_messages.dart';
import 'package:finance_tracker/features/backup/presentation/backup_screen.dart';
import 'package:finance_tracker/features/backup/presentation/restore_flow.dart';
import 'package:finance_tracker/features/backup/presentation/restoring_app.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/restore_offer.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

/// The signed-in user of the app [tester] pumped.
String signedInUser(WidgetTester tester) => (ProviderScope.containerOf(
  tester.element(find.byType(BackupScreen)),
).read(sessionControllerProvider) as SignedIn).user.id;

BackupManifest manifest({String? userId}) => BackupManifest(
  schemaVersion: 12,
  appVersion: '1.0.0+1',
  createdAt: DateTime.utc(2026, 10, 20, 9),
  userId: userId,
  deviceId: 'device-1',
  tables: const {'accounts': 3, 'transactions': 40},
  receipts: 2,
  dumpSha256: '00',
);

/// A runner standing in for the isolates: it reports [progress], waits for [gate]
/// (open by default), then returns [result] or throws [failure].
final class FakeRunner {
  Object? result;
  Object? failure;
  BackupProgress progress = const BackupProgress(BackupStage.checking, 1, 4);
  Completer<void>? gate;
  int calls = 0;

  Future<T> call<T>(
    Future<T> Function(ProgressReport report) work,
    ProgressReport report,
  ) async {
    calls++;
    report(progress);
    await gate?.future;
    if (failure case final Object e) throw e;
    return result as T;
  }
}

void main() {
  late AppDatabase db;
  late FakeRunner runner;
  late FakeBackupPicker picker;
  late FakeFileExporter exporter;
  late List<Future<void> Function(ProgressReport)> restarts;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    runner = FakeRunner();
    // A file whose header opens: the rest is the runner's to judge.
    picker = FakeBackupPicker(
      file: Uint8List.fromList([
        ...BackupHeader(
          kdf: KdfParameters.standard,
          salt: Uint8List(16),
          baseNonce: Uint8List(24),
        ).toBytes(),
        ...List<int>.filled(40, 7),
      ]),
    );
    exporter = FakeFileExporter();
    restarts = [];
  });
  tearDown(() => db.close());

  List<Override> overrides({Directory? directory, AppRestart? restart}) => [
    databaseProvider.overrideWithValue(db),
    backupEnvironmentProvider.overrideWithValue(
      directory == null
          ? BackupEnvironment(runner: runner.call)
          : BackupEnvironment(
              runner: runner.call,
              directory: () async => directory,
            ),
    ),
    backupServiceProvider.overrideWith(
      (ref) => BackupService(
        database: db,
        receipts: MemoryReceiptStore(),
        tokens: InMemoryTokenStore(installUserId: 'demo-user'),
        clock: testClock,
        appVersion: () async => '1.0.0+1',
        runner: runner.call,
      ),
    ),
    backupPickerProvider.overrideWithValue(picker),
    fileExporterProvider.overrideWithValue(exporter),
    appRestartProvider.overrideWithValue(
      restart ?? (work) async => restarts.add(work),
    ),
  ];

  Future<void> pumpBackup(WidgetTester tester) => pumpApp(
    tester,
    initialLocation: '/settings/backup',
    overrides: overrides(),
  );

  group('export', () {
    Future<void> type(WidgetTester tester, String a, String b) async {
      await tester.enterText(
        find.widgetWithText(TextField, l10n.backupPassphrase),
        a,
      );
      await tester.enterText(
        find.widgetWithText(TextField, l10n.backupPassphraseConfirm),
        b,
      );
      await tester.pump();
    }

    testWidgets('needs 12 characters, typed twice alike', (tester) async {
      await pumpBackup(tester);
      expect(find.text(l10n.backupPassphraseHelper(12)), findsOneWidget);
      expect(find.text(l10n.backupNoRecovery), findsOneWidget);
      await type(tester, 'short', 'short');
      await tester.tap(find.text(l10n.backupSave));
      await tester.pump();
      expect(find.text(l10n.backupPassphraseTooShort(12)), findsOneWidget);
      await type(tester, 'correct horse battery', 'correct horse batterx');
      await tester.tap(find.text(l10n.backupSave));
      await tester.pump();
      expect(find.text(l10n.backupPassphraseMismatch), findsOneWidget);
      expect(runner.calls, 0);
      expect(exporter.calls, isEmpty);
    });

    testWidgets('hints at the strength as it is typed', (tester) async {
      await pumpBackup(tester);
      await type(tester, 'abcdefghijkl', '');
      expect(find.text(l10n.backupStrengthWeak), findsOneWidget);
      await type(tester, 'correct horse battery staple', '');
      expect(find.text(l10n.backupStrengthStrong), findsOneWidget);
    });

    testWidgets('shows its progress, then saves the file', (tester) async {
      await pumpBackup(tester);
      runner
        ..result = Uint8List.fromList([0x46, 0x54, 0x42, 0x4b])
        ..progress = const BackupProgress(BackupStage.encrypting, 2, 5)
        ..gate = Completer<void>();
      await type(tester, 'correct horse battery', 'correct horse battery');
      await tester.tap(find.text(l10n.backupSave));
      await tester.pump();
      await tester.pump();
      expect(runner.calls, 1);
      await tester.pump();
      expect(find.text(l10n.backupStageEncrypting), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.4,
      );
      runner.gate!.complete();
      await tester.pumpAndSettle();
      expect(exporter.calls.single.kind, ExportKind.saveAs);
      expect(exporter.calls.single.fileName, 'finance-tracker-2026-10-24.ftbk');
      expect(exporter.calls.single.mimeType, backupMimeType);
      expect(exporter.calls.single.bytes, [0x46, 0x54, 0x42, 0x4b]);
      expect(
        find.text(l10n.backupSaved('finance-tracker-2026-10-24.ftbk')),
        findsOneWidget,
      );
      expect(find.text(l10n.backupStageEncrypting), findsNothing);
      // The passphrase does not stay in the fields once the backup has left.
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, l10n.backupPassphrase),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text(l10n.backupPassphraseTooShort(12)), findsNothing);
    });

    testWidgets('says so when the backup cannot be made', (tester) async {
      await pumpBackup(tester);
      runner.failure = StateError('disk full');
      await type(tester, 'correct horse battery', 'correct horse battery');
      await tester.tap(find.text(l10n.backupShare));
      await tester.pump();
      await tester.pump();
      expect(runner.calls, 1);
      await tester.pumpAndSettle();
      expect(find.text(l10n.backupExportFailed), findsOneWidget);
      expect(exporter.calls, isEmpty);
    });
  });

  group('restore', () {
    Future<void> start(
      WidgetTester tester, {
      String passphrase = 'pass',
    }) async {
      final Finder button = find.widgetWithText(
        FilledButton,
        l10n.backupRestoreButton,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      if (find.byType(AlertDialog).evaluate().isEmpty) return;
      await tester.enterText(find.byType(TextField).last, passphrase);
      await tester.tap(find.text(l10n.backupOpen));
      await tester.pumpAndSettle();
    }

    testWidgets('is refused on an install that has data', (tester) async {
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES ('theme_mode', '\"dark\"')",
      );
      await pumpBackup(tester);
      await db.customStatement(
        'INSERT INTO saved_filters (id, name, query_json, position, created_at, '
        "updated_at) VALUES ('f', 'F', '{}', 0, 0, 0)",
      );
      await start(tester);
      expect(find.text(l10n.backupErrorHasData), findsOneWidget);
      expect(picker.calls, 0);
    });

    testWidgets('refuses a file over 512 MiB unread', (tester) async {
      picker.length = maxBackupBytes + 1;
      await pumpBackup(tester);
      await start(tester);
      expect(find.text(l10n.backupErrorTooLarge), findsOneWidget);
      expect(picker.reads, isEmpty);
      expect(picker.closed, 1);
      expect(runner.calls, 0);
    });

    testWidgets('reads only the header of a file that is not a backup', (
      tester,
    ) async {
      picker.file = Uint8List.fromList(List<int>.filled(4096, 1));
      await pumpBackup(tester);
      await start(tester);
      expect(find.text(l10n.backupErrorNotABackup), findsOneWidget);
      expect(picker.reads, [(0, backupHeaderLength)]);
      expect(picker.closed, 1);
      expect(runner.calls, 0);
    });

    testWidgets('refuses a header over the caps before reading the rest', (
      tester,
    ) async {
      final Uint8List file = Uint8List.fromList(picker.file!);
      ByteData.sublistView(file).setUint32(6, maxKdfMemoryKiB + 1);
      picker.file = file;
      await pumpBackup(tester);
      await start(tester);
      expect(find.text(l10n.backupErrorUnsafe), findsOneWidget);
      expect(picker.reads, [(0, backupHeaderLength)]);
    });

    testWidgets('does nothing when no file is chosen', (tester) async {
      picker.file = null;
      await pumpBackup(tester);
      await start(tester);
      expect(picker.calls, 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(runner.calls, 0);
    });

    for (final (BackupException e, String Function() message) in [
      (const NotABackupException(), () => l10n.backupErrorNotABackup),
      (const BackupTooNewException(), () => l10n.backupErrorTooNew),
      (const UnsafeBackupException(), () => l10n.backupErrorUnsafe),
      (const WrongPassphraseException(), () => l10n.backupErrorWrongPassphrase),
      (const BackupDamagedException(), () => l10n.backupErrorDamaged),
      (const BackupImportFailedException(), () => l10n.backupErrorFailed),
    ]) {
      testWidgets('says why for ${e.runtimeType}', (tester) async {
        runner.failure = e;
        await pumpBackup(tester);
        await start(tester);
        expect(find.text(message()), findsOneWidget);
        expect(restarts, isEmpty);
      });
    }

    testWidgets('refuses another account\'s backup', (tester) async {
      runner.result = OpenedBackup(
        manifest(userId: 'someone-else'),
        Uint8List(32),
      );
      await pumpBackup(tester);
      await start(tester);
      expect(find.text(l10n.backupErrorOtherAccount), findsOneWidget);
      expect(restarts, isEmpty);
    });

    testWidgets('shows its progress while it checks the file', (tester) async {
      runner.gate = Completer<void>();
      await pumpBackup(tester);
      runner.result = OpenedBackup(
        manifest(userId: signedInUser(tester)),
        Uint8List(32),
      );
      await start(tester);
      expect(find.text(l10n.backupStageChecking), findsOneWidget);
      runner.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(l10n.backupConfirmTitle), findsOneWidget);
    });

    testWidgets('confirms what it restores, then restarts around it', (
      tester,
    ) async {
      await pumpBackup(tester);
      runner.result = OpenedBackup(
        manifest(userId: signedInUser(tester)),
        Uint8List(32),
      );
      await start(tester);
      expect(find.text(l10n.backupConfirmTitle), findsOneWidget);
      expect(find.textContaining('1.0.0+1'), findsOneWidget);
      expect(
        find.textContaining('43 records and 2 receipt photos'),
        findsOneWidget,
      );
      expect(find.text(l10n.backupConfirmLostKey), findsNothing);
      await tester.tap(find.text(l10n.backupConfirmRestore));
      await tester.pumpAndSettle();
      expect(restarts, hasLength(1));
    });

    testWidgets('a backup that never signed in restores for anyone', (
      tester,
    ) async {
      runner.result = OpenedBackup(manifest(), Uint8List(32));
      await pumpBackup(tester);
      await start(tester);
      await tester.tap(find.text(l10n.backupConfirmRestore));
      await tester.pumpAndSettle();
      expect(restarts, hasLength(1));
    });

    testWidgets('cancelled at the confirmation, nothing happens', (
      tester,
    ) async {
      await pumpBackup(tester);
      runner.result = OpenedBackup(
        manifest(userId: signedInUser(tester)),
        Uint8List(32),
      );
      await start(tester);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(restarts, isEmpty);
    });
  });

  testWidgets('the demo\'s Settings says its data is not backed up', (
    tester,
  ) async {
    await pumpApp(
      tester,
      config: AppConfig.demo(),
      initialLocation: '/settings',
    );
    await tester.scrollUntilVisible(find.text(l10n.backupDemoNote), 200);
    expect(find.text(l10n.backupDemoNote), findsOneWidget);
  });

  testWidgets('Settings opens the backup screen in dev and prod', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/settings', overrides: overrides());
    await tester.scrollUntilVisible(
      find.text(l10n.backupSettingsSubtitle),
      200,
    );
    await tester.tap(find.text(l10n.backupSettingsSubtitle));
    await tester.pumpAndSettle();
    expect(find.byType(BackupScreen), findsOneWidget);
  });

  group('the offer', () {
    testWidgets('holds the app at /restore until it is answered', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          ...overrides(),
          restoreOfferProvider.overrideWith(PendingRestoreOffer.new),
        ],
      );
      expect(find.text(l10n.restoreOfferTitle), findsOneWidget);
      expect(find.byType(RestoreFlow), findsOneWidget);
      await tester.tap(find.text(l10n.restoreOfferStartFresh));
      await tester.pumpAndSettle();
      expect(find.text(l10n.restoreOfferTitle), findsNothing);
      expect(find.text(l10n.navAccounts), findsWidgets);
    });

    testWidgets('holds Start fresh while a restore is under way', (
      tester,
    ) async {
      runner
        ..result = OpenedBackup(manifest(), Uint8List(32))
        ..gate = Completer<void>();
      await pumpApp(
        tester,
        overrides: [
          ...overrides(),
          restoreOfferProvider.overrideWith(PendingRestoreOffer.new),
        ],
      );
      TextButton fresh() => tester.widget<TextButton>(
        find.widgetWithText(TextButton, l10n.restoreOfferStartFresh),
      );
      expect(fresh().onPressed, isNotNull);
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.backupRestoreButton),
      );
      await tester.pumpAndSettle();
      expect(fresh().onPressed, isNull);
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.tap(find.text(l10n.backupOpen));
      await tester.pump();
      expect(fresh().onPressed, isNull);
      runner.failure = const WrongPassphraseException();
      runner.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(l10n.backupErrorWrongPassphrase), findsOneWidget);
      expect(fresh().onPressed, isNotNull);
    });
  });

  test(
    'the progress shown is throttled to about each tenth, a new stage and the '
    'end',
    () {
      final ProgressThrottle throttle = ProgressThrottle();
      final List<int> shown = [
        for (int i = 1; i <= 100; i++)
          if (throttle.admit(BackupProgress(BackupStage.encrypting, i, 100))) i,
      ];
      expect(shown.first, 1);
      expect(shown.last, 100);
      expect(shown.length, inInclusiveRange(10, 12));
      expect(
        throttle.admit(const BackupProgress(BackupStage.checking, 1, 100)),
        isTrue,
      );
    },
  );

  testWidgets('the restoring screen shows the progress, then a failure', (
    tester,
  ) async {
    final ValueNotifier<RestoringState> state = ValueNotifier(
      const RestoringState(),
    );
    addTearDown(state.dispose);
    int continued = 0;
    await tester.pumpWidget(RestoringApp(state: state));
    expect(find.text(l10n.backupRestoringTitle), findsOneWidget);
    expect(find.text(l10n.backupStageRestoring), findsOneWidget);
    state.value = const RestoringState(
      progress: BackupProgress(BackupStage.restoring, 30, 120),
    );
    await tester.pump();
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.25,
    );
    state.value = RestoringState(
      failure: StateError('disk full'),
      onContinue: () => continued++,
    );
    await tester.pump();
    expect(find.text(l10n.backupRestoreFailedTitle), findsOneWidget);
    expect(find.text(l10n.backupRestoreFailedBody), findsOneWidget);
    await tester.tap(find.text(l10n.backupContinue));
    expect(continued, 1);
  });

  testWidgets('a double tap on Continue completes the restart once', (
    tester,
  ) async {
    final Completer<void> resume = Completer<void>();
    final ValueNotifier<RestoringState> state = ValueNotifier(
      RestoringState(
        failure: StateError('disk full'),
        onContinue: completeOnce(resume),
      ),
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(RestoringApp(state: state));
    await tester.tap(find.text(l10n.backupContinue));
    await tester.tap(find.text(l10n.backupContinue));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(resume.isCompleted, isTrue);
  });

  group('the lost-key screen', () {
    testWidgets('offers a restore, and warns that the old data goes', (
      tester,
    ) async {
      runner.result = OpenedBackup(manifest(), Uint8List(32));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides(),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          ],
          child: const DatabaseErrorApp(failure: DatabaseFailure.keyLost),
        ),
      );
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.backupRestoreButton),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.tap(find.text(l10n.backupOpen));
      await tester.pumpAndSettle();
      expect(find.text(l10n.backupConfirmLostKey), findsOneWidget);
      await tester.tap(find.text(l10n.backupConfirmRestore));
      await tester.pumpAndSettle();
      expect(restarts, hasLength(1));
    });

    Future<void> restoreOnLostKey(
      WidgetTester tester,
      InMemoryTokenStore tokens, {
      bool runWork = false,
    }) async {
      final Directory dir = Directory.systemTemp.createTempSync('lost_key');
      addTearDown(() => dir.deleteSync(recursive: true));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides(
              directory: dir,
              restart: (work) async {
                restarts.add(work);
                if (runWork) await work((_) {});
              },
            ),
            tokenStoreProvider.overrideWithValue(tokens),
            databaseKeyStoreProvider.overrideWithValue(
              InMemoryDatabaseKeyStore(),
            ),
          ],
          child: const DatabaseErrorApp(failure: DatabaseFailure.keyLost),
        ),
      );
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.backupRestoreButton),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.tap(find.text(l10n.backupOpen));
      await tester.pumpAndSettle();
      if (find.text(l10n.backupConfirmRestore).evaluate().isNotEmpty) {
        await tester.runAsync(() async {
          await tester.tap(find.text(l10n.backupConfirmRestore));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();
      }
    }

    testWidgets('refuses a backup of another user than the recorded one', (
      tester,
    ) async {
      runner.result = OpenedBackup(manifest(userId: 'y'), Uint8List(32));
      await restoreOnLostKey(tester, InMemoryTokenStore(installUserId: 'x'));
      expect(find.text(l10n.backupErrorOtherAccount), findsOneWidget);
      expect(restarts, isEmpty);
    });

    testWidgets('with no recorded user, refuses a backup of another user than '
        'the stored session\'s', (tester) async {
      runner.result = OpenedBackup(manifest(userId: 'y'), Uint8List(32));
      await restoreOnLostKey(
        tester,
        InMemoryTokenStore(session: _sessionOf('x')),
      );
      expect(find.text(l10n.backupErrorOtherAccount), findsOneWidget);
      expect(restarts, isEmpty);
    });

    testWidgets('with no recorded user, a backup of the stored session\'s user '
        'restores and records that user', (tester) async {
      runner.result = OpenedBackup(manifest(userId: 'x'), Uint8List(32));
      final InMemoryTokenStore tokens = InMemoryTokenStore(
        session: _sessionOf('x'),
      );
      await restoreOnLostKey(tester, tokens, runWork: true);
      expect(restarts, hasLength(1));
      expect(tokens.installUserId, 'x');
    });

    testWidgets('with no recorded user and no session, the restore records the '
        'backup\'s user through its work', (tester) async {
      runner.result = OpenedBackup(manifest(userId: 'y'), Uint8List(32));
      final InMemoryTokenStore tokens = InMemoryTokenStore();
      await restoreOnLostKey(tester, tokens, runWork: true);
      expect(restarts, hasLength(1));
      expect(tokens.installUserId, 'y');
    });

    testWidgets('the other failures offer none', (tester) async {
      for (final DatabaseFailure failure in [
        DatabaseFailure.keyMismatch,
        DatabaseFailure.encryptionUnavailable,
        DatabaseFailure.other,
      ]) {
        await tester.pumpWidget(
          ProviderScope(child: DatabaseErrorApp(failure: failure)),
        );
        expect(find.text(l10n.backupRestoreButton), findsNothing);
      }
    });
  });
}

Session _sessionOf(String userId) => Session(
  accessToken: 'access',
  refreshToken: 'refresh',
  accessExpiresAt: DateTime.utc(2030),
  user: User(
    id: userId,
    email: '$userId@example.com',
    displayName: userId,
    createdAt: DateTime.utc(2026),
  ),
  device: Device(id: 'device-$userId', userId: userId, name: 'Phone'),
);
