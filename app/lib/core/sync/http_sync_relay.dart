/// The sync engine's relay over the API (`docs/reference/sync-app.md`, **The relay**):
/// `POST /sync/push` and `GET /sync/pull` through [SyncEndpoints], which
/// [FinanceApiSyncEndpoints] gives from the app's `FinanceApi`. The API layer maps the
/// wire to the engine's types; this adapter adds the device check and the cursor reset.
library;

import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

/// The two sync operations of the API, in the engine's types. A pull from a `since` past
/// the server's last `seq` throws the API's `SyncCursorInvalid`.
abstract interface class SyncEndpoints {
  /// `POST /sync/push`.
  Future<PushResult> pushChanges(List<ChangeLogEntry> entries);

  /// `GET /sync/pull`.
  Future<PullPage> pullChanges({required int since, required int limit});
}

/// [SyncEndpoints] of a [FinanceApi].
final class FinanceApiSyncEndpoints implements SyncEndpoints {
  /// The endpoints of [_api].
  const FinanceApiSyncEndpoints(this._api);

  final FinanceApi _api;

  @override
  Future<PushResult> pushChanges(List<ChangeLogEntry> entries) =>
      _api.pushChanges(entries);

  @override
  Future<PullPage> pullChanges({required int since, required int limit}) =>
      _api.pullChanges(since: since, limit: limit);
}

/// The relay of the device [deviceId], whose session the endpoints carry: the server
/// knows the device from its token, so a pull for another device is a bug, refused here.
/// A pull from a cursor past the server's log is [SyncCursorInvalidException], whose last
/// `seq` is 0: the server does not say it.
final class HttpSyncRelay implements SyncRelay {
  /// The relay over [_endpoints] for [deviceId].
  HttpSyncRelay(this._endpoints, {required this.deviceId});

  final SyncEndpoints _endpoints;

  /// The server's id for this device.
  final String deviceId;

  @override
  Future<PushResult> push(List<ChangeLogEntry> entries) =>
      _endpoints.pushChanges(entries);

  @override
  Future<PullPage> pull({
    required int since,
    int limit = 200,
    required String deviceId,
  }) async {
    if (deviceId != this.deviceId) {
      throw ArgumentError.value(
        deviceId,
        'deviceId',
        'the session is device ${this.deviceId}',
      );
    }
    try {
      return await _endpoints.pullChanges(since: since, limit: limit);
    } on SyncCursorInvalid {
      throw SyncCursorInvalidException(since, 0);
    }
  }
}
