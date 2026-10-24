/// Holdings and investment transactions, which `shared_models` does not model yet.
///
/// Quantities are integer thousandths of a share; prices and amounts are `Money`. Values
/// are known only on the as-of date: the engine never emits a value history (`PLAN.md`
/// §7.1, tier C).
library;

import 'package:meta/meta.dart';
import 'package:shared_models/shared_models.dart';

/// A security.
@immutable
final class Security {
  /// A security, identified by [ticker].
  const Security(this.ticker, this.name, this.currencyCode);

  /// The ticker symbol.
  final String ticker;

  /// The display name.
  final String name;

  /// The trading currency.
  final String currencyCode;

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'ticker': ticker,
    'name': name,
    'currency': currencyCode,
  };
}

/// A position on the as-of date.
@immutable
final class Holding {
  /// A holding. [quantityMilli] is in thousandths of a share; [costBasis] is the total
  /// paid for it.
  const Holding({
    required this.accountId,
    required this.security,
    required this.quantityMilli,
    required this.costBasis,
    required this.price,
    required this.priceAsOf,
  });

  /// The investment account.
  final String accountId;

  /// What is held.
  final Security security;

  /// Thousandths of a share.
  final int quantityMilli;

  /// The total cost.
  final Money costBasis;

  /// The price on [priceAsOf].
  final Money price;

  /// The as-of date.
  final LocalDate priceAsOf;

  /// The value at [price], rounded half-even to the minor unit.
  Money get value => price.multipliedBy(quantityMilli, 1000);

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'account_id': accountId,
    'security': security.toJson(),
    'quantity_milli': quantityMilli,
    'cost_basis': costBasis.toJson(),
    'price': price.toJson(),
    'price_as_of': priceAsOf.toIso(),
    'value': value.toJson(),
  };
}

/// The kind of an investment transaction; Plaid's names.
enum InvestmentTransactionType { cash, buy }

/// A contribution or a purchase in an investment account.
@immutable
final class InvestmentTransaction {
  /// An investment transaction. A `cash` contribution has no security; a `buy` has a
  /// [security], [quantityMilli] and [price], and its [amount] is the cost.
  const InvestmentTransaction({
    required this.id,
    required this.accountId,
    required this.date,
    required this.name,
    required this.type,
    required this.amount,
    this.security,
    this.quantityMilli = 0,
    this.price,
    required this.source,
  });

  /// The id.
  final String id;

  /// The investment account.
  final String accountId;

  /// The date.
  final LocalDate date;

  /// The description.
  final String name;

  /// The kind.
  final InvestmentTransactionType type;

  /// The cash amount: the contribution, or the cost of the purchase.
  final Money amount;

  /// What was bought.
  final Security? security;

  /// Thousandths of a share bought.
  final int quantityMilli;

  /// The price paid.
  final Money? price;

  /// Always [DataSource.demo]: the engine never produces any other provenance.
  final DataSource source;

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'account_id': accountId,
    'date': date.toIso(),
    'name': name,
    'type': type.name,
    'amount': amount.toJson(),
    'security': security?.toJson(),
    'quantity_milli': quantityMilli,
    'price': price?.toJson(),
    'source': source.name,
  };
}
