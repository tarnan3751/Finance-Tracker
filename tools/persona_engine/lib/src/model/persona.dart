/// A persona: a household described as data. The generator has one code path per kind of
/// spec, never one per persona; a persona is only a choice of values.
///
/// Amounts are `Money` or integer minor units in the account's currency, rates are basis
/// points (625 is 6.25 %), and shapes are per-mille weights (1000 is "as usual"). Nothing
/// here is a `double`.
///
/// A household is defined relative to its as-of date: loan originations and the
/// brokerage's opening are months before as-of, never calendar dates, so the household has
/// the same shape on any date. Cadences (`Monthly(1)`, a biweekly Friday, the tax dates)
/// are calendar patterns, as in life.
library;

import 'package:meta/meta.dart';
import 'package:persona_engine/src/model/schedule.dart';
import 'package:shared_models/shared_models.dart';

/// The four personas, by their CLI and file names.
enum PersonaId {
  renter('renter'),
  family('family'),
  student('student'),
  smallBusiness('small_business');

  const PersonaId(this.slug);

  /// The name used on the command line, in ids and in file names.
  final String slug;

  /// The persona whose [slug] is [slug].
  static PersonaId fromSlug(String slug) => values.firstWhere(
    (p) => p.slug == slug,
    orElse: () => throw ArgumentError.value(slug, 'persona', 'unknown persona'),
  );
}

/// One of Plaid's non-OAuth Sandbox test institutions. Each is one Item, and so one
/// Sandbox custom user, in the Sandbox outputs.
@immutable
final class InstitutionSpec {
  /// An institution.
  const InstitutionSpec(this.key, this.plaidId, this.name);

  /// The persona-local key, used in ids and file names.
  final String key;

  /// Plaid's institution id, such as `ins_109508`.
  final String plaidId;

  /// Plaid's display name.
  final String name;
}

/// An account.
@immutable
final class AccountSpec {
  /// An account. [opening] is a depository or card account's balance the day before the
  /// window starts, in the domain's sign (a card balance owed is negative). A loan's and
  /// an investment account's opening are derived by replaying their history from their
  /// start, so they leave it null.
  const AccountSpec({
    required this.key,
    required this.institution,
    required this.type,
    required this.subtype,
    required this.name,
    required this.officialName,
    required this.mask,
    this.opening,
    this.creditLimit,
    this.apyBasisPoints,
    this.coverFrom,
  });

  /// The persona-local key.
  final String key;

  /// The [InstitutionSpec.key] that holds it.
  final String institution;

  /// The domain type.
  final AccountType type;

  /// Plaid's subtype string, such as `checking` or `credit card`.
  final String subtype;

  /// The display name.
  final String name;

  /// The institution's official name.
  final String officialName;

  /// The last digits of the number.
  final String mask;

  /// The balance before the first day of the window; null for a loan or investment
  /// account.
  final Money? opening;

  /// A card's credit limit.
  final Money? creditLimit;

  /// A savings account's annual yield in basis points, paid monthly on the last day.
  final int? apyBasisPoints;

  /// The account that tops this one up when a day would end below zero.
  final String? coverFrom;

  /// Plaid rejects `/sandbox/transactions/create` on student loan accounts (`PLAN.md` §4),
  /// so their transactions always go in the custom user.
  bool get acceptsInjection =>
      !(type == AccountType.loan && subtype == 'student');
}

/// The name a transaction carries: [raw] is the description as an institution writes it
/// (strings Plaid recognizes, `PLAN.md` §7.1 rule 4), [merchant] the normalized merchant
/// name (null for transfers), [detailed] a Plaid v2 detailed category code.
@immutable
final class Payee {
  /// A payee.
  const Payee(this.raw, this.merchant, this.detailed);

  /// The raw description.
  final String raw;

  /// The normalized merchant name.
  final String? merchant;

  /// The detailed category.
  final String detailed;
}

/// A merchant in a spending pool: one of [raw] descriptions is drawn per purchase.
@immutable
final class Merchant {
  /// A merchant; [minMinor] and [maxMinor] bound a purchase, in minor units.
  const Merchant(
    this.raw,
    this.name,
    this.detailed,
    this.minMinor,
    this.maxMinor, {
    this.weight = 1,
  });

  /// The raw descriptions, such as store-numbered variants.
  final List<String> raw;

  /// The normalized name; null where the description names no merchant.
  final String? name;

  /// The detailed category.
  final String detailed;

  /// The smallest purchase.
  final int minMinor;

  /// The largest purchase.
  final int maxMinor;

  /// The relative chance of this merchant within its pool.
  final int weight;
}

/// Money coming in from outside the household: payroll, gig payouts, a parent's transfer.
@immutable
final class IncomeSpec {
  /// An income stream. [varianceBasisPoints] spreads each amount uniformly around
  /// [amount]; [skipPermille] is the chance an occurrence does not happen (gig work), and
  /// a stream that can skip is not a recurring expectation.
  const IncomeSpec({
    required this.key,
    required this.account,
    required this.payer,
    required this.schedule,
    required this.amount,
    this.varianceBasisPoints = 0,
    this.skipPermille = 0,
  });

  /// The persona-local key.
  final String key;

  /// The account paid into.
  final String account;

  /// Who pays.
  final Payee payer;

  /// When.
  final Schedule schedule;

  /// The usual amount, positive.
  final Money amount;

  /// The spread, in basis points of [amount].
  final int varianceBasisPoints;

  /// The chance an occurrence is skipped.
  final int skipPermille;
}

/// A fixed outflow: rent, a utility, insurance, a subscription, an estimated tax payment.
@immutable
final class BillSpec {
  /// A bill. [seasonal] scales the amount by month (twelve per-mille weights), for
  /// utilities.
  const BillSpec({
    required this.key,
    required this.account,
    required this.payee,
    required this.schedule,
    required this.amount,
    this.varianceBasisPoints = 0,
    this.seasonal,
  });

  /// The persona-local key.
  final String key;

  /// The account charged.
  final String account;

  /// Who is paid.
  final Payee payee;

  /// When.
  final Schedule schedule;

  /// The usual amount, positive.
  final Money amount;

  /// The spread, in basis points.
  final int varianceBasisPoints;

  /// The monthly scale, January first.
  final List<int>? seasonal;
}

/// Day-to-day spending in one pool of merchants.
@immutable
final class SpendingSpec {
  /// A spending stream: [rateMilli] purchases per thousand days on an average day, scaled
  /// by [weekly] (Monday first) and [seasonal] (January first). Card purchases post up to
  /// [postLagDays] after the purchase.
  const SpendingSpec({
    required this.key,
    required this.account,
    required this.merchants,
    required this.rateMilli,
    required this.weekly,
    required this.seasonal,
    this.postLagDays = 0,
  });

  /// The persona-local key.
  final String key;

  /// The account charged.
  final String account;

  /// The merchant pool.
  final List<Merchant> merchants;

  /// Purchases per thousand days.
  final int rateMilli;

  /// The weekly shape, seven per-mille weights.
  final List<int> weekly;

  /// The seasonal shape, twelve per-mille weights.
  final List<int> seasonal;

  /// The most days a purchase takes to post.
  final int postLagDays;
}

/// The kind of an amortizing loan, which picks its categories and its liability record.
enum LoanKind { mortgage, auto, student }

/// An amortizing loan, originated [originationMonthsBefore] months before the as-of date.
/// On each [schedule] date after origination the month's interest is charged to the loan
/// account (`principal x APR / 12`, rounded half-even). From [nonRepaymentMonths] after
/// origination the payment is made from [payFrom], unless the loan is [deferred]: the
/// smallest whole-cent payment that pays the loan off by maturity, found by replaying the
/// due dates. The principal falls by the payment less the interest; a paid-off loan stays
/// at zero. A deferred loan only accrues, and grows by its disbursements.
@immutable
final class LoanSpec {
  /// A loan.
  const LoanSpec({
    required this.key,
    required this.account,
    required this.kind,
    required this.schedule,
    required this.aprBasisPoints,
    required this.originationMonthsBefore,
    required this.originationPrincipal,
    required this.termMonths,
    required this.loanName,
    this.deferred = false,
    this.payFrom,
    this.paymentPayee,
    this.nonRepaymentMonths = 0,
  });

  /// The persona-local key.
  final String key;

  /// The loan account.
  final String account;

  /// The kind.
  final LoanKind kind;

  /// The due dates.
  final Schedule schedule;

  /// The annual rate in basis points.
  final int aprBasisPoints;

  /// How many months before the as-of date the loan was made.
  final int originationMonthsBefore;

  /// How much was lent.
  final Money originationPrincipal;

  /// The term.
  final int termMonths;

  /// The servicer's name for the loan.
  final String loanName;

  /// Whether the loan is in deferment for its whole life in the window: no payments.
  final bool deferred;

  /// The account the payment comes from.
  final String? payFrom;

  /// The payment's description on [payFrom].
  final Payee? paymentPayee;

  /// A student loan's months before repayment began.
  final int nonRepaymentMonths;
}

/// A student loan disbursement into checking on [schedule] dates after the loan's
/// origination. When [paysOut] is set, the same day pays [paysOutAmount] from checking to
/// it (tuition), so the payment never falls in a window without its disbursement.
@immutable
final class DisbursementSpec {
  /// A disbursement stream.
  const DisbursementSpec({
    required this.key,
    required this.loan,
    required this.to,
    required this.schedule,
    required this.amount,
    required this.payee,
    this.paysOut,
    this.paysOutAmount,
  });

  /// The persona-local key.
  final String key;

  /// The loan account that grows.
  final String loan;

  /// The account paid into.
  final String to;

  /// When.
  final Schedule schedule;

  /// How much.
  final Money amount;

  /// The description on both legs.
  final Payee payee;

  /// Who the disbursement pays on the same day.
  final Payee? paysOut;

  /// How much it pays.
  final Money? paysOutAmount;
}

/// How a card's statement is paid.
@immutable
final class CardSpec {
  /// A card: the statement closes on [closeDay] (1 to 28) and is paid [dueAfterDays]
  /// later from [payFrom]. [payBasisPoints] of the statement is paid (10000 pays in full),
  /// never less than the minimum of [minimumBasisPoints] with a floor of [minimumFloor],
  /// and never leaving [payFrom] below [keepAbove] unless the minimum requires it. A
  /// statement not paid in full is charged interest at the next close.
  const CardSpec({
    required this.account,
    required this.payFrom,
    required this.closeDay,
    required this.dueAfterDays,
    required this.payBasisPoints,
    required this.aprBasisPoints,
    required this.minimumBasisPoints,
    required this.minimumFloor,
    required this.keepAbove,
    required this.paymentPayee,
  });

  /// The card account.
  final String account;

  /// The account that pays.
  final String payFrom;

  /// The statement's closing day.
  final int closeDay;

  /// Days from close to payment.
  final int dueAfterDays;

  /// The share of the statement paid, in basis points.
  final int payBasisPoints;

  /// The purchase APR.
  final int aprBasisPoints;

  /// The minimum payment's share of the statement.
  final int minimumBasisPoints;

  /// The minimum payment's floor.
  final Money minimumFloor;

  /// The balance [payFrom] keeps when it can.
  final Money keepAbove;

  /// The description on [payFrom].
  final Payee paymentPayee;
}

/// A transfer between two of the household's accounts: savings, an owner's draw. When
/// [sweepAbove] is set, any balance above it moves too.
@immutable
final class TransferSpec {
  /// A transfer, skipped when it would leave [from] below [keepAbove].
  const TransferSpec({
    required this.key,
    required this.from,
    required this.to,
    required this.schedule,
    required this.amount,
    required this.keepAbove,
    required this.outPayee,
    required this.inPayee,
    this.sweepAbove,
  });

  /// The persona-local key.
  final String key;

  /// The account paying.
  final String from;

  /// The account receiving.
  final String to;

  /// When.
  final Schedule schedule;

  /// The fixed amount.
  final Money amount;

  /// The balance [from] keeps.
  final Money keepAbove;

  /// The description on [from].
  final Payee outPayee;

  /// The description on [to].
  final Payee inPayee;

  /// The balance above which everything is swept.
  final Money? sweepAbove;
}

/// A security in a brokerage spec, with its deterministic daily price walk: each day the
/// price moves by [driftBasisPoints] plus a uniform draw in `±[stepBasisPoints]`.
@immutable
final class SecuritySpec {
  /// A security.
  const SecuritySpec({
    required this.ticker,
    required this.name,
    required this.startPrice,
    required this.driftBasisPoints,
    required this.stepBasisPoints,
    required this.weight,
  });

  /// The ticker symbol.
  final String ticker;

  /// The display name.
  final String name;

  /// The price on the day the account opened.
  final Money startPrice;

  /// The daily drift.
  final int driftBasisPoints;

  /// The largest daily move.
  final int stepBasisPoints;

  /// The share of each contribution, relative to the others.
  final int weight;
}

/// A retirement account fed by payroll deduction: no checking leg, a `cash` contribution
/// and one `buy` per security on each [schedule] date. It opened [openedMonthsBefore]
/// months before the as-of date with [rollover] invested; prices walk daily from
/// [SecuritySpec.startPrice] on that day, so the position on any date does not depend on
/// the window.
@immutable
final class BrokerageSpec {
  /// A brokerage stream.
  const BrokerageSpec({
    required this.account,
    required this.schedule,
    required this.contribution,
    required this.openedMonthsBefore,
    required this.rollover,
    required this.securities,
  });

  /// The investment account.
  final String account;

  /// When contributions happen.
  final Schedule schedule;

  /// Each contribution.
  final Money contribution;

  /// How many months before the as-of date the account opened.
  final int openedMonthsBefore;

  /// The rollover invested on the day it opened.
  final Money rollover;

  /// What is bought.
  final List<SecuritySpec> securities;
}

/// The owner's identity in the Sandbox custom user. Fictional throughout.
@immutable
final class IdentitySpec {
  /// An identity.
  const IdentitySpec({
    required this.names,
    required this.phone,
    required this.email,
    required this.street,
    required this.city,
    required this.region,
    required this.postalCode,
  });

  /// The account holders' names.
  final List<String> names;

  /// A `555` phone number.
  final String phone;

  /// An `example.com` address.
  final String email;

  /// The street.
  final String street;

  /// The city.
  final String city;

  /// The region.
  final String region;

  /// The postal code.
  final String postalCode;
}

/// A household.
@immutable
final class Persona {
  /// A persona. Lists are in the order the generator walks them; that order is part of
  /// the output, so appending is safe and reordering changes every golden.
  const Persona({
    required this.id,
    required this.currency,
    required this.identity,
    required this.institutions,
    required this.accounts,
    this.incomes = const [],
    this.bills = const [],
    this.subscriptions = const [],
    this.loans = const [],
    this.disbursements = const [],
    this.cards = const [],
    this.transfers = const [],
    this.spending = const [],
    this.brokerage,
    required this.anomalyAccount,
    required this.anomalyMerchants,
  });

  /// Which persona.
  final PersonaId id;

  /// The household's currency.
  final String currency;

  /// The owner's identity.
  final IdentitySpec identity;

  /// The institutions, one Item each.
  final List<InstitutionSpec> institutions;

  /// The accounts.
  final List<AccountSpec> accounts;

  /// Income from outside.
  final List<IncomeSpec> incomes;

  /// Fixed bills.
  final List<BillSpec> bills;

  /// Subscriptions: bills that are recognizable subscription merchants.
  final List<BillSpec> subscriptions;

  /// Loans.
  final List<LoanSpec> loans;

  /// Student loan disbursements.
  final List<DisbursementSpec> disbursements;

  /// Card statements.
  final List<CardSpec> cards;

  /// Transfers between the household's accounts.
  final List<TransferSpec> transfers;

  /// Variable spending.
  final List<SpendingSpec> spending;

  /// The retirement account, if any.
  final BrokerageSpec? brokerage;

  /// The account a new-merchant anomaly is charged to.
  final String anomalyAccount;

  /// One-off merchants for new-merchant anomalies: distinct, and sharing no name or raw
  /// description with any regular merchant or payee of the household.
  final List<Merchant> anomalyMerchants;

  /// The account whose key is [key].
  AccountSpec account(String key) => accounts.firstWhere(
    (a) => a.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'no such account'),
  );

  /// The institution whose key is [key].
  InstitutionSpec institution(String key) =>
      institutions.firstWhere((i) => i.key == key);
}
