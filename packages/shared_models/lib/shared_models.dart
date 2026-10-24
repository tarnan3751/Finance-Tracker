/// The shared domain of the Finance Tracker app, the development server and the persona
/// engine: `Money` (integer minor units plus an ISO currency code), calendar dates and UTC
/// instants, the domain entities of `PLAN.md` §6.2 and Plaid's category taxonomy.
///
/// Pure Dart; no Flutter import. How to use it: `docs/reference/core.md`.
library;

export 'src/money/currency.dart';
export 'src/money/money.dart';
export 'src/money/rounding.dart' show RoundingMode;
