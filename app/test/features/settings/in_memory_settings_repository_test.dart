// The in-memory settings repository against the shared contract.
import 'package:finance_tracker/features/settings/data/in_memory_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'settings_repository_contract.dart';

void main() {
  settingsRepositoryContract('InMemorySettingsRepository', () {
    final InMemorySettingsRepository repository = InMemorySettingsRepository();
    addTearDown(repository.close);
    return repository;
  });
}
