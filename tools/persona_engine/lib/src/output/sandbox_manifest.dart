/// The Sandbox manifest: what each custom user carries and what it leaves out.
///
/// A provisioned Item holds exactly its custom user's transactions (nothing is injected
/// afterwards, `sandbox_split.dart`), so the manifest says per Item how much of the
/// persona's history Sandbox receives: the first day carried, the calendar days from it
/// through the as-of date, the transactions carried and the transactions left out.
///
/// Dates are the generator's, ending on the as-of date. Before any call the provisioning
/// job shifts every date of every Item of the persona by the same number of days, the
/// creation date minus the as-of date, so the as-of date lands on the creation day and
/// transfer legs across Items stay on one date.
library;

import 'package:persona_engine/src/model/household.dart';
import 'package:persona_engine/src/output/demo_seed.dart';
import 'package:persona_engine/src/output/sandbox_split.dart';
import 'package:persona_engine/src/output/sandbox_user.dart';

/// The manifest's file name.
const String sandboxManifestFileName = 'sandbox_manifest.json';

/// The manifest: the persona-wide date shift and budget, and per Item its file and what
/// it carries.
Map<String, Object?> sandboxManifest(
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
  'date_shift':
      'add (Item creation date - as_of) days to every date in every '
      'sandbox_user file of this persona, the same shift for every Item',
  'request_byte_budget': sandboxConfigByteBudget,
  'items': [
    for (final u in users)
      {
        'institution': u.split.institution.key,
        'plaid_institution_id': u.split.institution.plaidId,
        'sandbox_user_file': sandboxUserFileName(u),
        'custom_user_transactions': u.split.customUser.length,
        'first_day_carried': u.split.customUser.isEmpty
            ? null
            : u.split.customUser.first.date.toIso(),
        'days_carried': u.split.customUser.isEmpty
            ? 0
            : u.split.customUser.first.date.daysUntil(household.asOf) + 1,
        'transactions_left_out': u.split.leftOut.length,
      },
  ],
};
