/// The persona engine: deterministic synthetic households for the Finance Tracker.
///
/// One persona and one seed give one household (`generateHousehold`), written three
/// ways: the demo seed the demo flavor loads (`source: demo` on every record), Plaid
/// Sandbox custom users, and `/sandbox/transactions/create` injection batches. This is the
/// single source of synthesized financial life (`PLAN.md` §7.1). Pure Dart, VM only.
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
export 'src/output/demo_seed.dart';
export 'src/output/injection.dart';
export 'src/output/json_writer.dart';
export 'src/output/render.dart';
export 'src/output/sandbox_split.dart';
export 'src/output/sandbox_user.dart';
export 'src/personas/personas.dart';
export 'src/random/fnv1a.dart';
export 'src/random/pcg32.dart';
