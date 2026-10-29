// The InMemory GoalRepository against the shared contract.
import '../../../contract/goal_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = inMemoryFixtures();
  runGoalRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
