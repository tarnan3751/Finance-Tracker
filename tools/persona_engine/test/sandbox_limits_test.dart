// Plaid's limits on every persona: ten accounts, about 250 transactions and 55 KB per
// custom user, ten per injection call, no student-loan injection, a partition of the
// history between the two, and dates Plaid accepts.
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support/invariants.dart';

void main() {
  final asOf = LocalDate(2026, 10, 24);

  for (final id in PersonaId.values) {
    test('${id.slug} fits Sandbox', () {
      final h = generateHousehold(personaFor(id), seed: 1, asOf: asOf);
      expect(sandboxViolations(h), isEmpty);
      expect(dateViolations(h), isEmpty);
    });
  }
}
