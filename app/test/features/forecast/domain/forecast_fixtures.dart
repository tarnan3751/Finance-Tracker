// Builders for the forecast's domain tests: streams, member transactions and plans in
// USD, dated around 24 October 2026 (testClock's today).
import 'package:finance_tracker/features/forecast/domain/forecast_plan.dart';
import 'package:shared_models/shared_models.dart';

/// The day the forecast tests start on.
final LocalDate today = LocalDate(2026, 10, 24);

/// [cents] USD.
Money usd(int cents) => Money(cents, 'USD');

/// A stream [id] on `checking` at [cadence], averaging [cents].
RecurringStream stream(
  String id, {
  RecurringCadence cadence = RecurringCadence.monthly,
  int cents = -10000,
  LocalDate? next,
  LocalDate? last,
  RecurringStatus status = RecurringStatus.active,
  RecurringSource source = RecurringSource.plaid,
  List<String> members = const [],
}) => RecurringStream(
  id: id,
  accountId: 'checking',
  merchantName: id,
  cadence: cadence,
  averageAmount: usd(cents),
  lastExpected: last,
  nextExpected: next,
  status: status,
  isSubscription: false,
  source: source,
  transactionIds: members,
);

/// A transaction [id] of [cents] USD on [accountId] dated [date].
Transaction txn(
  String id,
  int cents,
  LocalDate date, {
  String accountId = 'checking',
  String currency = 'USD',
  bool pending = false,
  bool hidden = false,
  bool deleted = false,
  String? plaidDetailed,
}) => Transaction(
  id: id,
  accountId: accountId,
  amount: Money(cents, currency),
  date: date,
  pending: pending,
  name: id,
  plaidDetailedCategory: plaidDetailed,
  hidden: hidden,
  source: DataSource.manual,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  deletedAt: deleted ? DateTime.utc(2026, 10, 1) : null,
  syncVersion: 0,
);

/// A plan from [start] cents on [today] with [allowance] cents a day.
ForecastPlan plan({
  int start = 100000,
  int allowance = 0,
  List<ForecastStream> streams = const [],
  List<ForecastBill> bills = const [],
  LocalDate? on,
}) => ForecastPlan(
  today: on ?? today,
  start: usd(start),
  allowance: usd(allowance),
  streams: streams,
  bills: bills,
);
