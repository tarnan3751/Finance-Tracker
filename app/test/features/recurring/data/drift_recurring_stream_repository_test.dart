// The Drift RecurringStreamRepository against the shared contract.
import '../../../contract/drift_fixtures.dart';
import '../../../contract/memory_fixtures.dart';
import '../../../contract/recurring_stream_repository_contract.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runRecurringStreamRepositoryContract(
    fixtures.create,
    dispose: fixtures.dispose,
  );
}
