// The anomaly flags measured against the persona engine's ground truth (`PLAN.md` §12,
// "Reports and insights", "6c plan rulings"; docs/reference/reports.md, **Anomalies**):
// each persona's full demo seed (seeds 1 and 2, as of 2026-10-24), flagged over its whole window
// with the demo streams' and the detected streams' members as the scheduled payments,
// compared with the seed's planted `anomalies` by transaction id. No rules are given:
// a merchant a rule names is the user's choice to skip, not the rule's judgment, and one
// of the student's demo rules happens to name the bookstore an anomaly is planted at.
//
// The ground truth judged is the evaluable anomalies: those dated at least six months
// after their account's first row, since the rule cannot call a merchant new on a
// shorter history, by design. Recall over them must be at least 0.8. Precision (the
// flags that are planted anomalies, over all flags) must be at least 0.08: a regression
// floor, not a target (anomalies are a hint list, not a verdict; tuning precision is
// later scope). The test prints both, the recall over every planted anomaly, the misses
// and the extra flags.
@Tags(['anomaly_harness'])
library;

import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:finance_tracker/features/reports/domain/anomalies.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart' hide AnomalyKind;
import 'package:shared_models/shared_models.dart';

final LocalDate asOf = LocalDate(2026, 10, 24);

void main() {
  final CategoryLookup lookup = categoryLookup(systemCategories);

  for (final int seedNumber in [1, 2]) {
    for (final PersonaId persona in PersonaId.values) {
      test('${persona.slug}, seed $seedNumber: recall at least 0.8, precision at '
          'least 0.08', () {
        final DemoSeed seed = generateDemoSeed(persona, seedNumber, asOf);
        final GeneratedHousehold household = seed.household;
        final List<Transaction> ledger = household.transactions;

        final Set<String> scheduled = {
          for (final RecurringStream s in demoRecurringStreams(seed))
            ...s.transactionIds,
          for (final RecurringStream s in detectStreams(
            ledger,
            today: asOf,
            lookup: lookup,
            merchantKey: recurringMerchantKey,
          ))
            ...s.transactionIds,
        };
        final LocalDate first = ledger
            .map((t) => t.date)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        final List<AnomalyFlag> flags = detectAnomalies(
          ledger,
          window: LocalDateRange(first, asOf.addDays(1)),
          lookup: lookup,
          scheduledIds: scheduled,
          rules: const [],
        );

        final Map<String, Transaction> byId = {
          for (final Transaction t in ledger) t.id: t,
        };
        final Map<String, LocalDate> firstByAccount = {};
        for (final Transaction t in ledger) {
          final LocalDate? f = firstByAccount[t.accountId];
          if (f == null || t.date.isBefore(f)) {
            firstByAccount[t.accountId] = t.date;
          }
        }
        final Set<String> planted = {
          for (final Anomaly a in household.anomalies) a.transactionId,
        };
        final Set<String> evaluable = {
          for (final String id in planted)
            if (!byId[id]!.date.isBefore(
              firstByAccount[byId[id]!.accountId]!.addMonths(6),
            ))
              id,
        };
        final Set<String> flagged = {for (final f in flags) f.transactionId};

        String describe(String id) {
          final Transaction t = byId[id]!;
          return '${t.date} ${recurringMerchantKey(t)} ${t.amount}';
        }

        final int hits = evaluable.where(flagged.contains).length;
        final int correct = flagged.where(planted.contains).length;
        final String figures =
            '${persona.slug} (seed $seedNumber): recall $hits/${evaluable.length} evaluable '
            '(${planted.where(flagged.contains).length}/${planted.length} planted), '
            'precision $correct/${flagged.length}'
            '\n  missed: ${[for (final id in planted)
              if (!flagged.contains(id)) describe(id)]}'
            '\n  extra: ${[for (final f in flags)
              if (!planted.contains(f.transactionId)) '${describe(f.transactionId)} ${f.kind.name}']}';
        // ignore: avoid_print
        print(figures);

        expect(
          hits * 10,
          greaterThanOrEqualTo(evaluable.length * 8),
          reason: figures,
        );
        expect(
          correct * 100,
          greaterThanOrEqualTo(flagged.length * 8),
          reason: figures,
        );
      });
    }
  }
}
