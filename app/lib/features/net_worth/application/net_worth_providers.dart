/// What the Net worth segment shows (`docs/reference/net-worth.md`, **Providers**): the
/// history per currency (the observed series from the balance snapshots, after the
/// prefix reconstructed from the live ledger), the user's payoff entries, kept on the
/// device in `app_meta`, and each liability's payoff projection.
library;

import 'dart:convert';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/liabilities/application/liabilities_providers.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/features/net_worth/domain/payoff.dart';
import 'package:finance_tracker/features/net_worth/domain/payoff_entries.dart';
import 'package:finance_tracker/features/net_worth/domain/reconstruction.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'net_worth_providers.g.dart';

/// Every stored balance snapshot, by date, then account.
@riverpod
Stream<List<BalanceSnapshot>> balanceSnapshots(Ref ref) =>
    ref.watch(balanceSnapshotRepositoryProvider).watchAll();

/// The net worth history per currency code (`netWorthHistory`): the prefix
/// reconstructed from the live transactions (`recurringLedgerProvider`, every live
/// one), then the series of the stored snapshots, typed by the live accounts.
@riverpod
Future<Map<String, List<NetWorthPoint>>> netWorthSeries(Ref ref) async {
  final List<BalanceSnapshot> snapshots = await ref.watch(
    balanceSnapshotsProvider.future,
  );
  final List<Account> accounts = await ref.watch(accountsProvider.future);
  final List<Transaction> ledger = await ref.watch(
    recurringLedgerProvider.future,
  );
  return netWorthHistory(snapshots, {
    for (final Account a in accounts) a.id: a.type,
  }, ledger);
}

/// The payoff entries by account id (`PayoffEntry`), kept on this device only under
/// `AppMetaKeys.payoffEntries` (never synced). The changes are applied one at a time,
/// in the order they are made: the state is updated, then written; when the write fails
/// the state goes back and the change's Future fails.
@Riverpod(keepAlive: true)
class PayoffEntriesController extends _$PayoffEntriesController {
  Future<void> _changes = Future<void>.value();

  @override
  Future<Map<String, PayoffEntry>> build() async {
    final String? stored = await ref
        .watch(appMetaStoreProvider)
        .read(AppMetaKeys.payoffEntries);
    if (stored == null) return const {};
    try {
      return payoffEntriesFromJson(jsonDecode(stored));
    } on FormatException {
      return const {};
    }
  }

  /// Sets account [accountId]'s entered payment (null clears it).
  Future<void> setPayment(String accountId, Money? payment) =>
      _change(accountId, (e) => e.withPayment(payment));

  /// Sets account [accountId]'s entered rate in basis points (null clears it).
  Future<void> setRate(String accountId, int? rateBasisPoints) =>
      _change(accountId, (e) => e.withRate(rateBasisPoints));

  /// Sets account [accountId]'s extra payment a month (null clears it).
  Future<void> setExtra(String accountId, Money? extra) =>
      _change(accountId, (e) => e.withExtra(extra));

  // An invalid value throws from [PayoffEntry] before anything changes.
  Future<void> _change(String accountId, PayoffEntry Function(PayoffEntry) f) {
    final Future<void> run = _changes.then((_) async {
      final Map<String, PayoffEntry> previous = await future;
      final Map<String, PayoffEntry> next = {
        ...previous,
        accountId: f(previous[accountId] ?? PayoffEntry()),
      };
      state = AsyncData(next);
      try {
        await ref
            .read(appMetaStoreProvider)
            .write(
              AppMetaKeys.payoffEntries,
              jsonEncode(payoffEntriesToJson(next)),
            );
      } catch (_) {
        state = AsyncData(previous);
        rethrow;
      }
    });
    _changes = run.then((_) {}, onError: (Object _) {});
    return run;
  }
}

/// A liability account with its payoff: the [terms] it is projected from, the user's
/// [entry], the projection at the payment ([projection], null without a rate or a
/// payment) and with the entry's extra on top ([withExtra], null without an extra).
typedef LiabilityPayoff = ({
  Account account,
  PayoffTerms terms,
  PayoffEntry entry,
  PayoffProjection? projection,
  PayoffProjection? withExtra,
});

/// The live credit and loan accounts that owe something, hidden ones included (net worth
/// counts them), in the accounts' order, each with its payoff from today.
@riverpod
Future<List<LiabilityPayoff>> liabilityPayoffs(Ref ref) async {
  final LocalDate today = ref.watch(todayProvider);
  final List<Account> accounts = await ref.watch(accountsProvider.future);
  final Map<String, Money?> derived = await ref.watch(
    derivedBalancesProvider.future,
  );
  final List<Liability> liabilities = await ref.watch(
    liabilitiesProvider.future,
  );
  final Map<String, PayoffEntry> entries = await ref.watch(
    payoffEntriesControllerProvider.future,
  );
  final List<LiabilityPayoff> payoffs = [];
  for (final Account a in accounts) {
    if (a.type != AccountType.credit && a.type != AccountType.loan) continue;
    final PayoffEntry entry = entries[a.id] ?? PayoffEntry();
    final PayoffTerms terms = payoffTermsOf(
      shownBalance(a, derived).amount,
      liabilities.where((l) => l.accountId == a.id).firstOrNull,
      enteredRate: entry.rateBasisPoints,
      enteredPayment: entry.payment,
    );
    if (!terms.owed.isPositive) continue;
    final Money? extra = entry.extra?.currencyCode == a.currencyCode
        ? entry.extra
        : null;
    PayoffProjection? at(Money? more) =>
        switch ((terms.rateBasisPoints, terms.payment)) {
          (final int rate, final Money payment) => projectPayoff(
            owed: terms.owed,
            rateBasisPoints: rate,
            payment: payment,
            extra: more,
            today: today,
          ),
          _ => null,
        };
    payoffs.add((
      account: a,
      terms: terms,
      entry: entry,
      projection: at(null),
      withExtra: extra == null || extra.isZero ? null : at(extra),
    ));
  }
  return payoffs;
}
