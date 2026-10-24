// Balances close, transfers pair, loans follow their amortization and positions add up.
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support/invariants.dart';

void main() {
  final asOf = LocalDate(2026, 10, 24);

  for (final id in PersonaId.values) {
    group(id.slug, () {
      final persona = personaFor(id);
      final h = generateHousehold(persona, seed: 1, asOf: asOf);

      test('every account closes', () => expect(closureViolations(h), isEmpty));

      test('every transfer pairs exactly', () {
        expect(h.transfers, isNotEmpty);
        expect(transferViolations(h), isEmpty);
      });

      test('depository accounts never end a day below zero', () {
        expect(depositoryFloorViolations(h), isEmpty);
      });

      test('loans follow their amortization, month by month', () {
        expect(
          h.liabilities.whereType<LoanLiability>(),
          hasLength(persona.loans.length),
        );
        expect(loanViolations(h), isEmpty);
      });

      test('positions are their opening position plus their purchases', () {
        expect(positionViolations(h), isEmpty);
      });
    });
  }
}
