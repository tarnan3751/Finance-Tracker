// The Drift BalanceSnapshotRepository against the shared contract.
import '../../../contract/balance_snapshot_repository_contract.dart';
import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runBalanceSnapshotRepositoryContract(
    fixtures.create,
    dispose: fixtures.dispose,
  );
}
