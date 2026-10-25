// The InMemory RuleRepository against the shared contract.
import '../../../contract/memory_fixtures.dart';
import '../../../contract/rule_repository_contract.dart';

void main() {
  final FixtureFactory fixtures = inMemoryFixtures();
  runRuleRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
