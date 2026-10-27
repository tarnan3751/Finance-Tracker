// The Drift BillRepository against the shared contract.
import '../../../contract/bill_repository_contract.dart';
import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runBillRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
