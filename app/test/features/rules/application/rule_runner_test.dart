// The rules on arrival, over the in-memory and the Drift repositories: a matching rule
// files (or hides) an arriving Plaid transaction and is recorded as an override; a field
// another device (or the user) has set, hidden included, is left alone; a row the runner cannot write is logged
// and skipped, never thrown, and the others still change.
import 'package:finance_tracker/features/rules/application/rule_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';

import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';
import '../../../contract/repository_fixture.dart';

Transaction _plaid(String id, {String accountId = 'a1'}) => testTransaction(
  id,
  accountId,
  -450,
  name: 'STARBUCKS STORE 08812',
  merchantName: 'Starbucks',
).copyWith(source: DataSource.plaid);

const Rule _coffee = Rule(
  id: 'r-coffee',
  name: 'Coffee',
  position: 0,
  conditions: [
    RuleCondition(kind: RuleConditionKind.merchantContains, text: 'starbucks'),
  ],
  actions: [
    RuleAction(kind: RuleActionKind.setCategory, value: 'u1'),
    RuleAction(kind: RuleActionKind.addTag, value: 'coffee'),
  ],
);

void main() {
  for (final (String name, FixtureFactory fixtures) in [
    ('in memory', inMemoryFixtures()),
    ('Drift', driftFixtures()),
  ]) {
    group('$name: the rules on arrival', () {
      late RepositoryFixture f;
      late RuleRunner runner;

      setUp(() async {
        f = await fixtures.create();
        runner = RuleRunner(
          rules: f.rules,
          categories: f.categories,
          transactions: f.transactions,
          syncStore: f.syncStore,
        );
        await f.accounts.upsert(testAccount('a1'));
        await f.categories.upsert(
          const Category(
            id: 'u1',
            name: 'Coffee',
            isSystem: false,
            icon: 'coffee',
            color: 1,
          ),
        );
        await f.rules.upsert(_coffee);
      });
      tearDown(fixtures.dispose);

      Future<List<String>> entries(String id) async => [
        for (final ChangeLogEntry e in await f.syncStore!.unsynced(limit: 1000))
          if (e.entityId == id)
            '${e.operation.name} ${(e.payload.keys.toList()..sort()).join(',')}',
      ];

      test(
        'a hide rule hides an arriving row unless the user unhid it',
        () async {
          await f.rules.upsert(
            _coffee.copyWith(
              actions: const [RuleAction(kind: RuleActionKind.hide)],
            ),
          );
          await f.transactions.upsert(_plaid('p1'));
          await f.transactions.upsert(_plaid('p2'));
          // The user (here, or on another device) hid and then unhid p2.
          await f.transactions.upsert(_plaid('p2').copyWith(hidden: true));
          await f.transactions.upsert(_plaid('p2'));
          await runner.onArrived([
            (await f.transactions.watchById('p1').first)!,
            (await f.transactions.watchById('p2').first)!,
          ]);
          expect((await f.transactions.watchById('p1').first)!.hidden, isTrue);
          expect(await entries('p1'), ['update hidden']);
          expect((await f.transactions.watchById('p2').first)!.hidden, isFalse);
          expect(await entries('p2'), ['update hidden', 'update hidden']);
        },
      );

      test(
        'a matching rule files the transaction, recorded as an override',
        () async {
          await f.transactions.upsert(_plaid('p1'));
          await runner.onArrived([_plaid('p1')]);
          final Transaction stored = (await f.transactions
              .watchById('p1')
              .first)!;
          expect(stored.userCategoryId, 'u1');
          expect(stored.tags, ['coffee']);
          expect(stored.source, DataSource.plaid);
          expect(await entries('p1'), ['update tags,user_category_id']);

          // Again: nothing changes, nothing more is recorded.
          await runner.onArrived([stored]);
          expect(await entries('p1'), ['update tags,user_category_id']);
        },
      );

      test('an override that already has a sync clock is left alone', () async {
        await f.transactions.upsert(_plaid('p1'));
        // The user (here, or on another device) set and then cleared the category.
        await f.transactions.upsert(
          _plaid('p1').copyWith(userCategoryId: 'u1'),
        );
        await f.transactions.upsert(_plaid('p1'));
        expect(await entries('p1'), [
          'update user_category_id',
          'update user_category_id',
        ]);
        await runner.onArrived([(await f.transactions.watchById('p1').first)!]);
        final Transaction stored = (await f.transactions
            .watchById('p1')
            .first)!;
        expect(stored.userCategoryId, isNull);
        expect(stored.tags, ['coffee']);
      });

      test(
        'a row that cannot be written is skipped; the others change',
        () async {
          final List<LogRecord> logs = [];
          Logger.root.level = Level.ALL;
          final sub = Logger('rules').onRecord.listen(logs.add);
          addTearDown(sub.cancel);
          await f.transactions.upsert(_plaid('p1'));
          await f.transactions.upsert(_plaid('p3'));
          await runner.onArrived([
            _plaid('p1'),
            _plaid('p2', accountId: 'missing'),
            _plaid('p3'),
          ]);
          expect(
            (await f.transactions.watchById('p1').first)!.userCategoryId,
            'u1',
          );
          expect(
            (await f.transactions.watchById('p3').first)!.userCategoryId,
            'u1',
          );
          expect(
            logs.map((r) => r.message),
            contains(
              'rule r-coffee not applied to a transaction: '
              'AccountNotFoundException',
            ),
          );
          expect(
            logs.map((r) => r.message).join(),
            isNot(contains('Starbucks')),
          );
        },
      );

      test(
        'with no rules, or nothing added, nothing is read or written',
        () async {
          await f.rules.delete(_coffee.id);
          await f.transactions.upsert(_plaid('p1'));
          await runner.onArrived([_plaid('p1')]);
          await runner.onArrived(const []);
          expect(
            (await f.transactions.watchById('p1').first)!.userCategoryId,
            isNull,
          );
        },
      );
    });
  }

  test(
    'in the demo (no sync store) the rules apply and nothing is read',
    () async {
      final FixtureFactory fixtures = demoFixtures();
      final RepositoryFixture f = await fixtures.create();
      addTearDown(fixtures.dispose);
      await f.accounts.upsert(testAccount('a1'));
      await f.categories.upsert(
        const Category(
          id: 'u1',
          name: 'Coffee',
          isSystem: false,
          icon: 'c',
          color: 1,
        ),
      );
      await f.rules.upsert(_coffee);
      final Transaction demo = _plaid('d1').copyWith(source: DataSource.demo);
      await f.transactions.upsert(demo);
      await RuleRunner(
        rules: f.rules,
        categories: f.categories,
        transactions: f.transactions,
      ).onArrived([demo]);
      expect((await f.transactions.watchById('d1').first)!.tags, ['coffee']);
    },
  );
}
