/// Plaid's non-OAuth Sandbox test institutions. Custom users can fail at OAuth
/// institutions (Plaid's "Sandbox custom users" page), so the personas use only these.
library;

import 'package:persona_engine/src/model/persona.dart';

/// First Platypus Bank.
const InstitutionSpec platypus = InstitutionSpec(
  'platypus',
  'ins_109508',
  'First Platypus Bank',
);

/// First Gingham Credit Union.
const InstitutionSpec gingham = InstitutionSpec(
  'gingham',
  'ins_109509',
  'First Gingham Credit Union',
);

/// Tattersall Federal Credit Union.
const InstitutionSpec tattersall = InstitutionSpec(
  'tattersall',
  'ins_109510',
  'Tattersall Federal Credit Union',
);

/// Tartan Bank.
const InstitutionSpec tartan = InstitutionSpec(
  'tartan',
  'ins_109511',
  'Tartan Bank',
);
