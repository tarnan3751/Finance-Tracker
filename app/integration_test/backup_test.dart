// Backup and restore on a device, in the demo build on the dev flavor's wiring (as
// sync_two_devices_test.dart runs it): the encrypted Drift database, the recorder and
// the real client over the in-app fake server, the fake file exporter and the fake
// backup picker. Run on the harness's emulator with `tools/emulator_tests.sh
// integration`.
//
// The source install (its database a temporary file) holds the family persona, pulled
// from the fake server, and a manual account and transaction with a receipt photo; its
// Settings → Backup exports with a passphrase, which the fake exporter records. A fresh
// install then starts as bootstrap starts the dev flavor (startApp: the database file
// under the application support directory, created now), signed in as the same user on
// a new device: the restore offer holds it at /restore; the fake picker hands it the
// file, the passphrase opens it, the confirmation restores it, and the app starts again
// on the restored data, the receipt photo back in place and the transaction found by
// search.
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/backup_picker_provider.dart';
import 'package:finance_tracker/core/platform/fake_backup_picker.dart';
import 'package:finance_tracker/core/platform/fake_file_exporter.dart';
import 'package:finance_tracker/core/platform/file_exporter_provider.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/auth/application/device_name.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_models/shared_models.dart';

const String _email = 'ada@example.com';
const String _password = 'correct horse';
const String _passphrase = 'correct horse battery staple';

/// Pumps until [finder] shows, or fails after [timeout] saying what the screen shows.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 180),
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  final List<String> shown = [
    for (final Element e in find.byType(Text).evaluate())
      if ((e.widget as Text).data case final String text) text,
  ];
  fail('$finder did not appear; the screen shows $shown');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;

  void removeInstall() {
    for (final String suffix in const ['', '-wal', '-shm', '-journal']) {
      final File f = File(p.join(support.path, '$databaseFileName$suffix'));
      if (f.existsSync()) f.deleteSync();
    }
    final Directory receipts = Directory(p.join(support.path, receiptFolder));
    if (receipts.existsSync()) receipts.deleteSync(recursive: true);
  }

  setUp(() async {
    support = await getApplicationSupportDirectory();
    removeInstall();
  });
  tearDown(() async {
    await stopApp();
    removeInstall();
  });

  testWidgets('backup: export on one install, restore onto a fresh one', (
    tester,
  ) async {
    await setUpTimeZones();
    final LocalDate today = LocalDate.fromDateTime(DateTime.now());
    final FakeServer server = FakeServer(
      dataset: FakeDataset.fromDemoSeed(demoSeedFor(PersonaId.family, today)),
    )..seedUser(email: _email, password: _password, displayName: 'Ada');
    server.seedLinkedItems(_email);

    // The source install, on a temporary file.
    final File sourceFile = File(
      p.join((await getTemporaryDirectory()).path, 'backup-source.db'),
    );
    if (sourceFile.existsSync()) sourceFile.deleteSync();
    final InMemoryDatabaseKeyStore sourceKeys = InMemoryDatabaseKeyStore();
    final AppDatabase source = AppDatabase(
      LazyDatabase(
        () => openDatabaseExecutor(sourceFile, keyStore: sourceKeys),
      ),
    );
    final Session sourceSession = server.seedSession(
      email: _email,
      password: _password,
      deviceName: 'Old phone',
    );
    final ProviderContainer a = ProviderContainer(
      overrides: [
        ...localDataOverridesFor(AppConfig.dev()),
        databaseProvider.overrideWithValue(source),
        fakeServerProvider.overrideWithValue(server),
        tokenStoreProvider.overrideWithValue(
          InMemoryTokenStore(
            session: sourceSession,
            installUserId: sourceSession.user.id,
          ),
        ),
        fakeFinanceApiOverride,
        deviceNameProvider.overrideWith((ref) async => 'Old phone'),
        appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
        syncDebounceProvider.overrideWithValue(const Duration(days: 1)),
      ],
    );
    addTearDown(() async {
      a.dispose();
      await source.close();
      if (sourceFile.existsSync()) sourceFile.deleteSync();
    });
    await source.verifyOpen();
    await a.read(categoryRepositoryProvider).ensureSeeded();
    await a.read(sessionControllerProvider.notifier).restored();
    await a.read(plaidPullProvider).run();
    final DateTime now = a.read(clockProvider).nowUtc();
    final ReceiptStore receipts = a.read(receiptStoreProvider);
    final Uint8List photo = Uint8List.fromList(
      List<int>.generate(5000, (i) => i % 251),
    );
    final String receipt = await receipts.commit(
      await receipts.stage('lisbon-lunch', photo),
    );
    await a
        .read(accountRepositoryProvider)
        .create(
          const Account(
            id: 'cash-jar',
            type: AccountType.depository,
            name: 'Cash jar',
            currencyCode: 'USD',
            isHidden: false,
            displayOrder: 50,
          ),
          openingBalance: Transaction(
            id: 'lisbon-lunch',
            accountId: 'cash-jar',
            amount: Money(-2450, 'USD'),
            date: today,
            pending: false,
            name: 'Lunch in Lisbon',
            receiptPath: receipt,
            source: DataSource.manual,
            createdAt: now,
            updatedAt: now,
            syncVersion: 0,
          ),
        );

    // Settings → Backup on the source: the passphrase twice, then Save as.
    await tester.pumpWidget(
      UncontrolledProviderScope(container: a, child: const FinanceTrackerApp()),
    );
    await pumpUntil(tester, find.text('Cash jar'));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Backup'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Backup'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Passphrase'),
      _passphrase,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Passphrase again'),
      _passphrase,
    );
    final FakeFileExporter exporter =
        a.read(fileExporterProvider) as FakeFileExporter;
    await tester.tap(find.text('Save as'));
    await pumpUntil(tester, find.textContaining('Saved finance-tracker-'));
    final ExportCall call = exporter.calls.single;
    expect(call.fileName, 'finance-tracker-${today.toIso()}.ftbk');
    expect(String.fromCharCodes(call.bytes.sublist(0, 4)), 'FTBK');
    await tester.pumpWidget(const SizedBox());

    // The source's receipt is not where the fresh install will look: only the backup
    // brings it.
    removeInstall();

    // The fresh install: the dev flavor's startup on a new database, a new device.
    final Session session = server.seedSession(
      email: _email,
      password: _password,
      deviceName: 'New phone',
    );
    await startApp(
      AppConfig.dev(),
      overrides: [
        ...localDataOverridesFor(AppConfig.dev()),
        databaseKeyStoreProvider.overrideWithValue(InMemoryDatabaseKeyStore()),
        fakeServerProvider.overrideWithValue(server),
        tokenStoreProvider.overrideWithValue(
          InMemoryTokenStore(session: session, installUserId: session.user.id),
        ),
        fakeFinanceApiOverride,
        deviceNameProvider.overrideWith((ref) async => 'New phone'),
        appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
        backupPickerProvider.overrideWithValue(
          FakeBackupPicker(file: call.bytes),
        ),
      ],
    );
    await pumpUntil(tester, find.text('Restore from a backup?'));
    await tester.tap(
      find.widgetWithText(FilledButton, 'Restore from a backup'),
    );
    await pumpUntil(tester, find.text("This backup's passphrase"));
    await tester.enterText(find.byType(TextField).last, _passphrase);
    await tester.tap(find.text('Open'));
    await pumpUntil(tester, find.text('Restore this backup?'));
    await tester.tap(find.text('Restore'));
    await pumpUntil(tester, find.text('Cash jar'));

    // The restored install: its receipt back, and the transaction found by search.
    final ProviderContainer b = ProviderScope.containerOf(
      tester.element(find.text('Cash jar')),
    );
    expect(await b.read(receiptStoreProvider).read(receipt), photo);
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'lisb');
    await pumpUntil(tester, find.text('Lunch in Lisbon'));

    // Off the screen before the app stops, as a restart does: a query stream a live
    // widget opens while the database closes trips Drift's close.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await stopApp();
  });
}
