// Properties of the report math over seeded random ledgers: the result does not depend
// on the rows' order; the totals by kind add up to the sum of what is counted; every
// category's total is its own rows plus its children's totals; the movers are sorted and
// at most ten.
import 'dart:math';

import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/reports/domain/report_period.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

final CategoryLookup lookup = categoryLookup(systemCategories);
final List<String> codes = [
  for (final Category c in systemCategories) c.plaidCategory!,
];
final LocalDate today = LocalDate(2026, 10, 17);

List<Transaction> ledger(Random rng) => [
  for (int i = 0; i < 300; i++)
    Transaction(
      id: 't$i',
      accountId: 'a${rng.nextInt(3)}',
      amount: Money(
        (rng.nextInt(4) == 0 ? 1 : -1) * (1 + rng.nextInt(200000)),
        rng.nextInt(20) == 0 ? 'EUR' : 'USD',
      ),
      date: today.addDays(-rng.nextInt(800)),
      pending: rng.nextInt(10) == 0,
      name: 'Shop ${rng.nextInt(25)}',
      plaidDetailedCategory: rng.nextInt(10) == 0
          ? null
          : codes[rng.nextInt(codes.length)],
      hidden: rng.nextInt(15) == 0,
      splits: rng.nextInt(12) == 0
          ? [
              TransactionSplit(
                categoryId:
                    systemCategories[rng.nextInt(systemCategories.length)].id,
                amount: Money(-(1 + rng.nextInt(5000)), 'USD'),
              ),
              TransactionSplit(
                categoryId: 'plaid:${codes[rng.nextInt(codes.length)]}',
                amount: Money(-(1 + rng.nextInt(5000)), 'USD'),
              ),
            ]
          : const [],
      source: DataSource.manual,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      syncVersion: 0,
    ),
];

Report report(List<Transaction> ts) => buildReport(
  period: LocalDateRange(LocalDate(2026, 10, 1), LocalDate(2026, 11, 1)),
  periodStartDay: 1,
  today: today,
  currencyCode: 'USD',
  entries: reportEntries(
    ts,
    lookup,
    currencyCode: 'USD',
    creditAccountIds: const {},
    excluded: (t) => t.hidden,
  ).toList(),
  lookup: lookup,
);

String fingerprint(Report r) => [
  for (final ReportPeriod p in [r.current, r.previous, r.yearAgo]) ...[
    p.spend,
    p.income,
    p.transferNet,
    p.counts,
    for (final t in p.spendByCategory) '${t.categoryId}:${t.own}:${t.total}',
    for (final t in p.incomeByCategory) '${t.categoryId}:${t.own}:${t.total}',
    for (final m in p.spendByMerchant) '${m.key}:${m.total}:${m.count}',
  ],
  for (final m in [...r.categoryMovers, ...r.merchantMovers])
    '${m.id}:${m.change.change}',
  for (final t in r.trend) '${t.spend}:${t.income}',
].join('|');

void main() {
  for (int seed = 0; seed < 40; seed++) {
    test('seed $seed', () {
      final Random rng = Random(seed);
      final List<Transaction> ts = ledger(rng);
      final Report r = report(ts);

      expect(fingerprint(report([...ts]..shuffle(rng))), fingerprint(r));

      for (final ReportPeriod p in [r.current, r.previous, r.yearAgo]) {
        final Money counted = Money.sum([
          for (final ReportEntry e in reportEntries(
            ts,
            lookup,
            currencyCode: 'USD',
            creditAccountIds: const {},
            excluded: (t) => t.hidden,
          ))
            if (p.range.contains(e.date) && !e.date.isAfter(p.through))
              e.amount,
        ], currencyCode: 'USD');
        expect(p.income - p.spend + p.transferNet, counted);

        for (final List<CategoryTotal> totals in [
          p.spendByCategory,
          p.incomeByCategory,
        ]) {
          for (final CategoryTotal t in totals) {
            if (t.categoryId == null) continue;
            final Money children = Money.sum([
              for (final c in ReportPeriod.childrenOf(totals, t.categoryId!))
                c.total,
            ], currencyCode: 'USD');
            expect(t.total, t.own + children, reason: '${t.categoryId}');
          }
          expect(
            Money.sum([
              for (final t in ReportPeriod.topLevel(totals)) t.total,
            ], currencyCode: 'USD'),
            totals == p.spendByCategory ? p.spend : p.income,
          );
        }
      }

      for (final List<Mover> movers in [r.categoryMovers, r.merchantMovers]) {
        expect(movers.length, lessThanOrEqualTo(topMoverLimit));
        for (int i = 1; i < movers.length; i++) {
          expect(
            movers[i - 1].change.change.abs() >= movers[i].change.change.abs(),
            isTrue,
          );
        }
      }
    });
  }
}
