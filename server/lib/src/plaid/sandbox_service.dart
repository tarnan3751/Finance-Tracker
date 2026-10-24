/// The Plaid Sandbox controls the developer menu and the provisioning script use
/// (`docs/reference/server.md`, **Sandbox operations**): reset an Item's login, fire a
/// webhook, inject transactions. Each is the [ServerConfig.canDriveSandbox] check (409
/// `conflict` otherwise), the ownership check (404 for another user's Item), the
/// `removed` check (409 `conflict`), then one call through [PlaidClient]. With the fake
/// client a webhook is a no-op and injected transactions reach the next sync with
/// `source: demo`; nothing here fabricates a record (`PLAN.md` §7.1).
library;

import 'package:finance_tracker_server/src/config.dart';
import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/logging.dart';
import 'package:finance_tracker_server/src/plaid/item_service.dart';
import 'package:finance_tracker_server/src/plaid/plaid_client.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';

/// The webhook codes `/sandbox/item/fire_webhook` takes (the contract's `WebhookCode`).
const webhookCodes = {
  'SYNC_UPDATES_AVAILABLE',
  'DEFAULT_UPDATE',
  'RECURRING_TRANSACTIONS_UPDATE',
  'NEW_ACCOUNTS_AVAILABLE',
  'PENDING_DISCONNECT',
  'USER_PERMISSION_REVOKED',
  'LOGIN_REPAIRED',
  'ERROR',
};

/// How far back `/sandbox/transactions/create` accepts a date (`PLAN.md` §4).
const plaidWindowDays = 730;

/// "Today" for Plaid's Sandbox: the calendar date at UTC−12 of [now], the earliest date
/// anywhere, so a date on or before it is never in Plaid's future whatever zone Plaid
/// reckons in (`PLAN.md` §12).
LocalDate plaidToday(DateTime now) =>
    LocalDate.fromDateTime(now.toUtc().subtract(const Duration(hours: 12)));

/// Whether [date] is within Plaid's window as of [today]: today or up to 730 days back.
bool inPlaidWindow(LocalDate date, LocalDate today) =>
    !date.isAfter(today) && !date.isBefore(today.addDays(-plaidWindowDays));

/// An injected transaction as the contract's `SandboxTransaction` carries it: [amount]
/// in Plaid's sign, [accountId] this API's account id.
typedef SandboxTransactionRequest = ({
  LocalDate dateTransacted,
  LocalDate datePosted,
  Money amount,
  String description,
  String? accountId,
});

/// The Sandbox controls.
final class SandboxService {
  /// The service over [items].
  SandboxService({
    required this.config,
    required this.db,
    required this.items,
    required this.plaid,
    required this.now,
  });

  /// The configuration ([ServerConfig.canDriveSandbox]).
  final ServerConfig config;

  /// The database.
  final AppDatabase db;

  /// The Item store.
  final ItemService items;

  /// The Plaid client.
  final PlaidClient plaid;

  /// The server's clock.
  final DateTime Function() now;

  final Logger _log = Logger('sandbox');

  /// 409 `conflict` unless the server can drive Sandbox.
  void checkAvailable() {
    if (!config.canDriveSandbox) {
      throw const ProblemException(
        409,
        ProblemCode.conflict,
        detail: 'This server cannot drive Plaid Sandbox',
      );
    }
  }

  /// `/sandbox/item/reset_login` for the user's Item.
  Future<void> resetLogin(String userId, String itemId) async {
    checkAvailable();
    final item = await items.loadActive(userId, itemId);
    await items.itemCall(
      itemId,
      () => plaid.sandboxItemResetLogin(item.accessToken),
    );
    _log.info(LogEvent('sandbox_reset_login', {'item_id': itemId}));
  }

  /// `/sandbox/item/fire_webhook` with [webhookCode] for the user's Item.
  Future<void> fireWebhook(
    String userId,
    String itemId,
    String webhookCode,
  ) async {
    checkAvailable();
    final item = await items.loadActive(userId, itemId);
    await items.itemCall(
      itemId,
      () => plaid.sandboxItemFireWebhook(item.accessToken, webhookCode),
    );
    _log.info(
      LogEvent('sandbox_webhook_fired', {
        'item_id': itemId,
        'webhook_code': webhookCode,
      }),
    );
  }

  /// `/sandbox/transactions/create` for the user's Item. Dates outside Plaid's window,
  /// account ids that are not the Item's, and an amount in another currency than its
  /// account's (the Item's checking account, or its first, when none is named: Plaid
  /// picks checking) are a 400 naming the field: a mixed-currency account would break
  /// its derived balance.
  Future<void> createTransactions(
    String userId,
    String itemId,
    List<SandboxTransactionRequest> transactions,
  ) async {
    checkAvailable();
    final item = await items.loadActive(userId, itemId);
    final rows = await db.read(
      (tx) => tx.select(
        'SELECT id, plaid_account_id, subtype, currency_code FROM accounts '
        'WHERE item_id = ? ORDER BY display_order, id',
        [itemId],
      ),
    );
    final accounts = {
      for (final r in rows)
        r['id']! as String: r['plaid_account_id']! as String,
    };
    final currencies = {
      for (final r in rows) r['id']! as String: r['currency_code']! as String,
    };
    final checking = rows.where((r) => r['subtype'] == 'checking').firstOrNull;
    final fallback = (checking ?? rows.firstOrNull)?['id'] as String?;
    final today = plaidToday(now());
    final errors = <FieldError>[];
    for (final (i, t) in transactions.indexed) {
      for (final (key, date) in [
        ('date_transacted', t.dateTransacted),
        ('date_posted', t.datePosted),
      ]) {
        if (!inPlaidWindow(date, today)) {
          errors.add(
            FieldError(
              'transactions[$i].$key',
              'must be today or up to $plaidWindowDays days back',
            ),
          );
        }
      }
      final accountId = t.accountId;
      if (accountId != null && !accounts.containsKey(accountId)) {
        errors.add(
          FieldError(
            'transactions[$i].account_id',
            'is not an account of this Item',
          ),
        );
        continue;
      }
      final currency = currencies[accountId ?? fallback];
      if (currency != null && currency != t.amount.currencyCode) {
        errors.add(
          FieldError(
            'transactions[$i].amount',
            "currency must be the account's",
          ),
        );
      }
    }
    if (errors.isNotEmpty) throw ValidationException(errors);
    await items.itemCall(
      itemId,
      () => plaid.sandboxTransactionsCreate(item.accessToken, [
        for (final t in transactions)
          (
            dateTransacted: t.dateTransacted,
            datePosted: t.datePosted,
            amount: t.amount,
            description: t.description,
            accountId: t.accountId == null ? null : accounts[t.accountId],
          ),
      ]),
    );
    _log.info(
      LogEvent('sandbox_transactions_created', {
        'item_id': itemId,
        'count': transactions.length,
      }),
    );
  }
}
