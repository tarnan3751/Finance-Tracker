// The contract's liability objects read into the entity: each kind's fields, the rates
// in basis points rounded half to even, the object kept whole as the payload.
import 'package:finance_tracker/core/api/api_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  test(
    'a Decimal percentage in basis points, half to even past two places',
    () {
      expect(
        {
          for (final String p in [
            '0',
            '12.5',
            '15.24',
            '24.99',
            '3.875',
            '3.885',
            '3.8851',
            '3.8749',
            '6.00500',
            '7',
            '-1.25',
          ])
            p: basisPointsOf(p),
        },
        {
          '0': 0,
          '12.5': 1250,
          '15.24': 1524,
          '24.99': 2499,
          '3.875': 388,
          '3.885': 388,
          '3.8851': 389,
          '3.8749': 387,
          '6.00500': 600,
          '7': 700,
          '-1.25': -125,
        },
      );
      for (final String bad in ['', '1.', '.5', '01', 'ten', '1e3']) {
        expect(() => basisPointsOf(bad), throwsFormatException, reason: bad);
      }
    },
  );

  test('each kind reads into the entity with its fields and its payload', () {
    final Map<String, Object?> json = {
      'credit': [
        {
          'account_id': 'card',
          'source': 'plaid',
          'aprs': [
            {
              'apr_percentage': '15.24',
              'apr_type': 'purchase_apr',
              'balance_subject_to_apr': {
                'minor_units': 141066,
                'currency': 'USD',
              },
              'interest_charge_amount': null,
            },
          ],
          'is_overdue': false,
          'last_payment_amount': {'minor_units': 16820, 'currency': 'USD'},
          'last_payment_date': '2026-09-16',
          'last_statement_issue_date': '2026-09-28',
          'last_statement_balance': {'minor_units': 170847, 'currency': 'USD'},
          'minimum_payment_amount': {'minor_units': 2000, 'currency': 'USD'},
          'next_payment_due_date': '2026-10-28',
        },
      ],
      'mortgage': [
        {
          'account_id': 'home',
          'source': 'demo',
          'loan_type_description': 'conventional',
          'loan_term': '30 year',
          'interest_rate_percentage': '3.875',
          'interest_rate_type': 'fixed',
          'current_late_fee': null,
          'escrow_balance': null,
          'has_pmi': false,
          'has_prepayment_penalty': false,
          'last_payment_amount': {'minor_units': 310050, 'currency': 'USD'},
          'last_payment_date': '2026-10-01',
          'maturity_date': '2049-07-01',
          'next_monthly_payment': {'minor_units': 310050, 'currency': 'USD'},
          'next_payment_due_date': '2026-11-01',
          'origination_date': '2019-06-14',
          'origination_principal_amount': {
            'minor_units': 42500000,
            'currency': 'USD',
          },
          'past_due_amount': null,
          'ytd_interest_paid': {'minor_units': 1205000, 'currency': 'USD'},
          'ytd_principal_paid': null,
        },
      ],
      'student': [
        {
          'account_id': 'loan',
          'source': 'plaid',
          'loan_name': 'Consolidation',
          'guarantor': null,
          'interest_rate_percentage': '5.25',
          'is_overdue': null,
          'expected_payoff_date': null,
          'last_payment_amount': null,
          'last_payment_date': null,
          'last_statement_balance': {'minor_units': 1200000, 'currency': 'USD'},
          'last_statement_issue_date': '2026-10-05',
          'minimum_payment_amount': {'minor_units': 15000, 'currency': 'USD'},
          'next_payment_due_date': '2026-11-05',
          'origination_date': null,
          'origination_principal_amount': null,
          'outstanding_interest_amount': null,
          'loan_status_type': 'repayment',
          'repayment_plan_type': 'standard',
          'ytd_interest_paid': null,
          'ytd_principal_paid': null,
        },
      ],
    };
    final List<Liability> all = Liabilities.fromJson(json).toEntities();
    expect(all.map((l) => (l.accountId, l.kind, l.source)), [
      ('card', LiabilityKind.credit, DataSource.plaid),
      ('home', LiabilityKind.mortgage, DataSource.demo),
      ('loan', LiabilityKind.student, DataSource.plaid),
    ]);
    final [Liability card, Liability home, Liability loan] = all;
    expect(card.aprs, [
      LiabilityApr(
        type: 'purchase_apr',
        percentageBasisPoints: 1524,
        balanceSubjectToApr: Money(141066, 'USD'),
      ),
    ]);
    expect(card.minimumPaymentAmount, Money(2000, 'USD'));
    expect(card.nextPaymentDueDate, LocalDate(2026, 10, 28));
    expect(card.isOverdue, isFalse);
    expect(card.payload, (json['credit']! as List<Object?>).single);
    expect(home.interestRateBasisPoints, 388);
    expect(home.loanTerm, '30 year');
    expect(home.nextMonthlyPayment, Money(310050, 'USD'));
    expect(home.originationPrincipal, Money(42500000, 'USD'));
    expect(home.minimumPaymentAmount, isNull);
    expect(
      home.payload['interest_rate_percentage'],
      '3.875',
      reason: 'the exact rate stays in the payload',
    );
    expect(loan.interestRateBasisPoints, 525);
    expect(loan.minimumPaymentAmount, Money(15000, 'USD'));
    expect(loan.lastStatementBalance, Money(1200000, 'USD'));
    expect(loan.payload, (json['student']! as List<Object?>).single);
  });
}
