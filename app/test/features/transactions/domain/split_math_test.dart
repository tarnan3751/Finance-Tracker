// The split arithmetic: what the split magnitudes leave unallocated, the sum rule, and
// "Distribute evenly", which sums exactly, keeps every part within one minor unit of the
// others and puts the larger parts last, in currencies of zero, two and three decimals.
import 'dart:math';

import 'package:finance_tracker/features/transactions/domain/split_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

Money _usd(int cents) => Money(cents, 'USD');

void main() {
  group('unallocated', () {
    test('is what the parts leave of the magnitude, the sign aside', () {
      expect(unallocated(_usd(-1000), [_usd(300), _usd(200)]), _usd(500));
      expect(unallocated(_usd(1000), [_usd(300), _usd(200)]), _usd(500));
    });

    test('is negative when the parts exceed it', () {
      expect(unallocated(_usd(-1000), [_usd(800), _usd(300)]), _usd(-100));
    });

    test('with no parts is the whole magnitude', () {
      expect(unallocated(_usd(-1234), const []), _usd(1234));
    });
  });

  group('splitsBalance', () {
    test('holds only for an exact sum', () {
      expect(splitsBalance(_usd(-12418), [_usd(10000), _usd(2418)]), isTrue);
      expect(splitsBalance(_usd(-12418), [_usd(10000), _usd(2417)]), isFalse);
      expect(splitsBalance(_usd(-12418), [_usd(10000), _usd(2419)]), isFalse);
    });

    test('a single part equal to the amount balances', () {
      expect(splitsBalance(_usd(500), [_usd(500)]), isTrue);
    });
  });

  group('distributeEvenly', () {
    test(r'puts the extra cent on the last row: $10.00 in three', () {
      expect(distributeEvenly(_usd(-1000), 3), [
        _usd(333),
        _usd(333),
        _usd(334),
      ]);
    });

    test('puts the extra units on the last rows', () {
      expect(distributeEvenly(_usd(1002), 4), [
        _usd(250),
        _usd(250),
        _usd(251),
        _usd(251),
      ]);
    });

    test('an even amount divides evenly', () {
      expect(distributeEvenly(_usd(900), 3), [_usd(300), _usd(300), _usd(300)]);
    });

    test('never loses a minor unit, in any currency (property)', () {
      final Random random = Random(4);
      for (final String currency in ['USD', 'JPY', 'BHD']) {
        for (int i = 0; i < 500; i++) {
          final int magnitude = random.nextInt(10000000);
          final Money amount = Money(
            random.nextBool() ? -magnitude : magnitude,
            currency,
          );
          final int parts = 1 + random.nextInt(12);
          final List<Money> split = distributeEvenly(amount, parts);
          final String reason = '$amount in $parts';

          expect(split, hasLength(parts), reason: reason);
          expect(splitsBalance(amount, split), isTrue, reason: reason);
          for (final Money part in split) {
            expect(part.currencyCode, currency, reason: reason);
            expect(part.isNegative, isFalse, reason: reason);
          }
          final int smallest = split.first.minorUnits;
          for (int k = 1; k < split.length; k++) {
            final int step = split[k].minorUnits - split[k - 1].minorUnits;
            // Non-decreasing: the larger parts last.
            expect(step, inInclusiveRange(0, 1), reason: reason);
          }
          expect(split.last.minorUnits - smallest, lessThanOrEqualTo(1));
        }
      }
    });
  });
}
