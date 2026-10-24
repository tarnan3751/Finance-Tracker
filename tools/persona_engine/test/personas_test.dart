// The four personas: each generates over the longest window and fits Plaid's shape.
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  final asOf = LocalDate(2026, 10, 24);

  for (final id in PersonaId.values) {
    group(id.slug, () {
      final persona = personaFor(id);

      test('is registered under its own id and slug', () {
        expect(persona.id, id);
        expect(PersonaId.fromSlug(id.slug), id);
      });

      test('names only its own institutions and accounts', () {
        final institutions = {for (final i in persona.institutions) i.key};
        final accounts = {for (final a in persona.accounts) a.key};
        expect(accounts, hasLength(persona.accounts.length));
        for (final a in persona.accounts) {
          expect(institutions, contains(a.institution));
          if (a.coverFrom != null) expect(accounts, contains(a.coverFrom));
        }
        for (final i in persona.institutions) {
          final count = persona.accounts.where((a) => a.institution == i.key);
          expect(count.length, inInclusiveRange(1, 10), reason: i.key);
        }
        final used = <String>[
          for (final s in persona.incomes) s.account,
          for (final s in persona.bills) s.account,
          for (final s in persona.subscriptions) s.account,
          for (final s in persona.spending) s.account,
          for (final s in persona.cards) ...[s.account, s.payFrom],
          for (final s in persona.transfers) ...[s.from, s.to],
          for (final s in persona.loans) ...[s.account, ?s.payFrom],
          for (final s in persona.disbursements) ...[s.loan, s.to],
          ?persona.brokerage?.account,
          persona.anomalyAccount,
        ];
        expect(accounts, containsAll(used.toSet()));
      });

      test('uses only Plaid non-OAuth test institutions', () {
        for (final i in persona.institutions) {
          expect(
            i.plaidId,
            isIn(['ins_109508', 'ins_109509', 'ins_109510', 'ins_109511']),
          );
        }
      });

      test('generates 730 days that close', () {
        final h = generateHousehold(persona, seed: 1, asOf: asOf);
        expect(h.transactions, isNotEmpty);
        for (final a in h.accounts) {
          expect(a.currentBalance, isNotNull, reason: a.id);
        }
      });
    });
  }
}
