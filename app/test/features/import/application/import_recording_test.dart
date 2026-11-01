// The import on the dev wiring (Drift, the change recorder): every row written is
// recorded once for sync as an `import` upsert, and the undo records a tombstone for each.
// With 10,000 rows, every row lands, the parse and the write each well inside two
// minutes (about a quarter of a second and two and a half seconds on the
// development Mac).
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:finance_tracker/features/import/application/import_providers.dart';
import 'package:finance_tracker/features/import/domain/csv_reader.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../contract/repository_fixture.dart';
import '../../../helpers/dev_wiring.dart';
import '../import_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ProviderContainer container;
  late Account account;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.customStatement(
      'INSERT INTO app_meta (key, value) VALUES (?, ?)',
      [AppMetaKeys.restoreOfferAnswered, '2026-10-24T15:00:00.000Z'],
    );
    final SteppingClock clock = SteppingClock();
    container = ProviderContainer.test(
      overrides: [
        ...devWiring(),
        ...fakeApiOverrides(signedIn: true),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        syncDeviceIdProvider.overrideWithValue('dev-a'),
      ],
    );
    account = const Account(
      id: 'manual-checking',
      type: AccountType.depository,
      name: 'Checking',
      currencyCode: 'USD',
      isHidden: false,
      displayOrder: 0,
    );
    await container.read(accountRepositoryProvider).create(account);
  });
  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<List<ChangeLogRow>> transactionEntries() async => [
    for (final ChangeLogRow row
        in await database.select(database.changeLog).get())
      if (row.entityType == 'transaction') row,
  ];

  Future<ImportResult> import(PickedCsv file) async {
    final ImportActions actions = container.read(importActionsProvider);
    final CsvTable table = await actions.read(file);
    return actions.write(
      await actions.review(
        file: file,
        table: table,
        headerRow: 0,
        mapping: plainMapping(),
        target: ExistingAccount(account),
      ),
      includeDuplicates: false,
    );
  }

  test(
    'each row is recorded once as an import; the undo, a tombstone each',
    () async {
      final ImportResult result = await import(
        pickedCsv(
          'Date,Description,Amount\n'
          '2026-10-20,One,-1.00\n'
          '2026-10-21,Two,-2.00\n'
          '2026-10-22,Three,3.00\n',
        ),
      );
      final List<ChangeLogRow> written = await transactionEntries();
      expect(written, hasLength(3));
      expect(written.map((e) => e.entityId).toSet(), {
        ...result.batch.transactionIds,
      });
      for (final ChangeLogRow e in written) {
        expect(e.operation, 'create');
        expect(
          (jsonDecode(e.payload) as Map<String, Object?>)['source'],
          'import',
        );
      }
      await container.read(importActionsProvider).undo(result.batch);
      final List<ChangeLogRow> deletes = [
        for (final ChangeLogRow e in await transactionEntries())
          if (e.operation == 'delete') e,
      ];
      expect(deletes.map((e) => e.entityId).toSet(), {
        ...result.batch.transactionIds,
      });
      expect(
        await currentValue(
          container
              .read(transactionRepositoryProvider)
              .watch(TransactionQuery(accountIds: {account.id})),
        ),
        isEmpty,
      );
    },
  );

  test('10,000 rows: the parse and the write', () async {
    final StringBuffer csv = StringBuffer('Date,Description,Amount\n');
    final LocalDate start = LocalDate(2020, 1, 1);
    for (int i = 0; i < 10000; i++) {
      final LocalDate d = start.addDays(i ~/ 5);
      csv.write(
        '${d.toIso()},MERCHANT ${i % 97} PURCHASE,-${i % 500}.${i % 100}\n',
      );
    }
    final PickedCsv file = pickedCsv(csv.toString());
    final ImportActions actions = container.read(importActionsProvider);
    final Stopwatch parse = Stopwatch()..start();
    final CsvTable table = await actions.read(file);
    final ImportReview review = await actions.review(
      file: file,
      table: table,
      headerRow: 0,
      mapping: plainMapping(),
      target: ExistingAccount(account),
    );
    parse.stop();
    final Stopwatch write = Stopwatch()..start();
    final ImportResult result = await actions.write(
      review,
      includeDuplicates: false,
    );
    write.stop();
    expect(result.batch.count + review.failures.length, 10000);
    expect(parse.elapsed, lessThan(const Duration(minutes: 2)));
    expect(write.elapsed, lessThan(const Duration(minutes: 2)));
    expect(
      await container
          .read(transactionRepositoryProvider)
          .count(TransactionQuery(accountIds: {account.id})),
      result.batch.count,
    );
  });
}
