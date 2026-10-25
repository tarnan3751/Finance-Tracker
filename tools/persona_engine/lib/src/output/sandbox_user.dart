/// Plaid Sandbox custom users: the configuration `/sandbox/public_token/create` takes as
/// `options.override_password` with `override_username: user_custom`, one per institution.
///
/// The shape is Plaid's documented `UserCustomPassword` schema
/// (https://plaid.com/docs/sandbox/user-custom/). The rules the engine applies:
/// - `roll_dates_forward: false`: Plaid would shift each Item by its own newest activity
///   date, which pulls the legs of a transfer between two Items apart. The provisioning
///   job instead shifts every date of every Item of a persona by one amount, the
///   creation date minus the as-of date ([shiftSandboxUserDates]). No `inflow_model`,
///   which would add transactions of Plaid's own.
/// - The transactions are the newest whole days that keep the configuration, as the
///   request carries it ([sandboxRequestBytes]), within `sandboxConfigByteBudget`
///   (`sandbox_split.dart`).
/// - Amounts in Plaid's sign: positive is money out of the account. `starting_balance` is
///   the balance on the as-of date, positive for money held in a depository or investment
///   account and for money owed on a card or loan.
/// - Every number is written from `Money.toDecimalString()` or an integer scale, never
///   through a `double`.
/// - Only cards and student loans carry a `liability` block (`credit`, `student`). Plaid
///   says mortgages are not supported in the custom Sandbox, and a block of `type: loan`
///   (an auto loan) makes `/sandbox/public_token/create` answer 500
///   `INTERNAL_SERVER_ERROR` (verified 2026-10-24, `PLAN.md` §4: the same configuration
///   without it is accepted), so every other loan kind emits none. The demo seed keeps
///   every liability.
///
/// [shiftSandboxUserDates] applies the provisioning job's one date shift to a
/// configuration.
library;

import 'dart:convert';

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
}) => [
  for (final split in splitForSandbox(
    household,
    includeInterestLegs: includeInterestLegs,
    fits: (institution, carried) =>
        sandboxRequestBytes(
          sandboxUserConfig(household, institution, carried),
        ) <=
        sandboxConfigByteBudget,
  ))
    SandboxUser._(
      split,
      sandboxUserConfig(household, split.institution, split.customUser),
    ),
];

/// The bytes [config] takes in a `/sandbox/public_token/create` request: the UTF-8
/// length of its compact JSON, written as the JSON string `override_password` is, quotes
/// and escapes included.
int sandboxRequestBytes(Map<String, Object?> config) =>
    utf8.encode(jsonEncode(writeJson(config, pretty: false))).length;

/// The configuration of [institution]'s custom user carrying [carried] (in id order),
/// with every account, holding, liability and identity of the institution.
Map<String, Object?> sandboxUserConfig(
  GeneratedHousehold household,
  InstitutionSpec institution,
  List<Transaction> carried,
) {
  final persona = household.persona;
  final accounts = <Map<String, Object?>>[];
  for (final spec in persona.accounts) {
    if (spec.institution != institution.key) continue;
    final accountId = accountIdFor(persona.id, spec.key);
    final account = household.accounts.firstWhere((a) => a.id == accountId);
    final balance = account.currentBalance!;
    final owed =
        spec.type == AccountType.credit || spec.type == AccountType.loan;
    final limit = spec.creditLimit;
    final apy = spec.apyBasisPoints;
    final transactions = [
      for (final t in carried)
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
  return {
    'version': 2,
    'seed': '${persona.id.slug}-${household.seed}-${institution.key}',
    'roll_dates_forward': false,
    'override_accounts': accounts,
  };
}

/// The custom user's file name.
String sandboxUserFileName(SandboxUser user) =>
    'sandbox_user_${user.split.institution.key}.json';

/// Every key whose value is a calendar date in a custom-user configuration.
const sandboxUserDateKeys = {
  'date_transacted',
  'date_posted',
  'date',
  'institution_price_as_of',
  'origination_date',
  'maturity_date',
  'next_payment_due_date',
  'last_payment_date',
};

/// [config] (a [SandboxUser.config]) with every date moved [days] days: the provisioning
/// job's one shift, the Item creation day minus the as-of date, for every Item of a
/// persona alike (`docs/reference/persona.md`, **Dates in Sandbox**). Nothing else
/// changes; [config] itself is left as it was.
Map<String, Object?> shiftSandboxUserDates(
  Map<String, Object?> config,
  int days,
) {
  Object? walk(Object? node) => switch (node) {
    final Map<String, Object?> map => {
      for (final MapEntry(:key, :value) in map.entries)
        key: sandboxUserDateKeys.contains(key) && value is String
            ? LocalDate.parse(value).addDays(days).toIso()
            : walk(value),
    },
    final List<Object?> list => [for (final e in list) walk(e)],
    _ => node,
  };
  return walk(config)! as Map<String, Object?>;
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

/// The liability block: a card's or a student loan's; null for every other loan kind.
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
    case LoanLiability():
      return null;
  }
}
