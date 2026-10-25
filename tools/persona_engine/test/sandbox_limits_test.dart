// Plaid's limits on every persona: ten accounts and the request budget per custom user,
// the newest whole days carried, a partition of the history between carried and left
// out, and dates Plaid accepts.
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
