/// The Plaid-sourced data endpoints: `listAccounts`, `listTransactions`, `getLiabilities`,
/// `listHoldings`, `listInvestmentTransactions` and `listRecurringStreams`
/// (`docs/reference/server.md`, **Data endpoints**).
///
/// Accounts, transactions and recurring streams are written through `shared_models`'
/// entities, whose JSON the contract mirrors. Transaction amounts are in our sign (Plaid's
/// flipped at ingestion); balances, limits, liability amounts and holding values are the
/// institution's reported figures. The user-authored fields of a Plaid transaction
/// (category, notes, tags, splits, receipt) travel through the change log and are always
/// empty here. Accounts, liabilities, holdings, securities and investment transactions
/// store their `source` but do not expose it until a later contract change does. Rows of
/// an Item marked `plaid_removed_at` are hidden from every endpoint, unless the Item was
/// unlinked with its history kept (status `removed`).
library;

import 'dart:convert';

import 'package:finance_tracker_server/src/data/versions.dart';
import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/api_route.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart' show Row;

/// Rows of an Item already removed at Plaid (a deletion that stopped part-way) are
/// hidden, as the Item is; an Item unlinked with its history kept (`removed`) keeps its
/// rows visible. Rows whose Item row is gone (tombstones of a deleted Item) stay visible.
const _live =
    'NOT EXISTS (SELECT 1 FROM items i WHERE i.id = x.item_id '
    "AND i.plaid_removed_at IS NOT NULL AND i.status <> 'removed')";

DateTime _instant(int millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);

LocalDate? _date(Object? text) =>
    text == null ? null : LocalDate.parse(text as String);

Money? _money(Object? minor, String currency) =>
    minor == null ? null : Money(minor as int, currency);

/// The contract's `Account` from an `accounts` row.
Map<String, Object?> accountJson(Map<String, Object?> a) => Account(
  id: a['id'] as String,
  itemId: a['item_id'] as String,
  type: AccountType.values.byName(a['type'] as String),
  subtype: a['subtype'] as String?,
  name: a['name'] as String,
  officialName: a['official_name'] as String?,
  mask: a['mask'] as String?,
  currencyCode: a['currency_code'] as String,
  currentBalance: _money(
    a['current_balance_minor'],
    a['currency_code'] as String,
  ),
  availableBalance: _money(
    a['available_balance_minor'],
    a['currency_code'] as String,
  ),
  creditLimit: _money(a['credit_limit_minor'], a['currency_code'] as String),
  balancesAsOf: a['balances_as_of'] == null
      ? null
      : _instant(a['balances_as_of'] as int),
  isHidden: false,
  displayOrder: a['display_order'] as int,
).toJson();

/// The data routes over [db].
List<ApiRoute> dataRoutes(AppDatabase db) => [
  ApiRoute('listAccounts', 'get', '/accounts', (r) async {
    final rows = await db.read(
      (tx) => tx.select(
        'SELECT a.* FROM accounts a JOIN items i ON i.id = a.item_id '
        "WHERE a.user_id = ? AND (i.plaid_removed_at IS NULL OR i.status = 'removed') "
        'ORDER BY a.display_order, a.id',
        [r.userId],
      ),
    );
    return jsonResponse([for (final a in rows) accountJson(a)]);
  }),
  ApiRoute('listTransactions', 'get', '/transactions', (r) async {
    final page = await _page(db, r, 'transactions');
    return jsonResponse({
      'transactions': [for (final t in page.rows) _transaction(t).toJson()],
      'next_since': page.nextSince,
      'has_more': page.hasMore,
    });
  }),
  ApiRoute('getLiabilities', 'get', '/liabilities', (r) async {
    final rows = await db.read(
      (tx) => tx.select(
        'SELECT kind, payload FROM liabilities x WHERE user_id = ? AND $_live '
        'ORDER BY account_id',
        [r.userId],
      ),
    );
    List<Object?> of(String kind) => [
      for (final row in rows)
        if (row['kind'] == kind) jsonDecode(row['payload'] as String),
    ];
    return jsonResponse({
      'credit': of('credit'),
      'mortgage': of('mortgage'),
      'student': of('student'),
    });
  }),
  ApiRoute('listHoldings', 'get', '/investments/holdings', (r) async {
    final (holdings, securities) = await db.read(
      (tx) => (
        tx.select(
          'SELECT * FROM holdings x WHERE user_id = ? AND $_live '
          'ORDER BY account_id, security_id',
          [r.userId],
        ),
        tx.select(
          'SELECT * FROM securities x WHERE user_id = ? AND $_live '
          'ORDER BY security_id, item_id',
          [r.userId],
        ),
      ),
    );
    final seen = <String>{};
    return jsonResponse({
      'holdings': [
        for (final h in holdings)
          {
            'account_id': h['account_id'],
            'security_id': h['security_id'],
            'quantity': h['quantity'],
            'institution_price': h['institution_price'],
            'institution_price_as_of': h['institution_price_as_of'],
            'institution_value': Money(
              h['institution_value_minor'] as int,
              h['currency_code'] as String,
            ).toJson(),
            'cost_basis': _money(
              h['cost_basis_minor'],
              h['currency_code'] as String,
            )?.toJson(),
            'currency_code': h['currency_code'],
          },
      ],
      'securities': [
        for (final s in securities)
          if (seen.add(s['security_id'] as String))
            {
              'id': s['security_id'],
              'name': s['name'],
              'ticker_symbol': s['ticker_symbol'],
              'type': s['type'],
              'is_cash_equivalent': s['is_cash_equivalent'] == null
                  ? null
                  : s['is_cash_equivalent'] == 1,
              'close_price': s['close_price'],
              'close_price_as_of': s['close_price_as_of'],
              'currency_code': s['currency_code'],
            },
      ],
    });
  }),
  ApiRoute('listInvestmentTransactions', 'get', '/investments/transactions', (
    r,
  ) async {
    final page = await _page(db, r, 'investment_transactions');
    return jsonResponse({
      'investment_transactions': [
        for (final t in page.rows)
          {
            'id': t['id'],
            'account_id': t['account_id'],
            'security_id': t['security_id'],
            'date': t['date'],
            'name': t['name'],
            'type': t['type'],
            'subtype': t['subtype'],
            'quantity': t['quantity'],
            'price': t['price'],
            'amount': Money(
              t['amount_minor'] as int,
              t['currency'] as String,
            ).toJson(),
            'fees': _money(t['fees_minor'], t['currency'] as String)?.toJson(),
            'deleted_at': optionalInstantJson(t['deleted_at'] as int?),
            'sync_version': t['sync_version'],
          },
      ],
      'next_since': page.nextSince,
      'has_more': page.hasMore,
    });
  }),
  ApiRoute('listRecurringStreams', 'get', '/recurring', (r) async {
    final rows = await db.read(
      (tx) => tx.select(
        'SELECT * FROM recurring_streams x WHERE user_id = ? AND $_live '
        'ORDER BY merchant_name, id',
        [r.userId],
      ),
    );
    return jsonResponse([
      for (final s in rows)
        RecurringStream(
          id: s['id'] as String,
          accountId: s['account_id'] as String,
          merchantName: s['merchant_name'] as String,
          cadence: RecurringCadence.values.firstWhere(
            (c) => _snake(c.name) == s['cadence'],
          ),
          averageAmount: Money(
            s['average_amount_minor'] as int,
            s['currency'] as String,
          ),
          lastExpected: _date(s['last_date']),
          nextExpected: _date(s['next_date']),
          status: RecurringStatus.values.byName(s['status'] as String),
          isSubscription: s['is_subscription'] == 1,
          // A stream's finder is the stored provenance: `plaid` from the real client,
          // `demo` from the fake one.
          source: RecurringSource.values.byName(s['source'] as String),
        ).toJson(),
    ]);
  }),
];

String _snake(String camel) =>
    camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

Transaction _transaction(Row t) => Transaction(
  id: t['id'] as String,
  accountId: t['account_id'] as String,
  amount: Money(t['amount_minor'] as int, t['currency'] as String),
  date: LocalDate.parse(t['date'] as String),
  authorizedDate: _date(t['authorized_date']),
  pending: t['pending'] == 1,
  pendingTransactionId: t['pending_transaction_id'] as String?,
  name: t['name'] as String,
  merchantName: t['merchant_name'] as String?,
  merchantLogoUrl: t['merchant_logo_url'] == null
      ? null
      : Uri.parse(t['merchant_logo_url'] as String),
  plaidPrimaryCategory: t['plaid_primary_category'] as String?,
  plaidDetailedCategory: t['plaid_detailed_category'] as String?,
  source: DataSource.values.byName(t['source'] as String),
  createdAt: _instant(t['created_at'] as int),
  updatedAt: _instant(t['updated_at'] as int),
  deletedAt: t['deleted_at'] == null ? null : _instant(t['deleted_at'] as int),
  syncVersion: t['sync_version'] as int,
);

/// One page of [table] by `sync_version` for the caller: `since` and `limit` from the
/// query; a `since` past the user's current version is 409 `sync_cursor_invalid`.
Future<({List<Row> rows, int nextSince, bool hasMore})> _page(
  AppDatabase db,
  ApiRequest r,
  String table,
) async {
  final errors = <FieldError>[];
  final Request raw = r.raw;
  final since = queryInt(raw, 'since', fallback: 0, min: 0, errors: errors);
  final limit = queryInt(
    raw,
    'limit',
    fallback: 500,
    min: 1,
    max: 500,
    errors: errors,
  );
  if (errors.isNotEmpty) throw ValidationException(errors);
  return db.read((tx) {
    final current = currentVersion(tx, r.userId);
    if (since! > current) {
      throw ProblemException(
        409,
        ProblemCode.syncCursorInvalid,
        detail:
            'since $since is past the current version $current; reset the cursor to 0 '
            'and read again',
      );
    }
    final rows = tx.select(
      'SELECT * FROM $table x WHERE user_id = ? AND sync_version > ? AND $_live '
      'ORDER BY sync_version LIMIT ?',
      [r.userId, since, limit! + 1],
    );
    final hasMore = rows.length > limit;
    final page = hasMore ? rows.sublist(0, limit) : rows.toList();
    return (
      rows: page,
      nextSince: page.isEmpty ? since : page.last['sync_version'] as int,
      hasMore: hasMore,
    );
  });
}
