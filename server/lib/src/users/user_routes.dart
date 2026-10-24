/// `getMe`, `deleteMe`, `listDevices` and `deleteDevice` (`docs/reference/server.md`,
/// **Users and devices**).
///
/// Account deletion is end to end (`PLAN.md` §6.5): every Item is removed at Plaid first,
/// each with three attempts; if one still fails the answer is 502 `plaid_error` and no
/// user data is deleted (Items already removed keep their `plaid_removed_at` marker, so a
/// retry skips them). Then one transaction checks that no Item has appeared meanwhile (an
/// exchange during the retries) and deletes the user; the cascade takes every row the
/// user owns, devices and refresh tokens included, which ends every session. An Item
/// that appeared sends the deletion round again, at most [deletionRounds] times; one
/// still there after that is 502 and nothing is deleted.
library;

import 'package:finance_tracker_server/src/auth/auth_service.dart';
import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/api_route.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/logging.dart';
import 'package:finance_tracker_server/src/plaid/item_service.dart';
import 'package:logging/logging.dart';

final _log = Logger('users');

/// How many times account deletion removes the user's Items and re-checks before it
/// gives up.
const deletionRounds = 3;

/// The user and device routes.
List<ApiRoute> userRoutes({
  required AppDatabase db,
  required AuthService auth,
  required ItemService items,
}) => [
  ApiRoute('getMe', 'get', '/me', (r) async {
    final row = await db.read(
      (tx) => tx.first(
        'SELECT id, email, display_name, created_at FROM users WHERE id = ?',
        [r.userId],
      ),
    );
    return jsonResponse({
      'id': row!['id'],
      'email': row['email'],
      'display_name': row['display_name'],
      'created_at': instantJson(row['created_at'] as int),
    });
  }),
  ApiRoute('deleteMe', 'delete', '/me', (r) async {
    for (var round = 1; ; round++) {
      for (final item in await items.itemsToRemove(r.userId)) {
        await items.removeAtPlaid(item.id, item.accessToken);
      }
      final deleted = await db.transaction((tx) async {
        final linked = tx.first(
          'SELECT 1 FROM items WHERE user_id = ? AND plaid_removed_at IS NULL',
          [r.userId],
        );
        if (linked != null) return false;
        tx.execute('DELETE FROM users WHERE id = ?', [r.userId]);
        return true;
      });
      if (deleted) break;
      if (round == deletionRounds) {
        throw const ProblemException(
          502,
          ProblemCode.plaidError,
          detail: 'Items kept being linked during the deletion; nothing was deleted',
        );
      }
    }
    _log.info(LogEvent('user_deleted', {'user_id': r.userId}));
    return noContent();
  }),
  ApiRoute('listDevices', 'get', '/devices', (r) async {
    final rows = await db.read(
      (tx) => tx.select(
        'SELECT * FROM devices d WHERE d.user_id = ? AND EXISTS (SELECT 1 FROM '
        'refresh_tokens t WHERE t.device_id = d.id AND t.revoked_at IS NULL AND '
        't.expires_at > ?) ORDER BY d.created_at, d.id',
        [r.userId, auth.now().millisecondsSinceEpoch],
      ),
    );
    return jsonResponse([for (final row in rows) deviceJson(row)]);
  }),
  ApiRoute('deleteDevice', 'delete', '/devices/{device_id}', (r) async {
    final id = r.param('device_id');
    final found = await db.transaction((tx) async {
      final row = tx.first(
        'SELECT 1 FROM devices WHERE id = ? AND user_id = ?',
        [id, r.userId],
      );
      if (row == null) return false;
      auth.removeDevice(tx, id);
      return true;
    });
    if (!found) throw const ProblemException.notFound('No device with that id');
    _log.info(
      LogEvent('device_removed', {'user_id': r.userId, 'device_id': id}),
    );
    return noContent();
  }),
];
