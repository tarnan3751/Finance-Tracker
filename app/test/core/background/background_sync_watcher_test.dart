// The app's side of the background sync: the periodic sync scheduled while someone is
// signed in and the switch is on, cancelled on a sign-out or when the switch goes off,
// nothing at all where the data does not sync (the demo flavor), and the Drift streams
// told to read again on resume after a run the worker made on its own (not after one the
// app made).
import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate;
import 'package:drift/native.dart';
import 'package:finance_tracker/core/background/background_cycle.dart';
import 'package:finance_tracker/core/background/background_sync_watcher.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/background_work.dart';
import 'package:finance_tracker/core/platform/background_work_provider.dart';
import 'package:finance_tracker/core/platform/fake_background_work.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  late FakeBackgroundWork work;
  late AppDatabase database;
  late InMemoryAppMetaStore meta;

  setUp(() {
    work = FakeBackgroundWork();
    database = AppDatabase(NativeDatabase.memory());
    meta = InMemoryAppMetaStore();
  });
  tearDown(() => database.close());

  ProviderContainer app({bool syncs = true}) {
    final ProviderContainer c = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(database),
        appMetaStoreProvider.overrideWithValue(meta),
        localDataSyncsProvider.overrideWithValue(syncs),
        syncDeviceIdProvider.overrideWith((ref) => ref.watch(_device)),
        backgroundWorkProvider.overrideWithValue(work),
      ],
    );
    c.listen(backgroundSyncWatcherProvider, (_, _) {});
    return c;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'signed in, the periodic sync is scheduled; a sign-out cancels it',
    () async {
      final ProviderContainer c = app();
      await settle();
      expect(work.scheduled, isTrue);
      expect(work.calls.single.every, backgroundSyncEvery);
      expect(work.constraints, backgroundSyncConstraints);
      c.read(_device.notifier).set(null);
      await settle();
      expect(work.scheduled, isFalse);
    },
  );

  test('the switch cancels it and schedules it again', () async {
    final ProviderContainer c = app();
    await settle();
    final BackgroundSyncWatcher watcher = c.read(
      backgroundSyncWatcherProvider.notifier,
    );
    await watcher.setEnabled(false);
    expect(work.scheduled, isFalse);
    expect(await watcher.enabled(), isFalse);
    await watcher.setEnabled(true);
    expect(work.scheduled, isTrue);
  });

  test('nothing is scheduled where the data does not sync', () async {
    app(syncs: false);
    await settle();
    expect(work.calls, isEmpty);
  });

  test("on resume after the worker's own run the streams read again", () async {
    app();
    await settle();
    int updates = 0;
    final StreamSubscription<Set<TableUpdate>> sub = database
        .tableUpdates()
        .listen((_) => updates++);
    addTearDown(sub.cancel);
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.instance;
    Future<void> resume() async {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    BackgroundRun run({required bool delegated, int minute = 0}) =>
        BackgroundRun(
          at: DateTime.utc(2026, 10, 31, 12, minute),
          result: BackgroundResult.synced,
          delegated: delegated,
        );

    await meta.write(
      AppMetaKeys.backgroundLastRun,
      run(delegated: true).toJson(),
    );
    await resume();
    expect(updates, 0, reason: 'the app made that run itself');
    await meta.write(
      AppMetaKeys.backgroundLastRun,
      run(delegated: false, minute: 1).toJson(),
    );
    await resume();
    expect(updates, greaterThan(0));
    final int after = updates;
    await resume();
    expect(updates, after, reason: 'nothing moved since');
  });
}
