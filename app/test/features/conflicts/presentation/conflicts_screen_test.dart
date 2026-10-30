// The Conflicts screen: both values with the device that wrote each (this device, a name
// from the devices list, else the node id) and when, in the device's zone; values shown
// as amounts, categories and lists; the two actions; the empty state; and Settings →
// Sync's entry, there only while there are conflicts.
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/conflicts/application/conflicts_providers.dart';
import 'package:finance_tracker/features/conflicts/data/in_memory_conflict_store.dart';
import 'package:finance_tracker/features/conflicts/domain/sync_conflict.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

final class _SignedIn extends SyncController {
  @override
  SyncStatus build() => const SyncStatus(
    phase: SyncPhase.idle,
    ledger: (pending: 0, rejected: 0, lastRejected: null, held: 0),
  );

  @override
  Future<void> syncNow() async {}
}

// 30 October 2026, 14:02 and 14:05 UTC: 10:02 and 10:05 in New York (EDT).
final Hlc _mine = Hlc(
  DateTime.utc(2026, 10, 30, 14, 2).millisecondsSinceEpoch,
  0,
  'dev-a',
);
final Hlc _tablet = Hlc(
  DateTime.utc(2026, 10, 30, 14, 5).millisecondsSinceEpoch,
  0,
  'dev-b',
);
final Hlc _gone = Hlc(
  DateTime.utc(2026, 10, 30, 14, 6).millisecondsSinceEpoch,
  0,
  'dev-old',
);

SyncConflict _conflict(
  String id,
  String field,
  Object? local,
  Object? remote, {
  Hlc? remoteClock,
  String? label = 'Starbucks',
}) => SyncConflict(
  entityType: EntityType.transaction,
  entityId: id,
  field: field,
  localValue: local,
  localClock: _mine,
  remoteValue: remote,
  remoteClock: remoteClock ?? _tablet,
  entityLabel: label,
  seenAt: DateTime.utc(2026, 10, 30, 14, 10),
);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late InMemoryConflictStore store;
  setUp(() => store = InMemoryConflictStore());
  tearDown(() => store.close());

  List<Override> overrides() => [
    conflictStoreProvider.overrideWithValue(store),
    syncDeviceIdProvider.overrideWithValue('dev-a'),
    conflictDeviceNamesProvider.overrideWith(
      (ref) async => {'dev-a': 'Pixel 6', 'dev-b': 'Pixel Tablet'},
    ),
    // The demo's recorder: "Keep this device's value" only forgets here; its write is
    // conflict_actions_test's.
    changeRecorderProvider.overrideWithValue(const NoChangeRecorder()),
  ];

  Clock newYork() => FixedClock(
    DateTime.utc(2026, 10, 30, 15),
    tz.getLocation('America/New_York'),
  );

  testWidgets('shows both values, their devices and times in the zone', (
    tester,
  ) async {
    store
      ..add(_conflict('t1', 'notes', 'Team lunch', 'Lunch with Ana'))
      ..add(
        _conflict(
          't2',
          'amount',
          {'minor_units': -1250, 'currency': 'USD'},
          {'minor_units': -1350, 'currency': 'USD'},
          remoteClock: _gone,
        ),
      )
      ..add(
        _conflict(
          't3',
          'tags',
          ['work', 'food'],
          const <Object?>[],
          label: null,
        ),
      );
    await pumpApp(
      tester,
      initialLocation: '/settings/conflicts',
      clock: newYork(),
      size: const Size(412, 1600),
      overrides: overrides(),
    );
    expect(find.text('Conflicts'), findsOneWidget);
    expect(find.text('Transaction · Starbucks'), findsNWidgets(2));
    expect(find.text('Transaction'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Team lunch'), findsOneWidget);
    expect(find.text('Lunch with Ana'), findsOneWidget);
    expect(find.text('-\$12.50'), findsOneWidget);
    expect(find.text('-\$13.50'), findsOneWidget);
    expect(find.text('work, food'), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
    expect(find.text('This device, Oct 30, 2026 10:02 AM'), findsNWidgets(3));
    expect(find.text('Pixel Tablet, Oct 30, 2026 10:05 AM'), findsNWidgets(2));
    // A device no longer listed shows its id.
    expect(find.text('dev-old, Oct 30, 2026 10:06 AM'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('an account is shown by its name', (tester) async {
    store.add(_conflict('t1', 'account_id', checkingId, 'gone-account'));
    await pumpApp(
      tester,
      initialLocation: '/settings/conflicts',
      clock: newYork(),
      overrides: [...overrides(), storeOverride(seededStore())],
    );
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Everyday Checking'), findsOneWidget);
    // An account this device does not have shows its id.
    expect(find.text('gone-account'), findsOneWidget);
  });

  testWidgets('either action resolves its conflict', (tester) async {
    store
      ..add(_conflict('t1', 'notes', 'Team lunch', 'Lunch with Ana'))
      ..add(_conflict('t2', 'notes', 'Coffee', 'Coffee beans'));
    await pumpApp(
      tester,
      initialLocation: '/settings/conflicts',
      clock: newYork(),
      size: const Size(412, 1200),
      overrides: overrides(),
    );
    await tester.tap(find.text('Keep the other').first);
    await tester.pumpAndSettle();
    expect(find.text('Team lunch'), findsNothing);
    await tester.tap(find.text("Keep this device's value"));
    await tester.pumpAndSettle();
    expect(find.text('No conflicts'), findsOneWidget);
    expect(await store.watch().first, isEmpty);
  });

  testWidgets('Settings → Sync lists the conflicts only while there are any', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      size: const Size(412, 1400),
      overrides: [
        ...overrides(),
        syncControllerProvider.overrideWith(_SignedIn.new),
      ],
    );
    expect(find.textContaining('Conflicts ('), findsNothing);
    store.add(_conflict('t1', 'notes', 'a', 'b'));
    await tester.pumpAndSettle();
    expect(find.text('Conflicts (1)'), findsOneWidget);
    await tester.tap(find.text('Conflicts (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Team lunch'), findsNothing);
    expect(find.text('Starbucks'), findsNothing);
    expect(find.text('Transaction · Starbucks'), findsOneWidget);
  });
}
