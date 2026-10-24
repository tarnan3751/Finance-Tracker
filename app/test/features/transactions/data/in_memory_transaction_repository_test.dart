// The InMemory TransactionRepository against the shared contract.
import '../../../contract/memory_fixtures.dart';
import '../../../contract/transaction_repository_contract.dart';

void main() {
  final FixtureFactory fixtures = inMemoryFixtures();
  runTransactionRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
