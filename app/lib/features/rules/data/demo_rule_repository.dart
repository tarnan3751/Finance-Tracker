/// The demo flavor's [RuleRepository]: the in-memory one, holding the two rules of the
/// persona the demo shows (`demo_rules.dart`, through `ruleRepositoryProvider`).
library;

import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/rules/data/in_memory_rule_repository.dart';
import 'package:finance_tracker/features/rules/domain/rule_repository.dart';

/// The demo's rules; changes last until the app closes (or another persona is chosen)
/// and are never recorded for sync.
final class DemoRuleRepository extends InMemoryRuleRepository {
  /// The repository holding `initial`, stamping deletes from `clock`.
  DemoRuleRepository(super.clock, {super.initial})
    : super(recorder: const NoChangeRecorder());
}
