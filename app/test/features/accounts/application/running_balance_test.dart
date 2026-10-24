// The account ledger's running balance: summed from the oldest transaction to the newest
// and listed newest first, so each row shows the balance after it.
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
    ]);

    expect([for (final e in ledger) e.transaction.id], ['c', 'b', 'a']);
    expect(
      [for (final e in ledger) e.balance],
      [Money(57500, 'USD'), Money(60000, 'USD'), Money(50000, 'USD')],
    );
  });

  test('an empty account has an empty ledger', () {
    expect(withRunningBalances(const []), isEmpty);
  });
}
