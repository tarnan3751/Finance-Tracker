// The observed net worth series (net_worth_series.dart): signed sums by account type, a
// day without snapshots carried, an account no longer live classified by sign, one
// series per currency.
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

final LocalDate d0 = LocalDate(2026, 10, 20);

BalanceSnapshot row(String account, int day, int cents, [String cur = 'USD']) =>
    BalanceSnapshot(
      accountId: account,
      date: d0.addDays(day),
      current: Money(cents, cur),
      source: DataSource.plaid,
    );

Money usd(int cents) => Money(cents, 'USD');

const Map<String, AccountType> types = {
  'checking': AccountType.depository,
  'card': AccountType.credit,
  'mortgage': AccountType.loan,
  '401k': AccountType.investment,
  'cash': AccountType.other,
};

void main() {
  test('sums assets and liabilities by type, signed', () {
    final List<NetWorthPoint> s = observedNetWorth([
      row('checking', 0, -2500), // overdrawn: lowers the assets
      row('401k', 0, 1000000),
      row('cash', 0, 5000),
      row('card', 0, 1200), // in credit: lowers the liabilities
      row('mortgage', 0, -20000000),
    ], types)['USD']!;
    expect(s, [
      NetWorthPoint(date: d0, assets: usd(1002500), liabilities: usd(19998800)),
    ]);
    expect(s.single.netWorth, usd(-2500 + 1000000 + 5000 + 1200 - 20000000));
  });

  test('a day without snapshots carries the previous values', () {
    final List<NetWorthPoint> s = observedNetWorth([
      row('checking', 0, 10000),
      row('card', 0, -3000),
      row('checking', 3, 12000),
    ], types)['USD']!;
    expect(s.map((p) => p.date), [for (int i = 0; i < 4; i++) d0.addDays(i)]);
    expect(s.map((p) => p.carried), [false, true, true, false]);
    expect(s[1].assets, usd(10000));
    expect(s[2].liabilities, usd(3000));
    expect(
      s[3],
      NetWorthPoint(
        date: d0.addDays(3),
        assets: usd(12000),
        liabilities: usd(0),
      ),
    );
    expect(s.any((p) => p.derived), isFalse);
  });

  test('an account no longer live is classified by its sign', () {
    final NetWorthPoint p = observedNetWorth([
      row('gone-asset', 0, 700),
      row('gone-loan', 0, -400),
    ], types)['USD']!.single;
    expect(p.assets, usd(700));
    expect(p.liabilities, usd(400));
  });

  test('one series per currency, each over its own dates', () {
    final Map<String, List<NetWorthPoint>> s = observedNetWorth(
      [
        row('checking', 1, 100),
        row('eur', 0, 900, 'EUR'),
        row('eur', 2, 800, 'EUR'),
      ],
      {...types, 'eur': AccountType.depository},
    );
    expect(s.keys, ['EUR', 'USD']);
    expect(s['EUR']!.map((p) => p.assets.minorUnits), [900, 900, 800]);
    expect(s['USD']!.single.date, d0.addDays(1));
  });

  test('no snapshots, no series', () {
    expect(observedNetWorth(const [], types), isEmpty);
  });
}
