/// The demo flavor's [RecurringStreamRepository]: the in-memory one, holding the
/// persona's streams (`recurringStreamRepositoryProvider`).
library;

import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/recurring/data/in_memory_recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';

/// The demo's streams and overrides; changes last until the app closes (or another
/// persona is chosen) and are never recorded for sync.
final class DemoRecurringStreamRepository
    extends InMemoryRecurringStreamRepository {
  /// The repository holding `initial`, stamping clears from `clock`.
  DemoRecurringStreamRepository(super.clock, {super.initial})
    : super(recorder: const NoChangeRecorder());
}
