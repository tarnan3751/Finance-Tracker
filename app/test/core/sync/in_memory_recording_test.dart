// The in-memory repositories against the recording contract; the demo ones record
// nothing.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/demo_account_repository.dart';
import 'package:finance_tracker/features/budgets/data/demo_budget_repository.dart';
import 'package:finance_tracker/features/categories/data/demo_category_repository.dart';
import 'package:finance_tracker/features/rules/data/demo_rule_repository.dart';
import 'package:finance_tracker/features/settings/data/demo_settings_repository.dart';
import 'package:finance_tracker/features/transactions/data/demo_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contract/memory_fixtures.dart';
import '../../contract/recording_contract.dart';
import '../../contract/repository_fixture.dart';

void main() {
  final FixtureFactory fixtures = inMemoryFixtures();
  runRecordingContract(fixtures.create, dispose: fixtures.dispose);

  test('the demo repositories record nothing', () {
    final InMemoryStore store = InMemoryStore(SteppingClock());
    addTearDown(store.close);
    expect(DemoAccountRepository(store).recorder, isA<NoChangeRecorder>());
    expect(DemoTransactionRepository(store).recorder, isA<NoChangeRecorder>());
    expect(DemoCategoryRepository(store).recorder, isA<NoChangeRecorder>());
    expect(DemoSettingsRepository().recorder, isA<NoChangeRecorder>());
    expect(
      DemoRuleRepository(SteppingClock()).recorder,
      isA<NoChangeRecorder>(),
    );
    expect(
      DemoBudgetRepository(SteppingClock()).recorder,
      isA<NoChangeRecorder>(),
    );
  });
}
