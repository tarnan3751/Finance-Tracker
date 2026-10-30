// The allocation by security type and a holding's gain, in integer minor units.
import 'package:finance_tracker/features/investments/domain/allocation.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

Security _security(String id, {String? type, bool? cash}) => Security(
  id: id,
  type: type,
  isCashEquivalent: cash,
  currencyCode: 'USD',
  source: DataSource.plaid,
);

HoldingView _view(Security? security, int cents, {String currency = 'USD'}) => (
  holding: Holding(
    accountId: 'a',
    securityId: security?.id ?? 'gone',
    quantity: Decimal.parse('1'),
    institutionPrice: Decimal.parse('1'),
    institutionValue: Money(cents, currency),
    source: DataSource.plaid,
  ),
  security: security,
);

Holding _holding(int valueCents, int? costCents) => Holding(
  accountId: 'a',
  securityId: 's',
  quantity: Decimal.parse('1'),
  institutionPrice: Decimal.parse('1'),
  institutionValue: Money(valueCents, 'USD'),
  costBasis: costCents == null ? null : Money(costCents, 'USD'),
  source: DataSource.plaid,
);

void main() {
  group('allocationKey', () {
    test('a cash equivalent is cash whatever its type', () {
      expect(
        allocationKey(_security('s', type: 'mutual fund', cash: true)),
        'cash',
      );
    });

    test('the type trimmed and in lower case', () {
      expect(
        allocationKey(_security('s', type: ' Mutual Fund ')),
        'mutual fund',
      );
    });

    test('no type, an empty type or no security is other', () {
      expect(allocationKey(_security('s')), 'other');
      expect(allocationKey(_security('s', type: '  ')), 'other');
      expect(allocationKey(null), 'other');
    });
  });

  test('allocationOf sums each type per currency, the largest first', () {
    final List<Allocation> allocations = allocationOf([
      _view(_security('vti', type: 'etf'), 306375),
      _view(_security('acme', type: 'equity'), 150000),
      _view(_security('bnd', type: 'ETF'), 144800),
      _view(_security('usd', type: 'cash', cash: true), 150000),
      _view(null, 3127),
      _view(_security('eu', type: 'etf'), 5000, currency: 'EUR'),
    ]);
    expect(allocations.map((a) => a.total), [
      Money(5000, 'EUR'),
      Money(754302, 'USD'),
    ]);
    expect(allocations.last.slices, [
      (key: 'etf', value: Money(451175, 'USD')),
      // A tie goes by key.
      (key: 'cash', value: Money(150000, 'USD')),
      (key: 'equity', value: Money(150000, 'USD')),
      (key: 'other', value: Money(3127, 'USD')),
    ]);
    expect(allocationOf(const []), isEmpty);
  });

  test('shareBasisPoints rounds toward zero, null on a total not positive', () {
    expect(shareBasisPoints(Money(1, 'USD'), Money(3, 'USD')), 3333);
    expect(shareBasisPoints(Money(-1, 'USD'), Money(3, 'USD')), -3333);
    expect(shareBasisPoints(Money(1, 'USD'), Money(0, 'USD')), isNull);
  });

  group('gainOf', () {
    test('value less cost basis, with its basis points of the cost basis', () {
      expect(gainOf(_holding(306375, 290000)), (
        amount: Money(16375, 'USD'),
        basisPoints: 564,
      ));
      expect(gainOf(_holding(150000, 165000)), (
        amount: Money(-15000, 'USD'),
        basisPoints: -909,
      ));
    });

    test('no cost basis, no gain; a zero cost basis, no percent', () {
      expect(gainOf(_holding(100, null)), isNull);
      expect(gainOf(_holding(100, 0)), (
        amount: Money(100, 'USD'),
        basisPoints: null,
      ));
    });
  });
}
