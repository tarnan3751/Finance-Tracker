/// The hybrid logical clock that stamps change-log entries (`PLAN.md` §6.4).
///
/// The send and receive rules are Figure 5 of Kulkarni, Demirbas, Madappa, Avva and Leone,
/// "Logical Physical Clocks and Consistent Snapshots in Globally Distributed Databases"
/// (2014), with two deliberate departures, both for monotonicity, which last-writer-wins
/// merge depends on: a counter that would pass [Hlc.maxCounter] advances the wall by one
/// millisecond instead of rolling over, and the paper's corrective reset of `l` to the
/// physical clock (§4.1) is never applied. The paper's other corrective action, ignoring a
/// message too far ahead of the physical clock, is [ClockDriftException].
///
/// The clock does no IO: the host persists [HlcClock.last] (`SyncStore.saveClock`) and
/// passes it back at construction.
library;

import 'package:shared_models/shared_models.dart';

/// A remote clock more than the allowed drift ahead of this node's physical clock. The
/// entry that carried it is rejected, not applied; the clock's state is unchanged.
final class ClockDriftException implements Exception {
  /// The exception for [remote] seen at [nowWallMillis] with [maxDrift] allowed.
  const ClockDriftException(this.remote, this.nowWallMillis, this.maxDrift);

  /// The rejected remote timestamp.
  final Hlc remote;

  /// This node's physical clock when [remote] was received.
  final int nowWallMillis;

  /// The drift allowed.
  final Duration maxDrift;

  @override
  String toString() =>
      'ClockDriftException: $remote is '
      '${remote.wallMillis - nowWallMillis} ms ahead of $nowWallMillis '
      '(at most ${maxDrift.inMilliseconds} ms allowed)';
}

/// One node's hybrid logical clock.
final class HlcClock {
  /// A clock for [nodeId], resumed from the persisted [last] when there is one (the
  /// paper's initial state, wall 0 and counter 0, otherwise). A remote wall time more than
  /// [maxDrift] ahead of the physical clock is rejected by [receive].
  HlcClock(this.nodeId, {Hlc? last, this.maxDrift = const Duration(hours: 1)})
    : _last = last ?? Hlc(0, 0, nodeId) {
    if (_last.nodeId != nodeId) {
      throw ArgumentError.value(last, 'last', 'issued by another node');
    }
  }

  /// The node (device) id stamped on every timestamp this clock issues.
  final String nodeId;

  /// How far ahead of the physical clock a remote wall time may be.
  final Duration maxDrift;

  Hlc _last;

  /// The latest state: the last timestamp issued or the result of the last receive. The
  /// host persists it.
  Hlc get last => _last;

  /// A timestamp for a local or send event at physical time [nowWallMillis] (UTC
  /// milliseconds). Always greater than [last], even when the wall clock went backwards.
  Hlc send(int nowWallMillis) {
    final l0 = _last.wallMillis;
    final l = l0 > nowWallMillis ? l0 : nowWallMillis;
    final c = l == l0 ? _last.counter + 1 : 0;
    return _last = _stamp(l, c);
  }

  /// Advances the clock past [remote], received at physical time [nowWallMillis].
  ///
  /// Throws [ClockDriftException], leaving the state unchanged, when [remote]'s wall time
  /// is more than [maxDrift] ahead of [nowWallMillis].
  Hlc receive(Hlc remote, int nowWallMillis) {
    checkDrift(remote, nowWallMillis);
    final l0 = _last.wallMillis;
    final lm = remote.wallMillis;
    var l = l0 > lm ? l0 : lm;
    if (nowWallMillis > l) l = nowWallMillis;
    final int c;
    if (l == l0 && l == lm) {
      c = (_last.counter > remote.counter ? _last.counter : remote.counter) + 1;
    } else if (l == l0) {
      c = _last.counter + 1;
    } else if (l == lm) {
      c = remote.counter + 1;
    } else {
      c = 0;
    }
    return _last = _stamp(l, c);
  }

  /// Throws [ClockDriftException] when [remote] is more than [maxDrift] ahead of
  /// [nowWallMillis]; changes nothing.
  void checkDrift(Hlc remote, int nowWallMillis) {
    if (remote.wallMillis - nowWallMillis > maxDrift.inMilliseconds) {
      throw ClockDriftException(remote, nowWallMillis, maxDrift);
    }
  }

  /// The timestamp `(l, c)`, or `(l + 1, 0)` when [c] would pass the counter's range.
  Hlc _stamp(int l, int c) =>
      c > Hlc.maxCounter ? Hlc(l + 1, 0, nodeId) : Hlc(l, c, nodeId);
}
