// The schema's migrations against the dumped schemas in drift_schemas/ (data.md, "Changing
// the schema"). Schema 1 is validated as created; from schema 2 on, each step opens the
// previous version's database with data, migrates it, and checks the data and the schema.
import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/tables/record_clocks.dart';
import 'package:finance_tracker/core/db/tables/sync_meta.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../helpers/pump_app.dart' show testClock;
import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('every schema version up to the current one has a dump', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    expect(GeneratedHelper.versions, [
      for (int v = 1; v <= database.schemaVersion; v++) v,
    ]);
  });

  test('a new database matches the schema 1 dump', () async {
    final AppDatabase database = AppDatabase(await verifier.startAt(1));
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 1);
  });

  test('a new database matches the schema 2 dump', () async {
    final AppDatabase database = AppDatabase(await verifier.startAt(2));
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 2);
  });

  test('a new database matches the schema 3 dump', () async {
    final AppDatabase database = AppDatabase(await verifier.startAt(3));
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 3);
  });

  test('a new database matches the schema 4 dump', () async {
    final AppDatabase database = AppDatabase(await verifier.startAt(4));
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 4);
  });

  group('schema 1 to 2', () {
    // 2026-10-01 09:00 UTC, the v1 rows' audit instants; 2026-10-02, a v1 delete.
    const int created = 1759309200000;
    const int deleted = 1759395600000;
    const int migratedAt = 1761318000000; // 2026-10-24 15:00 UTC

    Future<AppDatabase> migrated() async {
      final schema = await verifier.schemaAt(1);
      schema.rawDatabase.execute('''
        INSERT INTO accounts (id, item_id, type, subtype, name, official_name, mask,
          currency, current_balance_minor, available_balance_minor, credit_limit_minor,
          balances_as_of, is_hidden, display_order, created_at, updated_at, deleted_at,
          sync_version)
        VALUES
          ('acc-live', NULL, 'depository', 'checking', 'Checking', NULL, NULL, 'USD',
           NULL, NULL, NULL, NULL, 0, 0, $created, $created, NULL, 0),
          ('acc-gone', NULL, 'credit', NULL, 'Old card', NULL, NULL, 'USD',
           NULL, NULL, NULL, NULL, 1, 1, $created, $deleted, $deleted, 0);
        INSERT INTO transactions (id, account_id, amount_minor, currency, date,
          authorized_date, pending, pending_transaction_id, name, merchant_name,
          merchant_logo_url, plaid_primary_category, plaid_detailed_category,
          user_category_id, notes, receipt_path, source, created_at, updated_at, deleted_at,
          sync_version, deleted_with_account)
        VALUES
          ('t-manual', 'acc-live', -1250, 'USD', '2026-09-30', NULL, 0, NULL, 'Lunch',
           NULL, NULL, NULL, NULL, 'user-cat', 'with Sam', NULL, 'manual', $created,
           $created, NULL, 0, 0),
          ('t-import', 'acc-live', 5000, 'USD', '2026-09-29', NULL, 0, NULL, 'Imported',
           NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'import', $created, $created, NULL, 0,
           0),
          ('t-cascade', 'acc-gone', -300, 'USD', '2026-09-28', NULL, 0, NULL, 'Coffee',
           NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'manual', $created, $deleted,
           $deleted, 0, 1),
          ('t-alone', 'acc-live', -700, 'USD', '2026-09-27', NULL, 0, NULL, 'Snack', NULL,
           NULL, NULL, NULL, NULL, NULL, NULL, 'manual', $created, $deleted, $deleted, 0,
           0);
        INSERT INTO transaction_tags (transaction_id, position, tag)
        VALUES ('t-manual', 0, 'work'), ('t-manual', 1, 'food');
        INSERT INTO transaction_splits (transaction_id, position, category_id,
          amount_minor, note)
        VALUES ('t-manual', 0, 'user-cat', -1000, NULL),
               ('t-manual', 1, 'plaid:FOOD_AND_DRINK', -250, 'tip');
        INSERT INTO categories (id, name, parent_id, is_system, icon, color,
          plaid_category, created_at, updated_at, deleted_at, sync_version)
        VALUES
          ('user-cat', 'Lunches', NULL, 0, 'restaurant', 4283215696, NULL, $created,
           $created, NULL, 0),
          ('plaid:FOOD_AND_DRINK', 'Food and drink', NULL, 1, 'restaurant', 4294198070,
           'FOOD_AND_DRINK', $created, $created, NULL, 0);
        INSERT INTO app_settings (key, value)
        VALUES ('theme_mode', '"dark"'), ('use_dynamic_color', 'false');
        INSERT INTO app_meta (key, value) VALUES ('install_date', '2026-10-01');
      ''');
      int tick = 0;
      final AppDatabase database = AppDatabase(
        schema.newConnection(),
        wallMillis: () => migratedAt + tick++ ~/ 3,
        newNodeId: () => 'local-test',
      );
      addTearDown(database.close);
      await verifier.migrateAndValidate(database, 2);
      return database;
    }

    test('keeps every row', () async {
      final AppDatabase database = await migrated();
      expect(
        (await database.select(database.accounts).get()).map((a) => a.id),
        unorderedEquals(['acc-live', 'acc-gone']),
      );
      expect(
        (await database.select(database.transactions).get()).map((t) => t.id),
        unorderedEquals(['t-manual', 't-import', 't-cascade', 't-alone']),
      );
      expect(
        await database.select(database.transactionTags).get(),
        hasLength(2),
      );
      expect(
        await database.select(database.transactionSplits).get(),
        hasLength(2),
      );
      expect(await database.select(database.categories).get(), hasLength(2));
      expect(await database.select(database.appSettings).get(), hasLength(2));
      expect(await database.select(database.appMeta).get(), hasLength(1));
    });

    test('records a create for every user-authored row and a delete for every '
        'deleted one, at increasing clocks of one provisional node', () async {
      final AppDatabase database = await migrated();
      final List<ChangeLogRow> log = await (database.select(
        database.changeLog,
      )..orderBy([(c) => OrderingTerm.asc(c.seq)])).get();
      expect(
        [
          for (final ChangeLogRow e in log)
            '${e.entityType}/${e.entityId} ${e.operation}',
        ],
        [
          'account/acc-gone create',
          'account/acc-gone delete',
          'account/acc-live create',
          'category/user-cat create',
          'transaction/t-alone create',
          'transaction/t-alone delete',
          'transaction/t-cascade create',
          'transaction/t-cascade delete',
          'transaction/t-import create',
          'transaction/t-manual create',
          'settings/local create',
        ],
      );
      final List<Hlc> clocks = [for (final e in log) Hlc.parse(e.hlc)];
      for (int i = 1; i < clocks.length; i++) {
        expect(clocks[i].compareTo(clocks[i - 1]), greaterThan(0));
      }
      expect(clocks.map((c) => c.nodeId).toSet(), {'local-test'});
      expect(log.map((e) => e.deviceId).toSet(), {'local-test'});
      expect(log.every((e) => !e.synced && e.rejectedReason == null), isTrue);

      final Map<String, String> meta = {
        for (final SyncMetaRow row
            in await database.select(database.syncMeta).get())
          row.key: row.value,
      };
      expect(meta[SyncMetaKeys.deviceId], 'local-test');
      expect(meta[SyncMetaKeys.lastClock], clocks.last.pack());
    });

    test(
      'a create carries the whole row; a delete the tombstone and the cascade '
      'flag',
      () async {
        final AppDatabase database = await migrated();
        Future<Map<String, Object?>> payload(
          String id,
          String operation,
        ) async => jsonDecode(
          (await (database.select(database.changeLog)..where(
                    (c) =>
                        c.entityId.equals(id) & c.operation.equals(operation),
                  ))
                  .getSingle())
              .payload,
        ) as Map<String, Object?>;

        final Map<String, Object?> manual = await payload('t-manual', 'create');
        expect(manual['tags'], ['work', 'food']);
        expect(manual['splits'], [
          {
            'category_id': 'user-cat',
            'amount': {'minor_units': -1000, 'currency': 'USD'},
            'note': null,
          },
          {
            'category_id': 'plaid:FOOD_AND_DRINK',
            'amount': {'minor_units': -250, 'currency': 'USD'},
            'note': 'tip',
          },
        ]);
        expect(manual['notes'], 'with Sam');
        expect(manual['source'], 'manual');
        expect(manual[deletedWithAccountField], false);
        expect(manual.containsKey(deletedAtField), isFalse);

        final Map<String, Object?> cascade = await payload(
          't-cascade',
          'delete',
        );
        expect(
          cascade.keys,
          unorderedEquals([deletedAtField, deletedWithAccountField]),
        );
        expect(cascade[deletedWithAccountField], true);
        final Map<String, Object?> alone = await payload('t-alone', 'delete');
        expect(alone.keys, [deletedAtField]);

        final Map<String, Object?> settings = await payload('local', 'create');
        expect(settings, {'theme_mode': 'dark', 'use_dynamic_color': false});
      },
    );

    test('a deleted row takes its delete entry\'s instant', () async {
      final AppDatabase database = await migrated();
      final ChangeLogRow delete =
          await (database.select(database.changeLog)..where(
                (c) =>
                    c.entityId.equals('acc-gone') &
                    c.operation.equals('delete'),
              ))
              .getSingle();
      final AccountRow account = await (database.select(
        database.accounts,
      )..where((a) => a.id.equals('acc-gone'))).getSingle();
      expect(account.deletedAt, Hlc.parse(delete.hlc).wall);
      final TransactionRow cascaded = await (database.select(
        database.transactions,
      )..where((t) => t.id.equals('t-cascade'))).getSingle();
      expect(cascaded.deletedAt, isNotNull);
      expect(cascaded.deletedWithAccount, isTrue);
    });

    test('the field clocks are what merging the entries gives', () async {
      final AppDatabase database = await migrated();
      final Map<String, EntityRecord> folded = {};
      for (final ChangeLogRow e in await (database.select(
        database.changeLog,
      )..orderBy([(c) => OrderingTerm.asc(c.seq)])).get()) {
        final ChangeLogEntry entry = ChangeLogEntry(
          entityType: enumFromSnakeName(EntityType.values, e.entityType),
          entityId: e.entityId,
          operation: enumFromSnakeName(ChangeOperation.values, e.operation),
          payload: jsonDecode(e.payload) as Map<String, dynamic>,
          hlc: Hlc.parse(e.hlc),
          deviceId: e.deviceId,
          synced: false,
        );
        final String key = '${e.entityType}/${e.entityId}';
        folded[key] = merge(folded[key], entry).record;
      }
      final Map<String, Map<String, String>> stored = {};
      for (final RecordClockRow row
          in await database.select(database.recordClocks).get()) {
        (stored['${row.entityType}/${row.entityId}'] ??= {})[row.field] =
            row.hlc;
      }
      expect(stored.keys, unorderedEquals(folded.keys));
      for (final MapEntry<String, EntityRecord> e in folded.entries) {
        expect(stored[e.key], {
          for (final c in e.value.fieldClocks.entries) c.key: c.value.pack(),
          createClockField: e.value.createdAt!.pack(),
        }, reason: e.key);
      }
      // And the store reads back exactly the folded records from the migrated rows.
      final DriftSyncStore store = DriftSyncStore(database, testClock);
      for (final EntityRecord record in folded.values) {
        expect(
          (await store.read(record.type, record.id))!.toCanonicalJson(),
          record.toCanonicalJson(),
        );
      }
    });

    test(
      'a schema 1 database with no data migrates to an empty change log',
      () async {
        final schema = await verifier.schemaAt(1);
        final AppDatabase database = AppDatabase(
          schema.newConnection(),
          newNodeId: () => 'local-empty',
        );
        addTearDown(database.close);
        await verifier.migrateAndValidate(database, 2);
        expect(await database.select(database.changeLog).get(), isEmpty);
        expect(await database.select(database.recordClocks).get(), isEmpty);
      },
    );
  });

  group('schema 2 to 3', () {
    const int created = 1759309200000; // 2026-10-01 09:00 UTC

    test('keeps every row and adds an empty items table', () async {
      final schema = await verifier.schemaAt(2);
      schema.rawDatabase.execute('''
        INSERT INTO accounts (id, item_id, type, subtype, name, official_name, mask,
          currency, current_balance_minor, available_balance_minor, credit_limit_minor,
          balances_as_of, is_hidden, display_order, created_at, updated_at, deleted_at,
          sync_version)
        VALUES
          ('acc-manual', NULL, 'depository', NULL, 'Wallet', NULL, NULL, 'USD',
           NULL, NULL, NULL, NULL, 0, 0, $created, $created, NULL, 0),
          ('acc-linked', 'item-1', 'credit', 'credit card', 'Card', NULL, '4242', 'USD',
           -5000, NULL, 100000, $created, 1, 1, $created, $created, NULL, 3);
        INSERT INTO transactions (id, account_id, amount_minor, currency, date,
          authorized_date, pending, pending_transaction_id, name, merchant_name,
          merchant_logo_url, plaid_primary_category, plaid_detailed_category,
          user_category_id, notes, receipt_path, source, created_at, updated_at, deleted_at,
          sync_version, deleted_with_account)
        VALUES
          ('t-manual', 'acc-manual', -1250, 'USD', '2026-09-30', NULL, 0, NULL, 'Lunch',
           NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'manual', $created, $created, NULL,
           0, 0),
          ('t-plaid', 'acc-linked', -999, 'USD', '2026-09-29', NULL, 1, NULL, 'NETFLIX',
           'Netflix', NULL, 'ENTERTAINMENT', NULL, 'user-cat', 'shared', NULL, 'plaid',
           $created, $created, NULL, 7, 0);
        INSERT INTO change_log (entity_type, entity_id, operation, payload, hlc,
          device_id, synced, rejected_reason)
        VALUES ('transaction', 't-manual', 'create', '{}',
          '001759309200000-00000-local-test', 'local-test', 1, NULL);
        INSERT INTO record_clocks (entity_type, entity_id, field, hlc)
        VALUES ('transaction', 't-manual', 'name', '001759309200000-00000-local-test');
        INSERT INTO sync_meta (key, value)
        VALUES ('pull_cursor', '12'), ('device_id', 'local-test');
      ''');
      final AppDatabase database = AppDatabase(schema.newConnection());
      addTearDown(database.close);
      await verifier.migrateAndValidate(database, 3);

      expect(
        (await database.select(database.accounts).get()).map((a) => a.id),
        unorderedEquals(['acc-manual', 'acc-linked']),
      );
      final TransactionRow plaid = await (database.select(
        database.transactions,
      )..where((t) => t.id.equals('t-plaid'))).getSingle();
      expect(plaid.source, DataSource.plaid);
      expect(plaid.userCategoryId, 'user-cat');
      expect(plaid.syncVersion, 7);
      expect(await database.select(database.transactions).get(), hasLength(2));
      expect(await database.select(database.changeLog).get(), hasLength(1));
      expect(await database.select(database.recordClocks).get(), hasLength(1));
      expect(
        {
          for (final SyncMetaRow m
              in await database.select(database.syncMeta).get())
            m.key: m.value,
        },
        {'pull_cursor': '12', 'device_id': 'local-test'},
      );
      expect(await database.select(database.items).get(), isEmpty);
    });
  });

  group('schema 3 to 4', () {
    const int created = 1759309200000; // 2026-10-01 09:00 UTC
    const int migratedAt = 1761318000000; // 2026-10-24 15:00 UTC
    const String clock = '001759309200000-00000-dev-b';

    String rule(String id, {Map<String, Object?> extra = const {}}) =>
        jsonEncode({
          'id': id,
          'name': 'Coffee',
          'position': 1,
          'conditions': [
            {
              'kind': 'merchant_contains',
              'text': 'Starbucks',
              'min_amount': null,
              'max_amount': {'minor_units': 2500, 'currency': 'USD'},
            },
          ],
          'actions': [
            {'kind': 'add_tag', 'value': 'coffee'},
          ],
          'deleted_at': null,
          ...extra,
        }).replaceAll("'", "''");

    String clocks(String id, List<String> fields) =>
        [for (final String f in fields) "('rule', '$id', '$f', '$clock')"]
            .join(', ');

    test(
      'keeps every row, adds the rules table and materializes the held rules',
      () async {
        const List<String> all = [
          'id',
          'name',
          'position',
          'conditions',
          'actions',
          'deleted_at',
        ];
        final schema = await verifier.schemaAt(3);
        schema.rawDatabase.execute('''
          INSERT INTO accounts (id, item_id, type, subtype, name, official_name, mask,
            currency, current_balance_minor, available_balance_minor, credit_limit_minor,
            balances_as_of, is_hidden, display_order, created_at, updated_at, deleted_at,
            sync_version)
          VALUES ('acc-manual', NULL, 'depository', NULL, 'Wallet', NULL, NULL, 'USD',
            NULL, NULL, NULL, NULL, 0, 0, $created, $created, NULL, 0);
          INSERT INTO transactions (id, account_id, amount_minor, currency, date,
            authorized_date, pending, pending_transaction_id, name, merchant_name,
            merchant_logo_url, plaid_primary_category, plaid_detailed_category,
            user_category_id, notes, receipt_path, source, created_at, updated_at,
            deleted_at, sync_version, deleted_with_account)
          VALUES ('t-manual', 'acc-manual', -1250, 'USD', '2026-09-30', NULL, 0, NULL,
            'Lunch', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'manual', $created,
            $created, NULL, 0, 0);
          INSERT INTO held_records (entity_type, entity_id, fields, reason)
          VALUES
            ('rule', 'r-complete', '${rule('r-complete')}', 'unsupported_type'),
            ('rule', 'r-updates', '{"name":"Renamed"}', 'unsupported_type'),
            ('rule', 'r-newer', '${rule('r-newer', extra: {'priority': 2})}',
             'unsupported_type'),
            ('goal', 'g1', '{"name":"Holiday"}', 'unsupported_type');
          INSERT INTO record_clocks (entity_type, entity_id, field, hlc)
          VALUES ${clocks('r-complete', [...all, '_create'])},
            ${clocks('r-updates', ['name'])},
            ${clocks('r-newer', [...all, 'priority', '_create'])},
            ('goal', 'g1', 'name', '$clock');
          INSERT INTO sync_meta (key, value)
          VALUES ('pull_cursor', '12'), ('device_id', 'dev-a');
          INSERT INTO items (id, institution_id, institution_name, institution_logo_url,
            institution_logo, institution_color, status, error_code,
            last_successful_sync_at, pulled_at)
          VALUES ('item-1', 'ins_109508', 'First Platypus Bank', NULL, NULL, NULL,
            'healthy', NULL, $created, $created);
        ''');
        final AppDatabase database = AppDatabase(
          schema.newConnection(),
          wallMillis: () => migratedAt,
        );
        addTearDown(database.close);
        await verifier.migrateAndValidate(database, 4);

        expect(await database.select(database.accounts).get(), hasLength(1));
        expect(
          await database.select(database.transactions).get(),
          hasLength(1),
        );
        expect(await database.select(database.changeLog).get(), isEmpty);
        expect(
          (await database.select(database.items).getSingle()).institutionName,
          'First Platypus Bank',
        );
        final List<RuleRow> rules = await (database.select(
          database.rules,
        )..orderBy([(r) => OrderingTerm.asc(r.id)])).get();
        expect(rules.map((r) => r.id), ['r-complete', 'r-newer']);
        expect(rules.first.position, 1);
        expect(rules.first.createdAt.millisecondsSinceEpoch, migratedAt);
        expect(rules.first.deletedAt, isNull);
        expect(
          {
            for (final HeldRecordRow h
                in await database.select(database.heldRecords).get())
              '${h.entityType}/${h.entityId}': h.reason,
          },
          {
            'rule/r-updates': 'incomplete',
            'rule/r-newer': 'unknown_fields',
            'goal/g1': 'unsupported_type',
          },
        );
        // The records read back as they were, the unknown field included.
        final DriftSyncStore store = DriftSyncStore(database, testClock);
        final EntityRecord newer = (await store.read(
          EntityType.rule,
          'r-newer',
        ))!;
        expect(newer.fields['priority'], 2);
        expect(
          (await store.read(EntityType.rule, 'r-complete'))!.fields['actions'],
          [
            {'kind': 'add_tag', 'value': 'coffee'},
          ],
        );
        expect(
          {
            for (final SyncMetaRow m
                in await database.select(database.syncMeta).get())
              m.key: m.value,
          },
          {'pull_cursor': '12', 'device_id': 'dev-a'},
        );
      },
    );
  });
}
