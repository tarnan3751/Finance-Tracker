// The detector measured against the persona engine's ground truth (`PLAN.md` §12, "The
// detector"; docs/reference/recurring.md, **The detector**): every persona's full demo
// seed (seed 1, as of 2026-10-24) through `detectStreams`, compared with the seed's
// `recurring` expectations. An expectation is matched, one to one, by a detected stream on
// its account with its merchant key (the expectation's merchant name, else its raw name,
// through the enrichment fallback, normalized) and its cadence; among several, the one
// whose median is inside the expectation's range, then the lowest id. Precision is the
// matched detected streams over all detected, recall the matched expectations over all;
// both must be at least 0.9 per persona. The figures, the misses and the extras are
// printed, with the cadence agreement (of the expectations a stream shares account and
// key with), the median next-date error in days and, as information, how often the
// subscription classifier agrees with the expectations' flag.
@Tags(['detector_harness'])
library;

import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:finance_tracker/features/recurring/domain/subscription_classifier.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';

final LocalDate asOf = LocalDate(2026, 10, 24);

String expectationKey(RecurringExpectation e) => normalizeMerchantText(
  e.merchantName ?? lookupMerchant(e.name)?.name ?? cleanMerchantName(e.name),
);

bool inRange(RecurringStream s, RecurringExpectation e) {
  final Money m = s.averageAmount.abs();
  return m >= e.minAmount && m <= e.maxAmount;
}

void main() {
  final CategoryLookup lookup = categoryLookup(systemCategories);

  for (final PersonaId persona in PersonaId.values) {
    test('${persona.slug}: precision and recall at least 0.9', () {
      final GeneratedHousehold household = generateDemoSeed(
        persona,
        1,
        asOf,
      ).household;
      final List<RecurringStream> detected = detectStreams(
        household.transactions,
        today: asOf,
        lookup: lookup,
        merchantKey: recurringMerchantKey,
      );
      final List<RecurringExpectation> expected = household.recurring;

      final Map<String, Transaction> byId = {
        for (final Transaction t in household.transactions) t.id: t,
      };
      final Set<String> used = {};
      int classifierAgrees = 0;
      final List<String> misses = [];
      final List<int> dateErrors = [];
      int sharingKey = 0;
      int cadenceAgrees = 0;
      for (final RecurringExpectation e in expected) {
        final String key = expectationKey(e);
        final List<RecurringStream> sameKey = [
          for (final RecurringStream s in detected)
            if (s.accountId == e.accountId &&
                normalizeMerchantText(s.merchantName) == key)
              s,
        ];
        if (sameKey.isNotEmpty) sharingKey++;
        final List<RecurringStream> candidates =
            [
              for (final RecurringStream s in sameKey)
                if (s.cadence == e.cadence && !used.contains(s.id)) s,
            ]..sort((a, b) {
              final int byRange =
                  (inRange(b, e) ? 1 : 0) - (inRange(a, e) ? 1 : 0);
              return byRange != 0 ? byRange : a.id.compareTo(b.id);
            });
        if (candidates.isEmpty) {
          misses.add(
            '${e.key} (${e.cadence.name}; detected '
            '${sameKey.map((s) => s.cadence.name).toList()})',
          );
          continue;
        }
        cadenceAgrees++;
        final RecurringStream match = candidates.first;
        used.add(match.id);
        final List<Transaction> members = [
          for (final String id in match.transactionIds) byId[id]!,
        ];
        final bool subscription = isSubscription(
          match,
          effectiveCategory: streamCategory(members, lookup),
          band: StreamBand.of(members),
        );
        if (subscription == e.isSubscription) classifierAgrees++;
        final LocalDate next = e.schedule
            .occurrences(asOf.addDays(1), asOf.addDays(400))
            .first;
        dateErrors.add(next.daysUntil(match.nextExpected!).abs());
      }
      final List<String> extras = [
        for (final RecurringStream s in detected)
          if (!used.contains(s.id)) '${s.merchantName} (${s.cadence.name})',
      ];
      dateErrors.sort();
      final int matched = used.length;
      final String figures =
          '${persona.slug}: precision $matched/${detected.length}, '
          'recall $matched/${expected.length}, '
          'cadence agreement $cadenceAgrees/$sharingKey, '
          'median next-date error '
          '${dateErrors.isEmpty ? '-' : dateErrors[(dateErrors.length - 1) ~/ 2]} days, '
          'classifier agreement $classifierAgrees/$matched'
          '\n  missed: $misses\n  extra: $extras';
      // ignore: avoid_print
      print(figures);

      expect(
        matched * 10,
        greaterThanOrEqualTo(detected.length * 9),
        reason: figures,
      );
      expect(
        matched * 10,
        greaterThanOrEqualTo(expected.length * 9),
        reason: figures,
      );
    });
  }
}
