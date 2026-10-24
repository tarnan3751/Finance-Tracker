// A relay wrapper for tests and the simulation: hooks before and after each call (to
// inject failures, lost responses and event-loop yields), call counts, and an option to
// stop filtering the caller's own entries, as a relay that does not filter would.
import 'dart:async';

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

class HookedRelay implements SyncRelay {
  HookedRelay(this.inner);

  final SyncRelay inner;

  /// Runs before the inner call; a throw is a request that never arrived.
  FutureOr<void> Function(String op)? before;

  /// Runs after the inner call; a throw is a response that was lost.
  FutureOr<void> Function(String op)? after;

  /// When false, pulls return every device's entries, the caller's own included.
  bool filterOwn = true;

  int pushCalls = 0;
  int pullCalls = 0;

  @override
  Future<PushResult> push(List<ChangeLogEntry> entries) async {
    pushCalls++;
    await before?.call('push');
    final result = await inner.push(entries);
    await after?.call('push');
    return result;
  }

  @override
  Future<PullPage> pull({
    required int since,
    int limit = 200,
    required String deviceId,
  }) async {
    pullCalls++;
    await before?.call('pull');
    final page = await inner.pull(
      since: since,
      limit: limit,
      deviceId: filterOwn ? deviceId : '\u0000none',
    );
    await after?.call('pull');
    return page;
  }
}
