// The InMemory BalanceSnapshotRepository against the shared contract.
import '../../../contract/balance_snapshot_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = inMemoryFixtures();
  runBalanceSnapshotRepositoryContract(
    fixtures.create,
    dispose: fixtures.dispose,
  );
}
