// Checks that the generated Plaid taxonomy matches the committed CSV: the generator's
// output for the CSV must equal the committed file byte for byte, so a stale or hand-edited
// file fails the gate. Runs from the package root, as `dart test` does.
import 'dart:io';

import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import '../tool/gen_taxonomy.dart' as gen;

void main() {
  final csv = File(gen.csvPath).readAsStringSync();

  test('the generated file is current', () async {
    expect(
      await gen.formattedTaxonomy(csv),
      File(gen.outputPath).readAsStringSync(),
      reason: 'run `dart run tool/gen_taxonomy.dart` in packages/shared_models',
    );
  });

  test('the entries are the CSV rows', () {
    final rows = gen
        .parseCsv(csv)
        .skip(1)
        .where((row) => row.length >= 3 && row[1].isNotEmpty)
        .toList();
    expect(plaidCategories.length, rows.length);
    for (var i = 0; i < rows.length; i++) {
      expect(
        plaidCategories[i],
        PlaidCategory(
          primary: rows[i][0],
          detailed: rows[i][1],
          description: rows[i][2],
        ),
      );
    }
  });

  test('codes are consistent', () {
    expect(plaidPrimaryCategories, {
      for (final c in plaidCategories) c.primary,
    });
    expect(
      plaidPrimaryCategories,
      containsAll(['LOAN_DISBURSEMENTS', 'OTHER']),
    );
    expect(
      plaidCategories.map((c) => c.detailed).toSet().length,
      plaidCategories.length,
      reason: 'detailed codes are unique',
    );
    for (final category in plaidCategories) {
      expect(category.detailed, startsWith('${category.primary}_'));
    }
  });

  test('the CSV parser handles quotes, commas and CRLF', () {
    expect(gen.parseCsv('a,"b, ""c""",d\r\ne,,f\n'), [
      ['a', 'b, "c"', 'd'],
      ['e', '', 'f'],
    ]);
  });
}
