// Presets and the import history: a preset reads back against its header (repeated
// header texts by occurrence), the lists round-trip newest first and keep twenty, a
// preset replaces the one for its header, an undone batch replaces itself, a pending one
// round-trips and completes, and a damaged value is refused with its own exception.
import 'dart:convert';

import 'package:finance_tracker/features/import/domain/amount_parser.dart';
import 'package:finance_tracker/features/import/domain/date_formats.dart';
import 'package:finance_tracker/features/import/domain/import_mapping.dart';
import 'package:finance_tracker/features/import/domain/import_records.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _at = DateTime.utc(2026, 10, 31, 12, 0, 0, 123);

ImportBatch _batch(String id, {DateTime? undoneAt}) => ImportBatch(
  id: id,
  importedAt: _at,
  fileName: id == 'b0' ? null : 'export-$id.csv',
  sha256: 'ab' * 32,
  accountId: 'acct',
  count: 2,
  transactionIds: ['$id-1', '$id-2'],
  undoneAt: undoneAt,
);

void main() {
  const List<String> header = [
    'Date',
    ' Amount ',
    'Notes',
    'Amount',
    'Description',
  ];

  test('the signature is of the trimmed header', () {
    expect(headerSignature(header), hasLength(64));
    expect(
      headerSignature(header),
      headerSignature(['Date', 'Amount', 'Notes', 'Amount', 'Description']),
    );
    expect(
      headerSignature(header),
      isNot(headerSignature(['Date', 'Amount', 'Notes', 'Description'])),
    );
  });

  test('a preset reads back against its header', () {
    final ImportMapping mapping = ImportMapping(
      columns: {
        ImportRole.date: 0,
        ImportRole.debit: 1,
        ImportRole.credit: 3,
        ImportRole.description: 4,
      },
      debitCredit: true,
      dateFormat: ImportDateFormat.day,
      separator: DecimalSeparator.comma,
      outflowsNegative: false,
    );
    final ImportPreset preset = ImportPreset.of(
      header,
      mapping,
      delimiter: ';',
      headerRow: 3,
      accountId: 'acct',
      savedAt: _at,
    );
    expect(preset.columns[ImportRole.credit], (name: 'Amount', occurrence: 1));
    final ImportPreset back = decodePresets(encodePresets(const [], preset))
        .single;
    expect(back.signature, preset.signature);
    expect(back.delimiter, ';');
    expect(back.headerRow, 3);
    expect(back.accountId, 'acct');
    expect(back.savedAt, _at);
    final ImportMapping read = back.mappingFor(header);
    expect(read.columns, mapping.columns);
    expect(read.debitCredit, isTrue);
    expect(read.dateFormat, ImportDateFormat.day);
    expect(read.separator, DecimalSeparator.comma);
    expect(read.outflowsNegative, isFalse);
  });

  test('presets: newest first, one per header, twenty kept', () {
    ImportPreset p(String sig) => ImportPreset(
      signature: sig,
      columns: const {},
      debitCredit: false,
      dateFormat: ImportDateFormat.iso,
      separator: DecimalSeparator.point,
      outflowsNegative: true,
      delimiter: ',',
      headerRow: 0,
      accountId: null,
      savedAt: _at,
    );
    List<ImportPreset> list = const [];
    for (int i = 0; i < 25; i++) {
      list = decodePresets(encodePresets(list, p('s$i')));
    }
    expect(list, hasLength(importRecordsKept));
    expect(list.first.signature, 's24');
    list = decodePresets(encodePresets(list, p('s10')));
    expect(list.map((e) => e.signature).take(2), ['s10', 's24']);
    expect(list, hasLength(importRecordsKept));
    expect(list.first.accountId, isNull);
  });

  test('history: newest first, an undo in place, twenty kept', () {
    List<ImportBatch> history = const [];
    for (int i = 0; i < 22; i++) {
      history = decodeHistory(encodeHistory(history, _batch('b$i')));
    }
    expect(history, hasLength(importRecordsKept));
    expect(history.first.id, 'b21');
    expect(history.first.fileName, 'export-b21.csv');
    expect(history.first.transactionIds, ['b21-1', 'b21-2']);
    expect(history.first.undoneAt, isNull);
    final DateTime later = _at.add(const Duration(hours: 1));
    history = decodeHistory(encodeHistory(history, history[3].undone(later)));
    expect(history, hasLength(importRecordsKept));
    expect(history[3].id, 'b18');
    expect(history[3].undoneAt, later);
    expect(
      decodeHistory(encodeHistory(const [], _batch('b0'))).single.fileName,
      isNull,
    );
    final ImportBatch pending = ImportBatch(
      id: 'p',
      importedAt: _at,
      fileName: null,
      sha256: 'ab' * 32,
      accountId: 'acct',
      count: 1,
      transactionIds: const ['p-1'],
      pending: true,
    );
    final ImportBatch read = decodeHistory(encodeHistoryList([pending])).single;
    expect(read.pending, isTrue);
    expect(read.completed().pending, isFalse);
    expect(read.completed().transactionIds, ['p-1']);
    expect(read.undone(later).pending, isTrue);
    expect(history.first.pending, isFalse);
  });

  test('nothing stored is empty; a damaged value is refused', () {
    expect(decodeHistory(null), isEmpty);
    expect(decodePresets(''), isEmpty);
    for (final String bad in [
      'not json',
      '{}',
      '[1]',
      jsonEncode([
        {'id': 'x'},
      ]),
      jsonEncode([
        {..._batch('b1').toJson(), 'imported_at': 'yesterday'},
      ]),
      jsonEncode([
        {
          ..._batch('b1').toJson(),
          'transaction_ids': [1],
        },
      ]),
    ]) {
      expect(
        () => decodeHistory(bad),
        throwsA(isA<ImportRecordsFormatException>()),
        reason: bad,
      );
    }
    expect(
      () => decodePresets(
        jsonEncode([
          {
            'signature': 's',
            'columns': {
              'nope': {'name': 'a', 'occurrence': 0},
            },
            'debit_credit': false,
            'date_format': 'iso',
            'separator': 'point',
            'outflows_negative': true,
            'delimiter': ',',
            'header_row': 0,
            'account_id': null,
            'saved_at': '2026-10-31T12:00:00.000Z',
          },
        ]),
      ),
      throwsA(isA<ImportRecordsFormatException>()),
    );
  });
}
