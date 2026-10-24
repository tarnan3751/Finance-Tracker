/// Which generated transactions go into each Sandbox custom user and which are injected
/// afterwards through `/sandbox/transactions/create`.
///
/// Per institution (one Item, one custom user):
/// 1. every transaction on an account that rejects injection (student loans, `PLAN.md` §4)
///    goes in the custom user;
/// 2. the remaining budget of [customUserTransactionBudget] is filled with whole days,
///    newest first;
/// 3. everything older is injected, newest first, ten per call.
library;

import 'package:collection/collection.dart';
import 'package:persona_engine/src/model/household.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:shared_models/shared_models.dart';

/// The most transactions a custom user carries: ten below Plaid's "approximately 250"
/// (Plaid's "Sandbox custom users" page).
const int customUserTransactionBudget = 240;

/// The most investment transactions a custom user carries, newest first; the holdings
/// carry the whole position, and the cap keeps the configuration under Plaid's size
/// limit.
const int customUserInvestmentTransactionBudget = 60;

/// One institution's share of a household.
final class InstitutionSplit {
  InstitutionSplit._(this.institution, this.customUser, this.injected);

  /// The institution.
  final InstitutionSpec institution;

  /// The transactions in the custom user, oldest first.
  final List<Transaction> customUser;

  /// The transactions to inject, newest first.
  final List<Transaction> injected;
}

/// The split of [household] by institution, in the persona's institution order. With
/// [includeInterestLegs] false, card and loan interest charges are left out of both
/// halves, for a Sandbox that accrues interest itself.
List<InstitutionSplit> splitForSandbox(
  GeneratedHousehold household, {
  bool includeInterestLegs = true,
}) {
  final persona = household.persona;
  final result = <InstitutionSplit>[];
  for (final institution in persona.institutions) {
    final specs = {
      for (final a in persona.accounts)
        if (a.institution == institution.key &&
            a.type != AccountType.investment)
          accountIdFor(persona.id, a.key): a,
    };
    final candidates = [
      for (final t in household.transactions)
        if (specs.containsKey(t.accountId) &&
            (includeInterestLegs ||
                !household.interestTransactionIds.contains(t.id)))
          t,
    ];
    final fixed = [
      for (final t in candidates)
        if (!specs[t.accountId]!.acceptsInjection) t,
    ];
    var budget = customUserTransactionBudget - fixed.length;
    if (budget < 0) {
      throw StateError(
        '${institution.key} has ${fixed.length} transactions that cannot be '
        'injected, more than a custom user carries',
      );
    }
    final movable = [
      for (final t in candidates)
        if (specs[t.accountId]!.acceptsInjection) t,
    ];
    // household.transactions is in date order, so the newest day is at the end.
    var cut = movable.length;
    while (cut > 0) {
      final day = movable[cut - 1].date;
      var start = cut;
      while (start > 0 && movable[start - 1].date == day) {
        start--;
      }
      if (cut - start > budget) break;
      budget -= cut - start;
      cut = start;
    }
    final customUser = [...fixed, ...movable.sublist(cut)];
    mergeSort(customUser, compare: (a, b) => a.id.compareTo(b.id));
    result.add(
      InstitutionSplit._(
        institution,
        customUser,
        movable.sublist(0, cut).reversed.toList(),
      ),
    );
  }
  return result;
}
