/// The live rules (`docs/reference/rules.md`); the runner the Plaid pull applies them with
/// is `arrivalProcessorProvider` (`core/di/providers.dart`).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'rules_providers.g.dart';

/// The live rules, in the order they are applied.
@riverpod
Stream<List<Rule>> rules(Ref ref) =>
    ref.watch(ruleRepositoryProvider).watchAll();
