// The account ledger's running balance: summed from the oldest transaction to the newest
// and listed newest first, so each row shows the balance after it; or, for a linked
// account with a reported balance, worked back from that balance, so the newest row is
// what the bank reports even when the history on the device is partial.
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/seed.dart';

void main() {
  test('each row carries the balance after it, oldest first in the sum', () {
    final List<LedgerEntry> ledger = withRunningBalances([
      testTransaction('c', cents: -2500, daysAgo: 0),
      testTransaction('b', cents: 10000, daysAgo: 1),
      testTransaction('a', cents: 50000, daysAgo: 2),
    ], currencyCode: 'USD');

    expect([for (final e in ledger) e.transaction.id], ['c', 'b', 'a']);
    expect(
      [for (final e in ledger) e.balance],
      [Money(57500, 'USD'), Money(60000, 'USD'), Money(50000, 'USD')],
    );
  });

  test('an empty account has an empty ledger', () {
    expect(withRunningBalances(const [], currencyCode: 'USD'), isEmpty);
    expect(
      withRunningBalances(
        const [],
        currencyCode: 'USD',
        reported: Money(100, 'USD'),
      ),
      isEmpty,
    );
  });

  test('a reported balance anchors the newest row, partial history or not', () {
    // The linked checking's transactions sum to 2,437.45 while its bank reports 1,100.00.
    final Money reported = testLinkedAccounts.first.currentBalance!;
    final List<LedgerEntry> ledger = withRunningBalances(
      testLinkedTransactions,
      currencyCode: 'USD',
      reported: reported,
    );
    final Money sum = testLinkedTransactions
        .map((t) => t.amount)
        .reduce((a, b) => a + b);
    expect(sum, Money(243745, 'USD'));

    expect(
      [for (final e in ledger) e.transaction.id],
      [for (final t in testLinkedTransactions) t.id],
    );
    expect(ledger.first.balance, Money(110000, 'USD'));
    // Each older row is the reported balance less every newer amount, pending included;
    // the oldest row less only its own amount is the reported balance less all of them.
    expect(ledger[1].balance, reported - testLinkedTransactions.first.amount);
    expect(
      ledger.last.balance,
      reported - sum + testLinkedTransactions.last.amount,
    );
    // The balance before the oldest row is the reported balance minus every amount.
    expect(
      ledger.last.balance! - ledger.last.transaction.amount,
      reported - sum,
    );
  });

  test('a row in another currency has no balance and is left out', () {
    final List<Transaction> rows = [
      testTransaction('c', cents: -2500, daysAgo: 0),
      testTransaction('stray', cents: -999, currency: 'EUR', daysAgo: 1),
      testTransaction('a', cents: 50000, daysAgo: 2),
    ];

    final List<LedgerEntry> derived = withRunningBalances(
      rows,
      currencyCode: 'USD',
    );
    expect(
      [for (final e in derived) e.balance],
      [Money(47500, 'USD'), null, Money(50000, 'USD')],
    );

    final List<LedgerEntry> anchored = withRunningBalances(
      rows,
      currencyCode: 'USD',
      reported: Money(100000, 'USD'),
    );
    expect(
      [for (final e in anchored) e.balance],
      [Money(100000, 'USD'), null, Money(102500, 'USD')],
    );
  });
}
