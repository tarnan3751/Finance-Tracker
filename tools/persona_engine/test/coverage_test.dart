// Categories and merchants: every primary category is used by some persona, every code
// is Plaid's, and the personas look like households.
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support/invariants.dart';

void main() {
  final asOf = LocalDate(2026, 10, 24);
  final households = {
    for (final id in PersonaId.values)
      id: generateHousehold(personaFor(id), seed: 1, asOf: asOf),
  };
  final detailedToPrimary = {
    for (final c in plaidCategories) c.detailed: c.primary,
  };

  test('every primary category is used by at least one persona', () {
    final used = {
      for (final h in households.values)
        for (final t in h.transactions) t.plaidPrimaryCategory!,
    };
    expect(used, plaidPrimaryCategories);
  });

  test(
    'every transaction carries a Plaid v2 detailed code under its primary',
    () {
      for (final h in households.values) {
        for (final t in h.transactions) {
          expect(
            detailedToPrimary[t.plaidDetailedCategory],
            t.plaidPrimaryCategory,
          );
        }
      }
    },
  );

  test('every merchant in every pool is a Plaid v2 category', () {
    for (final id in PersonaId.values) {
      final p = personaFor(id);
      for (final m in [
        for (final s in p.spending) ...s.merchants,
        ...p.anomalyMerchants,
      ]) {
        expect(detailedToPrimary.keys, contains(m.detailed), reason: m.name);
        expect(m.minMinor, lessThanOrEqualTo(m.maxMinor));
        expect(m.raw, isNotEmpty);
      }
    }
  });

  test('raw names are present and merchants recognizable', () {
    for (final h in households.values) {
      final merchants = {for (final t in h.transactions) ?t.merchantName};
      expect(merchants.length, greaterThan(15), reason: h.persona.id.slug);
      for (final t in h.transactions) {
        expect(t.name, isNotEmpty);
      }
    }
  });

  test(
    'two or three anomalies a year; a new merchant appears exactly once',
    () {
      for (final h in households.values) {
        expect(
          h.anomalies,
          hasLength(inInclusiveRange(4, 6)),
          reason: h.persona.id.slug,
        );
        final ids = {for (final t in h.transactions) t.id};
        for (final a in h.anomalies) {
          expect(ids, contains(a.transactionId));
        }
        expect(anomalyViolations(h), isEmpty, reason: h.persona.id.slug);
      }
    },
  );

  test('both kinds of anomaly are planted', () {
    expect({
      for (final h in households.values)
        for (final a in h.anomalies) a.kind,
    }, AnomalyKind.values.toSet());
  });

  test('weekends are heavier and December is the holiday spike', () {
    final h = households[PersonaId.family]!;
    int spend(bool Function(Transaction t) where) => h.transactions
        .where(
          (t) =>
              t.plaidDetailedCategory ==
              'GENERAL_MERCHANDISE_ONLINE_MARKETPLACES',
        )
        .where(where)
        .length;
    final december = spend((t) => t.authorizedDate!.month == 12);
    final february = spend((t) => t.authorizedDate!.month == 2);
    expect(december, greaterThan(february));
    final restaurants = h.transactions.where(
      (t) => t.plaidDetailedCategory == 'FOOD_AND_DRINK_RESTAURANT',
    );
    final saturdays = restaurants.where(
      (t) => t.authorizedDate!.weekday == DateTime.saturday,
    );
    final tuesdays = restaurants.where(
      (t) => t.authorizedDate!.weekday == DateTime.tuesday,
    );
    expect(saturdays.length, greaterThan(tuesdays.length));
  });
}
