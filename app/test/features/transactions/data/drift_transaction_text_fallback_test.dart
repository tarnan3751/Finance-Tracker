// The Drift TransactionRepository on a SQLite without FTS5 (data.md, **Full-text
// search**): TransactionQuery.text falls back to one LIKE substring of the name, the
// merchant name or the notes, ASCII letters folded, LIKE's metacharacters literal.
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';
import '../../../contract/repository_fixture.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures(fullTextSearch: false);
  late TransactionRepository transactions;

  setUp(() async {
    final RepositoryFixture f = await fixtures.create();
    transactions = f.transactions;
    await f.accounts.upsert(testAccount('a1'));
    await transactions.upsert(
      testTransaction(
        't1',
        'a1',
        -1500,
        name: 'GROCER 12',
        merchantName: 'Corner Grocer',
        tags: const ['food'],
      ),
    );
    await transactions.upsert(
      testTransaction('t2', 'a1', -1, name: 'Payroll', notes: 'October SALARY'),
    );
    await transactions.upsert(
      testTransaction('t3', 'a1', -1, name: 'Café Été'),
    );
    await transactions.upsert(
      testTransaction('t4', 'a1', -1, name: '50% off_sale \\ deal'),
    );
    await transactions.upsert(
      testTransaction('t5', 'a1', -1, name: '50x offXsale'),
    );
  });
  tearDown(fixtures.dispose);

  Future<Set<String>> ids(String text) async => {
    for (final t
        in await transactions.watch(TransactionQuery(text: text)).first)
      t.id,
  };

  test(
    'matches one substring of the name, merchant or notes, ASCII case folded',
    () async {
      expect(await ids('rocer'), {'t1'});
      expect(await ids('CORNER'), {'t1'});
      expect(await ids('salary'), {'t2'});
      expect(await ids('café'), {'t3'});
      expect(await ids('CAFÉ'), isEmpty, reason: 'only ASCII letters fold');
      expect(await ids('food'), isEmpty, reason: 'tags are not searched');
      expect(await ids('corner grocer'), {'t1'});
      expect(await ids(''), hasLength(5));
    },
  );

  test("matches LIKE's metacharacters literally", () async {
    expect(await ids('50%'), {'t4'});
    expect(await ids('off_sale'), {'t4'});
    expect(await ids(r'\ deal'), {'t4'});
    expect(await ids('%'), {'t4'});
  });
}
