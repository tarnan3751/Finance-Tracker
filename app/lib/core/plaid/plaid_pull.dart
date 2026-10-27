/// The Plaid pull: the server's Items, linked accounts, Plaid-sourced transactions and
/// recurring streams brought into the local store (`docs/reference/sync-app.md`, **The Plaid pull**;
/// `PLAN.md` §6.4: Plaid data is server-authoritative and only pulled, never pushed).
///
/// One run:
///
/// 1. `GET /plaid/items` and `GET /accounts`, applied together in one store transaction:
///    the accounts (`AccountRepository.applyPlaid`: a linked account the list lacks is
///    soft-deleted), then the Items (`ItemRepository.applyPlaid`: an Item the list lacks
///    is removed), with `plaid_accounts_pulled_at` and `plaid_items_pulled_at`;
/// 2. `GET /transactions` from the stored `plaid_transactions_since`, page by page
///    through `has_more`. Each page is one store transaction: the page applied
///    (`TransactionRepository.applyPlaid`), the held sync records of the rows it inserted
///    materialized onto them (an override pulled through the change log before its
///    Plaid row), the arrival processor run on the inserted rows as stored after that, and the cursor saved,
///    so a failure anywhere in a page leaves the cursor where it was. A cursor past the
///    server's version (`SyncCursorInvalid`) restarts from 0 once per run, replacing
///    rows by id;
/// 3. `GET /recurring`, the server's whole list, applied in one store transaction
///    (`RecurringStreamRepository.applyPlaid`: every server-supplied stream replaced, the
///    detector's and the user's overrides left alone). A failure is logged by its type
///    and does not fail the run: the transactions matter more;
/// 4. the institution logos: for each Item whose institution has a `logo_url` and whose
///    bytes are missing (never fetched, or the URL changed), `GET
///    /institutions/{id}/logo` (bearer-secured, so the screen cannot load the URL
///    itself); a failure is logged and the logo fetched again on the next run;
/// 5. `plaid_pulled_at`, when the run succeeded (a failed list does not stop it).
///
/// Nothing is recorded, and every row keeps the `source` the server sent. [PlaidPull.run]
/// is single-flight: a call during a run gets one more run that starts after it, shared
/// by every caller during that run, so data a caller has just caused the server to hold
/// (a completed Item sync) is always pulled. A failure is thrown to the caller. Counts
/// and exception types only are logged.
///
/// Pure Dart, no Flutter import.
library;

import 'dart:async';

import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/items/domain/item_repository.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';

final Logger _log = Logger('plaid');

/// Where the pull keeps its cursors, and the transaction its writes share.
abstract interface class PlaidPullStore {
  /// Runs [body] as one write: the Drift store's database transaction (the repositories'
  /// own writes join it); the in-memory store runs it as it is.
  Future<T> transaction<T>(Future<T> Function() body);

  /// The `sync_version` the transactions were pulled up to, or null before the first.
  Future<int?> transactionsSince();

  /// Saves the transactions cursor.
  Future<void> saveTransactionsSince(int since);

  /// Saves when the accounts and the Items were last applied.
  Future<void> savePulledListsAt(DateTime at);

  /// When the last whole run finished, UTC, or null before the first.
  Future<DateTime?> pulledAt();

  /// Saves when the last whole run finished.
  Future<void> savePulledAt(DateTime at);

  /// Materializes the held sync records of the [inserted] transactions onto their new
  /// rows, and returns those rows as now stored (with any override another device
  /// recorded for them before they arrived), in the same order.
  Future<List<Transaction>> materializeHeld(List<Transaction> inserted);
}

/// What happens to the transactions a pull inserts, once per row, inside the page's
/// store transaction: the seam the rules engine fills (Phase 3e). It must not fail on a
/// row it cannot handle, since a failure rolls the page back.
///
/// It sees each row as stored once the page is applied: overrides another device pulled
/// through the change log before the row existed (a held `user_category_id`, notes,
/// tags, splits, a receipt) are already on it, so a processor need not re-read the rows.
abstract interface class ArrivalProcessor {
  /// Processes [added], the live rows a page inserted, as stored.
  Future<void> onArrived(List<Transaction> added);
}

/// The arrival processor until rules exist: does nothing.
final class NoArrivalProcessor implements ArrivalProcessor {
  /// The processor.
  const NoArrivalProcessor();

  @override
  Future<void> onArrived(List<Transaction> added) async {}
}

/// The pull over [api] into the repositories, through [store].
final class PlaidPull {
  /// A pull.
  PlaidPull({
    required this.api,
    required this.store,
    required this.items,
    required this.accounts,
    required this.transactions,
    required this.streams,
    required this.clock,
    this.arrival = const NoArrivalProcessor(),
    this.pageSize = 500,
  });

  final FinanceApi api;
  final PlaidPullStore store;
  final ItemRepository items;
  final AccountRepository accounts;
  final TransactionRepository transactions;
  final RecurringStreamRepository streams;
  final Clock clock;
  final ArrivalProcessor arrival;

  /// The transactions page size: the contract's maximum, smaller in tests.
  final int pageSize;

  Future<void>? _running;
  Future<void>? _next;

  /// Runs the pull, or, during a run, one more after it. Completes when the run it
  /// started or joined has finished; throws what that run threw.
  Future<void> run() {
    final Future<void>? running = _running;
    if (running == null) {
      return _running = _once().whenComplete(() => _running = null);
    }
    return _next ??= running.then<void>((_) {}, onError: (Object _) {}).then((
      _,
    ) {
      _next = null;
      return run();
    });
  }

  Future<void> _once() async {
    final List<LinkedItem> listed = await api.listItems();
    final List<Account> linked = await api.listAccounts();
    final DateTime at = clock.nowUtc();
    final List<LinkedBank> banks = await store.transaction(() async {
      await accounts.applyPlaid(linked);
      final List<LinkedBank> stored = await items.applyPlaid(
        listed,
        pulledAt: at,
      );
      await store.savePulledListsAt(at);
      return stored;
    });
    int since = await store.transactionsSince() ?? 0;
    bool restarted = false;
    int pages = 0;
    int added = 0;
    while (true) {
      final VersionPage<Transaction> page;
      try {
        page = await api.listTransactions(since: since, limit: pageSize);
      } on SyncCursorInvalid {
        if (restarted) rethrow;
        // The server's data was reset: read everything again, replacing rows by id.
        _log.warning('the transactions cursor is past the server; from 0');
        restarted = true;
        since = 0;
        continue;
      }
      await store.transaction(() async {
        final List<Transaction> inserted = await transactions.applyPlaid(
          page.items,
        );
        await arrival.onArrived(await store.materializeHeld(inserted));
        await store.saveTransactionsSince(page.nextSince);
        added += inserted.length;
      });
      pages++;
      since = page.nextSince;
      if (!page.hasMore) break;
    }
    final int? streamCount = await _pullList('recurring streams', () async {
      final List<RecurringStream> pulled = await api.listRecurringStreams();
      await store.transaction(() => streams.applyPlaid(pulled));
      return pulled.length;
    });
    await _fetchLogos(banks);
    await store.savePulledAt(clock.nowUtc());
    _log.info(
      'pulled ${listed.length} items, ${linked.length} accounts, '
      '$pages transaction pages ($added new), '
      '${streamCount ?? 'no'} recurring streams',
    );
  }
}

extension on PlaidPull {
  // Fetches and applies one of the lists after the transactions, returning how many it
  // applied, or null when it failed: logged by type, never failing the run.
  Future<int?> _pullList(String what, Future<int> Function() pull) async {
    try {
      return await pull();
    } on Exception catch (e) {
      _log.warning('$what not pulled: ${e.runtimeType}');
    } on ArgumentError catch (e) {
      _log.warning('$what not pulled: ${e.runtimeType}');
    }
    return null;
  }

  Future<void> _fetchLogos(List<LinkedBank> banks) async {
    for (final LinkedBank bank in banks) {
      final Uri? url = bank.institution.logoUrl;
      if (url == null || bank.logo != null) continue;
      try {
        await items.saveLogo(
          bank.id,
          url,
          await api.getInstitutionLogo(bank.institution.id),
        );
      } on ApiException catch (e) {
        _log.warning('logo of ${bank.institution.id} not fetched: ${e.code}');
      }
    }
  }
}

/// The [PlaidPullStore] of the tests and the demo flavor, in memory: it lives as long as
/// the in-memory store it serves, so the demo's persona switch starts it afresh.
final class InMemoryPlaidPullStore implements PlaidPullStore {
  /// A store whose transactions cursor starts at [transactionsSince] (null: from 0): the
  /// demo's starts where its store's seed already is, so its first pull does not apply
  /// the seeded rows again over the demo's own edits.
  InMemoryPlaidPullStore({int? transactionsSince}) : _since = transactionsSince;

  int? _since;
  DateTime? _pulledAt;

  /// When the accounts and Items were last applied.
  DateTime? listsPulledAt;

  @override
  Future<T> transaction<T>(Future<T> Function() body) => body();

  @override
  Future<int?> transactionsSince() async => _since;

  @override
  Future<void> saveTransactionsSince(int since) async => _since = since;

  @override
  Future<void> savePulledListsAt(DateTime at) async => listsPulledAt = at;

  @override
  Future<DateTime?> pulledAt() async => _pulledAt;

  @override
  Future<void> savePulledAt(DateTime at) async => _pulledAt = at;

  @override
  Future<List<Transaction>> materializeHeld(List<Transaction> inserted) async =>
      inserted;
}
