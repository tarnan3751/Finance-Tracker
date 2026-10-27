/// Which recurring streams are subscriptions (`docs/reference/recurring.md`,
/// **Subscriptions**; `PLAN.md` §12, "Recurring streams"). Plaid does not say, so the app
/// classifies every stream, Plaid's, the demo's and the detector's alike; the user's
/// override (`stream_overrides`) wins over the result. Pure Dart.
///
/// A stream is a subscription when all of these hold:
///
/// - it is an outflow;
/// - its amount is stable: its band ([StreamBand], from its member transactions) is within
///   5 % of its median, or its source already flags it a subscription;
/// - its cadence is weekly, monthly or annual (biweekly and semimonthly are pay-like);
/// - its category (the most common effective category of its members, [streamCategory])
///   is not under one of [nonSubscriptionCodes]: rent and utilities (`RENT_AND_UTILITIES`),
///   mortgages and other loan payments (`LOAN_PAYMENTS`), transfers (`TRANSFER_IN`,
///   `TRANSFER_OUT`), income (`INCOME`) or taxes
///   (`GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT`). A category with no Plaid code (the user's
///   own) is never excluded.
library;

import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:shared_models/shared_models.dart';

/// The Plaid codes, primary or detailed, whose categories (and their detailed ones) are
/// never subscriptions.
const List<String> nonSubscriptionCodes = [
  'RENT_AND_UTILITIES',
  'LOAN_PAYMENTS',
  'TRANSFER_IN',
  'TRANSFER_OUT',
  'INCOME',
  'GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT',
];

/// The band a subscription's amounts stay within, in basis points of the median.
const int subscriptionBandBasisPoints = 500;

/// Whether [stream] is a subscription, its members' category being [effectiveCategory]
/// and their band [band] (null when none of them is known: then only the stream's own
/// flag shows a stable amount).
bool isSubscription(
  RecurringStream stream, {
  required Category? effectiveCategory,
  required StreamBand? band,
}) {
  if (!stream.averageAmount.isNegative) return false;
  final bool stable =
      stream.isSubscription ||
      (band?.isWithin(subscriptionBandBasisPoints) ?? false);
  if (!stable) return false;
  if (!const {
    RecurringCadence.weekly,
    RecurringCadence.monthly,
    RecurringCadence.annually,
  }.contains(stream.cadence)) {
    return false;
  }
  final String? code = effectiveCategory?.plaidCategory;
  return code == null ||
      !nonSubscriptionCodes.any((c) => code == c || code.startsWith('${c}_'));
}

/// The category of a stream with [members]: their most common effective category, a tie
/// going to the newest member's (by date, then id); null when none is a member or the
/// most common is "Uncategorized".
Category? streamCategory(Iterable<Transaction> members, CategoryLookup lookup) {
  final List<Transaction> newestFirst = members.toList()
    ..sort((a, b) {
      final int byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
  final Map<String?, int> counts = {};
  final List<Category?> categories = [
    for (final Transaction t in newestFirst) effectiveCategory(t, lookup),
  ];
  for (final Category? c in categories) {
    counts[c?.id] = (counts[c?.id] ?? 0) + 1;
  }
  Category? best;
  int bestCount = 0;
  for (final Category? c in categories) {
    if (counts[c?.id]! > bestCount) {
      best = c;
      bestCount = counts[c?.id]!;
    }
  }
  return best;
}
