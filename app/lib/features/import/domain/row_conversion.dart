/// A file's rows read through a mapping into what will be imported
/// (`docs/reference/import.md`, **The review**). Pure Dart.
///
/// A row becomes an [ImportedRow], or a [RowFailure] with the reason it is skipped:
///
/// - the date must read in the mapping's format;
/// - the amount must read (`amount_parser.dart`) and not be zero; with a debit and a
///   credit column, exactly one of them carries a nonzero amount, and the result is the
///   credit's magnitude less the debit's, so either sign convention in those columns
///   reads the same;
/// - the description is the name, or the merchant when the description is blank, and one
///   of them must be there.
///
/// A field past the end of a short row is blank. Tags are read only from a mapped tags
/// column, split on `;`: a field with no `;` is one tag.
library;

import 'package:finance_tracker/features/import/domain/amount_parser.dart';
import 'package:finance_tracker/features/import/domain/import_mapping.dart';
import 'package:shared_models/shared_models.dart';

/// Why a row is skipped.
enum RowProblem {
  /// The date is missing or not in the mapping's format.
  badDate,

  /// The amount is blank.
  noAmount,

  /// The amount is not a number.
  badAmount,

  /// Both the debit and the credit carry an amount.
  debitAndCredit,

  /// The amount is zero.
  zeroAmount,

  /// Neither the description nor the merchant is there.
  noDescription,
}

/// A row that will be imported.
final class ImportedRow {
  /// The row numbered [row].
  const ImportedRow({
    required this.row,
    required this.date,
    required this.amount,
    required this.name,
    this.merchant,
    this.notes,
    this.category,
    this.tags = const [],
  });

  /// Its number in the file's rows, from 1 (blank lines are not counted).
  final int row;
  final LocalDate date;
  final Money amount;
  final String name;
  final String? merchant;
  final String? notes;

  /// The category's name as the file writes it.
  final String? category;
  final List<String> tags;
}

/// A row that will not be imported, and why.
typedef RowFailure = ({int row, RowProblem problem});

/// What a file's rows read as.
final class ImportParse {
  /// The rows read and the rows skipped.
  const ImportParse({required this.rows, required this.failures});

  /// The rows that will be imported, in the file's order.
  final List<ImportedRow> rows;

  /// The rows skipped, in the file's order.
  final List<RowFailure> failures;
}

/// [dataRows] (the rows after the header, the first numbered [firstRow]) read through
/// [mapping] into amounts in [currencyCode].
ImportParse convertRows(
  List<List<String>> dataRows,
  ImportMapping mapping, {
  required String currencyCode,
  required int firstRow,
}) {
  final int scale = Currency.scaleOf(currencyCode);
  final List<ImportedRow> rows = [];
  final List<RowFailure> failures = [];
  for (int i = 0; i < dataRows.length; i++) {
    final List<String> fields = dataRows[i];
    final int number = firstRow + i;
    String field(ImportRole role) {
      final int? column = mapping.columns[role];
      return column == null || column >= fields.length
          ? ''
          : fields[column].trim();
    }

    String? optional(ImportRole role) {
      final String value = field(role);
      return value.isEmpty ? null : value;
    }

    final LocalDate? date = mapping.dateFormat.parse(field(ImportRole.date));
    if (date == null) {
      failures.add((row: number, problem: RowProblem.badDate));
      continue;
    }
    final (int? minor, RowProblem? problem) = _amount(field, mapping, scale);
    if (problem != null) {
      failures.add((row: number, problem: problem));
      continue;
    }
    final String? merchant = optional(ImportRole.merchant);
    final String? name = optional(ImportRole.description) ?? merchant;
    if (name == null) {
      failures.add((row: number, problem: RowProblem.noDescription));
      continue;
    }
    rows.add(
      ImportedRow(
        row: number,
        date: date,
        amount: Money(minor!, currencyCode),
        name: name,
        merchant: merchant,
        notes: optional(ImportRole.notes),
        category: optional(ImportRole.category),
        tags: _tags(field(ImportRole.tags)),
      ),
    );
  }
  return ImportParse(rows: rows, failures: failures);
}

(int?, RowProblem?) _amount(
  String Function(ImportRole) field,
  ImportMapping mapping,
  int scale,
) {
  int? read(String text) {
    if (text.isEmpty) return null;
    return parseMinorUnits(text, separator: mapping.separator, scale: scale);
  }

  try {
    if (!mapping.debitCredit) {
      final int? signed = read(field(ImportRole.amount));
      if (signed == null) return (null, RowProblem.noAmount);
      if (signed == 0) return (null, RowProblem.zeroAmount);
      return (mapping.outflowsNegative ? signed : -signed, null);
    }
    final int? debit = read(field(ImportRole.debit));
    final int? credit = read(field(ImportRole.credit));
    if (debit == null && credit == null) return (null, RowProblem.noAmount);
    final int out = (debit ?? 0).abs(), into = (credit ?? 0).abs();
    if (out != 0 && into != 0) return (null, RowProblem.debitAndCredit);
    if (out == 0 && into == 0) return (null, RowProblem.zeroAmount);
    return (into - out, null);
  } on AmountFormatException catch (e) {
    return (
      null,
      e.problem == AmountProblem.empty
          ? RowProblem.noAmount
          : RowProblem.badAmount,
    );
  }
}

List<String> _tags(String field) {
  final List<String> tags = [];
  for (final String part in field.split(';')) {
    final String tag = part.trim();
    if (tag.isNotEmpty && !tags.contains(tag)) tags.add(tag);
  }
  return tags;
}
