// The open sequence on a real file: the host test library carries SQLite3 Multiple Ciphers
// (the hook define in the workspace root pubspec), so the cipher, the key, a wrong key, a
// lost key and the plain escape hatch are all checked here; the integration test
// encrypted_database_test.dart repeats the essentials on the emulator.
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

const List<int> _sqliteHeader = [
  0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
  0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
];

void main() {
  late Directory directory;
  late File file;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('ft-open-db-');
    file = File('${directory.path}/$databaseFileName');
  });
  tearDown(() => directory.deleteSync(recursive: true));

  Future<AppDatabase> open(DatabaseKeyStore? keyStore) async =>
      AppDatabase(await openDatabaseExecutor(file, keyStore: keyStore));

  List<int> header() => file.readAsBytesSync().take(16).toList();

  test('a first open creates a key and an encrypted file', () async {
    final InMemoryDatabaseKeyStore keys = InMemoryDatabaseKeyStore();
    final AppDatabase database = await open(keys);
    await database.verifyOpen();
    final QueryRow cipher = await database
        .customSelect('PRAGMA cipher')
        .getSingle();
    expect(cipher.data.values.single, isNotEmpty);
    await DriftAppMetaStore(database).write('k', 'v');
    await database.close();

    expect(keys.key, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(file.lengthSync(), greaterThan(0));
    expect(header(), isNot(_sqliteHeader));

    final AppDatabase again = await open(keys);
    addTearDown(again.close);
    expect(await DriftAppMetaStore(again).read('k'), 'v');
  });

  test('the dev flavor\'s encryption log opens, encrypted and in memory', () async {
    // beforeOpen runs these statements only in dev (AppDatabase.logEncryption).
    final AppDatabase encrypted = AppDatabase(
      await openDatabaseExecutor(file, keyStore: InMemoryDatabaseKeyStore()),
      logEncryption: true,
    );
    await encrypted.verifyOpen();
    await encrypted.close();

    final AppDatabase memory = AppDatabase(
      NativeDatabase.memory(),
      logEncryption: true,
    );
    addTearDown(memory.close);
    await memory.verifyOpen();
  });

  test('another key is a DatabaseKeyMismatchException', () async {
    final AppDatabase database = await open(InMemoryDatabaseKeyStore());
    await DriftAppMetaStore(database).write('k', 'v');
    await database.close();

    await expectLater(
      openDatabaseExecutor(
        file,
        keyStore: InMemoryDatabaseKeyStore(newDatabaseKey()),
      ),
      throwsA(isA<DatabaseKeyMismatchException>()),
    );
    await expectLater(
      openDatabaseExecutor(file, keyStore: null),
      throwsA(isA<DatabaseKeyMismatchException>()),
    );
  });

  test('a database file with no key is a DatabaseKeyLostException', () async {
    final AppDatabase database = await open(InMemoryDatabaseKeyStore());
    await database.verifyOpen();
    await database.close();

    final InMemoryDatabaseKeyStore empty = InMemoryDatabaseKeyStore();
    await expectLater(open(empty), throwsA(isA<DatabaseKeyLostException>()));
    expect(empty.key, isNull, reason: 'the key is never recreated over data');
  });

  test('a malformed stored key is a DatabaseKeyLostException', () async {
    await expectLater(
      open(InMemoryDatabaseKeyStore("abc'; DROP TABLE x; --")),
      throwsA(isA<DatabaseKeyLostException>()),
    );
  });

  test(
    'no key store opens an unencrypted file (the dev escape hatch)',
    () async {
      final AppDatabase database = await open(null);
      await DriftAppMetaStore(database).write('k', 'v');
      await database.close();
      expect(header(), _sqliteHeader);
    },
  );

  test('the encryption check needs a key', () {
    expect(
      () => databaseSetup(hexKey: null, requireEncryption: true),
      throwsArgumentError,
    );
  });

  group('SecureDatabaseKeyStore', () {
    late _MockStorage storage;
    setUp(() => storage = _MockStorage());

    test('keeps the key under db_key_v1 without reset on error', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      final String key = await SecureDatabaseKeyStore(storage).create();

      expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
      verify(() => storage.write(key: 'db_key_v1', value: key)).called(1);
      expect(
        SecureDatabaseKeyStore.androidOptions.params['resetOnError'],
        'false',
      );
      expect(
        SecureDatabaseKeyStore.androidOptions.params['storageNamespace'],
        'finance_tracker',
      );
    });

    test('a failing read is a DatabaseKeyLostException', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenThrow(PlatformException(code: 'decrypt'));
      await expectLater(
        SecureDatabaseKeyStore(storage).read(),
        throwsA(
          isA<DatabaseKeyLostException>().having(
            (e) => e.cause,
            'cause',
            isA<PlatformException>(),
          ),
        ),
      );
    });
  });

  test('keys are 32 random bytes', () {
    final Set<String> keys = {for (int i = 0; i < 50; i++) newDatabaseKey()};
    expect(keys, hasLength(50));
  });
}
