// The Drift ItemRepository against the shared contract.
import '../../../contract/drift_fixtures.dart';
import '../../../contract/item_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runItemRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
