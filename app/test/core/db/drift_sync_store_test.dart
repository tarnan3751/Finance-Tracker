// The Drift sync store: the SyncStore contract (the cases of the engine's in-memory
// reference), records round-tripping through the entity tables, the held records, the
// node substitution and the ledger.
import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../contract/repository_fixture.dart';

EntityRecord goal(String id, String name) => EntityRecord(
  type: EntityType.goal,
  id: id,
  fields: {'name': name},
  fieldClocks: {'name': Hlc(1, 0, 'a')},
);

ChangeLogEntry entry(int wall, {String node = 'a'}) => ChangeLogEntry(
  entityType: EntityType.goal,
  entityId: 'g',
  operation: ChangeOperation.update,
  payload: const {'name': 'x'},
  hlc: Hlc(wall, 0, node),
  deviceId: node,
  synced: false,
);

// A complete record of [fields], every field (and the create) at [hlc].
EntityRecord complete(
  EntityType type,
  String id,
  Map<String, Object?> fields,
  Hlc hlc,
) => EntityRecord(
  type: type,
  id: id,
  fields: fields,
  fieldClocks: {for (final String f in fields.keys) f: hlc},
  createdAt: hlc,
);

void main() {
  late AppDatabase database;
  late DriftSyncStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftSyncStore(database, SteppingClock());
  });
  tearDown(() => database.close());

  group('the SyncStore contract', () {
    test('a throwing transaction leaves nothing behind', () async {
      await store.write(goal('g1', 'before'));
      await store.savePullCursor(3);
      await expectLater(
        store.transaction(() async {
          await store.write(goal('g1', 'after'));
          await store.write(goal('g2', 'new'));
          await store.append(entry(5));
          await store.savePullCursor(9);
          await store.saveClock(Hlc(9, 0, 'a'));
          throw StateError('crash');
        }),
        throwsStateError,
      );
      expect(
        (await store.read(EntityType.goal, 'g1'))!.fields['name'],
        'before',
      );
      expect(await store.read(EntityType.goal, 'g2'), isNull);
      expect(await store.unsynced(), isEmpty);
      expect(await store.pullCursor(), 3);
      expect(await store.lastClock(), isNull);
    });

    test('transactions do not interleave, and standalone calls wait', () async {
      final List<String> events = [];
      final Completer<void> gate = Completer<void>();
      final Future<void> first = store.transaction(() async {
        events.add('first start');
        await gate.future;
        await store.write(goal('g1', 'first'));
        events.add('first end');
      });
      final Future<void> second = store.transaction(() async {
        events.add('second start');
        events.add(
          'second sees '
          '${(await store.read(EntityType.goal, 'g1'))?.fields['name']}',
        );
      });
      final Future<void> read = store
          .read(EntityType.goal, 'g1')
          .then((r) => events.add('read ${r?.fields['name']}'));
      await pumpEventQueue();
      expect(events, ['first start']);
      gate.complete();
      await Future.wait([first, second, read]);
      expect(events, [
        'first start',
        'first end',
        'second start',
        'second sees first',
        'read first',
      ]);
    });

    test('a nested transaction joins the outer one', () async {
      await expectLater(
        store.transaction(() async {
          await store.transaction(() => store.write(goal('g1', 'inner')));
          throw StateError('outer fails');
        }),
        throwsStateError,
      );
      expect(await store.read(EntityType.goal, 'g1'), isNull);
    });

    test(
      'unsynced is in clock order and limited; markSynced removes entries',
      () async {
        for (final int w in [5, 1, 3, 2, 4]) {
          await store.append(entry(w));
        }
        expect((await store.unsynced(limit: 3)).map((e) => e.hlc.wallMillis), [
          1,
          2,
          3,
        ]);
        await store.markSynced([Hlc(1, 0, 'a'), Hlc(3, 0, 'a')]);
        expect((await store.unsynced()).map((e) => e.hlc.wallMillis), [
          2,
          4,
          5,
        ]);
        expect(
          (await store.unsynced()).first,
          entry(2),
          reason: 'an entry reads back as it was appended',
        );
      },
    );

    test(
      'markRejected takes entries out of the outbox and keeps them',
      () async {
        for (final int w in [1, 2, 3]) {
          await store.append(entry(w));
        }
        await store.markRejected([
          Hlc(2, 0, 'a'),
        ], PushRejectionReason.conflictingDuplicate);
        expect((await store.unsynced()).map((e) => e.hlc.wallMillis), [1, 3]);
        final ChangeLogRow kept = await (database.select(
          database.changeLog,
        )..where((c) => c.hlc.equals(Hlc(2, 0, 'a').pack()))).getSingle();
        expect(kept.rejectedReason, 'conflicting_duplicate');
        await expectLater(
          store.transaction(() async {
            await store.markRejected([
              Hlc(1, 0, 'a'),
            ], PushRejectionReason.invalid);
            throw StateError('crash');
          }),
          throwsStateError,
        );
        expect(await store.unsynced(), hasLength(2));
      },
    );

    test('the cursor and the clock persist', () async {
      expect(await store.pullCursor(), isNull);
      await store.savePullCursor(12);
      await store.saveClock(Hlc(7, 3, 'a'));
      final DriftSyncStore again = DriftSyncStore(database, SteppingClock());
      expect(await again.pullCursor(), 12);
      expect(await again.lastClock(), Hlc(7, 3, 'a'));
    });
  });

  group('records', () {
    final Hlc at = Hlc(1761318000000, 0, 'dev-a');

    Account account({String currency = 'USD'}) => Account(
      id: 'a1',
      type: AccountType.depository,
      name: 'Checking',
      currencyCode: currency,
      isHidden: false,
      displayOrder: 2,
    );

    Transaction transaction({
      String currency = 'USD',
      String splitIn = 'USD',
    }) => Transaction(
      id: 't1',
      accountId: 'a1',
      amount: Money(-1250, currency),
      date: LocalDate(2026, 10, 1),
      pending: false,
      name: 'Lunch',
      merchantLogoUrl: Uri.parse('https://example.com/logo.png'),
      notes: 'with Sam',
      tags: const ['food', 'work', 'food'],
      splits: [
        TransactionSplit(categoryId: 'c1', amount: Money(-1000, splitIn)),
        TransactionSplit(
          categoryId: 'c2',
          amount: Money(-250, splitIn),
          note: 'tip',
        ),
      ],
      source: DataSource.manual,
      createdAt: DateTime.utc(2026, 10, 1, 9),
      updatedAt: DateTime.utc(2026, 10, 1, 9, 30),
      syncVersion: 0,
    );

    const Category category = Category(
      id: 'c1',
      name: 'Lunches',
      isSystem: false,
      icon: 'restaurant',
      color: 0xFF336699,
    );

    Future<void> roundTrips(EntityRecord record) async {
      await store.write(record);
      expect(
        (await store.read(record.type, record.id))!.toCanonicalJson(),
        record.toCanonicalJson(),
      );
    }

    test('an account, live and deleted, round-trips through its row', () async {
      final Map<String, Object?> live = accountRecordJson(account())
        ..remove(deletedAtField);
      await roundTrips(complete(EntityType.account, 'a1', live, at));
      final AccountRow row = await database
          .select(database.accounts)
          .getSingle();
      expect(row.deletedAt, isNull);
      await roundTrips(
        complete(
          EntityType.account,
          'a1',
          accountRecordJson(account(), deletedAt: DateTime.utc(2026, 10, 2)),
          at,
        ),
      );
      expect(
        (await database.select(database.accounts).getSingle()).deletedAt,
        DateTime.utc(2026, 10, 2),
      );
    });

    test(
      'a transaction round-trips with its tags, splits and cascade flag',
      () async {
        await roundTrips(
          complete(
            EntityType.transaction,
            't1',
            transactionRecordJson(transaction())..remove(deletedAtField),
            at,
          ),
        );
        await roundTrips(
          complete(
            EntityType.transaction,
            't1',
            transactionRecordJson(
              transaction().copyWith(deletedAt: DateTime.utc(2026, 10, 3)),
              deletedWithAccount: true,
            ),
            at,
          ),
        );
        final TransactionRow row = await database
            .select(database.transactions)
            .getSingle();
        expect(row.deletedWithAccount, isTrue);
        expect(
          await database.select(database.transactionTags).get(),
          hasLength(3),
        );
      },
    );

    test(
      'a transaction may arrive before its account, in its own currency',
      () async {
        await roundTrips(
          complete(
            EntityType.transaction,
            't1',
            transactionRecordJson(transaction(currency: 'EUR', splitIn: 'EUR')),
            at,
          ),
        );
        expect(
          (await database.select(database.transactions).getSingle()).currency,
          'EUR',
        );
      },
    );

    test('a category and the settings round-trip', () async {
      await roundTrips(
        complete(EntityType.category, 'c1', categoryRecordJson(category), at),
      );
      await roundTrips(
        complete(EntityType.settings, settingsRecordId, {
          'theme_mode': 'dark',
          'use_dynamic_color': false,
        }, at),
      );
    });

    test('an entity with no clocks has no record, even with a row', () async {
      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'c1',
              name: 'Lunches',
              isSystem: false,
              icon: 'restaurant',
              color: 1,
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            ),
          );
      expect(await store.read(EntityType.category, 'c1'), isNull);
      expect(await store.read(EntityType.settings, settingsRecordId), isNull);
    });

    test(
      'an incomplete record is laid over its row, or held until it has one',
      () async {
        final EntityRecord notes = EntityRecord(
          type: EntityType.transaction,
          id: 't1',
          fields: const {'notes': 'from the other device'},
          fieldClocks: {'notes': at},
        );
        await roundTrips(notes);
        final HeldRecordRow held = await database
            .select(database.heldRecords)
            .getSingle();
        expect(held.reason, 'incomplete');
        expect(await database.select(database.transactions).get(), isEmpty);

        // Its create arrives: the merged record is materialized and no longer held.
        final ChangeLogEntry create = diff(
          EntityType.transaction,
          't1',
          null,
          transactionRecordJson(transaction()),
          Hlc(at.wallMillis - 10, 0, 'dev-b'),
        )!;
        final EntityRecord merged = merge(
          await store.read(EntityType.transaction, 't1'),
          create,
        ).record;
        await roundTrips(merged);
        expect(await database.select(database.heldRecords).get(), isEmpty);
        final TransactionRow row = await database
            .select(database.transactions)
            .getSingle();
        expect(row.notes, 'from the other device');
        expect(row.name, 'Lunch');

        // An override alone, on a row that exists, is laid over it.
        await roundTrips(
          EntityRecord(
            type: EntityType.transaction,
            id: 't1',
            fields: const {
              'tags': ['moved'],
            },
            fieldClocks: {'tags': at},
          ),
        );
        expect(
          (await database.select(database.transactionTags).getSingle()).tag,
          'moved',
        );
        expect(
          (await database.select(database.transactions).getSingle()).name,
          'Lunch',
        );
      },
    );

    test('splits the table cannot store: held whole, every other field in the row, '
        'no splits', () async {
      await store.write(
        complete(
          EntityType.transaction,
          't1',
          transactionRecordJson(transaction()),
          at,
        ),
      );
      // An EUR amount (moved to an EUR account) with USD splits (edited elsewhere).
      final EntityRecord mixed = complete(
        EntityType.transaction,
        't1',
        transactionRecordJson(
          transaction(currency: 'EUR')
              .copyWith(amount: Money(-900, 'EUR'), notes: 'moved'),
        ),
        Hlc(at.wallMillis + 1, 0, 'dev-a'),
      );
      await roundTrips(mixed);
      expect(
        (await database.select(database.heldRecords).getSingle()).reason,
        'unrepresentable',
      );
      final TransactionRow row = await database
          .select(database.transactions)
          .getSingle();
      expect(
        (row.amountMinor, row.currency, row.notes),
        (-900, 'EUR', 'moved'),
      );
      expect(await database.select(database.transactionSplits).get(), isEmpty);
      expect(
        await database.select(database.transactionTags).get(),
        hasLength(3),
      );

      // Splits in the amount's currency: held no more, splits back in the table.
      await roundTrips(
        complete(
          EntityType.transaction,
          't1',
          transactionRecordJson(transaction(currency: 'EUR', splitIn: 'EUR')),
          Hlc(at.wallMillis + 2, 0, 'dev-a'),
        ),
      );
      expect(await database.select(database.heldRecords).get(), isEmpty);
      expect(
        await database.select(database.transactionSplits).get(),
        hasLength(2),
      );
    });

    test(
      'a record that does not decode at all is held, the row untouched',
      () async {
        await store.write(
          complete(EntityType.category, 'c1', categoryRecordJson(category), at),
        );
        await roundTrips(
          complete(EntityType.category, 'c1', {
            ...categoryRecordJson(category),
            'name': 7,
          }, Hlc(at.wallMillis + 1, 0, 'dev-a')),
        );
        expect(
          (await database.select(database.heldRecords).getSingle()).reason,
          'unrepresentable',
        );
        expect(
          (await database.select(database.categories).getSingle()).name,
          'Lunches',
        );
      },
    );

    test('fields this version does not know: the known ones in the row, the record '
        'held whole', () async {
      final Map<String, Object?> fields = {
        ...transactionRecordJson(transaction())..remove(deletedAtField),
        'mood': 'celebratory',
      };
      await roundTrips(complete(EntityType.transaction, 't1', fields, at));
      expect(
        (await database.select(database.heldRecords).getSingle()).reason,
        'unknown_fields',
      );
      expect(
        (await database.select(database.transactions).getSingle()).name,
        'Lunch',
      );
      expect((await store.watchLedger().first).held, 1);

      // A local edit keeps the unknown field: the record still holds it and the entry
      // does not touch it, so every device keeps it.
      final ChangeLogEntry? edit = await LocalEditor(store, HlcClock('dev-b'))
          .recordChange(
            EntityType.transaction,
            't1',
            transactionRecordJson(transaction()),
            transactionRecordJson(transaction().copyWith(notes: 'edited')),
            at.wallMillis + 5,
          );
      expect(edit!.payload.keys, ['notes']);
      final EntityRecord after = (await store.read(
        EntityType.transaction,
        't1',
      ))!;
      expect(after.fields['mood'], 'celebratory');
      expect(after.fields['notes'], 'edited');
      expect(
        (await database.select(database.transactions).getSingle()).notes,
        'edited',
      );
      // Another device that merges the create and the edit holds the field too.
      final EntityRecord elsewhere = merge(
        merge(
          null,
          diff(EntityType.transaction, 't1', null, fields, at)!,
        ).record,
        edit,
      ).record;
      expect(elsewhere.toCanonicalJson(), after.toCanonicalJson());
    });

    test(
      'an entity the app does not store yet is held as unsupported',
      () async {
        await roundTrips(goal('g1', 'Holiday'));
        expect(
          (await database.select(database.heldRecords).getSingle()).reason,
          'unsupported_type',
        );
      },
    );

    test('randomized transactions round-trip', () async {
      for (int seed = 0; seed < 50; seed++) {
        final Random random = Random(seed);
        String pick(List<String> values) =>
            values[random.nextInt(values.length)];
        final Transaction t = transaction().copyWith(
          id: 't$seed',
          amount: Money(random.nextInt(1 << 30) - (1 << 29), 'USD'),
          pending: random.nextBool(),
          notes: random.nextBool() ? null : pick(['a', 'é', '😀', '']),
          tags: [
            for (int i = random.nextInt(4); i > 0; i--) pick(['x', 'y']),
          ],
          splits: [
            for (int i = random.nextInt(3); i > 0; i--)
              TransactionSplit(
                categoryId: pick(['c1', 'c2']),
                amount: Money(-random.nextInt(1000), 'USD'),
                note: random.nextBool() ? null : 'n',
              ),
          ],
          userCategoryId: random.nextBool() ? null : 'c1',
        );
        final Map<String, Object?> fields = transactionRecordJson(
          t,
          deletedWithAccount: random.nextBool(),
        );
        if (random.nextBool()) fields.remove(deletedAtField);
        await roundTrips(complete(EntityType.transaction, t.id, fields, at));
      }
    });
  });

  group('the node substitution', () {
    test(
      'moves the outbox and its field clocks, wall and counter kept',
      () async {
        final Hlc synced = Hlc(10, 0, 'local-x');
        final Hlc pending = Hlc(20, 3, 'local-x');
        final Hlc rejected = Hlc(15, 0, 'local-x');
        final Hlc remote = Hlc(30, 0, 'dev-b');
        for (final Hlc h in [synced, pending, rejected]) {
          await store.append(entry(0).copyWith(hlc: h, deviceId: h.nodeId));
        }
        await store.markSynced([synced]);
        await store.markRejected([rejected], PushRejectionReason.invalid);
        await store.write(
          EntityRecord(
            type: EntityType.goal,
            id: 'g',
            fields: const {'name': 'x', 'amount': 1, 'note': 'n'},
            fieldClocks: {'name': pending, 'amount': synced, 'note': remote},
          ),
        );
        await store.saveClock(Hlc(30, 1, 'local-x'));

        expect(await store.substituteNode('dev-new'), Hlc(30, 1, 'dev-new'));

        final List<ChangeLogRow> rows = await (database.select(
          database.changeLog,
        )..orderBy([(c) => OrderingTerm.asc(c.seq)])).get();
        expect(rows.map((r) => r.hlc), [
          synced.pack(),
          Hlc(20, 3, 'dev-new').pack(),
          rejected.pack(),
        ]);
        expect(rows.map((r) => r.deviceId), ['local-x', 'dev-new', 'local-x']);
        expect((await store.unsynced()).single.hlc, Hlc(20, 3, 'dev-new'));
        final EntityRecord moved = (await store.read(EntityType.goal, 'g'))!;
        expect(moved.fieldClocks, {
          'name': Hlc(20, 3, 'dev-new'),
          'amount': synced,
          'note': remote,
        });
        expect(await store.meta('device_id'), 'dev-new');
        expect(await store.lastClock(), Hlc(30, 1, 'dev-new'));
      },
    );

    test('on a new device, saves the node and has no clock to move', () async {
      expect(await store.substituteNode('dev-new'), isNull);
      expect(await store.meta('device_id'), 'dev-new');
    });
  });

  test(
    'the ledger counts the outbox, the rejected entries and the held records',
    () async {
      final List<SyncLedger> seen = [];
      final StreamSubscription<SyncLedger> subscription = store
          .watchLedger()
          .listen(seen.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      await store.append(entry(1));
      await store.append(entry(2));
      await pumpEventQueue();
      await store.markRejected([Hlc(2, 0, 'a')], PushRejectionReason.invalid);
      await store.write(goal('g1', 'x'));
      await pumpEventQueue();
      expect(seen.first, (
        pending: 0,
        rejected: 0,
        lastRejected: null,
        held: 0,
      ));
      expect(seen.last, (
        pending: 1,
        rejected: 1,
        lastRejected: Hlc(2, 0, 'a'),
        held: 1,
      ));
    },
  );
}
