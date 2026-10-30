// The committed backup of a schema 12 database, `test/fixtures/backup/ftbk-v1-schema12.ftbk`,
// restores into the current schema: the archive format stays readable, and an older
// schema's rows land in today's tables (unknown columns dropped, missing ones defaulted;
// `docs/reference/backup.md`, **Restore**). The fixture was made by this file at schema
// 12; run it with FT_WRITE_BACKUP_FIXTURE=1 to make it again (only at schema 12: the
// point of the fixture is that it stays old). The same file also goes through the app's
// own path: opened in an isolate, then restored by the restore's work over old database
// files, in an isolate, under a new key; and the account rule.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/backup/application/backup_service.dart';
import 'package:finance_tracker/features/backup/application/backup_worker.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

import 'backup_test_support.dart';

const String fixturePath = 'test/fixtures/backup/ftbk-v1-schema12.ftbk';
const String fixturePassphrase = 'fixture passphrase twelve';
const String fixtureUser = 'fixture-user';

final DateTime _now = DateTime.utc(2026, 10, 30, 9);

Transaction _lunch(String receipt) => Transaction(
  id: 'fixture-lunch',
  accountId: 'fixture-checking',
  amount: Money(-2450, 'USD'),
  date: LocalDate(2026, 10, 29),
  pending: false,
  name: 'Lunch in Lisbon',
  userCategoryId: systemCategoryId('FOOD_AND_DRINK'),
  tags: const ['a', 'b'],
  splits: [
    TransactionSplit(
      categoryId: systemCategoryId('FOOD_AND_DRINK'),
      amount: Money(-2000, 'USD'),
    ),
    TransactionSplit(
      categoryId: systemCategoryId('ENTERTAINMENT'),
      amount: Money(-450, 'USD'),
    ),
  ],
  receiptPath: receipt,
  source: DataSource.manual,
  createdAt: _now,
  updatedAt: _now,
  syncVersion: 0,
);

Future<Uint8List> _makeFixture(Directory dir) async {
  final AppDatabase db = AppDatabase(NativeDatabase.memory());
  final Clock clock = FixedClock(_now, tz.UTC);
  final ProviderContainer container = ProviderContainer(
    overrides: [
      ...localDataOverridesFor(AppConfig.dev()),
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock),
    ],
  );
  try {
    await container.read(categoryRepositoryProvider).ensureSeeded();
    final FileReceiptStore receipts = FileReceiptStore(() async => dir);
    await container
        .read(accountRepositoryProvider)
        .upsert(
          const Account(
            id: 'fixture-checking',
            type: AccountType.depository,
            name: 'Fixture checking',
            currencyCode: 'USD',
            isHidden: false,
            displayOrder: 0,
          ),
        );
    await container
        .read(transactionRepositoryProvider)
        .upsert(
          _lunch(
            await receipts.commit(
              await receipts.stage('fixture-lunch', receiptPhoto()),
            ),
          ),
        );
    // A deleted row, so the fixture pins a nullable instant (`deleted_at`) as ISO.
    final TransactionRepository transactions = container.read(
      transactionRepositoryProvider,
    );
    await transactions.upsert(
      _lunch(receiptPathFor('fixture-gone')).copyWith(
        id: 'fixture-gone',
        name: 'Deleted coffee',
        receiptPath: null,
        splits: const [],
        tags: const [],
      ),
    );
    await transactions.delete('fixture-gone');
    return await BackupService(
      database: db,
      receipts: receipts,
      tokens: InMemoryTokenStore(installUserId: fixtureUser),
      clock: clock,
      appVersion: () async => '1.0.0+1',
      kdf: testKdf,
      runner: runHere,
      random: Random(12),
    ).export(fixturePassphrase, (_) {});
  } finally {
    container.dispose();
    await db.close();
  }
}

void main() {
  late Directory dir;

  test('the account rule', () async {
    final OpenedBackup opened = await openBackup(
      File(fixturePath).readAsBytesSync(),
      fixturePassphrase,
      (_) {},
    );
    checkBackupAccount(opened.manifest, fixtureUser);
    checkBackupAccount(opened.manifest, null);
    expect(
      () => checkBackupAccount(opened.manifest, 'someone-else'),
      throwsA(isA<BackupOtherAccountException>()),
    );
  });

  test('a refusal crosses the isolate boundary as its own type', () async {
    await expectLater(
      openBackupFile(
        runInIsolate,
        File(fixturePath).readAsBytesSync(),
        'not the fixture passphrase',
        (_) {},
      ),
      throwsA(isA<WrongPassphraseException>()),
    );
  });

  test('in isolates, over old database files, under a new key', () async {
    final Directory root = await Directory.systemTemp.createTemp('replace');
    addTearDown(() => root.delete(recursive: true));
    for (final String suffix in const ['', '-wal', '-shm', '-journal']) {
      File(p.join(root.path, '$databaseFileName$suffix'))
          .writeAsStringSync('old');
    }
    final Uint8List file = File(fixturePath).readAsBytesSync();
    final List<BackupProgress> seen = [];
    final OpenedBackup opened = await openBackupFile(
      runInIsolate,
      file,
      fixturePassphrase,
      seen.add,
    );
    expect(seen.map((s) => s.stage).toSet(), {
      BackupStage.deriving,
      BackupStage.checking,
    });
    final InMemoryDatabaseKeyStore keys = InMemoryDatabaseKeyStore('0' * 64);
    seen.clear();
    await replaceDatabase(
      file: file,
      opened: opened,
      directory: root,
      keyStore: keys,
      report: seen.add,
      runner: runInIsolate,
    );
    expect(keys.key, isNot('0' * 64));
    expect(seen.last.stage, BackupStage.restoring);
    expect(seen.last.done, seen.last.total);
    for (final String suffix in const ['-wal', '-shm', '-journal']) {
      expect(
        File(p.join(root.path, '$databaseFileName$suffix')).existsSync(),
        isFalse,
      );
    }
    final AppDatabase restored = AppDatabase(
      await openDatabaseExecutor(
        File(p.join(root.path, databaseFileName)),
        keyStore: keys,
      ),
    );
    addTearDown(restored.close);
    expect(
      (await restored.customSelect('SELECT name FROM accounts').getSingle())
          .read<String>('name'),
      'Fixture checking',
    );
    expect(
      await FileReceiptStore(() async => root)
          .read('receipts/fixture-lunch.jpg'),
      receiptPhoto(),
    );
  });
  setUp(() async => dir = await Directory.systemTemp.createTemp('fixture'));
  tearDown(() => dir.delete(recursive: true));

  test('the schema 12 fixture restores into the current schema', () async {
    if (Platform.environment['FT_WRITE_BACKUP_FIXTURE'] == '1') {
      expect(
        AppDatabase(NativeDatabase.memory()).schemaVersion,
        12,
        reason: 'the fixture is a schema 12 backup',
      );
      File(fixturePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(await _makeFixture(dir));
    }
    final Uint8List file = File(fixturePath).readAsBytesSync();
    final OpenedBackup opened = await openBackup(
      file,
      fixturePassphrase,
      (_) {},
    );
    expect(opened.manifest.schemaVersion, 12);
    expect(opened.manifest.userId, fixtureUser);
    expect(opened.manifest.appVersion, '1.0.0+1');
    expect(opened.manifest.createdAt, _now);
    expect(opened.manifest.receipts, 1);

    final String path = p.join(dir.path, databaseFileName);
    await restoreBackup(
      RestoreRequest(
        file: file,
        frameKey: opened.frameKey,
        databasePath: path,
        hexKey: null,
        receiptsRoot: dir.path,
        newNodeId: 'local-fixture-restored',
      ),
      (_) {},
    );
    final AppDatabase restored = AppDatabase(
      NativeDatabase(
        File(path),
        setup: databaseSetup(hexKey: null, requireEncryption: false),
      ),
    );
    addTearDown(restored.close);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        ...localDataOverridesFor(AppConfig.dev()),
        databaseProvider.overrideWithValue(restored),
        clockProvider.overrideWithValue(FixedClock(_now, tz.UTC)),
      ],
    );
    addTearDown(container.dispose);
    final Transaction? lunch = await container
        .read(transactionRepositoryProvider)
        .watchById('fixture-lunch')
        .first;
    expect(lunch, isNotNull);
    expect(lunch!.amount, Money(-2450, 'USD'));
    expect(lunch.tags, ['a', 'b']);
    expect(lunch.splits, hasLength(2));
    expect(
      await FileReceiptStore(() async => dir).read(lunch.receiptPath!),
      receiptPhoto(),
    );
    // Schema 13's additions: the receipt hash a schema 12 backup lacks defaults to
    // null (the launch's hash fill gives it one), and no conflict comes along.
    expect(lunch.receiptSha256, isNull);
    expect(await restored.select(restored.conflicts).get(), isEmpty);
    final Account? checking = await container
        .read(accountRepositoryProvider)
        .watchById('fixture-checking')
        .first;
    expect(checking?.name, 'Fixture checking');
    expect(
      (await restored
              .customSelect(
                "SELECT deleted_at FROM transactions WHERE id = 'fixture-gone'",
              )
              .getSingle())
          .read<int>('deleted_at'),
      _now.millisecondsSinceEpoch,
    );
    expect(
      await container.read(driftSyncStoreProvider).meta('device_id'),
      'local-fixture-restored',
    );
    expect(
      await restored
          .customSelect(
            "SELECT 1 FROM transactions_fts WHERE transactions_fts MATCH '\"lisbon\"*'",
          )
          .get(),
      hasLength(1),
    );
  });
}
