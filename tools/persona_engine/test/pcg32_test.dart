// PCG32 against its author's reference output, and FNV-1a against its published vectors.
import 'package:persona_engine/persona_engine.dart';
import 'package:test/test.dart';

String _hex(int v) => '0x${v.toRadixString(16).padLeft(8, '0')}';

/// One round of pcg-c-basic's `pcg32-demo.c`: six outputs, 65 coins, 33 dice, a deal.
({String outputs, String coins, String rolls, String cards}) _round(Pcg32 rng) {
  final outputs = [for (var i = 0; i < 6; i++) _hex(rng.nextUint32())]
      .join(' ');
  final coins = [for (var i = 0; i < 65; i++) rng.nextInt(2) == 1 ? 'H' : 'T']
      .join();
  final rolls = [for (var i = 0; i < 33; i++) rng.nextInt(6) + 1].join(' ');
  final cards = List<int>.generate(52, (i) => i);
  for (var i = 52; i > 1; i--) {
    final chosen = rng.nextInt(i);
    final card = cards[chosen];
    cards[chosen] = cards[i - 1];
    cards[i - 1] = card;
  }
  const number = 'A23456789TJQK';
  const suit = 'hcds';
  final deal = [for (final c in cards) '${number[c ~/ 4]}${suit[c % 4]}']
      .join(' ');
  return (outputs: outputs, coins: coins, rolls: rolls, cards: deal);
}

void main() {
  group('PCG32 reference output (pcg32-demo, pcg32_srandom_r(42, 54))', () {
    // https://www.pcg-random.org/using-pcg-c-basic.html, "Playing with the Code".
    test('round 1', () {
      final round = _round(Pcg32(42, 54));
      expect(
        round.outputs,
        '0xa15c02b7 0x7b47f409 0xba1d3330 0x83d2f293 0xbfa4784b 0xcbed606e',
      );
      expect(
        round.coins,
        'HHTTTHTHHHTHTTTHHHHHTTTHHHTHTHTHTTHTTTHHHHHHTTTTHHTTTTTHTTTTTTTHT',
      );
      expect(
        round.rolls,
        '3 4 1 1 2 2 3 2 4 3 2 4 3 3 5 2 3 1 3 1 5 1 4 1 5 6 4 6 6 2 6 3 3',
      );
      expect(
        round.cards,
        'Qd Ks 6d 3s 3d 4c 3h Td Kc 5c Jh Kd Jd As 4s 4h Ad Th Ac Jc 7s Qs '
        '2s 7h Kh 2d 6c Ah 4d Qh 9h 6s 5s 2c 9c Ts 8d 9s 3c 8c Js 5d 2h 6h '
        '7d 8s 9d 5h 8h Qc 7c Tc',
      );
    });

    test('round 5', () {
      final rng = Pcg32(42, 54);
      for (var i = 0; i < 4; i++) {
        _round(rng);
      }
      final round = _round(rng);
      expect(
        round.outputs,
        '0xfcef7cd6 0x1b488b5a 0xd0daf7ea 0x1d9a70f7 0x241a37cf 0x9a3857b7',
      );
      expect(
        round.coins,
        'HHHHTHHTTHTTHHHTTTHHTHTHTTTTHTTHTHTTTHHHTHTHTTHTTHTHHTHTHHHTHTHTT',
      );
      expect(
        round.rolls,
        '5 4 1 2 6 1 3 1 5 6 3 6 2 1 4 4 5 2 1 5 6 5 6 4 4 4 5 2 6 4 3 5 6',
      );
    });
  });

  group('Pcg32', () {
    test('nextInt stays in range and rejects a bad bound', () {
      final rng = Pcg32(7, 11);
      for (var i = 0; i < 10000; i++) {
        final v = rng.nextInt(7);
        expect(v, inInclusiveRange(0, 6));
      }
      expect(() => rng.nextInt(0), throwsRangeError);
      expect(() => rng.nextInt(0x100000001), throwsRangeError);
      expect(rng.nextInt(0x100000000), inInclusiveRange(0, 0xffffffff));
    });

    test('nextIntInRange is inclusive at both ends', () {
      final rng = Pcg32(1, 2);
      final seen = <int>{};
      for (var i = 0; i < 2000; i++) {
        seen.add(rng.nextIntInRange(-2, 2));
      }
      expect(seen, {-2, -1, 0, 1, 2});
    });

    test('pickWeighted never picks a zero weight', () {
      final rng = Pcg32(3, 4);
      for (var i = 0; i < 2000; i++) {
        expect(rng.pickWeighted([2, 0, 1]), isNot(1));
      }
    });

    test('forks are reproducible and keyed', () {
      List<int> draws(Pcg32 r) => [for (var i = 0; i < 8; i++) r.nextUint32()];
      final a = Pcg32.forPersona('renter', 1);
      final b = Pcg32.forPersona('renter', 1);
      expect(draws(a.fork('x')), draws(b.fork('x')));
      expect(
        draws(Pcg32.forPersona('renter', 1).fork('x')),
        isNot(draws(Pcg32.forPersona('renter', 1).fork('y'))),
      );
      expect(
        draws(Pcg32.forPersona('renter', 1)),
        isNot(draws(Pcg32.forPersona('family', 1))),
      );
    });
  });

  test('FNV-1a 64 matches the published test vectors', () {
    // The reference vectors from the FNV authors' test suite (draft-eastlake-fnv).
    expect(fnv1a64Hex(fnv1a64String('')), 'cbf29ce484222325');
    expect(fnv1a64Hex(fnv1a64String('a')), 'af63dc4c8601ec8c');
    expect(fnv1a64Hex(fnv1a64String('foobar')), '85944171f73967e8');
  });
}
