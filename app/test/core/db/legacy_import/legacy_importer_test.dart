// The legacy importer against the original app's shared_preferences shape
// (`git show fdf69c0:lib/main.dart`: jsonEncode of [{"amount": double, "description":
// String}] under `transactions` and `incomes`, and `totalBalance` as a double).
import 'dart:convert';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/db/legacy_import/legacy_importer.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late InMemoryStore store;
  late InMemoryAccountRepository accounts;
  late InMemoryTransactionRepository transactions;
  late InMemoryAppMetaStore meta;
  late Clock clock;

  setUp(() {
    // 03:00 UTC on 25 October is 23:00 on 24 October in New York.
    clock = FixedClock(
      DateTime.utc(2026, 10, 25, 3),
      tz.getLocation('America/New_York'),
    );
    store = InMemoryStore(clock);
    accounts = InMemoryAccountRepository(
      store,
      recorder: const NoChangeRecorder(),
    );
    transactions = InMemoryTransactionRepository(
      store,
      recorder: const NoChangeRecorder(),
    );
    meta = InMemoryAppMetaStore();
  });
  tearDown(() => store.close());

  Future<LegacyImporter> importer({String locale = 'en_US'}) async =>
      LegacyImporter(
        preferences: await SharedPreferences.getInstance(),
        accounts: accounts,
        transactions: transactions,
        meta: meta,
        clock: clock,
        locale: locale,
      );

  // What the original app's _saveData wrote.
  void original(
    List<Map<String, Object>> expenses,
    List<Map<String, Object>> incomes,
  ) => SharedPreferences.setMockInitialValues({
    'transactions': jsonEncode(expenses),
    'incomes': jsonEncode(incomes),
    'totalBalance': 0.0,
  });

  Future<List<Transaction>> imported() =>
      transactions.watch(TransactionQuery.all).first;

  test(
    'imports both lists into one Imported account, then removes them',
    () async {
      original(
        [
          {'amount': 12.5, 'description': 'Lunch'},
          {'amount': 3.0, 'description': 'Coffee'},
        ],
        [
          {'amount': 1000.0, 'description': 'Salary'},
        ],
      );

      final ImportSummary? summary = await (await importer()).runIfNeeded();

      expect(
        summary,
        ImportSummary(transactions: 3, total: Money(98450, 'USD'), skipped: 0),
      );
      final List<Account> all = await accounts.watchAll().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Imported');
      expect(all.single.type, AccountType.depository);
      expect(all.single.currencyCode, 'USD');

      final List<Transaction> records = await imported();
      expect(
        {for (final t in records) t.name: t.amount},
        {
          'Lunch': Money(-1250, 'USD'),
          'Coffee': Money(-300, 'USD'),
          'Salary': Money(100000, 'USD'),
        },
      );
      for (final Transaction t in records) {
        expect(t.source, DataSource.import);
        expect(t.date, LocalDate(2026, 10, 24));
        expect(t.merchantName, isNull);
        expect(t.accountId, all.single.id);
        expect(t.pending, isFalse);
      }
      expect(
        await accounts.watchDerivedBalance(all.single.id).first,
        Money(98450, 'USD'),
      );

      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      for (final String key in legacyKeys) {
        expect(preferences.containsKey(key), isFalse, reason: key);
      }
      expect(await meta.read('legacy_import_done'), '2026-10-24');
    },
  );

  test('float error is rounded at the currency scale', () async {
    original(
      [
        {'amount': 0.1 + 0.2, 'description': 'a'},
        {'amount': 1.005, 'description': 'b'},
        {'amount': 2.675, 'description': 'c'},
      ],
      [
        {'amount': 1e-9, 'description': 'd'},
      ],
    );
    await (await importer()).runIfNeeded();
    expect(
      {for (final t in await imported()) t.name: t.amount.minorUnits},
      {
        'a': -30,
        'b': -100, // 1.005 is 1.00499999... as a double
        'c': -267, // 2.675 is 2.67499999...
        'd': 0,
      },
    );
  });

  test('a negative or integral entry keeps the original arithmetic', () async {
    SharedPreferences.setMockInitialValues({
      // jsonEncode(5.0) is "5.0", but an int survives a hand-edited store.
      'transactions': '[{"amount": -5.0, "description": "refund"}]',
      'incomes': '[{"amount": 7, "description": "gift"}]',
    });
    await (await importer()).runIfNeeded();
    expect(
      {for (final t in await imported()) t.name: t.amount},
      {'refund': Money(500, 'USD'), 'gift': Money(700, 'USD')},
    );
  });

  test("the currency is the locale's, at its scale", () async {
    original([
      {'amount': 1234.4, 'description': 'Ramen'},
    ], []);
    await (await importer(locale: 'ja_JP')).runIfNeeded();
    final Account account = (await accounts.watchAll().first).single;
    expect(account.currencyCode, 'JPY');
    expect((await imported()).single.amount, Money(-1234, 'JPY'));
  });

  test('a locale intl does not know falls back to USD', () async {
    original([
      {'amount': 1.0, 'description': 'x'},
    ], []);
    await (await importer(locale: 'xx_YY')).runIfNeeded();
    expect((await accounts.watchAll().first).single.currencyCode, 'USD');
  });

  test('an empty store imports nothing and is marked done', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await (await importer()).runIfNeeded(), isNull);
    expect(await accounts.watchAll().first, isEmpty);
    expect(await meta.read('legacy_import_done'), isNotNull);
  });

  test('empty lists import nothing and are removed', () async {
    original([], []);
    expect(await (await importer()).runIfNeeded(), isNull);
    expect(await accounts.watchAll().first, isEmpty);
    expect(
      (await SharedPreferences.getInstance()).containsKey('transactions'),
      isFalse,
    );
  });

  test('a second run does nothing', () async {
    original([
      {'amount': 1.0, 'description': 'x'},
    ], []);
    await (await importer()).runIfNeeded();
    original([
      {'amount': 2.0, 'description': 'y'},
    ], []);
    expect(await (await importer()).runIfNeeded(), isNull);
    expect((await imported()).map((t) => t.name), ['x']);
  });

  test(
    'a run interrupted before it was marked done does not duplicate',
    () async {
      original(
        [
          {'amount': 1.0, 'description': 'x'},
        ],
        [
          {'amount': 2.0, 'description': 'y'},
        ],
      );
      await (await importer()).runIfNeeded();
      // As if the app died after writing the records and before recording the import.
      meta = InMemoryAppMetaStore();
      original(
        [
          {'amount': 1.0, 'description': 'x'},
        ],
        [
          {'amount': 2.0, 'description': 'y'},
        ],
      );
      await (await importer()).runIfNeeded();
      expect(await imported(), hasLength(2));
      expect(await accounts.watchAll().first, hasLength(1));
    },
  );

  test('unreadable entries are skipped and the legacy data is kept', () async {
    SharedPreferences.setMockInitialValues({
      'transactions': jsonEncode([
        {'amount': 4.5, 'description': 'ok'},
        {'amount': '4.5', 'description': 'amount as text'},
        {'amount': 1e300, 'description': 'too large'},
        {'description': 'no amount'},
        'not an object',
      ]),
      'incomes': 'not json',
    });
    final ImportSummary? summary = await (await importer()).runIfNeeded();
    expect(
      summary,
      ImportSummary(transactions: 1, total: Money(-450, 'USD'), skipped: 5),
    );
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('transactions'), isTrue);
    expect(preferences.containsKey('incomes'), isTrue);
    expect(await (await importer()).runIfNeeded(), isNull);
  });

  test('the Imported account goes after the existing accounts', () async {
    await accounts.upsert(
      const Account(
        id: 'mine',
        type: AccountType.credit,
        name: 'Card',
        currencyCode: 'USD',
        isHidden: false,
        displayOrder: 4,
      ),
    );
    original([
      {'amount': 1.0, 'description': 'x'},
    ], []);
    await (await importer()).runIfNeeded();
    expect(
      (await accounts.watchById(LegacyImporter.accountId).first)!.displayOrder,
      5,
    );
  });

  test(
    'an interrupted run resumes in the Imported account\'s currency',
    () async {
      // An earlier run created the account in euros, then the device locale changed.
      await accounts.upsert(
        Account(
          id: LegacyImporter.accountId,
          type: AccountType.depository,
          name: 'Renamed by the user',
          currencyCode: 'EUR',
          isHidden: false,
          displayOrder: 0,
        ),
      );
      original([
        {'amount': 2.5, 'description': 'x'},
      ], []);
      final ImportSummary? summary = await (await importer(locale: 'ja_JP'))
          .runIfNeeded();

      expect(
        summary,
        ImportSummary(transactions: 1, total: Money(-250, 'EUR'), skipped: 0),
      );
      final Account account = (await accounts.watchAll().first).single;
      expect(account.currencyCode, 'EUR');
      expect(account.name, 'Renamed by the user');
    },
  );

  test('a deleted Imported account stops the import for good', () async {
    await accounts.upsert(
      Account(
        id: LegacyImporter.accountId,
        type: AccountType.depository,
        name: 'Imported',
        currencyCode: 'USD',
        isHidden: false,
        displayOrder: 0,
      ),
    );
    await accounts.delete(LegacyImporter.accountId);
    original([
      {'amount': 1.0, 'description': 'x'},
    ], []);

    expect(await (await importer()).runIfNeeded(), isNull);
    expect(await accounts.watchAll().first, isEmpty);
    expect(await imported(), isEmpty);
    expect(await meta.read('legacy_import_done'), isNotNull);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    for (final String key in legacyKeys) {
      expect(preferences.containsKey(key), isFalse, reason: key);
    }
    expect(await (await importer()).runIfNeeded(), isNull);
  });

  test(
    'a resumed run neither counts nor sums a transaction the user deleted',
    () async {
      List<Map<String, Object>> expenses() => [
        {'amount': 1.0, 'description': 'a'},
        {'amount': 2.0, 'description': 'b'},
        {'amount': 4.0, 'description': 'c'},
      ];
      original(expenses(), []);
      await (await importer()).runIfNeeded();
      // As if the app died before recording the import, and the user then deleted "b".
      final String b = (await imported()).singleWhere((t) => t.name == 'b').id;
      await transactions.delete(b);
      meta = InMemoryAppMetaStore();
      original(expenses(), []);

      final ImportSummary? summary = await (await importer()).runIfNeeded();

      expect(
        summary,
        ImportSummary(transactions: 2, total: Money(-500, 'USD'), skipped: 0),
      );
      expect(
        (await imported()).map((t) => t.name),
        unorderedEquals(['a', 'c']),
      );
    },
  );
}
