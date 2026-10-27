/// The demo flavor's [BillRepository]: the in-memory one, holding the two bills of the
/// persona the demo shows (`demo_bills.dart`, through `billRepositoryProvider`).
library;

import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:finance_tracker/features/bills/domain/bill_repository.dart';

/// The demo's bills; changes last until the app closes (or another persona is chosen)
/// and are never recorded for sync.
final class DemoBillRepository extends InMemoryBillRepository {
  /// The repository holding `initial`, stamping deletes from `clock`.
  DemoBillRepository(super.clock, {super.initial})
    : super(recorder: const NoChangeRecorder());
}
