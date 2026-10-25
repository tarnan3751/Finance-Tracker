// The in-memory SavedFilterRepository (the demo's too) against the shared contract, and
// the demo's samples, which decode as the filters they name.
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/data/demo_saved_filters.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_saved_filter_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../contract/saved_filter_repository_contract.dart';

void main() {
  late InMemorySavedFilterRepository repository;
  runSavedFilterRepositoryContract(
    () async => repository = InMemorySavedFilterRepository(),
    dispose: () => repository.close(),
  );

  test('the demo samples are what their names say', () async {
    final InMemorySavedFilterRepository demo = InMemorySavedFilterRepository(
      initial: demoSavedFilters,
    );
    addTearDown(demo.close);
    final List<TransactionFilters> filters = [
      for (final f in await demo.watchAll().first)
        TransactionFilters.fromJson(f.filters),
    ];
    expect(filters, [
      const TransactionFilters(
        categoryIds: {'plaid:FOOD_AND_DRINK'},
        date: DateFilter(DatePreset.thisMonth),
      ),
      TransactionFilters(
        date: const DateFilter(DatePreset.last90Days),
        minAmount: Money(10000, 'USD'),
      ),
    ]);
  });
}
