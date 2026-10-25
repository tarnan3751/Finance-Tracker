// The Drift RuleRepository against the shared contract.
import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';
import '../../../contract/rule_repository_contract.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runRuleRepositoryContract(fixtures.create, dispose: fixtures.dispose);
}
