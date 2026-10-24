/// The shared domain of the Finance Tracker app, the development server and the persona
/// engine: `Money` (integer minor units plus an ISO currency code), calendar dates and UTC
/// instants, the domain entities of `PLAN.md` §6.2 and Plaid's category taxonomy.
///
/// Pure Dart; no Flutter import. How to use it: `docs/reference/core.md`.
library;

export 'src/entities/account.dart';
export 'src/entities/balance_snapshot.dart';
export 'src/entities/bill_reminder.dart';
export 'src/entities/budget.dart';
export 'src/entities/category.dart';
export 'src/entities/change_log_entry.dart';
export 'src/entities/device.dart';
export 'src/entities/enums.dart';
export 'src/entities/goal.dart';
export 'src/entities/hlc.dart';
export 'src/entities/institution.dart';
export 'src/entities/item.dart';
export 'src/entities/net_worth_snapshot.dart';
export 'src/entities/recurring_stream.dart';
export 'src/entities/rule.dart';
export 'src/entities/transaction.dart';
export 'src/entities/user.dart';
export 'src/money/currency.dart';
export 'src/money/money.dart';
export 'src/money/rounding.dart' show RoundingMode;
export 'src/time/local_date.dart';
export 'src/time/utc_instant_converter.dart';
