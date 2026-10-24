/// Plaid Sandbox custom users: the configuration `/sandbox/public_token/create` takes as
/// `options.override_password` with `override_username: user_custom`, one per institution.
///
/// The shape is Plaid's documented `UserCustomPassword` schema
/// (https://plaid.com/docs/sandbox/user-custom/). The rules the engine applies:
/// - `roll_dates_forward: false`: Plaid would shift each Item by its own newest activity
///   date, which pulls the legs of a transfer between two Items apart. The provisioning
///   script instead shifts every date of every Item of a persona by one amount, the
///   creation date minus the as-of date (see `injection.dart`). No `inflow_model`, which
///   would add transactions of Plaid's own.
/// - Amounts in Plaid's sign: positive is money out of the account. `starting_balance` is
///   the balance on the as-of date, positive for money held in a depository or investment
///   account and for money owed on a card or loan.
/// - Every number is written from `Money.toDecimalString()` or an integer scale, never
///   through a `double`.
/// - Mortgages carry no `liability` block: the custom Sandbox does not support one.
library;

import 'package:collection/collection.dart';
import 'package:persona_engine/src/model/household.dart';
import 'package:persona_engine/src/model/investments.dart';
import 'package:persona_engine/src/model/liabilities.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:persona_engine/src/output/json_writer.dart';
import 'package:persona_engine/src/output/sandbox_split.dart';
import 'package:shared_models/shared_models.dart';

/// [money] in Plaid's number form.
JsonDecimal plaidNumber(Money money) => JsonDecimal(money.toDecimalString());

/// A transaction's amount in Plaid's sign: positive is money out.
JsonDecimal plaidAmount(Transaction t) => plaidNumber(-t.amount);

/// One institution's custom user and what it was built from.
final class SandboxUser {
  SandboxUser._(this.split, this.config);

  /// The split it carries.
  final InstitutionSplit split;

  /// The configuration object.
  final Map<String, Object?> config;
}

/// The custom users for [household], one per institution with an account.
List<SandboxUser> sandboxUsers(
  GeneratedHousehold household, {
  bool includeInterestLegs = true,
}) {
  final persona = household.persona;
  return [
    for (final split in splitForSandbox(
      household,
      includeInterestLegs: includeInterestLegs,
    ))
      _user(household, persona, split),
  ];
}

SandboxUser _user(
  GeneratedHousehold household,
  Persona persona,
  InstitutionSplit split,
) {
  final accounts = <Map<String, Object?>>[];
  for (final spec in persona.accounts) {
    if (spec.institution != split.institution.key) continue;
    final accountId = accountIdFor(persona.id, spec.key);
    final account = household.accounts.firstWhere((a) => a.id == accountId);
    final balance = account.currentBalance!;
    final owed =
        spec.type == AccountType.credit || spec.type == AccountType.loan;
    final limit = spec.creditLimit;
    final apy = spec.apyBasisPoints;
    final transactions = [
      for (final t in split.customUser)
        if (t.accountId == accountId) t,
    ];
    final json = <String, Object?>{
      'type': spec.type.name,
      'subtype': spec.subtype,
      'starting_balance': plaidNumber(owed ? -balance : balance),
      'currency': persona.currency,
      'meta': {
        'name': spec.name,
        'official_name': spec.officialName,
        'mask': spec.mask,
        if (limit != null) 'limit': plaidNumber(limit),
        if (apy != null) 'apy': scaledDecimal(apy, 2),
      },
      'identity': _identity(persona.identity),
      'transactions': [
        for (final t in transactions)
          {
            'date_transacted': t.authorizedDate!.toIso(),
            'date_posted': t.date.toIso(),
            'amount': plaidAmount(t),
            'description': t.name,
            'currency': t.amount.currencyCode,
          },
      ],
    };
    if (spec.type == AccountType.investment) {
      final holdings = [
        for (final h in household.holdings)
          if (h.accountId == accountId) h,
      ];
      final buys = [
        for (final t in household.investmentTransactions)
          if (t.accountId == accountId &&
              t.type == InvestmentTransactionType.buy)
            t,
      ];
      final kept = buys.sublist(
        buys.length > customUserInvestmentTransactionBudget
            ? buys.length - customUserInvestmentTransactionBudget
            : 0,
      );
      json['holdings'] = [for (final h in holdings) _holding(h)];
      json['investment_transactions'] = [
        for (final t in kept) _investmentTransaction(t),
      ];
    }
    final liability = household.liabilities.firstWhereOrNull(
      (l) => l.accountId == accountId,
    );
    final liabilityJson = liability == null ? null : _liability(liability);
    if (liabilityJson != null) json['liability'] = liabilityJson;
    accounts.add(json);
  }
  return SandboxUser._(split, {
    'version': 2,
    'seed': '${persona.id.slug}-${household.seed}-${split.institution.key}',
    'roll_dates_forward': false,
    'override_accounts': accounts,
  });
}

Map<String, Object?> _identity(IdentitySpec identity) => {
  'names': identity.names,
  'phone_numbers': [
    {'data': identity.phone, 'primary': true, 'type': 'mobile'},
  ],
  'emails': [
    {'data': identity.email, 'primary': true, 'type': 'primary'},
  ],
  'addresses': [
    {
      'data': {
        'city': identity.city,
        'region': identity.region,
        'street': identity.street,
        'postal_code': identity.postalCode,
        'country': 'US',
      },
      'primary': true,
    },
  ],
};

Map<String, Object?> _security(Security s) => {
  'ticker_symbol': s.ticker,
  'name': s.name,
  'currency': s.currencyCode,
};

Map<String, Object?> _holding(Holding h) => {
  'institution_price': plaidNumber(h.price),
  'institution_price_as_of': h.priceAsOf.toIso(),
  'cost_basis': plaidNumber(h.costBasis),
  'quantity': scaledDecimal(h.quantityMilli, 3),
  'currency': h.price.currencyCode,
  'security': _security(h.security),
};

Map<String, Object?> _investmentTransaction(InvestmentTransaction t) => {
  'date': t.date.toIso(),
  'name': t.name,
  'quantity': scaledDecimal(t.quantityMilli, 3),
  'price': plaidNumber(t.price!),
  'fees': JsonDecimal('0'),
  'type': t.type.name,
  'currency': t.amount.currencyCode,
  'security': _security(t.security!),
};

/// The liability block; null for a mortgage.
Map<String, Object?>? _liability(Liability liability) {
  switch (liability) {
    case final CreditLiability c:
      final last = c.lastPaymentAmount;
      return {
        'type': 'credit',
        'purchase_apr': scaledDecimal(c.aprBasisPoints, 2),
        if (last != null) 'last_payment_amount': plaidNumber(last),
        'last_statement_balance': plaidNumber(c.lastStatementBalance),
        'minimum_payment_amount': plaidNumber(c.minimumPayment),
        'is_overdue': false,
      };
    case final LoanLiability l when l.kind == LoanKind.mortgage:
      return null;
    case final LoanLiability l when l.kind == LoanKind.student:
      final next = l.nextPaymentAmount;
      return {
        'type': 'student',
        'origination_date': l.originationDate.toIso(),
        'principal': plaidNumber(l.originationPrincipal),
        'nominal_apr': scaledDecimal(l.aprBasisPoints, 2),
        'loan_name': l.loanName,
        'repayment_model': {
          'type': 'standard',
          'non_repayment_months': l.nonRepaymentMonths,
          'repayment_months': l.termMonths - l.nonRepaymentMonths,
        },
        'is_federal': true,
        if (next != null) 'minimum_payment_amount': plaidNumber(next),
      };
    case final LoanLiability l:
      final lastDate = l.lastPaymentDate;
      final lastAmount = l.lastPaymentAmount;
      final next = l.nextPaymentAmount;
      final nextDue = l.nextPaymentDueDate;
      return {
        'type': 'loan',
        'interest_rate': {
          'percentage': scaledDecimal(l.aprBasisPoints, 2),
          'type': 'fixed',
        },
        'principal_balance': plaidNumber(l.principalBalance),
        'origination_principal_amount': plaidNumber(l.originationPrincipal),
        'loan_term_months': l.termMonths,
        'maturity_date': l.maturityDate.toIso(),
        'payment_frequency': 'monthly',
        if (next != null) 'next_payment_amount': plaidNumber(next),
        if (nextDue != null) 'next_payment_due_date': nextDue.toIso(),
        if (lastDate != null) 'last_payment_date': lastDate.toIso(),
        if (lastAmount != null) 'last_payment_amount': plaidNumber(lastAmount),
        'ytd_interest_paid': plaidNumber(l.ytdInterestPaid),
      };
  }
}
