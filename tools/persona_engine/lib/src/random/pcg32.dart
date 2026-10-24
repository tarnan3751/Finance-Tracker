/// PCG32, the persona engine's only source of randomness.
///
/// The engine ships its own generator so that a seed gives the same household on every Dart
/// version: `dart:math`'s `Random` makes no such promise. This is PCG32 as Melissa O'Neill's
/// reference `pcg-c-basic` defines it (`pcg32_srandom_r`, `pcg32_random_r`,
/// `pcg32_boundedrand_r`): a 64-bit linear congruential state with the XSH-RR output
/// permutation, 32-bit outputs, and one of 2^63 streams chosen by the sequence constant.
/// `test/pcg32_test.dart` checks the author's published `pcg32-demo` output.
///
/// Dart's native `int` arithmetic wraps modulo 2^64, which is the arithmetic the reference
/// uses on `uint64_t`; `>>>` is the unsigned shift. The package therefore runs on the Dart
/// VM (the app, the CLI and the tests), not on the web, where `int` is a double.
library;

import 'package:persona_engine/src/random/fnv1a.dart';

const int _multiplier = 6364136223846793005;
const int _mask32 = 0xffffffff;

/// A PCG32 generator.
final class Pcg32 {
  /// A generator seeded as `pcg32_srandom_r(initState, initSeq)` does.
  Pcg32(int initState, int initSeq) : _inc = (initSeq << 1) | 1 {
    nextUint32();
    _state += initState;
    nextUint32();
  }

  /// The root generator of a household: the state is [seed] and the stream is the FNV-1a
  /// hash of the persona's [name], so two personas with one seed never share a sequence.
  factory Pcg32.forPersona(String name, int seed) =>
      Pcg32(seed, fnv1a64String(name));

  int _state = 0;
  final int _inc;

  /// The next 32-bit output, in `[0, 2^32)`.
  int nextUint32() {
    final old = _state;
    _state = old * _multiplier + _inc;
    final xorShifted = (((old >>> 18) ^ old) >>> 27) & _mask32;
    final rot = old >>> 59;
    return ((xorShifted >>> rot) | (xorShifted << ((-rot) & 31))) & _mask32;
  }

  /// A uniform integer in `[0, bound)`, without modulo bias: outputs below
  /// `2^32 mod bound` are rejected, as `pcg32_boundedrand_r` does. [bound] is 1 to 2^32.
  int nextInt(int bound) {
    if (bound < 1 || bound > 0x100000000) {
      throw RangeError.range(bound, 1, 0x100000000, 'bound');
    }
    final threshold = (0x100000000 - bound) % bound;
    while (true) {
      final r = nextUint32();
      if (r >= threshold) return r % bound;
    }
  }

  /// A uniform integer in `[min, max]`, both inclusive.
  int nextIntInRange(int min, int max) {
    if (max < min) throw ArgumentError('max $max is below min $min');
    return min + nextInt(max - min + 1);
  }

  /// True with probability [permille] / 1000.
  bool chance(int permille) => nextInt(1000) < permille;

  /// An element of [items], uniformly.
  T pick<T>(List<T> items) => items[nextInt(items.length)];

  /// An index into [weights], with probability proportional to each weight.
  int pickWeighted(List<int> weights) {
    var total = 0;
    for (final w in weights) {
      total += w;
    }
    var r = nextInt(total);
    for (var i = 0; i < weights.length; i++) {
      if (r < weights[i]) return i;
      r -= weights[i];
    }
    throw StateError('unreachable');
  }

  /// A child generator for the component named [key]: its state is two draws from this
  /// generator and its stream is the FNV-1a hash of [key]. Forking in a fixed order keeps
  /// every component's draws independent of how many draws the others make.
  Pcg32 fork(String key) {
    final high = nextUint32();
    final low = nextUint32();
    return Pcg32((high << 32) | low, fnv1a64String(key));
  }
}
