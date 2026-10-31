/// Which column of a file means what (`docs/reference/import.md`, **The mapping**). Pure
/// Dart.
///
/// The date and the description are required, and the amount comes either from one
/// signed column or from a debit and a credit column, never both (a Monzo-style file has
/// all three; reading both would count each row twice).
library;

import 'package:finance_tracker/features/import/domain/amount_parser.dart';
import 'package:finance_tracker/features/import/domain/date_formats.dart';

/// What a column can be.
enum ImportRole {
  /// The transaction's date.
  date,

  /// One signed amount.
  amount,

  /// The money out, read as a magnitude.
  debit,

  /// The money in, read as a magnitude.
  credit,

  /// The transaction's name.
  description,

  /// The merchant's name.
  merchant,

  /// Notes.
  notes,

  /// A category's name.
  category,

  /// Tags, separated by `;`.
  tags,
}

/// How a file's rows become transactions.
final class ImportMapping {
  /// The mapping of [columns] (each role's column index) read with [dateFormat] and
  /// [separator]; with [debitCredit] the amount is the credit less the debit, else the
  /// [ImportRole.amount] column, negated unless [outflowsNegative].
  ImportMapping({
    required Map<ImportRole, int> columns,
    required this.debitCredit,
    required this.dateFormat,
    required this.separator,
    this.outflowsNegative = true,
  }) : columns = Map.unmodifiable(columns);

  /// Each mapped role's column index.
  final Map<ImportRole, int> columns;

  /// Whether the amount is a debit and a credit column rather than one signed column.
  final bool debitCredit;

  /// How the dates are written.
  final ImportDateFormat dateFormat;

  /// How the amounts are written.
  final DecimalSeparator separator;

  /// Whether the file writes money out as negative (the app's own sign); false flips
  /// a signed amount, for exports where spending is positive.
  final bool outflowsNegative;

  /// Whether every required role has a column: the date, the description, and the amount
  /// or both the debit and the credit.
  bool get isComplete =>
      columns.containsKey(ImportRole.date) &&
      columns.containsKey(ImportRole.description) &&
      (debitCredit
          ? columns.containsKey(ImportRole.debit) &&
                columns.containsKey(ImportRole.credit)
          : columns.containsKey(ImportRole.amount));
}
