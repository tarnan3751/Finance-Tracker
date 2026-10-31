// The sync controller: when sessions run (start, local changes after the debounce,
// resume, Sync now), one at a time, the cursor reset, the node adoption, the status and
// its persistence, the Plaid pull after each session (against the in-app fake server);
// that it never runs in demo or while signed out; and that it holds while the restore
// offer is pending, running once the offer is answered.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/connectivity_provider.dart';
import 'package:finance_tracker/core/platform/fake_connectivity.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart'
    show SyncProblem, SyncProblemNotification;
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../contract/repository_fixture.dart';
import '../../helpers/dev_wiring.dart';

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

/// A restore offer worked out by [_answer] at each build.
final class _SlowOffer extends RestoreOffer {
  _SlowOffer(this._answer);

  final Future<bool> Function() _answer;

  @override
  Future<bool> build() => _answer();
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
  late FakeConnectivity network;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    // An install that answered the restore offer, as every install but a fresh one has.
    await database.customStatement(
      'INSERT INTO app_meta (key, value) VALUES (?, ?)',
      [AppMetaKeys.restoreOfferAnswered, '2026-10-24T15:00:00.000Z'],
    );
    clock = SteppingClock();
    network = FakeConnectivity();
    relay = ScriptedRelay(
      InMemorySyncRelay(
        nowWallMillis: () => clock.nowUtc().millisecondsSinceEpoch,
      ),
    );
  });
  tearDown(() async {
    await database.close();
    await network.close();
  });

  ProviderContainer device({
    String? deviceId = 'dev-a',
    List<Override> extra = const [],
    FakeServer? server,
  }) {
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        ...extra,
        ...devWiring(),
        for (final Override o in fakeApiOverrides(signedIn: true))
          // ignore: invalid_use_of_visible_for_testing_member
          if (server == null || !identical(o.origin, fakeServerProvider)) o,
        if (server != null) fakeServerProvider.overrideWithValue(server),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        connectivityProvider.overrideWithValue(network),
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

  test('in-memory data never syncs, even signed in', () {
    final ProviderContainer c = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.prod()),
        syncDeviceIdProvider.overrideWithValue('dev-a'),
        syncRelayProvider.overrideWithValue(relay),
      ],
    );
    expect(c.read(syncControllerProvider), SyncStatus.unavailable);
  });

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
          localDataSyncsProvider.overrideWithValue(true),
          syncDeviceIdProvider.overrideWithValue(null),
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

  test('no session runs while the restore offer is pending; answering it runs '
      'one', () async {
    await database.customStatement('DELETE FROM app_meta WHERE key = ?', [
      AppMetaKeys.restoreOfferAnswered,
    ]);
    final ProviderContainer c = device();
    c.read(syncControllerProvider);
    expect(await c.read(restoreOfferProvider.future), isTrue);
    await c.read(syncControllerProvider.notifier).syncNow();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(relay.pulls, 0);
    expect(c.read(syncControllerProvider).lastSyncAt, isNull);

    await c.read(restoreOfferProvider.notifier).answer();
    final SyncStatus status = await settled(c);
    expect(status.failure, isNull);
    expect(
      await DriftAppMetaStore(database).read(AppMetaKeys.restoreOfferAnswered),
      isNotNull,
    );
  });

  test(
    'no session runs while the offer is worked out again (a sign-in rebuilds '
    'it; what it was signed out says nothing)',
    () async {
      final List<Completer<bool>> answers = [
        Completer<bool>()..complete(false),
      ];
      final ProviderContainer c = ProviderContainer.test(
        overrides: [
          ...devWiring(),
          ...fakeApiOverrides(signedIn: true),
          databaseProvider.overrideWithValue(database),
          clockProvider.overrideWithValue(clock),
          syncDeviceIdProvider.overrideWithValue('dev-a'),
          syncRelayProvider.overrideWithValue(relay),
          restoreOfferProvider.overrideWith(
            () => _SlowOffer(() => answers.last.future),
          ),
        ],
        retry: (_, _) => null,
      );
      c.read(syncControllerProvider);
      await settled(c);

      answers.add(Completer<bool>());
      c.invalidate(restoreOfferProvider);
      c.read(restoreOfferProvider);
      await c.read(syncControllerProvider.notifier).syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(relay.pulls, 1, reason: 'held while the offer is worked out');

      answers.last.complete(false);
      await settled(c, pulls: 2);
    },
  );

  test(
    'a session awaiting the network when the app stops (a restore) ends with a '
    'logged error, nothing unhandled',
    () async {
      final ProviderContainer before = device(deviceId: null);
      await before.read(accountRepositoryProvider).upsert(testAccount('a1'));
      before.dispose();
      final List<LogRecord> logged = [];
      final StreamSubscription<LogRecord> logs = Logger.root.onRecord.listen(
        logged.add,
      );
      addTearDown(logs.cancel);

      relay.hold = Completer<void>();
      final ProviderContainer c = device();
      c.read(syncControllerProvider);
      while (relay.pushing == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      // What stopApp does: the container goes, then the database is closed.
      c.dispose();
      await database.close();
      relay.hold!.complete();
      relay.hold = null;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        logged.where(
          (r) => r.loggerName == 'sync' && r.message.startsWith('sync failed'),
        ),
        isNotEmpty,
      );
    },
  );

  test('the Plaid pull runs after the session', () async {
    final ProviderContainer c = device();
    c.read(syncControllerProvider);
    final SyncStatus status = await settled(c);
    expect(status.plaidFailure, isNull);
    expect(status.plaidPulledAt, isNotNull);
    expect(
      (await c.read(itemRepositoryProvider).watchAll().first).map((b) => b.id),
      ['sample-item-1'],
    );
    expect(
      await c.read(accountRepositoryProvider).watchAll().first,
      hasLength(3),
    );
  });

  test(
    'a failed Plaid pull is in the status, apart from the session',
    () async {
      final ProviderContainer c = device();
      c.read(fakeServerProvider).failNext('listItems', 500);
      c.read(syncControllerProvider);
      final SyncStatus status = await settled(c);
      expect(status.failure, isNull);
      expect(status.plaidFailure, SyncFailure.server);
      expect(status.plaidPulledAt, isNull);

      await c.read(syncControllerProvider.notifier).syncNow();
      final SyncStatus after = c.read(syncControllerProvider);
      expect(after.plaidFailure, isNull);
      expect(after.plaidPulledAt, isNotNull);
    },
  );

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
        ...devWiring(),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        connectivityProvider.overrideWithValue(network),
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
    // The controller hears of it when next read, and applies it right after.
    c.read(syncControllerProvider);
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

  test('a sign-out during the Plaid pull leaves the status signed out', () async {
    final ProviderContainer c = ProviderContainer.test(
      overrides: [
        ...devWiring(),
        ...fakeApiOverrides(signedIn: true),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        connectivityProvider.overrideWithValue(network),
        syncDeviceIdProvider.overrideWith((ref) => ref.watch(_device)),
        syncRelayProvider.overrideWith(
          (ref) => ref.watch(_device) == null ? null : relay,
        ),
      ],
      retry: (_, _) => null,
    );
    // Every answer of the fake (the pull's, not the relay's) takes a while.
    c.read(fakeServerProvider).latency = const Duration(milliseconds: 300);
    c.read(syncControllerProvider);
    while (relay.pulls == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    // The session's relay pull is done; the Plaid pull is waiting on the fake.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.read(syncControllerProvider).phase, SyncPhase.running);
    c.read(_device.notifier).set(null);
    c.read(syncControllerProvider);
    await Future<void>.delayed(const Duration(seconds: 2));
    final SyncStatus status = c.read(syncControllerProvider);
    expect(status.phase, SyncPhase.signedOut);
    expect(status.plaidFailure, isNull);
    expect(status.plaidPulledAt, isNull);
  });

  testWidgets('a device change met while a widget builds is applied after the '
      'build', (tester) async {
    final ProviderContainer c = ProviderContainer(
      overrides: [
        ...devWiring(),
        ...fakeApiOverrides(signedIn: true),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        connectivityProvider.overrideWithValue(network),
        syncDeviceIdProvider.overrideWith((ref) => ref.watch(_device)),
        syncRelayProvider.overrideWith(
          (ref) => ref.watch(_device) == null ? null : relay,
        ),
      ],
      retry: (_, _) => null,
    );
    addTearDown(c.dispose);
    await tester.runAsync(() async {
      c.read(syncControllerProvider);
      await settled(c);
    });
    Widget app(Key key) => UncontrolledProviderScope(
      container: c,
      child: Consumer(
        key: key,
        builder: (context, ref, _) => Text(
          ref.watch(syncControllerProvider).phase.name,
          textDirection: TextDirection.ltr,
        ),
      ),
    );
    await tester.pumpWidget(app(const ValueKey(1)));

    // Nothing watches the controller (Riverpod pauses it), the device signs out, then a
    // screen watching it builds: the controller hears of the change during that build
    // and must not change its state there.
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const SizedBox()),
    );
    c.read(_device.notifier).set(null);
    await tester.pumpWidget(app(const ValueKey(2)));
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(c.read(syncControllerProvider).phase, SyncPhase.signedOut);
    expect(find.text('signedOut'), findsOneWidget);
  });

  group('after a failure', () {
    const NetworkError offline = NetworkError(NetworkErrorKind.connection);

    // A session that fails offline after the start's.
    Future<ProviderContainer> failed({
      Duration backoff = const Duration(hours: 1),
      List<Override> extra = const [],
    }) async {
      final ProviderContainer c = device(
        extra: [
          syncBackoffProvider.overrideWithValue((_) => backoff),
          ...extra,
        ],
      );
      c.read(syncControllerProvider);
      await settled(c);
      relay.failNextPull = offline;
      await c.read(syncControllerProvider.notifier).syncNow();
      expect(c.read(syncControllerProvider).failure, SyncFailure.offline);
      return c;
    }

    test(
      'the backoff runs the next session, and the debounce waits for it',
      () async {
        final ProviderContainer c = await failed(
          backoff: const Duration(milliseconds: 400),
        );
        await c.read(accountRepositoryProvider).upsert(testAccount('a1'));
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(relay.pulls, 2, reason: 'the debounce waits for the backoff');
        await settled(c, pulls: 3);
        expect(c.read(syncControllerProvider).failure, isNull);
        expect(relay.inner.entries, hasLength(1));
      },
    );

    test('a paused app arms no retry; resume runs the session', () async {
      final TestWidgetsFlutterBinding binding =
          TestWidgetsFlutterBinding.instance;
      final ProviderContainer c = await failed(
        backoff: const Duration(milliseconds: 100),
      );
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      addTearDown(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      relay.failNextPull = offline;
      await c.read(syncControllerProvider.notifier).syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(relay.pulls, 3, reason: 'no retry while paused');
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settled(c, pulls: 4);
    });

    test(
      'offline, no retry is armed; the network back runs the session',
      () async {
        final ProviderContainer c = await failed(
          backoff: const Duration(milliseconds: 100),
        );
        network.set(false);
        relay.failNextPull = offline;
        await c.read(syncControllerProvider.notifier).syncNow();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        expect(relay.pulls, 3, reason: 'no retry while offline');
        network.set(true);
        await settled(c, pulls: 4);
      },
    );

    test(
      'a network that returns runs a session at once, with no tap',
      () async {
        final ProviderContainer c = await failed();
        network.set(false);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(relay.pulls, 2, reason: 'nothing runs while offline');
        network.set(true);
        await settled(c, pulls: 3);
        expect(c.read(syncControllerProvider).failure, isNull);
      },
    );

    test('a network change after a success runs nothing', () async {
      final ProviderContainer c = device();
      c.read(syncControllerProvider);
      await settled(c);
      network.set(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(relay.pulls, 1);
    });

    test('resume runs at once during the backoff', () async {
      final ProviderContainer c = await failed();
      final TestWidgetsFlutterBinding binding =
          TestWidgetsFlutterBinding.instance;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settled(c, pulls: 3);
    });

    test(
      'Sync now and a returning network drop the idle connections first',
      () async {
        int pools = 0;
        final ResettableHttpClientAdapter connections =
            ResettableHttpClientAdapter(() {
              pools++;
              return HttpClientAdapter();
            });
        addTearDown(connections.close);
        final ProviderContainer c = await failed(
          extra: [httpConnectionsProvider.overrideWithValue(connections)],
        );
        // The start's pool, then the failed Sync now's.
        expect(pools, 2);
        network.set(true);
        await settled(c, pulls: 3);
        expect(pools, 3);
      },
    );
  });

  test('the backoff doubles from 15 s to at most five minutes', () {
    expect(
      [for (int n = 1; n <= 8; n++) syncBackoffAfter(n).inSeconds],
      [15, 30, 60, 120, 240, 300, 300, 300],
    );
  });

  group('sync problems', () {
    List<SyncProblemNotification> told(ProviderContainer c) => [
      for (final InAppNotification n in c.read(inAppNotificationsProvider))
        if (n.notification case final SyncProblemNotification p) p,
    ];

    test(
      'sessions failing for a day since the last that worked are told once',
      () async {
        final ProviderContainer c = device(
          extra: [
            syncBackoffProvider.overrideWithValue(
              (_) => const Duration(hours: 1),
            ),
          ],
        );
        c.read(syncControllerProvider);
        final SyncStatus first = await settled(c);
        const NetworkError offline = NetworkError(NetworkErrorKind.connection);
        relay.failNextPull = offline;
        await c.read(syncControllerProvider.notifier).syncNow();
        expect(told(c), isEmpty, reason: 'not yet a day');
        clock.advance(const Duration(days: 1, minutes: 1));
        relay.failNextPull = offline;
        await c.read(syncControllerProvider.notifier).syncNow();
        relay.failNextPull = offline;
        await c.read(syncControllerProvider.notifier).syncNow();
        expect(told(c).map((p) => (p.problem, p.since)), [
          (SyncProblem.failing, first.lastSyncAt),
        ]);
      },
    );

    test('a linked bank that needs its sign-in is told once', () async {
      final ProviderContainer c = device();
      c.read(syncControllerProvider);
      await settled(c);
      final String itemId =
          (await c.read(itemRepositoryProvider).watchAll().first).first.id;
      await c.read(financeApiProvider).sandboxResetLogin(itemId);
      await c.read(syncControllerProvider.notifier).syncNow();
      await c.read(syncControllerProvider.notifier).syncNow();
      expect(told(c).map((p) => (p.problem, p.itemId)), [
        (SyncProblem.bankNeedsAttention, itemId),
      ]);
    });

    // Each container is a cycle of its own, as the background sync's are.
    test(
      'a problem is told once across containers, and again once it cleared',
      () async {
        const NetworkError offline = NetworkError(NetworkErrorKind.connection);
        int toldInAll = 0;
        Future<void> cycle({required bool fail}) async {
          final ProviderContainer c = device(
            extra: [
              syncBackoffProvider.overrideWithValue(
                (_) => const Duration(hours: 1),
              ),
            ],
          );
          if (fail) relay.failNextPull = offline;
          c.read(syncControllerProvider);
          await c.read(syncControllerProvider.notifier).firstSession();
          toldInAll += told(c).length;
          c.dispose();
        }

        await cycle(fail: false);
        clock.advance(const Duration(days: 1, minutes: 1));
        for (int i = 0; i < 3; i++) {
          await cycle(fail: true);
        }
        expect(toldInAll, 1);
        await cycle(fail: false);
        clock.advance(const Duration(days: 1, minutes: 1));
        await cycle(fail: true);
        expect(toldInAll, 2, reason: 'a new day of failures after a success');
      },
    );

    test(
      'a bank that needs its sign-in is told once across containers',
      () async {
        final FakeServer server =
            FakeServer(
                dataset: FakeDataset.sample(clock.today()),
                now: clock.nowUtc,
              )
              ..seedUser(
                email: demoEmail,
                password: demoPassword,
                displayName: 'Demo',
              )
              ..seedLinkedItems(demoEmail);
        int toldInAll = 0;
        String? itemId;
        for (int i = 0; i < 3; i++) {
          final ProviderContainer c = device(server: server);
          c.read(syncControllerProvider);
          await c.read(syncControllerProvider.notifier).firstSession();
          if (itemId == null) {
            itemId = (await c.read(itemRepositoryProvider).watchAll().first)
                .first
                .id;
            await c.read(financeApiProvider).sandboxResetLogin(itemId);
            await c.read(syncControllerProvider.notifier).syncNow();
          }
          toldInAll += told(c).length;
          c.dispose();
        }
        expect(toldInAll, 1);
      },
    );
  });
}
