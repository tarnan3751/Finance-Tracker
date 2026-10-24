// The contract every AccountRepository implementation passes (Drift, in memory, demo),
// each from its own test file under test/features/accounts/data/. Call
// runAccountRepositoryContract with a factory for a fresh, empty fixture and, when it holds
// resources, a dispose that releases the one the factory made last.
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// Registers the contract tests for the fixtures [create] builds.
void runAccountRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('AccountRepository contract', () {
    late RepositoryFixture f;
    late AccountRepository accounts;

    setUp(() async {
      f = await create();
      accounts = f.accounts;
    });
    if (dispose != null) tearDown(dispose);

    test('a fresh repository is empty', () async {
      expect(await accounts.watchAll().first, isEmpty);
      expect(await accounts.watchById('a1').first, isNull);
      expect(await accounts.watchDerivedBalance('a1').first, isNull);
      expect(await accounts.watchDerivedBalances().first, isEmpty);
    });

    test('an upsert is seen by watchAll and watchById', () async {
      final Account a = testAccount('a1');
      final Future<void> seen = expectLater(
        accounts.watchAll(),
        emitsInOrder([
          isEmpty,
          [a],
        ]),
      );
      await pumpEventQueue();
      await accounts.upsert(a);
      await seen;
      expect(await accounts.watchById('a1').first, a);
    });

    test('every field round-trips', () async {
      final Account a = Account(
        id: 'a1',
        itemId: 'item-1',
        type: AccountType.credit,
        subtype: 'credit card',
        name: 'Card',
        officialName: 'Rewards Visa',
        mask: '4242',
        currencyCode: 'EUR',
        currentBalance: Money(-12345, 'EUR'),
        availableBalance: Money(87655, 'EUR'),
        creditLimit: Money(100000, 'EUR'),
        balancesAsOf: DateTime.utc(2026, 10, 23, 8, 30, 0, 250),
        isHidden: true,
        displayOrder: 7,
      );
      await accounts.upsert(a);
      expect(await accounts.watchById('a1').first, a);
    });

    test('an update is seen by a watcher', () async {
      await accounts.upsert(testAccount('a1'));
      final Account renamed = testAccount('a1', name: 'Renamed');
      final Future<void> seen = expectLater(
        accounts.watchById('a1'),
        emitsThrough(renamed),
      );
      await pumpEventQueue();
      await accounts.upsert(renamed);
      await seen;
    });

    test(
      'accounts are ordered visible first, then by displayOrder and id',
      () async {
        await accounts.upsert(testAccount('c', displayOrder: 1));
        await accounts.upsert(
          testAccount('h', displayOrder: 0, isHidden: true),
        );
        await accounts.upsert(testAccount('b', displayOrder: 1));
        await accounts.upsert(testAccount('a', displayOrder: 2));
        final List<Account> all = await accounts.watchAll().first;
        expect(all.map((a) => a.id), ['b', 'c', 'a', 'h']);
      },
    );

    test(
      'ids tie-break in UTF-8 byte order, as SQLite compares text',
      () async {
        // U+1F600 sorts before U+FF21 in UTF-16 code units, after it in UTF-8 bytes.
        await accounts.upsert(testAccount('\u{1F600}'));
        await accounts.upsert(testAccount('\uFF21'));
        expect((await accounts.watchAll().first).map((a) => a.id), [
          '\uFF21',
          '\u{1F600}',
        ]);
      },
    );

    test('a delete hides the account; watchById yields null', () async {
      await accounts.upsert(testAccount('a1'));
      await accounts.upsert(testAccount('a2'));
      final Future<void> gone = expectLater(
        accounts.watchById('a1'),
        emitsThrough(isNull),
      );
      await pumpEventQueue();
      await accounts.delete('a1');
      await gone;
      expect((await accounts.watchAll().first).map((a) => a.id), ['a2']);
      await accounts.delete('a1');
      await accounts.delete('missing');
    });

    test('a linked account cannot be deleted', () async {
      final Account linked = testAccount('a1').copyWith(itemId: 'item-1');
      await accounts.upsert(linked);
      await expectLater(
        accounts.delete('a1'),
        throwsA(isA<BankDataNotDeletableException>()),
      );
      expect(await accounts.watchById('a1').first, linked);
    });

    test(
      'an upsert of a deleted account throws EntityDeletedException',
      () async {
        await accounts.upsert(testAccount('a1'));
        await accounts.delete('a1');
        await expectLater(
          accounts.upsert(testAccount('a1', name: 'Back')),
          throwsA(isA<EntityDeletedException>()),
        );
        expect(await accounts.watchById('a1').first, isNull);
      },
    );

    test('restore brings a deleted account back as it was', () async {
      final Account a = testAccount('a1', displayOrder: 3);
      await accounts.upsert(a);
      await accounts.delete('a1');
      await accounts.restore('a1');
      expect(await accounts.watchById('a1').first, a);
      await accounts.restore('a1');
      await accounts.restore('missing');
      expect(await accounts.watchAll().first, [a]);
    });

    test(
      'a balance in another currency is a CurrencyMismatchException',
      () async {
        for (final Account a in [
          testAccount('a1').copyWith(currentBalance: Money(1, 'EUR')),
          testAccount('a1').copyWith(availableBalance: Money(1, 'EUR')),
          testAccount('a1').copyWith(creditLimit: Money(1, 'EUR')),
        ]) {
          await expectLater(
            accounts.upsert(a),
            throwsA(isA<CurrencyMismatchException>()),
          );
        }
        expect(await accounts.watchAll().first, isEmpty);
      },
    );

    test(
      'the currency changes only while the account has no transactions',
      () async {
        await accounts.upsert(testAccount('a1'));
        await accounts.upsert(testAccount('a1', currency: 'EUR'));
        expect((await accounts.watchById('a1').first)!.currencyCode, 'EUR');

        await f.transactions.upsert(
          testTransaction('t1', 'a1', -100, currency: 'EUR'),
        );
        await expectLater(
          accounts.upsert(testAccount('a1', currency: 'USD')),
          throwsA(isA<CurrencyMismatchException>()),
        );
        await f.transactions.delete('t1');
        await expectLater(
          accounts.upsert(testAccount('a1', currency: 'USD')),
          throwsA(isA<CurrencyMismatchException>()),
          reason: 'a deleted transaction can be restored',
        );
      },
    );

    group('derived balance', () {
      test('is null until the account has a transaction', () async {
        await accounts.upsert(testAccount('a1'));
        expect(await accounts.watchDerivedBalance('a1').first, isNull);
        expect(await accounts.watchDerivedBalances().first, {'a1': null});
      });

      test('follows inserts, updates and deletes', () async {
        await accounts.upsert(testAccount('a1'));
        final Future<void> seen = expectLater(
          accounts.watchDerivedBalance('a1'),
          emitsInOrder([
            isNull,
            Money(-1000, 'USD'),
            Money(1500, 'USD'),
            Money(2000, 'USD'),
            emitsThrough(isNull),
          ]),
        );
        await pumpEventQueue();
        await f.transactions.upsert(testTransaction('t1', 'a1', -1000));
        await pumpEventQueue();
        await f.transactions.upsert(testTransaction('t2', 'a1', 2500));
        await pumpEventQueue();
        await f.transactions.upsert(testTransaction('t1', 'a1', -500));
        await pumpEventQueue();
        await f.transactions.delete('t1');
        await f.transactions.delete('t2');
        await seen;
      });

      test('counts pending transactions', () async {
        await accounts.upsert(testAccount('a1'));
        await f.transactions.upsert(
          testTransaction('t1', 'a1', -250, pending: true),
        );
        expect(
          await accounts.watchDerivedBalance('a1').first,
          Money(-250, 'USD'),
        );
      });

      test('ignores other accounts and other currencies', () async {
        await accounts.upsert(testAccount('a1'));
        await accounts.upsert(testAccount('a2', currency: 'JPY'));
        await f.transactions.upsert(testTransaction('t1', 'a1', -1000));
        await f.transactions.upsert(
          testTransaction('t2', 'a2', -700, currency: 'JPY'),
        );
        await expectLater(
          f.transactions.upsert(
            testTransaction('t3', 'a1', -5, currency: 'EUR'),
          ),
          throwsA(isA<CurrencyMismatchException>()),
        );

        expect(
          await accounts.watchDerivedBalance('a1').first,
          Money(-1000, 'USD'),
        );
        expect(await accounts.watchDerivedBalances().first, {
          'a1': Money(-1000, 'USD'),
          'a2': Money(-700, 'JPY'),
        });
      });

      test('is null for a missing or deleted account', () async {
        await accounts.upsert(testAccount('a1'));
        await f.transactions.upsert(testTransaction('t1', 'a1', -1000));
        await accounts.delete('a1');
        expect(await accounts.watchDerivedBalance('a1').first, isNull);
        expect(await accounts.watchDerivedBalance('missing').first, isNull);
        expect(await accounts.watchDerivedBalances().first, isEmpty);
      });
    });

    group('delete cascade', () {
      test("deletes the account's transactions and restores them", () async {
        await accounts.upsert(testAccount('a1'));
        await accounts.upsert(testAccount('a2'));
        final Transaction kept = testTransaction('t1', 'a1', -100);
        await f.transactions.upsert(kept);
        await f.transactions.upsert(testTransaction('t2', 'a2', -200));

        await accounts.delete('a1');
        expect(await f.transactions.watchById('t1').first, isNull);
        expect(
          (await f.transactions.watch(TransactionQuery.all).first).map(
            (t) => t.id,
          ),
          ['t2'],
        );

        await accounts.restore('a1');
        final Transaction restored = (await f.transactions
            .watchById('t1')
            .first)!;
        expect(restored.copyWith(updatedAt: kept.updatedAt), kept);
        expect(
          restored.updatedAt.isAfter(kept.updatedAt),
          isTrue,
          reason: 'the delete and the restore stamp updatedAt',
        );
        expect(
          await accounts.watchDerivedBalance('a1').first,
          Money(-100, 'USD'),
        );
      });

      test('a transaction deleted on its own in the same millisecond stays deleted', () async {
        await accounts.upsert(testAccount('a1'));
        await f.transactions.upsert(testTransaction('t1', 'a1', -100));
        await f.transactions.upsert(testTransaction('t2', 'a1', -200));
        f.clock.frozen = true;
        await f.transactions.delete('t1');
        await accounts.delete('a1');
        await accounts.restore('a1');

        expect(await f.transactions.watchById('t1').first, isNull);
        expect(await f.transactions.watchById('t2').first, isNotNull);
      });

      test(
        'a transaction deleted on its own stays deleted after the restore',
        () async {
          await accounts.upsert(testAccount('a1'));
          await f.transactions.upsert(testTransaction('t1', 'a1', -100));
          await f.transactions.upsert(testTransaction('t2', 'a1', -200));
          await f.transactions.delete('t1');

          await accounts.delete('a1');
          await accounts.restore('a1');

          expect(await f.transactions.watchById('t1').first, isNull);
          expect(await f.transactions.watchById('t2').first, isNotNull);
          await f.transactions.restore('t1');
          expect(
            await accounts.watchDerivedBalance('a1').first,
            Money(-300, 'USD'),
          );
        },
      );
    });

    group('create', () {
      test('writes the account and its opening balance together', () async {
        final Account a = testAccount('a1');
        final Transaction opening = testTransaction('o1', 'a1', 50000);
        await accounts.create(a, openingBalance: opening);

        expect(await accounts.watchById('a1').first, a);
        expect(await f.transactions.watchById('o1').first, opening);
        expect(
          await accounts.watchDerivedBalance('a1').first,
          Money(50000, 'USD'),
        );
      });

      test('without an opening balance it is an upsert', () async {
        await accounts.create(testAccount('a1'));

        expect(await accounts.watchById('a1').first, testAccount('a1'));
        expect(await f.transactions.count(TransactionQuery.all), 0);
      });

      test('an opening balance that fails leaves nothing written', () async {
        await expectLater(
          accounts.create(
            testAccount('a1'),
            openingBalance: testTransaction('o1', 'a1', 50000, currency: 'EUR'),
          ),
          throwsA(isA<CurrencyMismatchException>()),
        );

        expect(await accounts.watchById('a1').first, isNull);
        expect(await f.transactions.count(TransactionQuery.all), 0);
      });

      test('an opening balance on another account is refused', () async {
        expect(
          () => accounts.create(
            testAccount('a1'),
            openingBalance: testTransaction('o1', 'a2', 100),
          ),
          throwsArgumentError,
        );

        expect(await accounts.watchById('a1').first, isNull);
      });

      test('a deleted account cannot be created again', () async {
        await accounts.upsert(testAccount('a1'));
        await accounts.delete('a1');

        await expectLater(
          accounts.create(testAccount('a1')),
          throwsA(isA<EntityDeletedException>()),
        );
      });
    });
  });
}
