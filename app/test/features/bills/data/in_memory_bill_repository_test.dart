// The InMemory BillRepository against the shared contract.
import '../../../contract/bill_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = inMemoryFixtures();
  runBillRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
