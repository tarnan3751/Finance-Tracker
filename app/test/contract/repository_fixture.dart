// What the account, transaction, category, item, rule, budget, recurring stream,
// liability, holding, investment transaction, balance snapshot, bill and goal contract
// suites run against:
// the repositories of one implementation over one backing store (an in-memory store, or
// one Drift database), and the clock their deletes are stamped with. Each implementation's
// test file builds a fixture per test; the suites never see which implementation it is.
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/bills/domain/bill_repository.dart';
import 'package:finance_tracker/features/budgets/domain/budget_repository.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/goals/domain/goal_repository.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:finance_tracker/features/investments/domain/investment_transaction_repository.dart';
import 'package:finance_tracker/features/items/domain/item_repository.dart';
import 'package:finance_tracker/features/liabilities/domain/liability_repository.dart';
import 'package:finance_tracker/features/net_worth/domain/balance_snapshot_repository.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';
import 'package:finance_tracker/features/rules/domain/rule_repository.dart';
import 'package:finance_tracker/features/settings/domain/settings_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:timezone/timezone.dart' as tz;

/// The repositories of one implementation, sharing one store, and the sync store they
/// record into (null for the demo implementation, which records nothing).
final class RepositoryFixture {
  RepositoryFixture({
    required this.accounts,
    required this.transactions,
    required this.categories,
    required this.settings,
    required this.items,
    required this.rules,
    required this.budgets,
    required this.streams,
    required this.liabilities,
    required this.holdings,
    required this.investmentTransactions,
    required this.snapshots,
    required this.bills,
    required this.goals,
    required this.clock,
    this.syncStore,
  });

  final AccountRepository accounts;
  final TransactionRepository transactions;
  final CategoryRepository categories;
  final SettingsRepository settings;
  final ItemRepository items;
  final RuleRepository rules;
  final BudgetRepository budgets;
  final RecurringStreamRepository streams;
  final LiabilityRepository liabilities;
  final HoldingRepository holdings;
  final InvestmentTransactionRepository investmentTransactions;
  final BalanceSnapshotRepository snapshots;
  final BillRepository bills;
  final GoalRepository goals;

  /// Where the writes are recorded.
  final SyncStore? syncStore;

  /// The clock the repositories stamp with.
  final SteppingClock clock;
}

/// A clock that moves one millisecond forward on every read of [nowUtc], so the stamps of
/// two writes differ, unless [frozen], when every read gives the same instant. Starts at
/// 24 October 2026, 15:00 UTC, in UTC.
final class SteppingClock implements Clock {
  int _millis = DateTime.utc(2026, 10, 24, 15).millisecondsSinceEpoch;

  /// Whether the clock has stopped.
  bool frozen = false;

  @override
  DateTime nowUtc() => DateTime.fromMillisecondsSinceEpoch(
    frozen ? _millis : _millis++,
    isUtc: true,
  );

  @override
  DateTime todayLocalMidnight() {
    final tz.TZDateTime now = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.UTC,
      _millis,
    );
    return tz.TZDateTime(tz.UTC, now.year, now.month, now.day);
  }

  @override
  LocalDate today() => LocalDate.fromDateTime(todayLocalMidnight());

  @override
  tz.Location get location => tz.UTC;
}

/// An audit instant for test records.
final DateTime testInstant = DateTime.utc(2026, 10, 1, 9);

/// A manual account.
Account testAccount(
  String id, {
  String currency = 'USD',
  int displayOrder = 0,
  bool isHidden = false,
  String? name,
}) => Account(
  id: id,
  type: AccountType.depository,
  name: name ?? 'Account $id',
  currencyCode: currency,
  isHidden: isHidden,
  displayOrder: displayOrder,
);

/// A manual transaction of [minorUnits] on [accountId].
Transaction testTransaction(
  String id,
  String accountId,
  int minorUnits, {
  String currency = 'USD',
  LocalDate? date,
  DateTime? createdAt,
  String name = 'Purchase',
  String? merchantName,
  String? notes,
  String? userCategoryId,
  bool pending = false,
  bool hidden = false,
  List<String> tags = const [],
  List<TransactionSplit> splits = const [],
}) => Transaction(
  id: id,
  accountId: accountId,
  amount: Money(minorUnits, currency),
  date: date ?? LocalDate(2026, 10, 1),
  pending: pending,
  name: name,
  merchantName: merchantName,
  notes: notes,
  userCategoryId: userCategoryId,
  tags: tags,
  splits: splits,
  hidden: hidden,
  source: DataSource.manual,
  createdAt: createdAt ?? testInstant,
  updatedAt: createdAt ?? testInstant,
  syncVersion: 0,
);
