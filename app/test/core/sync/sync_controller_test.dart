// The sync controller: when sessions run (start, local changes after the debounce,
// resume, Sync now), one at a time, the cursor reset, the node adoption, the status and
// its persistence; and that it never runs in demo or while signed out.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../contract/repository_fixture.dart';

/// A relay that counts and can hold or fail its calls.
final class ScriptedRelay implements SyncRelay {
  ScriptedRelay(this.inner);

  final InMemorySyncRelay inner;
  int pulls = 0;
  int pushing = 0;
  int mostPushing = 0;
  Completer<void>? hold;
  Object? failNextPull;

  @override
  Future<PushResult> push(List<ChangeLogEntry> entries) async {
    pushing++;
    if (pushing > mostPushing) mostPushing = pushing;
    try {
      await hold?.future;
      return await inner.push(entries);
    } finally {
      pushing--;
    }
  }

  @override
  Future<PullPage> pull({
    required int since,
    int limit = 200,
    required String deviceId,
  }) async {
    pulls++;
    final Object? failure = failNextPull;
    if (failure != null) {
      failNextPull = null;
      throw failure;
    }
    return inner.pull(since: since, limit: limit, deviceId: deviceId);
  }
}

/// The session's device id, changeable as a sign-out and sign-in change it.
final class _Device extends Notifier<String?> {
  @override
  String? build() => 'dev-a';

  void set(String? id) => state = id;
}

final NotifierProvider<_Device, String?> _device = NotifierProvider(
  _Device.new,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ScriptedRelay relay;
  late SteppingClock clock;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    clock = SteppingClock();
    relay = ScriptedRelay(
      InMemorySyncRelay(
        nowWallMillis: () => clock.nowUtc().millisecondsSinceEpoch,
      ),
    );
  });
  tearDown(() => database.close());

  ProviderContainer device({String? deviceId = 'dev-a'}) {
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        ...overridesFor(AppConfig.dev()),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        syncDeviceIdProvider.overrideWithValue(deviceId),
        syncRelayProvider.overrideWithValue(deviceId == null ? null : relay),
        syncDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 100),
        ),
      ],
      retry: (_, _) => null,
    );
    return container;
  }

  // Waits until the controller is idle with a session finished after [after] pulls.
  Future<SyncStatus> settled(ProviderContainer c, {int pulls = 1}) async {
    for (int i = 0; i < 200; i++) {
      final SyncStatus s = c.read(syncControllerProvider);
      if (s.phase == SyncPhase.idle &&
          relay.pulls >= pulls &&
          s.lastSyncAt != null) {
        return s;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('the controller did not settle: ${c.read(syncControllerProvider)}');
  }

  test('the demo flavor never syncs', () {
    final ProviderContainer c = ProviderContainer.test(
      overrides: overridesFor(AppConfig.demo()),
    );
    expect(c.read(syncControllerProvider), SyncStatus.unavailable);
  });

  test(
    'while signed out nothing runs and the database is not needed',
    () async {
      final ProviderContainer c = ProviderContainer.test(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.dev()),
          databaseProvider.overrideWith(
            (ref) => throw StateError('no database'),
          ),
        ],
      );
      expect(c.read(syncControllerProvider), SyncStatus.signedOut);
      await c.read(syncControllerProvider.notifier).syncNow();
      expect(relay.pulls, 0);
    },
  );

  test('a session runs at start, adopting the device id for what was recorded '
      'before sign-in', () async {
    final ProviderContainer before = device(deviceId: null);
    await before.read(accountRepositoryProvider).upsert(testAccount('a1'));
    before.dispose();

    final ProviderContainer c = device();
    c.read(syncControllerProvider);
    final SyncStatus status = await settled(c);
    expect(status.failure, isNull);
    expect(status.lastSummary!.pushed, 1);
    expect(relay.inner.entries.single.deviceId, 'dev-a');
    expect(relay.inner.entries.single.hlc.nodeId, 'dev-a');
    expect(status.ledger!.pending, 0);

    // The status survives a restart.
    final DriftSyncStore store = c.read(driftSyncStoreProvider);
    expect(await store.meta('last_report'), isNotNull);
    c.dispose();
    final ProviderContainer again = device();
    again.read(syncControllerProvider);
    final SyncStatus restored = await settled(again, pulls: 2);
    expect(restored.lastSyncAt, isNotNull);
  });

  test('a local change syncs after the debounce', () async {
    final ProviderContainer c = device();
    c.read(syncControllerProvider);
    await settled(c);
    await c.read(accountRepositoryProvider).upsert(testAccount('a1'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(relay.inner.entries, isEmpty, reason: 'still inside the debounce');
    await settled(c, pulls: 2);
    expect(relay.inner.entries, hasLength(1));
  });

  test(
    'one session at a time; triggers during one run one more after it',
    () async {
      final ProviderContainer c = device();
      c.read(syncControllerProvider);
      await settled(c);
      final SyncController controller = c.read(syncControllerProvider.notifier);
      await c.read(accountRepositoryProvider).upsert(testAccount('a1'));
      relay.hold = Completer<void>();
      final Future<void> first = controller.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.read(syncControllerProvider).phase, SyncPhase.running);
      final Future<void> second = controller.syncNow();
      final Future<void> third = controller.syncNow();
      relay.hold!.complete();
      relay.hold = null;
      await Future.wait([first, second, third]);
      expect(
        relay.pulls,
        3,
        reason: 'the start, the held run, one coalesced rerun',
      );
    },
  );

  test('a reset relay resets the cursor and pulls again', () async {
    final ProviderContainer c = device();
    c.read(syncControllerProvider);
    await settled(c);
    await c.read(driftSyncStoreProvider).savePullCursor(40);
    relay.failNextPull = const SyncCursorInvalidException(40, 0);
    await c.read(syncControllerProvider.notifier).syncNow();
    expect(c.read(syncControllerProvider).failure, isNull);
    expect(await c.read(driftSyncStoreProvider).pullCursor(), 0);
  });

  test(
    'a failure is kept in the status and cleared by the next session',
    () async {
      final ProviderContainer c = device();
      c.read(syncControllerProvider);
      await settled(c);
      relay.failNextPull = StateError('down');
      await c.read(syncControllerProvider.notifier).syncNow();
      expect(c.read(syncControllerProvider).failure, SyncFailure.other);
      expect(c.read(syncControllerProvider).phase, SyncPhase.idle);
      await c.read(syncControllerProvider.notifier).syncNow();
      expect(c.read(syncControllerProvider).failure, isNull);
    },
  );

  test('a session runs when the app resumes', () async {
    final ProviderContainer c = device();
    c.read(syncControllerProvider);
    await settled(c);
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.instance;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settled(c, pulls: 2);
  });

  test('the outbox at start is pushed by the start session alone', () async {
    final ProviderContainer before = device(deviceId: null);
    await before.read(accountRepositoryProvider).upsert(testAccount('a1'));
    before.dispose();
    final ProviderContainer c = device();
    c.read(syncControllerProvider);
    await settled(c);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(relay.pulls, 1, reason: 'no debounced session on top of the start');
  });

  test('a sign-out and sign-in during a session: one session at a time, each entry '
      'on the relay once', () async {
    final ProviderContainer c = ProviderContainer.test(
      overrides: [
        ...overridesFor(AppConfig.dev()),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        syncDeviceIdProvider.overrideWith((ref) => ref.watch(_device)),
        syncRelayProvider.overrideWith(
          (ref) => ref.watch(_device) == null ? null : relay,
        ),
        syncDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 100),
        ),
      ],
      retry: (_, _) => null,
    );
    c.read(syncControllerProvider);
    await settled(c);

    await c.read(accountRepositoryProvider).upsert(testAccount('a1'));
    relay.hold = Completer<void>();
    final Future<void> held = c.read(syncControllerProvider.notifier).syncNow();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(relay.pushing, 1);

    c.read(_device.notifier).set(null);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.read(syncControllerProvider).phase, SyncPhase.signedOut);
    c.read(_device.notifier).set('dev-b');
    c.read(syncControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(relay.mostPushing, 1, reason: 'no second session while one is held');

    relay.hold!.complete();
    relay.hold = null;
    await held;
    while (c.read(syncControllerProvider).phase != SyncPhase.idle) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await c.read(syncControllerProvider.notifier).syncNow();
    expect(relay.mostPushing, 1);
    final List<ChangeLogEntry> stored = relay.inner.entries;
    expect(stored.where((e) => e.entityId == 'a1'), hasLength(1));
    expect(await c.read(driftSyncStoreProvider).unsynced(), isEmpty);

    // Changes made now go out under the new node.
    await c
        .read(accountRepositoryProvider)
        .upsert(testAccount('a1', name: 'Renamed'));
    await c.read(syncControllerProvider.notifier).syncNow();
    expect(relay.inner.entries.last.deviceId, 'dev-b');
    expect(c.read(syncControllerProvider).failure, isNull);
  });
}
