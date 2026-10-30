/// The [TransactionRepository] of the dev and prod flavors, over the `transactions`,
/// `transaction_tags` and `transaction_splits` tables (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/full_text_search.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/transactions/domain/search_text.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
import 'package:shared_models/shared_models.dart';

/// Transactions in [AppDatabase]. A query is one SELECT over `transactions` with the
/// filters as SQL (see [_filter]); the page's tags and splits are loaded after it. The
/// search text goes through the full-text index when the database has one
/// ([AppDatabase.fullTextSearch]), else through the LIKE fallback. Every
/// write to a transaction rewrites its row, so watching `transactions` sees tag and split
/// changes too. Every local write records the transaction through [_recorder] in the
/// same database transaction; [applyPlaid], the server's, records nothing.
final class DriftTransactionRepository implements TransactionRepository {
  /// The repository over [_database], stamping deletes from [_clock] and recording writes
  /// through `recorder`.
  DriftTransactionRepository(
    this._database,
    this._clock, {
    required this._recorder,
  });

  final AppDatabase _database;
  final Clock _clock;
  final ChangeRecorder _recorder;

  $TransactionsTable get _transactions => _database.transactions;

  @override
  Stream<List<Transaction>> watch(TransactionQuery query) =>
      Stream.fromFuture(_database.fullTextSearch)
          .asyncExpand((fts) => _watch(query, fts: fts));

  Stream<List<Transaction>> _watch(
    TransactionQuery query, {
    required bool fts,
  }) {
    final SimpleSelectStatement<$TransactionsTable, TransactionRow> select =
        _database.select(_transactions)
          ..where((t) => _filter(t, query, fts: fts))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]);
    final int? limit = query.limit;
    if (limit != null) {
      select.limit(limit, offset: query.offset);
    } else if (query.offset > 0) {
      select.limit(
        -1,
        offset: query.offset,
      ); // SQLite: no limit, with an offset
    }
    return select
        .watch()
        .asyncMap((rows) => transactionsWithChildren(_database, rows))
        .distinct(sameList);
  }

  @override
  Stream<Transaction?> watchById(String id) =>
      (_database.select(_transactions)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .watchSingleOrNull()
          .asyncMap(
            (row) async => row == null
                ? null
                : (await transactionsWithChildren(_database, [row])).single,
          )
          .distinct();

  @override
  Future<void> upsert(Transaction transaction) =>
      _database.transaction(() => _upsert(transaction));

  @override
  Future<void> upsertAll(List<Transaction> batch) async {
    checkDistinctIds([for (final Transaction t in batch) t.id]);
    if (batch.isEmpty) return;
    await _database.transaction(() async {
      for (final Transaction t in batch) {
        await _refusedAs(t.id, () => _upsert(t, overridesOnly: true));
      }
    });
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    if (ids.isEmpty) return;
    await _database.transaction(() async {
      for (final String id in ids) {
        await _refusedAs(id, () => delete(id));
      }
    });
  }

  // Runs [write] for transaction [id] of a batch, reporting a refusal as the batch's.
  Future<void> _refusedAs(String id, Future<void> Function() write) async {
    try {
      await write();
    } on Object catch (e) {
      if (!isBatchRefusal(e)) rethrow;
      throw TransactionBatchException(id, e);
    }
  }

  // upsert's write, inside the caller's database transaction; with [overridesOnly], a
  // `plaid` row may change only the fields the user owns (upsertAll).
  Future<void> _upsert(
    Transaction transaction, {
    bool overridesOnly = false,
  }) async {
    checkAuditInstants(transaction);
    final String id = transaction.id;
    final TransactionRow? existing = await (_database.select(
      _transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('transaction', id);
    }
    final AccountRow? account =
        await (_database.select(_database.accounts)..where(
              (a) => a.id.equals(transaction.accountId) & a.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (account == null) {
      throw AccountNotFoundException(transaction.accountId);
    }
    final Transaction? stored = existing == null
        ? null
        : (await transactionsWithChildren(_database, [existing])).single;
    if (overridesOnly) checkPlaidOverridesOnly(transaction, stored);
    final Map<String, Object?>? before = stored == null
        ? null
        : transactionRecordJson(
            stored,
            deletedWithAccount: existing!.deletedWithAccount,
          );
    await writeTransactionRow(
      _database,
      transaction,
      currency: account.currency,
    );
    await _recorder.record(
      EntityType.transaction,
      id,
      before,
      transactionRecordJson(transaction.copyWith(deletedAt: null)),
    );
  }

  @override
  Future<List<Transaction>> applyPlaid(List<Transaction> page) =>
      _database.transaction(() async {
        final Map<String, Transaction> stored = {};
        final List<String> ids = [for (final Transaction t in page) t.id];
        for (int start = 0; start < ids.length; start += 500) {
          final List<String> chunk = ids.sublist(
            start,
            start + 500 > ids.length ? ids.length : start + 500,
          );
          final List<TransactionRow> rows = await (_database.select(
            _transactions,
          )..where((t) => t.id.isIn(chunk))).get();
          for (final Transaction t in await transactionsWithChildren(
            _database,
            rows,
          )) {
            stored[t.id] = t;
          }
        }
        final List<Transaction> inserted = [];
        for (final Transaction t in page) {
          final Transaction? old = stored[t.id];
          if (old == null && t.deletedAt != null) continue;
          final Transaction row = old == null ? t : withPlaidOverrides(t, old);
          await writeTransactionRow(
            _database,
            row,
            currency: row.amount.currencyCode,
            deletedAt: Value(row.deletedAt),
          );
          if (row.deletedAt != null) {
            // Plaid removed it (a pending row its posted one replaced included): its
            // sync record carries no tombstone, so its conflicts go here.
            await (_database.delete(_database.conflicts)..where(
                  (c) =>
                      c.entityType.equals('transaction') &
                      c.entityId.equals(t.id),
                ))
                .go();
          }
          if (old == null) inserted.add(row);
        }
        return inserted;
      });

  @override
  Future<void> delete(String id) => _database.transaction(() async {
    final TransactionRow? row = await (_database.select(
      _transactions,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    if (row == null) return;
    if (row.source == DataSource.plaid) {
      throw BankDataNotDeletableException('transaction', id);
    }
    final DateTime now = _clock.nowUtc();
    await (_database.update(
      _transactions,
    )..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    await _recordChange(row);
  });

  @override
  Future<void> restore(String id) => _database.transaction(() async {
    final TransactionRow? row = await (_database.select(
      _transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null || row.deletedAt == null) return;
    final AccountRow? account =
        await (_database.select(_database.accounts)
              ..where((a) => a.id.equals(row.accountId) & a.deletedAt.isNull()))
            .getSingleOrNull();
    if (account == null) throw AccountNotFoundException(row.accountId);
    await (_database.update(
      _transactions,
    )..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(_clock.nowUtc()),
        deletedWithAccount: const Value(false),
      ),
    );
    await _recordChange(row);
  });

  // Records the change of the transaction [before] held to what its row holds now.
  Future<void> _recordChange(TransactionRow before) async {
    final TransactionRow after = await (_database.select(
      _transactions,
    )..where((t) => t.id.equals(before.id))).getSingle();
    await _recorder.record(
      EntityType.transaction,
      before.id,
      await _recordJson(before),
      await _recordJson(after),
    );
  }

  Future<Map<String, Object?>> _recordJson(TransactionRow row) async =>
      transactionRecordJson(
        (await transactionsWithChildren(_database, [row])).single,
        deletedWithAccount: row.deletedWithAccount,
      );

  @override
  Future<List<Transaction>> unhashedReceipts() async =>
      transactionsWithChildren(
        _database,
        await (_database.select(_transactions)..where(
              (t) =>
                  t.receiptPath.isNotNull() &
                  t.receiptSha256.isNull() &
                  t.deletedAt.isNull(),
            ))
            .get(),
      );

  @override
  Future<int> count(TransactionQuery query) async {
    final Expression<int> count = _transactions.id.count();
    final TypedResult row =
        await (_database.selectOnly(_transactions)
              ..addColumns([count])
              ..where(
                _filter(
                  _transactions,
                  query,
                  fts: await _database.fullTextSearch,
                ),
              ))
            .getSingle();
    return row.read(count)!;
  }

  @override
  Stream<TransactionUsage> watchUsage({int recentLimit = 20}) {
    checkRecentLimit(recentLimit);
    final Set<ResultSetImplementation<dynamic, dynamic>> tables = {
      _transactions,
      _database.transactionTags,
    };
    // The most recently used values of [column] among live transactions: one row per
    // value, ordered by its newest created_at, ties by the value.
    Future<List<String>> recent(String column) async => [
      for (final QueryRow row
          in await _database
              .customSelect(
                'SELECT $column AS id FROM transactions '
                'WHERE deleted_at IS NULL AND $column IS NOT NULL '
                'GROUP BY $column ORDER BY MAX(created_at) DESC, $column ASC '
                'LIMIT ?',
                variables: [Variable.withInt(recentLimit)],
                readsFrom: tables,
              )
              .get())
        row.read<String>('id'),
    ];
    return _database
        .customSelect(
          'SELECT DISTINCT tg.tag AS tag FROM transaction_tags tg '
          'JOIN transactions t ON t.id = tg.transaction_id '
          'WHERE t.deleted_at IS NULL ORDER BY tg.tag',
          readsFrom: tables,
        )
        .watch()
        .asyncMap(
          (rows) async => TransactionUsage(
            tags: [for (final QueryRow row in rows) row.read<String>('tag')],
            recentCategoryIds: await recent('user_category_id'),
            recentAccountIds: await recent('account_id'),
          ),
        )
        .distinct();
  }

  // The query's filters as one SQL condition (TransactionQuery documents each); the
  // text through the full-text index when [fts], else by LIKE.
  Expression<bool> _filter(
    $TransactionsTable t,
    TransactionQuery q, {
    required bool fts,
  }) {
    final List<Expression<bool>> conditions = [t.deletedAt.isNull()];
    if (q.accountIds.isNotEmpty) conditions.add(t.accountId.isIn(q.accountIds));
    if (q.categoryIds.isNotEmpty || q.categoryPlaidCodes.isNotEmpty) {
      final $TransactionSplitsTable s = _database.transactionSplits;
      final List<Expression<bool>> any = [
        t.userCategoryId.isIn(q.categoryIds),
        existsQuery(
          _database.selectOnly(s)
            ..addColumns([s.position])
            ..where(
              s.transactionId.equalsExp(t.id) &
                  s.categoryId.isIn(q.categoryIds),
            ),
        ),
      ];
      if (q.categoryPlaidCodes.isNotEmpty) {
        any.add(_byPlaidCode(t, q.categoryPlaidCodes));
      }
      conditions.add(Expression.or(any));
    }
    final LocalDateRange? range = q.range;
    if (range != null) {
      conditions.add(
        t.date.isBiggerOrEqualValue(range.start.toIso()) &
            t.date.isSmallerThanValue(range.end.toIso()),
      );
    }
    final String? text = q.text;
    final List<String> terms = searchTerms(text ?? '');
    if (fts && terms.isNotEmpty) {
      conditions.add(_FullTextMatch(t.id, terms));
    } else if (!fts && text != null && text.isNotEmpty) {
      final String pattern = '%${_escapeLike(text)}%';
      conditions.add(
        t.name.like(pattern, escapeChar: r'\') |
            t.merchantName.like(pattern, escapeChar: r'\') |
            t.notes.like(pattern, escapeChar: r'\'),
      );
    }
    final bool? pending = q.pending;
    if (pending != null) conditions.add(t.pending.equals(pending));
    final bool? hidden = q.hidden;
    if (hidden != null) conditions.add(t.hidden.equals(hidden));
    if (q.tags.isNotEmpty) {
      final $TransactionTagsTable g = _database.transactionTags;
      conditions.add(
        existsQuery(
          _database.selectOnly(g)
            ..addColumns([g.position])
            ..where(g.transactionId.equalsExp(t.id) & g.tag.isIn(q.tags)),
        ),
      );
    }
    final Money? min = q.minAmount;
    if (min != null) {
      conditions.add(
        t.currency.equals(min.currencyCode) &
            t.amountMinor.abs().isBiggerOrEqualValue(min.minorUnits),
      );
    }
    final Money? max = q.maxAmount;
    if (max != null) {
      conditions.add(
        t.currency.equals(max.currencyCode) &
            t.amountMinor.abs().isSmallerOrEqualValue(max.minorUnits),
      );
    }
    return Expression.and(conditions);
  }

  // Whether t has no live user category and its Plaid code resolves to one of [codes]:
  // its detailed code when a live category has it, else its primary code
  // (`effective_category.dart`).
  Expression<bool> _byPlaidCode($TransactionsTable t, Set<String> codes) {
    final $CategoriesTable c = _database.categories;
    // Whether a live category matches [match].
    Expression<bool> live(Expression<bool> match) => existsQuery(
      _database.selectOnly(c)
        ..addColumns([c.id])
        ..where(match & c.deletedAt.isNull()),
    );
    final Expression<bool> detailedResolves = live(
      c.plaidCategory.equalsExp(t.plaidDetailedCategory),
    );
    return Expression.and([
      t.userCategoryId.isNull() | live(c.id.equalsExp(t.userCategoryId)).not(),
      Expression.or([
        Expression.and([t.plaidDetailedCategory.isIn(codes), detailedResolves]),
        Expression.and([
          t.plaidPrimaryCategory.isIn(codes),
          detailedResolves.not(),
          live(c.plaidCategory.equalsExp(t.plaidPrimaryCategory)),
        ]),
      ]),
    ]);
  }
}

/// The transactions [rows] hold, with their tags and splits, loaded in chunks so the IN
/// lists stay far below SQLite's variable limit. `deletedAt` is the row's.
Future<List<Transaction>> transactionsWithChildren(
  AppDatabase database,
  List<TransactionRow> rows,
) async {
  final Map<String, List<String>> tags = {};
  final Map<String, List<TransactionSplit>> splits = {};
  final List<String> ids = [for (final TransactionRow row in rows) row.id];
  for (int start = 0; start < ids.length; start += 500) {
    final List<String> chunk = ids.sublist(
      start,
      start + 500 > ids.length ? ids.length : start + 500,
    );
    final List<TransactionTagRow> tagRows =
        await (database.select(database.transactionTags)
              ..where((g) => g.transactionId.isIn(chunk))
              ..orderBy([(g) => OrderingTerm.asc(g.position)]))
            .get();
    for (final TransactionTagRow tag in tagRows) {
      (tags[tag.transactionId] ??= []).add(tag.tag);
    }
    final List<TransactionSplitRow> splitRows =
        await (database.select(database.transactionSplits)
              ..where((s) => s.transactionId.isIn(chunk))
              ..orderBy([(s) => OrderingTerm.asc(s.position)]))
            .get();
    final Map<String, String> currencies = {
      for (final TransactionRow row in rows) row.id: row.currency,
    };
    for (final TransactionSplitRow split in splitRows) {
      (splits[split.transactionId] ??= []).add(
        TransactionSplit(
          categoryId: split.categoryId,
          amount: Money(split.amountMinor, currencies[split.transactionId]!),
          note: split.note,
        ),
      );
    }
  }
  return [
    for (final TransactionRow row in rows)
      Transaction(
        id: row.id,
        accountId: row.accountId,
        amount: Money(row.amountMinor, row.currency),
        date: row.date,
        authorizedDate: row.authorizedDate,
        pending: row.pending,
        pendingTransactionId: row.pendingTransactionId,
        name: row.name,
        merchantName: row.merchantName,
        merchantLogoUrl: row.merchantLogoUrl,
        plaidPrimaryCategory: row.plaidPrimaryCategory,
        plaidDetailedCategory: row.plaidDetailedCategory,
        userCategoryId: row.userCategoryId,
        notes: row.notes,
        tags: tags[row.id] ?? const [],
        splits: splits[row.id] ?? const [],
        receiptPath: row.receiptPath,
        receiptSha256: row.receiptSha256,
        hidden: row.hidden,
        source: row.source,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        syncVersion: row.syncVersion,
      ),
  ];
}

/// Writes [transaction]'s row, replacing its tags and splits, with its amount and splits
/// in [currency] (the account's for a local edit). `deleted_at` and
/// `deleted_with_account` are written only when given. Throws
/// `CurrencyMismatchException` when the amount or a split is in another currency.
Future<void> writeTransactionRow(
  AppDatabase database,
  Transaction transaction, {
  required String currency,
  Value<DateTime?> deletedAt = const Value.absent(),
  Value<bool> deletedWithAccount = const Value.absent(),
}) async {
  final String id = transaction.id;
  final int amount = minorUnitsIn(transaction.amount, currency)!;
  final List<int> splitAmounts = [
    for (final TransactionSplit split in transaction.splits)
      minorUnitsIn(split.amount, currency)!,
  ];
  await database
      .into(database.transactions)
      .insertOnConflictUpdate(
        TransactionsCompanion(
          id: Value(id),
          accountId: Value(transaction.accountId),
          amountMinor: Value(amount),
          currency: Value(currency),
          date: Value(transaction.date),
          authorizedDate: Value(transaction.authorizedDate),
          pending: Value(transaction.pending),
          pendingTransactionId: Value(transaction.pendingTransactionId),
          name: Value(transaction.name),
          merchantName: Value(transaction.merchantName),
          merchantLogoUrl: Value(transaction.merchantLogoUrl),
          plaidPrimaryCategory: Value(transaction.plaidPrimaryCategory),
          plaidDetailedCategory: Value(transaction.plaidDetailedCategory),
          userCategoryId: Value(transaction.userCategoryId),
          notes: Value(transaction.notes),
          receiptPath: Value(transaction.receiptPath),
          receiptSha256: Value(transaction.receiptSha256),
          hidden: Value(transaction.hidden),
          source: Value(transaction.source),
          createdAt: Value(transaction.createdAt),
          updatedAt: Value(transaction.updatedAt),
          deletedAt: deletedAt,
          syncVersion: Value(transaction.syncVersion),
          deletedWithAccount: deletedWithAccount,
        ),
      );
  await (database.delete(
    database.transactionTags,
  )..where((t) => t.transactionId.equals(id))).go();
  await (database.delete(
    database.transactionSplits,
  )..where((s) => s.transactionId.equals(id))).go();
  await database.batch((batch) {
    batch.insertAll(database.transactionTags, [
      for (int i = 0; i < transaction.tags.length; i++)
        TransactionTagsCompanion.insert(
          transactionId: id,
          position: i,
          tag: transaction.tags[i],
        ),
    ]);
    batch.insertAll(database.transactionSplits, [
      for (int i = 0; i < transaction.splits.length; i++)
        TransactionSplitsCompanion.insert(
          transactionId: id,
          position: i,
          categoryId: transaction.splits[i].categoryId,
          amountMinor: splitAmounts[i],
          note: Value(transaction.splits[i].note),
        ),
    ]);
  });
}

/// Whether the transaction [id] matches every one of [terms] in the full-text index:
/// `id IN (SELECT transaction_id FROM transactions_fts WHERE transactions_fts MATCH ?)`
/// with each term quoted as an FTS5 string ([_ftsString]), so none of the user's text
/// reaches the query parser, and marked as a prefix. A term with no token characters
/// matches nothing (`search_text.dart`), so the condition is then false.
final class _FullTextMatch extends Expression<bool> {
  _FullTextMatch(this.id, this.terms);

  final Expression<String> id;
  final List<String> terms;

  @override
  void writeInto(GenerationContext context) {
    if (terms.any((term) => searchTokens(term).isEmpty)) {
      context.buffer.write('0');
      return;
    }
    id.writeInto(context);
    context.buffer.write(
      ' IN (SELECT transaction_id FROM $ftsTable WHERE $ftsTable MATCH ',
    );
    Variable<String>(
      [for (final String term in terms) '"${_ftsString(term)}"*'].join(' '),
    ).writeInto(context);
    context.buffer.write(')');
  }
}

/// [term] as the inside of an FTS5 string: `"` doubled, and U+0000, which would end the
/// string early, as a space, which separates tokens as U+0000 does for the tokenizer
/// (`search_text.dart`).
String _ftsString(String term) =>
    term.replaceAll('"', '""').replaceAll('\u0000', ' ');

/// [text] with `\`, `%` and `_` escaped by a backslash, for `LIKE ... ESCAPE '\'`.
String _escapeLike(String text) =>
    text.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
