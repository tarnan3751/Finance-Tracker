// The Drift InvestmentTransactionRepository against the shared contract.
import '../../../contract/drift_fixtures.dart';
import '../../../contract/investment_transaction_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runInvestmentTransactionRepositoryContract(
    fixtures.create,
    dispose: fixtures.dispose,
  );
}
