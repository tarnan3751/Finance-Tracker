/// The Plaid webhook receiver behind `POST /webhooks/plaid` (`docs/reference/server.md`,
/// **Webhooks**).
///
/// [WebhookService.receive] verifies the exact bytes first ([WebhookVerifier]); an
/// unverified delivery is 401 `webhook_unverified`, logged with the reason's class only
/// and never processed. Nothing touches the database before that. A verified body is
/// decoded and dispatched by `webhook_type` and `webhook_code`:
///
/// - `TRANSACTIONS` `SYNC_UPDATES_AVAILABLE` or `DEFAULT_UPDATE`: a background sync;
/// - `TRANSACTIONS` `RECURRING_TRANSACTIONS_UPDATE`: the recurring streams refetched;
/// - `ITEM` `ERROR`: `login_required` for `ITEM_LOGIN_REQUIRED`, else `error`, with the
///   code (none when the delivery carries no `error`);
/// - `ITEM` `LOGIN_REPAIRED`: `healthy`, the code cleared;
/// - `ITEM` `PENDING_EXPIRATION` or `PENDING_DISCONNECT`: `pending_expiration`, the code
///   stored;
/// - `ITEM` `USER_PERMISSION_REVOKED` or `USER_ACCOUNT_REVOKED`: `error`, the code stored;
/// - anything else: logged.
///
/// The answer is 204 for every verified delivery, an unknown or removed Item's included
/// (logged), so a sender cannot probe which Item ids exist. Syncs and recurring refetches
/// run in the background; their failures are logged.
library;

import 'dart:async';
import 'dart:convert';

import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/logging.dart';
import 'package:finance_tracker_server/src/plaid/item_service.dart';
import 'package:finance_tracker_server/src/plaid/plaid_json.dart';
import 'package:finance_tracker_server/src/plaid/webhook_verifier.dart';
import 'package:logging/logging.dart';

/// The receiver.
final class WebhookService {
  /// A receiver verifying with [verifier] and acting through [items].
  WebhookService({
    required this.db,
    required this.items,
    required this.verifier,
  });

  /// The database.
  final AppDatabase db;

  /// The Item flows.
  final ItemService items;

  /// The verifier.
  final WebhookVerifier verifier;

  final Logger _log = Logger('plaid');

  /// Handles one delivery: [body] its exact bytes, [token] its `Plaid-Verification`.
  Future<void> receive(List<int> body, String? token) async {
    try {
      await verifier.verify(body, token);
    } on WebhookRejected catch (e) {
      _log.warning(LogEvent('webhook_rejected', {'reason': e.reason}));
      throw const ProblemException.unauthorized(
        ProblemCode.webhookUnverified,
        detail: 'The delivery did not verify and was not processed',
      );
    }
    final Object? decoded;
    try {
      decoded = decodePlaidJson(utf8.decode(body));
    } on FormatException {
      throw ValidationException.single('', 'the body is not JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw ValidationException.single('', 'the body must be a JSON object');
    }
    final type = decoded['webhook_type'];
    final code = decoded['webhook_code'];
    final plaidItemId = decoded['item_id'];
    final row = plaidItemId is! String
        ? null
        : await db.read(
            (tx) => tx.first(
              'SELECT id, user_id FROM items WHERE plaid_item_id = ? '
              'AND plaid_removed_at IS NULL',
              [plaidItemId],
            ),
          );
    if (row == null) {
      _log.info(LogEvent('webhook_unknown_item', {'type': type, 'code': code}));
      return;
    }
    final itemId = row['id']! as String;
    final userId = row['user_id']! as String;
    _log.info(
      LogEvent('webhook_received', {
        'type': type,
        'code': code,
        'item_id': itemId,
      }),
    );
    final error = decoded['error'];
    final errorCode = error is Map<String, Object?>
        ? error['error_code']
        : null;
    switch ((type, code)) {
      case ('TRANSACTIONS', 'SYNC_UPDATES_AVAILABLE' || 'DEFAULT_UPDATE'):
        _background(
          'sync',
          itemId,
          items.sync(userId, itemId, retryNotReady: true),
        );
      case ('TRANSACTIONS', 'RECURRING_TRANSACTIONS_UPDATE'):
        _background(
          'recurring',
          itemId,
          items.refreshRecurring(userId, itemId),
        );
      case ('ITEM', 'ERROR'):
        // An ERROR without an error object stores no code.
        final codeText = errorCode is String ? errorCode : null;
        await items.setStatus(
          itemId,
          codeText == 'ITEM_LOGIN_REQUIRED' ? 'login_required' : 'error',
          codeText,
        );
      case ('ITEM', 'LOGIN_REPAIRED'):
        await items.setStatus(itemId, 'healthy', null);
      case ('ITEM', 'PENDING_EXPIRATION' || 'PENDING_DISCONNECT'):
        await items.setStatus(itemId, 'pending_expiration', code! as String);
      case ('ITEM', 'USER_PERMISSION_REVOKED' || 'USER_ACCOUNT_REVOKED'):
        await items.setStatus(itemId, 'error', code! as String);
      default:
        _log.info(
          LogEvent('webhook_ignored', {
            'type': type,
            'code': code,
            'item_id': itemId,
          }),
        );
    }
  }

  void _background(String what, String itemId, Future<Object?> work) =>
      unawaited(
        work.then<void>(
          (_) {},
          onError: (Object e) => _log.warning(
            LogEvent('webhook_${what}_failed', {
              'item_id': itemId,
              ...errorFields(e),
              if (e is ProblemException) 'code': e.code.wire,
            }),
          ),
        ),
      );
}
