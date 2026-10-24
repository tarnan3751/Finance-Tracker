// The Demo ItemRepository against the shared contract.
import '../../../contract/item_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = demoFixtures();
  runItemRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
