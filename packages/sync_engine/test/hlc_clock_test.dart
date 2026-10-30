// The hybrid logical clock: every branch of the paper's Figure 5 with hand-computed values,
// the Figure 4 loop, Theorems 1 and 2 on random message traces, and the engine's edge cases
// (a backwards wall clock, counter overflow, the clock bound). The random traces draw from
// `Random(seed)` with the default seed 20261024; set SYNC_ENGINE_SEED to explore.
import 'dart:io';
import 'dart:math';

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

final int seed =
    int.tryParse(Platform.environment['SYNC_ENGINE_SEED'] ?? '') ?? 20261024;

void main() {
  group('send (Figure 5, send or local event)', () {
    test('starts from wall 0, counter 0 and takes the physical clock', () {
      final clock = HlcClock('a');
      expect(clock.last, Hlc(0, 0, 'a'));
      expect(clock.send(100), Hlc(100, 0, 'a'));
    });

    test('a later physical clock resets the counter', () {
      final clock = HlcClock('a', last: Hlc(100, 7, 'a'));
      expect(clock.send(101), Hlc(101, 0, 'a'));
    });

    test('the same physical millisecond increments the counter', () {
      final clock = HlcClock('a', last: Hlc(100, 7, 'a'));
      expect(clock.send(100), Hlc(100, 8, 'a'));
    });

    test('a wall clock that went backwards keeps l and increments c', () {
      final clock = HlcClock('a', last: Hlc(100, 7, 'a'));
      expect(clock.send(40), Hlc(100, 8, 'a'));
      expect(clock.send(99), Hlc(100, 9, 'a'));
      expect(clock.send(101), Hlc(101, 0, 'a'));
    });
  });

  group('receive (Figure 5, receive event of message m)', () {
    test('l = l\' = l.m: c = max(c, c.m) + 1', () {
      final clock = HlcClock('a', last: Hlc(100, 3, 'a'));
      expect(clock.receive(Hlc(100, 9, 'b'), 50), Hlc(100, 10, 'a'));
      final other = HlcClock('a', last: Hlc(100, 12, 'a'));
      expect(other.receive(Hlc(100, 9, 'b'), 50), Hlc(100, 13, 'a'));
    });

    test('l = l\' only: c = c + 1', () {
      final clock = HlcClock('a', last: Hlc(100, 3, 'a'));
      expect(clock.receive(Hlc(90, 9, 'b'), 50), Hlc(100, 4, 'a'));
    });

    test('l = l.m only: c = c.m + 1', () {
      final clock = HlcClock('a', last: Hlc(100, 3, 'a'));
      expect(clock.receive(Hlc(120, 9, 'b'), 110), Hlc(120, 10, 'a'));
    });

    test('the physical clock is ahead of both: c = 0', () {
      final clock = HlcClock('a', last: Hlc(100, 3, 'a'));
      expect(clock.receive(Hlc(120, 9, 'b'), 130), Hlc(130, 0, 'a'));
    });

    test('the result keeps this node\'s id', () {
      final clock = HlcClock('a');
      expect(clock.receive(Hlc(5, 0, 'b'), 1).nodeId, 'a');
    });
  });

  test('the Figure 4 loop: c stays bounded and resets once pt passes l', () {
    // Node 0's physical clock is at 10 while nodes 1, 2 and 3 are near 0; they pass a
    // message round 1 -> 2 -> 3 -> 1, each node's physical clock ticking by one per turn.
    final n0 = HlcClock('n0');
    final nodes = [HlcClock('n1'), HlcClock('n2'), HlcClock('n3')];
    final pt = [1, 1, 1];
    var message = n0.send(10);
    expect(message, Hlc(10, 0, 'n0'));
    var previous = message;
    var turn = 0;
    while (pt.every((p) => p <= 10)) {
      final j = turn % 3;
      final received = nodes[j].receive(message, pt[j]);
      expect(received.compareTo(previous), greaterThan(0));
      expect(received.wallMillis, 10, reason: 'l stays at 10 while pt < 10');
      message = nodes[j].send(pt[j]);
      expect(message.compareTo(received), greaterThan(0));
      previous = message;
      pt[j]++;
      turn++;
    }
    expect(previous.counter, lessThan(3 * 2 * 11));
    // Once a node's pt passes 10, its next event resets c.
    for (var j = 0; j < 3; j++) {
      expect(nodes[j].send(11), Hlc(11, 0, 'n${j + 1}'));
    }
  });

  test('Theorems 1 and 2 on random traces (seed $seed)', () {
    final r = Random(seed);
    for (var trace = 0; trace < 200; trace++) {
      final n = r.nextInt(4) + 2;
      final clocks = [for (var i = 0; i < n; i++) HlcClock('n$i')];
      final pt = [for (var i = 0; i < n; i++) r.nextInt(50)];
      final inFlight = <(int, Hlc)>[];
      for (var step = 0; step < 200; step++) {
        final j = r.nextInt(n);
        pt[j] += r.nextInt(3); // physical clocks advance by 0 to 2 per step
        final before = clocks[j].last;
        final Hlc event;
        if (inFlight.isNotEmpty && r.nextBool()) {
          final (to, m) = inFlight.removeAt(r.nextInt(inFlight.length));
          final atNode = clocks[to].last;
          event = clocks[to].receive(m, pt[to]);
          final why = 'seed $seed, trace $trace, step $step';
          // Theorem 1: the send happened before the receive, and the previous event on
          // the receiving node happened before it.
          expect(event.compareTo(m), greaterThan(0), reason: why);
          expect(event.compareTo(atNode), greaterThan(0), reason: why);
          expect(event.wallMillis, greaterThanOrEqualTo(pt[to]), reason: why);
          continue;
        }
        event = clocks[j].send(pt[j]);
        final why = 'seed $seed, trace $trace, step $step';
        expect(event.compareTo(before), greaterThan(0), reason: why);
        // Theorem 2: l >= pt.
        expect(event.wallMillis, greaterThanOrEqualTo(pt[j]), reason: why);
        inFlight.add((r.nextInt(n), event));
      }
    }
  });

  group('counter overflow', () {
    test('send advances the wall by one millisecond', () {
      final clock = HlcClock('a', last: Hlc(100, Hlc.maxCounter, 'a'));
      expect(clock.send(100), Hlc(101, 0, 'a'));
    });

    test('receive advances past both clocks', () {
      final clock = HlcClock('a', last: Hlc(100, 5, 'a'));
      final remote = Hlc(100, Hlc.maxCounter, 'b');
      final got = clock.receive(remote, 90);
      expect(got, Hlc(101, 0, 'a'));
      expect(got.compareTo(remote), greaterThan(0));
    });
  });

  group('the clock bound', () {
    const hour = 3600 * 1000;

    test('the bound is one hour, the one the relays use', () {
      expect(Hlc.maxDrift, const Duration(hours: 1));
      expect(HlcClock('a').maxDrift, Hlc.maxDrift);
      expect(InMemorySyncRelay(nowWallMillis: () => 0).maxDrift, Hlc.maxDrift);
    });

    test('a remote wall up to an hour ahead is adopted', () {
      final clock = HlcClock('a', last: Hlc(100, 1, 'a'));
      expect(clock.beyondBound(Hlc(1000 + hour, 0, 'b'), 1000), isFalse);
      expect(
        clock.receive(Hlc(1000 + hour, 4, 'b'), 1000),
        Hlc(1000 + hour, 5, 'a'),
        reason: 'exactly the bound is adopted',
      );
    });

    test('a remote wall beyond the bound clamps to the physical clock', () {
      final clock = HlcClock('a', last: Hlc(100, 1, 'a'));
      final remote = Hlc(1000 + hour + 1, 9, 'b');
      expect(clock.beyondBound(remote, 1000), isTrue);
      expect(
        clock.last,
        Hlc(100, 1, 'a'),
        reason: 'beyondBound changes nothing',
      );
      expect(clock.receive(remote, 1000), Hlc(1000, 0, 'a'));
      expect(clock.last.compareTo(remote), lessThan(0));
    });

    test(
      'a clamp with the physical clock behind the clock bumps the counter',
      () {
        final clock = HlcClock('a', last: Hlc(5000, 3, 'a'));
        expect(
          clock.receive(Hlc(1000 + 5 * hour, 0, 'b'), 1000),
          Hlc(5000, 4, 'a'),
        );
        expect(
          clock.receive(Hlc(1000 + 5 * hour, 0, 'b'), 5000),
          Hlc(5000, 5, 'a'),
        );
      },
    );

    test(
      'a clamp at the counter limit advances the wall by one millisecond',
      () {
        final clock = HlcClock('a', last: Hlc(5000, Hlc.maxCounter, 'a'));
        expect(clock.receive(Hlc(10 * hour, 0, 'b'), 1000), Hlc(5001, 0, 'a'));
      },
    );

    test('sendAfter stamps past a clock beyond the bound, unlike receive', () {
      final clock = HlcClock('a', last: Hlc(1000, 2, 'a'));
      final seen = Hlc(1000 + 5 * hour, 7, 'b');
      expect(clock.sendAfter(seen, 1000), Hlc(1000 + 5 * hour, 8, 'a'));
      expect(clock.sendAfter(seen, 1000), Hlc(1000 + 5 * hour, 9, 'a'));
      expect(
        clock.sendAfter(Hlc(5, 0, 'b'), 1000 + 6 * hour),
        Hlc(1000 + 6 * hour, 0, 'a'),
        reason: 'a seen clock behind is a plain send',
      );
    });

    test('sendAfter at the counter limit advances the wall', () {
      final clock = HlcClock('a');
      expect(
        clock.sendAfter(Hlc(5000, Hlc.maxCounter, 'b'), 1000),
        Hlc(5001, 0, 'a'),
      );
    });

    test('the bound is configurable', () {
      final clock = HlcClock('a', maxDrift: const Duration(seconds: 1));
      expect(clock.beyondBound(Hlc(2001, 0, 'b'), 1000), isTrue);
      expect(clock.beyondBound(Hlc(2000, 0, 'b'), 1000), isFalse);
      expect(clock.receive(Hlc(2001, 0, 'b'), 1000), Hlc(1000, 0, 'a'));
    });

    test('a remote clock behind is never clamped', () {
      final clock = HlcClock('a');
      expect(clock.beyondBound(Hlc(1, 0, 'b'), 1 << 40), isFalse);
      expect(clock.receive(Hlc(1, 0, 'b'), 1 << 40), Hlc(1 << 40, 0, 'a'));
    });

    test('with skews of hours, the clock strictly increases and never adopts a '
        'wall beyond the bound', () {
      final r = Random(seed);
      for (var trace = 0; trace < 200; trace++) {
        final clock = HlcClock('a');
        var physical = 1000 * hour;
        var maxPhysical = 0;
        var previous = clock.last;
        for (var i = 0; i < 100; i++) {
          physical += r.nextInt(2 * hour) - hour ~/ 2;
          maxPhysical = max(maxPhysical, physical);
          final got = r.nextBool()
              ? clock.send(physical)
              : clock.receive(
                  Hlc(
                    physical + r.nextInt(6 * hour) - 3 * hour,
                    r.nextInt(9),
                    'b',
                  ),
                  physical,
                );
          expect(got.compareTo(previous), greaterThan(0));
          expect(
            got.wallMillis,
            lessThanOrEqualTo(maxPhysical + hour + 1),
            reason: 'trace $trace step $i',
          );
          previous = got;
        }
      }
    });
  });

  test('a persisted last from another node is refused', () {
    expect(
      () => HlcClock('a', last: Hlc(1, 0, 'b')),
      throwsA(isA<ArgumentError>()),
    );
  });
}
