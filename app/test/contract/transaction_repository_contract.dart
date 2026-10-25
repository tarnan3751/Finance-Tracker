// The contract every TransactionRepository implementation passes (Drift, in memory, demo),
// each from its own test file under test/features/transactions/data/. Call
// runTransactionRepositoryContract with a factory for a fresh, empty fixture and, when it
// holds resources, a dispose that releases the one the factory made last.
import 'dart:convert';
import 'dart:io';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/transactions/domain/search_text.dart';
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
        hidden: true,
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

    test('a Plaid transaction cannot be deleted', () async {
      final Transaction plaid = testTransaction(
        'p1',
        'a1',
        -100,
      ).copyWith(source: DataSource.plaid);
      await transactions.upsert(plaid);
      await expectLater(
        transactions.delete('p1'),
        throwsA(isA<BankDataNotDeletableException>()),
      );
      expect(await transactions.watchById('p1').first, plaid);
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

    test('a hidden transaction still counts toward its account\'s derived '
        'balance', () async {
      await transactions.upsert(testTransaction('t1', 'a1', -1500));
      await transactions.upsert(
        testTransaction('t2', 'a1', -2500, hidden: true),
      );
      expect(
        await f.accounts.watchDerivedBalance('a1').first,
        Money(-4000, 'USD'),
      );
      expect(
        (await f.accounts.watchDerivedBalances().first)['a1'],
        Money(-4000, 'USD'),
      );
    });

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

      test('by text: word prefixes in the name, merchant or notes', () async {
        expect(await ids(TransactionQuery(text: 'groc')), ['t1']);
        expect(await ids(TransactionQuery(text: 'CORN')), ['t1']);
        expect(await ids(TransactionQuery(text: 'salar')), ['t2']);
        expect(await ids(TransactionQuery(text: 'rocer')), isEmpty);
        expect(await ids(TransactionQuery(text: '')), hasLength(5));
        expect(await ids(TransactionQuery(text: '   ')), hasLength(5));
      });

      test('by text: every term, each in any field', () async {
        expect(await ids(TransactionQuery(text: 'corner grocer')), ['t1']);
        expect(await ids(TransactionQuery(text: 'oct  sal')), ['t2']);
        expect(await ids(TransactionQuery(text: 'grocer payroll')), isEmpty);
        expect(await ids(TransactionQuery(text: 'food grocer')), ['t1']);
      });

      test('by text: accents and case fold', () async {
        expect(await ids(TransactionQuery(text: 'cafe')), ['t3']);
        expect(await ids(TransactionQuery(text: 'CAFÉ ÉTÉ')), ['t3']);
        expect(await ids(TransactionQuery(text: 'ete')), ['t3']);
      });

      test('by text: tags', () async {
        expect(await ids(TransactionQuery(text: 'treat')), ['t3']);
        expect(await ids(TransactionQuery(text: 'COFF')), ['t3']);
      });

      test(
        'by text: punctuation separates words and never reaches FTS5',
        () async {
          expect(await ids(TransactionQuery(text: '50')), ['t5', 't4']);
          expect(await ids(TransactionQuery(text: 'off_sale')), ['t4']);
          expect(await ids(TransactionQuery(text: '"grocer')), ['t1']);
          expect(await ids(TransactionQuery(text: 'gro*')), ['t1']);
          expect(await ids(TransactionQuery(text: '(corner')), ['t1']);
          expect(await ids(TransactionQuery(text: '-payroll')), ['t2']);
          expect(await ids(TransactionQuery(text: '"corner grocer"')), ['t1']);
          expect(
            await ids(TransactionQuery(text: 'grocer")OR("payroll')),
            isEmpty,
          );
          expect(
            await ids(TransactionQuery(text: 'corner NEAR grocer')),
            isEmpty,
          );
          expect(
            await ids(TransactionQuery(text: 'grocer OR payroll')),
            isEmpty,
          );
          expect(await ids(TransactionQuery(text: 'NOT payroll')), isEmpty);
          expect(await ids(TransactionQuery(text: 'name:grocer')), isEmpty);
          expect(await ids(TransactionQuery(text: 'grocer\u0000')), ['t1']);
          expect(await ids(TransactionQuery(text: 'corner\u0000groc')), ['t1']);
          expect(await ids(TransactionQuery(text: 'gro\u0000cer')), isEmpty);
        },
      );

      test('by text: a term with no letter or digit matches nothing', () async {
        expect(await ids(TransactionQuery(text: '%')), isEmpty);
        expect(await ids(TransactionQuery(text: 'grocer --')), isEmpty);
        expect(await ids(TransactionQuery(text: '\u0000')), isEmpty);
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

      test('by hidden; count follows', () async {
        final Transaction t4 = (await transactions.watchById('t4').first)!;
        await transactions.upsert(t4.copyWith(hidden: true));
        expect(await ids(TransactionQuery(hidden: true)), ['t4']);
        expect(await ids(TransactionQuery(hidden: false)), [
          't5',
          't3',
          't2',
          't1',
        ]);
        expect(await transactions.count(TransactionQuery(hidden: false)), 4);
        expect(await transactions.count(TransactionQuery(hidden: true)), 1);
        expect(await transactions.count(TransactionQuery.all), 5);
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

    group('search over a corpus', () {
      // The 316 raw names Plaid Sandbox returned, with merchants, notes and tags in
      // accented, cased and non-Latin text; the expected matches are the pure-Dart
      // reference's (search_text.dart), which the Drift run checks FTS5 against.
      const List<String> merchants = [
        'Crème Brûlée Café',
        'ÉCOLE Française',
        "Zoë's Kitchen",
        'İstanbul Grill',
        'Ωmega Gym',
        'Straße 12',
        'Naïve Bakery',
        '日本料理 Sushi',
      ];
      const List<String> notes = [
        'Paid with Ångström card',
        'split w/ Renée (50/50)',
        'reimbursed: yes!',
        'Ölmühle order #4421',
      ];
      const List<String> tags = ['work-trip', 'Café', 'TAXES_2026', 'façade'];
      late List<Transaction> corpus;

      setUp(() async {
        final List<String> names = [
          for (final Object? n in jsonDecode(
            File('test/fixtures/plaid_transaction_names.json')
                .readAsStringSync(),
          ) as List<Object?>)
            n! as String,
        ];
        corpus = [
          for (final (int i, String name) in names.indexed)
            testTransaction(
              'c$i',
              'a1',
              -100 - i,
              date: LocalDate(2026, 1, 1).addDays(i),
              name: name,
              merchantName: i % 4 == 0
                  ? merchants[i ~/ 4 % merchants.length]
                  : null,
              notes: i % 5 == 0 ? notes[i ~/ 5 % notes.length] : null,
              tags: i % 3 == 0 ? [tags[i ~/ 3 % tags.length], 'x$i'] : const [],
            ),
        ];
        await transactions.upsertAll(corpus);
      });

      test('matches as the reference tokenizer does', () async {
        final Set<String> queries = {
          'creme',
          'BRUL',
          'cafe',
          'ecole fran',
          'zoe',
          'zoes',
          'istanbul',
          'ωmeg',
          'strasse',
          'straße',
          'naive',
          '日本',
          'angstrom',
          'renee 50',
          'olmuhle',
          'work trip',
          'work-trip',
          'taxes_2026',
          'facade',
          'payroll',
          'amazon len',
          '#052',
          "mcdonald's",
          'mcdonald s',
          'x1',
          'x30',
        };
        for (final Transaction t in corpus.take(160)) {
          final List<String> words = t.name.split(' ');
          final String first = words.first;
          for (int n = 1; n <= first.length && n <= 4; n++) {
            queries.add(first.substring(0, n));
          }
          queries.add(first.toUpperCase());
          if (words.length > 1 && words[1].isNotEmpty) {
            queries.add('${first.toLowerCase()} ${words[1].substring(0, 1)}');
          }
        }
        int nonEmpty = 0;
        for (final String q in queries) {
          final List<String> terms = searchTerms(q);
          final Set<String> expected = {
            for (final Transaction t in corpus)
              if (matchesSearch(terms, [
                t.name,
                t.merchantName,
                t.notes,
                t.tags.join(' '),
              ]))
                t.id,
          };
          if (expected.isNotEmpty) nonEmpty++;
          expect(
            (await ids(TransactionQuery(text: q))).toSet(),
            expected,
            reason: q,
          );
        }
        expect(nonEmpty, greaterThan(queries.length ~/ 2));
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

    group('batches', () {
      final DateTime later = DateTime.utc(2026, 10, 24, 12);
      // A Plaid row on a1 as the pull stores it.
      final Transaction bank = Transaction(
        id: 'p1',
        accountId: 'a1',
        amount: Money(-1599, 'USD'),
        date: LocalDate(2026, 10, 20),
        pending: false,
        name: 'NETFLIX.COM',
        merchantName: 'Netflix',
        plaidPrimaryCategory: 'ENTERTAINMENT',
        source: DataSource.plaid,
        createdAt: testInstant,
        updatedAt: testInstant,
        syncVersion: 3,
      );

      setUp(() async {
        await transactions.upsert(testTransaction('t1', 'a1', -100));
        await transactions.upsert(testTransaction('t2', 'a2', -200));
        await transactions.applyPlaid([bank]);
      });

      Future<Map<String, Transaction>> all() async => {
        for (final Transaction t
            in await transactions.watch(TransactionQuery.all).first)
          t.id: t,
      };

      // Expects [write] to throw a TransactionBatchException naming [id] with a
      // [Cause] cause, and to leave every transaction as it was.
      Future<void> refused<Cause>(
        Future<void> Function() write,
        String id,
      ) async {
        final Map<String, Transaction> before = await all();
        await expectLater(
          write(),
          throwsA(
            isA<TransactionBatchException>()
                .having((e) => e.transactionId, 'transactionId', id)
                .having((e) => e.cause, 'cause', isA<Cause>()),
          ),
        );
        expect(await all(), before);
      }

      test(
        'upsertAll writes every transaction, Plaid overrides included',
        () async {
          final Map<String, Transaction> before = await all();
          final List<Transaction> batch = [
            before['t1']!.copyWith(hidden: true, updatedAt: later),
            before['p1']!.copyWith(
              hidden: true,
              userCategoryId: 'c1',
              notes: 'mine',
              tags: const ['tv'],
              updatedAt: later,
            ),
            testTransaction('t3', 'a2', -300, tags: const ['new']),
          ];
          await transactions.upsertAll(batch);
          expect(await all(), {
            't2': before['t2'],
            for (final Transaction t in batch) t.id: t,
          });
          await transactions.upsertAll(const []);
          expect(await transactions.count(TransactionQuery.all), 4);
        },
      );

      test(
        'upsertAll writes nothing when one transaction is deleted',
        () async {
          await transactions.delete('t2');
          final Map<String, Transaction> live = await all();
          await refused<EntityDeletedException>(
            () => transactions.upsertAll([
              live['t1']!.copyWith(hidden: true),
              testTransaction('t2', 'a2', -200, hidden: true),
            ]),
            't2',
          );
        },
      );

      test(
        'upsertAll writes nothing on a currency mismatch or a missing account',
        () async {
          await refused<CurrencyMismatchException>(
            () => transactions.upsertAll([
              testTransaction('t1', 'a1', -100, hidden: true),
              testTransaction('t2', 'a2', -200, currency: 'EUR'),
            ]),
            't2',
          );
          await refused<AccountNotFoundException>(
            () => transactions.upsertAll([
              testTransaction('t1', 'a1', -100, hidden: true),
              testTransaction('t4', 'nowhere', -1),
            ]),
            't4',
          );
        },
      );

      test(
        'upsertAll refuses a changed Plaid field on a plaid row, naming it',
        () async {
          final Map<String, Transaction> before = await all();
          await refused<PlaidOverridesOnlyError>(
            () => transactions.upsertAll([
              before['t1']!.copyWith(hidden: true),
              before['p1']!.copyWith(hidden: true, name: 'Renamed'),
            ]),
            'p1',
          );
          await expectLater(
            transactions.upsertAll([
              before['p1']!.copyWith(amount: Money(-1, 'USD')),
            ]),
            throwsA(
              isA<TransactionBatchException>().having(
                (e) => e.cause,
                'cause',
                isA<PlaidOverridesOnlyError>().having(
                  (e) => e.field,
                  'field',
                  'amount',
                ),
              ),
            ),
          );
          await refused<PlaidOverridesOnlyError>(
            () => transactions.upsertAll([
              before['t1']!.copyWith(source: DataSource.plaid),
            ]),
            't1',
          );
          await refused<PlaidOverridesOnlyError>(
            () => transactions.upsertAll([
              bank.copyWith(id: 'p-new', hidden: true),
            ]),
            'p-new',
          );
        },
      );

      test('upsertAll refuses a repeated id before writing anything', () async {
        final Map<String, Transaction> before = await all();
        await expectLater(
          transactions.upsertAll([
            before['t1']!.copyWith(hidden: true),
            before['t1']!.copyWith(notes: 'twice'),
          ]),
          throwsArgumentError,
        );
        expect(await all(), before);
      });

      test(
        'deleteAll deletes every transaction, or none when one is plaid',
        () async {
          await refused<BankDataNotDeletableException>(
            () => transactions.deleteAll(['t1', 'p1', 't2']),
            'p1',
          );
          await transactions.deleteAll(['t1', 't2', 'missing']);
          expect((await all()).keys, ['p1']);
          await transactions.restore('t1');
          expect(await transactions.watchById('t1').first, isNotNull);
        },
      );
    });

    group('applyPlaid', () {
      final DateTime at = DateTime.utc(2026, 10, 20, 8);
      Transaction bank(
        String id, {
        int cents = -1599,
        String name = 'NETFLIX.COM',
        bool pending = true,
        DateTime? deletedAt,
        int version = 1,
        DataSource source = DataSource.plaid,
        String accountId = 'a1',
      }) => Transaction(
        id: id,
        accountId: accountId,
        amount: Money(cents, 'USD'),
        date: LocalDate(2026, 10, 20),
        pending: pending,
        name: name,
        merchantName: 'Netflix',
        plaidPrimaryCategory: 'ENTERTAINMENT',
        source: source,
        createdAt: at,
        updatedAt: at,
        deletedAt: deletedAt,
        syncVersion: version,
      );

      test('new transactions are stored as sent and returned', () async {
        final List<Transaction> page = [
          bank('p1'),
          bank('d1', source: DataSource.demo, accountId: 'elsewhere'),
        ];
        expect(await transactions.applyPlaid(page), page);
        expect(await transactions.watchById('p1').first, page[0]);
        // No account check: the server's row may arrive before its account.
        expect(await transactions.watchById('d1').first, page[1]);
      });

      test('an update keeps the six fields the user owns', () async {
        await transactions.applyPlaid([bank('p1')]);
        final Transaction mine = bank('p1').copyWith(
          userCategoryId: 'c1',
          notes: 'shared',
          tags: const ['tv'],
          splits: [
            TransactionSplit(categoryId: 'c1', amount: Money(-1599, 'USD')),
          ],
          receiptPath: 'receipts/1.jpg',
          hidden: true,
        );
        await transactions.upsert(mine);
        final Transaction posted = bank(
          'p1',
          cents: -1699,
          pending: false,
          version: 7,
        ).copyWith(updatedAt: at.add(const Duration(days: 1)));
        expect(await transactions.applyPlaid([posted]), isEmpty);
        expect(
          await transactions.watchById('p1').first,
          posted.copyWith(
            userCategoryId: 'c1',
            notes: 'shared',
            tags: const ['tv'],
            splits: mine.splits,
            receiptPath: 'receipts/1.jpg',
            hidden: true,
          ),
        );
      });

      test('a tombstone applies as sent; a tombstone of an unknown row is '
          'skipped', () async {
        await transactions.applyPlaid([bank('p1')]);
        final DateTime gone = at.add(const Duration(hours: 1));
        expect(
          await transactions.applyPlaid([
            bank('p1', deletedAt: gone, version: 2),
            bank('p2', deletedAt: gone, version: 3),
          ]),
          isEmpty,
        );
        expect(await transactions.watchById('p1').first, isNull);
        expect(await transactions.watchById('p2').first, isNull);
        expect(await transactions.count(TransactionQuery.all), 0);
        // The server's row comes back live: it is live again here.
        await transactions.applyPlaid([bank('p1', version: 4)]);
        expect(
          await transactions.watchById('p1').first,
          bank('p1', version: 4),
        );
      });

      test('the source is the server\'s, and nothing is recorded', () async {
        final int before = (await f.syncStore?.unsynced())?.length ?? 0;
        await transactions.applyPlaid([
          bank('p1'),
          bank('d1', source: DataSource.demo),
        ]);
        await transactions.applyPlaid([
          bank('p1', name: 'Netflix', version: 2),
        ]);
        expect(
          (await transactions.watchById('p1').first)!.source,
          DataSource.plaid,
        );
        expect(
          (await transactions.watchById('d1').first)!.source,
          DataSource.demo,
        );
        expect((await f.syncStore?.unsynced())?.length ?? 0, before);
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
      expect(TransactionQuery(hidden: false), TransactionQuery(hidden: false));
      expect(
        TransactionQuery(hidden: false).hashCode,
        TransactionQuery(hidden: false).hashCode,
      );
      expect(TransactionQuery(hidden: false), isNot(TransactionQuery()));
    });
  });
}
