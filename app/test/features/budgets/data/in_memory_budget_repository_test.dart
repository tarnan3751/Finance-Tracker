// The InMemory BudgetRepository against the shared contract.
import '../../../contract/budget_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = inMemoryFixtures();
  runBudgetRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
