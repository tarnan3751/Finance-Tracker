// Same seed, same bytes: twice in one run, against the committed goldens, and a different
// seed differs. To regenerate the goldens after a deliberate change:
// `dart run tool/update_goldens.dart` in this package.
import 'dart:io';

import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import '../tool/golden_set.dart';

void main() {
  final asOf = LocalDate(2026, 10, 24);

  test('the same seed renders byte-identical files twice', () {
    for (final id in PersonaId.values) {
      final a = renderOutputs(id, seed: 7, asOf: asOf, days: 90);
      final b = renderOutputs(id, seed: 7, asOf: asOf, days: 90);
      expect(a, b, reason: id.slug);
    }
  });

  test('a different seed gives a different household', () {
    for (final id in PersonaId.values) {
      final a = renderOutputs(id, seed: 1, asOf: asOf, days: 90);
      final b = renderOutputs(id, seed: 2, asOf: asOf, days: 90);
      expect(a['demo_seed.json'], isNot(b['demo_seed.json']), reason: id.slug);
    }
  });

  for (final id in PersonaId.values) {
    test('${id.slug} matches its committed goldens', () {
      final expected = goldenSet(id);
      final dir = Directory('test/goldens/${id.slug}');
      final committed = {
        for (final f in dir.listSync(recursive: true).whereType<File>())
          f.path.substring(dir.path.length + 1): f,
      };
      expect(
        committed.keys.toSet(),
        expected.keys.toSet(),
        reason: 'run dart run tool/update_goldens.dart',
      );
      for (final e in expected.entries) {
        expect(
          committed[e.key]!.readAsStringSync(),
          e.value,
          reason:
              '${id.slug}/${e.key} differs; run dart run tool/update_goldens.dart',
        );
      }
    });
  }
}
