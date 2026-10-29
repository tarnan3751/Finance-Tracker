// The Drift GoalRepository against the shared contract.
import '../../../contract/drift_fixtures.dart';
import '../../../contract/goal_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runGoalRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
