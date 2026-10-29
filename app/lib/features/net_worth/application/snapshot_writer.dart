/// The balance snapshot writer (`docs/reference/net-worth.md`, **The writer**;
/// `PLAN.md` §12, "Balance snapshots and net worth" and "6a plan rulings").
///
/// [SnapshotWriter.write] records today's balances of every live account as one
/// `BalanceSnapshot` each, replacing the rows of today and never touching an earlier day:
///
/// - `current` is the balance the account is shown with (`shownBalance`): the one its
///   institution reported, else the one derived from its transactions. An investment
///   account's reported balance is its total value, holdings included (Plaid's
///   `balances.current`); one with no reported balance adds its holdings'
///   `institution_value` to the cash its transactions give.
/// - `available` and `limit` are the account's reported ones, null when there are none.
/// - `source`: `manual` for an account with no Item; for a linked one `demo` in the demo
///   flavor or when any of its stored rows (recent transactions, holdings, liabilities)
///   is `demo`, else `plaid`. `Account` carries no source of its own (later scope).
///
/// A write is skipped when a snapshot is stored for a later day than today (the device's
/// clock moved back), and a first-of-day write ([SnapshotWriterRunner] at launch and at
/// each new local day) when `app_meta` `snapshots_written_on` already says today and
/// today's rows are stored; a write after a Plaid pull or a sync session always replaces
/// today's rows.
///
/// [SnapshotWriterRunner] runs it for the clock's date when the write runs: once when
/// built, again when [todayProvider] moves to a new day, after every whole Plaid pull
/// ([PlaidPull.completed]) and after every sync session (a new `lastSyncAt`), one write
/// at a time; a failed write is logged and never stops the next. Nothing runs unless
/// something listens: `bootstrap` does, after the first frame, for the life of the app,
/// in every flavor.
library;

import 'dart:async';

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/plaid/plaid_pull.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:finance_tracker/features/liabilities/domain/liability_repository.dart';
import 'package:finance_tracker/features/net_worth/domain/balance_snapshot_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'snapshot_writer.g.dart';

final Logger _log = Logger('net_worth');

/// How many of a linked account's newest transactions the writer reads for its source.
const int snapshotSourceSample = 20;

/// Writes the day's balance snapshots from the repositories.
final class SnapshotWriter {
  /// A writer over the repositories; [demo] in the demo flavor, whose linked accounts
  /// are all `demo`.
  SnapshotWriter({
    required this.accounts,
    required this.transactions,
    required this.holdings,
    required this.liabilities,
    required this.snapshots,
    required this.meta,
    required this.demo,
  });

  final AccountRepository accounts;
  final TransactionRepository transactions;
  final HoldingRepository holdings;
  final LiabilityRepository liabilities;
  final BalanceSnapshotRepository snapshots;
  final AppMetaStore meta;
  final bool demo;

  /// Writes [today]'s snapshots, unless a later day is stored or, when [firstOfDay],
  /// today's were already written. Returns whether it wrote.
  Future<bool> write(LocalDate today, {required bool firstOfDay}) async {
    final LocalDate? latest = await snapshots.latestDate();
    if (latest != null && latest.isAfter(today)) {
      _log.warning('a later day is stored than today; no snapshot written');
      return false;
    }
    // Today's rows gone with their store (the demo's persona switch) are written again.
    if (firstOfDay &&
        latest == today &&
        await meta.read(AppMetaKeys.snapshotsWrittenOn) == today.toIso()) {
      return false;
    }
    final List<Account> live = await accounts.watchAll().first;
    final Map<String, Money?> derived = await accounts
        .watchDerivedBalances()
        .first;
    final List<Holding> held = [
      for (final HoldingView v in await holdings.watchAll().first) v.holding,
    ];
    final List<Liability> owed = await liabilities.watchAll().first;
    final List<BalanceSnapshot> rows = [
      for (final Account account in live)
        snapshotOf(
          account,
          date: today,
          derived: derived[account.id],
          holdings: [
            for (final Holding h in held)
              if (h.accountId == account.id) h,
          ],
          source: await _sourceOf(account, held, owed),
        ),
    ];
    await snapshots.writeDay(today, rows);
    await meta.write(AppMetaKeys.snapshotsWrittenOn, today.toIso());
    return true;
  }

  // The source of [account]'s balance, by the evidence of what is stored for it.
  Future<DataSource> _sourceOf(
    Account account,
    List<Holding> held,
    List<Liability> owed,
  ) async {
    if (account.itemId == null) return DataSource.manual;
    if (demo) return DataSource.demo;
    bool isDemo(DataSource s) => s == DataSource.demo;
    if (held.any((h) => h.accountId == account.id && isDemo(h.source)) ||
        owed.any((l) => l.accountId == account.id && isDemo(l.source))) {
      return DataSource.demo;
    }
    final List<Transaction> recent = await transactions
        .watch(
          TransactionQuery(
            accountIds: {account.id},
            limit: snapshotSourceSample,
          ),
        )
        .first;
    return recent.any((t) => isDemo(t.source))
        ? DataSource.demo
        : DataSource.plaid;
  }
}

/// [account]'s snapshot on [date] from what it is shown with: its reported balance, else
/// [derived] (zero when null), plus for an investment account with no reported balance
/// the value of its [holdings] in its currency; its reported available balance and limit;
/// [source].
BalanceSnapshot snapshotOf(
  Account account, {
  required LocalDate date,
  required Money? derived,
  required List<Holding> holdings,
  required DataSource source,
}) {
  final ShownBalance shown = shownBalance(account, {account.id: derived});
  final Money current =
      !shown.reported && account.type == AccountType.investment
      ? shown.amount +
            Money.sum([
              for (final Holding h in holdings)
                if (h.institutionValue.currencyCode == account.currencyCode)
                  h.institutionValue,
            ], currencyCode: account.currencyCode)
      : shown.amount;
  bool sameCurrency(Money? m) => m?.currencyCode == current.currencyCode;
  return BalanceSnapshot(
    accountId: account.id,
    date: date,
    current: current,
    available: sameCurrency(account.availableBalance)
        ? account.availableBalance
        : null,
    limit: sameCurrency(account.creditLimit) ? account.creditLimit : null,
    source: source,
  );
}

/// Keeps today's snapshots written while listened to (see the library comment). Its
/// state is the last day it wrote, null before its first write.
@Riverpod(keepAlive: true)
class SnapshotWriterRunner extends _$SnapshotWriterRunner {
  Future<void> _last = Future<void>.value();

  @override
  LocalDate? build() {
    final SnapshotWriter writer = SnapshotWriter(
      accounts: ref.watch(accountRepositoryProvider),
      transactions: ref.watch(transactionRepositoryProvider),
      holdings: ref.watch(holdingRepositoryProvider),
      liabilities: ref.watch(liabilityRepositoryProvider),
      snapshots: ref.watch(balanceSnapshotRepositoryProvider),
      meta: ref.watch(appMetaStoreProvider),
      demo: ref.watch(appConfigProvider).flavor == Flavor.demo,
    );
    final StreamSubscription<DateTime> pulls = ref
        .watch(plaidPullProvider)
        .completed
        .listen((_) => _write(writer, firstOfDay: false));
    ref.onDispose(pulls.cancel);
    ref.listen(todayProvider, (_, _) => _write(writer, firstOfDay: true));
    ref.listen<SyncStatus>(syncControllerProvider, (previous, next) {
      final DateTime? at = next.lastSyncAt;
      if (at != null && at != previous?.lastSyncAt) {
        _write(writer, firstOfDay: false);
      }
    });
    _write(writer, firstOfDay: true);
    return null;
  }

  /// Completes when every write asked for so far has finished.
  Future<void> settled() => _last;

  void _write(SnapshotWriter writer, {required bool firstOfDay}) {
    _last = _last
        .then((_) async {
          if (!ref.mounted) return;
          try {
            // The clock's date when the write runs, not todayProvider's: a pull that
            // lands just after local midnight writes the new day.
            final LocalDate today = ref.read(clockProvider).today();
            if (await writer.write(today, firstOfDay: firstOfDay) &&
                ref.mounted) {
              state = today;
            }
          } on Object catch (e) {
            // Only the type: a message could carry an amount.
            _log.warning('balance snapshots not written: ${e.runtimeType}');
          }
        })
        // One failed run never stops the next.
        .catchError((Object _) {});
  }
}
