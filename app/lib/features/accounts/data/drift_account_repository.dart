/// The [AccountRepository] of the dev and prod flavors, over the `accounts` and
/// `transactions` tables (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Accounts in [AppDatabase]. Audit fields are stamped from the clock: `created_at` on
/// insert, `updated_at` on every write, `deleted_at` on delete.
final class DriftAccountRepository implements AccountRepository {
  /// The repository over [_database], stamping writes from [_clock].
  DriftAccountRepository(this._database, this._clock);

  final AppDatabase _database;
  final Clock _clock;

  $AccountsTable get _accounts => _database.accounts;

  @override
  Stream<List<Account>> watchAll() =>
      (_database.select(_accounts)
            ..where((a) => a.deletedAt.isNull())
            ..orderBy([
              (a) => OrderingTerm.asc(a.isHidden),
              (a) => OrderingTerm.asc(a.displayOrder),
              (a) => OrderingTerm.asc(a.id),
            ]))
          .watch()
          .map((rows) => rows.map(accountFromRow).toList())
          .distinct(sameList);

  @override
  Stream<Account?> watchById(String id) =>
      (_database.select(_accounts)
            ..where((a) => a.id.equals(id) & a.deletedAt.isNull()))
          .watchSingleOrNull()
          .map((row) => row == null ? null : accountFromRow(row))
          .distinct();

  @override
  Future<void> upsert(Account account) => _database.transaction(() async {
    final AccountRow? existing = await (_database.select(
      _accounts,
    )..where((a) => a.id.equals(account.id))).getSingleOrNull();
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('account', account.id);
    }
    final String currency = account.currencyCode;
    final int? current = minorUnitsIn(account.currentBalance, currency);
    final int? available = minorUnitsIn(account.availableBalance, currency);
    final int? limit = minorUnitsIn(account.creditLimit, currency);
    if (existing != null && existing.currency != currency) {
      final TypedResult? any =
          await (_database.selectOnly(_database.transactions)
                ..addColumns([_database.transactions.id])
                ..where(_database.transactions.accountId.equals(account.id))
                ..limit(1))
              .getSingleOrNull();
      if (any != null) {
        throw CurrencyMismatchException(existing.currency, currency);
      }
    }
    final DateTime now = _clock.nowUtc();
    await _database
        .into(_accounts)
        .insertOnConflictUpdate(
          AccountsCompanion(
            id: Value(account.id),
            itemId: Value(account.itemId),
            type: Value(account.type),
            subtype: Value(account.subtype),
            name: Value(account.name),
            officialName: Value(account.officialName),
            mask: Value(account.mask),
            currency: Value(currency),
            currentBalanceMinor: Value(current),
            availableBalanceMinor: Value(available),
            creditLimitMinor: Value(limit),
            balancesAsOf: Value(account.balancesAsOf),
            isHidden: Value(account.isHidden),
            displayOrder: Value(account.displayOrder),
            createdAt: Value(existing?.createdAt ?? now),
            updatedAt: Value(now),
          ),
        );
  });

  @override
  Future<void> delete(String id) => _database.transaction(() async {
    final DateTime now = _clock.nowUtc();
    final int changed =
        await (_database.update(
          _accounts,
        )..where((a) => a.id.equals(id) & a.deletedAt.isNull())).write(
          AccountsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
    if (changed == 0) return;
    await (_database.update(
      _database.transactions,
    )..where((t) => t.accountId.equals(id) & t.deletedAt.isNull())).write(
      TransactionsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        deletedWithAccount: const Value(true),
      ),
    );
  });

  @override
  Future<void> restore(String id) => _database.transaction(() async {
    final DateTime now = _clock.nowUtc();
    final int changed =
        await (_database.update(
          _accounts,
        )..where((a) => a.id.equals(id) & a.deletedAt.isNotNull())).write(
          AccountsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now),
          ),
        );
    if (changed == 0) return;
    await (_database.update(_database.transactions)..where(
          (t) => t.accountId.equals(id) & t.deletedWithAccount.equals(true),
        ))
        .write(
          TransactionsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now),
            deletedWithAccount: const Value(false),
          ),
        );
  });

  @override
  Stream<Money?> watchDerivedBalance(String id) =>
      _balances(id).map((balances) => balances[id]).distinct();

  @override
  Stream<Map<String, Money?>> watchDerivedBalances() =>
      _balances(null).distinct(sameMap);

  // One SQL sum per live account, over its live transactions in its currency (the
  // currency check on write makes that every transaction; the join repeats it).
  Stream<Map<String, Money?>> _balances(String? id) => _database
      .customSelect(
        'SELECT a.id AS id, a.currency AS currency, '
        'SUM(t.amount_minor) AS total, COUNT(t.id) AS n '
        'FROM accounts a LEFT JOIN transactions t '
        'ON t.account_id = a.id AND t.deleted_at IS NULL '
        'AND t.currency = a.currency '
        'WHERE a.deleted_at IS NULL${id == null ? '' : ' AND a.id = ?'} '
        'GROUP BY a.id',
        variables: [if (id != null) Variable.withString(id)],
        readsFrom: {_accounts, _database.transactions},
      )
      .watch()
      .map(
        (rows) => {
          for (final QueryRow row in rows)
            row.read<String>('id'): row.read<int>('n') == 0
                ? null
                : Money(row.read<int>('total'), row.read<String>('currency')),
        },
      );
}

/// The [Account] a row holds.
Account accountFromRow(AccountRow row) => Account(
  id: row.id,
  itemId: row.itemId,
  type: row.type,
  subtype: row.subtype,
  name: row.name,
  officialName: row.officialName,
  mask: row.mask,
  currencyCode: row.currency,
  currentBalance: moneyOrNull(row.currentBalanceMinor, row.currency),
  availableBalance: moneyOrNull(row.availableBalanceMinor, row.currency),
  creditLimit: moneyOrNull(row.creditLimitMinor, row.currency),
  balancesAsOf: row.balancesAsOf,
  isHidden: row.isHidden,
  displayOrder: row.displayOrder,
);
