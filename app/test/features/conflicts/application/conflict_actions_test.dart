// The conflicts' actions on a device with the dev wiring over its own Drift database,
// syncing with an engine-only second device through one relay: a conflict a pull really
// produces; "Keep this device's value" writes it again through the local edit path, the
// row materialised as a pull's is, so the repository's stream shows it at once, the
// change syncs and wins on the other device; "Keep the other" changes nothing but the
// conflict; a conflict whose entity is deleted since goes; and the demo's wiring only
// forgets.
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/conflicts/application/conflicts_providers.dart';
import 'package:finance_tracker/features/conflicts/data/in_memory_conflict_store.dart';
import 'package:finance_tracker/features/conflicts/domain/sync_conflict.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart'
    show receiptHash;
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../contract/conflict_store_contract.dart';
import '../../../contract/repository_fixture.dart';

/// A clock the test moves.
final class _Clock implements Clock {
  int millis = DateTime.utc(2026, 10, 24, 15).millisecondsSinceEpoch;

  @override
  DateTime nowUtc() =>
      DateTime.fromMillisecondsSinceEpoch(millis++, isUtc: true);

  @override
  DateTime todayLocalMidnight() => DateTime.utc(2026, 10, 24);

  @override
  LocalDate today() => LocalDate(2026, 10, 24);

  @override
  tz.Location get location => tz.UTC;
}

const int _minute = 60 * 1000;

/// The other device: engine only.
final class _Other {
  _Other(SyncRelay relay, this.now) {
    session = SyncSession(store, relay, clock, nowWallMillis: () => now);
  }

  final InMemorySyncStore store = InMemorySyncStore();
  final HlcClock clock = HlcClock('dev-b');
  late final SyncSession session;
  int now;

  Future<void> edit(String id, Map<String, Object?> change) async {
    final Map<String, Object?> before = (await store.read(
      EntityType.transaction,
      id,
    ))!.fields;
    await LocalEditor(store, clock).recordChange(
      EntityType.transaction,
      id,
      before,
      {...before, ...change},
      now,
    );
  }
}

void main() {
  late AppDatabase database;
  late _Clock clock;
  late ProviderContainer a;
  late InMemorySyncRelay relay;
  late _Other b;
  late MemoryReceiptStore receipts;

  Future<void> syncA() async {
    final DriftSyncStore store = a.read(driftSyncStoreProvider);
    await a.read(deviceClockProvider).adopt('dev-a');
    await SyncSession(
      store,
      relay,
      await store.transaction(a.read(deviceClockProvider).current),
      nowWallMillis: () => clock.millis,
    ).run();
  }

  TransactionRepository transactions() => a.read(transactionRepositoryProvider);

  Future<String?> notes() async =>
      (await transactions().watchById('t1').first)?.notes;

  // A writes its notes; B overwrites them a minute later; A pulls: a conflict.
  setUp(() async {
    clock = _Clock();
    relay = InMemorySyncRelay(nowWallMillis: () => clock.millis);
    database = AppDatabase(NativeDatabase.memory());
    receipts = MemoryReceiptStore();
    a = ProviderContainer(
      overrides: [
        for (final o in overridesFor(AppConfig.dev()))
          if (o.origin != receiptStoreProvider) o,
        receiptStoreProvider.overrideWithValue(receipts),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
      ],
    );
    await a.read(deviceClockProvider).adopt('dev-a');
    await a.read(accountRepositoryProvider).upsert(testAccount('a1'));
    await transactions().upsert(testTransaction('t1', 'a1', -1250));
    await syncA();
    b = _Other(relay, clock.millis);
    await b.session.run();
    final Transaction t = (await transactions().watchById('t1').first)!;
    await transactions().upsert(t.copyWith(notes: 'from A'));
    await syncA();
    await b.session.run();
    b.now = clock.millis + _minute;
    await b.edit('t1', {'notes': 'from B'});
    await b.session.run();
    clock.millis += 2 * _minute;
    await syncA();
  });
  tearDown(() async {
    a.dispose();
    await database.close();
  });

  Future<List<SyncConflict>> conflicts() =>
      a.read(conflictStoreProvider).watch().first;

  test(
    'a pull that overwrites this device\'s value keeps the conflict',
    () async {
      expect(await notes(), 'from B');
      final SyncConflict c = (await conflicts()).single;
      expect(
        (c.field, c.localValue, c.remoteValue),
        ('notes', 'from A', 'from B'),
      );
      expect((c.localClock.nodeId, c.remoteClock.nodeId), ('dev-a', 'dev-b'));
      expect(c.entityLabel, 'Purchase');
    },
  );

  test("keeping this device's value shows at once, syncs and wins", () async {
    final SyncConflict c = (await conflicts()).single;
    final List<String?> seen = [];
    final sub = transactions()
        .watchById('t1')
        .listen((t) => seen.add(t?.notes));
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await a.read(conflictActionsProvider).keepLocal(c);
    await pumpEventQueue();
    expect(seen.last, 'from A', reason: 'the repository stream emits it');
    expect(await notes(), 'from A');
    expect(await conflicts(), isEmpty);
    final List<ChangeLogEntry> outbox = await a
        .read(driftSyncStoreProvider)
        .unsynced();
    expect(outbox.single.payload['notes'], 'from A');
    expect(outbox.single.hlc.compareTo(c.remoteClock), greaterThan(0));
    await syncA();
    await b.session.run();
    expect(
      (await b.store.read(EntityType.transaction, 't1'))!.fields['notes'],
      'from A',
    );
    // b's value lost within ten minutes in turn: b is asked now.
    expect(b.store.conflicts.single.localValue, 'from B');
  });

  test('keeping the other forgets the conflict and writes nothing', () async {
    final SyncConflict c = (await conflicts()).single;
    await a.read(conflictActionsProvider).keepOther(c);
    expect(await conflicts(), isEmpty);
    expect(await notes(), 'from B');
    expect(await a.read(driftSyncStoreProvider).unsynced(), isEmpty);
  });

  test('a conflict whose entity is deleted since goes with it', () async {
    final Map<String, Object?> before = (await b.store.read(
      EntityType.transaction,
      't1',
    ))!.fields;
    await LocalEditor(b.store, b.clock).recordChange(
      EntityType.transaction,
      't1',
      before,
      {...before, 'deleted_at': '2026-10-24T15:10:00.000Z'},
      b.now + _minute,
    );
    await b.session.run();
    await syncA();
    expect(await conflicts(), isEmpty);
  });

  test(
    "keeping this device's value after the field moved on only forgets",
    () async {
      final SyncConflict c = (await conflicts()).single;
      // Kept as the screen loaded it, while a later write moves the field on.
      final Transaction t = (await transactions().watchById('t1').first)!;
      await transactions().upsert(t.copyWith(notes: 'later'));
      await a.read(conflictActionsProvider).keepLocal(c);
      expect(await notes(), 'later');
      expect(await conflicts(), isEmpty);
    },
  );

  test('a Plaid removal drops the conflicts of its row, and keeping the '
      'value of a removed row writes nothing', () async {
    final Transaction bank = testTransaction(
      'p1',
      'a1',
      -900,
    ).copyWith(source: DataSource.plaid, syncVersion: 1);
    await transactions().applyPlaid([bank]);
    await transactions().upsert(
      (await transactions().watchById('p1').first)!.copyWith(notes: 'mine'),
    );
    await syncA();
    await b.session.run();
    b.now = clock.millis + _minute;
    await b.edit('p1', {'notes': 'theirs'});
    await b.session.run();
    clock.millis += 2 * _minute;
    await syncA();
    final SyncConflict c = (await conflicts()).firstWhere(
      (c) => c.entityId == 'p1',
    );
    expect((c.localValue, c.remoteValue), ('mine', 'theirs'));

    // Plaid removes it (as a posted row replaces its pending one).
    await transactions().applyPlaid([
      bank.copyWith(deletedAt: clock.nowUtc(), syncVersion: 2),
    ]);
    expect((await conflicts()).where((c) => c.entityId == 'p1'), isEmpty);
    await a.read(conflictActionsProvider).keepLocal(c);
    expect(await a.read(driftSyncStoreProvider).unsynced(), isEmpty);
  });

  group('a receipt photo', () {
    final Uint8List mine = Uint8List.fromList([0xff, 0xd8, 0xff, 1]);
    final Uint8List theirs = Uint8List.fromList([0xff, 0xd8, 0xff, 2]);

    // a attaches its photo; b replaces the hash a minute later; a pulls: a conflict.
    Future<SyncConflict> race() async {
      await receipts.commit(await receipts.stage('t1', mine));
      final Transaction t = (await transactions().watchById('t1').first)!;
      await transactions().upsert(
        t.copyWith(
          receiptPath: receiptPathFor('t1'),
          receiptSha256: receiptHash(mine),
        ),
      );
      await syncA();
      await b.session.run();
      b.now = clock.millis + _minute;
      await b.edit('t1', {'receipt_sha256': receiptHash(theirs)});
      await b.session.run();
      clock.millis += 2 * _minute;
      await syncA();
      return (await conflicts()).firstWhere((c) => c.field == 'receipt_sha256');
    }

    test("keeping this device's photo while it is here keeps it", () async {
      final SyncConflict c = await race();
      expect(await a.read(conflictActionsProvider).keepLocal(c), isTrue);
      expect(
        (await transactions().watchById('t1').first)!.receiptSha256,
        receiptHash(mine),
      );
    });

    test(
      'a photo fetched over it since the screen looked refuses the keep',
      () async {
        final SyncConflict c = await race();
        // The other photo is fetched over the file while the screen still shows Keep.
        await receipts.commit(await receipts.stage('t1', theirs));
        expect(await a.read(conflictActionsProvider).keepLocal(c), isFalse);
        expect([
          for (final c in await conflicts()) c.field,
        ], isNot(contains('receipt_sha256')));
        expect(await a.read(driftSyncStoreProvider).unsynced(), isEmpty);
        expect(
          (await transactions().watchById('t1').first)!.receiptSha256,
          receiptHash(theirs),
        );
      },
    );
  });

  test('a build that records nothing only forgets', () async {
    final InMemoryConflictStore store = InMemoryConflictStore();
    addTearDown(store.close);
    final SyncConflict c = testConflict('t1', 'notes');
    store.add(c);
    await ConflictActions(
      store,
      const NoChangeRecorder(),
      clock,
      a.read(transactionRepositoryProvider),
    ).keepLocal(c);
    expect(await store.watch().first, isEmpty);
  });
}
