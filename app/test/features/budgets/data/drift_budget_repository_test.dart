// The Drift BudgetRepository against the shared contract.
import '../../../contract/budget_repository_contract.dart';
import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runBudgetRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
