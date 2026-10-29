/// What the screens read of the investments (`docs/reference/investments.md`); the
/// repositories are `holdingRepositoryProvider` and
/// `investmentTransactionRepositoryProvider` (`core/di/providers.dart`).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'investments_providers.g.dart';

/// Every holding of the user's linked investment accounts with its security, by
/// account, then security name.
@riverpod
Stream<List<HoldingView>> holdings(Ref ref) =>
    ref.watch(holdingRepositoryProvider).watchAll();

/// The live investment transactions of account [accountId], newest first.
@riverpod
Stream<List<InvestmentTransaction>> investmentTransactions(
  Ref ref,
  String accountId,
) => ref
    .watch(investmentTransactionRepositoryProvider)
    .watchByAccount(accountId);
