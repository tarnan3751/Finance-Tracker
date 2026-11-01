// startApp on the demo's wiring for the watcher tests: the recurring streams counting the
// detector's runs, flags for when the budget alert watcher and the detector start, and
// the app's container, known before the first frame.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/recurring/application/detector_runner.dart';
import 'package:finance_tracker/features/recurring/data/in_memory_recurring_stream_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_models/shared_models.dart';

import 'mode_wiring.dart';

/// The in-memory streams, counting the detector's runs (each ends in replaceDetected).
final class CountingStreams extends InMemoryRecurringStreamRepository {
  CountingStreams(super.clock, {required super.recorder});

  int runs = 0;

  @override
  Future<void> replaceDetected(List<RecurringStream> streams) {
    runs++;
    return super.replaceDetected(streams);
  }
}

/// startApp on the demo's wiring with the counting streams in place of its own, noting
/// when the alert watcher and the detector start and keeping the app's container.
final class StartupWiring {
  bool alertsStarted = false;
  bool detectorStarted = false;
  late CountingStreams streams;
  late ProviderContainer container;

  Future<void> start() {
    final InMemoryAppModeStore modes = InMemoryAppModeStore(mode: AppMode.demo);
    return startApp(
      AppConfig.prod(),
      modes: modes,
      wiringFor: (config) => [
        for (final Override o in modeWiring(modes)(config))
          if (!identical(
                // ignore: invalid_use_of_visible_for_testing_member
                o.origin,
                recurringStreamRepositoryProvider,
              ) &&
              !identical(
                // ignore: invalid_use_of_visible_for_testing_member
                o.origin,
                appConfigProvider,
              ))
            o,
        // Read before the first frame (the lock reads it), so the container is known.
        appConfigProvider.overrideWith((ref) {
          container = ref.container;
          return config;
        }),
        budgetAlertDebounceProvider.overrideWith((ref) {
          alertsStarted = true;
          return const Duration(milliseconds: 20);
        }),
        detectorDebounceProvider.overrideWith((ref) {
          detectorStarted = true;
          return const Duration(milliseconds: 100);
        }),
        recurringStreamRepositoryProvider.overrideWith((ref) {
          streams = CountingStreams(
            ref.watch(clockProvider),
            recorder: ref.watch(changeRecorderProvider),
          );
          ref.onDispose(streams.close);
          return streams;
        }),
      ],
    );
  }
}
