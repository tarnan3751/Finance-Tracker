/// The demo flavor's data: a small, hand-written household that runs with no server and no
/// database (`PLAN.md` §7.1: synthesized data lives in the demo flavor, labelled `demo`).
///
/// Two manual accounts and a dozen transactions over the 60 days before "today", every one
/// with `source: DataSource.demo`, categorized with the seeded system categories. The seed
/// is deterministic for a given day: the same date gives the same records, ids and audit
/// instants. Phase 2's persona engine replaces the content; [DemoSeed] is the shape it
/// produces.
library;

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:shared_models/shared_models.dart';

/// The records the demo flavor starts with.
final class DemoSeed {
  /// A seed of [accounts] and [transactions].
  const DemoSeed({required this.accounts, required this.transactions});

  /// A seed with nothing in it.
  const DemoSeed.empty() : accounts = const [], transactions = const [];

  final List<Account> accounts;
  final List<Transaction> transactions;
}

/// Loads [seed] into [store], through the store's rules. The demo flavor's store also
/// holds the system categories, which `CategoryRepository.ensureSeeded` adds.
void loadDemoSeed(InMemoryStore store, DemoSeed seed) {
  seed.accounts.forEach(store.upsertAccount);
  seed.transactions.forEach(store.upsertTransaction);
}

const String _checking = 'demo-checking';
const String _card = 'demo-card';
const String _usd = 'USD';

/// The demo seed with its transactions dated relative to [today].
DemoSeed buildDemoSeed(LocalDate today) {
  int number = 0;
  Transaction entry(
    String account,
    int daysAgo,
    int cents,
    String name, {
    String? merchant,
    String? category,
    bool pending = false,
    List<String> tags = const [],
    List<TransactionSplit> splits = const [],
  }) {
    number++;
    final LocalDate date = today.addDays(-daysAgo);
    final DateTime at = DateTime.utc(date.year, date.month, date.day, 12);
    return Transaction(
      id: 'demo-txn-${number.toString().padLeft(2, '0')}',
      accountId: account,
      amount: Money(cents, _usd),
      date: date,
      pending: pending,
      name: name,
      merchantName: merchant,
      userCategoryId: category == null ? null : systemCategoryId(category),
      tags: tags,
      splits: splits,
      source: DataSource.demo,
      createdAt: at,
      updatedAt: at,
      syncVersion: 0,
    );
  }

  return DemoSeed(
    accounts: const [
      Account(
        id: _checking,
        type: AccountType.depository,
        subtype: 'checking',
        name: 'Everyday Checking',
        currencyCode: _usd,
        isHidden: false,
        displayOrder: 0,
      ),
      Account(
        id: _card,
        type: AccountType.credit,
        subtype: 'credit card',
        name: 'Rewards Card',
        currencyCode: _usd,
        isHidden: false,
        displayOrder: 1,
      ),
    ],
    transactions: [
      entry(_checking, 58, 320000, 'Opening balance'),
      entry(
        _checking,
        45,
        245000,
        'ACME CORP PAYROLL',
        category: 'INCOME_SALARY',
      ),
      entry(
        _checking,
        44,
        -145000,
        'Rent',
        category: 'RENT_AND_UTILITIES_RENT',
      ),
      entry(
        _card,
        40,
        -12418,
        'WHOLEFDS MKT 10234',
        merchant: 'Whole Foods Market',
        category: 'FOOD_AND_DRINK_GROCERIES',
        tags: const ['household'],
        splits: [
          TransactionSplit(
            categoryId: systemCategoryId('FOOD_AND_DRINK_GROCERIES'),
            amount: Money(-10000, _usd),
          ),
          TransactionSplit(
            categoryId: systemCategoryId('GENERAL_MERCHANDISE_SUPERSTORES'),
            amount: Money(-2418, _usd),
            note: 'Household supplies',
          ),
        ],
      ),
      entry(
        _checking,
        30,
        -8640,
        'CITY POWER & LIGHT',
        category: 'RENT_AND_UTILITIES_GAS_AND_ELECTRICITY',
      ),
      entry(
        _card,
        26,
        -1549,
        'NETFLIX.COM',
        merchant: 'Netflix',
        category: 'ENTERTAINMENT_TV_AND_MOVIES',
        tags: const ['subscription'],
      ),
      entry(
        _card,
        20,
        -4802,
        'SHELL OIL 57442',
        merchant: 'Shell',
        category: 'TRANSPORTATION_GAS',
      ),
      entry(
        _checking,
        15,
        245000,
        'ACME CORP PAYROLL',
        category: 'INCOME_SALARY',
      ),
      entry(
        _checking,
        14,
        -145000,
        'Rent',
        category: 'RENT_AND_UTILITIES_RENT',
      ),
      entry(
        _checking,
        12,
        -18769,
        'Card payment',
        category: 'LOAN_PAYMENTS_CREDIT_CARD_PAYMENT',
      ),
      entry(
        _card,
        12,
        18769,
        'Payment received',
        category: 'LOAN_PAYMENTS_CREDIT_CARD_PAYMENT',
      ),
      entry(
        _card,
        1,
        -575,
        'BLUE BOTTLE COFFEE',
        merchant: 'Blue Bottle Coffee',
        category: 'FOOD_AND_DRINK_COFFEE',
        pending: true,
      ),
    ],
  );
}
