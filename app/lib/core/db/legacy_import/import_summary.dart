/// What the legacy importer did, for Phase 1d's one-time snackbar.
library;

import 'package:shared_models/shared_models.dart';

/// The result of importing the original app's data.
final class ImportSummary {
  /// A summary of [transactions] imported entries totalling [total], with [skipped]
  /// entries (or whole lists) that could not be read.
  const ImportSummary({
    required this.transactions,
    required this.total,
    required this.skipped,
  });

  /// How many transactions were created.
  final int transactions;

  /// Their sum: incomes less expenses, in the imported account's currency.
  final Money total;

  /// How many legacy entries could not be read; when nonzero, the legacy data is left in
  /// place.
  final int skipped;

  @override
  bool operator ==(Object other) =>
      other is ImportSummary &&
      other.transactions == transactions &&
      other.total == total &&
      other.skipped == skipped;

  @override
  int get hashCode => Object.hash(transactions, total, skipped);

  @override
  String toString() =>
      'ImportSummary($transactions transactions, $skipped skipped)';
}
