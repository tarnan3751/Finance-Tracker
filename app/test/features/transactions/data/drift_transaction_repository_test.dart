// The Drift TransactionRepository against the shared contract.
import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';
import '../../../contract/transaction_repository_contract.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runTransactionRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
