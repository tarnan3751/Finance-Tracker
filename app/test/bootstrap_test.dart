// What bootstrap does around the app in dev and prod: opening the local data records the
// install date once and seeds the categories, and the screen shown when the database
// cannot be opened.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
      final ProviderContainer first = container(DateTime.utc(2026, 10, 25, 2));
      await openLocalData(first);
      expect(
        await DriftAppMetaStore(database).read('install_date'),
        '2026-10-24',
      );
      expect(
        await first.read(categoryRepositoryProvider).watchAll().first,
        hasLength(systemCategories.length),
      );

      await openLocalData(container(DateTime.utc(2026, 12, 1)));
      expect(
        await DriftAppMetaStore(database).read('install_date'),
        '2026-10-24',
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
        await openLocalData(container);
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
