/// The hybrid logical clock timestamp carried by change-log entries.
///
/// Only the value type lives here; the send and receive rules that advance a clock are the
/// sync engine's (`packages/sync_engine`, Phase 2).
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

/// A hybrid logical clock timestamp: wall-clock milliseconds, a logical counter and the
/// id of the node that issued it. Ordered by wall time, then counter, then node id.
///
/// The packed form `<wall>-<counter>-<node>` zero-pads the wall time to 15 digits and the
/// counter to 5, so packed strings sort in the same order as [compareTo].
@immutable
final class Hlc implements Comparable<Hlc> {
  /// A timestamp; [wallMillis] must be 0 to 10^15 - 1, [counter] 0 to 99999, and
  /// [nodeId] one or more of `A-Z a-z 0-9 _ . : -` (a UUID fits; no whitespace).
  Hlc(this.wallMillis, this.counter, this.nodeId) {
    if (wallMillis < 0 || wallMillis > maxWallMillis) {
      throw ArgumentError.value(wallMillis, 'wallMillis', 'out of range');
    }
    if (counter < 0 || counter > maxCounter) {
      throw ArgumentError.value(counter, 'counter', 'out of range');
    }
    if (!_nodeIdPattern.hasMatch(nodeId)) {
      throw ArgumentError.value(
        nodeId,
        'nodeId',
        'must match [A-Za-z0-9_.:-]+',
      );
    }
  }

  /// Parses the packed form; the node id may itself contain `-`.
  factory Hlc.parse(String packed) {
    final match = _packedPattern.firstMatch(packed);
    if (match == null) throw FormatException('Not a packed HLC', packed);
    return Hlc(int.parse(match[1]!), int.parse(match[2]!), match[3]!);
  }

  /// The largest wall time the packed form holds (about the year 33658).
  static const int maxWallMillis = 999999999999999;

  /// The largest counter the packed form holds.
  static const int maxCounter = 99999;

  /// The clock bound: how far a wall time may lie ahead of the physical clock that judges
  /// it. A relay refuses a pushed entry more than this ahead of its own clock, and a
  /// device never adopts a received wall time more than this ahead of its own
  /// (`docs/reference/sync.md`, **The clock bound**).
  static const Duration maxDrift = Duration(hours: 1);

  static final RegExp _nodeIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

  static final RegExp _packedPattern = RegExp(
    r'^(\d{15})-(\d{5})-([A-Za-z0-9_.:-]+)$',
  );

  /// Milliseconds since the Unix epoch, UTC.
  final int wallMillis;

  /// The logical counter within one wall-clock millisecond.
  final int counter;

  /// The issuing node (device) id.
  final String nodeId;

  /// The wall time as a UTC instant.
  DateTime get wall =>
      DateTime.fromMillisecondsSinceEpoch(wallMillis, isUtc: true);

  /// The packed, sortable string form.
  String pack() =>
      '${wallMillis.toString().padLeft(15, '0')}-'
      '${counter.toString().padLeft(5, '0')}-$nodeId';

  @override
  int compareTo(Hlc other) {
    final byWall = wallMillis.compareTo(other.wallMillis);
    if (byWall != 0) return byWall;
    final byCounter = counter.compareTo(other.counter);
    if (byCounter != 0) return byCounter;
    return nodeId.compareTo(other.nodeId);
  }

  @override
  bool operator ==(Object other) =>
      other is Hlc &&
      other.wallMillis == wallMillis &&
      other.counter == counter &&
      other.nodeId == nodeId;

  @override
  int get hashCode => Object.hash(wallMillis, counter, nodeId);

  @override
  String toString() => pack();
}

/// Converts [Hlc] to and from its packed string, for annotated model fields.
final class HlcConverter implements JsonConverter<Hlc, String> {
  /// The converter.
  const HlcConverter();

  @override
  Hlc fromJson(String json) => Hlc.parse(json);

  @override
  String toJson(Hlc object) => object.pack();
}
