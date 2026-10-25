/// The arithmetic of a transaction's splits as the editor enters them: amounts typed
/// without a sign, the sign being the transaction's. Splits balance when their magnitudes
/// sum exactly to the transaction's; "Distribute evenly" divides it with `Money.split`, the
/// larger parts last. Pure Dart, in `Money` only.
library;

import 'package:shared_models/shared_models.dart';

/// What of [amount]'s magnitude the split magnitudes [parts] leave unallocated: positive
/// when they fall short, negative when they exceed it, zero when they balance. Every part
/// must be in [amount]'s currency.
Money unallocated(Money amount, Iterable<Money> parts) =>
    amount.abs() - Money.sum(parts, currencyCode: amount.currencyCode);

/// Whether the split magnitudes [parts] sum exactly to [amount]'s magnitude.
bool splitsBalance(Money amount, Iterable<Money> parts) =>
    unallocated(amount, parts).isZero;

/// [amount]'s magnitude in [parts] near-equal magnitudes that sum exactly to it, each
/// within one minor unit of the others, the larger ones last (`Money.split` gives the
/// leftover units to the earlier parts; the editor's rounding lands on the last rows).
List<Money> distributeEvenly(Money amount, int parts) =>
    amount.abs().split(parts).reversed.toList();
