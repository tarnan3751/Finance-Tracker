/// What the account screens show and do: the accounts, their derived balances and the
/// balance each is shown with, the linked banks they belong to, one account's
/// transactions with the running balance after each, and the writes the list, the detail
/// and the editor make.
///
/// A balance is either derived from transactions or reported by the institution
/// (`PLAN.md` §6: balances are derived, never stored as truth); the screens label which.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

part 'accounts_providers.g.dart';

/// The live accounts: visible ones first, then hidden ones, each in display order.
@riverpod
Stream<List<Account>> accounts(Ref ref) =>
    ref.watch(accountRepositoryProvider).watchAll();

/// The live accounts by id, for screens that name a transaction's account.
@riverpod
Map<String, Account> accountsById(Ref ref) => {
  for (final Account account in ref.watch(accountsProvider).value ?? const [])
    account.id: account,
};

/// Every live account's balance derived from its transactions, by account id; null for an
/// account with none.
@riverpod
Stream<Map<String, Money?>> derivedBalances(Ref ref) =>
    ref.watch(accountRepositoryProvider).watchDerivedBalances();

/// The balance an account is shown with, and whether the institution [reported] it.
typedef ShownBalance = ({Money amount, bool reported});

/// The balance [account] is shown with: for a linked account, the current balance its
/// institution last reported; else, and for a linked account never synced, its balance
/// derived from its transactions ([derived], `derivedBalancesProvider`'s), zero when it
/// has none.
ShownBalance shownBalance(Account account, Map<String, Money?> derived) =>
    switch (reportedBalance(account)) {
      final Money reported => (amount: reported, reported: true),
      null => (
        amount: derived[account.id] ?? Money.zero(account.currencyCode),
        reported: false,
      ),
    };

/// The current balance [account]'s institution last reported, when it is linked and has
/// one; else null.
Money? reportedBalance(Account account) =>
    account.itemId == null ? null : account.currentBalance;

/// The stored linked banks by Item id, unlinked ones included, for the accounts that
/// name their institution.
@riverpod
Stream<Map<String, LinkedBank>> linkedBanksById(Ref ref) => ref
    .watch(itemRepositoryProvider)
    .watchAll()
    .map((banks) => {for (final LinkedBank bank in banks) bank.id: bank});

/// The live account [id], or null when it does not exist or is deleted.
@riverpod
Stream<Account?> account(Ref ref, String id) =>
    ref.watch(accountRepositoryProvider).watchById(id);

/// One row of an account's ledger: a transaction and the account's balance after it, null
/// for a transaction in another currency than the account's, which has none.
typedef LedgerEntry = ({Transaction transaction, Money? balance});

/// Account [accountId]'s live transactions, newest first, each with the running balance
/// after it: anchored to the account's [reportedBalance] when it has one, else derived
/// from the transactions before it ([withRunningBalances]).
@riverpod
Stream<List<LedgerEntry>> accountLedger(Ref ref, String accountId) async* {
  final Account? account = await ref.watch(accountProvider(accountId).future);
  if (account == null) return;
  final Money? reported = reportedBalance(account);
  yield* ref
      .watch(transactionRepositoryProvider)
      .watch(TransactionQuery(accountIds: {accountId}))
      .map(
        (t) => withRunningBalances(
          t,
          currencyCode: account.currencyCode,
          reported: reported,
        ),
      );
}

/// [newestFirst] (one account's transactions in the repository's order) with the running
/// balance after each, in [currencyCode] (the account's), returned newest first.
///
/// With [reported] (the institution's current balance), the newest row's balance is
/// [reported] and each older row's is [reported] minus every newer transaction's amount,
/// pending ones included, so a linked account with partial history still ends at what its
/// bank reports. Without it, the balances are summed from the oldest transaction to the
/// newest. A transaction in another currency (which the repositories refuse, but a synced
/// record could carry) has no balance and is left out of the walk, so one stray row never
/// puts the whole ledger in error.
List<LedgerEntry> withRunningBalances(
  List<Transaction> newestFirst, {
  required String currencyCode,
  Money? reported,
}) {
  bool counts(Transaction t) => t.amount.currencyCode == currencyCode;
  if (reported != null) {
    final List<LedgerEntry> entries = [];
    Money balance = reported;
    for (final Transaction transaction in newestFirst) {
      if (!counts(transaction)) {
        entries.add((transaction: transaction, balance: null));
        continue;
      }
      entries.add((transaction: transaction, balance: balance));
      // The balance before this transaction, which is the one after the next row.
      balance = balance - transaction.amount;
    }
    return entries;
  }
  final List<LedgerEntry> oldestFirst = [];
  Money running = Money.zero(currencyCode);
  for (final Transaction transaction in newestFirst.reversed) {
    if (!counts(transaction)) {
      oldestFirst.add((transaction: transaction, balance: null));
      continue;
    }
    running = running + transaction.amount;
    oldestFirst.add((transaction: transaction, balance: running));
  }
  return oldestFirst.reversed.toList(growable: false);
}

/// How many live transactions account [accountId] has, when the editor or the delete
/// confirmation asks.
@riverpod
Future<int> accountTransactionCount(Ref ref, String accountId) => ref
    .watch(transactionRepositoryProvider)
    .count(TransactionQuery(accountIds: {accountId}));

/// The writes of the account screens.
@riverpod
AccountActions accountActions(Ref ref) => AccountActions(
  ref.watch(accountRepositoryProvider),
  ref.watch(clockProvider),
);

/// Creates, edits, reorders, hides and deletes accounts. The repositories' typed
/// exceptions (`CurrencyMismatchException`, `EntityDeletedException`,
/// `AccountNotFoundException`) reach the caller, which explains them.
final class AccountActions {
  AccountActions(this._accounts, this._clock);

  final AccountRepository _accounts;
  final Clock _clock;

  static const Uuid _uuid = Uuid();

  /// Creates a manual account after [existing] (the live accounts) and returns its id.
  /// A nonzero [openingBalance] becomes a `manual` transaction named [openingBalanceName]
  /// dated [openingDate], written with the account in one repository write
  /// (`AccountRepository.create`): the opening balance is itself a transaction, so the
  /// balance stays derived, and a failure leaves neither behind.
  Future<String> create({
    required List<Account> existing,
    required String name,
    required AccountType type,
    required String currencyCode,
    Money? openingBalance,
    required LocalDate openingDate,
    required String openingBalanceName,
  }) async {
    final String id = _uuid.v4();
    final DateTime now = _clock.nowUtc();
    await _accounts.create(
      Account(
        id: id,
        type: type,
        name: name,
        currencyCode: currencyCode,
        isHidden: false,
        displayOrder: existing.isEmpty
            ? 0
            : existing
                      .map((a) => a.displayOrder)
                      .reduce((a, b) => a > b ? a : b) +
                  1,
      ),
      openingBalance: openingBalance == null || openingBalance.isZero
          ? null
          : Transaction(
              id: _uuid.v4(),
              accountId: id,
              amount: openingBalance,
              date: openingDate,
              pending: false,
              name: openingBalanceName,
              source: DataSource.manual,
              createdAt: now,
              updatedAt: now,
              syncVersion: 0,
            ),
    );
    return id;
  }

  /// Saves an edited [account].
  Future<void> update(Account account) => _accounts.upsert(account);

  /// Hides or shows [account].
  Future<void> setHidden(Account account, {required bool hidden}) =>
      _accounts.upsert(account.copyWith(isHidden: hidden));

  /// Writes [ordered] (the visible accounts in their new order) as display orders 0, 1,
  /// 2..., touching only the accounts whose order changes.
  Future<void> reorder(List<Account> ordered) async {
    for (int i = 0; i < ordered.length; i++) {
      if (ordered[i].displayOrder != i) {
        await _accounts.upsert(ordered[i].copyWith(displayOrder: i));
      }
    }
  }

  /// Deletes account [id] and, with it, its transactions.
  Future<void> delete(String id) => _accounts.delete(id);
}

/// The currency of [locale] (intl's default locale, the device's, when null), or USD
/// when intl does not know one: the default of a new account.
String defaultCurrencyCode({String? locale}) {
  try {
    final String? code = NumberFormat.simpleCurrency(locale: locale)
        .currencyName;
    return code != null && Money.isValidCurrencyCode(code) ? code : 'USD';
  } on ArgumentError {
    return 'USD';
  }
}
