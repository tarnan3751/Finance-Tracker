// Every recurring expectation recurs: once per scheduled date, within the weekend rule's
// tolerance, with an amount in range, and nothing else of that name on that account.
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  final asOf = LocalDate(2026, 10, 24);

  for (final id in PersonaId.values) {
    group(id.slug, () {
      final h = generateHousehold(personaFor(id), seed: 1, asOf: asOf);

      test('has subscriptions, and its regular income on a schedule', () {
        expect(h.recurring.where((r) => r.isSubscription), isNotEmpty);
        final regular = h.persona.incomes.where((s) => s.skipPermille == 0);
        expect(h.recurring.where((r) => r.isInflow), hasLength(regular.length));
      });

      for (final r in h.recurring) {
        test('${r.key} recurs on its schedule', () {
          final hits = h.transactions
              .where((t) => t.accountId == r.accountId && t.name == r.name)
              .toList();
          final tolerance = r.schedule.toleranceDays;
          final first = h.window.start.addDays(tolerance);
          final last = asOf.addDays(-tolerance);
          var nominal = 0;
          for (var d = first; !d.isAfter(last); d = d.addDays(1)) {
            if (!r.schedule.isNominal(d)) continue;
            nominal++;
            final near = hits.where(
              (t) => t.authorizedDate!.daysUntil(d).abs() <= tolerance,
            );
            expect(near, hasLength(1), reason: '${r.key} near $d');
          }
          expect(nominal, greaterThan(0));
          final inside = hits.where(
            (t) =>
                !t.authorizedDate!.isBefore(first) &&
                !t.authorizedDate!.isAfter(last),
          );
          expect(
            inside.length,
            nominal,
            reason: '${r.key}: no extra occurrences',
          );
          for (final t in hits) {
            expect(t.amount.isPositive, r.isInflow);
            expect(
              t.amount.abs() >= r.minAmount && t.amount.abs() <= r.maxAmount,
              isTrue,
              reason: '${r.key} ${t.amount}',
            );
            expect(t.merchantName, r.merchantName);
          }
        });
      }

      test('monthly subscriptions appear once in every full month', () {
        for (final r in h.recurring.where(
          (r) => r.isSubscription && r.cadence == RecurringCadence.monthly,
        )) {
          var month = h.window.start.firstOfMonth.addMonths(1);
          while (month.lastOfMonth.isBefore(asOf)) {
            final count = h.transactions.where(
              (t) =>
                  t.accountId == r.accountId &&
                  t.name == r.name &&
                  t.authorizedDate!.year == month.year &&
                  t.authorizedDate!.month == month.month,
            );
            expect(count, hasLength(1), reason: '${r.key} $month');
            month = month.addMonths(1);
          }
        }
      });
    });
  }
}
