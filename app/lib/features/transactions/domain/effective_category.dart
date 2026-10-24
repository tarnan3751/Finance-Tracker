/// The category a transaction is shown and filtered under: the user's own choice, else
/// the system category seeded from its Plaid code (`PLAN.md` §12, effective category).
/// Pure Dart.
///
/// The resolution is display-side only: it never writes `userCategoryId`, which stays the
/// user's explicit choice, so sync and the override rules see only what the user did.
library;

import 'package:shared_models/shared_models.dart';

/// The live categories a transaction's category is looked up in: [byId], and
/// [byPlaidCode], keyed by each category's `plaidCategory`.
typedef CategoryLookup = ({
  Map<String, Category> byId,
  Map<String, Category> byPlaidCode,
});

/// [categories] (the live ones) as a [CategoryLookup].
CategoryLookup categoryLookup(Iterable<Category> categories) => (
  byId: {for (final Category c in categories) c.id: c},
  byPlaidCode: {
    for (final Category c in categories)
      if (c.plaidCategory case final String code) code: c,
  },
);

/// The effective category of [transaction]: its user category when that is live, else
/// [plaidCategoryOf] it; null ("Uncategorized") when neither resolves. A user category
/// that is deleted or unknown counts as unset.
Category? effectiveCategory(Transaction transaction, CategoryLookup lookup) =>
    lookup.byId[transaction.userCategoryId] ??
    plaidCategoryOf(transaction, lookup.byPlaidCode);

/// The category [transaction]'s Plaid codes resolve to, whatever its user category: the
/// one whose `plaidCategory` is its detailed code, else the one whose `plaidCategory` is
/// its primary code, else null.
Category? plaidCategoryOf(
  Transaction transaction,
  Map<String, Category> byPlaidCode,
) =>
    byPlaidCode[transaction.plaidDetailedCategory] ??
    byPlaidCode[transaction.plaidPrimaryCategory];
