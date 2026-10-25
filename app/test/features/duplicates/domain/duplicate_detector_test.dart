// The duplicate detector: the pairing rules case by case, the ranking, and a seeded
// property test over random ledgers. The property test is deterministic by default
// (seeds from 1000); set DUPLICATES_SEED to start elsewhere
// (`DUPLICATES_SEED=5000 flutter test test/features/duplicates`). A failure names its
// seed. Each run checks the detector against a brute-force reading of the rules over
// every pair (so every pair it reports is within the rules and none is missing), that
// the result does not depend on the input's order, that no row pairs with itself, that
// two bank rows of one account never pair, that no hidden row pairs, that the ranking
// holds, and that dismissed pairs are left out and only they.
import 'dart:io';
import 'dart:math';

import 'package:finance_tracker/core/util/binary_compare.dart';
import 'package:finance_tracker/features/duplicates/domain/duplicate_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

final DateTime _at = DateTime.utc(2026, 10, 1, 9);

Transaction _t(
  String id, {
  String account = 'a1',
  int cents = -1000,
  String currency = 'USD',
  LocalDate? date,
  DataSource source = DataSource.manual,
  String name = 'Purchase',
  String? merchant,
  bool deleted = false,
  bool hidden = false,
}) => Transaction(
  id: id,
  accountId: account,
  amount: Money(cents, currency),
  date: date ?? LocalDate(2026, 10, 10),
  pending: false,
  name: name,
  merchantName: merchant,
  source: source,
  createdAt: _at,
  updatedAt: _at,
  deletedAt: deleted ? _at : null,
  hidden: hidden,
  syncVersion: 0,
);

List<String> _pairs(List<DuplicateCandidate> found) => [
  for (final DuplicateCandidate c in found) '${c.first.id}+${c.second.id}',
];

// The rules, read pair by pair.
bool _pairsByRule(Transaction a, Transaction b) {
  bool bank(Transaction t) =>
      t.source == DataSource.plaid || t.source == DataSource.demo;
  bool entered(Transaction t) =>
      t.source == DataSource.manual || t.source == DataSource.import;
  return a.id != b.id &&
      a.deletedAt == null &&
      b.deletedAt == null &&
      !a.hidden &&
      !b.hidden &&
      a.source != DataSource.derived &&
      b.source != DataSource.derived &&
      a.amount == b.amount &&
      a.date.daysUntil(b.date).abs() <= duplicateWindowDays &&
      (a.accountId != b.accountId ||
          (bank(a) && entered(b)) ||
          (entered(a) && bank(b)));
}

void main() {
  group('the rules', () {
    test('a manual entry and its bank row on one account pair', () {
      final List<DuplicateCandidate> found = findDuplicates([
        _t('m1', name: 'Blue Bottle'),
        _t(
          'p1',
          source: DataSource.plaid,
          date: LocalDate(2026, 10, 12),
          name: 'BLUE BOTTLE COFFEE',
        ),
      ]);
      expect(_pairs(found), ['m1+p1']);
      expect(found.single.dayDistance, 2);
      expect(found.single.similarity, (shared: 2, total: 3));
    });

    test(
      'two bank rows of one account never pair; of two accounts they do',
      () {
        expect(
          findDuplicates([
            _t('p1', source: DataSource.plaid),
            _t('p2', source: DataSource.plaid),
            _t('d1', source: DataSource.demo),
          ]),
          isEmpty,
        );
        expect(
          _pairs(
            findDuplicates([
              _t('p1', source: DataSource.plaid),
              _t('p2', account: 'a2', source: DataSource.plaid),
            ]),
          ),
          ['p1+p2'],
        );
      },
    );

    test('two entered rows pair across accounts only', () {
      expect(
        findDuplicates([
          _t('m1'),
          _t('m2'),
          _t('i1', source: DataSource.import),
        ]),
        isEmpty,
      );
      expect(_pairs(findDuplicates([_t('m1'), _t('m2', account: 'a2')])), [
        'm1+m2',
      ]);
    });

    test('the amount must match in sign and currency', () {
      expect(
        findDuplicates([
          _t('m1'),
          _t('m2', account: 'a2', cents: 1000),
          _t('m3', account: 'a3', cents: -1000, currency: 'EUR'),
          _t('m4', account: 'a4', cents: -1001),
        ]),
        isEmpty,
      );
    });

    test('three days apart pair; four do not', () {
      expect(
        _pairs(
          findDuplicates([
            _t('m1', date: LocalDate(2026, 2, 27)),
            _t('m2', account: 'a2', date: LocalDate(2026, 3, 2)),
            _t('m3', account: 'a3', date: LocalDate(2026, 3, 6)),
          ]),
        ),
        ['m1+m2'],
      );
    });

    test('deleted, hidden and derived rows, and dismissed pairs, are left '
        'out', () {
      final List<Transaction> rows = [
        _t('m1'),
        _t('m2', account: 'a2', deleted: true),
        _t('h1', account: 'a5', hidden: true),
        _t('x1', account: 'a3', source: DataSource.derived),
        _t('m3', account: 'a4'),
      ];
      expect(_pairs(findDuplicates(rows)), ['m1+m3']);
      expect(findDuplicates(rows, dismissed: {PairKey('m3', 'm1')}), isEmpty);
    });

    test('ranked by days apart, then likeness, then the newer pair', () {
      final List<DuplicateCandidate> found = findDuplicates([
        _t('a', name: 'Rent', date: LocalDate(2026, 10, 1)),
        _t('b', account: 'a2', name: 'Rent', date: LocalDate(2026, 10, 2)),
        _t('c', name: 'Gym', cents: -500, date: LocalDate(2026, 10, 8)),
        _t('d', account: 'a2', name: 'Other', cents: -500),
        _t('e', account: 'a3', name: 'Gym', cents: -500),
        _t('f', name: 'Tea', cents: -300, date: LocalDate(2026, 9, 1)),
        _t('g', account: 'a2', name: 'Tea', cents: -300),
      ]);
      expect(_pairs(found), ['d+e', 'a+b', 'c+e', 'c+d']);
    });

    test('a key is the same either way round', () {
      expect(PairKey('b', 'a'), PairKey('a', 'b'));
      expect(PairKey('b', 'a').first, 'a');
    });
  });

  test('property: the detector agrees with the rules on random ledgers', () {
    final int start =
        int.tryParse(Platform.environment['DUPLICATES_SEED'] ?? '') ?? 1000;
    for (int seed = start; seed < start + 300; seed++) {
      final Random random = Random(seed);
      T pick<T>(List<T> values) => values[random.nextInt(values.length)];
      const List<String> words = ['blue', 'bottle', 'coffee', 'rent', 'gym'];
      final List<Transaction> ledger = [
        for (int i = 0; i < 2 + random.nextInt(40); i++)
          _t(
            't$i',
            account: pick(['a1', 'a2', 'a3']),
            cents: pick([-450, -1000, 450, 1000]),
            currency: random.nextInt(8) == 0 ? 'EUR' : 'USD',
            date: LocalDate(2026, 2, 20).addDays(random.nextInt(14)),
            source: pick(DataSource.values),
            name: [for (int w = 0; w < 1 + random.nextInt(3); w++) pick(words)]
                .join(' '),
            merchant: random.nextBool() ? null : pick(words),
            deleted: random.nextInt(10) == 0,
            hidden: random.nextInt(10) == 0,
          ),
      ];
      final String reason = 'seed $seed';

      final List<DuplicateCandidate> found = findDuplicates(ledger);
      final Set<PairKey> expected = {
        for (int i = 0; i < ledger.length; i++)
          for (int j = i + 1; j < ledger.length; j++)
            if (_pairsByRule(ledger[i], ledger[j]))
              PairKey(ledger[i].id, ledger[j].id),
      };
      final List<PairKey> keys = [for (final c in found) c.key];
      expect(keys.toSet(), expected, reason: reason);
      expect(keys, hasLength(expected.length), reason: '$reason: each once');
      for (final DuplicateCandidate c in found) {
        expect(c.first.id, isNot(c.second.id), reason: reason);
        expect(compareBinary(c.first.id, c.second.id), lessThan(0));
        expect(
          c.first.accountId != c.second.accountId ||
              !({
                c.first.source,
                c.second.source,
              }.every((s) => s == DataSource.plaid || s == DataSource.demo)),
          isTrue,
          reason: '$reason: two bank rows of one account',
        );
        expect(
          c.first.hidden || c.second.hidden,
          isFalse,
          reason: '$reason: a hidden row',
        );
        expect(_pairsByRule(c.second, c.first), isTrue, reason: reason);
      }
      for (int i = 1; i < found.length; i++) {
        expect(
          found[i - 1].dayDistance,
          lessThanOrEqualTo(found[i].dayDistance),
          reason: '$reason: ranking',
        );
      }

      // Any order gives the same result.
      final List<Transaction> shuffled = [...ledger]..shuffle(random);
      expect(
        _pairs(findDuplicates(shuffled)),
        _pairs(found),
        reason: '$reason: order',
      );

      // Dismissed pairs, and only they, go.
      final Set<PairKey> dismissed = {
        for (final PairKey k in expected)
          if (random.nextBool()) k,
      };
      expect(
        {for (final c in findDuplicates(ledger, dismissed: dismissed)) c.key},
        expected.difference(dismissed),
        reason: '$reason: dismissed',
      );
    }
  });
}
