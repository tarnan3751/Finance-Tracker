// The Demo TransactionRepository against the shared contract.
import '../../../contract/memory_fixtures.dart';
import '../../../contract/transaction_repository_contract.dart';

void main() {
  final FixtureFactory fixtures = demoFixtures();
  runTransactionRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
