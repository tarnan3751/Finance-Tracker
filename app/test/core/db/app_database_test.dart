// The schema's constraints: provenance and account type CHECKs that match the enums, the
// cascade from transactions to their tags and splits, and foreign keys switched on.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  final DateTime at = DateTime.utc(2026, 10, 24, 12);

  TransactionsCompanion row(String id, DataSource source) =>
      TransactionsCompanion.insert(
        id: id,
        accountId: 'a1',
        amountMinor: -100,
        currency: 'USD',
        date: LocalDate(2026, 10, 24),
        pending: false,
        name: 'Coffee',
        source: source,
        createdAt: at,
        updatedAt: at,
      );

  test('every DataSource value is stored under its JSON name', () async {
    for (final DataSource source in DataSource.values) {
      await database
          .into(database.transactions)
          .insert(row(source.name, source));
    }
    final List<QueryRow> rows = await database
        .customSelect('SELECT id, source FROM transactions ORDER BY id')
        .get();
    for (final QueryRow r in rows) {
      final DataSource source = DataSource.values.byName(r.read<String>('id'));
      final Object? json = Transaction(
        id: 't',
        accountId: 'a',
        amount: Money(0, 'USD'),
        date: LocalDate(2026, 1, 1),
        pending: false,
        name: 'n',
        source: source,
        createdAt: at,
        updatedAt: at,
        syncVersion: 0,
      ).toJson()['source'];
      expect(r.read<String>('source'), json);
    }
  });

  test('a source outside the five provenance values is refused', () async {
    await database
        .into(database.transactions)
        .insert(row('t1', DataSource.manual));
    await expectLater(
      database.customStatement(
        "UPDATE transactions SET source = 'bank' WHERE id = 't1'",
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('every AccountType value is accepted under its JSON name', () async {
    for (final AccountType type in AccountType.values) {
      await database
          .into(database.accounts)
          .insert(
            AccountsCompanion.insert(
              id: type.name,
              type: type,
              name: 'Account',
              currency: 'USD',
              isHidden: false,
              displayOrder: 0,
              createdAt: at,
              updatedAt: at,
            ),
          );
      final Object? json = Account(
        id: 'a',
        type: type,
        name: 'n',
        currencyCode: 'USD',
        isHidden: false,
        displayOrder: 0,
      ).toJson()['type'];
      expect(type.name, json);
    }
    await expectLater(
      database.customStatement(
        "UPDATE accounts SET type = 'brokerage' WHERE id = 'loan'",
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test(
    'foreign keys are on, and tags and splits go with their transaction',
    () async {
      await expectLater(
        database
            .into(database.transactionTags)
            .insert(
              TransactionTagsCompanion.insert(
                transactionId: 'missing',
                position: 0,
                tag: 'x',
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      await database
          .into(database.transactions)
          .insert(row('t1', DataSource.manual));
      await database
          .into(database.transactionTags)
          .insert(
            TransactionTagsCompanion.insert(
              transactionId: 't1',
              position: 0,
              tag: 'x',
            ),
          );
      await database
          .into(database.transactionSplits)
          .insert(
            TransactionSplitsCompanion.insert(
              transactionId: 't1',
              position: 0,
              categoryId: 'c',
              amountMinor: -100,
            ),
          );
      await database.customStatement(
        "DELETE FROM transactions WHERE id = 't1'",
      );

      expect(await database.select(database.transactionTags).get(), isEmpty);
      expect(await database.select(database.transactionSplits).get(), isEmpty);
    },
  );
}
