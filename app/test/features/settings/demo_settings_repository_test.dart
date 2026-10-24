// The demo settings repository against the shared contract.
import 'package:finance_tracker/features/settings/data/demo_settings_repository.dart';

import '../../contract/settings_repository_contract.dart';

void main() {
  late DemoSettingsRepository repository;
  runSettingsRepositoryContract(
    () async => repository = DemoSettingsRepository(),
    dispose: () => repository.close(),
  );
}
