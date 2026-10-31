// The background work seam: the workmanager implementation's calls (the unique names, the
// tag, the policies, the constraints, the flavor handed to the dispatcher, expedited only
// on Android 12 and later, the developer menu's delayed run, a cancel by tag only), over a
// recording platform; and the fake.
import 'package:finance_tracker/core/platform/background_work.dart';
import 'package:finance_tracker/core/platform/fake_background_work.dart';
import 'package:finance_tracker/core/platform/workmanager_background_work.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workmanager/workmanager.dart';

final class _Recording extends WorkmanagerPlatform {
  final List<String> calls = [];
  final Map<String, Object?> last = {};
  WorkInfo? info;

  @override
  Future<void> initialize(
    Function callbackDispatcher, {
    bool isInDebugMode = false,
  }) async => calls.add('initialize');

  @override
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? flexInterval,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingPeriodicWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async {
    calls.add('periodic');
    last
      ..clear()
      ..addAll({
        'name': uniqueName,
        'task': taskName,
        'frequency': frequency,
        'flex': flexInterval,
        'input': inputData,
        'network': constraints?.networkType,
        'batteryNotLow': constraints?.requiresBatteryNotLow,
        'policy': existingWorkPolicy,
        'backoff': backoffPolicy,
        'backoffDelay': backoffPolicyDelay,
        'tag': tag,
        'foreground': foregroundServiceConfig,
      });
  }

  @override
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    OutOfQuotaPolicy? outOfQuotaPolicy,
    ForegroundServiceConfig? foregroundServiceConfig,
    bool expedited = false,
  }) async {
    calls.add('oneOff');
    last
      ..clear()
      ..addAll({
        'name': uniqueName,
        'input': inputData,
        'delay': initialDelay,
        'network': constraints?.networkType,
        'policy': existingWorkPolicy,
        'quota': outOfQuotaPolicy,
        'expedited': expedited,
        'tag': tag,
      });
  }

  @override
  Future<void> cancelByTag(String tag) async => calls.add('cancelByTag $tag');

  @override
  Future<void> cancelAll() async => calls.add('cancelAll');

  @override
  Future<WorkInfo?> getWorkInfo(String uniqueName) async => info;
}

void _dispatcher() {}

void main() {
  late _Recording platform;
  late int sdk;

  setUp(() {
    platform = _Recording();
    sdk = 36;
  });

  WorkmanagerBackgroundWork work() => WorkmanagerBackgroundWork(
    dispatcher: _dispatcher,
    flavor: 'prod',
    sdkInt: () async => sdk,
    platform: platform,
  );

  test(
    'the periodic sync: hourly, on a network, battery not low, kept',
    () async {
      final WorkmanagerBackgroundWork w = work();
      await w.schedulePeriodicSync(
        every: backgroundSyncEvery,
        constraints: backgroundSyncConstraints,
      );
      await w.schedulePeriodicSync(
        every: backgroundSyncEvery,
        constraints: backgroundSyncConstraints,
      );
      expect(platform.calls, ['initialize', 'periodic', 'periodic']);
      expect(platform.last, {
        'name': periodicSyncName,
        'task': syncTaskName,
        'frequency': const Duration(minutes: 60),
        'flex': null,
        'input': {flavorInputKey: 'prod'},
        'network': NetworkType.connected,
        'batteryNotLow': true,
        'policy': ExistingPeriodicWorkPolicy.keep,
        'backoff': BackoffPolicy.linear,
        'backoffDelay': const Duration(seconds: 30),
        'tag': syncTag,
        'foreground': null,
      });
    },
  );

  test('the one-off is expedited on Android 12 and later only', () async {
    await work().runSyncNow();
    expect(platform.last, {
      'name': oneOffSyncName,
      'input': {flavorInputKey: 'prod'},
      'delay': null,
      'network': NetworkType.connected,
      'policy': ExistingWorkPolicy.keep,
      'quota': OutOfQuotaPolicy.runAsNonExpeditedWorkRequest,
      'expedited': true,
      'tag': syncTag,
    });
    sdk = 30;
    await work().runSyncNow();
    expect(platform.last['expedited'], isFalse);
    expect(platform.last['quota'], isNull);
  });

  test("the developer menu's delayed run: its own name, replaced, never "
      'expedited', () async {
    await work().runSyncLater(const Duration(seconds: 20));
    expect(platform.last, {
      'name': delayedSyncName,
      'input': {flavorInputKey: 'prod'},
      'delay': const Duration(seconds: 20),
      'network': NetworkType.connected,
      'policy': ExistingWorkPolicy.replace,
      'quota': null,
      'expedited': false,
      'tag': syncTag,
    });
  });

  test('cancelling cancels the tag, never all of WorkManager', () async {
    await work().cancelAll();
    expect(platform.calls, ['initialize', 'cancelByTag $syncTag']);
  });

  test("the periodic state is WorkManager's", () async {
    final WorkmanagerBackgroundWork w = work();
    expect(await w.periodicState(), BackgroundWorkState.none);
    platform.info = const WorkInfo(
      uniqueName: periodicSyncName,
      state: WorkState.scheduled,
      isPeriodic: true,
    );
    expect(await w.periodicState(), BackgroundWorkState.scheduled);
    platform.info = const WorkInfo(
      uniqueName: periodicSyncName,
      state: WorkState.running,
      isPeriodic: true,
    );
    expect(await w.periodicState(), BackgroundWorkState.running);
  });

  test(
    'the fake records schedules, one-offs, delayed runs and cancellations',
    () async {
      final FakeBackgroundWork fake = FakeBackgroundWork();
      await fake.schedulePeriodicSync(
        every: backgroundSyncEvery,
        constraints: backgroundSyncConstraints,
      );
      expect(await fake.periodicState(), BackgroundWorkState.scheduled);
      await fake.runSyncNow();
      await fake.runSyncLater(const Duration(seconds: 20));
      await fake.cancelAll();
      expect(fake.calls.map((c) => c.method), [
        'schedule',
        'runNow',
        'runLater',
        'cancel',
      ]);
      expect(fake.calls[2].every, const Duration(seconds: 20));
      expect(fake.calls.first.every, backgroundSyncEvery);
      expect(fake.constraints, backgroundSyncConstraints);
      expect(await fake.periodicState(), BackgroundWorkState.none);
    },
  );
}
