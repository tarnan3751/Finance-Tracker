// A rule applied to the existing transactions, over the in-memory, Drift and demo
// repositories: it writes what the preview shows, recorded like a user's edit (on a plaid
// row, the override fields only), each row keeping its updatedAt; a second application
// changes nothing and records nothing; a field another device or the user set is left
// alone; a transaction whose account is deleted is left out; and in Drift a failed write
// rolls the whole application back.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/categories/data/drift_category_repository.dart';
import 'package:finance_tracker/features/rules/application/rule_preview.dart';
import 'package:finance_tracker/features/rules/application/rules_providers.dart';
import 'package:finance_tracker/features/rules/data/drift_rule_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';
import '../../../contract/repository_fixture.dart';

const Category _coffeeCategory = Category(
  id: 'u1',
  name: 'Coffee',
  isSystem: false,
  icon: 'coffee',
  color: 1,
);

const Rule _coffee = Rule(
  id: 'r-coffee',
  name: 'Coffee',
  position: 0,
  conditions: [
    RuleCondition(kind: RuleConditionKind.merchantContains, text: 'coffee'),
  ],
  actions: [
    RuleAction(kind: RuleActionKind.setCategory, value: 'u1'),
    RuleAction(kind: RuleActionKind.addTag, value: 'coffee'),
  ],
);

Transaction _plaid(String id) => testTransaction(
  id,
  'a1',
  -450,
  name: 'BLUE BOTTLE COFFEE',
).copyWith(source: DataSource.plaid);

RuleActions _actions(RepositoryFixture f) => RuleActions(
  f.rules,
  transactions: f.transactions,
  accounts: f.accounts,
  categories: f.categories,
  syncStore: f.syncStore,
);

void main() {
  for (final (String name, FixtureFactory fixtures) in [
    ('in memory', inMemoryFixtures()),
    ('Drift', driftFixtures()),
    ('demo', demoFixtures()),
  ]) {
    group('$name: a rule applied to the existing transactions', () {
      late RepositoryFixture f;

      setUp(() async {
        f = await fixtures.create();
        await f.accounts.upsert(testAccount('a1'));
        await f.categories.upsert(_coffeeCategory);
        await f.transactions.upsert(
          testTransaction('m1', 'a1', -450, name: 'Corner coffee'),
        );
        await f.transactions.upsert(
          testTransaction('m2', 'a1', -1200, name: 'Groceries'),
        );
        await f.transactions.upsert(_plaid('p1'));
      });
      tearDown(fixtures.dispose);

      Future<Transaction> row(String id) async =>
          (await f.transactions.watchById(id).first)!;

      Future<List<String>> entries() async => [
        for (final ChangeLogEntry e
            in await f.syncStore?.unsynced(limit: 1000) ?? const [])
          '${e.entityId} ${e.operation.name} '
              '${(e.payload.keys.toList()..sort()).join(',')}',
      ];

      test('writes what the preview shows, once', () async {
        final List<String> before = await entries();
        final Transaction m1 = await row('m1');
        final RulePreview applied = await _actions(f).applyToHistory(_coffee);
        expect(applied.total, 3);
        expect(
          [for (final RuleChange c in applied.changes) c.before.id],
          ['p1', 'm1'],
        );
        expect(applied.filed, 2);
        expect(applied.tagged, 2);

        for (final String id in ['m1', 'p1']) {
          final Transaction t = await row(id);
          expect(t.userCategoryId, 'u1', reason: id);
          expect(t.tags, ['coffee'], reason: id);
        }
        expect((await row('m1')).updatedAt, m1.updatedAt);
        expect((await row('p1')).source, DataSource.plaid);
        expect((await row('m2')).userCategoryId, isNull);
        if (f.syncStore != null) {
          expect(await entries(), [
            ...before,
            'p1 update tags,user_category_id',
            'm1 update tags,user_category_id',
          ]);
        }

        final List<String> recorded = await entries();
        final RulePreview again = await _actions(f).applyToHistory(_coffee);
        expect(again.changes, isEmpty);
        expect(await entries(), recorded);
      });

      test('a field with a sync clock on a plaid row is left alone', () async {
        if (f.syncStore == null) return; // The demo records nothing.
        // The user set and then cleared the category of the bank row.
        await f.transactions.upsert(
          _plaid('p1').copyWith(userCategoryId: 'u1'),
        );
        await f.transactions.upsert(_plaid('p1'));
        await _actions(f).applyToHistory(_coffee);
        final Transaction p1 = await row('p1');
        expect(p1.userCategoryId, isNull);
        expect(p1.tags, ['coffee']);
      });

      test('a hide rule hides once; a bank row unhidden by its user stays '
          'shown', () async {
        const Rule hide = Rule(
          id: 'r-hide',
          name: 'Hide coffee',
          position: 0,
          conditions: [
            RuleCondition(
              kind: RuleConditionKind.merchantContains,
              text: 'coffee',
            ),
          ],
          actions: [RuleAction(kind: RuleActionKind.hide)],
        );
        if (f.syncStore != null) {
          // The user hid and then showed the bank row: the hidden field is theirs.
          await f.transactions.upsert(_plaid('p1').copyWith(hidden: true));
          await f.transactions.upsert(_plaid('p1'));
        }
        final RulePreview applied = await _actions(f).applyToHistory(hide);
        expect(applied.hidden, f.syncStore == null ? 2 : 1);
        expect((await row('m1')).hidden, isTrue);
        expect((await row('p1')).hidden, f.syncStore == null);
        expect((await _actions(f).applyToHistory(hide)).changes, isEmpty);
      });

      test('a transaction whose account is deleted is left out', () async {
        await f.accounts.upsert(testAccount('a2'));
        await f.transactions.upsert(
          testTransaction('m3', 'a2', -450, name: 'coffee'),
        );
        await f.accounts.delete('a2');
        final RulePreview applied = await _actions(f).applyToHistory(_coffee);
        expect(applied.total, 3);
        expect(applied.changes.map((c) => c.before.id), isNot(contains('m3')));
      });
    });
  }

  test('Drift: a failed write rolls the whole application back', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final SteppingClock clock = SteppingClock();
    final DriftSyncStore store = DriftSyncStore(database, clock);
    final HlcClock hlc = HlcClock('device-a');
    final ChangeRecorder recorder = EngineChangeRecorder(
      store,
      () async => hlc,
      () => clock.nowUtc().millisecondsSinceEpoch,
    );
    final DriftAccountRepository accounts = DriftAccountRepository(
      database,
      clock,
      recorder: recorder,
    );
    final DriftTransactionRepository transactions = DriftTransactionRepository(
      database,
      clock,
      recorder: recorder,
    );
    final DriftCategoryRepository categories = DriftCategoryRepository(
      database,
      clock,
      recorder: recorder,
    );
    await accounts.upsert(testAccount('a1'));
    await categories.upsert(_coffeeCategory);
    // Oldest first, so the newest, written first, has changed when the other fails.
    await transactions.upsert(
      testTransaction(
        'm1',
        'a1',
        -450,
        name: 'coffee one',
        date: LocalDate(2026, 9, 1),
      ),
    );
    await transactions.upsert(
      testTransaction('m2', 'a1', -450, name: 'coffee two'),
    );
    final int outbox = (await store.unsynced(limit: 1000)).length;
    await database.customStatement(
      "CREATE TRIGGER fail_m1 BEFORE UPDATE ON transactions WHEN NEW.id = 'm1' "
      "BEGIN SELECT RAISE(ABORT, 'refused'); END",
    );
    final RuleActions actions = RuleActions(
      DriftRuleRepository(database, clock, recorder: recorder),
      transactions: transactions,
      accounts: accounts,
      categories: categories,
      syncStore: store,
    );
    await expectLater(actions.applyToHistory(_coffee), throwsA(anything));
    for (final String id in ['m1', 'm2']) {
      final Transaction t = (await transactions.watchById(id).first)!;
      expect(t.userCategoryId, isNull, reason: id);
      expect(t.tags, isEmpty, reason: id);
    }
    expect(await store.unsynced(limit: 1000), hasLength(outbox));
  });
}
