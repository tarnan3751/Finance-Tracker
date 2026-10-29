// The InMemory HoldingRepository against the shared contract.
import '../../../contract/holding_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = inMemoryFixtures();
  runHoldingRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
