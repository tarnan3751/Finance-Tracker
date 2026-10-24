/// One entry of Plaid's personal-finance category taxonomy; the entries themselves are
/// generated into `plaid_taxonomy.dart`.
library;

import 'package:meta/meta.dart';

/// A Plaid personal-finance category: a [detailed] code under a [primary] code, as
/// returned in a transaction's `personal_finance_category`.
@immutable
final class PlaidCategory {
  /// A category entry.
  const PlaidCategory({
    required this.primary,
    required this.detailed,
    required this.description,
  });

  /// The primary code, such as `FOOD_AND_DRINK`.
  final String primary;

  /// The detailed code, such as `FOOD_AND_DRINK_GROCERIES`; it starts with [primary].
  final String detailed;

  /// Plaid's description of the category; empty where Plaid gives none.
  final String description;

  @override
  bool operator ==(Object other) =>
      other is PlaidCategory &&
      other.primary == primary &&
      other.detailed == detailed &&
      other.description == description;

  @override
  int get hashCode => Object.hash(primary, detailed, description);

  @override
  String toString() => detailed;
}
