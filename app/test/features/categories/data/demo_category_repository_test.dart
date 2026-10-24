// The Demo CategoryRepository against the shared contract.
import '../../../contract/category_repository_contract.dart';
import '../../../contract/memory_fixtures.dart';

void main() {
  final FixtureFactory fixtures = demoFixtures();
  runCategoryRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
