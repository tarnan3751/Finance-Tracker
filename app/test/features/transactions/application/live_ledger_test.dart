// The live ledger is one watch of the whole ledger: the recurring streams, the detector,
// the duplicates, the rules' preview, the reports and the weekly summary listening at
// once open it once, and a write reaches every one of them through it.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/duplicates/application/duplicates_providers.dart';
import 'package:finance_tracker/features/recurring/application/detector_runner.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/reports/application/reports_providers.dart';
import 'package:finance_tracker/features/reports/application/weekly_summary_providers.dart';
import 'package:finance_tracker/features/rules/application/rules_providers.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

// The in-memory repository, counting the watches of the whole ledger it opens.
final class _CountingTransactions extends InMemoryTransactionRepository {
  _CountingTransactions(super.store, {required super.recorder});

  int wholeLedgerWatches = 0;

  @override
  Stream<List<Transaction>> watch(TransactionQuery query) {
    if (query == TransactionQuery.all) wholeLedgerWatches++;
    return super.watch(query);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every reader of the whole ledger shares one watch of it', () async {
    final InMemoryStore store = seededStore();
    late final _CountingTransactions transactions;
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        storeOverride(store),
        clockProvider.overrideWithValue(testClock),
        transactionRepositoryProvider.overrideWith(
          (ref) => transactions = _CountingTransactions(
            ref.watch(inMemoryStoreProvider),
            recorder: ref.watch(changeRecorderProvider),
          ),
        ),
      ],
    );
    const Rule rule = Rule(
      id: 'r1',
      name: 'Coffee',
      position: 0,
      conditions: [
        RuleCondition(kind: RuleConditionKind.merchantContains, text: 'x'),
      ],
      actions: [RuleAction(kind: RuleActionKind.addTag, value: 'x')],
    );
    container.listen(mergedStreamsProvider, (_, _) {});
    container.listen(detectorRunnerProvider, (_, _) {});
    container.listen(duplicateCandidatesProvider, (_, _) {});
    container.listen(rulePreviewProvider(rule), (_, _) {});
    container.listen(reportProvider(0), (_, _) {});
    container.listen(weeklyReportProvider, (_, _) {});
    final int before = (await container.read(liveLedgerProvider.future)).length;
    await container.read(duplicateCandidatesProvider.future);
    await container.read(rulePreviewProvider(rule).future);
    await container.read(weeklyReportProvider.future);
    expect(transactions.wholeLedgerWatches, 1);

    await container
        .read(transactionRepositoryProvider)
        .upsert(testTransaction('new', name: 'New'));
    await pumpEventQueue();
    expect(
      (await container.read(liveLedgerProvider.future)).length,
      before + 1,
    );
    expect(transactions.wholeLedgerWatches, 1);
  });
}
