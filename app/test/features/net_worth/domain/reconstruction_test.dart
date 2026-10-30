// The derived prefix (reconstruction.dart): the walk back through posted, hidden and
// transfer rows, what it leaves out, the flat accounts, the join with the observed
// series, and the recipe on the family persona against the engine's own balances.
import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart'
    show snapshotOf;
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/features/net_worth/domain/reconstruction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart'
    show DemoSeed, OpeningBalance, PersonaId, generateDemoSeed;
import 'package:shared_models/shared_models.dart';

final LocalDate s = LocalDate(2026, 10, 24);
final DateTime at = DateTime.utc(2026, 10, 24);

Money usd(int cents) => Money(cents, 'USD');

BalanceSnapshot row(String account, int cents, {int day = 0}) =>
    BalanceSnapshot(
      accountId: account,
      date: s.addDays(day),
      current: usd(cents),
      source: DataSource.plaid,
    );

Transaction tx(
  String id,
  String account,
  int cents,
  int day, {
  bool pending = false,
  bool hidden = false,
  String currency = 'USD',
  DateTime? deletedAt,
}) => Transaction(
  id: id,
  accountId: account,
  amount: Money(cents, currency),
  date: s.addDays(day),
  pending: pending,
  name: id,
  hidden: hidden,
  source: DataSource.plaid,
  createdAt: at,
  updatedAt: at,
  deletedAt: deletedAt,
  syncVersion: 1,
);

const Map<String, AccountType> types = {
  'checking': AccountType.depository,
  'savings': AccountType.depository,
  'card': AccountType.credit,
  'mortgage': AccountType.loan,
  '401k': AccountType.investment,
  'cash': AccountType.other,
};

void main() {
  test(
    'walks back through posted rows, hidden ones and both transfer legs',
    () {
      final List<(LocalDate, Money)> walked = walkedBalances(
        row('checking', 50000),
        [
          tx(
            'pay',
            'checking',
            200000,
            0,
          ), // dated on the anchor day: before it, less
          tx('rent', 'checking', -150000, -1),
          tx('hidden', 'checking', -1000, -1, hidden: true),
          tx('to-savings', 'checking', -20000, -2),
          tx('from-checking', 'savings', 20000, -2), // the other account's leg
          tx('pending', 'checking', -999, -1, pending: true),
          tx('eur', 'checking', -777, -1, currency: 'EUR'),
          tx('later', 'checking', -5000, 1), // after the anchor: not walked
          tx('gone', 'checking', -333, -1, deletedAt: at),
        ],
      );
      expect(walked, [
        (s.addDays(-2), usd(50000 - 200000 + 151000)),
        (s.addDays(-1), usd(50000 - 200000)),
      ]);
    },
  );

  test('no counted row before the anchor day, no walk', () {
    expect(
      walkedBalances(row('checking', 100), [tx('a', 'checking', 5, 0)]),
      isEmpty,
    );
    expect(walkedBalances(row('checking', 100), const []), isEmpty);
  });

  test('the prefix holds loans, investments and other accounts flat', () {
    final List<BalanceSnapshot> rows = [
      row('checking', 100000),
      row('card', -30000),
      row('mortgage', -20000000),
      row('401k', 5000000),
      row('cash', 2000),
    ];
    final List<NetWorthPoint> prefix = reconstructedPrefix(rows, types, [
      tx('a', 'checking', -10000, 0),
      tx('b', 'card', -5000, -1),
      tx('c', 'mortgage', -90000, -1), // a loan's interest: not walked
      tx('d', 'checking', 3000, -3),
    ], 'USD');
    expect(prefix.map((p) => p.date), [
      for (int i = -3; i < 0; i++) s.addDays(i),
    ]);
    expect(prefix.every((p) => p.derived && !p.carried), isTrue);
    // Checking is 100000 − (−10000) on each of the three days; the card is −30000 on
    // day −1, its earliest row's, and before it holds at −30000 − (−5000).
    expect(prefix.last.assets, usd(110000 + 5000000 + 2000));
    expect(prefix.last.liabilities, usd(30000 + 20000000));
    expect(prefix[1].liabilities, usd(25000 + 20000000));
    expect(prefix.first.liabilities, usd(25000 + 20000000));
    expect(prefix.first.assets, usd(110000 + 5000000 + 2000));
  });

  test('an account whose history starts later holds its opening before it', () {
    // Checking starts on day −6; the card's first purchase is on day −2, so from −6 to
    // −3 the card holds what it owed before that purchase, with no step on −2.
    final List<NetWorthPoint> prefix = reconstructedPrefix(
      [row('checking', 50000), row('card', -12000)],
      types,
      [
        tx('pay', 'checking', 50000, -6),
        tx('coffee', 'card', -2000, -2),
        tx('book', 'card', -3000, -1),
      ],
      'USD',
    );
    expect(prefix.first.date, s.addDays(-6));
    expect(prefix.map((p) => p.liabilities.minorUnits), [
      7000, // −6: −12000 − (−2000 − 3000)
      7000,
      7000,
      7000,
      9000, // −2: after the coffee
      12000, // −1: after the book
    ]);
    expect(
      balanceBefore(row('card', -12000), [
        tx('coffee', 'card', -2000, -2),
        tx('book', 'card', -3000, -1),
      ]),
      usd(-7000),
    );
  });

  test('a dormant account holds at its snapshot on every day', () {
    final List<NetWorthPoint> prefix = reconstructedPrefix(
      [row('checking', 1000), row('savings', 2070375)],
      types,
      [tx('a', 'checking', 400, -3)],
      'USD',
    );
    expect(prefix, hasLength(3));
    expect(prefix.every((p) => p.assets == usd(1000 + 2070375)), isTrue);
  });

  test('an account first stored after the start has no derived history', () {
    final List<NetWorthPoint> prefix = reconstructedPrefix(
      [row('checking', 1000), row('savings', 5000, day: 2)],
      types,
      [tx('a', 'checking', 100, -1), tx('b', 'savings', 900, -1)],
      'USD',
    );
    expect(prefix, [
      NetWorthPoint(
        date: s.addDays(-1),
        assets: usd(1000),
        liabilities: usd(0),
        derived: true,
      ),
    ]);
  });

  test('the history joins the observed series at its first day exactly', () {
    final List<BalanceSnapshot> rows = [
      row('checking', 1000),
      row('card', -400),
      row('checking', 1500, day: 1),
      row('card', -400, day: 1),
    ];
    final List<Transaction> ledger = [
      tx('a', 'checking', 250, 0),
      tx('b', 'checking', -50, -2),
      tx('c', 'card', -400, -1),
    ];
    final List<NetWorthPoint> all = netWorthHistory(
      rows,
      types,
      ledger,
    )['USD']!;
    final List<NetWorthPoint> observed = observedNetWorth(rows, types)['USD']!;
    expect(all.sublist(all.length - observed.length), observed);
    expect(all.map((p) => p.date).toList(), [
      for (int i = -2; i <= 1; i++) s.addDays(i),
    ]);
    expect(all.map((p) => p.derived), [true, true, false, false]);
    // The day before the join: checking 1000 − 250, card −400 − 0.
    expect(all[1].netWorth, usd(750 - 400));
    // Day −2: checking still 750 (b is on −2 itself); the card's walk ends on −1.
    expect(
      all[0],
      NetWorthPoint(
        date: s.addDays(-2),
        assets: usd(750),
        liabilities: usd(0),
        derived: true,
      ),
    );
  });

  test('the family persona: every walked day equals the engine\'s balance', () {
    final DemoSeed seed = generateDemoSeed(PersonaId.family, 1, s);
    final List<Account> accounts = seed.household.accounts;
    final List<Transaction> ledger = seed.household.transactions;
    final Map<String, AccountType> typeOf = {
      for (final Account a in accounts) a.id: a.type,
    };
    final List<BalanceSnapshot> rows = [
      for (final Account a in accounts)
        snapshotOf(
          a,
          date: s,
          derived: null,
          holdings: const [],
          source: DataSource.demo,
        ),
    ];
    final Map<String, Money> opening = {
      for (final OpeningBalance o in seed.household.openingBalances)
        o.accountId: o.amount,
    };
    int walkedDays = 0;
    for (final Account a in accounts.where((a) => isWalked(a.type))) {
      final BalanceSnapshot anchor = rows.singleWhere(
        (r) => r.accountId == a.id,
      );
      final List<Transaction> own = [
        for (final Transaction t in ledger)
          if (t.accountId == a.id) t,
      ];
      final List<(LocalDate, Money)> walked = walkedBalances(anchor, ledger);
      expect(
        walked.first.$1,
        own.map((t) => t.date).reduce((x, y) => x.isBefore(y) ? x : y),
        reason: a.id,
      );
      for (final (LocalDate d, Money balance) in walked) {
        final Money expected =
            opening[a.id]! +
            Money.sum([
              for (final Transaction t in own)
                if (!t.date.isAfter(d)) t.amount,
            ], currencyCode: a.currencyCode);
        expect(balance, expected, reason: '${a.id} on $d');
        walkedDays++;
      }
    }
    expect(walkedDays, greaterThan(700));

    final List<NetWorthPoint> history = netWorthHistory(
      rows,
      typeOf,
      ledger,
    )['USD']!;
    final List<NetWorthPoint> prefix = [
      for (final NetWorthPoint p in history)
        if (p.derived) p,
    ];
    expect(prefix, isNotEmpty);
    expect(history.last.date, s);
    expect(history.last.derived, isFalse);
    expect(
      history.last.netWorth,
      Money.sum([for (final BalanceSnapshot r in rows) r.current]),
    );
    // Every prefix day is each walked account's engine balance (its opening before its
    // first transaction, so no account appears with a step) plus the loans and the
    // 401(k) flat at today's rows.
    final Money flat = Money.sum([
      for (final BalanceSnapshot r in rows)
        if (!isWalked(typeOf[r.accountId])) r.current,
    ]);
    final List<Account> walkedAccounts = [
      for (final Account a in accounts)
        if (isWalked(a.type)) a,
    ];
    expect(
      prefix.first.date,
      ledger
          .where((t) => walkedAccounts.any((a) => a.id == t.accountId))
          .map((t) => t.date)
          .reduce((x, y) => x.isBefore(y) ? x : y),
    );
    for (final NetWorthPoint p in prefix) {
      final Money expected =
          flat +
          Money.sum([
            for (final Account a in walkedAccounts)
              opening[a.id]! +
                  Money.sum([
                    for (final Transaction t in ledger)
                      if (t.accountId == a.id && !t.date.isAfter(p.date))
                        t.amount,
                  ], currencyCode: 'USD'),
          ]);
      expect(p.netWorth, expected, reason: '${p.date}');
    }
  });
}
