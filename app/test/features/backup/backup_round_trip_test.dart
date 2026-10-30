// The acceptance test of backup and restore (`docs/reference/backup.md`, **Tests**;
// `PLAN.md` §12, "Backup content and restore"): a database holding the family persona
// (linked through the in-app fake server and pulled as the dev flavor pulls it) and
// manual data of every kind (accounts, transactions with tags, splits, notes and
// receipts, a deleted one, rules, budgets, bills, goals and contributions, settings, a
// saved filter, alerts, snapshots, device bookkeeping, a held record, an outbox with
// synced, rejected and unsynced entries) is exported, restored into a new database and
// dumped again: every table is equal, row for row, but for the three device keys a
// restore drops and the device identity it resets, and the receipt files are equal byte
// for byte. Two exports of one database are byte-identical with the same instant, salt
// and nonce, and differ only in the manifest's created_at otherwise. The restored
// install's outbox pushes to the relay as a new device with nothing refused.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/device_clock.dart';
import 'package:finance_tracker/core/sync/http_sync_relay.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/backup/application/backup_service.dart';
import 'package:finance_tracker/features/backup/application/backup_worker.dart';
import 'package:finance_tracker/features/backup/data/database_dump.dart';
import 'package:finance_tracker/features/backup/domain/backup_archive.dart';
import 'package:finance_tracker/features/backup/domain/backup_cipher.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../core/api/support/fake_api.dart';
import 'backup_test_support.dart';

const String _email = 'ada@example.com';
const String _password = 'correct horse';
const String _passphrase = 'correct horse battery staple';
const String _restoredNode = 'local-restored-node';

void main() {
  late Directory dir;
  late FakeServer server;
  late AppDatabase source;
  late ProviderContainer container;
  late FileReceiptStore receipts;
  late Session session;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('backup_round_trip');
    server = FakeServer(
      dataset: FakeDataset.fromDemoSeed(
        demoSeedFor(PersonaId.family, LocalDate(2026, 10, 24)),
      ),
      now: () => fakeNow,
    );
    server
      ..seedUser(email: _email, password: _password)
      ..seedLinkedItems(_email);
    session = server.seedSession(email: _email, password: _password);
    source = AppDatabase(NativeDatabase.memory());
    receipts = FileReceiptStore(
      () async => Directory(p.join(dir.path, 'source'))..createSync(),
    );
    container = ProviderContainer(
      overrides: [
        ...localDataOverridesFor(AppConfig.dev()),
        databaseProvider.overrideWithValue(source),
        fakeServerProvider.overrideWithValue(server),
        tokenStoreProvider.overrideWithValue(
          InMemoryTokenStore(session: session, installUserId: session.user.id),
        ),
        fakeFinanceApiOverride,
        clockProvider.overrideWithValue(fakeClientClock),
        appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
      ],
    );
    await seedEverything(container, receipts);
  });

  tearDownAll(() async {
    container.dispose();
    await source.close();
    await dir.delete(recursive: true);
  });

  BackupService service({DateTime? at, int seed = 1}) => BackupService(
    database: source,
    receipts: receipts,
    tokens: container.read(tokenStoreProvider),
    clock: FixedClock(at ?? fakeNow, fakeClientClock.location),
    appVersion: () async => '1.0.0+1',
    kdf: testKdf,
    runner: runHere,
    random: Random(seed),
  );

  test('the source holds every kind of data the test means it to', () async {
    final Map<String, int> counts = {
      for (final BackupTable t in await dumpDatabase(source))
        t.name: t.rows.length,
    };
    // The local-only and server tables a restore must carry are not empty.
    for (final String table in [
      'accounts',
      'transactions',
      'transaction_tags',
      'transaction_splits',
      'categories',
      'app_settings',
      'app_meta',
      'change_log',
      'record_clocks',
      'sync_meta',
      'held_records',
      'items',
      'rules',
      'budgets',
      'budget_alerts',
      'dismissed_pairs',
      'saved_filters',
      'recurring_streams',
      'liabilities',
      'bills',
      'bill_alerts',
      'securities',
      'holdings',
      'investment_transactions',
      'balance_snapshots',
      'goals',
      'goal_contributions',
    ]) {
      expect(counts[table], greaterThan(0), reason: table);
    }
    final Map<String, int> outbox = await outboxStates(source);
    expect(outbox['unsynced'], greaterThan(0));
    expect(outbox['synced'], greaterThan(0));
    expect(outbox['rejected'], greaterThan(0));
  });

  test('restore gives every table back, row for row', () async {
    final Uint8List file = await service().export(_passphrase, (_) {});
    final Directory target = Directory(p.join(dir.path, 'target'))
      ..createSync();
    final String path = p.join(target.path, databaseFileName);
    final String hexKey = List.filled(32, 'ab').join();
    final OpenedBackup opened = await openBackup(file, _passphrase, (_) {});
    expect(opened.manifest.userId, session.user.id);
    expect(opened.manifest.schemaVersion, source.schemaVersion);
    await restoreBackup(
      RestoreRequest(
        file: file,
        frameKey: opened.frameKey,
        databasePath: path,
        hexKey: hexKey,
        receiptsRoot: target.path,
        newNodeId: _restoredNode,
      ),
      (_) {},
    );
    // Opened as the app opens it: the full-text index is built at this open.
    final AppDatabase restored = AppDatabase(
      NativeDatabase(
        File(path),
        setup: databaseSetup(hexKey: hexKey, requireEncryption: true),
      ),
    );
    addTearDown(restored.close);
    await restored.verifyOpen();

    final List<BackupTable> before = expectedAfterRestore(
      await dumpDatabase(source),
      _restoredNode,
    );
    final List<BackupTable> after = await dumpDatabase(restored);
    expect(after.map((t) => t.name), before.map((t) => t.name));
    for (int i = 0; i < before.length; i++) {
      expect(after[i].columns, before[i].columns, reason: before[i].name);
      expect(
        jsonEncode(after[i].rows),
        jsonEncode(before[i].rows),
        reason: before[i].name,
      );
    }

    // The receipts, byte for byte.
    final FileReceiptStore restoredReceipts = FileReceiptStore(
      () async => target,
    );
    final List<String> paths = referencedReceipts(before);
    expect(paths, isNotEmpty);
    for (final String receipt in paths) {
      expect(
        await restoredReceipts.read(receipt),
        await receipts.read(receipt),
        reason: receipt,
      );
    }

    // The full-text index was rebuilt and finds a restored transaction.
    expect(
      await restored
          .customSelect(
            'SELECT transaction_id FROM transactions_fts '
            "WHERE transactions_fts MATCH '\"lisbon\"*'",
          )
          .get(),
      isNotEmpty,
    );

    // The restored outbox pushes as a new device, nothing refused.
    final FakeClient client = FakeClient(
      server,
      session: server.seedSession(
        email: _email,
        password: _password,
        deviceName: 'Restored phone',
      ),
    );
    final DriftSyncStore store = DriftSyncStore(restored, fakeClientClock);
    final DeviceClock clock = DeviceClock(store);
    final String deviceId = client.session.device.id;
    await clock.adopt(deviceId);
    final int unsynced = (await outboxStates(restored))['unsynced']!;
    final SyncReport report = await SyncSession(
      store,
      HttpSyncRelay(FinanceApiSyncEndpoints(client.api), deviceId: deviceId),
      await store.transaction(clock.current),
      nowWallMillis: () => fakeNow.millisecondsSinceEpoch,
    ).run();
    expect(report.rejected, isEmpty);
    expect(report.pushed, unsynced);
    expect((await outboxStates(restored))['unsynced'], 0);
  });

  test(
    'two exports are byte-identical but for created_at, salt and nonce',
    () async {
      final Uint8List a = await service().export(_passphrase, (_) {});
      final Uint8List b = await service().export(_passphrase, (_) {});
      expect(b, a);
      final Uint8List later = await service(
        at: fakeNow.add(const Duration(hours: 1)),
        seed: 2,
      ).export(_passphrase, (_) {});
      expect(later.sublist(18, 58), isNot(a.sublist(18, 58)));
      final List<String> one = await plaintextLines(a, _passphrase);
      final List<String> two = await plaintextLines(later, _passphrase);
      expect(two.skip(1), one.skip(1));
      final Map<String, Object?> m1 =
          jsonDecode(one.first) as Map<String, Object?>;
      final Map<String, Object?> m2 =
          jsonDecode(two.first) as Map<String, Object?>;
      expect(m2['created_at'], isNot(m1['created_at']));
      expect({...m2}..remove('created_at'), {...m1}..remove('created_at'));
    },
  );

  test(
    'the dump carries Money as minor units, dates and instants as ISO',
    () async {
      final List<BackupTable> tables = await dumpDatabase(source);
      final BackupTable transactions = tables.firstWhere(
        (t) => t.name == 'transactions',
      );
      final List<Object?> row = transactions.rows.firstWhere(
        (r) => r[transactions.columns.indexOf('id')] == 'manual-lunch',
      );
      Object? at(String column) => row[transactions.columns.indexOf(column)];
      expect(at('amount_minor'), -2450);
      expect(at('currency'), 'USD');
      expect(at('date'), '2026-10-22');
      expect(
        at('created_at'),
        matches(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$'),
      );
      expect(at('hidden'), isFalse);
      final BackupTable items = tables.firstWhere((t) => t.name == 'items');
      expect(
        items.rows.any(
          (r) => r[items.columns.indexOf('institution_logo')] is String,
        ),
        isTrue,
      );
    },
  );
}

// The dump of the transformed source: what a restore of [tables] yields, given the
// restored install's new node [node] (`database_dump.dart`).
List<BackupTable> expectedAfterRestore(List<BackupTable> tables, String node) {
  String moved(String hlc) => '${hlc.substring(0, 22)}$node';
  final BackupTable log = tables.firstWhere((t) => t.name == 'change_log');
  final int hlcAt = log.columns.indexOf('hlc');
  final Set<String> outbox = {
    for (final List<Object?> r in log.rows)
      if (r[log.columns.indexOf('synced')] == false &&
          r[log.columns.indexOf('rejected_reason')] == null)
        r[hlcAt]! as String,
  };
  return [
    for (final BackupTable t in tables)
      BackupTable(t.name, t.columns, switch (t.name) {
        'change_log' => [
          for (final List<Object?> r in t.rows)
            if (outbox.contains(r[hlcAt]))
              [
                for (int i = 0; i < r.length; i++)
                  i == hlcAt
                      ? moved(r[i]! as String)
                      : t.columns[i] == 'device_id'
                      ? node
                      : r[i],
              ]
            else
              r,
        ],
        'record_clocks' => [
          for (final List<Object?> r in t.rows)
            [
              for (int i = 0; i < r.length; i++)
                t.columns[i] == 'hlc' && outbox.contains(r[i])
                    ? moved(r[i]! as String)
                    : r[i],
            ],
        ],
        'sync_meta' => [
          for (final List<Object?> r in t.rows)
            switch (r[0]) {
              'device_id' => [r[0], node],
              'last_clock' => [r[0], moved(r[1]! as String)],
              _ => r,
            },
        ],
        'app_meta' => [
          for (final List<Object?> r in t.rows)
            if (!restoreDroppedMetaKeys.contains(r[0])) r,
        ],
        _ => t.rows,
      }),
  ];
}

Future<List<String>> plaintextLines(Uint8List file, String passphrase) async {
  final BackupHeader header = BackupHeader.read(file);
  return const LineSplitter().convert(
    utf8.decode(
      openFrames(file, await deriveFrameKey(passphrase, header), header),
    ),
  );
}
