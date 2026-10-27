// The Drift LiabilityRepository against the shared contract.
import '../../../contract/drift_fixtures.dart';
import '../../../contract/liability_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runLiabilityRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
