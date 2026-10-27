// The InMemory RecurringStreamRepository against the shared contract.
import '../../../contract/memory_fixtures.dart';
import '../../../contract/recurring_stream_repository_contract.dart';

void main() {
  final FixtureFactory fixtures = inMemoryFixtures();
  runRecurringStreamRepositoryContract(
    fixtures.create,
    dispose: fixtures.dispose,
  );
}
