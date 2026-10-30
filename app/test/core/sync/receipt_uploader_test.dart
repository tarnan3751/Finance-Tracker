// The receipt upload before the push, over the in-app fake server through the real
// client: the photo reaches the server before the change that names it; a failed upload
// holds back only that change, which goes with the next session; a change whose hash has
// been replaced since, or whose photo is gone, goes without one; a refusal no retry can
// change lets the change go; each photo is uploaded once a session.
import 'dart:typed_data';

import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/sync/http_sync_relay.dart';
import 'package:finance_tracker/core/sync/receipt_uploader.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart'
    show receiptHash;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../api/support/fake_api.dart';

final Uint8List _photo = Uint8List.fromList([0xff, 0xd8, 0xff, 1, 2, 3]);
final Uint8List _other = Uint8List.fromList([0xff, 0xd8, 0xff, 4, 5, 6]);

void main() {
  late FakeServer server;
  late FakeClient client;
  late MemoryReceiptStore receipts;
  late InMemorySyncStore store;
  late HlcClock clock;
  late int now;

  setUp(() {
    server = newFakeServer();
    client = FakeClient.signedIn(server);
    receipts = MemoryReceiptStore();
    store = InMemorySyncStore();
    clock = HlcClock(client.session.device.id);
    now = fakeNow.millisecondsSinceEpoch;
  });

  SyncSession session() => SyncSession(
    store,
    HttpSyncRelay(
      FinanceApiSyncEndpoints(client.api),
      deviceId: client.session.device.id,
    ),
    clock,
    nowWallMillis: () => now,
    beforePush: ReceiptUploader(client.api, receipts, store).ready,
  );

  // A manual transaction [id], recorded, with the photo [bytes] stored here (none when
  // null) and named by its hash.
  Future<void> withReceipt(
    String id,
    Uint8List? bytes, {
    Uint8List? named,
  }) async {
    if (bytes != null) await receipts.commit(await receipts.stage(id, bytes));
    final Transaction t = Transaction(
      id: id,
      accountId: 'a1',
      amount: Money(-1250, 'USD'),
      date: LocalDate(2026, 10, 24),
      pending: false,
      name: 'Lunch',
      receiptPath: receiptPathFor(id),
      receiptSha256: receiptHash(named ?? bytes ?? _photo),
      source: DataSource.manual,
      createdAt: fakeNow,
      updatedAt: fakeNow,
      syncVersion: 0,
    );
    await LocalEditor(store, clock).recordChange(
      EntityType.transaction,
      id,
      null,
      transactionRecordJson(t),
      now++,
    );
  }

  Future<void> plain(String id) => LocalEditor(store, clock).recordChange(
    EntityType.category,
    id,
    null,
    {'id': id, 'name': 'Food', 'deleted_at': null},
    now++,
  );

  test(
    'the photo reaches the server before the change that names it',
    () async {
      await withReceipt('t1', _photo);
      final SyncReport report = await session().run();
      expect((report.pushed, report.deferred), (1, 0));
      expect(
        server.calls.where((c) => c == 'putReceipt' || c == 'pushChanges'),
        ['putReceipt', 'pushChanges'],
      );
      expect(await client.api.getReceipt(receiptHash(_photo)), _photo);
    },
  );

  test(
    'a failed upload holds back only its change, which goes next session',
    () async {
      await plain('c1');
      await withReceipt('t1', _photo);
      await plain('c2');
      server.failNextNetwork('putReceipt');
      final SyncReport first = await session().run();
      expect((first.pushed, first.deferred), (2, 1));
      expect([for (final e in await store.unsynced()) e.entityId], ['t1']);
      final SyncReport second = await session().run();
      expect((second.pushed, second.deferred), (1, 0));
      expect(await store.unsynced(), isEmpty);
      expect(await client.api.getReceipt(receiptHash(_photo)), _photo);
    },
  );

  test(
    'a change whose hash a later edit replaced goes without an upload',
    () async {
      await withReceipt('t1', _photo);
      // A later photo, recorded after the first change, replaced it here.
      await receipts.commit(await receipts.stage('t1', _other));
      final Map<String, Object?> before = (await store.read(
        EntityType.transaction,
        't1',
      ))!.fields;
      await LocalEditor(store, clock).recordChange(
        EntityType.transaction,
        't1',
        before,
        {...before, receiptHashField: receiptHash(_other)},
        now++,
      );
      final SyncReport report = await session().run();
      expect((report.pushed, report.deferred), (2, 0));
      expect(server.calls.where((c) => c == 'putReceipt'), hasLength(1));
      expect(await client.api.getReceipt(receiptHash(_other)), _other);
    },
  );

  test('a change whose photo is not here goes without an upload', () async {
    await withReceipt('t1', null);
    final SyncReport report = await session().run();
    expect((report.pushed, report.deferred), (1, 0));
    expect(server.calls, isNot(contains('putReceipt')));
  });

  for (final int status in [400, 413, 415]) {
    test('a $status, which no retry can change, lets the change go', () async {
      await withReceipt('t1', _photo);
      server.failNext('putReceipt', status);
      final SyncReport report = await session().run();
      expect((report.pushed, report.deferred), (1, 0));
    });
  }

  for (final int status in [500, 503]) {
    test('a $status holds the change back until the next session', () async {
      await withReceipt('t1', _photo);
      server.failNext('putReceipt', status);
      final SyncReport first = await session().run();
      expect((first.pushed, first.deferred), (0, 1));
      expect([for (final e in await store.unsynced()) e.entityId], ['t1']);
      final SyncReport second = await session().run();
      expect((second.pushed, second.deferred), (1, 0));
    });
  }

  test('a 401 holds the change back', () async {
    await plain('c1');
    await withReceipt('t1', _photo);
    // The auth interceptor refreshes an expired token itself; a 401 that reaches the
    // uploader is one it could not, such as a revoked session.
    final List<ChangeLogEntry> batch = await store.unsynced();
    final List<ChangeLogEntry> ready = await ReceiptUploader(
      const _Refusing(InvalidCredentials(status: 401)),
      receipts,
      store,
    ).ready(batch);
    expect([for (final e in ready) e.entityId], ['c1']);
  });

  test('a record holding the hash with a file that hashes differently lets the '
      'change go without an upload', () async {
    await withReceipt('t1', _photo);
    // The file was replaced here outside the record (a fetch of another photo).
    await receipts.commit(await receipts.stage('t1', _other));
    final SyncReport report = await session().run();
    expect((report.pushed, report.deferred), (1, 0));
    expect(server.calls, isNot(contains('putReceipt')));
  });

  test('one photo named by two changes is uploaded once', () async {
    await withReceipt('t1', _photo);
    await receipts.commit(await receipts.stage('t2', _photo));
    await withReceipt('t2', _photo);
    final SyncReport report = await session().run();
    expect(report.pushed, 2);
    expect(server.calls.where((c) => c == 'putReceipt'), hasLength(1));
  });
}

/// An API whose every receipt upload fails with [error].
final class _Refusing implements FinanceApi {
  const _Refusing(this.error);

  final ApiException error;

  @override
  Future<void> putReceipt(String sha256, Uint8List bytes) async => throw error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
