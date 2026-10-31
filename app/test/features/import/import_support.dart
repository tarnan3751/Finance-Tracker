// Helpers for the import's tests: a file picked from text, and a mapping of the plain
// `Date,Description,Amount` layout the inline files use.
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:finance_tracker/features/import/application/import_providers.dart';
import 'package:finance_tracker/features/import/domain/amount_parser.dart';
import 'package:finance_tracker/features/import/domain/date_formats.dart';
import 'package:finance_tracker/features/import/domain/import_mapping.dart';

/// [text] as a picked file named [name].
PickedCsv pickedCsv(String text, {String? name = 'export.csv'}) =>
    pickedBytes(Uint8List.fromList(utf8.encode(text)), name: name);

/// [bytes] as a picked file named [name].
PickedCsv pickedBytes(Uint8List bytes, {String? name = 'export.csv'}) =>
    PickedCsv(
      bytes: bytes,
      name: name,
      sha256: sha256.convert(bytes).toString(),
    );

/// Date, description, amount in columns 0, 1 and 2, ISO dates, decimal points; with
/// [extra] roles mapped too.
ImportMapping plainMapping([Map<ImportRole, int> extra = const {}]) =>
    ImportMapping(
      columns: {
        ImportRole.date: 0,
        ImportRole.description: 1,
        ImportRole.amount: 2,
        ...extra,
      },
      debitCredit: false,
      dateFormat: ImportDateFormat.iso,
      separator: DecimalSeparator.point,
    );
