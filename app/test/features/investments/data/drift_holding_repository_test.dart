// The Drift HoldingRepository against the shared contract.
import '../../../contract/drift_fixtures.dart';
import '../../../contract/holding_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runHoldingRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
