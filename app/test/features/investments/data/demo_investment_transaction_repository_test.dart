// The Demo InvestmentTransactionRepository against the shared contract.
import '../../../contract/investment_transaction_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = demoFixtures();
  runInvestmentTransactionRepositoryContract(
    fixtures.create,
    dispose: fixtures.dispose,
  );
}
