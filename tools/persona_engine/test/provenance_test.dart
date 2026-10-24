// The synthesis-policy boundary (PLAN.md §7.1): everything the engine emits is demo, and
// the engine's code has no hidden source of variation.
import 'dart:convert';
import 'dart:io';

import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support/invariants.dart';

void main() {
  final asOf = LocalDate(2026, 10, 24);

  for (final id in PersonaId.values) {
    test('${id.slug}: every record is demo, in the model and in the JSON', () {
      final seed = generateDemoSeed(id, 1, asOf, days: 200);
      expect(provenanceViolations(seed.household), isEmpty);
      final json = jsonDecode(writeJson(seed.toJson())) as Map<String, Object?>;
      for (final key in ['transactions', 'investment_transactions']) {
        for (final t
            in (json[key]! as List<Object?>).cast<Map<String, Object?>>()) {
          expect(t['source'], 'demo');
        }
      }
    });
  }

  test('the library reads no clock, uses no dart:math and no double', () {
    final offenders = <String>[];
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        if (RegExp(r'dart:math|\bdouble\b|DateTime\.now|\bRandom\(')
            .hasMatch(code)) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
