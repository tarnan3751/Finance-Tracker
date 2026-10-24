// The encrypted database on a device: the APK's SQLite library carries SQLite3 Multiple
// Ciphers, the app's real open path (openAppDatabase) writes an encrypted file under the
// application support directory, a different key cannot open it, and the Keystore-backed
// key store round-trips a key, and the prod startup shows its error screen, not a crash,
// for a database whose key is gone. Runs in the demo build (tools/emulator_tests.sh
// integration), which opens no database of its own; the test removes what it writes.
import 'dart:io';

import 'package:drift/drift.dart' show QueryRow;
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const List<int> _sqliteHeader = [
  0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
  0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File file;

  setUp(() async {
    final Directory support = await getApplicationSupportDirectory();
    file = File(p.join(support.path, databaseFileName));
    if (file.existsSync()) file.deleteSync();
  });
  tearDown(() {
    if (file.existsSync()) file.deleteSync();
  });

  testWidgets('the database is encrypted at rest and refuses another key', (
    tester,
  ) async {
    final InMemoryDatabaseKeyStore keys = InMemoryDatabaseKeyStore();
    final AppDatabase database = openAppDatabase(AppConfig.prod(), keys);
    await database.verifyOpen();
    final QueryRow cipher = await database
        .customSelect('PRAGMA cipher')
        .getSingle();
    expect(cipher.data.values.single, isNotEmpty);
    await DriftAppMetaStore(database).write('probe', 'written');
    await database.close();

    expect(file.existsSync(), isTrue);
    expect(file.readAsBytesSync().take(16).toList(), isNot(_sqliteHeader));

    await expectLater(
      openDatabaseExecutor(
        file,
        keyStore: InMemoryDatabaseKeyStore(newDatabaseKey()),
      ),
      throwsA(isA<DatabaseKeyMismatchException>()),
    );

    final AppDatabase again = openAppDatabase(AppConfig.prod(), keys);
    expect(await DriftAppMetaStore(again).read('probe'), 'written');
    await again.close();
  });

  testWidgets('the dev flavor opens its database', (tester) async {
    // dev logs the cipher in beforeOpen, a path no other flavor takes.
    final AppDatabase database = openAppDatabase(
      AppConfig.dev(),
      InMemoryDatabaseKeyStore(),
    );
    await database.verifyOpen();
    await database.close();
    expect(file.existsSync(), isTrue);
  });

  testWidgets('the Keystore-backed store keeps a key', (tester) async {
    const FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: SecureDatabaseKeyStore.androidOptions,
    );
    final SecureDatabaseKeyStore keys = SecureDatabaseKeyStore(storage);
    addTearDown(() => storage.delete(key: SecureDatabaseKeyStore.keyName));
    await storage.delete(key: SecureDatabaseKeyStore.keyName);

    expect(await keys.read(), isNull);
    final String created = await keys.create();
    expect(await keys.read(), created);
  });

  testWidgets('a database whose key is gone shows the error screen', (
    tester,
  ) async {
    const FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: SecureDatabaseKeyStore.androidOptions,
    );
    await storage.delete(key: SecureDatabaseKeyStore.keyName);
    final AppDatabase database = openAppDatabase(
      AppConfig.prod(),
      InMemoryDatabaseKeyStore(),
    );
    await database.verifyOpen();
    await database.close();

    await bootstrap(AppConfig.prod());
    await tester.pumpAndSettle();

    expect(find.byType(DatabaseErrorApp), findsOneWidget);
    expect(
      tester.widget<DatabaseErrorApp>(find.byType(DatabaseErrorApp)).failure,
      DatabaseFailure.keyLost,
    );
    expect(await storage.read(key: SecureDatabaseKeyStore.keyName), isNull);
  });
}
