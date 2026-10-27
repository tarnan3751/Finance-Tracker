// The Demo LiabilityRepository against the shared contract.
import '../../../contract/liability_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = demoFixtures();
  runLiabilityRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
