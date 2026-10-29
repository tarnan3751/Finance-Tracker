// The Demo GoalRepository against the shared contract.
import '../../../contract/goal_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = demoFixtures();
  runGoalRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
