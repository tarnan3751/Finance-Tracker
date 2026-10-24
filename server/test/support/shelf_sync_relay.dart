// The engine's SyncRelay over the server's /sync endpoints, through TestServer (the shelf
// handler, no socket), so every push and pull is validated against the contract. The
// rejection code maps to PushRejectionReason by name and a 409 sync_cursor_invalid to
// SyncCursorInvalidException, as the app's relay client will.
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import 'test_server.dart';

/// [PushRejectionReason] by the contract's `PushRejectionCode`.
final rejectionReasons = {
  for (final r in PushRejectionReason.values)
    r.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}'):
        r,
};

/// The relay one device sees: [server] with that device's [accessToken].
final class ShelfSyncRelay implements SyncRelay {
  ShelfSyncRelay(this.server, this.accessToken);

  final TestServer server;
  final String accessToken;

  @override
  Future<PushResult> push(List<ChangeLogEntry> entries) async {
    final r = await server.call(
      'post',
      '/sync/push',
      token: accessToken,
      body: {
        'entries': [
          for (final e in entries) {...e.toJson()}..remove('synced'),
        ],
      },
    );
    if (r.status != 200) throw StateError('push answered $r');
    return PushResult(
      accepted: [
        for (final h in r.json['accepted']! as List<Object?>)
          Hlc.parse(h! as String),
      ],
      rejected: [
        for (final j
            in (r.json['rejected']! as List<Object?>)
                .cast<Map<String, Object?>>())
          PushRejection(
            Hlc.parse(j['hlc']! as String),
            rejectionReasons[j['code']]!,
            j['reason']! as String,
          ),
      ],
    );
  }

  @override
  Future<PullPage> pull({
    required int since,
    int limit = 200,
    required String deviceId,
  }) async {
    final r = await server.call(
      'get',
      '/sync/pull?since=$since&limit=$limit',
      token: accessToken,
    );
    if (r.status == 409 && r.code == 'sync_cursor_invalid') {
      throw SyncCursorInvalidException(since, -1);
    }
    if (r.status != 200) throw StateError('pull answered $r');
    return PullPage(
      entries: [
        for (final e in r.json['entries']! as List<Object?>)
          ChangeLogEntry.fromJson(
            {...(e! as Map<String, Object?>), 'synced': true}..remove('seq'),
          ),
      ],
      nextSince: r.json['next_since']! as int,
      hasMore: r.json['has_more']! as bool,
    );
  }
}
