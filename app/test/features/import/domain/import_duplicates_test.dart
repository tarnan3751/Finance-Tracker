// Likely duplicates of an import: the same file again and an overlapping export into a
// manual account (the re-import match), each stored row answering for one incoming row,
// a hidden stored row counting, a bank row on a linked account (the detector), and the
// rows that never match: another day or amount, a transfer's other leg, a deleted row.
import 'package:finance_tracker/features/import/domain/import_duplicates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

Transaction _t(
  String id, {
  String account = 'acct',
  int cents = -475,
  int day = 5,
  String name = 'CONTOSO COFFEE 0193',
  DataSource source = DataSource.import,
  bool hidden = false,
  DateTime? deletedAt,
}) {
  final DateTime at = DateTime.utc(2026, 10, 31);
  return Transaction(
    id: id,
    accountId: account,
    amount: Money(cents, 'USD'),
    date: LocalDate(2026, 10, day),
    pending: false,
    name: name,
    hidden: hidden,
    source: source,
    createdAt: at,
    updatedAt: at,
    deletedAt: deletedAt,
    syncVersion: 0,
  );
}

void main() {
  test('the same file again: every row', () {
    final List<Transaction> stored = [
      _t('s1'),
      _t('s2', cents: -8217, day: 6, name: 'NORTHWIND'),
    ];
    final List<Transaction> incoming = [
      _t('i1', name: ' contoso   coffee 0193 '),
      _t('i2', cents: -8217, day: 6, name: 'NORTHWIND'),
    ];
    expect(likelyDuplicates(incoming, stored), {'i1', 'i2'});
  });

  test('an overlap: only the rows already there', () {
    final List<Transaction> stored = [_t('s1', day: 1), _t('s2', day: 2)];
    final List<Transaction> incoming = [
      _t('i1', day: 2),
      _t('i2', day: 3),
      _t('i3', day: 4),
    ];
    expect(likelyDuplicates(incoming, stored), {'i1'});
  });

  test('each stored row answers for one incoming row', () {
    final List<Transaction> incoming = [_t('i1'), _t('i2')];
    expect(likelyDuplicates(incoming, [_t('s1')]), {'i1'});
    expect(likelyDuplicates(incoming, [_t('s1'), _t('s2')]), {'i1', 'i2'});
    expect(likelyDuplicates(incoming, const []), isEmpty);
  });

  test('a hidden or manual stored row counts; a deleted one does not', () {
    expect(likelyDuplicates([_t('i1')], [_t('s1', hidden: true)]), {'i1'});
    expect(
      likelyDuplicates([_t('i1')], [_t('s1', source: DataSource.manual)]),
      {'i1'},
    );
    expect(
      likelyDuplicates(
        [_t('i1')],
        [_t('s1', deletedAt: DateTime.utc(2026, 10, 30))],
      ),
      isEmpty,
    );
  });

  test('another day, amount, name or account is not a re-import', () {
    final Transaction stored = _t('s1');
    expect(likelyDuplicates([_t('i1', day: 6)], [stored]), isEmpty);
    expect(likelyDuplicates([_t('i1', cents: -476)], [stored]), isEmpty);
    expect(likelyDuplicates([_t('i1', name: 'Other')], [stored]), isEmpty);
    expect(likelyDuplicates([_t('i1', cents: 475)], [stored]), isEmpty);
  });

  test('a bank row: the detector pairs it within three days', () {
    final List<Transaction> stored = [
      _t('p1', source: DataSource.plaid, day: 3, name: 'Contoso'),
      _t('p2', source: DataSource.plaid, day: 20, cents: -1000),
    ];
    final List<Transaction> incoming = [
      _t('i1', day: 5),
      _t('i2', day: 25, cents: -1000),
      _t('i3', day: 20, cents: 1000),
    ];
    expect(likelyDuplicates(incoming, stored), {'i1'});
  });

  test('a bank row answers for one incoming row, the nearest', () {
    final List<Transaction> bank = [
      _t('p1', source: DataSource.plaid, day: 10, name: 'Contoso'),
    ];
    expect(likelyDuplicates([_t('i1', day: 10), _t('i2', day: 10)], bank), {
      'i1',
    });
    expect(likelyDuplicates([_t('i1', day: 8), _t('i2', day: 11)], bank), {
      'i2',
    });
    // A stored row the re-import match took is not paired again.
    expect(
      likelyDuplicates(
        [_t('i1', day: 10), _t('i2', day: 11), _t('i3', day: 12)],
        [_t('s1', day: 10), _t('p1', source: DataSource.plaid, day: 10)],
      ),
      {'i1', 'i2'},
    );
  });

  test('two incoming rows never mark each other', () {
    expect(likelyDuplicates([_t('i1'), _t('i2')], const []), isEmpty);
  });
}
