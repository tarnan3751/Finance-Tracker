// The monthly report's PDF: the fixture's bytes hash to the pinned golden (on a
// mismatch the test prints the new hash and, against the last matching copy cached
// under build/, the first byte that differs); two builds give the same bytes; the
// document has no metadata and a zeroed id; a report past the package's default of 20
// pages is drawn whole; and fixDocumentId refuses a PDF without exactly one id.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/export/domain/monthly_report.dart';
import 'package:finance_tracker/features/export/domain/monthly_report_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/monthly_report_fixture.dart';

// The last PDF that matched the golden, kept to locate a drift; and the one that did not.
final File _cached = File('build/export/monthly_report_fixture.pdf');
final File _actual = File('build/export/monthly_report_fixture.actual.pdf');

ReportFonts _fonts() => (
  regular: ByteData.sublistView(
    File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync(),
  ),
  bold: ByteData.sublistView(
    File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync(),
  ),
);

Future<Uint8List> _build() => buildMonthlyReportPdf(
  monthlyReportFixture(),
  monthlyReportFixtureStrings(),
  fonts: _fonts(),
  locale: monthlyReportFixtureLocale,
);

void main() {
  test('the fixture\'s PDF matches the pinned hash', () async {
    final Uint8List bytes = await _build();
    final String hash = sha256.convert(bytes).toString();
    _cached.parent.createSync(recursive: true);
    if (hash == monthlyReportFixtureSha256) {
      _cached.writeAsBytesSync(bytes);
      return;
    }
    _actual.writeAsBytesSync(bytes);
    final StringBuffer why = StringBuffer(
      'The monthly report fixture hashes to $hash, not the pinned '
      '$monthlyReportFixtureSha256 (${bytes.length} bytes, written to '
      '${_actual.path}).',
    );
    if (_cached.existsSync()) {
      final Uint8List before = _cached.readAsBytesSync();
      int at = 0;
      while (at < before.length &&
          at < bytes.length &&
          before[at] == bytes[at]) {
        at++;
      }
      final int from = at < 40 ? 0 : at - 40;
      String around(Uint8List b) => latin1
          .decode(b.sublist(from, (at + 40).clamp(0, b.length)))
          .replaceAll(RegExp(r'[^\x20-\x7e]'), '.');
      why
        ..write(
          ' Against the last matching copy (${before.length} bytes, '
          '${_cached.path}) the first differing byte is at offset $at.',
        )
        ..write('\n  before: ${around(before)}')
        ..write('\n  now:    ${around(bytes)}');
    }
    why.write(
      '\nIf the change is intended, set monthlyReportFixtureSha256 in '
      'test/helpers/monthly_report_fixture.dart to the new hash.',
    );
    fail(why.toString());
  });

  test('two builds give the same bytes', () async {
    expect(await _build(), await _build());
  });

  test('the document has no metadata and a zeroed id', () async {
    final String text = latin1.decode(await _build());

    expect(text, startsWith('%PDF-1.5'));
    expect(text, isNot(contains('/Info')));
    expect(text, isNot(contains('/CreationDate')));
    expect(text, isNot(contains('/ModDate')));
    expect(text, contains('/ID[<${'0' * 64}><${'0' * 64}>]'));
    expect(text, contains('/FontName/Roboto-Regular'));
    expect(text, contains('/FontName/Roboto-Bold'));
    // Uncompressed: no stream is deflated.
    expect(text, isNot(contains('/FlateDecode')));
  });

  test('a report past 20 pages is drawn whole', () async {
    final MonthlyReportData fixture = monthlyReportFixture();
    final Uint8List bytes = await buildMonthlyReportPdf(
      MonthlyReportData(
        report: fixture.report,
        categoryNames: fixture.categoryNames,
        anomalies: fixture.anomalies,
        bills: [
          for (int i = 0; i < 800; i++)
            ReportBill(
              name: 'Bill $i',
              due: LocalDate(2026, 10, 1 + i % 31),
              amount: Money(-1000 - i, 'USD'),
              state: BillState.paid,
            ),
        ],
        budgets: fixture.budgets,
      ),
      monthlyReportFixtureStrings(),
      fonts: _fonts(),
      locale: monthlyReportFixtureLocale,
    );

    final int pages = RegExp(r'/Type/Page[^s]')
        .allMatches(latin1.decode(bytes))
        .length;
    expect(pages, greaterThan(20));
    expect(pages, lessThanOrEqualTo(reportMaxPages));
  });

  test('fixDocumentId needs exactly one id', () {
    expect(
      () => fixDocumentId(Uint8List.fromList(latin1.encode('%PDF-1.5 no id'))),
      throwsStateError,
    );
    final String id = '/ID[<${'a' * 64}><${'b' * 64}>]';
    expect(
      () => fixDocumentId(Uint8List.fromList(latin1.encode('$id $id'))),
      throwsStateError,
    );
    expect(
      latin1.decode(
        fixDocumentId(Uint8List.fromList(latin1.encode('x $id y'))),
      ),
      'x /ID[<${'0' * 64}><${'0' * 64}>] y',
    );
  });
}
