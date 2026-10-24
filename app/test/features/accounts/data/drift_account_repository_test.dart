// The Drift AccountRepository against the shared contract.
import '../../../contract/account_repository_contract.dart';
import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runAccountRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
