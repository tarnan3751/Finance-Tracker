/// Which generated transactions each Sandbox custom user carries.
///
/// A custom user is the only way history reaches a Sandbox Item: Plaid serves a row
/// injected through `/sandbox/transactions/create` only when it is dated Plaid's today,
/// and `/sandbox/public_token/create` refuses a request over 100,000 bytes (both verified
/// 2026-10-25, `PLAN.md` §4). So per institution (one Item, one custom user) the
/// configuration carries the newest whole days of transactions that fit
/// [sandboxConfigByteBudget], and the older rest is left out: never injected, recorded
/// in the manifest. A day is kept or left out whole, so no day is half-recorded.
library;

import 'package:persona_engine/src/model/household.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:shared_models/shared_models.dart';

/// The most bytes a custom-user configuration takes in the request, measured as the
/// request carries it (`sandboxRequestBytes`: the JSON-escaped `override_password`
/// string); ten thousand below Plaid's 100,000 for the request's other fields.
const int sandboxConfigByteBudget = 90000;

/// The most investment transactions a custom user carries, newest first; the holdings
/// carry the whole position, and the cap keeps the configuration small.
const int customUserInvestmentTransactionBudget = 60;

/// One institution's share of a household.
final class InstitutionSplit {
  InstitutionSplit._(this.institution, this.customUser, this.leftOut);

  /// The institution.
  final InstitutionSpec institution;

  /// The transactions in the custom user, oldest first (in id order).
  final List<Transaction> customUser;

  /// The older transactions that did not fit, newest first.
  final List<Transaction> leftOut;
}

/// The split of [household] by institution, in the persona's institution order: per
/// institution, the most newest whole days whose transactions [fits] accepts for that
/// institution's custom user. [fits] must accept no transactions, and accept fewer days
/// whenever it accepts more (a configuration grows with every row). With
/// [includeInterestLegs] false, card and loan interest charges are left out of both
/// halves, for a Sandbox that accrues interest itself.
List<InstitutionSplit> splitForSandbox(
  GeneratedHousehold household, {
  required bool Function(InstitutionSpec institution, List<Transaction> carried)
  fits,
  bool includeInterestLegs = true,
}) {
  final persona = household.persona;
  final result = <InstitutionSplit>[];
  for (final institution in persona.institutions) {
    final accountIds = {
      for (final a in persona.accounts)
        if (a.institution == institution.key &&
            a.type != AccountType.investment)
          accountIdFor(persona.id, a.key),
    };
    // household.transactions is in date order, so the newest day is at the end.
    final candidates = [
      for (final t in household.transactions)
        if (accountIds.contains(t.accountId) &&
            (includeInterestLegs ||
                !household.interestTransactionIds.contains(t.id)))
          t,
    ];
    // starts[k] is where the newest k days begin.
    final starts = [candidates.length];
    for (var i = candidates.length - 1; i >= 0; i--) {
      if (i == 0 || candidates[i - 1].date != candidates[i].date) {
        starts.add(i);
      }
    }
    List<Transaction> newest(int days) => candidates.sublist(starts[days]);
    if (!fits(institution, const [])) {
      throw StateError(
        '${institution.key}: the custom user is over budget with no transactions',
      );
    }
    // The most days that fit: fits(lo) holds, fits(hi + 1) does not.
    var lo = 0;
    var hi = starts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (fits(institution, newest(mid))) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    result.add(
      InstitutionSplit._(
        institution,
        newest(lo),
        candidates.sublist(0, starts[lo]).reversed.toList(),
      ),
    );
  }
  return result;
}
