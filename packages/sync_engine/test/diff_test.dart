// The change diff: classification, field granularity, nested values replaced whole, and
// the delete's tombstone instant.
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

final hlc = Hlc(
  DateTime.utc(2026, 10, 24, 15, 4, 5, 123).millisecondsSinceEpoch,
  2,
  'dev-a',
);

Map<String, Object?> txn({Object? notes, Object? tags, Object? deletedAt}) => {
  'id': 't1',
  'amount': {'minor_units': -1234, 'currency': 'USD'},
  'notes': notes,
  'tags': tags ?? <Object?>['food'],
  'splits': <Object?>[
    {
      'category_id': 'c1',
      'amount': {'minor_units': -1234, 'currency': 'USD'},
      'note': null,
    },
  ],
  'deleted_at': deletedAt,
};

void main() {
  test('no before is a create carrying every field but deleted_at', () {
    final e = diff(EntityType.transaction, 't1', null, txn(), hlc)!;
    expect(e.operation, ChangeOperation.create);
    expect(e.payload, txn()..remove('deleted_at'));
    expect(e.payload.containsKey('deleted_at'), isFalse);
    expect(e.hlc, hlc);
    expect(e.deviceId, 'dev-a');
    expect(e.synced, isFalse);
    expect(e.entityType, EntityType.transaction);
    expect(e.entityId, 't1');
  });

  test('a create of a deleted entity is refused', () {
    expect(
      () => diff(
        EntityType.transaction,
        't1',
        null,
        txn(deletedAt: '2026-10-24T15:04:05.123Z'),
        hlc,
      ),
      throwsArgumentError,
    );
  });

  test('an empty create is refused', () {
    expect(
      () => diff(EntityType.transaction, 't1', null, const {}, hlc),
      throwsArgumentError,
    );
    expect(
      () => diff(EntityType.transaction, 't1', null, const {
        'deleted_at': null,
      }, hlc),
      throwsArgumentError,
    );
  });

  test('an update carries only the changed fields', () {
    final e = diff(
      EntityType.transaction,
      't1',
      txn(),
      txn(notes: 'lunch'),
      hlc,
    )!;
    expect(e.operation, ChangeOperation.update);
    expect(e.payload, {'notes': 'lunch'});
  });

  test('an unchanged entity yields no entry', () {
    expect(diff(EntityType.transaction, 't1', txn(), txn(), hlc), isNull);
  });

  test('nested values compare deeply and are carried whole', () {
    final before = txn();
    final after = {
      ...txn(),
      'amount': {
        'currency': 'USD',
        'minor_units': -1234,
      }, // same, other key order
      'splits': <Object?>[
        {
          'category_id': 'c1',
          'amount': {'minor_units': -1000, 'currency': 'USD'},
          'note': null,
        },
        {
          'category_id': 'c2',
          'amount': {'minor_units': -234, 'currency': 'USD'},
          'note': 'tip',
        },
      ],
    };
    final e = diff(EntityType.transaction, 't1', before, after, hlc)!;
    expect(e.payload.keys, ['splits']);
    expect(e.payload['splits'], after['splits']);
  });

  test('a reordered list is a change', () {
    final e = diff(
      EntityType.transaction,
      't1',
      txn(tags: ['a', 'b']),
      txn(tags: ['b', 'a']),
      hlc,
    )!;
    expect(e.payload, {
      'tags': ['b', 'a'],
    });
  });

  test('a key missing from after is written as null', () {
    final after = txn(notes: 'x')..remove('notes');
    final e = diff(EntityType.transaction, 't1', txn(notes: 'x'), after, hlc)!;
    expect(e.payload, {'notes': null});
    expect(e.payload.containsKey('notes'), isTrue);
  });

  test('a key added in after is written', () {
    final e = diff(EntityType.transaction, 't1', txn(), {
      ...txn(),
      'receipt_path': 'r',
    }, hlc)!;
    expect(e.payload, {'receipt_path': 'r'});
  });

  test('deleted_at going non-null is a delete stamped with the entry wall', () {
    final e = diff(
      EntityType.transaction,
      't1',
      {...txn(), 'updated_at': '2026-10-24T15:00:00.000Z'},
      {
        ...txn(deletedAt: '2020-01-01T00:00:00.000Z'),
        'updated_at': '2026-10-24T15:04:05.000Z',
      },
      hlc,
    )!;
    expect(e.operation, ChangeOperation.delete);
    expect(e.payload, {
      'deleted_at': '2026-10-24T15:04:05.123Z',
      'updated_at': '2026-10-24T15:04:05.000Z',
    });
  });

  test('deleted_at going null is a restore, an update', () {
    final e = diff(
      EntityType.transaction,
      't1',
      txn(deletedAt: '2026-10-24T15:04:05.123Z'),
      txn(),
      hlc,
    )!;
    expect(e.operation, ChangeOperation.update);
    expect(e.payload, {'deleted_at': null});
  });

  test('a change to an existing tombstone is an update', () {
    final e = diff(
      EntityType.transaction,
      't1',
      txn(deletedAt: '2026-10-24T15:04:05.123Z'),
      txn(deletedAt: '2026-10-24T16:00:00.000Z'),
      hlc,
    )!;
    expect(e.operation, ChangeOperation.update);
  });

  test('a value that is not JSON is refused', () {
    expect(
      () => diff(EntityType.transaction, 't1', txn(), {
        ...txn(),
        'notes': DateTime(2026),
      }, hlc),
      throwsArgumentError,
    );
    expect(
      () => diff(EntityType.transaction, 't1', txn(), {
        ...txn(),
        'notes': double.nan,
      }, hlc),
      throwsArgumentError,
    );
  });

  test('the payload is an unmodifiable copy', () {
    final after = txn(notes: 'x');
    final e = diff(EntityType.transaction, 't1', null, after, hlc)!;
    (after['tags']! as List<Object?>).add('changed');
    expect(e.payload['tags'], ['food']);
    expect(
      () => (e.payload['tags']! as List<Object?>).add('y'),
      throwsUnsupportedError,
    );
  });
}
