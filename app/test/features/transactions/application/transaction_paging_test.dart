// The transaction list's paging on the dev wiring (Drift): each page is its own query of
// fifty rows at its own offset, so scrolling to a page reads that page once, and a write
// re-reads each loaded page's fifty rows, never one query of every loaded row from the
// start; the pages together list every row once, newest first.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../contract/repository_fixture.dart';
import '../../../helpers/dev_wiring.dart';

// The SELECTs on `transactions` that page, as their LIMIT and OFFSET.
final class _PageQueries extends QueryInterceptor {
  final List<String> pages = [];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    final RegExpMatch? paged = RegExp(
      r'FROM "transactions".* LIMIT (\d+) OFFSET (\d+)',
    ).firstMatch(statement);
    if (paged != null) pages.add('${paged[1]}@${paged[2]}');
    return executor.runSelect(statement, args);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a scroll queries its page once and a write re-queries only the loaded pages', () async {
    final _PageQueries queries = _PageQueries();
    final AppDatabase database = AppDatabase(
      NativeDatabase.memory().interceptWith(queries),
    );
    await database.customStatement(
      'INSERT INTO app_meta (key, value) VALUES (?, ?)',
      [AppMetaKeys.restoreOfferAnswered, '2026-10-24T15:00:00.000Z'],
    );
    final SteppingClock clock = SteppingClock();
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        ...devWiring(),
        ...fakeApiOverrides(signedIn: true),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        syncDeviceIdProvider.overrideWithValue('dev-a'),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });
    await container.read(accountRepositoryProvider).create(testAccount('a1'));
    // 160 rows, one a day: rows 0 to 159, the newest first.
    await container.read(transactionRepositoryProvider).upsertAll([
      for (int i = 0; i < 160; i++)
        testTransaction(
          't${i.toString().padLeft(3, '0')}',
          'a1',
          -100 - i,
          date: LocalDate(2026, 10, 24).addDays(-i),
        ),
    ]);
    container.listen(transactionPageProvider, (_, _) {});
    Future<TransactionPage> settled() async {
      await pumpEventQueue();
      return container.read(transactionPageProvider.future);
    }

    queries.pages.clear();
    TransactionPage page = await settled();
    expect(queries.pages, ['50@0']);
    expect(page.transactions, hasLength(50));
    expect(page.hasMore, isTrue);

    // Two scrolls: each reads its own page once.
    for (final String next in ['50@50', '50@100']) {
      queries.pages.clear();
      container
          .read(transactionListControllerProvider.notifier)
          .loadMore(loaded: page.transactions.length);
      page = await settled();
      expect(queries.pages, [next]);
    }
    expect(
      [for (final Transaction t in page.transactions) t.id],
      [for (int i = 0; i < 150; i++) 't${i.toString().padLeft(3, '0')}'],
    );
    expect(page.hasMore, isTrue);

    // A write re-reads the three loaded pages, fifty rows each; the new row leads.
    queries.pages.clear();
    await container
        .read(transactionRepositoryProvider)
        .upsert(
          testTransaction('new', 'a1', -1, date: LocalDate(2026, 10, 25)),
        );
    page = await settled();
    expect(queries.pages..sort(), ['50@0', '50@100', '50@50']);
    expect(page.transactions.first.id, 'new');
    expect({
      for (final Transaction t in page.transactions) t.id,
    }, hasLength(150));

    // The last page: 161 rows in four pages, the last one short.
    container
        .read(transactionListControllerProvider.notifier)
        .loadMore(loaded: page.transactions.length);
    page = await settled();
    expect(page.transactions, hasLength(161));
    expect(page.hasMore, isFalse);
  });
}
