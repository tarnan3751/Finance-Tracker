// The everyday-spending allowance (forecast_plan.dart): the 90 whole days before today,
// half-even rounding, and what it leaves out (stream members and bill payments, own-account
// and savings transfers, hidden and deleted rows, inflows, other accounts and
// currencies) and keeps (pending rows, card payments).
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/forecast/domain/forecast_plan.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'forecast_fixtures.dart';

final CategoryLookup lookup = categoryLookup(systemCategories);

Money allowance(List<Transaction> ledger, {Set<String> excluded = const {}}) =>
    dailyAllowance(
      ledger,
      today: today,
      accountIds: const {'checking', 'savings'},
      currencyCode: 'USD',
      excludedIds: excluded,
      lookup: lookup,
    );

void main() {
  test('the window is the 90 days before today, today left out', () {
    expect(
      allowance([
        txn('first', -9000, today.addDays(-90)),
        txn('yesterday', -9000, today.addDays(-1)),
        txn('too old', -9000, today.addDays(-91)),
        txn('today', -9000, today),
      ]),
      usd(200),
    );
  });

  test('the average rounds half-even', () {
    expect(allowance([txn('a', -135, today.addDays(-1))]), usd(2));
    expect(allowance([txn('a', -225, today.addDays(-1))]), usd(2));
    expect(allowance([txn('a', -44, today.addDays(-1))]), usd(0));
    expect(allowance([txn('a', -46, today.addDays(-1))]), usd(1));
  });

  test(
    'members, payments, transfers, hidden, deleted and inflows are left out',
    () {
      final LocalDate d = today.addDays(-10);
      expect(
        allowance(
          [
            txn('spend', -9000, d),
            txn('member', -9000, d),
            txn('payment', -9000, d),
            txn(
              'own',
              -9000,
              d,
              plaidDetailed: 'TRANSFER_OUT_ACCOUNT_TRANSFER',
            ),
            txn('saved', -9000, d, plaidDetailed: 'TRANSFER_OUT_SAVINGS'),
            txn('hidden', -9000, d, hidden: true),
            txn('deleted', -9000, d, deleted: true),
            txn('refund', 9000, d),
            txn('elsewhere', -9000, d, accountId: 'card'),
            txn('euro', -9000, d, currency: 'EUR'),
          ],
          excluded: {'member', 'payment'},
        ),
        usd(100),
      );
    },
  );

  test('pending rows and card payments stay in', () {
    final LocalDate d = today.addDays(-3);
    expect(
      allowance([
        txn('pending', -4500, d, pending: true),
        txn(
          'card payment',
          -4500,
          d,
          plaidDetailed: 'LOAN_PAYMENTS_CREDIT_CARD_PAYMENT',
        ),
      ]),
      usd(100),
    );
  });

  test('a transfer the user recategorized counts', () {
    expect(
      allowance([
        txn(
          'moved',
          -9000,
          today.addDays(-2),
          plaidDetailed: 'TRANSFER_OUT_SAVINGS',
        ).copyWith(userCategoryId: systemCategoryId('FOOD_AND_DRINK')),
      ]),
      usd(100),
    );
  });

  test('nothing spent is no allowance', () {
    expect(allowance(const []), usd(0));
  });
}
