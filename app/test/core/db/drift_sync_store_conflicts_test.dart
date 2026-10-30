// The Drift sync store's conflicts: kept one per entity and field with the entity's name,
// a newer one replacing it, audit instants left out; dropped when the field's clock moves
// on or the entity is deleted; relabelled when it is renamed; swept after thirty days.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:timezone/timezone.dart' as tz;

/// A clock the test moves.
final class _Clock implements Clock {
  DateTime now = DateTime.utc(2026, 10, 24, 15);

  @override
  DateTime nowUtc() => now;

  @override
  DateTime todayLocalMidnight() => DateTime.utc(now.year, now.month, now.day);

  @override
  LocalDate today() => LocalDate.fromDateTime(now);

  @override
  tz.Location get location => tz.UTC;
}

const Category _category = Category(
  id: 'c1',
  name: 'Lunches',
  isSystem: false,
  icon: 'restaurant',
  color: 0xFF336699,
);

final Hlc _mine = Hlc(1761318000000, 0, 'dev-a');
final Hlc _theirs = Hlc(1761318060000, 0, 'dev-b');

void main() {
  late AppDatabase database;
  late _Clock clock;
  late DriftSyncStore store;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    clock = _Clock();
    store = DriftSyncStore(database, clock);
    // The category as this device wrote it, then b's rename merged over it.
    final Map<String, Object?> fields = categoryRecordJson(_category)
      ..remove(deletedAtField);
    await store.write(
      EntityRecord(
        type: EntityType.category,
        id: 'c1',
        fields: {...fields, 'name': 'Dinners'},
        fieldClocks: {for (final String f in fields.keys) f: _mine}
          ..['name'] = _theirs,
        createdAt: _mine,
      ),
    );
  });
  tearDown(() => database.close());

  FieldConflict conflict(String field, {Object? local = 'Lunches'}) =>
      FieldConflict(
        entityType: EntityType.category,
        entityId: 'c1',
        field: field,
        localValue: local,
        localClock: _mine,
        remoteValue: 'Dinners',
        remoteClock: _theirs,
      );

  Future<List<ConflictRow>> rows() => database.select(database.conflicts).get();

  Future<void> rewrite(Map<String, Object?> change, Hlc at) async {
    final EntityRecord record = (await store.read(EntityType.category, 'c1'))!;
    await store.write(
      EntityRecord(
        type: record.type,
        id: record.id,
        fields: {...record.fields, ...change},
        fieldClocks: {
          ...record.fieldClocks,
          for (final String f in change.keys) f: at,
        },
        createdAt: record.createdAt,
      ),
    );
  }

  test(
    'keeps a conflict with both values, clocks, the label and when',
    () async {
      await store.recordConflicts([conflict('name')]);
      final ConflictRow row = (await rows()).single;
      expect(
        (row.entityType, row.entityId, row.field),
        ('category', 'c1', 'name'),
      );
      expect((row.localValue, row.remoteValue), ('"Lunches"', '"Dinners"'));
      expect((row.localHlc, row.remoteHlc), (_mine.pack(), _theirs.pack()));
      expect(row.entityLabel, 'Dinners');
      expect(row.seenAt, clock.now);
      expect(await database.select(database.changeLog).get(), isEmpty);
    },
  );

  test('a newer conflict on the field replaces the older', () async {
    await store.recordConflicts([conflict('name', local: 'first')]);
    await store.recordConflicts([conflict('name', local: 'second')]);
    expect((await rows()).single.localValue, '"second"');
  });

  test('an audit instant is not kept', () async {
    await store.recordConflicts([
      conflict('updated_at'),
      conflict('created_at'),
    ]);
    expect(await rows(), isEmpty);
  });

  test('a write that moves the field on drops it; another field keeps it and '
      'relabels', () async {
    await store.recordConflicts([conflict('name')]);
    await rewrite({'icon': 'cake'}, Hlc(1761318070000, 0, 'dev-c'));
    expect((await rows()).single.entityLabel, 'Dinners');
    await rewrite({'name': 'Suppers'}, Hlc(1761318080000, 0, 'dev-c'));
    expect(await rows(), isEmpty);
  });

  test('the label follows a rename of another conflict\'s entity', () async {
    await store.recordConflicts([conflict('icon', local: 'fork')]);
    // icon's clock is mine in the setup: make it theirs, as the conflict says.
    await rewrite({'icon': 'Dinners'}, _theirs);
    await store.recordConflicts([conflict('icon', local: 'fork')]);
    await rewrite({'name': 'Suppers'}, Hlc(1761318080000, 0, 'dev-c'));
    expect((await rows()).single.entityLabel, 'Suppers');
  });

  test('deleting the entity drops its conflicts', () async {
    await store.recordConflicts([conflict('name')]);
    await rewrite({
      deletedAtField: '2026-10-24T15:05:00.000Z',
    }, Hlc(1761318090000, 0, 'dev-b'));
    expect(await rows(), isEmpty);
  });

  test('the sweep removes conflicts thirty days old, and only those', () async {
    await store.recordConflicts([conflict('name')]);
    clock.now = clock.now.add(const Duration(days: 30));
    expect(await store.sweepConflicts(), 0);
    expect(await rows(), hasLength(1));
    clock.now = clock.now.add(const Duration(milliseconds: 1));
    expect(await store.sweepConflicts(), 1);
    expect(await rows(), isEmpty);
  });
}
