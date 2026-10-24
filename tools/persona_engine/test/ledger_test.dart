// The ledger: the only way a balance changes.
import 'package:persona_engine/persona_engine.dart';
import 'package:persona_engine/src/generate/ledger.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support/fixture_persona.dart';

final Map<String, Money> _openings = {
  'checking': usd(100000),
  'savings': usd(500000),
  'card': usd(-30000),
};

void main() {
  final asOf = LocalDate(2026, 10, 24);
  const out = Payee('OUT', null, 'TRANSFER_OUT_SAVINGS');
  const into = Payee('IN', null, 'TRANSFER_IN_SAVINGS');

  test('a transfer writes one value, negated, on one date', () {
    final ledger = Ledger(fixturePersona, asOf, _openings);
    ledger.transfer(
      from: 'checking',
      to: 'savings',
      amount: usd(1234),
      date: asOf,
      outPayee: out,
      inPayee: into,
    );
    final [a, b] = ledger.entries;
    expect(a.amount, -b.amount);
    expect(a.transacted, b.transacted);
    expect(a.pairId, b.pairId);
    expect(a.leg, TransferLeg.out);
    expect(b.leg, TransferLeg.into);
    expect(ledger.balance('checking'), usd(100000 - 1234));
    expect(ledger.balance('savings'), usd(500000 + 1234));
  });

  test(
    'a non-positive transfer, a zero entry and a future date are refused',
    () {
      final ledger = Ledger(fixturePersona, asOf, _openings);
      expect(
        () => ledger.transfer(
          from: 'checking',
          to: 'savings',
          amount: usd(0),
          date: asOf,
          outPayee: out,
          inPayee: into,
        ),
        throwsArgumentError,
      );
      expect(
        () => ledger.postPayee('checking', usd(0), asOf, out),
        throwsArgumentError,
      );
      expect(
        () => ledger.postPayee('checking', usd(-1), asOf.addDays(1), out),
        throwsArgumentError,
      );
    },
  );

  test('a category outside the taxonomy is refused', () {
    final ledger = Ledger(fixturePersona, asOf, _openings);
    expect(
      () => ledger.postPayee(
        'checking',
        usd(-1),
        asOf,
        const Payee('X', null, 'FOOD'),
      ),
      throwsArgumentError,
    );
    expect(primaryCategoryOf('FOOD_AND_DRINK_COFFEE'), 'FOOD_AND_DRINK');
  });

  test('a posting date past the as-of date is clamped to it', () {
    final ledger = Ledger(fixturePersona, asOf, _openings);
    final e = ledger.post(
      account: 'card',
      amount: usd(-500),
      date: asOf.addDays(-1),
      posted: asOf.addDays(1),
      raw: 'CAFE',
      merchant: 'Cafe',
      detailed: 'FOOD_AND_DRINK_COFFEE',
    );
    expect(e.posted, asOf);
    expect(e.transacted, asOf.addDays(-1));
  });

  test('an account without an opening has no ledger balance', () {
    expect(
      () => Ledger(fixturePersona, asOf, _openings).balance('retirement'),
      throwsArgumentError,
    );
  });
}
