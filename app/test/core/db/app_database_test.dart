// The schema's constraints: provenance, account type, Item status and budget period CHECKs
// that match the enums (an Item status stored under its JSON name), a budget's start day, the cascade from transactions to their tags and splits, and foreign keys switched on.
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

  test('every ItemStatus value is stored under its JSON name', () async {
    for (final ItemStatus status in ItemStatus.values) {
      await database
          .into(database.items)
          .insert(
            ItemsCompanion.insert(
              id: status.name,
              institutionId: 'ins_1',
              institutionName: 'Bank',
              status: status,
              pulledAt: at,
            ),
          );
      final QueryRow stored = await database
          .customSelect(
            'SELECT status FROM items WHERE id = ?',
            variables: [Variable.withString(status.name)],
          )
          .getSingle();
      final Object? json = Item(
        id: 'i',
        institutionId: 'ins_1',
        status: status,
      ).toJson()['status'];
      expect(stored.read<String>('status'), json);
      expect(
        (await (database.select(
          database.items,
        )..where((i) => i.id.equals(status.name))).getSingle()).status,
        status,
      );
    }
    await expectLater(
      database.customStatement(
        "UPDATE items SET status = 'broken' WHERE id = 'healthy'",
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('every BudgetPeriodKind value is stored under its JSON name, and a '
      'start day outside 1 to 28 is refused', () async {
    for (final BudgetPeriodKind period in BudgetPeriodKind.values) {
      final Budget budget = Budget(
        id: period.name,
        categoryId: 'c1',
        period: period,
        periodStartDay: 28,
        amount: Money(40000, 'USD'),
        rollover: false,
        startDate: LocalDate(2026, 10, 1),
      );
      await database
          .into(database.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: budget.id,
              categoryId: budget.categoryId,
              period: period,
              periodStartDay: budget.periodStartDay,
              amountMinor: 40000,
              currency: 'USD',
              rollover: false,
              startDate: budget.startDate,
              createdAt: at,
              updatedAt: at,
            ),
          );
      final QueryRow stored = await database
          .customSelect(
            'SELECT period FROM budgets WHERE id = ?',
            variables: [Variable.withString(period.name)],
          )
          .getSingle();
      expect(stored.read<String>('period'), budget.toJson()['period']);
    }
    for (final String change in [
      "period = 'weekly'",
      'period_start_day = 29',
      'period_start_day = 0',
    ]) {
      await expectLater(
        database.customStatement('UPDATE budgets SET $change'),
        throwsA(isA<SqliteException>()),
        reason: change,
      );
    }
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
