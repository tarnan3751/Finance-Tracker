// The recording contract: every user-authored write of the account, transaction,
// category, rule, budget, bill, goal, settings and recurring stream repositories records exactly one change-log entry per entity it
// changed, and nothing else is recorded (Plaid rows only through their six overrides;
// derived and demo transactions, linked accounts, the seeding and the streams
// themselves never; a stream's override only as updates). The Drift and
// in-memory implementations run it from test/core/sync/; the demo one records nothing.
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import 'bill_repository_contract.dart' show testBill;
import 'budget_repository_contract.dart' show testBudget;
import 'goal_repository_contract.dart' show testContribution, testGoal;
import 'recurring_stream_repository_contract.dart' show testStream;
import 'repository_fixture.dart';
import 'rule_repository_contract.dart' show testRule;

/// Registers the recording tests for the fixtures [create] builds, each with a sync store.
void runRecordingContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('recording contract', () {
    late RepositoryFixture f;
    late SyncStore sync;

    setUp(() async {
      f = await create();
      sync = f.syncStore!;
    });
    if (dispose != null) tearDown(dispose);

    // The entries recorded since the last call, as "type/id operation {fields}".
    int seen = 0;
    setUp(() => seen = 0);
    Future<List<String>> recorded() async {
      final List<ChangeLogEntry> all = await sync.unsynced(limit: 100000);
      final List<ChangeLogEntry> fresh = all.sublist(seen);
      seen = all.length;
      return [
        for (final ChangeLogEntry e in fresh)
          '${snakeName(e.entityType)}/${e.entityId} ${e.operation.name} '
              '${(e.payload.keys.toList()..sort()).join(',')}',
      ];
    }

    const String accountFields =
        'available_balance,balances_as_of,credit_limit,currency_code,'
        'current_balance,display_order,id,is_hidden,item_id,mask,name,'
        'official_name,subtype,type';
    const String transactionFields =
        'account_id,amount,authorized_date,created_at,date,deleted_with_account,'
        'hidden,id,merchant_logo_url,merchant_name,name,notes,pending,'
        'pending_transaction_id,plaid_detailed_category,plaid_primary_category,'
        'receipt_path,source,splits,sync_version,tags,updated_at,user_category_id';

    test('an account: a create, then an update of what changed', () async {
      await f.accounts.upsert(testAccount('a1'));
      expect(await recorded(), ['account/a1 create $accountFields']);
      await f.accounts.upsert(testAccount('a1', name: 'Renamed'));
      expect(await recorded(), ['account/a1 update name']);
      await f.accounts.upsert(testAccount('a1', name: 'Renamed'));
      expect(await recorded(), isEmpty);
    });

    test('a create with an opening balance records both', () async {
      await f.accounts.create(
        testAccount('a1'),
        openingBalance: testTransaction('t1', 'a1', 1000),
      );
      expect(await recorded(), [
        'account/a1 create $accountFields',
        'transaction/t1 create $transactionFields',
      ]);
    });

    test('a refused write records nothing', () async {
      await expectLater(
        f.accounts.create(
          testAccount('a1'),
          openingBalance: testTransaction('t1', 'a1', 1000, currency: 'EUR'),
        ),
        throwsA(isA<CurrencyMismatchException>()),
      );
      await expectLater(
        f.transactions.upsert(testTransaction('t2', 'nowhere', 1)),
        throwsA(isA<AccountNotFoundException>()),
      );
      expect(await recorded(), isEmpty);
    });

    test(
      'an account delete and restore record the account and each transaction '
      'they change',
      () async {
        await f.accounts.upsert(testAccount('a1'));
        for (final String id in ['t1', 't2', 't3']) {
          await f.transactions.upsert(testTransaction(id, 'a1', -100));
        }
        await f.transactions.delete('t3');
        await recorded();

        await f.accounts.delete('a1');
        final List<String> deleted = await recorded();
        expect(deleted, hasLength(3));
        expect(deleted, contains('account/a1 delete deleted_at'));
        expect(
          deleted,
          containsAll([
            'transaction/t1 delete deleted_at,deleted_with_account,updated_at',
            'transaction/t2 delete deleted_at,deleted_with_account,updated_at',
          ]),
        );

        await f.accounts.restore('a1');
        final List<String> restored = await recorded();
        expect(restored, hasLength(3));
        expect(restored, contains('account/a1 update deleted_at'));
        expect(
          restored,
          containsAll([
            'transaction/t1 update deleted_at,deleted_with_account,updated_at',
            'transaction/t2 update deleted_at,deleted_with_account,updated_at',
          ]),
        );
        await f.accounts.delete('missing');
        await f.accounts.restore('a1');
        expect(await recorded(), isEmpty);
      },
    );

    test('a transaction: create, update, delete, restore', () async {
      await f.accounts.upsert(testAccount('a1'));
      await recorded();
      final Transaction t = testTransaction('t1', 'a1', -100, tags: ['a']);
      await f.transactions.upsert(t);
      expect(await recorded(), ['transaction/t1 create $transactionFields']);
      await f.transactions.upsert(t.copyWith(tags: ['b', 'a'], notes: 'n'));
      expect(await recorded(), ['transaction/t1 update notes,tags']);
      await f.transactions.delete('t1');
      expect(await recorded(), ['transaction/t1 delete deleted_at,updated_at']);
      await f.transactions.restore('t1');
      expect(await recorded(), ['transaction/t1 update deleted_at,updated_at']);
    });

    test('a delete records the delete instant as the tombstone', () async {
      await f.accounts.upsert(testAccount('a1'));
      await f.transactions.upsert(testTransaction('t1', 'a1', -100));
      await f.transactions.delete('t1');
      final ChangeLogEntry delete = (await sync.unsynced()).last;
      expect(delete.operation, ChangeOperation.delete);
      expect(
        delete.payload[deletedAtField],
        const UtcInstantConverter().toJson(delete.hlc.wall),
      );
    });

    test('a Plaid transaction records only the user-owned fields', () async {
      await f.accounts.upsert(testAccount('a1'));
      await recorded();
      final Transaction plaid = testTransaction(
        'p1',
        'a1',
        -100,
      ).copyWith(source: DataSource.plaid);
      await f.transactions.upsert(plaid);
      expect(await recorded(), isEmpty, reason: 'Plaid creates its own rows');
      await f.transactions.upsert(
        plaid.copyWith(
          name: 'Renamed by Plaid',
          notes: 'mine',
          tags: ['x'],
          userCategoryId: 'c1',
        ),
      );
      expect(await recorded(), [
        'transaction/p1 update notes,tags,user_category_id',
      ]);
      await f.transactions.upsert(
        (await f.transactions.watchById('p1').first)!.copyWith(hidden: true),
      );
      expect(await recorded(), ['transaction/p1 update hidden']);
      await expectLater(f.transactions.delete('p1'), throwsException);
      expect(await recorded(), isEmpty);
    });

    test('a batch records one entry per transaction it changes', () async {
      await f.accounts.upsert(testAccount('a1'));
      await f.transactions.upsert(testTransaction('t1', 'a1', -100));
      await f.transactions.upsert(testTransaction('t2', 'a1', -200));
      final Transaction plaid = testTransaction(
        'p1',
        'a1',
        -300,
      ).copyWith(source: DataSource.plaid);
      await f.transactions.applyPlaid([plaid]);
      await recorded();

      await f.transactions.upsertAll([
        testTransaction('t1', 'a1', -100, hidden: true),
        testTransaction('t2', 'a1', -200),
        plaid.copyWith(hidden: true, tags: ['tv']),
        testTransaction('t3', 'a1', -400),
      ]);
      expect(await recorded(), [
        'transaction/t1 update hidden',
        'transaction/p1 update hidden,tags',
        'transaction/t3 create $transactionFields',
      ]);

      await expectLater(
        f.transactions.upsertAll([
          testTransaction('t2', 'a1', -200, notes: 'kept?'),
          plaid.copyWith(name: 'Renamed'),
        ]),
        throwsA(isA<TransactionBatchException>()),
      );
      await expectLater(
        f.transactions.deleteAll(['t2', 'p1']),
        throwsA(isA<TransactionBatchException>()),
      );
      expect(
        await recorded(),
        isEmpty,
        reason: 'a refused batch records nothing',
      );

      await f.transactions.deleteAll(['t1', 't2']);
      expect(await recorded(), [
        'transaction/t1 delete deleted_at,updated_at',
        'transaction/t2 delete deleted_at,updated_at',
      ]);
    });

    test(
      'derived and demo transactions and linked accounts are not recorded',
      () async {
        await f.accounts.upsert(testAccount('a1'));
        await recorded();
        for (final DataSource source in [DataSource.derived, DataSource.demo]) {
          final Transaction t = testTransaction(
            't-${source.name}',
            'a1',
            -1,
          ).copyWith(source: source);
          await f.transactions.upsert(t);
          await f.transactions.upsert(t.copyWith(notes: 'n'));
          await f.transactions.delete(t.id);
        }
        await f.accounts.upsert(
          testAccount('linked').copyWith(itemId: 'item-1', name: 'Bank'),
        );
        await f.accounts.upsert(
          testAccount('linked').copyWith(itemId: 'item-1', name: 'Renamed'),
        );
        expect(await recorded(), isEmpty);
      },
    );

    test(
      'categories: the seeding is not recorded, edits and deletes are',
      () async {
        await f.categories.ensureSeeded();
        expect(await recorded(), isEmpty);
        final Category food = (await f.categories
            .watchById('plaid:FOOD_AND_DRINK')
            .first)!;
        await f.categories.upsert(food.copyWith(icon: 'cake'));
        expect(await recorded(), ['category/plaid:FOOD_AND_DRINK update icon']);

        const Category parent = Category(
          id: 'u1',
          name: 'Hobbies',
          isSystem: false,
          icon: 'palette',
          color: 1,
        );
        await f.categories.upsert(parent);
        await f.categories.upsert(
          parent.copyWith(id: 'u2', name: 'Paint', parentId: 'u1'),
        );
        expect(await recorded(), [
          'category/u1 create color,icon,id,is_system,name,parent_id,plaid_category',
          'category/u2 create color,icon,id,is_system,name,parent_id,plaid_category',
        ]);
        await f.categories.delete('u1');
        expect(
          await recorded(),
          unorderedEquals([
            'category/u1 delete deleted_at',
            'category/u2 delete deleted_at',
          ]),
        );
      },
    );

    test('rules: every write records what it changed', () async {
      await f.rules.upsert(testRule('r1'));
      await f.rules.upsert(testRule('r2', position: 1));
      expect(await recorded(), [
        'rule/r1 create actions,conditions,id,name,position',
        'rule/r2 create actions,conditions,id,name,position',
      ]);
      await f.rules.upsert(testRule('r1', name: 'Coffee shops'));
      await f.rules.upsert(testRule('r1', name: 'Coffee shops'));
      expect(await recorded(), ['rule/r1 update name']);
      await f.rules.reorder(['r2', 'r1']);
      expect(await recorded(), [
        'rule/r2 update position',
        'rule/r1 update position',
      ]);
      await f.rules.reorder(['r2', 'r1']);
      await f.rules.delete('r1');
      expect(await recorded(), ['rule/r1 delete deleted_at']);
      await expectLater(
        f.rules.upsert(testRule('r1')),
        throwsA(isA<EntityDeletedException>()),
      );
      await f.rules.restore('r1');
      expect(await recorded(), ['rule/r1 update deleted_at']);
      final EntityRecord record = (await sync.read(EntityType.rule, 'r1'))!;
      expect(record.isComplete, isTrue);
      expect(record.fields['position'], 1);
    });

    test('budgets: every write records what it changed', () async {
      await f.budgets.upsert(testBudget('b1'));
      expect(await recorded(), [
        'budget/b1 create amount,category_id,id,period,period_start_day,'
            'rollover,start_date',
      ]);
      await f.budgets.upsert(testBudget('b1', amount: 50000));
      await f.budgets.upsert(testBudget('b1', amount: 50000));
      expect(await recorded(), ['budget/b1 update amount']);
      await f.budgets.delete('b1');
      expect(await recorded(), ['budget/b1 delete deleted_at']);
      await expectLater(
        f.budgets.upsert(testBudget('b1')),
        throwsA(isA<EntityDeletedException>()),
      );
      await f.budgets.restore('b1');
      expect(await recorded(), ['budget/b1 update deleted_at']);
      final EntityRecord record = (await sync.read(EntityType.budget, 'b1'))!;
      expect(record.isComplete, isTrue);
      expect(record.fields['amount'], {
        'minor_units': 50000,
        'currency': 'USD',
      });
      expect(record.fields['start_date'], '2026-08-25');
    });

    test('bills: every write records what it changed', () async {
      await f.bills.upsert(testBill('b1'));
      expect(await recorded(), [
        'bill_reminder/b1 create account_id,active,amount,autopay,cadence,due_date,'
            'id,liability_account_id,name,paid_occurrences,reminder_minutes,'
            'reminder_offset_days,stream_id',
      ]);
      await f.bills.upsert(testBill('b1', paid: [LocalDate(2026, 11, 1)]));
      await f.bills.upsert(testBill('b1', paid: [LocalDate(2026, 11, 1)]));
      expect(await recorded(), ['bill_reminder/b1 update paid_occurrences']);
      await f.bills.delete('b1');
      expect(await recorded(), ['bill_reminder/b1 delete deleted_at']);
      await expectLater(
        f.bills.upsert(testBill('b1')),
        throwsA(isA<EntityDeletedException>()),
      );
      await f.bills.restore('b1');
      expect(await recorded(), ['bill_reminder/b1 update deleted_at']);
      final EntityRecord record = (await sync.read(
        EntityType.billReminder,
        'b1',
      ))!;
      expect(record.isComplete, isTrue);
      expect(record.fields['paid_occurrences'], ['2026-11-01']);
      expect(record.fields['amount'], {
        'minor_units': -150000,
        'currency': 'USD',
      });
    });

    test('goals and contributions: every write records what it changed, each '
        'contribution a record of its own', () async {
      await f.goals.create(testGoal('g1'));
      expect(await recorded(), [
        'goal/g1 create archived_at,created_on,id,kind,'
            'linked_account_ids,name,note,target,target_date',
      ]);
      await f.goals.update(testGoal('g1', name: 'Rainy day'));
      await f.goals.update(testGoal('g1', name: 'Rainy day'));
      expect(await recorded(), ['goal/g1 update name']);
      await f.goals.setArchived('g1', archived: true);
      expect(await recorded(), ['goal/g1 update archived_at']);
      await f.goals.addContribution(testContribution('c1'));
      expect(await recorded(), [
        'goal_contribution/c1 create amount,date,goal_id,id,note',
      ]);
      await f.goals.deleteContribution('c1');
      expect(await recorded(), ['goal_contribution/c1 delete deleted_at']);
      await f.goals.restoreContribution('c1');
      expect(await recorded(), ['goal_contribution/c1 update deleted_at']);
      await f.goals.delete('g1');
      expect(await recorded(), ['goal/g1 delete deleted_at']);
      await expectLater(
        f.goals.addContribution(testContribution('c2')),
        throwsA(isA<EntityDeletedException>()),
      );
      expect(await recorded(), isEmpty);
      await f.goals.restore('g1');
      expect(await recorded(), ['goal/g1 update deleted_at']);
      final EntityRecord record = (await sync.read(EntityType.goal, 'g1'))!;
      expect(record.isComplete, isTrue);
      expect(record.fields['target'], {
        'minor_units': 500000,
        'currency': 'USD',
      });
      expect(record.fields['linked_account_ids'], ['savings', 'checking']);
    });

    test(
      'settings: each save an update of what changed, from the defaults',
      () async {
        await f.settings.save(
          const Settings(themeMode: AppThemeMode.dark, useDynamicColor: true),
        );
        expect(await recorded(), ['settings/local update theme_mode']);
        await f.settings.save(
          const Settings(themeMode: AppThemeMode.dark, useDynamicColor: false),
        );
        expect(await recorded(), ['settings/local update use_dynamic_color']);
      },
    );

    test('stream overrides: each write an update of what changed, a clear a '
        'delete; the streams themselves record nothing', () async {
      await f.streams.applyPlaid([testStream('s1')]);
      await f.streams.replaceDetected([
        testStream('d1', source: RecurringSource.detected),
      ]);
      expect(await recorded(), isEmpty);
      await f.streams.setOverride('s1', (o) => o.withMuted(true));
      expect(await recorded(), ['recurring_stream/s1 update muted']);
      await f.streams.setOverride('s1', (o) => o.withMuted(true));
      expect(await recorded(), isEmpty);
      await f.streams.setOverride(
        's1',
        (o) => o.withDisplayName('TV').withSubscription(true),
      );
      expect(await recorded(), [
        'recurring_stream/s1 update display_name,is_subscription',
      ]);
      await f.streams.clearOverride('s1');
      expect(await recorded(), ['recurring_stream/s1 delete deleted_at']);
      await f.streams.setOverride('s1', (o) => o.withMuted(true));
      expect(await recorded(), [
        'recurring_stream/s1 update deleted_at,display_name,is_subscription',
      ]);
      final EntityRecord record = (await sync.read(
        EntityType.recurringStream,
        's1',
      ))!;
      expect(record.isComplete, isFalse, reason: 'never created');
      expect(record.fields, {
        'muted': true,
        'is_subscription': null,
        'display_name': null,
        deletedAtField: null,
      });
    });

    test(
      'each entry carries the values written, at increasing clocks',
      () async {
        await f.accounts.upsert(testAccount('a1'));
        await f.accounts.upsert(testAccount('a1', displayOrder: 3));
        final List<ChangeLogEntry> entries = await sync.unsynced();
        expect(entries.last.payload, {'display_order': 3});
        expect(entries.first.payload['name'], 'Account a1');
        expect(entries.first.hlc.compareTo(entries.last.hlc), lessThan(0));
        expect(entries.every((e) => !e.synced), isTrue);
        final EntityRecord record = (await sync.read(
          EntityType.account,
          'a1',
        ))!;
        expect(record.fields['display_order'], 3);
        expect(record.isComplete, isTrue);
      },
    );
  });
}
