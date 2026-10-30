/// The hybrid logical clock that stamps change-log entries (`PLAN.md` §6.4).
///
/// The send and receive rules are Figure 5 of Kulkarni, Demirbas, Madappa, Avva and Leone,
/// "Logical Physical Clocks and Consistent Snapshots in Globally Distributed Databases"
/// (2014), with two deliberate departures, both for monotonicity, which last-writer-wins
/// merge depends on: a counter that would pass [Hlc.maxCounter] advances the wall by one
/// millisecond instead of rolling over, and the paper's corrective reset of `l` to the
/// physical clock (§4.1) is never applied. In place of the paper's other corrective
/// action, ignoring a message too far ahead of the physical clock, a remote clock beyond
/// the bound ([Hlc.maxDrift]) is received without adopting its wall time: the clock
/// clamps to its own physical time and bumps the counter. A local edit is stamped past
/// the clocks of the values it changes ([sendAfter]), whatever the bound, so it is
/// causally after them (`docs/reference/sync.md`, **The clock bound**).
///
/// The clock does no IO: the host persists [HlcClock.last] (`SyncStore.saveClock`) and
/// passes it back at construction.
library;

import 'package:shared_models/shared_models.dart';

/// One node's hybrid logical clock.
final class HlcClock {
  /// A clock for [nodeId], resumed from the persisted [last] when there is one (the
  /// paper's initial state, wall 0 and counter 0, otherwise). A remote wall time more than
  /// [maxDrift] ahead of the physical clock is never adopted by [receive].
  HlcClock(this.nodeId, {Hlc? last, this.maxDrift = Hlc.maxDrift})
    : _last = last ?? Hlc(0, 0, nodeId) {
    if (_last.nodeId != nodeId) {
      throw ArgumentError.value(last, 'last', 'issued by another node');
    }
  }

  /// The node (device) id stamped on every timestamp this clock issues.
  final String nodeId;

  /// How far ahead of the physical clock a remote wall time may be and still be adopted.
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

  /// A timestamp for a local event at physical time [nowWallMillis] that follows [seen]:
  /// greater than [last] and than [seen], by the receive rule of Figure 5 without the
  /// bound. [LocalEditor] stamps an edit after the greatest clock among the values it
  /// changes, so the edit wins over what the user saw even when that clock is beyond the
  /// bound. Such a clock was accepted by a relay, so it was within the bound of the
  /// relay's time, and an edit just past it is too while the relay's clock does not step
  /// back (and the counter does not overflow into the next millisecond at the bound's
  /// edge); otherwise the relay refuses it for drift for a while and it stays queued.
  Hlc sendAfter(Hlc seen, int nowWallMillis) => _past(seen, nowWallMillis);

  /// Advances the clock on receiving [remote] at physical time [nowWallMillis].
  ///
  /// Within the bound, past [remote] (Figure 5). When [remote] is [beyondBound], its wall
  /// time is not adopted: the clock advances as [send] does, to its own physical time or,
  /// when that is behind, by one on the counter, and stays behind [remote].
  Hlc receive(Hlc remote, int nowWallMillis) =>
      beyondBound(remote, nowWallMillis)
      ? send(nowWallMillis)
      : _past(remote, nowWallMillis);

  Hlc _past(Hlc remote, int nowWallMillis) {
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

  /// Whether [remote] is more than [maxDrift] ahead of [nowWallMillis], so that [receive]
  /// clamps instead of adopting it. Changes nothing.
  bool beyondBound(Hlc remote, int nowWallMillis) =>
      remote.wallMillis - nowWallMillis > maxDrift.inMilliseconds;

  /// The timestamp `(l, c)`, or `(l + 1, 0)` when [c] would pass the counter's range.
  Hlc _stamp(int l, int c) =>
      c > Hlc.maxCounter ? Hlc(l + 1, 0, nodeId) : Hlc(l, c, nodeId);
}
