/// The accounts, transactions, categories and Plaid Items held in memory: the shared state
/// behind the in-memory repositories (tests) and the demo ones (the demo flavor, loaded
/// with the demo seed).
///
/// One store backs all three repositories because they depend on each other: a derived
/// balance sums the store's transactions, a transaction's currency is checked against its
/// account's, and an account's delete takes its transactions with it. The rules are the
/// Drift repositories' rules, and both pass the same contract suites
/// (`test/contract/`); in particular the search text matches as the full-text index does
/// (`search_text.dart`), and text order follows SQLite's `BINARY` and `NOCASE`. The operations are synchronous, so the demo seed can be
/// loaded in a provider; the repositories wrap them in futures and streams.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/items/domain/item_repository.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/search_text.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
import 'package:shared_models/shared_models.dart';

/// The in-memory state, its rules, and change notification.
final class InMemoryStore {
  /// An empty store whose deletes are stamped by [clock].
  InMemoryStore(this._clock);

  final Clock _clock;
  final Map<String, ({Account account, DateTime? deletedAt})> _accounts = {};
  final Map<String, Transaction> _transactions = {};
  // The transactions an account's delete removed: what its restore brings back.
  final Set<String> _deletedWithAccount = {};
  final Map<String, ({Category category, DateTime? deletedAt})> _categories =
      {};
  final Map<String, LinkedBank> _items = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// The clock the store stamps with.
  Clock get clock => _clock;

  // Accounts --------------------------------------------------------------------------

  /// The live accounts, ordered as `AccountRepository.watchAll` documents.
  List<Account> accounts() {
    final List<Account> live = [
      for (final entry in _accounts.values)
        if (entry.deletedAt == null) entry.account,
    ];
    return live..sort((a, b) {
      if (a.isHidden != b.isHidden) return a.isHidden ? 1 : -1;
      final int byOrder = a.displayOrder.compareTo(b.displayOrder);
      return byOrder != 0 ? byOrder : compareBinary(a.id, b.id);
    });
  }

  /// The live account [id], or null.
  Account? account(String id) {
    final entry = _accounts[id];
    return entry == null || entry.deletedAt != null ? null : entry.account;
  }

  /// `AccountRepository.upsert`.
  void upsertAccount(Account account) {
    _checkAccount(account);
    _accounts[account.id] = (account: account, deletedAt: null);
    _changed();
  }

  /// `AccountRepository.create`: every check of both writes runs before either is made,
  /// so a failure leaves the store as it was.
  void createAccount(Account account, Transaction? openingBalance) {
    if (openingBalance != null && openingBalance.accountId != account.id) {
      throw ArgumentError.value(
        openingBalance.accountId,
        'openingBalance',
        'must be on account ${account.id}',
      );
    }
    _checkAccount(account);
    if (openingBalance != null) _checkTransaction(openingBalance, account);
    _accounts[account.id] = (account: account, deletedAt: null);
    if (openingBalance != null) {
      _transactions[openingBalance.id] = openingBalance.copyWith(
        deletedAt: null,
      );
    }
    _changed();
  }

  void _checkAccount(Account account) {
    final existing = _accounts[account.id];
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('account', account.id);
    }
    for (final Money? balance in [
      account.currentBalance,
      account.availableBalance,
      account.creditLimit,
    ]) {
      if (balance != null && balance.currencyCode != account.currencyCode) {
        throw CurrencyMismatchException(
          account.currencyCode,
          balance.currencyCode,
        );
      }
    }
    if (existing != null &&
        existing.account.currencyCode != account.currencyCode &&
        _transactions.values.any((t) => t.accountId == account.id)) {
      throw CurrencyMismatchException(
        existing.account.currencyCode,
        account.currencyCode,
      );
    }
  }

  /// `AccountRepository.delete`.
  void deleteAccount(String id) {
    final entry = _accounts[id];
    if (entry == null || entry.deletedAt != null) return;
    if (entry.account.itemId != null) {
      throw BankDataNotDeletableException('account', id);
    }
    final DateTime now = _clock.nowUtc();
    _accounts[id] = (account: entry.account, deletedAt: now);
    for (final Transaction t in _transactions.values.toList()) {
      if (t.accountId == id && t.deletedAt == null) {
        _transactions[t.id] = t.copyWith(deletedAt: now, updatedAt: now);
        _deletedWithAccount.add(t.id);
      }
    }
    _changed();
  }

  /// `AccountRepository.restore`.
  void restoreAccount(String id) {
    final entry = _accounts[id];
    if (entry == null || entry.deletedAt == null) return;
    final DateTime now = _clock.nowUtc();
    _accounts[id] = (account: entry.account, deletedAt: null);
    for (final Transaction t in _transactions.values.toList()) {
      if (t.accountId == id && _deletedWithAccount.remove(t.id)) {
        _transactions[t.id] = t.copyWith(deletedAt: null, updatedAt: now);
      }
    }
    _changed();
  }

  /// `AccountRepository.applyPlaid`: [accounts] is the server's whole list of linked
  /// accounts.
  void applyPlaidAccounts(List<Account> accounts) {
    final DateTime now = _clock.nowUtc();
    int next = _accounts.values.fold(
      0,
      (n, e) => e.account.displayOrder >= n ? e.account.displayOrder + 1 : n,
    );
    // Every account is checked before any is written.
    for (final Account account in accounts) {
      for (final Money? balance in [
        account.currentBalance,
        account.availableBalance,
        account.creditLimit,
      ]) {
        if (balance != null && balance.currencyCode != account.currencyCode) {
          throw CurrencyMismatchException(
            account.currencyCode,
            balance.currencyCode,
          );
        }
      }
    }
    final Set<String> listed = {};
    for (final Account account in accounts) {
      listed.add(account.id);
      final existing = _accounts[account.id];
      _accounts[account.id] = (
        account: existing == null
            ? account.copyWith(displayOrder: next++)
            : account.copyWith(
                isHidden: existing.account.isHidden,
                displayOrder: existing.account.displayOrder,
              ),
        deletedAt: null,
      );
    }
    for (final entry in _accounts.values.toList()) {
      final Account a = entry.account;
      if (a.itemId != null &&
          entry.deletedAt == null &&
          !listed.contains(a.id)) {
        _accounts[a.id] = (account: a, deletedAt: now);
      }
    }
    _changed();
  }

  /// The derived balance of every live account, as `AccountRepository` documents.
  Map<String, Money?> derivedBalances() => {
    for (final Account a in accounts()) a.id: _derivedBalance(a),
  };

  /// The derived balance of live account [id]; null when it has none or is not live.
  Money? derivedBalance(String id) {
    final Account? a = account(id);
    return a == null ? null : _derivedBalance(a);
  }

  Money? _derivedBalance(Account account) {
    final List<Money> amounts = [
      for (final Transaction t in _transactions.values)
        if (t.accountId == account.id &&
            t.deletedAt == null &&
            t.amount.currencyCode == account.currencyCode)
          t.amount,
    ];
    return amounts.isEmpty ? null : Money.sum(amounts);
  }

  // Transactions ----------------------------------------------------------------------

  /// The live transactions matching [query], ordered and paged.
  List<Transaction> transactions(TransactionQuery query) {
    final List<Transaction> matching = _matching(query);
    final int start = query.offset.clamp(0, matching.length);
    final int? limit = query.limit;
    final int end = limit == null
        ? matching.length
        : (start + limit).clamp(start, matching.length);
    return matching.sublist(start, end);
  }

  /// How many live transactions match [query], ignoring its paging.
  int count(TransactionQuery query) => _matching(query).length;

  /// The live transaction [id], or null.
  Transaction? transaction(String id) {
    final Transaction? t = _transactions[id];
    return t == null || t.deletedAt != null ? null : t;
  }

  /// `TransactionRepository.upsert`.
  void upsertTransaction(Transaction transaction) {
    _checkTransaction(transaction, account(transaction.accountId));
    _transactions[transaction.id] = transaction.copyWith(deletedAt: null);
    _changed();
  }

  /// `TransactionRepository.upsertAll`: every transaction is checked before any is
  /// written, so a refusal leaves the store as it was.
  void upsertTransactions(List<Transaction> batch) {
    checkDistinctIds([for (final Transaction t in batch) t.id]);
    for (final Transaction t in batch) {
      _refusedAs(t.id, () {
        _checkTransaction(t, account(t.accountId));
        checkPlaidOverridesOnly(t, _transactions[t.id]);
      });
    }
    if (batch.isEmpty) return;
    for (final Transaction t in batch) {
      _transactions[t.id] = t.copyWith(deletedAt: null);
    }
    _changed();
  }

  /// `TransactionRepository.deleteAll`: no transaction is deleted when one is `plaid`.
  void deleteTransactions(List<String> ids) {
    for (final String id in ids) {
      if (transaction(id)?.source == DataSource.plaid) {
        throw TransactionBatchException(
          id,
          BankDataNotDeletableException('transaction', id),
        );
      }
    }
    final DateTime now = _clock.nowUtc();
    bool changed = false;
    for (final String id in ids) {
      final Transaction? t = transaction(id);
      if (t == null) continue;
      _transactions[id] = t.copyWith(deletedAt: now, updatedAt: now);
      changed = true;
    }
    if (changed) _changed();
  }

  // Runs [check] for transaction [id] of a batch, reporting a refusal as the batch's.
  void _refusedAs(String id, void Function() check) {
    try {
      check();
    } on Object catch (e) {
      if (!isBatchRefusal(e)) rethrow;
      throw TransactionBatchException(id, e);
    }
  }

  // The checks of an upsert of [transaction] on its live account [owner] (null when
  // there is none).
  void _checkTransaction(Transaction transaction, Account? owner) {
    final Transaction? existing = _transactions[transaction.id];
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('transaction', transaction.id);
    }
    checkAuditInstants(transaction);
    if (owner == null) throw AccountNotFoundException(transaction.accountId);
    for (final Money amount in [
      transaction.amount,
      for (final TransactionSplit split in transaction.splits) split.amount,
    ]) {
      if (amount.currencyCode != owner.currencyCode) {
        throw CurrencyMismatchException(
          owner.currencyCode,
          amount.currencyCode,
        );
      }
    }
  }

  /// `TransactionRepository.applyPlaid`; returns the transactions it inserted.
  List<Transaction> applyPlaidTransactions(List<Transaction> page) {
    final List<Transaction> inserted = [];
    for (final Transaction t in page) {
      final Transaction? old = _transactions[t.id];
      if (old == null) {
        if (t.deletedAt != null) continue;
        _transactions[t.id] = t;
        inserted.add(t);
        continue;
      }
      _transactions[t.id] = withPlaidOverrides(t, old);
    }
    _changed();
    return inserted;
  }

  /// `TransactionRepository.watchUsage`'s value.
  TransactionUsage usage(int recentLimit) {
    final Set<String> tags = {};
    final Map<String, DateTime> categories = {};
    final Map<String, DateTime> accounts = {};
    void newest(Map<String, DateTime> into, String id, DateTime at) {
      final DateTime? seen = into[id];
      if (seen == null || at.isAfter(seen)) into[id] = at;
    }

    for (final Transaction t in _transactions.values) {
      if (t.deletedAt != null) continue;
      tags.addAll(t.tags);
      if (t.userCategoryId case final String id) {
        newest(categories, id, t.createdAt);
      }
      newest(accounts, t.accountId, t.createdAt);
    }
    List<String> recent(Map<String, DateTime> used) =>
        (used.keys.toList()..sort((a, b) {
              final int byTime = used[b]!.compareTo(used[a]!);
              return byTime != 0 ? byTime : compareBinary(a, b);
            }))
            .take(recentLimit)
            .toList();
    return TransactionUsage(
      tags: tags.toList()..sort(compareBinary),
      recentCategoryIds: recent(categories),
      recentAccountIds: recent(accounts),
    );
  }

  /// `TransactionRepository.delete`.
  void deleteTransaction(String id) {
    final Transaction? t = transaction(id);
    if (t == null) return;
    if (t.source == DataSource.plaid) {
      throw BankDataNotDeletableException('transaction', id);
    }
    final DateTime now = _clock.nowUtc();
    _transactions[id] = t.copyWith(deletedAt: now, updatedAt: now);
    _changed();
  }

  /// `TransactionRepository.restore`.
  void restoreTransaction(String id) {
    final Transaction? t = _transactions[id];
    if (t == null || t.deletedAt == null) return;
    if (account(t.accountId) == null) {
      throw AccountNotFoundException(t.accountId);
    }
    _transactions[id] = t.copyWith(deletedAt: null, updatedAt: _clock.nowUtc());
    _deletedWithAccount.remove(id);
    _changed();
  }

  List<Transaction> _matching(TransactionQuery q) {
    final List<String> terms = searchTerms(q.text ?? '');
    bool withinBound(Transaction t, Money? bound, bool isMin) {
      if (bound == null) return true;
      if (t.amount.currencyCode != bound.currencyCode) return false;
      final int amount = t.amount.minorUnits.abs();
      return isMin ? amount >= bound.minorUnits : amount <= bound.minorUnits;
    }

    final CategoryLookup? lookup = q.categoryPlaidCodes.isEmpty
        ? null
        : categoryLookup(categories());
    bool inCategories(Transaction t) {
      if (q.categoryIds.contains(t.userCategoryId) ||
          t.splits.any((s) => q.categoryIds.contains(s.categoryId))) {
        return true;
      }
      if (lookup == null || lookup.byId.containsKey(t.userCategoryId)) {
        return false;
      }
      final String? code = plaidCategoryOf(
        t,
        lookup.byPlaidCode,
      )?.plaidCategory;
      return q.categoryPlaidCodes.contains(code);
    }

    final List<Transaction> matching = [
      for (final Transaction t in _transactions.values)
        if (t.deletedAt == null &&
            (q.accountIds.isEmpty || q.accountIds.contains(t.accountId)) &&
            ((q.categoryIds.isEmpty && q.categoryPlaidCodes.isEmpty) ||
                inCategories(t)) &&
            (q.range == null || q.range!.contains(t.date)) &&
            (terms.isEmpty ||
                matchesSearch(terms, [
                  t.name,
                  t.merchantName,
                  t.notes,
                  t.tags.join(' '),
                ])) &&
            (q.pending == null || t.pending == q.pending) &&
            (q.hidden == null || t.hidden == q.hidden) &&
            (q.tags.isEmpty || t.tags.any(q.tags.contains)) &&
            withinBound(t, q.minAmount, true) &&
            withinBound(t, q.maxAmount, false))
          t,
    ];
    return matching..sort(compareTransactionsNewestFirst);
  }

  // Categories ------------------------------------------------------------------------

  /// The live categories, ordered as `CategoryRepository.watchAll` documents.
  List<Category> categories() {
    final List<Category> live = [
      for (final entry in _categories.values)
        if (entry.deletedAt == null) entry.category,
    ];
    return live..sort((a, b) {
      final int byName = compareNoCase(a.name, b.name);
      return byName != 0 ? byName : compareBinary(a.id, b.id);
    });
  }

  /// The live category [id], or null.
  Category? category(String id) {
    final entry = _categories[id];
    return entry == null || entry.deletedAt != null ? null : entry.category;
  }

  /// `CategoryRepository.upsert`.
  void upsertCategory(Category category) {
    final existing = _categories[category.id];
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('category', category.id);
    }
    checkCategoryEdit(existing?.category, category);
    _categories[category.id] = (category: category, deletedAt: null);
    _changed();
  }

  /// `CategoryRepository.delete`.
  void deleteCategory(String id) {
    final Category? c = category(id);
    if (c == null) return;
    if (c.isSystem) throw CategoryNotDeletableException(id);
    final DateTime now = _clock.nowUtc();
    for (final entry in _categories.values.toList()) {
      final Category each = entry.category;
      if (entry.deletedAt == null && (each.id == id || each.parentId == id)) {
        _categories[each.id] = (category: each, deletedAt: now);
      }
    }
    _changed();
  }

  /// `CategoryRepository.ensureSeeded`.
  void seedSystemCategories() {
    bool added = false;
    for (final Category c in systemCategories) {
      if (_categories.containsKey(c.id)) continue;
      _categories[c.id] = (category: c, deletedAt: null);
      added = true;
    }
    if (added) _changed();
  }

  // Items -----------------------------------------------------------------------------

  /// The stored Items, ordered as `ItemRepository.watchAll` documents.
  List<LinkedBank> items() => _items.values.toList()
    ..sort((a, b) {
      final int byName = compareNoCase(a.institution.name, b.institution.name);
      return byName != 0 ? byName : compareBinary(a.id, b.id);
    });

  /// Item [id], or null.
  LinkedBank? item(String id) => _items[id];

  /// `ItemRepository.applyPlaid`.
  void applyPlaidItems(List<ServerItem> items, DateTime pulledAt) {
    for (final ServerItem item in items) {
      _putItem(item, pulledAt);
    }
    final Set<String> listed = {for (final i in items) i.item.id};
    _items.removeWhere((id, _) => !listed.contains(id));
    _changed();
  }

  /// `ItemRepository.applyPlaidItem`.
  void applyPlaidItem(ServerItem item, DateTime pulledAt) {
    _putItem(item, pulledAt);
    _changed();
  }

  void _putItem(ServerItem item, DateTime pulledAt) {
    final LinkedBank? existing = _items[item.item.id];
    _items[item.item.id] = LinkedBank(
      item: item.item,
      institution: item.institution,
      logo: existing?.institution.logoUrl == item.institution.logoUrl
          ? existing?.logo
          : null,
      pulledAt: pulledAt,
    );
  }

  /// `ItemRepository.saveLogo`.
  void saveItemLogo(String id, Uri logoUrl, Uint8List bytes) {
    final LinkedBank? existing = _items[id];
    if (existing == null || existing.institution.logoUrl != logoUrl) return;
    _items[id] = LinkedBank(
      item: existing.item,
      institution: existing.institution,
      logo: bytes,
      pulledAt: existing.pulledAt,
    );
    _changed();
  }

  /// `ItemRepository.markLoginRequired`.
  void markItemLoginRequired(String id) {
    final LinkedBank? existing = _items[id];
    if (existing == null) return;
    _items[id] = existing.withItem(
      existing.item.copyWith(
        status: ItemStatus.loginRequired,
        errorCode: itemLoginRequiredCode,
      ),
    );
    _changed();
  }

  // Sync records ----------------------------------------------------------------------

  /// The record fields of account [id], deleted or not, or null when there is none.
  Map<String, Object?>? accountRecord(String id) {
    final entry = _accounts[id];
    return entry == null
        ? null
        : accountRecordJson(entry.account, deletedAt: entry.deletedAt);
  }

  /// The record fields of transaction [id], deleted or not, or null when there is none.
  Map<String, Object?>? transactionRecord(String id) {
    final Transaction? t = _transactions[id];
    return t == null
        ? null
        : transactionRecordJson(
            t,
            deletedWithAccount: _deletedWithAccount.contains(id),
          );
  }

  /// The record fields of every transaction on account [accountId], deleted or not, by
  /// id.
  Map<String, Map<String, Object?>> transactionRecordsOf(String accountId) => {
    for (final Transaction t in _transactions.values)
      if (t.accountId == accountId) t.id: transactionRecord(t.id)!,
  };

  /// The record fields of category [id] and of its direct children, deleted or not, by
  /// id.
  Map<String, Map<String, Object?>> categoryRecordsOf(String id) => {
    for (final entry in _categories.values)
      if (entry.category.id == id || entry.category.parentId == id)
        entry.category.id: categoryRecordJson(
          entry.category,
          deletedAt: entry.deletedAt,
        ),
  };

  // Watching --------------------------------------------------------------------------

  /// [read] now, then again after every change, emitting only values that differ from
  /// the last one emitted by [same] (`==` by default). An error from [read] is emitted as
  /// an error event.
  Stream<T> watch<T>(T Function() read, {bool Function(T, T)? same}) {
    final bool Function(T, T) equal = same ?? (a, b) => a == b;
    return Stream<T>.multi((controller) {
      late T last;
      bool emitted = false;
      void emit() {
        try {
          final T value = read();
          if (emitted && equal(last, value)) return;
          last = value;
          emitted = true;
          controller.add(value);
        } on Object catch (e, s) {
          controller.addError(e, s);
        }
      }

      emit();
      final StreamSubscription<void> subscription = _changes.stream.listen(
        (_) => emit(),
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  void _changed() => _changes.add(null);

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}
