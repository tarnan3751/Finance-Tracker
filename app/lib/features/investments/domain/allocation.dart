/// The holdings' allocation by security type and a holding's gain
/// (`docs/reference/investments.md`, **The segment**), in integer `Money` only: every
/// value is the institution's `institutionValue`, never a price times a quantity.
library;

import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:shared_models/shared_models.dart';

/// The key a holding of [security] is allocated under: `cash` for a cash equivalent,
/// else its security's type trimmed and in lower case (Plaid's open string: `etf`,
/// `equity`, `mutual fund`, ...), `other` when there is none or no security.
String allocationKey(Security? security) {
  if (security == null) return 'other';
  if (security.isCashEquivalent ?? false) return 'cash';
  final String type = security.type?.trim().toLowerCase() ?? '';
  return type.isEmpty ? 'other' : type;
}

/// One security type's part of an [Allocation]: its [key] (`allocationKey`) and the
/// summed value of its holdings.
typedef AllocationSlice = ({String key, Money value});

/// The holdings of one currency by security type: [total] is every holding's value,
/// [slices] each type's, the largest first (by key on a tie).
typedef Allocation = ({Money total, List<AllocationSlice> slices});

/// [holdings] allocated by security type, one [Allocation] per currency of their values,
/// by currency code.
List<Allocation> allocationOf(List<HoldingView> holdings) {
  final Map<String, Map<String, Money>> byCurrency = {};
  for (final HoldingView view in holdings) {
    final Money value = view.holding.institutionValue;
    final Map<String, Money> byKey = byCurrency.putIfAbsent(
      value.currencyCode,
      () => {},
    );
    final String key = allocationKey(view.security);
    byKey[key] = (byKey[key] ?? Money.zero(value.currencyCode)) + value;
  }
  return [
    for (final String currency in byCurrency.keys.toList()..sort())
      () {
        final Map<String, Money> byKey = byCurrency[currency]!;
        final List<AllocationSlice> slices =
            [
              for (final MapEntry(:key, :value) in byKey.entries)
                (key: key, value: value),
            ]..sort((a, b) {
              final int byValue = b.value.compareTo(a.value);
              return byValue != 0 ? byValue : a.key.compareTo(b.key);
            });
        return (
          total: Money.sum(byKey.values, currencyCode: currency),
          slices: slices,
        );
      }(),
  ];
}

/// [part]'s share of [total] in basis points, rounded toward zero; null when [total] is
/// not positive.
int? shareBasisPoints(Money part, Money total) => total.isPositive
    ? part
          .multipliedBy(10000, total.minorUnits, mode: RoundingMode.down)
          .minorUnits
    : null;

/// A holding's gain: its value less its cost basis, and that as basis points of the cost
/// basis (rounded toward zero; null when the cost basis is not positive).
typedef Gain = ({Money amount, int? basisPoints});

/// [holding]'s gain, or null when the institution reports no cost basis.
Gain? gainOf(Holding holding) {
  final Money? cost = holding.costBasis;
  if (cost == null) return null;
  final Money amount = holding.institutionValue - cost;
  return (amount: amount, basisPoints: shareBasisPoints(amount, cost));
}
