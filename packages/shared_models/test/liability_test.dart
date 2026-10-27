// The liability entity: value equality over its nested values (the APRs and the payload).
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  Liability card({String rate = '24.99'}) => Liability(
    accountId: 'card',
    kind: LiabilityKind.credit,
    source: DataSource.plaid,
    minimumPaymentAmount: Money(2500, 'USD'),
    aprs: [
      LiabilityApr(
        type: 'purchase_apr',
        percentageBasisPoints: 2499,
        balanceSubjectToApr: Money(51234, 'USD'),
      ),
    ],
    payload: {
      'account_id': 'card',
      'aprs': [
        {'apr_percentage': rate, 'apr_type': 'purchase_apr'},
      ],
    },
  );

  test('equal when every field, nested ones included, is equal', () {
    expect(card(), card());
    expect(card().hashCode, card().hashCode);
  });

  test('a payload that differs makes the liability differ', () {
    expect(card(), isNot(card(rate: '24.999')));
  });

  test('a liability with nothing reported has no APRs', () {
    const Liability bare = Liability(
      accountId: 'loan',
      kind: LiabilityKind.student,
      source: DataSource.demo,
      payload: {},
    );
    expect(bare.aprs, isEmpty);
    expect(bare.nextPaymentDueDate, isNull);
  });
}
