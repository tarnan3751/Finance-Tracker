// A transaction whose account is deleted or unknown, as sync can leave one (another
// device recorded it while this one deleted the account, or it arrived before its
// account): the list labels it by its category alone, and the editor says the account
// is gone instead of failing.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/test_seed.dart';

/// The store's transactions plus [orphans], whose accounts the store does not have:
/// what a synced store can hold, which the in-memory one's rules never produce.
final class _WithOrphans extends InMemoryTransactionRepository {
  _WithOrphans(super.store, this.orphans)
    : super(recorder: const NoChangeRecorder());

  final List<Transaction> orphans;

  @override
  Stream<List<Transaction>> watch(TransactionQuery query) =>
      super.watch(query).map((live) => [...orphans, ...live]);

  @override
  Stream<Transaction?> watchById(String id) {
    for (final Transaction t in orphans) {
      if (t.id == id) return Stream.value(t);
    }
    return super.watchById(id);
  }
}

void main() {
  testWidgets('a transaction on a deleted or unknown account', (tester) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
    await pumpApp(
      tester,
      initialLocation: '/transactions',
      overrides: [
        storeOverride(store),
        transactionRepositoryProvider.overrideWithValue(
          _WithOrphans(store, [
            testTransaction('t-gone', accountId: 'gone', name: 'Lunch'),
          ]),
        ),
      ],
    );
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Uncategorized'), findsOneWidget);
    expect(find.textContaining(' · '), findsNothing);

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('This account no longer exists.'), findsOneWidget);
  });
}
