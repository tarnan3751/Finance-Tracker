/// Injection batches for `/sandbox/transactions/create`
/// (https://plaid.com/docs/api/sandbox/#sandboxtransactionscreate): the transactions each
/// custom user does not carry, at most ten per call, newest first, so an interrupted run
/// leaves a shorter history with no gap. Each entry names the generator's account key,
/// which the provisioning script maps to the Item's Plaid `account_id`.
///
/// Dates are the generator's, relative to the as-of date. Before any call the
/// provisioning script shifts every date of every Item of the persona, in the custom users
/// and in these batches, by the same number of days: the creation date minus the as-of
/// date. The as-of date then lands on the creation day, transfer legs across Items stay
/// on one date, and since the window is at most 730 days and ends on the as-of date,
/// every shifted date is within Plaid's "today or up to 730 days in the past".
library;

import 'package:persona_engine/src/model/household.dart';
import 'package:persona_engine/src/output/demo_seed.dart';
import 'package:persona_engine/src/output/sandbox_user.dart';
import 'package:shared_models/shared_models.dart';

/// Plaid's per-call limit.
const int injectionBatchSize = 10;

/// The suggested wait between calls on one Item. Plaid's rate-limit table lists
/// `/sandbox/transactions/create` at 2 per minute per Item and 50 per minute per client
/// (https://plaid.com/docs/errors/rate-limit-exceeded/); documented, to be confirmed
/// against Sandbox in Phase 3.
const int injectionIntervalSeconds = 35;

/// The injection file for [user]'s institution.
Map<String, Object?> injectionFile(
  GeneratedHousehold household,
  SandboxUser user,
) {
  final keys = {
    for (final a in household.persona.accounts)
      accountIdFor(household.persona.id, a.key): a.key,
  };
  final injected = user.split.injected;
  return {
    'generator': 'persona_engine',
    'format_version': formatVersion,
    'persona': household.persona.id.slug,
    'seed': household.seed,
    'institution': user.split.institution.key,
    'plaid_institution_id': user.split.institution.plaidId,
    'as_of': household.asOf.toIso(),
    'order': 'newest_first',
    'batches': [
      for (var i = 0; i < injected.length; i += injectionBatchSize)
        [
          for (final t in injected.skip(i).take(injectionBatchSize))
            _entry(t, keys[t.accountId]!),
        ],
    ],
  };
}

Map<String, Object?> _entry(Transaction t, String accountKey) => {
  'date_transacted': t.authorizedDate!.toIso(),
  'date_posted': t.date.toIso(),
  'amount': plaidAmount(t),
  'description': t.name,
  'iso_currency_code': t.amount.currencyCode,
  'account': accountKey,
};

/// The number of calls [user]'s injection takes.
int batchCount(SandboxUser user) =>
    (user.split.injected.length + injectionBatchSize - 1) ~/ injectionBatchSize;

/// The manifest: the persona-wide date shift and pacing, and per Item the files and the
/// counts.
Map<String, Object?> injectionManifest(
  GeneratedHousehold household,
  List<SandboxUser> users, {
  required bool includeInterestLegs,
}) => {
  'generator': 'persona_engine',
  'format_version': formatVersion,
  'persona': household.persona.id.slug,
  'seed': household.seed,
  'as_of': household.asOf.toIso(),
  'include_interest_legs': includeInterestLegs,
  'order': 'newest_first',
  'date_shift':
      'add (Item creation date - as_of) days to every date in every '
      'sandbox_user and injection file of this persona, the same shift for '
      'every Item',
  'pacing': {
    'interval_seconds_per_item': injectionIntervalSeconds,
    'basis':
        "Plaid's rate-limit table: /sandbox/transactions/create 2 per minute per "
        'Item, 50 per minute per client; documented, to be confirmed against '
        'Sandbox in Phase 3',
  },
  'items': [
    for (final u in users)
      {
        'institution': u.split.institution.key,
        'plaid_institution_id': u.split.institution.plaidId,
        'sandbox_user_file': sandboxUserFileName(u),
        'injection_file': injectionFileName(u),
        'custom_user_transactions': u.split.customUser.length,
        'injected_transactions': u.split.injected.length,
        'batch_count': batchCount(u),
        'estimated_duration_seconds': batchCount(u) == 0
            ? 0
            : (batchCount(u) - 1) * injectionIntervalSeconds,
      },
  ],
};

/// The custom user's file name.
String sandboxUserFileName(SandboxUser user) =>
    'sandbox_user_${user.split.institution.key}.json';

/// The injection file's name.
String injectionFileName(SandboxUser user) =>
    'injection_${user.split.institution.key}.json';
