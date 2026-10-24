/// The accounts, transactions and categories held in memory: the shared state behind the
/// in-memory repositories (tests) and the demo ones (the demo flavor, loaded with the demo
/// seed).
///
/// One store backs all three repositories because they depend on each other: a derived
/// balance sums the store's transactions, a transaction's currency is checked against its
/// account's, and an account's delete takes its transactions with it. The rules are the
/// Drift repositories' rules, and both pass the same contract suites
/// (`test/contract/`); in particular text matching ignores case for ASCII letters only, as
/// SQLite's `LIKE` and `NOCASE` do. The operations are synchronous, so the demo seed can be
/// loaded in a provider; the repositories wrap them in futures and streams.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
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
  final StreamController<void> _changes = StreamController<void>.broadcast();

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
    _accounts[account.id] = (account: account, deletedAt: null);
    _changed();
  }

  /// `AccountRepository.delete`.
  void deleteAccount(String id) {
    final entry = _accounts[id];
    if (entry == null || entry.deletedAt != null) return;
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
    final Transaction? existing = _transactions[transaction.id];
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('transaction', transaction.id);
    }
    checkAuditInstants(transaction);
    final Account? owner = account(transaction.accountId);
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
    _transactions[transaction.id] = transaction.copyWith(deletedAt: null);
    _changed();
  }

  /// `TransactionRepository.delete`.
  void deleteTransaction(String id) {
    final Transaction? t = transaction(id);
    if (t == null) return;
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
    final String? text = q.text == null || q.text!.isEmpty
        ? null
        : asciiLowerCase(q.text!);
    bool contains(String? field) =>
        field != null && asciiLowerCase(field).contains(text!);
    bool withinBound(Transaction t, Money? bound, bool isMin) {
      if (bound == null) return true;
      if (t.amount.currencyCode != bound.currencyCode) return false;
      final int amount = t.amount.minorUnits.abs();
      return isMin ? amount >= bound.minorUnits : amount <= bound.minorUnits;
    }

    final List<Transaction> matching = [
      for (final Transaction t in _transactions.values)
        if (t.deletedAt == null &&
            (q.accountIds.isEmpty || q.accountIds.contains(t.accountId)) &&
            (q.categoryIds.isEmpty ||
                q.categoryIds.contains(t.userCategoryId) ||
                t.splits.any((s) => q.categoryIds.contains(s.categoryId))) &&
            (q.range == null || q.range!.contains(t.date)) &&
            (text == null ||
                contains(t.name) ||
                contains(t.merchantName) ||
                contains(t.notes)) &&
            (q.pending == null || t.pending == q.pending) &&
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
