/// The demo flavor's [InvestmentTransactionRepository]: the in-memory one, holding the
/// persona's brokerage (`investmentTransactionRepositoryProvider`).
library;

import 'package:finance_tracker/features/investments/data/in_memory_investment_transaction_repository.dart';
import 'package:finance_tracker/features/investments/domain/investment_transaction_repository.dart';

/// The demo's investment transactions; a pull applies what the in-app fake serves, which
/// is the same seed.
final class DemoInvestmentTransactionRepository
    extends InMemoryInvestmentTransactionRepository {
  /// The repository holding `initial`.
  DemoInvestmentTransactionRepository({super.initial});
}
