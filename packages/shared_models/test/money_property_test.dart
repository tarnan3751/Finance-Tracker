// Randomized property tests for Money and the HLC packed form. Deterministic by default: every property draws from
// `Random(seed)` with the default seed 20261024; set SHARED_MODELS_SEED to another integer
// to explore (`SHARED_MODELS_SEED=7 dart test test/money_property_test.dart`). A failure's
// reason names the seed, the case index and the inputs, so it reproduces exactly.
import 'dart:io';
import 'dart:math';

import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

const int defaultSeed = 20261024;
const int casesPerProperty = 5000;

final int seed =
    int.tryParse(Platform.environment['SHARED_MODELS_SEED'] ?? '') ??
    defaultSeed;

const _codes = ['USD', 'JPY', 'KWD', 'CLF', 'EUR'];

/// A random int in [-bound, bound], spread over magnitudes so small and large both occur.
int _amount(Random r, {int maxDigits = 15}) {
  final digits = r.nextInt(maxDigits) + 1;
  var value = 0;
  for (var i = 0; i < digits; i++) {
    value = value * 10 + r.nextInt(10);
  }
  return r.nextBool() ? -value : value;
}

/// Any 64-bit integer except -2^63, which Money excludes.
int _anyMinorUnits(Random r) {
  final value = (r.nextInt(1 << 32) << 32) | r.nextInt(1 << 32);
  return value == -0x8000000000000000 ? 0 : value;
}

void property(String name, void Function(Random r, String Function() at) body) {
  test('$name (seed $seed)', () {
    final r = Random(seed);
    for (var i = 0; i < casesPerProperty; i++) {
      body(r, () => 'seed $seed, case $i');
    }
  });
}

void main() {
  property(
    'allocate sums exactly and each part is within one unit of its share',
    (r, at) {
      final money = Money(_amount(r), _codes[r.nextInt(_codes.length)]);
      final weights = List<int>.generate(
        r.nextInt(8) + 1,
        (_) => r.nextInt(1000),
      );
      if (weights.every((w) => w == 0)) weights[0] = 1;
      final parts = money.allocate(weights);
      final why = '${at()}: $money by $weights -> $parts';
      expect(Money.sum(parts), money, reason: why);
      final total = weights.reduce((a, b) => a + b);
      for (var i = 0; i < parts.length; i++) {
        // |part * total - amount * weight| < total, i.e. within one minor unit of the
        // exact share amount * weight / total. BigInt keeps the check itself exact.
        final error =
            BigInt.from(parts[i].minorUnits) * BigInt.from(total) -
            BigInt.from(money.minorUnits) * BigInt.from(weights[i]);
        expect(
          error.abs() < BigInt.from(total),
          isTrue,
          reason: '$why, part $i',
        );
      }
    },
  );

  property('split then sum is identity', (r, at) {
    final money = Money(_amount(r), _codes[r.nextInt(_codes.length)]);
    final parts = money.split(r.nextInt(50) + 1);
    expect(Money.sum(parts), money, reason: '${at()}: $money');
    final sizes = parts.map((p) => p.minorUnits).toSet();
    expect(
      sizes.reduce(max) - sizes.reduce(min) <= 1,
      isTrue,
      reason: '${at()}: $parts',
    );
  });

  property('a + b - b == a', (r, at) {
    final code = _codes[r.nextInt(_codes.length)];
    final a = Money(_amount(r, maxDigits: 18), code);
    final b = Money(_amount(r, maxDigits: 18), code);
    expect(a + b - b, a, reason: '${at()}: $a, $b');
  });

  property('parse(toDecimalString()) is identity over the whole range', (
    r,
    at,
  ) {
    final money = Money(
      r.nextBool() ? _amount(r, maxDigits: 18) : _anyMinorUnits(r),
      _codes[r.nextInt(_codes.length)],
    );
    expect(
      Money.parse(money.toDecimalString(), money.currencyCode),
      money,
      reason: '${at()}: ${money.toDecimalString()}',
    );
  });

  property('multipliedBy(n, d) then back is within one minor unit', (r, at) {
    final money = Money(_amount(r, maxDigits: 12), 'USD');
    final n = r.nextInt(999) + 1;
    final d = r.nextInt(999) + 1;
    final mode = RoundingMode.values[r.nextInt(RoundingMode.values.length)];
    // Scaling up first keeps the round trip within a unit: back(there(a)) has error at
    // most (d/n + 1) units otherwise, so the property is stated for n >= d.
    final (up, down) = n >= d ? (n, d) : (d, n);
    final there = money.multipliedBy(up, down, mode: mode);
    final back = there.multipliedBy(down, up, mode: mode);
    expect(
      (back - money).minorUnits.abs() <= 1,
      isTrue,
      reason:
          '${at()}: $money * $up/$down by ${mode.name} = $there, back $back',
    );
  });

  property('packed HLC strings sort as compareTo', (r, at) {
    Hlc next() => Hlc(
      r.nextBool() ? r.nextInt(1000) : r.nextInt(1 << 32) * 1000,
      r.nextInt(3) == 0 ? 0 : r.nextInt(Hlc.maxCounter + 1),
      ['a', 'b', 'node-1', 'node-10', 'Z'][r.nextInt(5)],
    );
    final a = next();
    final b = next();
    expect(
      a.pack().compareTo(b.pack()).sign,
      a.compareTo(b).sign,
      reason: '${at()}: $a vs $b',
    );
  });
}
