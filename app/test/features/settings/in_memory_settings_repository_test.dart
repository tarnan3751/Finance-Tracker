// The in-memory settings repository against the shared contract.
import 'package:finance_tracker/features/settings/data/in_memory_settings_repository.dart';

import '../../contract/settings_repository_contract.dart';

void main() {
  late InMemorySettingsRepository repository;
  runSettingsRepositoryContract(
    () async => repository = InMemorySettingsRepository(),
    dispose: () => repository.close(),
  );
}
