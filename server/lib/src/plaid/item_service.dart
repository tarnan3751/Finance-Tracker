/// Plaid Items: Link tokens, the exchange, the Item store, the sync run, refreshes, the
/// balance refresh, unlinking and the institution logo (`docs/reference/server.md`,
/// **Items** and **The sync run**).
///
/// This is the code Phase 3 reuses unchanged with the real client: it depends only on
/// [PlaidClient], and stamps every stored row with the client's `provenance`. Access
/// tokens are stored sealed by [TokenCipher]. No Plaid call is made while a database
/// transaction is open: a sync run fetches every page and every product first, then
/// applies all of it, both cursors included, in one transaction, so a failure part-way
/// leaves the store as it was (`PLAN.md` §4: apply every page before persisting the
/// cursor). Runs are serialized per Item. A secondary product that fails is skipped and
/// logged; the transactions still apply. An Item whose removal at Plaid succeeded, or
/// that Plaid no longer knows (`ITEM_NOT_FOUND`), carries `plaid_removed_at`; it is
/// hidden from every Item and data route, and a retried account deletion skips it, unless
/// it was unlinked with its history kept: then its status is `removed`, it stays listed
/// with its data, and every call that would reach Plaid for it is 409 `conflict`. An
/// exchange whose `/item/get` fails removes the new Item at Plaid before answering, so
/// none is orphaned there; so does an exchange whose user or device went away while Plaid
/// was called, which answers 401 `token_revoked`.
library;

import 'dart:async';
import 'dart:convert';

import 'package:finance_tracker_server/src/data/data_routes.dart'
    show accountJson;
import 'package:finance_tracker_server/src/data/versions.dart';
import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/ids.dart';
import 'package:finance_tracker_server/src/logging.dart';
import 'package:finance_tracker_server/src/plaid/plaid_client.dart';
import 'package:finance_tracker_server/src/plaid/token_cipher.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';

/// The `/transactions/sync` page size (Plaid's maximum).
const plaidSyncPageSize = 500;

/// How often a sync run restarts after `TRANSACTIONS_SYNC_MUTATION_DURING_PAGINATION`
/// before it gives up.
const maxPaginationRestarts = 3;

/// The waits between the three attempts at `/item/remove`.
const removeBackoff = [Duration(milliseconds: 500), Duration(seconds: 1)];

/// The Items a route may see: those not removed at Plaid, and those unlinked with their
/// history kept (`removed`). Rows of an Item whose removal stopped part-way stay hidden.
const visibleItem = "(plaid_removed_at IS NULL OR status = 'removed')";

/// What unlinking does with an Item's data (`deleteItem`'s `history`).
enum UnlinkHistory {
  /// The accounts and other rows go, the transactions become tombstones.
  delete,

  /// Everything stays; the Item is listed as `removed`.
  keep,
}

/// The problem a [PlaidException] is answered with: 429 for Plaid's rate limit, 502
/// `plaid_error` otherwise.
ProblemException plaidProblem(PlaidException e) => e.isRateLimit
    ? const ProblemException(
        429,
        ProblemCode.rateLimited,
        detail: 'Plaid rate-limited the request',
        headers: {'retry-after': '60'},
      )
    : ProblemException(
        502,
        ProblemCode.plaidError,
        detail: 'Plaid answered ${e.errorCode}',
      );

/// The Item flows.
final class ItemService {
  /// The service.
  ItemService({
    required this.db,
    required this.plaid,
    required this.cipher,
    required this.now,
    Future<void> Function(Duration)? delay,
    this.syncPageSize = plaidSyncPageSize,
  }) : delay = delay ?? Future<void>.delayed;

  /// The database.
  final AppDatabase db;

  /// The Plaid client.
  final PlaidClient plaid;

  /// Seals access tokens.
  final TokenCipher cipher;

  /// The server's clock.
  final DateTime Function() now;

  /// Waits between removal attempts (instant in tests).
  final Future<void> Function(Duration) delay;

  /// The `count` of each `/transactions/sync` call.
  final int syncPageSize;

  final Logger _log = Logger('plaid');

  int get _nowMillis => now().millisecondsSinceEpoch;

  String get _source => plaid.provenance.name;

  Future<T> _plaid<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlaidException catch (e) {
      _log.warning(
        LogEvent('plaid_error', {
          'type': e.errorType,
          'code': e.errorCode,
          'request_id': ?e.requestId,
        }),
      );
      throw plaidProblem(e);
    }
  }

  /// A Link token for [userId]; with [updateItemId], in update mode for that Item.
  Future<Map<String, Object?>> createLinkToken(
    String userId, {
    required String androidPackageName,
    String? updateItemId,
  }) async {
    if (updateItemId != null) {
      return createUpdateLinkToken(
        userId,
        updateItemId,
        androidPackageName: androidPackageName,
      );
    }
    final token = await _plaid(
      () => plaid.createLinkToken(
        LinkTokenRequest(
          clientUserId: userId,
          androidPackageName: androidPackageName,
          products: const ['transactions'],
        ),
      ),
    );
    return _linkTokenJson(token);
  }

  /// An update-mode Link token for the Item [itemId] of [userId].
  Future<Map<String, Object?>> createUpdateLinkToken(
    String userId,
    String itemId, {
    required String androidPackageName,
  }) async {
    final item = await _load(userId, itemId);
    if (item.row['status'] == 'removed') {
      throw const ProblemException.notFound('The Item was unlinked');
    }
    final token = await _plaid(
      () => plaid.createUpdateLinkToken(
        item.accessToken,
        clientUserId: userId,
        androidPackageName: androidPackageName,
      ),
    );
    return _linkTokenJson(token);
  }

  /// Exchanges [publicToken] and stores the new Item; the contract's `Item`, its logo URL
  /// under [baseUrl].
  Future<Map<String, Object?>> exchange(
    String userId,
    String deviceId,
    String publicToken, {
    required Uri baseUrl,
  }) async {
    final exchanged = await _plaid(
      () => plaid.exchangePublicToken(publicToken),
    );
    final PlaidItem item;
    try {
      item = await plaid.getItem(exchanged.accessToken);
    } on PlaidException catch (e) {
      await _removeOrphan(exchanged.accessToken);
      _log.warning(
        LogEvent('plaid_error', {
          'type': e.errorType,
          'code': e.errorCode,
          'request_id': ?e.requestId,
        }),
      );
      throw plaidProblem(e);
    }
    final id = newId();
    final sealed = await cipher.seal(exchanged.accessToken, itemId: id);
    final row = await db.transaction((tx) async {
      // The user or the device may have gone while Plaid was called (a concurrent
      // DELETE /me or device removal): store nothing.
      if (tx.first('SELECT 1 FROM devices WHERE id = ? AND user_id = ?', [
            deviceId,
            userId,
          ]) ==
          null) {
        return null;
      }
      tx.execute(
        'INSERT INTO items (id, user_id, plaid_item_id, institution_id, '
        'institution_name, products, access_token_ciphertext, access_token_nonce, '
        'status, error_code, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          id,
          userId,
          exchanged.itemId,
          item.institutionId,
          item.institutionName,
          jsonEncode(item.products),
          sealed.ciphertext,
          sealed.nonce,
          item.errorCode == 'ITEM_LOGIN_REQUIRED'
              ? 'login_required'
              : 'healthy',
          item.errorCode == 'ITEM_LOGIN_REQUIRED' ? item.errorCode : null,
          _nowMillis,
        ],
      );
      return tx.first('SELECT * FROM items WHERE id = ?', [id])!;
    });
    if (row == null) {
      await _removeOrphan(exchanged.accessToken);
      throw const ProblemException.unauthorized(
        ProblemCode.tokenRevoked,
        detail: 'This device was signed out while the Item was being linked',
      );
    }
    _log.info(LogEvent('item_linked', {'user_id': userId, 'item_id': id}));
    return itemJson(row, baseUrl);
  }

  /// Removes, best effort, an Item exchanged at Plaid that the server will not store, so
  /// none is left there that the server does not know about.
  Future<void> _removeOrphan(String accessToken) async {
    try {
      await plaid.removeItem(accessToken);
    } on PlaidException catch (e) {
      _log.warning(
        LogEvent('orphan_item_remove_failed', {'code': e.errorCode}),
      );
    }
  }

  /// The user's Items, `removed` ones included, their logo URLs under [baseUrl].
  Future<List<Map<String, Object?>>> list(
    String userId, {
    required Uri baseUrl,
  }) async {
    final rows = await db.read(
      (tx) => tx.select(
        'SELECT * FROM items WHERE user_id = ? AND $visibleItem '
        'ORDER BY created_at, id',
        [userId],
      ),
    );
    return [for (final r in rows) itemJson(r, baseUrl)];
  }

  /// Unlinks the Item: removes it at Plaid (unless it is `removed` already), then, with
  /// [UnlinkHistory.delete], deletes its rows, leaving its transactions and investment
  /// transactions as tombstones with new versions; with [UnlinkHistory.keep], keeps every
  /// row and marks the Item `removed`.
  Future<void> delete(
    String userId,
    String itemId, {
    UnlinkHistory history = UnlinkHistory.delete,
  }) async {
    final item = await _load(userId, itemId);
    final alreadyRemoved = item.row['status'] == 'removed';
    if (!alreadyRemoved) {
      await removeAtPlaid(
        item.id,
        item.accessToken,
        keepHistory: history == UnlinkHistory.keep,
      );
    }
    if (history == UnlinkHistory.keep) {
      if (!alreadyRemoved) {
        _log.info(
          LogEvent('item_unlinked_kept', {
            'user_id': userId,
            'item_id': itemId,
          }),
        );
      }
      return;
    }
    await db.transaction((tx) async {
      for (final table in const ['transactions', 'investment_transactions']) {
        final live = tx.select(
          'SELECT id FROM $table WHERE item_id = ? AND deleted_at IS NULL',
          [itemId],
        );
        for (final row in live) {
          tx.execute(
            'UPDATE $table SET deleted_at = ?, updated_at = ?, sync_version = ? '
            'WHERE id = ?',
            [_nowMillis, _nowMillis, nextVersion(tx, userId), row['id']],
          );
        }
      }
      tx.execute('DELETE FROM items WHERE id = ?', [itemId]);
    });
    _log.info(LogEvent('item_removed', {'user_id': userId, 'item_id': itemId}));
  }

  /// Calls `/item/remove` up to three times with [removeBackoff] between attempts and
  /// marks the Item `plaid_removed_at`; with [keepHistory], also `removed` in the same
  /// statement, so it stays listed. When every attempt fails, 502 `plaid_error`.
  Future<void> removeAtPlaid(
    String itemId,
    String accessToken, {
    bool keepHistory = false,
  }) async {
    for (var attempt = 1; ; attempt++) {
      try {
        await plaid.removeItem(accessToken);
        break;
      } on PlaidException catch (e) {
        if (e.errorCode == 'ITEM_NOT_FOUND') {
          // Plaid no longer knows the Item: it is removed there already.
          _log.info(LogEvent('item_already_removed', {'item_id': itemId}));
          break;
        }
        _log.warning(
          LogEvent('item_remove_failed', {
            'item_id': itemId,
            'attempt': attempt,
            'code': e.errorCode,
          }),
        );
        if (attempt > removeBackoff.length) {
          throw ProblemException(
            502,
            ProblemCode.plaidError,
            detail:
                'Plaid could not remove an Item (${e.errorCode}); nothing was deleted',
          );
        }
        await delay(removeBackoff[attempt - 1]);
      }
    }
    await db.read(
      (tx) => tx.execute(
        keepHistory
            ? "UPDATE items SET plaid_removed_at = ?, status = 'removed', "
                  'error_code = NULL WHERE id = ?'
            : 'UPDATE items SET plaid_removed_at = ? WHERE id = ?',
        [_nowMillis, itemId],
      ),
    );
  }

  /// The user's Items not yet removed at Plaid, with their access tokens.
  Future<List<({String id, String accessToken})>> itemsToRemove(
    String userId,
  ) async {
    final rows = await db.read(
      (tx) => tx.select(
        'SELECT * FROM items WHERE user_id = ? AND plaid_removed_at IS NULL',
        [userId],
      ),
    );
    return [for (final r in rows) await _open(r)];
  }

  /// Runs `/transactions/sync` for the Item, then the Item's other products, and applies
  /// all of it in one transaction; the contract's `SyncRun`.
  Future<Map<String, Object?>> sync(String userId, String itemId) =>
      _serialized(itemId, () => _sync(userId, itemId));

  /// Runs [body] after every earlier run for [itemId]: one run per Item at a time, so a
  /// second sync starts from the cursor the first stored and no page is applied twice.
  Future<T> _serialized<T>(String itemId, Future<T> Function() body) async {
    final previous = _running[itemId];
    final done = Completer<void>();
    _running[itemId] = done.future;
    try {
      await previous;
      return await body();
    } finally {
      done.complete();
      if (identical(_running[itemId], done.future)) {
        _running.remove(itemId)?.ignore();
      }
    }
  }

  final Map<String, Future<void>> _running = {};

  /// Calls `/transactions/refresh` for the Item, then starts a sync run in the
  /// background (after any run in progress); the contract's `SyncRun` with status
  /// `started`. A failure of the background run is logged, not answered.
  Future<Map<String, Object?>> refresh(String userId, String itemId) async {
    final item = await loadActive(userId, itemId);
    await itemCall(itemId, () => plaid.transactionsRefresh(item.accessToken));
    unawaited(
      sync(userId, itemId).then<void>(
        (_) {},
        onError: (Object e) => _log.warning(
          LogEvent('item_refresh_sync_failed', {
            'item_id': itemId,
            'error_type': e.runtimeType.toString(),
            if (e is ProblemException) 'code': e.code.wire,
          }),
        ),
      ),
    );
    _log.info(LogEvent('item_refresh_started', {'item_id': itemId}));
    return const {
      'status': 'started',
      'added': 0,
      'modified': 0,
      'removed': 0,
      'next_cursor_saved': false,
    };
  }

  /// Calls `/accounts/balance/get` for the Item, stores the reported balances (new
  /// accounts included) and returns the Item's accounts as the contract's `Account`s.
  Future<List<Map<String, Object?>>> refreshBalances(
    String userId,
    String itemId,
  ) => _serialized(itemId, () async {
    final item = await loadActive(userId, itemId);
    final accounts = await itemCall(
      itemId,
      () => plaid.accountsBalanceGet(item.accessToken),
    );
    final rows = await db.transaction((tx) async {
      if (tx.first(
            'SELECT 1 FROM items WHERE id = ? AND user_id = ? '
            'AND plaid_removed_at IS NULL',
            [itemId, userId],
          ) ==
          null) {
        throw const ProblemException.notFound('The Item was removed');
      }
      _upsertAccounts(tx, userId, itemId, accounts);
      return tx.select(
        'SELECT * FROM accounts WHERE item_id = ? ORDER BY display_order, id',
        [itemId],
      );
    });
    _log.info(
      LogEvent('item_balances_refreshed', {
        'item_id': itemId,
        'accounts': rows.length,
      }),
    );
    return [for (final a in rows) accountJson(a)];
  });

  /// The newest logo stored for [institutionId] among [userId]'s visible Items; 404 when
  /// there is none.
  Future<List<int>> institutionLogo(String userId, String institutionId) async {
    final row = await db.read(
      (tx) => tx.first(
        'SELECT institution_logo FROM items WHERE user_id = ? '
        'AND institution_id = ? AND institution_logo IS NOT NULL '
        'AND $visibleItem ORDER BY created_at DESC, id DESC LIMIT 1',
        [userId, institutionId],
      ),
    );
    if (row == null) {
      throw const ProblemException.notFound('No logo for that institution');
    }
    return row['institution_logo']! as List<int>;
  }

  /// A Plaid call for the Item [itemId]: `ITEM_LOGIN_REQUIRED` marks it `login_required`
  /// and answers 409 `item_login_required`; any other failure is [plaidProblem].
  Future<T> itemCall<T>(String itemId, Future<T> Function() call) async {
    try {
      return await call();
    } on PlaidException catch (e) {
      if (e.isLoginRequired) await _markLoginRequired(itemId);
      _log.warning(
        LogEvent('plaid_error', {
          'type': e.errorType,
          'code': e.errorCode,
          'request_id': ?e.requestId,
        }),
      );
      throw e.isLoginRequired ? _loginRequired : plaidProblem(e);
    }
  }

  static const _loginRequired = ProblemException(
    409,
    ProblemCode.itemLoginRequired,
    detail: 'The Item needs re-authentication through Link in update mode',
  );

  /// Marks the Item `login_required`, unless it was removed at Plaid meanwhile (an
  /// unlink, kept or not, while the failing call was in flight): a `removed` Item keeps
  /// its status, so its kept history stays visible.
  Future<void> _markLoginRequired(String itemId) => db.read(
    (tx) => tx.execute(
      "UPDATE items SET status = 'login_required', error_code = ? "
      'WHERE id = ? AND plaid_removed_at IS NULL',
      ['ITEM_LOGIN_REQUIRED', itemId],
    ),
  );

  Future<Map<String, Object?>> _sync(String userId, String itemId) async {
    final item = await loadActive(userId, itemId);
    final startCursor = item.row['cursor'] as String? ?? '';
    final List<TransactionsSyncPage> pages;
    try {
      final fetched = await _fetchAllPages(item.accessToken, startCursor);
      if (fetched == null) {
        _log.info(LogEvent('item_sync_not_ready', {'item_id': itemId}));
        return const {
          'status': 'not_ready',
          'added': 0,
          'modified': 0,
          'removed': 0,
          'next_cursor_saved': false,
        };
      }
      pages = fetched;
    } on PlaidException catch (e) {
      if (e.isLoginRequired) {
        await _markLoginRequired(itemId);
        throw _loginRequired;
      }
      throw plaidProblem(e);
    }
    final products = [
      for (final p
          in jsonDecode(item.row['products'] as String) as List<Object?>)
        p! as String,
    ];
    // A secondary product that fails (PRODUCT_NOT_READY or any other Plaid error) is
    // skipped and logged by name; accounts and transactions still apply.
    Future<T?> secondary<T>(String product, Future<T> Function() call) async {
      try {
        return await call();
      } on PlaidException catch (e) {
        _log.warning(
          LogEvent('item_sync_product_skipped', {
            'item_id': itemId,
            'product': product,
            'code': e.errorCode,
          }),
        );
        return null;
      }
    }

    final currencies = {
      ...await _storedCurrencies(itemId),
      for (final page in pages)
        for (final a in page.accounts) a.accountId: a.currencyCode,
    };
    final recurring = products.contains('transactions')
        ? await secondary(
            'recurring',
            () => plaid.transactionsRecurringGet(
              item.accessToken,
              currencyOf: (accountId) => currencies[accountId],
            ),
          )
        : null;
    final liabilities = products.contains('liabilities')
        ? await secondary(
            'liabilities',
            () => plaid.liabilitiesGet(item.accessToken),
          )
        : null;
    final holdings = products.contains('investments')
        ? await secondary(
            'investments_holdings',
            () => plaid.investmentsHoldingsGet(item.accessToken),
          )
        : null;
    final today = LocalDate.fromDateTime(now().toUtc());
    final investments = products.contains('investments')
        ? await secondary(
            'investments_transactions',
            () => plaid.investmentsTransactionsGet(
              item.accessToken,
              start: today.addDays(-730),
              end: today,
            ),
          )
        : null;

    final counts = await db.transaction((tx) async {
      // The user or the Item may have gone while Plaid was called (a concurrent
      // DELETE /me or DELETE /plaid/items/{id}).
      if (tx.first(
            'SELECT 1 FROM items WHERE id = ? AND user_id = ? '
            'AND plaid_removed_at IS NULL',
            [itemId, userId],
          ) ==
          null) {
        throw const ProblemException.notFound('The Item was removed');
      }
      final accounts = _upsertAccounts(tx, userId, itemId, [
        for (final page in pages) ...page.accounts,
      ]);
      final counts = _applyTransactions(tx, userId, itemId, accounts, pages);
      if (recurring != null) {
        _replaceRecurring(tx, userId, itemId, accounts, recurring);
      }
      if (liabilities != null) {
        _replaceLiabilities(tx, userId, itemId, accounts, liabilities);
      }
      if (holdings != null) {
        _replaceHoldings(tx, userId, itemId, accounts, holdings);
      }
      if (investments != null) {
        _upsertInvestmentTransactions(
          tx,
          userId,
          itemId,
          accounts,
          investments,
        );
      }
      tx.execute(
        "UPDATE items SET cursor = ?, run_start_cursor = ?, status = 'healthy', "
        'error_code = NULL, last_successful_sync_at = ? '
        'WHERE id = ? AND plaid_removed_at IS NULL',
        [pages.last.nextCursor, startCursor, _nowMillis, itemId],
      );
      return counts;
    });
    _log.info(
      LogEvent('item_synced', {
        'item_id': itemId,
        'added': counts.added,
        'modified': counts.modified,
        'removed': counts.removed,
      }),
    );
    return {
      'status': 'completed',
      'added': counts.added,
      'modified': counts.modified,
      'removed': counts.removed,
      'next_cursor_saved': true,
    };
  }

  /// The currencies of the Item's stored accounts, by Plaid's account id.
  Future<Map<String, String>> _storedCurrencies(String itemId) => db.read(
    (tx) => {
      for (final r in tx.select(
        'SELECT plaid_account_id, currency_code FROM accounts WHERE item_id = ?',
        [itemId],
      ))
        r['plaid_account_id'] as String: r['currency_code'] as String,
    },
  );

  /// Every page from [startCursor], or null for `NOT_READY`. Restarts from [startCursor]
  /// on a mutation during pagination, up to [maxPaginationRestarts] times.
  Future<List<TransactionsSyncPage>?> _fetchAllPages(
    String accessToken,
    String startCursor,
  ) async {
    for (var restart = 0; ; restart++) {
      final pages = <TransactionsSyncPage>[];
      var cursor = startCursor;
      try {
        while (true) {
          final page = await plaid.transactionsSync(
            accessToken,
            cursor,
            count: syncPageSize,
          );
          if (page.notReady) return null;
          pages.add(page);
          cursor = page.nextCursor;
          if (!page.hasMore) return pages;
        }
      } on PlaidException catch (e) {
        if (!e.isMutationDuringPagination || restart >= maxPaginationRestarts) {
          rethrow;
        }
        _log.info(LogEvent('item_sync_restart', {'restart': restart + 1}));
      }
    }
  }

  /// Upserts [reported], the last report of an account winning; Plaid's account id to
  /// ours.
  Map<String, String> _upsertAccounts(
    Tx tx,
    String userId,
    String itemId,
    List<PlaidAccount> reported,
  ) {
    final latest = <String, PlaidAccount>{
      for (final a in reported) a.accountId: a,
    };
    final ids = <String, String>{
      for (final r in tx.select(
        'SELECT id, plaid_account_id FROM accounts WHERE item_id = ?',
        [itemId],
      ))
        r['plaid_account_id'] as String: r['id'] as String,
    };
    for (final a in latest.values) {
      final values = [
        _accountType(a.type),
        a.subtype,
        a.name,
        a.officialName,
        a.mask,
        a.currencyCode,
        a.current?.minorUnits,
        a.available?.minorUnits,
        a.limit?.minorUnits,
        _nowMillis,
        _source,
      ];
      final existing = ids[a.accountId];
      if (existing != null) {
        tx.execute(
          'UPDATE accounts SET type = ?, subtype = ?, name = ?, official_name = ?, '
          'mask = ?, currency_code = ?, current_balance_minor = ?, '
          'available_balance_minor = ?, credit_limit_minor = ?, balances_as_of = ?, '
          'source = ? WHERE id = ?',
          [...values, existing],
        );
      } else {
        final id = newId();
        final order =
            tx.first('SELECT COUNT(*) AS n FROM accounts WHERE user_id = ?', [
                  userId,
                ])!['n']
                as int;
        tx.execute(
          'INSERT INTO accounts (type, subtype, name, official_name, mask, '
          'currency_code, current_balance_minor, available_balance_minor, '
          'credit_limit_minor, balances_as_of, source, id, user_id, item_id, '
          'plaid_account_id, display_order) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [...values, id, userId, itemId, a.accountId, order],
        );
        ids[a.accountId] = id;
      }
    }
    return ids;
  }

  ({int added, int modified, int removed}) _applyTransactions(
    Tx tx,
    String userId,
    String itemId,
    Map<String, String> accounts,
    List<TransactionsSyncPage> pages,
  ) {
    var added = 0, modified = 0, removed = 0;
    String? ourId(String? plaidId) => plaidId == null
        ? null
        : tx.first(
                'SELECT id FROM transactions WHERE item_id = ? '
                'AND plaid_transaction_id = ?',
                [itemId, plaidId],
              )?['id']
              as String?;

    void write(PlaidTransaction t) {
      final account = accounts[t.accountId];
      if (account == null) {
        throw StateError('Plaid sent a transaction for an unknown account');
      }
      // Ingestion flips Plaid's sign: ours is negative for money out.
      final amount = -t.amount;
      final values = [
        account,
        amount.minorUnits,
        amount.currencyCode,
        t.date.toString(),
        t.authorizedDate?.toString(),
        t.pending ? 1 : 0,
        ourId(t.pendingTransactionId),
        t.name,
        t.merchantName,
        t.logoUrl,
        t.primaryCategory,
        t.detailedCategory,
        _source,
        _nowMillis,
        nextVersion(tx, userId),
      ];
      final existing = ourId(t.transactionId);
      if (existing != null) {
        tx.execute(
          'UPDATE transactions SET account_id = ?, amount_minor = ?, currency = ?, '
          'date = ?, authorized_date = ?, pending = ?, pending_transaction_id = ?, '
          'name = ?, merchant_name = ?, merchant_logo_url = ?, '
          'plaid_primary_category = ?, plaid_detailed_category = ?, source = ?, '
          'updated_at = ?, sync_version = ?, deleted_at = NULL WHERE id = ?',
          [...values, existing],
        );
      } else {
        tx.execute(
          'INSERT INTO transactions (account_id, amount_minor, currency, date, '
          'authorized_date, pending, pending_transaction_id, name, merchant_name, '
          'merchant_logo_url, plaid_primary_category, plaid_detailed_category, '
          'source, updated_at, sync_version, id, user_id, item_id, '
          'plaid_transaction_id, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [...values, newId(), userId, itemId, t.transactionId, _nowMillis],
        );
      }
    }

    for (final page in pages) {
      for (final t in page.added) {
        write(t);
        added++;
      }
      for (final t in page.modified) {
        write(t);
        modified++;
      }
      for (final plaidId in page.removed) {
        removed++;
        final existing = ourId(plaidId);
        if (existing == null) continue;
        tx.execute(
          'UPDATE transactions SET deleted_at = ?, updated_at = ?, sync_version = ? '
          'WHERE id = ? AND deleted_at IS NULL',
          [_nowMillis, _nowMillis, nextVersion(tx, userId), existing],
        );
      }
    }
    return (added: added, modified: modified, removed: removed);
  }

  void _replaceRecurring(
    Tx tx,
    String userId,
    String itemId,
    Map<String, String> accounts,
    PlaidRecurring recurring,
  ) {
    final seen = <String>{};
    for (final s in [...recurring.inflow, ...recurring.outflow]) {
      final account = accounts[s.accountId];
      if (account == null) continue;
      seen.add(s.streamId);
      final amount = -s.averageAmount;
      final values = [
        account,
        s.merchantName,
        _cadence(s.frequency),
        amount.minorUnits,
        amount.currencyCode,
        s.lastDate?.toString(),
        s.predictedNextDate?.toString(),
        s.isActive ? 'active' : 'ended',
        // Plaid does not say whether a stream is a subscription; the app's detector does.
        0,
        _source,
      ];
      final changed = tx.execute(
        'UPDATE recurring_streams SET account_id = ?, merchant_name = ?, cadence = ?, '
        'average_amount_minor = ?, currency = ?, last_date = ?, next_date = ?, '
        'status = ?, is_subscription = ?, source = ? '
        'WHERE item_id = ? AND plaid_stream_id = ?',
        [...values, itemId, s.streamId],
      );
      if (changed == 0) {
        tx.execute(
          'INSERT INTO recurring_streams (account_id, merchant_name, cadence, '
          'average_amount_minor, currency, last_date, next_date, status, '
          'is_subscription, source, id, user_id, item_id, plaid_stream_id) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [...values, newId(), userId, itemId, s.streamId],
        );
      }
    }
    for (final r in tx.select(
      'SELECT id, plaid_stream_id FROM recurring_streams WHERE item_id = ?',
      [itemId],
    )) {
      if (!seen.contains(r['plaid_stream_id'])) {
        tx.execute('DELETE FROM recurring_streams WHERE id = ?', [r['id']]);
      }
    }
  }

  void _replaceLiabilities(
    Tx tx,
    String userId,
    String itemId,
    Map<String, String> accounts,
    PlaidLiabilities liabilities,
  ) {
    tx.execute('DELETE FROM liabilities WHERE item_id = ?', [itemId]);
    for (final (kind, list) in [
      ('credit', liabilities.credit),
      ('mortgage', liabilities.mortgage),
      ('student', liabilities.student),
    ]) {
      for (final l in list) {
        final account = accounts[l['account_id']];
        if (account == null) continue;
        tx.execute(
          'INSERT INTO liabilities (user_id, item_id, account_id, kind, payload, '
          'source) VALUES (?, ?, ?, ?, ?, ?)',
          [
            userId,
            itemId,
            account,
            kind,
            jsonEncode({...l, 'account_id': account}),
            _source,
          ],
        );
      }
    }
  }

  void _replaceHoldings(
    Tx tx,
    String userId,
    String itemId,
    Map<String, String> accounts,
    PlaidHoldings holdings,
  ) {
    tx.execute('DELETE FROM holdings WHERE item_id = ?', [itemId]);
    tx.execute('DELETE FROM securities WHERE item_id = ?', [itemId]);
    for (final s in holdings.securities) {
      tx.execute(
        'INSERT INTO securities (user_id, item_id, security_id, name, ticker_symbol, '
        'type, is_cash_equivalent, close_price, close_price_as_of, currency_code, '
        'source) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          userId,
          itemId,
          s.securityId,
          s.name,
          s.tickerSymbol,
          s.type,
          s.isCashEquivalent == null ? null : (s.isCashEquivalent! ? 1 : 0),
          s.closePrice,
          s.closePriceAsOf?.toString(),
          s.currencyCode,
          _source,
        ],
      );
    }
    for (final h in holdings.holdings) {
      final account = accounts[h.accountId];
      if (account == null) continue;
      tx.execute(
        'INSERT INTO holdings (user_id, item_id, account_id, security_id, quantity, '
        'institution_price, institution_price_as_of, institution_value_minor, '
        'cost_basis_minor, currency_code, source) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          userId,
          itemId,
          account,
          h.securityId,
          h.quantity,
          h.institutionPrice,
          h.institutionPriceAsOf?.toString(),
          h.institutionValue.minorUnits,
          h.costBasis?.minorUnits,
          h.currencyCode,
          _source,
        ],
      );
    }
  }

  /// Upserts the window's investment transactions; a row takes a new version only when
  /// it changed. Rows outside the window are left alone: the window is a date range, so
  /// absence from it is not a removal.
  void _upsertInvestmentTransactions(
    Tx tx,
    String userId,
    String itemId,
    Map<String, String> accounts,
    PlaidInvestmentTransactions investments,
  ) {
    for (final t in investments.transactions) {
      final account = accounts[t.accountId];
      if (account == null) continue;
      final amount = -t.amount;
      final fees = t.fees;
      final values = <Object?>[
        account,
        t.securityId,
        t.date.toString(),
        t.name,
        t.type,
        t.subtype,
        t.quantity,
        t.price,
        amount.minorUnits,
        fees?.minorUnits,
        amount.currencyCode,
        _source,
      ];
      final existing = tx.first(
        'SELECT id, account_id, security_id, date, name, type, subtype, quantity, '
        'price, amount_minor, fees_minor, currency, source, deleted_at '
        'FROM investment_transactions WHERE item_id = ? '
        'AND plaid_investment_transaction_id = ?',
        [itemId, t.investmentTransactionId],
      );
      if (existing == null) {
        tx.execute(
          'INSERT INTO investment_transactions (account_id, security_id, date, name, '
          'type, subtype, quantity, price, amount_minor, fees_minor, currency, source, '
          'id, user_id, item_id, plaid_investment_transaction_id, created_at, '
          'updated_at, sync_version) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ...values,
            newId(),
            userId,
            itemId,
            t.investmentTransactionId,
            _nowMillis,
            _nowMillis,
            nextVersion(tx, userId),
          ],
        );
        continue;
      }
      final stored = [
        for (var i = 1; i <= values.length; i++) existing.columnAt(i),
      ];
      final same =
          existing['deleted_at'] == null &&
          [for (var i = 0; i < values.length; i++) stored[i] == values[i]]
              .every((e) => e);
      if (same) continue;
      tx.execute(
        'UPDATE investment_transactions SET account_id = ?, security_id = ?, date = ?, '
        'name = ?, type = ?, subtype = ?, quantity = ?, price = ?, amount_minor = ?, '
        'fees_minor = ?, currency = ?, source = ?, deleted_at = NULL, updated_at = ?, '
        'sync_version = ? WHERE id = ?',
        [...values, _nowMillis, nextVersion(tx, userId), existing['id']],
      );
    }
  }

  /// The visible Item [itemId] of [userId] with its access token; 404 otherwise.
  Future<({String id, String accessToken, Map<String, Object?> row})> _load(
    String userId,
    String itemId,
  ) async {
    final row = await db.read(
      (tx) => tx.first(
        'SELECT * FROM items WHERE id = ? AND user_id = ? AND $visibleItem',
        [itemId, userId],
      ),
    );
    if (row == null) {
      throw const ProblemException.notFound('No Item with that id');
    }
    final opened = await _open(row);
    return (id: opened.id, accessToken: opened.accessToken, row: row);
  }

  /// [_load] for a call that reaches Plaid: a `removed` Item is 409 `conflict`.
  Future<({String id, String accessToken, Map<String, Object?> row})>
  loadActive(String userId, String itemId) async {
    final item = await _load(userId, itemId);
    if (item.row['status'] == 'removed') {
      throw const ProblemException(
        409,
        ProblemCode.conflict,
        detail: 'The Item was unlinked; link it again to use it',
      );
    }
    return item;
  }

  Future<({String id, String accessToken})> _open(
    Map<String, Object?> row,
  ) async {
    final id = row['id']! as String;
    final token = await cipher.open(
      row['access_token_ciphertext']! as List<int>,
      nonce: row['access_token_nonce']! as List<int>,
      itemId: id,
    );
    return (id: id, accessToken: token);
  }

  static Map<String, Object?> _linkTokenJson(PlaidLinkToken token) => {
    'link_token': token.linkToken,
    'expiration': const UtcInstantConverter().toJson(
      DateTime.fromMillisecondsSinceEpoch(
        token.expiration.millisecondsSinceEpoch,
        isUtc: true,
      ),
    ),
  };

  static String _accountType(String plaidType) => switch (plaidType) {
    'depository' || 'credit' || 'loan' || 'investment' => plaidType,
    'brokerage' => 'investment',
    _ => 'other',
  };

  static String _cadence(String frequency) => switch (frequency) {
    'WEEKLY' => 'weekly',
    'BIWEEKLY' => 'biweekly',
    'SEMI_MONTHLY' => 'semi_monthly',
    'MONTHLY' => 'monthly',
    'ANNUALLY' => 'annually',
    _ => 'unknown',
  };
}

/// The contract's `Item` from an `items` row, its institution embedded. `logo_url` is
/// the absolute URL of `GET /institutions/{id}/logo` under [baseUrl] (the request's
/// scheme and host) when the row holds a logo.
Map<String, Object?> itemJson(Map<String, Object?> row, Uri baseUrl) => {
  'id': row['id'],
  'institution_id': row['institution_id'],
  'status': row['status'],
  'last_successful_sync_at': optionalInstantJson(
    row['last_successful_sync_at'] as int?,
  ),
  'error_code': row['error_code'],
  'institution': {
    'id': row['institution_id'],
    'name': row['institution_name'],
    'logo_url': row['institution_logo'] == null
        ? null
        : baseUrl
              .resolve(
                '/v1/institutions/'
                '${Uri.encodeComponent(row['institution_id']! as String)}/logo',
              )
              .toString(),
    'primary_color': row['institution_primary_color'],
  },
};
