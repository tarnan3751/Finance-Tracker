/// The demo flavor's CSV picker (`docs/reference/import.md`, **Picking**; `PLAN.md` §12,
/// "9a plan rulings"): whatever the user picks, it is a sample export of a fictional bank,
/// built from the clock's today when picked, so the same day gives the same file. Its
/// rows land as `source: import`, the source they demonstrate, under the demo banner; the
/// demo flavor is where synthesis is allowed (`PLAN.md` §7.1).
///
/// The file has a title line and a blank line before its table (`Date`, `Description`,
/// `Amount`, `Balance`; `MM/dd/yyyy` dates over the last four weeks, so a day past the
/// 12th always settles the order), every merchant fictional.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:finance_tracker/core/platform/fake_backup_picker.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:shared_models/shared_models.dart';

/// The sample's file name.
const String demoCsvFileName = 'lakeshore-mutual-checking.csv';

/// The sample export's rows: days before today, description, amount in cents.
const List<(int, String, int)> _rows = [
  (27, 'LAKESIDE GROCERY #212', -6418),
  (26, 'BEANERY COFFEE CO', -525),
  (24, 'PAYROLL HARBORLIGHT DESIGN', 245000),
  (22, 'CITY WATER UTILITY', -4812),
  (20, 'BEANERY COFFEE CO', -525),
  (19, 'MAPLE STREET PHARMACY', -1899),
  (17, 'NORTHSHORE FITNESS CLUB', -3900),
  (15, 'LAKESIDE GROCERY #212', -8237),
  (13, 'ORBIT STREAMING', -1299),
  (12, 'TRANSFER TO SAVINGS', -30000),
  (10, 'PAYROLL HARBORLIGHT DESIGN', 245000),
  (9, 'PINECONE BOOKS', -2450),
  (7, 'BEANERY COFFEE CO', -525),
  (5, 'RIVERBEND FUEL 0042', -4176),
  (3, 'LAKESIDE GROCERY #212', -5590),
  (1, 'BEANERY COFFEE CO', -525),
];

/// The sample export for [today], as UTF-8 bytes.
Uint8List demoCsv(LocalDate today) {
  final StringBuffer out = StringBuffer()
    ..write('Lakeshore Mutual Bank,Everyday Checking,Transaction export\r\n')
    ..write('\r\n')
    ..write('Date,Description,Amount,Balance\r\n');
  int balance = 120000;
  for (final (int daysAgo, String name, int cents) in _rows) {
    balance += cents;
    final LocalDate d = today.addDays(-daysAgo);
    final String date =
        '${_two(d.month)}/${_two(d.day)}/${d.year.toString().padLeft(4, '0')}';
    out.write(
      '$date,$name,${Money(cents, 'USD').toDecimalString()},'
      '${Money(balance, 'USD').toDecimalString()}\r\n',
    );
  }
  return Uint8List.fromList(utf8.encode(out.toString()));
}

String _two(int n) => n.toString().padLeft(2, '0');

/// The picker answering [demoCsv] for the clock's today.
final class DemoCsvPicker implements BackupPicker {
  /// The picker over [clock].
  const DemoCsvPicker(this._clock);

  final Clock _clock;

  @override
  Future<PickedFile?> pick() => FakeBackupPicker(
    file: demoCsv(_clock.today()),
    name: demoCsvFileName,
  ).pick();
}
