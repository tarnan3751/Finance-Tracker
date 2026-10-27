/// The pulled streams and the detected ones as one list (`docs/reference/recurring.md`,
/// **Merging**; `PLAN.md` §12, "Recurring streams"). Pure Dart.
///
/// Every pulled stream (`plaid` or `demo`) is kept. A detected stream is dropped when
/// any of its transaction ids is a pulled stream's (the bank already reports it), or
/// when a pulled stream that lists no transaction ids is on its account with its
/// merchant (both names normalized as the enrichment fallback compares them), since then
/// the overlap cannot be seen. The rest are appended, and the list is sorted by merchant
/// name, then id.
library;

import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:shared_models/shared_models.dart';

/// [pulled] with the [detected] streams they do not already cover.
List<RecurringStream> mergeStreams(
  List<RecurringStream> pulled,
  List<RecurringStream> detected,
) {
  final Set<String> covered = {
    for (final RecurringStream s in pulled) ...s.transactionIds,
  };
  final Set<String> withoutIds = {
    for (final RecurringStream s in pulled)
      if (s.transactionIds.isEmpty)
        '${s.accountId}\u0000${normalizeMerchantText(s.merchantName)}',
  };
  return [
    ...pulled,
    for (final RecurringStream s in detected)
      if (!s.transactionIds.any(covered.contains) &&
          !withoutIds.contains(
            '${s.accountId}\u0000${normalizeMerchantText(s.merchantName)}',
          ))
        s,
  ]..sort(compareStreams);
}
