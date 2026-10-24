// The Demo AccountRepository against the shared contract.
import '../../../contract/account_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = demoFixtures();
  runAccountRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
