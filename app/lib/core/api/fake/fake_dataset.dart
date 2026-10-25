/// The Plaid-sourced data the in-app fake server serves: per Item, its institution,
/// accounts, transactions, recurring streams, liabilities and investments.
///
/// This is demo data (`PLAN.md` §7.1: synthesis lives in the demo flavor), so every
/// transaction and recurring stream must say `source: demo`; the constructor refuses any
/// other. The fake keeps every id as given and assigns only `sync_version`, per user, when
/// an Item's first completed sync applies it (`fake_server.dart`). [FakeDataset.sample] is
/// a small hand-written dataset (the tests and the dev flavor's fake);
/// [FakeDataset.fromDemoSeed] is the persona engine's household the demo flavor shows.
library;

import 'dart:typed_data';

import 'package:finance_tracker/core/api/api_models.dart';
import 'package:persona_engine/persona_engine.dart'
    show DemoSeed, GeneratedHousehold;
import 'package:shared_models/shared_models.dart';

/// One Item's data.
final class FakeItemData {
  /// The Item [id] at [institution]. Each transaction, stream, liability, holding and
  /// investment transaction must belong to one of [accounts]; transactions and streams
  /// must be `demo`.
  FakeItemData({
    required this.id,
    required this.institution,
    required this.accounts,
    this.transactions = const [],
    this.recurringStreams = const [],
    this.liabilities = const Liabilities(),
    this.holdings = const [],
    this.securities = const [],
    this.investmentTransactions = const [],
    this.institutionLogo,
  }) {
    final Set<String> accountIds = {for (final Account a in accounts) a.id};
    void owned(String accountId, String what) {
      if (!accountIds.contains(accountId)) {
        throw ArgumentError('$what is on $accountId, not an account of $id');
      }
    }

    for (final Transaction t in transactions) {
      if (t.source != DataSource.demo) {
        throw ArgumentError(
          'transaction ${t.id} is ${t.source.name}, not demo',
        );
      }
      owned(t.accountId, 'transaction ${t.id}');
    }
    for (final RecurringStream s in recurringStreams) {
      if (s.source != RecurringSource.demo) {
        throw ArgumentError('stream ${s.id} is ${s.source.name}, not demo');
      }
      owned(s.accountId, 'stream ${s.id}');
    }
    for (final CreditLiability c in liabilities.credit) {
      owned(c.accountId, 'a credit liability');
    }
    for (final MortgageLiability m in liabilities.mortgage) {
      owned(m.accountId, 'a mortgage');
    }
    for (final StudentLoanLiability s in liabilities.student) {
      owned(s.accountId, 'a student loan');
    }
    for (final Holding h in holdings) {
      owned(h.accountId, 'a holding');
    }
    for (final InvestmentTransaction t in investmentTransactions) {
      owned(t.accountId, 'investment transaction ${t.id}');
    }
  }

  final String id;
  final Institution institution;
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<RecurringStream> recurringStreams;
  final Liabilities liabilities;
  final List<Holding> holdings;
  final List<Security> securities;
  final List<InvestmentTransaction> investmentTransactions;

  /// The institution's logo as PNG bytes, served by `getInstitutionLogo`; null for none
  /// (the persona engine's datasets have none).
  final Uint8List? institutionLogo;
}

/// Everything the fake server can link.
final class FakeDataset {
  /// A dataset of [items], whose ids must be distinct.
  FakeDataset({required this.items}) {
    final Set<String> ids = {};
    for (final FakeItemData item in items) {
      if (!ids.add(item.id)) throw ArgumentError('two Items are ${item.id}');
    }
  }

  /// No Items.
  FakeDataset.empty() : items = const [];

  /// The persona engine's household [seed]: one Item per demo Item, at its institution,
  /// with its accounts and their transactions (all `demo`), ids as the engine gives them.
  /// The engine's liabilities, holdings and investment transactions are its own types
  /// and are not carried before Phase 3 and Phase 6 read them; it has no recurring
  /// streams.
  factory FakeDataset.fromDemoSeed(DemoSeed seed) {
    final GeneratedHousehold household = seed.household;
    return FakeDataset(
      items: [
        for (final Item item in household.items)
          FakeItemData(
            id: item.id,
            institution: household.institutions.firstWhere(
              (i) => i.id == item.institutionId,
            ),
            accounts: [
              for (final Account a in household.accounts)
                if (a.itemId == item.id) a,
            ],
            transactions: [
              for (final Transaction t in household.transactions)
                if (household.accounts.any(
                  (a) => a.id == t.accountId && a.itemId == item.id,
                ))
                  t,
            ],
          ),
      ],
    );
  }

  /// One Item at First Platypus Bank, with a checking, a savings and a credit-card
  /// account, a dozen transactions over the 40 days before [today] (one pending), a
  /// monthly subscription stream and the card's liability.
  factory FakeDataset.sample(LocalDate today) {
    const String usd = 'USD';
    const String checking = 'sample-checking';
    const String savings = 'sample-savings';
    const String card = 'sample-card';
    final DateTime asOf = DateTime.utc(today.year, today.month, today.day, 6);
    int number = 0;
    Transaction entry(
      String account,
      int daysAgo,
      int cents,
      String name, {
      String? merchant,
      String? primary,
      String? detailed,
      bool pending = false,
    }) {
      number++;
      final LocalDate date = today.addDays(-daysAgo);
      final DateTime at = DateTime.utc(date.year, date.month, date.day, 12);
      return Transaction(
        id: 'sample-txn-${number.toString().padLeft(2, '0')}',
        accountId: account,
        amount: Money(cents, usd),
        date: date,
        authorizedDate: pending ? null : date.addDays(-1),
        pending: pending,
        name: name,
        merchantName: merchant,
        plaidPrimaryCategory: primary,
        plaidDetailedCategory: detailed,
        source: DataSource.demo,
        createdAt: at,
        updatedAt: at,
        syncVersion: 0,
      );
    }

    return FakeDataset(
      items: [
        FakeItemData(
          id: 'sample-item-1',
          institution: const Institution(
            id: 'ins_109508',
            name: 'First Platypus Bank',
            primaryColor: 0xFF1F6FEB,
          ),
          accounts: [
            Account(
              id: checking,
              itemId: 'sample-item-1',
              type: AccountType.depository,
              subtype: 'checking',
              name: 'Platypus Checking',
              officialName: 'Platypus Gold Standard Checking',
              mask: '0000',
              currencyCode: usd,
              currentBalance: Money(245012, usd),
              availableBalance: Money(240012, usd),
              balancesAsOf: asOf,
              isHidden: false,
              displayOrder: 0,
            ),
            Account(
              id: savings,
              itemId: 'sample-item-1',
              type: AccountType.depository,
              subtype: 'savings',
              name: 'Platypus Savings',
              mask: '1111',
              currencyCode: usd,
              currentBalance: Money(1210000, usd),
              availableBalance: Money(1210000, usd),
              balancesAsOf: asOf,
              isHidden: false,
              displayOrder: 1,
            ),
            Account(
              id: card,
              itemId: 'sample-item-1',
              type: AccountType.credit,
              subtype: 'credit card',
              name: 'Platypus Rewards Card',
              mask: '3333',
              currencyCode: usd,
              // Owed, so negative in the app's sign (`api/openapi.yaml`, `Account`).
              currentBalance: Money(-51234, usd),
              availableBalance: Money(448766, usd),
              creditLimit: Money(500000, usd),
              balancesAsOf: asOf,
              isHidden: false,
              displayOrder: 2,
            ),
          ],
          transactions: [
            entry(
              checking,
              1,
              -1299,
              'NETFLIX.COM',
              merchant: 'Netflix',
              primary: 'ENTERTAINMENT',
              detailed: 'ENTERTAINMENT_TV_AND_MOVIES',
            ),
            entry(
              card,
              0,
              -642,
              'BLUE BOTTLE COFFEE',
              merchant: 'Blue Bottle Coffee',
              primary: 'FOOD_AND_DRINK',
              detailed: 'FOOD_AND_DRINK_COFFEE',
              pending: true,
            ),
            entry(
              card,
              2,
              -8417,
              'WHOLE FOODS MARKET',
              merchant: 'Whole Foods',
              primary: 'FOOD_AND_DRINK',
              detailed: 'FOOD_AND_DRINK_GROCERIES',
            ),
            entry(
              checking,
              3,
              325000,
              'ACME CORP PAYROLL',
              merchant: 'Acme Corp',
              primary: 'INCOME',
              detailed: 'INCOME_WAGES',
            ),
            entry(
              card,
              5,
              -2350,
              'UBER TRIP',
              merchant: 'Uber',
              primary: 'TRANSPORTATION',
              detailed: 'TRANSPORTATION_TAXIS_AND_RIDE_SHARES',
            ),
            entry(
              checking,
              7,
              -185000,
              'OAKWOOD APARTMENTS RENT',
              primary: 'RENT_AND_UTILITIES',
              detailed: 'RENT_AND_UTILITIES_RENT',
            ),
            entry(
              checking,
              9,
              -50000,
              'TRANSFER TO SAVINGS',
              primary: 'TRANSFER_OUT',
              detailed: 'TRANSFER_OUT_SAVINGS',
            ),
            entry(
              savings,
              9,
              50000,
              'TRANSFER FROM CHECKING',
              primary: 'TRANSFER_IN',
              detailed: 'TRANSFER_IN_SAVINGS',
            ),
            entry(
              card,
              12,
              -4599,
              'SHELL OIL',
              merchant: 'Shell',
              primary: 'TRANSPORTATION',
              detailed: 'TRANSPORTATION_GAS',
            ),
            entry(
              checking,
              15,
              -6240,
              'PACIFIC GAS AND ELECTRIC',
              merchant: 'PG&E',
              primary: 'RENT_AND_UTILITIES',
              detailed: 'RENT_AND_UTILITIES_GAS_AND_ELECTRICITY',
            ),
            entry(
              savings,
              30,
              1012,
              'INTEREST PAYMENT',
              primary: 'INCOME',
              detailed: 'INCOME_INTEREST_EARNED',
            ),
            entry(
              checking,
              31,
              -1299,
              'NETFLIX.COM',
              merchant: 'Netflix',
              primary: 'ENTERTAINMENT',
              detailed: 'ENTERTAINMENT_TV_AND_MOVIES',
            ),
          ],
          recurringStreams: [
            RecurringStream(
              id: 'sample-stream-netflix',
              accountId: checking,
              merchantName: 'Netflix',
              cadence: RecurringCadence.monthly,
              averageAmount: Money(-1299, usd),
              lastExpected: today.addDays(-1),
              nextExpected: today.addDays(-1).addMonths(1),
              status: RecurringStatus.active,
              isSubscription: true,
              source: RecurringSource.demo,
            ),
          ],
          liabilities: Liabilities(
            credit: [
              CreditLiability(
                accountId: card,
                aprs: [
                  Apr(
                    aprPercentage: '24.99',
                    aprType: 'purchase_apr',
                    balanceSubjectToApr: Money(51234, usd),
                    interestChargeAmount: Money(0, usd),
                  ),
                ],
                isOverdue: false,
                lastPaymentAmount: Money(30000, usd),
                lastPaymentDate: today.addDays(-20),
                lastStatementIssueDate: today.addDays(-25),
                lastStatementBalance: Money(42110, usd),
                minimumPaymentAmount: Money(2500, usd),
                nextPaymentDueDate: today.addDays(5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final List<FakeItemData> items;

  /// The Item [id], or null.
  FakeItemData? item(String id) {
    for (final FakeItemData item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
