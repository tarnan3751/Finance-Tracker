// The Drift CategoryRepository against the shared contract.
import '../../../contract/category_repository_contract.dart';
import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runCategoryRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
