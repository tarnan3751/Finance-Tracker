// Search on a device. Run on the harness's emulator with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The APK's SQLite has FTS5: the app's encrypted database, opened by its real open path,
// takes the full-text path and finds a bank's transaction by two word prefixes. Then the
// demo starts as main_demo.dart does and the list's search finds the newest transaction of
// a linked account by the prefixes of its first two words.
import 'dart:io';

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/search_text.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_models/shared_models.dart';

Finder _tab(String name) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the encrypted database searches through FTS5', (tester) async {
    final File file = File(
      p.join((await getApplicationSupportDirectory()).path, databaseFileName),
    );
    if (file.existsSync()) file.deleteSync();
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    final AppDatabase database = openAppDatabase(
      AppConfig.prod(),
      InMemoryDatabaseKeyStore(),
    );
    addTearDown(database.close);
    expect(await database.fullTextSearch, isTrue);

    final DateTime now = DateTime.utc(2026, 10, 25, 12);
    const Clock clock = SystemClock();
    await DriftAccountRepository(
      database,
      clock,
      recorder: const NoChangeRecorder(),
    ).applyPlaid([
      const Account(
        id: 'acc-linked',
        itemId: 'item-1',
        type: AccountType.depository,
        name: 'Plaid Checking',
        currencyCode: 'USD',
        isHidden: false,
        displayOrder: 0,
      ),
    ]);
    final DriftTransactionRepository transactions = DriftTransactionRepository(
      database,
      clock,
      recorder: const NoChangeRecorder(),
    );
    await transactions.applyPlaid([
      Transaction(
        id: 'plaid-1',
        accountId: 'acc-linked',
        amount: Money(-575, 'USD'),
        date: LocalDate(2026, 10, 24),
        pending: false,
        name: 'POS PURCHASE STARBUCKS STORE 1234',
        merchantName: 'Starbucks',
        source: DataSource.plaid,
        createdAt: now,
        updatedAt: now,
        syncVersion: 1,
      ),
    ]);
    final List<Transaction> found = await transactions
        .watch(TransactionQuery(text: 'starb STO'))
        .first;
    expect([for (final Transaction t in found) t.id], ['plaid-1']);
  });

  testWidgets('demo: two word prefixes find a linked bank row', (tester) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final Set<String> linked = {
      for (final Account a
          in await container.read(accountRepositoryProvider).watchAll().first)
        if (a.itemId != null) a.id,
    };
    final Transaction target =
        (await container
                .read(transactionRepositoryProvider)
                .watch(TransactionQuery(hidden: false, limit: 50))
                .first)
            .firstWhere(
              (t) =>
                  linked.contains(t.accountId) &&
                  searchTokens(t.name).length >= 2,
            );
    final List<String> words = searchTokens(target.name);
    final String text = [
      for (final String w in words.take(2))
        w.substring(0, w.length < 3 ? w.length : 3),
    ].join(' ');

    await _tap(tester, _tab('Transactions'));
    await _tap(tester, find.byTooltip('Search'));
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey(target.id)), findsOneWidget, reason: text);
  });
}
