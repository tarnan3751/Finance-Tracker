// The in-memory DismissedPairStore against the shared contract.
import 'package:finance_tracker/features/duplicates/data/in_memory_dismissed_pair_store.dart';

import '../../../contract/dismissed_pair_store_contract.dart';

void main() {
  late InMemoryDismissedPairStore store;
  runDismissedPairStoreContract(
    () async => store = InMemoryDismissedPairStore(),
    dispose: () => store.close(),
  );
}
