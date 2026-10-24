/// The persona engine: deterministic synthetic households for the Finance Tracker.
///
/// One persona and one seed give one household (`generateHousehold`), with `source: demo`
/// on every record; the four personas are `personaFor(PersonaId)`. This is the single
/// source of synthesized financial life (`PLAN.md` §7.1). Pure Dart, VM only.
/// How it works: `docs/reference/persona.md`.
library;

export 'src/generate/generator.dart' show generateHousehold, maxWindowDays;
export 'src/generate/loans.dart' show monthlyInterest;
export 'src/model/anomaly.dart';
export 'src/model/household.dart';
export 'src/model/investments.dart';
export 'src/model/liabilities.dart';
export 'src/model/persona.dart';
export 'src/model/recurring_expectation.dart';
export 'src/model/schedule.dart';
export 'src/personas/personas.dart';
export 'src/random/fnv1a.dart';
export 'src/random/pcg32.dart';
