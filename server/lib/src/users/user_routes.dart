/// `getMe`, `listDevices` and `deleteDevice` (`docs/reference/server.md`, **Users and
/// devices**).
library;

import 'package:finance_tracker_server/src/auth/auth_service.dart';
import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/api_route.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/logging.dart';
import 'package:logging/logging.dart';

final _log = Logger('users');

/// The user and device routes.
List<ApiRoute> userRoutes({
  required AppDatabase db,
  required AuthService auth,
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
