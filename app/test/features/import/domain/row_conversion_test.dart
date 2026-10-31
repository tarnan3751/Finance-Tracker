// Rows read through a mapping: every fixture's shape (Chase, Bank of America past its
// preamble, Monzo's debit and credit columns and its signed one, the European export,
// the app's own export with its tags and categories), the sign switch, and each reason a
// row is skipped.
import 'package:finance_tracker/features/import/domain/amount_parser.dart';
import 'package:finance_tracker/features/import/domain/csv_reader.dart';
import 'package:finance_tracker/features/import/domain/date_formats.dart';
import 'package:finance_tracker/features/import/domain/header_detection.dart';
import 'package:finance_tracker/features/import/domain/import_mapping.dart';
import 'package:finance_tracker/features/import/domain/row_conversion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../fixtures.dart';

Future<ImportParse> _parse(
  String fixture,
  Map<ImportRole, int> columns, {
  required ImportDateFormat dates,
  DecimalSeparator separator = DecimalSeparator.point,
  bool debitCredit = false,
  bool outflowsNegative = true,
  String currency = 'USD',
}) async {
  final CsvTable t = await readCsv(importFixture(fixture));
  final int header = findHeaderRow(t.rows)!;
  return convertRows(
    t.rows.sublist(header + 1),
    ImportMapping(
      columns: columns,
      debitCredit: debitCredit,
      dateFormat: dates,
      separator: separator,
      outflowsNegative: outflowsNegative,
    ),
    currencyCode: currency,
    firstRow: header + 2,
  );
}

Money _sum(ImportParse p, String currency) =>
    Money.sum(p.rows.map((r) => r.amount), currencyCode: currency);

void main() {
  test('Chase', () async {
    final ImportParse p = await _parse('chase_checking.csv', {
      ImportRole.date: 1,
      ImportRole.description: 2,
      ImportRole.amount: 3,
    }, dates: ImportDateFormat.us);
    expect(p.failures, isEmpty);
    expect(p.rows, hasLength(6));
    expect(p.rows.first.row, 2);
    expect(p.rows.first.date, LocalDate(2026, 10, 28));
    expect(p.rows.first.amount, Money(-8217, 'USD'));
    expect(p.rows.first.name, 'NORTHWIND GROCERS #4411, SPRINGFIELD');
    expect(_sum(p, 'USD'), Money(159703, 'USD'));
  });

  test('Bank of America: the opening balance row has no amount', () async {
    final ImportParse p = await _parse('bofa_preamble.csv', {
      ImportRole.date: 0,
      ImportRole.description: 1,
      ImportRole.amount: 2,
    }, dates: ImportDateFormat.us);
    expect(p.failures, [(row: 7, problem: RowProblem.noAmount)]);
    expect(p.rows, hasLength(4));
    expect(p.rows[2].amount, Money(200000, 'USD'));
    expect(_sum(p, 'USD'), Money(48760, 'USD'));
  });

  test('Monzo: the debit and credit columns, or the signed one', () async {
    final ImportParse split = await _parse(
      'monzo.csv',
      {
        ImportRole.date: 1,
        ImportRole.merchant: 4,
        ImportRole.category: 5,
        ImportRole.notes: 8,
        ImportRole.description: 9,
        ImportRole.debit: 10,
        ImportRole.credit: 11,
      },
      dates: ImportDateFormat.day,
      debitCredit: true,
      currency: 'GBP',
    );
    expect(split.failures, isEmpty);
    expect(split.rows.map((r) => r.amount.minorUnits), [
      -320,
      210000,
      -4567,
      -6000,
      -1899,
    ]);
    expect(split.rows[1].notes, 'October salary');
    expect(split.rows[1].merchant, 'Fabrikam Ltd');
    expect(split.rows[1].category, 'Income');
    expect(split.rows[0].notes, isNull);
    expect(split.rows[4].date, LocalDate(2026, 10, 24));
    final ImportParse signed = await _parse(
      'monzo.csv',
      {ImportRole.date: 1, ImportRole.description: 9, ImportRole.amount: 6},
      dates: ImportDateFormat.day,
      currency: 'GBP',
    );
    expect(_sum(signed, 'GBP'), _sum(split, 'GBP'));
  });

  test('a European export, in euros with decimal commas', () async {
    final ImportParse p = await _parse(
      'european.csv',
      {
        ImportRole.date: 0,
        ImportRole.merchant: 2,
        ImportRole.description: 4,
        ImportRole.amount: 5,
      },
      dates: ImportDateFormat.dotted,
      separator: DecimalSeparator.comma,
      currency: 'EUR',
    );
    expect(p.rows.map((r) => r.amount.minorUnits), [
      -8217,
      245000,
      -450,
      -123456,
    ]);
    expect(p.rows[2].merchant, 'Contoso Café');
    expect(p.rows[2].name, 'Kaffee, groß');
  });

  test('the app export: tags split on ;, one tag without one', () async {
    final ImportParse p = await _parse('app_export.csv', {
      ImportRole.date: 0,
      ImportRole.merchant: 2,
      ImportRole.description: 3,
      ImportRole.amount: 4,
      ImportRole.category: 6,
      ImportRole.tags: 10,
      ImportRole.notes: 11,
    }, dates: ImportDateFormat.iso);
    expect(p.rows.map((r) => r.tags), [
      ['work', 'travel'],
      ['home'],
      <String>[],
    ]);
    expect(p.rows[1].notes, 'Paid early');
    expect(p.rows[1].category, 'Rent');
    expect(p.rows[2].category, isNull);
  });

  test('outflows positive: the switch flips a signed amount', () async {
    final ImportParse p = await _parse(
      'chase_checking.csv',
      {ImportRole.date: 1, ImportRole.description: 2, ImportRole.amount: 3},
      dates: ImportDateFormat.us,
      outflowsNegative: false,
    );
    expect(p.rows.first.amount, Money(8217, 'USD'));
  });

  test('each reason a row is skipped', () {
    final ImportMapping signed = ImportMapping(
      columns: {
        ImportRole.date: 0,
        ImportRole.description: 1,
        ImportRole.amount: 2,
        ImportRole.merchant: 3,
        ImportRole.tags: 4,
      },
      debitCredit: false,
      dateFormat: ImportDateFormat.iso,
      separator: DecimalSeparator.point,
    );
    final ImportParse p = convertRows(
      const [
        ['2026-02-30', 'Bad date', '-1.00'],
        ['2026-10-01', 'Blank', ''],
        ['2026-10-01', 'Words', 'ten'],
        ['2026-10-01', 'Zero', '0.00'],
        ['2026-10-01', '', '-1.00'],
        ['2026-10-01', '', '-2.00', 'Merchant only'],
        ['2026-10-01', 'Short'],
        ['2026-10-01', 'Tags', '-3.00', '', ' a ; ;b;a '],
      ],
      signed,
      currencyCode: 'USD',
      firstRow: 2,
    );
    expect(p.failures, [
      (row: 2, problem: RowProblem.badDate),
      (row: 3, problem: RowProblem.noAmount),
      (row: 4, problem: RowProblem.badAmount),
      (row: 5, problem: RowProblem.zeroAmount),
      (row: 6, problem: RowProblem.noDescription),
      (row: 8, problem: RowProblem.noAmount),
    ]);
    expect(p.rows.map((r) => r.name), ['Merchant only', 'Tags']);
    expect(p.rows.last.tags, ['a', 'b']);

    final ImportMapping split = ImportMapping(
      columns: {
        ImportRole.date: 0,
        ImportRole.description: 1,
        ImportRole.debit: 2,
        ImportRole.credit: 3,
      },
      debitCredit: true,
      dateFormat: ImportDateFormat.iso,
      separator: DecimalSeparator.point,
    );
    final ImportParse q = convertRows(
      const [
        ['2026-10-01', 'Both', '1.00', '2.00'],
        ['2026-10-01', 'Neither', '', ''],
        ['2026-10-01', 'Zeros', '0.00', '0.00'],
        ['2026-10-01', 'Unsigned out', '5.00', ''],
        ['2026-10-01', 'In with a zero out', '0.00', '7.00'],
      ],
      split,
      currencyCode: 'USD',
      firstRow: 1,
    );
    expect(q.failures, [
      (row: 1, problem: RowProblem.debitAndCredit),
      (row: 2, problem: RowProblem.noAmount),
      (row: 3, problem: RowProblem.zeroAmount),
    ]);
    expect(q.rows.map((r) => r.amount.minorUnits), [-500, 700]);
  });

  test('a yen amount has no fraction', () {
    final ImportParse p = convertRows(
      const [
        ['2026-10-01', 'Ramen', '-1,200'],
      ],
      ImportMapping(
        columns: {
          ImportRole.date: 0,
          ImportRole.description: 1,
          ImportRole.amount: 2,
        },
        debitCredit: false,
        dateFormat: ImportDateFormat.iso,
        separator: DecimalSeparator.point,
      ),
      currencyCode: 'JPY',
      firstRow: 1,
    );
    expect(p.rows.single.amount, Money(-1200, 'JPY'));
  });

  test('isComplete', () {
    ImportMapping m(Map<ImportRole, int> c, {bool split = false}) =>
        ImportMapping(
          columns: c,
          debitCredit: split,
          dateFormat: ImportDateFormat.iso,
          separator: DecimalSeparator.point,
        );
    expect(
      m({ImportRole.date: 0, ImportRole.description: 1, ImportRole.amount: 2})
          .isComplete,
      isTrue,
    );
    expect(m({ImportRole.date: 0, ImportRole.amount: 2}).isComplete, isFalse);
    expect(
      m({
        ImportRole.date: 0,
        ImportRole.description: 1,
        ImportRole.amount: 2,
      }, split: true).isComplete,
      isFalse,
    );
    expect(
      m({
        ImportRole.date: 0,
        ImportRole.description: 1,
        ImportRole.debit: 2,
        ImportRole.credit: 3,
      }, split: true).isComplete,
      isTrue,
    );
  });
}
