/// What the screens read of the liabilities (`docs/reference/liabilities.md`); the
/// repository is `liabilityRepositoryProvider` (`core/di/providers.dart`).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'liabilities_providers.g.dart';

/// Every liability of the user's linked accounts, by account, then kind.
@riverpod
Stream<List<Liability>> liabilities(Ref ref) =>
    ref.watch(liabilityRepositoryProvider).watchAll();
