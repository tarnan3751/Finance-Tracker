// What bootstrap does around the app in dev and prod: opening the local data releases
// the held records of the types this build knows, records the install date once, seeds
// the categories and imports the original app's data, and the screen shown when the
// database cannot be opened.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _FailingAccounts extends Mock implements AccountRepository {}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test(
    'openLocalData records the install date once and seeds the categories',
    () async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      ProviderContainer container(DateTime now) => ProviderContainer.test(
        overrides: [
          ...overridesFor(AppConfig.prod()),
          databaseProvider.overrideWithValue(database),
          clockProvider.overrideWithValue(
            FixedClock(now, tz.getLocation('America/New_York')),
          ),
        ],
      );
      addTearDown(database.close);

      // 02:00 UTC on 25 October is 22:00 on 24 October in New York.
      SharedPreferences.setMockInitialValues({});
      final ProviderContainer first = container(DateTime.utc(2026, 10, 25, 2));
      await openLocalData(first, locale: 'en_US');
      expect(
        await DriftAppMetaStore(database).read('install_date'),
        '2026-10-24',
      );
      expect(
        await first.read(categoryRepositoryProvider).watchAll().first,
        hasLength(systemCategories.length),
      );

      await openLocalData(
        container(DateTime.utc(2026, 12, 1)),
        locale: 'en_US',
      );
      expect(
        await DriftAppMetaStore(database).read('install_date'),
        '2026-10-24',
      );
    },
  );

  test('openLocalData releases the records held under a known type with no schema step', () async {
    // A database created at this version, so no schema step runs; a category held
    // under its raw name, as a build that did not know categories held it, and one
    // of a type this build does not know either.
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final FixedClock clock = FixedClock(
      DateTime.utc(2026, 10, 30, 12),
      tz.getLocation('America/New_York'),
    );
    final DriftSyncStore store = DriftSyncStore(database, clock);
    UnknownTypeEntry held(
      String type,
      int wall,
      ChangeOperation operation,
      Map<String, dynamic> payload,
    ) => UnknownTypeEntry(
      entityType: type,
      entityId: 'x1',
      operation: operation,
      payload: payload,
      hlc: Hlc(wall, 0, 'dev-b'),
      deviceId: 'dev-b',
    );
    await store.holdUnknownType(
      held(
        'category',
        10,
        ChangeOperation.create,
        categoryRecordJson(
          const Category(
            id: 'x1',
            name: 'Pets',
            isSystem: false,
            icon: 'pets',
            color: 0xFF00FF00,
          ),
        )..remove(deletedAtField),
      ),
    );
    await store.holdUnknownType(
      held('category', 20, ChangeOperation.update, {'name': 'Animals'}),
    );
    await store.holdUnknownType(
      held('future_type', 10, ChangeOperation.create, {'id': 'x1'}),
    );
    expect(await store.heldTypes(), {EntityType.category});

    SharedPreferences.setMockInitialValues({});
    for (int open = 0; open < 2; open++) {
      await openLocalData(
        ProviderContainer.test(
          overrides: [
            ...overridesFor(AppConfig.prod()),
            databaseProvider.overrideWithValue(database),
            clockProvider.overrideWithValue(clock),
          ],
        ),
        locale: 'en_US',
      );
      expect(
        [
          for (final HeldRecordRow row
              in await database.select(database.heldRecords).get())
            (row.entityType, row.entityId, row.reason),
        ],
        [('future_type', 'x1', 'unsupported_type')],
        reason: 'open $open',
      );
      final CategoryRow row = await (database.select(
        database.categories,
      )..where((c) => c.id.equals('x1'))).getSingle();
      expect((row.name, row.icon), ('Animals', 'pets'), reason: 'open $open');
    }
    expect(await store.heldTypes(), isEmpty);
  });

  test('openLocalData leaves records held for a lasting reason as they were', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final FixedClock clock = FixedClock(
      DateTime.utc(2026, 10, 30, 12),
      tz.getLocation('America/New_York'),
    );
    final DriftSyncStore store = DriftSyncStore(database, clock);
    final Hlc at = Hlc(10, 0, 'dev-b');
    EntityRecord complete(
      EntityType type,
      String id,
      Map<String, Object?> fields,
    ) => EntityRecord(
      type: type,
      id: id,
      fields: fields,
      fieldClocks: {for (final String f in fields.keys) f: at},
      createdAt: at,
    );
    // A field this version does not know, a rule condition it cannot represent,
    // and a goal edit of only updates with no goal to lay it on.
    await store.write(
      complete(EntityType.category, 'c1', {
        ...categoryRecordJson(
          const Category(
            id: 'c1',
            name: 'Pets',
            isSystem: false,
            icon: 'pets',
            color: 0xFF00FF00,
          ),
        )..remove(deletedAtField),
        'mood': 'calm',
      }),
    );
    await store.write(
      complete(EntityType.rule, 'r1', {
        ...ruleRecordJson(
          const Rule(
            id: 'r1',
            name: 'Coffee',
            position: 0,
            conditions: [
              RuleCondition(kind: RuleConditionKind.account, text: 'a1'),
            ],
            actions: [RuleAction(kind: RuleActionKind.addTag, value: 'x')],
          ),
        ),
        'conditions': [
          {'kind': 'weekday_is', 'text': 'monday'},
        ],
      }),
    );
    await store.write(
      EntityRecord(
        type: EntityType.goal,
        id: 'g1',
        fields: const {'name': 'Holiday'},
        fieldClocks: {'name': at},
      ),
    );
    // The held rows, by type (their fields decoded: a release writes them again, equal
    // but not always in the same key order), and the records as the store reads them.
    Future<List<Object>> heldState() async => [
      ...<List<Object?>>[
        for (final HeldRecordRow row
            in await database.select(database.heldRecords).get())
          [row.entityType, row.entityId, jsonDecode(row.fields), row.reason],
      ]..sort((a, b) => '${a[0]}'.compareTo('${b[0]}')),
      for (final (EntityType type, String id) in [
        (EntityType.category, 'c1'),
        (EntityType.rule, 'r1'),
        (EntityType.goal, 'g1'),
      ])
        (await store.read(type, id))!.toString(),
    ];
    expect(
      {
        for (final HeldRecordRow row
            in await database.select(database.heldRecords).get())
          row.entityId: row.reason,
      },
      {'c1': 'unknown_fields', 'r1': 'unrepresentable', 'g1': 'incomplete'},
    );
    final List<Object> before = await heldState();

    SharedPreferences.setMockInitialValues({});
    for (int open = 0; open < 2; open++) {
      await openLocalData(
        ProviderContainer.test(
          overrides: [
            ...overridesFor(AppConfig.prod()),
            databaseProvider.overrideWithValue(database),
            clockProvider.overrideWithValue(clock),
          ],
        ),
        locale: 'en_US',
      );
      expect(await heldState(), before, reason: 'open $open');
    }
  });

  test(
    'a release that throws is logged and the app still opens, the record held',
    () async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final FixedClock clock = FixedClock(
        DateTime.utc(2026, 10, 30, 12),
        tz.getLocation('America/New_York'),
      );
      final List<LogRecord> logs = [];
      final StreamSubscription<LogRecord> logging = Logger.root.onRecord.listen(
        logs.add,
      );
      addTearDown(logging.cancel);
      ProviderContainer container() => ProviderContainer.test(
        overrides: [
          ...overridesFor(AppConfig.prod()),
          databaseProvider.overrideWithValue(database),
          clockProvider.overrideWithValue(clock),
        ],
      );
      // A held category whose fields do not decode: reading it back throws.
      await database
          .into(database.recordClocks)
          .insert(
            RecordClocksCompanion.insert(
              entityType: 'category',
              entityId: 'bad',
              field: 'name',
              hlc: Hlc(10, 0, 'dev-b').pack(),
            ),
          );
      await database
          .into(database.heldRecords)
          .insert(
            HeldRecordsCompanion.insert(
              entityType: 'category',
              entityId: 'bad',
              fields: '{"name":',
              reason: 'unknown_fields',
            ),
          );

      SharedPreferences.setMockInitialValues({});
      await openLocalData(container(), locale: 'en_US');
      expect(
        [
          for (final LogRecord r in logs)
            if (r.level == Level.WARNING) r.message,
        ],
        ['releasing the held records failed: FormatException'],
      );
      expect(
        await DriftAppMetaStore(database).read('install_date'),
        '2026-10-30',
      );
      expect(
        [
          for (final HeldRecordRow row
              in await database.select(database.heldRecords).get())
            (row.entityId, row.fields),
        ],
        [('bad', '{"name":')],
      );

      // Once the row reads back, the next launch releases it with no warning.
      await database.delete(database.recordClocks).go();
      await database.delete(database.heldRecords).go();
      await DriftSyncStore(database, clock).holdUnknownType(
        UnknownTypeEntry(
          entityType: 'category',
          entityId: 'bad',
          operation: ChangeOperation.create,
          payload: categoryRecordJson(
            const Category(
              id: 'bad',
              name: 'Pets',
              isSystem: false,
              icon: 'pets',
              color: 0xFF00FF00,
            ),
          )..remove(deletedAtField),
          hlc: Hlc(10, 0, 'dev-b'),
          deviceId: 'dev-b',
        ),
      );
      logs.clear();
      await openLocalData(container(), locale: 'en_US');
      expect(logs.where((r) => r.level >= Level.WARNING), isEmpty);
      expect(await database.select(database.heldRecords).get(), isEmpty);
      expect(
        (await (database.select(
          database.categories,
        )..where((c) => c.id.equals('bad'))).getSingle()).name,
        'Pets',
      );
    },
  );

  test(
    'openLocalData imports the original app once and keeps the summary',
    () async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      SharedPreferences.setMockInitialValues({
        'transactions': '[{"amount":12.5,"description":"Lunch"}]',
        'incomes': '[{"amount":100.0,"description":"Gift"}]',
        'totalBalance': 87.5,
      });
      final ProviderContainer container = ProviderContainer.test(
        overrides: [
          ...overridesFor(AppConfig.prod()),
          databaseProvider.overrideWithValue(database),
        ],
      );

      await openLocalData(container, locale: 'en_GB');

      expect(
        container.read(legacyImportResultProvider),
        ImportSummary(transactions: 2, total: Money(8750, 'GBP'), skipped: 0),
      );
      expect(
        (await container.read(accountRepositoryProvider).watchAll().first)
            .single
            .currencyCode,
        'GBP',
      );
    },
  );

  test(
    'a failing import does not stop startup and runs again next time',
    () async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      SharedPreferences.setMockInitialValues({
        'transactions': '[{"amount":1.0,"description":"x"}]',
      });
      final _FailingAccounts accounts = _FailingAccounts();
      when(
        accounts.watchAll,
      ).thenAnswer((_) => Stream.error(const FileSystemException('disk full')));
      final ProviderContainer container = ProviderContainer.test(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.prod()),
          databaseProvider.overrideWithValue(database),
          accountRepositoryProvider.overrideWithValue(accounts),
        ],
      );

      await openLocalData(container, locale: 'en_US');

      expect(container.read(legacyImportResultProvider), isNull);
      expect(
        await DriftAppMetaStore(database).read('legacy_import_done'),
        isNull,
      );
      expect(
        (await SharedPreferences.getInstance()).containsKey('transactions'),
        isTrue,
      );
    },
  );

  test(
    'a damaged file fails the open with a failure shown as "other"',
    () async {
      final Directory directory = Directory.systemTemp.createTempSync(
        'ft-corrupt-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final File file = File('${directory.path}/finance_tracker.db');
      final AppDatabase original = AppDatabase(
        await openDatabaseExecutor(file, keyStore: null),
      );
      await original.verifyOpen();
      await original.close();
      // Keep the 100-byte header, overwrite the schema on the rest of the first page.
      final RandomAccessFile raf = file.openSync(
        mode: FileMode.writeOnlyAppend,
      );
      raf.setPositionSync(100);
      raf.writeFromSync(List<int>.filled(3996, 0x5A));
      raf.closeSync();

      Object? failure;
      try {
        final AppDatabase damaged = AppDatabase(
          await openDatabaseExecutor(file, keyStore: null),
        );
        final ProviderContainer container = ProviderContainer.test(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.prod()),
            databaseProvider.overrideWithValue(damaged),
          ],
        );
        await openLocalData(container, locale: 'en_US');
      } catch (e) {
        failure = e;
      }
      expect(
        failure,
        isA<SqliteException>().having((e) => e.resultCode, 'resultCode', 11),
      );
      expect(databaseFailureOf(failure!), DatabaseFailure.other);
    },
  );

  test('the typed open failures keep their own message', () {
    expect(
      databaseFailureOf(const EncryptionUnavailableException()),
      DatabaseFailure.encryptionUnavailable,
    );
    expect(
      databaseFailureOf(const DatabaseKeyMismatchException()),
      DatabaseFailure.keyMismatch,
    );
    expect(
      databaseFailureOf(const DatabaseKeyLostException()),
      DatabaseFailure.keyLost,
    );
    expect(
      databaseFailureOf(StateError('No migration from schema 2 to 1')),
      DatabaseFailure.other,
    );
  });

  for (final (DatabaseFailure failure, String text) in [
    (DatabaseFailure.encryptionUnavailable, 'cannot encrypt data'),
    (DatabaseFailure.keyMismatch, 'does not open with its key'),
    (DatabaseFailure.keyLost, 'is missing or unreadable'),
    (DatabaseFailure.other, 'could not open its data'),
  ]) {
    testWidgets(
      'the database error screen explains ${failure.name}, light and dark',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(child: DatabaseErrorApp(failure: failure)),
        );
        expect(find.text("Your data can't be opened"), findsOneWidget);
        expect(find.textContaining(text), findsOneWidget);
        expect(find.textContaining('Nothing has been deleted'), findsOneWidget);
        await expectLater(tester, meetsGuideline(textContrastGuideline));

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      },
    );
  }
}
