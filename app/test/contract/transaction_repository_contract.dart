// The contract every TransactionRepository implementation passes (Drift, in memory, demo),
// each from its own test file under test/features/transactions/data/. Call
// runTransactionRepositoryContract with a factory for a fresh, empty fixture and, when it
// holds resources, a dispose that releases the one the factory made last.
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// Registers the contract tests for the fixtures [create] builds.
void runTransactionRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('TransactionRepository contract', () {
    late RepositoryFixture f;
    late TransactionRepository transactions;

    setUp(() async {
      f = await create();
      transactions = f.transactions;
      await f.accounts.upsert(testAccount('a1'));
      await f.accounts.upsert(testAccount('a2'));
    });
    if (dispose != null) tearDown(dispose);

    Future<List<String>> ids(TransactionQuery query) async =>
        (await transactions.watch(query).first).map((t) => t.id).toList();

    test('a fresh repository is empty', () async {
      expect(await transactions.watch(TransactionQuery.all).first, isEmpty);
      expect(await transactions.watchById('t1').first, isNull);
      expect(await transactions.count(TransactionQuery.all), 0);
    });

    test('every field, the tags and the splits round-trip', () async {
      final Transaction t = Transaction(
        id: 't1',
        accountId: 'a1',
        amount: Money(-12345, 'USD'),
        date: LocalDate(2026, 10, 20),
        authorizedDate: LocalDate(2026, 10, 19),
        pending: true,
        pendingTransactionId: 'p1',
        name: 'WHOLEFDS MKT 10234',
        merchantName: 'Whole Foods Market',
        merchantLogoUrl: Uri.parse('https://example.com/logo.png'),
        plaidPrimaryCategory: 'FOOD_AND_DRINK',
        plaidDetailedCategory: 'FOOD_AND_DRINK_GROCERIES',
        userCategoryId: 'c1',
        notes: 'Weekly shop',
        tags: const ['household', 'weekly', 'household'],
        splits: [
          TransactionSplit(categoryId: 'c1', amount: Money(-10000, 'USD')),
          TransactionSplit(
            categoryId: 'c2',
            amount: Money(-2345, 'USD'),
            note: 'Soap',
          ),
        ],
        receiptPath: 'receipts/t1.jpg',
        source: DataSource.import,
        createdAt: DateTime.utc(2026, 10, 20, 9, 0, 0, 1),
        updatedAt: DateTime.utc(2026, 10, 21, 9, 0, 0, 999),
        syncVersion: 4,
      );
      await transactions.upsert(t);
      expect(await transactions.watchById('t1').first, t);
      expect(await transactions.watch(TransactionQuery.all).first, [t]);
    });

    test('an upsert is seen by a watcher', () async {
      final Transaction t = testTransaction('t1', 'a1', -100);
      final Future<void> seen = expectLater(
        transactions.watch(TransactionQuery.all),
        emitsInOrder([
          isEmpty,
          [t],
        ]),
      );
      await pumpEventQueue();
      await transactions.upsert(t);
      await seen;
    });

    test('an update replaces the tags and splits', () async {
      await transactions.upsert(
        testTransaction(
          't1',
          'a1',
          -300,
          tags: const ['a', 'b'],
          splits: [
            TransactionSplit(categoryId: 'c1', amount: Money(-100, 'USD')),
            TransactionSplit(categoryId: 'c2', amount: Money(-200, 'USD')),
          ],
        ),
      );
      final Transaction updated = testTransaction(
        't1',
        'a1',
        -300,
        tags: const ['c'],
        splits: [
          TransactionSplit(categoryId: 'c3', amount: Money(-300, 'USD')),
        ],
      );
      final Future<void> seen = expectLater(
        transactions.watchById('t1'),
        emitsThrough(updated),
      );
      await pumpEventQueue();
      await transactions.upsert(updated);
      await seen;

      final Transaction cleared = testTransaction('t1', 'a1', -300);
      await transactions.upsert(cleared);
      expect(await transactions.watchById('t1').first, cleared);
    });

    test('createdAt and updatedAt must be UTC milliseconds', () async {
      final Transaction t = testTransaction('t1', 'a1', -100);
      for (final Transaction bad in [
        t.copyWith(createdAt: t.createdAt.toLocal()),
        t.copyWith(updatedAt: t.updatedAt.toLocal()),
        t.copyWith(createdAt: t.createdAt.add(const Duration(microseconds: 1))),
        t.copyWith(updatedAt: t.updatedAt.add(const Duration(microseconds: 1))),
      ]) {
        await expectLater(transactions.upsert(bad), throwsArgumentError);
      }
      expect(await transactions.count(TransactionQuery.all), 0);
    });

    test('deletedAt in an upsert is ignored', () async {
      final Transaction t = testTransaction('t1', 'a1', -100);
      await transactions.upsert(t.copyWith(deletedAt: testInstant));
      expect(await transactions.watchById('t1').first, t);
    });

    test('a delete hides the transaction; restore brings it back, updatedAt stamped', () async {
      final Transaction t = testTransaction(
        't1',
        'a1',
        -100,
        tags: const ['x'],
      );
      await transactions.upsert(t);
      final Future<void> gone = expectLater(
        transactions.watchById('t1'),
        emitsThrough(isNull),
      );
      await pumpEventQueue();
      await transactions.delete('t1');
      await gone;
      expect(await transactions.count(TransactionQuery.all), 0);
      await transactions.delete('t1');
      await transactions.delete('missing');

      f.clock.frozen = true;
      final DateTime restoredAt = f.clock.nowUtc();
      await transactions.restore('t1');
      expect(
        await transactions.watchById('t1').first,
        t.copyWith(updatedAt: restoredAt),
      );
      await transactions.restore('t1');
      await transactions.restore('missing');
    });

    test(
      'an upsert of a deleted transaction throws EntityDeletedException',
      () async {
        await transactions.upsert(testTransaction('t1', 'a1', -100));
        await transactions.delete('t1');
        await expectLater(
          transactions.upsert(testTransaction('t1', 'a1', -200)),
          throwsA(isA<EntityDeletedException>()),
        );
        expect(await transactions.watchById('t1').first, isNull);
      },
    );

    test(
      'a missing or deleted account is an AccountNotFoundException',
      () async {
        await expectLater(
          transactions.upsert(testTransaction('t1', 'nope', -100)),
          throwsA(isA<AccountNotFoundException>()),
        );
        await transactions.upsert(testTransaction('t2', 'a2', -100));
        await f.accounts.delete('a2');
        await expectLater(
          transactions.upsert(testTransaction('t3', 'a2', -100)),
          throwsA(isA<AccountNotFoundException>()),
        );
        await expectLater(
          transactions.restore('t2'),
          throwsA(isA<AccountNotFoundException>()),
        );
      },
    );

    test(
      "an amount or split outside the account's currency is refused",
      () async {
        await expectLater(
          transactions.upsert(
            testTransaction('t1', 'a1', -100, currency: 'EUR'),
          ),
          throwsA(isA<CurrencyMismatchException>()),
        );
        await expectLater(
          transactions.upsert(
            testTransaction(
              't1',
              'a1',
              -100,
              splits: [
                TransactionSplit(categoryId: 'c1', amount: Money(-100, 'EUR')),
              ],
            ),
          ),
          throwsA(isA<CurrencyMismatchException>()),
        );
        expect(await transactions.count(TransactionQuery.all), 0);
      },
    );

    test('the order is date, then createdAt, then id, newest first', () async {
      final LocalDate d1 = LocalDate(2026, 10, 1);
      final LocalDate d2 = LocalDate(2026, 10, 2);
      final DateTime early = DateTime.utc(2026, 10, 1, 8);
      final DateTime late = DateTime.utc(2026, 10, 1, 9);
      for (final Transaction t in [
        testTransaction('a', 'a1', -1, date: d1, createdAt: late),
        testTransaction('b', 'a1', -1, date: d2, createdAt: early),
        testTransaction('c', 'a1', -1, date: d1, createdAt: early),
        testTransaction('d', 'a1', -1, date: d1, createdAt: late),
      ]) {
        await transactions.upsert(t);
      }
      expect(await ids(TransactionQuery.all), ['b', 'd', 'a', 'c']);
    });

    test(
      'ids tie-break in UTF-8 byte order, as SQLite compares text',
      () async {
        // U+1F600 sorts before U+FF21 in UTF-16 code units, after it in UTF-8 bytes.
        await transactions.upsert(testTransaction('\u{1F600}', 'a1', -1));
        await transactions.upsert(testTransaction('\uFF21', 'a1', -1));
        expect(await ids(TransactionQuery.all), ['\u{1F600}', '\uFF21']);
      },
    );

    group('query', () {
      setUp(() async {
        await f.accounts.upsert(testAccount('eur', currency: 'EUR'));
        for (final Transaction t in [
          testTransaction(
            't1',
            'a1',
            -1500,
            date: LocalDate(2026, 9, 30),
            name: 'GROCER 12',
            merchantName: 'Corner Grocer',
            userCategoryId: 'groceries',
            tags: const ['food'],
          ),
          testTransaction(
            't2',
            'a1',
            250000,
            date: LocalDate(2026, 10, 1),
            name: 'Payroll',
            notes: 'October SALARY',
            userCategoryId: 'income',
          ),
          testTransaction(
            't3',
            'a2',
            -4999,
            date: LocalDate(2026, 10, 15),
            name: 'Café Été',
            pending: true,
            tags: const ['coffee', 'treat'],
            splits: [
              TransactionSplit(
                categoryId: 'coffee',
                amount: Money(-4999, 'USD'),
              ),
            ],
          ),
          testTransaction(
            't4',
            'a2',
            -500,
            date: LocalDate(2026, 10, 31),
            name: '50% off_sale \\ deal',
          ),
          testTransaction(
            't5',
            'eur',
            -1500,
            currency: 'EUR',
            date: LocalDate(2026, 11, 1),
            name: '50x offXsale',
          ),
        ]) {
          await transactions.upsert(t);
        }
      });

      test('by account', () async {
        expect(await ids(TransactionQuery(accountIds: {'a2'})), ['t4', 't3']);
        expect(await ids(TransactionQuery(accountIds: {'a1', 'eur'})), [
          't5',
          't2',
          't1',
        ]);
      });

      test('by category, the user category or a split', () async {
        expect(await ids(TransactionQuery(categoryIds: {'groceries'})), ['t1']);
        expect(await ids(TransactionQuery(categoryIds: {'coffee', 'income'})), [
          't3',
          't2',
        ]);
      });

      test('by a half-open date range', () async {
        final TransactionQuery october = TransactionQuery(
          range: LocalDateRange(
            LocalDate(2026, 10, 1),
            LocalDate(2026, 10, 31),
          ),
        );
        expect(await ids(october), ['t3', 't2']);
      });

      test(
        'by text in the name, merchant or notes, ignoring ASCII case',
        () async {
          expect(await ids(TransactionQuery(text: 'grocer')), ['t1']);
          expect(await ids(TransactionQuery(text: 'CORNER')), ['t1']);
          expect(await ids(TransactionQuery(text: 'salary')), ['t2']);
          expect(await ids(TransactionQuery(text: 'café')), ['t3']);
          expect(
            await ids(TransactionQuery(text: 'CAFÉ')),
            isEmpty,
            reason: 'only ASCII letters fold, as in SQLite',
          );
          expect(await ids(TransactionQuery(text: '')), hasLength(5));
        },
      );

      test('by text with LIKE metacharacters matched literally', () async {
        expect(await ids(TransactionQuery(text: '50%')), ['t4']);
        expect(await ids(TransactionQuery(text: 'off_sale')), ['t4']);
        expect(await ids(TransactionQuery(text: r'\ deal')), ['t4']);
        expect(await ids(TransactionQuery(text: '%')), ['t4']);
      });

      test('by pending', () async {
        expect(await ids(TransactionQuery(pending: true)), ['t3']);
        expect(await ids(TransactionQuery(pending: false)), [
          't5',
          't4',
          't2',
          't1',
        ]);
      });

      test('by any of the tags', () async {
        expect(await ids(TransactionQuery(tags: {'treat', 'food'})), [
          't3',
          't1',
        ]);
      });

      test("by absolute amount, in the bound's currency only", () async {
        expect(await ids(TransactionQuery(minAmount: Money(1500, 'USD'))), [
          't3',
          't2',
          't1',
        ]);
        expect(await ids(TransactionQuery(maxAmount: Money(1500, 'USD'))), [
          't4',
          't1',
        ]);
        expect(
          await ids(
            TransactionQuery(
              minAmount: Money(1000, 'USD'),
              maxAmount: Money(5000, 'USD'),
            ),
          ),
          ['t3', 't1'],
        );
        expect(await ids(TransactionQuery(minAmount: Money(1, 'EUR'))), ['t5']);
      });

      test('with filters combined', () async {
        expect(
          await ids(
            TransactionQuery(
              accountIds: {'a1', 'a2'},
              range: LocalDateRange(
                LocalDate(2026, 9, 1),
                LocalDate(2026, 11, 1),
              ),
              minAmount: Money(1000, 'USD'),
              pending: false,
            ),
          ),
          ['t2', 't1'],
        );
      });

      test('paged by limit and offset; count ignores paging', () async {
        expect(await ids(TransactionQuery(limit: 2)), ['t5', 't4']);
        expect(await ids(TransactionQuery(limit: 2, offset: 2)), ['t3', 't2']);
        expect(await ids(TransactionQuery(offset: 3)), ['t2', 't1']);
        expect(await ids(TransactionQuery(limit: 0)), isEmpty);
        expect(await ids(TransactionQuery(offset: 10)), isEmpty);
        expect(await transactions.count(TransactionQuery(limit: 1)), 5);
        expect(
          await transactions.count(TransactionQuery(accountIds: {'a2'})),
          2,
        );
      });

      test('a watcher sees only changes to its result', () async {
        final Transaction later = testTransaction(
          't6',
          'a2',
          -1,
          date: LocalDate(2026, 12, 1),
        );
        final Future<void> seen = expectLater(
          transactions.watch(TransactionQuery(accountIds: {'a2'})),
          emitsInOrder([
            hasLength(2),
            [later, isA<Transaction>(), isA<Transaction>()],
          ]),
        );
        await pumpEventQueue();
        await transactions.upsert(testTransaction('t7', 'a1', -1));
        await pumpEventQueue();
        await transactions.upsert(later);
        await seen;
      });
    });

    group('query by effective category', () {
      // The effective category (effective_category.dart): the live user category, else
      // the system category of the detailed Plaid code, else of the primary code.
      Transaction coded(
        String id, {
        String? user,
        String? primary,
        String? detailed,
      }) => testTransaction(id, 'a1', -100, userCategoryId: user).copyWith(
        plaidPrimaryCategory: primary,
        plaidDetailedCategory: detailed,
      );
      String sys(String code) => 'plaid:$code';
      // The query a filter by the categories with Plaid [codes] makes.
      TransactionQuery byCodes(Set<String> codes) => TransactionQuery(
        categoryIds: {for (final String code in codes) sys(code)},
        categoryPlaidCodes: codes,
      );

      setUp(() async {
        await f.categories.ensureSeeded();
        for (final String id in ['mine', 'gone']) {
          await f.categories.upsert(
            Category(
              id: id,
              name: id,
              isSystem: false,
              icon: 'category',
              color: 0xFF000000,
            ),
          );
        }
        await f.categories.delete('gone');
        for (final Transaction t in [
          coded(
            'p1',
            user: 'mine',
            primary: 'FOOD_AND_DRINK',
            detailed: 'FOOD_AND_DRINK_GROCERIES',
          ),
          coded(
            'p2',
            primary: 'FOOD_AND_DRINK',
            detailed: 'FOOD_AND_DRINK_GROCERIES',
          ),
          coded('p3', primary: 'FOOD_AND_DRINK'),
          coded(
            'p4',
            primary: 'FOOD_AND_DRINK',
            detailed: 'FOOD_AND_DRINK_COFFEE',
          ),
          coded(
            'p5',
            primary: 'FOOD_AND_DRINK',
            detailed: 'FOOD_AND_DRINK_NOT_A_CODE',
          ),
          coded('p6', user: 'gone', detailed: 'FOOD_AND_DRINK_GROCERIES'),
          coded('p7'),
          coded('p8', primary: 'NOT_A_CODE'),
        ]) {
          await transactions.upsert(t);
        }
      });

      test('by the user category, whatever the codes', () async {
        expect(await ids(TransactionQuery(categoryIds: {'mine'})), ['p1']);
        expect(
          await ids(
            TransactionQuery(
              categoryIds: {'mine'},
              categoryPlaidCodes: {'FOOD_AND_DRINK_GROCERIES'},
            ),
          ),
          ['p6', 'p2', 'p1'],
        );
      });

      test(
        'by the detailed code, a deleted user category counting as unset',
        () async {
          final TransactionQuery groceries = byCodes({
            'FOOD_AND_DRINK_GROCERIES',
          });
          expect(await ids(groceries), ['p6', 'p2']);
          expect(await transactions.count(groceries), 2);
          // Ids alone match only user categories and splits (the usage counts).
          expect(
            await transactions.count(
              TransactionQuery(categoryIds: {sys('FOOD_AND_DRINK_GROCERIES')}),
            ),
            0,
          );
        },
      );

      test(
        'by the primary code when the detailed code resolves to none',
        () async {
          expect(await ids(byCodes({'FOOD_AND_DRINK'})), ['p5', 'p3']);
        },
      );

      test('a detailed code that resolves wins over the primary', () async {
        expect(await ids(byCodes({'FOOD_AND_DRINK_COFFEE'})), ['p4']);
        expect(
          await ids(byCodes({'FOOD_AND_DRINK', 'FOOD_AND_DRINK_COFFEE'})),
          ['p5', 'p4', 'p3'],
        );
      });

      test('a transaction with no effective category matches none', () async {
        final Set<String> every = {
          for (final Category c in await f.categories.watchAll().first)
            if (c.plaidCategory case final String code) code,
        };
        expect(
          await ids(
            TransactionQuery(
              categoryIds: {'mine', for (final String c in every) sys(c)},
              categoryPlaidCodes: every,
            ),
          ),
          ['p6', 'p5', 'p4', 'p3', 'p2', 'p1'],
        );
      });

      test(
        'a watcher sees a user category deleted fall back to the code',
        () async {
          final Future<void> seen = expectLater(
            transactions
                .watch(byCodes({'FOOD_AND_DRINK_GROCERIES'}))
                .map((page) => [for (final Transaction t in page) t.id]),
            emitsInOrder([
              ['p6', 'p2'],
              ['p6', 'p2', 'p1'],
            ]),
          );
          await pumpEventQueue();
          await f.categories.delete('mine');
          await seen;
        },
      );
    });

    group('usage', () {
      DateTime at(int minute) => testInstant.add(Duration(minutes: minute));

      test('a fresh repository uses nothing', () async {
        expect(await transactions.watchUsage().first, TransactionUsage.empty);
      });

      test(
        'distinct tags; categories and accounts by their newest use',
        () async {
          await transactions.upsert(
            testTransaction(
              't1',
              'a1',
              -1,
              createdAt: at(1),
              userCategoryId: 'c1',
              tags: ['b', 'a', 'b'],
            ),
          );
          await transactions.upsert(
            testTransaction(
              't2',
              'a2',
              -1,
              createdAt: at(2),
              userCategoryId: 'c2',
              tags: ['B'],
            ),
          );
          await transactions.upsert(
            testTransaction(
              't3',
              'a1',
              -1,
              createdAt: at(3),
              userCategoryId: 'c1',
            ),
          );
          // A tie on createdAt is broken by id; splits do not count as use.
          await transactions.upsert(
            testTransaction(
              't4',
              'a1',
              -1,
              createdAt: at(0),
              userCategoryId: 'c0',
              splits: [
                TransactionSplit(categoryId: 'c9', amount: Money(-1, 'USD')),
              ],
            ),
          );
          await transactions.upsert(
            testTransaction(
              't5',
              'a2',
              -1,
              createdAt: at(0),
              userCategoryId: 'c3',
            ),
          );

          expect(
            await transactions.watchUsage().first,
            const TransactionUsage(
              tags: ['B', 'a', 'b'],
              recentCategoryIds: ['c1', 'c2', 'c0', 'c3'],
              recentAccountIds: ['a1', 'a2'],
            ),
          );
          final TransactionUsage limited = await transactions
              .watchUsage(recentLimit: 1)
              .first;
          expect(limited.recentCategoryIds, ['c1']);
          expect(limited.recentAccountIds, ['a1']);
          expect(limited.tags, ['B', 'a', 'b']);
        },
      );

      test(
        'deleted transactions do not count; a watcher sees the change',
        () async {
          await transactions.upsert(
            testTransaction('t1', 'a1', -1, userCategoryId: 'c1', tags: ['x']),
          );
          final Future<void> seen = expectLater(
            transactions.watchUsage(),
            emitsInOrder([
              const TransactionUsage(
                tags: ['x'],
                recentCategoryIds: ['c1'],
                recentAccountIds: ['a1'],
              ),
              TransactionUsage.empty,
            ]),
          );
          await pumpEventQueue();
          await transactions.delete('t1');
          await seen;
        },
      );

      test('a limit below 1 is refused', () {
        expect(
          () => transactions.watchUsage(recentLimit: 0),
          throwsArgumentError,
        );
      });
    });
  });

  group('TransactionQuery', () {
    test('refuses negative paging and bounds in two currencies', () {
      expect(() => TransactionQuery(limit: -1), throwsArgumentError);
      expect(() => TransactionQuery(offset: -1), throwsArgumentError);
      expect(
        () => TransactionQuery(
          minAmount: Money(1, 'USD'),
          maxAmount: Money(2, 'EUR'),
        ),
        throwsArgumentError,
      );
    });

    test('is equal by value, sets ignoring order', () {
      expect(
        TransactionQuery(accountIds: {'a', 'b'}, text: 'x', limit: 5),
        TransactionQuery(accountIds: {'b', 'a'}, text: 'x', limit: 5),
      );
      expect(
        TransactionQuery(accountIds: {'a', 'b'}).hashCode,
        TransactionQuery(accountIds: {'b', 'a'}).hashCode,
      );
      expect(TransactionQuery(text: 'x'), isNot(TransactionQuery(text: 'y')));
      expect(
        TransactionQuery(categoryPlaidCodes: {'A', 'B'}),
        TransactionQuery(categoryPlaidCodes: {'B', 'A'}),
      );
      expect(
        TransactionQuery(categoryPlaidCodes: {'A'}),
        isNot(TransactionQuery(categoryPlaidCodes: {'B'})),
      );
    });
  });
}
