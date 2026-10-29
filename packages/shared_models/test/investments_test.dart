// The investment entities are values: equal when their fields are, Decimals by value.
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  test('a holding equals another with the same fields', () {
    Holding holding(String quantity) => Holding(
      accountId: 'a1',
      securityId: 's1',
      quantity: Decimal.parse(quantity),
      institutionPrice: Decimal.parse('42.10'),
      institutionPriceAsOf: LocalDate(2026, 10, 23),
      institutionValue: Money(44205, 'USD'),
      costBasis: Money(40000, 'USD'),
      source: DataSource.plaid,
    );
    expect(holding('10.5'), holding('10.50'));
    expect(holding('10.5'), isNot(holding('10.6')));
    expect(
      holding('10.5').copyWith(source: DataSource.demo).source,
      DataSource.demo,
    );
  });

  test('a security and an investment transaction carry their fields', () {
    final Security security = Security(
      id: 's1',
      tickerSymbol: 'VTI',
      type: 'etf',
      closePrice: Decimal.parse('298.00'),
      currencyCode: 'USD',
      source: DataSource.demo,
    );
    expect(security.name, isNull);
    expect(security.closePrice.toString(), '298.00');
    final InvestmentTransaction buy = InvestmentTransaction(
      id: 't1',
      accountId: 'a1',
      securityId: 's1',
      date: LocalDate(2026, 10, 7),
      name: 'BUY VTI',
      type: 'buy',
      subtype: 'buy',
      quantity: Decimal.parse('0.9643'),
      price: Decimal.parse('280.00'),
      amount: Money(-27000, 'USD'),
      syncVersion: 13,
      source: DataSource.plaid,
    );
    expect(buy.deletedAt, isNull);
    expect(buy, buy.copyWith());
    expect(buy.copyWith(syncVersion: 14), isNot(buy));
  });
}
