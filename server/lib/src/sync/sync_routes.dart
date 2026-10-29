/// `pushChanges` and `pullChanges`.
library;

import 'package:finance_tracker_server/src/http/api_route.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/sync/change_log_relay.dart';

const _entityTypes = {
  'account',
  'transaction',
  'category',
  'rule',
  'budget',
  'recurring_stream',
  'bill_reminder',
  'goal',
  'goal_contribution',
  'settings',
};

const _operations = {'create', 'update', 'delete'};

final _hlc = RegExp(r'^[0-9]{15}-[0-9]{5}-[A-Za-z0-9_.:-]+$');

/// The sync routes over [relay].
List<ApiRoute> syncRoutes(ChangeLogRelay relay) => [
  ApiRoute('pushChanges', 'post', '/sync/push', (r) async {
    final body = ObjectReader(await r.json(limit: pushBodyLimit), const {
      'entries',
    });
    final raw = body.list('entries');
    final entries = <PushedEntry>[];
    for (final (i, item) in (raw ?? const <Object?>[]).indexed) {
      if (item is! Map<String, Object?>) {
        body.errors.add(FieldError('entries[$i]', 'must be an object'));
        continue;
      }
      final e = ObjectReader(
        item,
        const {
          'entity_type',
          'entity_id',
          'operation',
          'payload',
          'hlc',
          'device_id',
        },
        prefix: 'entries[$i]',
        errors: body.errors,
      );
      final type = e.oneOf('entity_type', {for (final t in _entityTypes) t: t});
      final id = e.string('entity_id');
      final operation = e.oneOf('operation', {
        for (final o in _operations) o: o,
      });
      final payload = e.object('payload');
      final hlc = e.string('hlc', pattern: _hlc);
      final device = e.string('device_id');
      if (type != null &&
          id != null &&
          operation != null &&
          payload != null &&
          hlc != null &&
          device != null) {
        entries.add((
          entityType: type,
          entityId: id,
          operation: operation,
          payload: payload,
          hlc: hlc,
          deviceId: device,
        ));
      }
    }
    body.check();
    return jsonResponse(await relay.push(r.userId, r.deviceId, entries));
  }),
  ApiRoute('pullChanges', 'get', '/sync/pull', (r) async {
    final errors = <FieldError>[];
    final since = queryInt(r.raw, 'since', fallback: 0, min: 0, errors: errors);
    final limit = queryInt(
      r.raw,
      'limit',
      fallback: 500,
      min: 1,
      max: 500,
      errors: errors,
    );
    if (errors.isNotEmpty) throw ValidationException(errors);
    return jsonResponse(
      await relay.pull(r.userId, r.deviceId, since: since!, limit: limit!),
    );
  }),
];
